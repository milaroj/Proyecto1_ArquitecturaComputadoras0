// fp_add_lane.v

`include "fp_add_diff.v"
`include "fp_add_control.v"
`include "fp_add_mux2.v"
`include "fp_add_shift_right.v"
`include "fp_add_big_adder.v"
`include "fp_add_shift_lr.v"
`include "fp_add_small_adder.v"
`include "fp_add_special.v"


module fp_add_lane #(
    parameter integer EXP_W  = 5,
    parameter integer FRAC_W = 10,
    parameter integer FP_W   = 1 + EXP_W + FRAC_W
)(
    input  wire               RST,
    input  wire               ENA,
    input  wire [FP_W-1:0]    a,
    input  wire [FP_W-1:0]    b,
    output wire [FP_W-1:0]    z
);
    localparam integer MANT_W  = FRAC_W + 1;
    localparam integer RES_W   = MANT_W + 1;
    localparam integer SHIFT_W = $clog2(FRAC_W + 2);

    // Campos de a y b
    wire sign_a = a[FP_W-1];
    wire sign_b = b[FP_W-1];

    wire [EXP_W-1:0]  exp_a  = a[FRAC_W +: EXP_W];
    wire [EXP_W-1:0]  exp_b  = b[FRAC_W +: EXP_W];
    wire [FRAC_W-1:0] mant_a = a[FRAC_W-1:0];
    wire [FRAC_W-1:0] mant_b = b[FRAC_W-1:0];

    // --- DIFERENCIAL ---
    wire [EXP_W-1:0] diff;
    wire s_rest;
    fp_add_diff #(.EXP_W(EXP_W)) DIFF (
        .EA  (exp_a),
        .EB  (exp_b),
        .diff(diff),
        .s   (s_rest)
    );

    // --- CONTROL ---
    wire mux_ExpM, mux_menor, mux_mayor;
    wire [EXP_W-1:0]  shift_right;
    wire [SHIFT_W-1:0] shift_amt;
    wire               shift_dir;
    wire               subtract;
    wire               result_sign;

    wire [RES_W-1:0]   res_big;
    wire [MANT_W-1:0]  S_big;
    wire               C;

    fp_add_control #(
        .EXP_W (EXP_W),
        .FRAC_W(FRAC_W)
    ) CTRL (
        .A          (diff),
        .S_rest     (s_rest),
        .Res_big    (res_big),
        .sign_a     (sign_a),
        .sign_b     (sign_b),
        .mant_a     (mant_a),
        .mant_b     (mant_b),
        .mux_ExpM   (mux_ExpM),
        .mux_menor  (mux_menor),
        .mux_mayor  (mux_mayor),
        .shift_right(shift_right),
        .shift_amt  (shift_amt),
        .shift_dir  (shift_dir),
        .subtract   (subtract),
        .result_sign(result_sign)
    );

    // --- MUX EXPONENTE MAYOR ---
    wire [EXP_W-1:0] Exp_M;
    fp_add_mux2 #(.W(EXP_W)) MUX_EXP (
        .A  (exp_a),
        .B  (exp_b),
        .SEL(mux_ExpM),
        .Y  (Exp_M)
    );

    // --- MUX MANTISAS ---
    wire [MANT_W-1:0] Y_menor, Y_mayor;

    fp_add_mux2 #(.W(MANT_W)) MUX_MENOR (
        .A  ({1'b1, mant_b}),
        .B  ({1'b1, mant_a}),
        .SEL(mux_menor),
        .Y  (Y_menor)
    );

    fp_add_mux2 #(.W(MANT_W)) MUX_MAYOR (
        .A  ({1'b1, mant_b}),
        .B  ({1'b1, mant_a}),
        .SEL(mux_mayor),
        .Y  (Y_mayor)
    );

    // --- SHIFT RIGHT PARA ALINEAR ---
    wire [MANT_W-1:0] Y_S_regD;
    fp_add_shift_right #(
        .MANT_W(MANT_W),
        .N_W   (EXP_W)
    ) SREG_RIGHT (
        .RST(RST),
        .ENA(ENA),
        .SEL(1'b0),
        .A  (Y_menor),
        .N  (shift_right),
        .Y  (Y_S_regD)
    );

    // --- SUMA/RESTA ---
    wire [MANT_W-1:0] opA = subtract ? Y_mayor  : Y_S_regD;
    wire [MANT_W-1:0] opB = subtract ? Y_S_regD : Y_mayor;

    fp_add_big_adder #(.MANT_W(MANT_W)) ALU_BIG (
        .A      (opA),
        .B      (opB),
        .subtract(subtract),
        .S      (S_big),
        .C      (C)
    );

    assign res_big = {C, S_big};

    // --- NORMALIZACIÓN ---
    wire [RES_W-1:0] Y_S_regI;
    fp_add_shift_lr #(
        .RES_W  (RES_W),
        .SHIFT_W(SHIFT_W)
    ) SREG_LR (
        .RST(RST),
        .ENA(ENA),
        .SEL(shift_dir),
        .A  (res_big),
        .N  (shift_amt),
        .Y  (Y_S_regI)
    );

    // --- AJUSTE DE EXPONENTE ---
    wire [EXP_W-1:0] Y_AL_small;
    wire             exp_overflow;

    wire [EXP_W-1:0] shift_amt_ext =
        {{(EXP_W-SHIFT_W){1'b0}}, shift_amt};

    fp_add_small_adder #(.EXP_W(EXP_W)) ALU_SMALL (
        .A       (Exp_M),
        .B       (shift_amt_ext),
        .OP      (shift_dir),     // 0 suma, 1 resta
        .Y       (Y_AL_small),
        .overflow(exp_overflow)
    );

    wire force_inf = exp_overflow | (&Y_AL_small);

    wire res_is_zero = (res_big == {RES_W{1'b0}});

wire [FP_W-1:0] normal_nonzero_result =
    force_inf ?
      {result_sign, {EXP_W{1'b1}}, {FRAC_W{1'b0}}} :
      {result_sign, Y_AL_small,    Y_S_regI[FRAC_W-1:0]};

wire [FP_W-1:0] normal_result =
    res_is_zero ?
      {1'b0, {EXP_W{1'b0}}, {FRAC_W{1'b0}}} :   // +0
      normal_nonzero_result;

  

    // --- CASOS ESPECIALES ---
    wire [FP_W-1:0] z_special;
    wire            is_special;

    fp_add_special #(
        .EXP_W(EXP_W),
        .FRAC_W(FRAC_W),
        .FP_W(FP_W)
    ) SPEC (
        .A            (a),
        .B            (b),
        .normal_result(normal_result),
        .final_result (z_special),
        .special_case (is_special)
    );

    assign z = is_special ? z_special : normal_result;
endmodule
