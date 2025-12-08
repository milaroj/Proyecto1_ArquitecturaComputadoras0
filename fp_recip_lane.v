// fp_recip_lane.v
// Recíproco de un número FP genérico en un solo lane.

`include "fp_unpack.v"
`include "fp_classify.v"

`timescale 1ns/1ps
module fp_recip_lane #(
    parameter integer EXP_W  = 5,
    parameter integer FRAC_W = 10,
    parameter integer FP_W   = 1 + EXP_W + FRAC_W
)(
    input  [FP_W-1:0] a,
    output [FP_W-1:0] z,
    output            illegal_input
);

    // =======================================================
    // 1) Desempaquetar y clasificar
    // =======================================================
    wire               sign_a;
    wire [EXP_W-1:0]   exp_a;
    wire [FRAC_W-1:0]  frac_a;

    fp_unpack #(
        .EXP_W (EXP_W),
        .FRAC_W(FRAC_W),
        .FP_W  (FP_W)
    ) UNPACK (
        .a    (a),
        .sign (sign_a),
        .exp  (exp_a),
        .frac (frac_a)
    );

    wire is_zero, is_inf, is_nan, is_normal, is_sub;

    fp_classify #(
        .EXP_W (EXP_W),
        .FRAC_W(FRAC_W)
    ) CLASS (
        .exp       (exp_a),
        .frac      (frac_a),
        .is_zero   (is_zero),
        .is_inf    (is_inf),
        .is_nan    (is_nan),
        .is_normal (is_normal),
        .is_sub    (is_sub)
    );

    assign illegal_input = is_nan | is_sub;

    // =======================================================
    // 2) Casos especiales (0 y +Inf)
    // =======================================================

    // Vectores útiles
    localparam [EXP_W-1:0] EXP_ZERO = {EXP_W{1'b0}};
    localparam [EXP_W-1:0] EXP_MAX  = {EXP_W{1'b1}};
    localparam [FRAC_W-1:0] FRAC_ZERO = {FRAC_W{1'b0}};

    // Recíproco de 0 = +Inf
    // Recíproco de +Inf = 0
    wire [FP_W-1:0] z_special;
    assign z_special =
        is_zero ? {1'b0, EXP_MAX,  FRAC_ZERO} :   // +Inf
        is_inf  ? {1'b0, EXP_ZERO, FRAC_ZERO} :   // +0
                  {FP_W{1'b0}};                   // no se usa para normales

    // =======================================================
    // 3) Parámetros del formato y bias
    // =======================================================
    localparam integer BIAS        = (1 << (EXP_W-1)) - 1;
    localparam integer MAX_NORM_E  = (1 << EXP_W) - 2; // máx exponente normal
    localparam integer MIN_NORM_E  = 1;                // mín exponente normal

    // =======================================================
    // 4) Cálculo del recíproco de la mantisa
    //     mant_in = 1.frac en entero (FRAC_W+1 bits)
    //     usamos una división entera:
    //       mant_recip_raw = (2^(2*FRAC_W+1)) / mant_in
    // =======================================================
    localparam integer MANT_W   = FRAC_W + 1;           // 1 + frac
    localparam integer DIV_SHIFT = 2*FRAC_W + 1;

    wire [MANT_W-1:0] mant_in;
    assign mant_in = {1'b1, frac_a}; // 1.frac

    // Elegimos un entero grande como "DIVISOR" para la aproximación.
    // NOTA: esto está pensado principalmente para valores tipo FP16;
    // para FRAC_W muy distinto habría que analizar numéricamente la calidad.
    localparam integer DIVISOR = (1 << DIV_SHIFT);

    // Resultado de la división
    wire [31:0] mant_recip_raw;
    assign mant_recip_raw = DIVISOR / mant_in;

    // Rango aproximado ~ [2^FRAC_W, 2^(FRAC_W+1)]
    // Detectar si >= 2.0 (bit FRAC_W+1)
    wire mant_ge_2;
    assign mant_ge_2 = mant_recip_raw[FRAC_W+1];

    // Normalizar a 1.xxxxx (MANT_W bits)
    wire [MANT_W-1:0] mant_normalized;
    assign mant_normalized =
        mant_ge_2 ? mant_recip_raw[FRAC_W+1 : 1] :  // shift si era >= 2.0
                    mant_recip_raw[FRAC_W   : 0];

    // Fracción de salida = FRAC_W LSBs
    wire [FRAC_W-1:0] frac_out;
    assign frac_out = mant_normalized[FRAC_W-1:0];

    // =======================================================
    // 5) Cálculo del exponente del recíproco
    //
    // Inspirado en tu fp16_reciprocal:
    //   exp_temp = (2*BIAS - exp_a)  ó (2*BIAS - 1 - exp_a)
    // según si la mantisa recíproca se normalizó con un factor extra 2.
    // =======================================================
    // Ancho suficiente para evitar overflow en cálculo intermedio
    wire signed [EXP_W+1:0] exp_temp;
    assign exp_temp = mant_ge_2 ?
                      ( (2*BIAS)     - $signed({1'b0, exp_a}) ) :
                      ( (2*BIAS - 1) - $signed({1'b0, exp_a}) );

    // Overflow / underflow
    wire overflow, underflow;
    assign overflow  = (exp_temp >  MAX_NORM_E);
    assign underflow = (exp_temp <  MIN_NORM_E);

    wire [EXP_W-1:0] exp_out;
    assign exp_out =
        overflow  ? EXP_MAX  :
        underflow ? EXP_ZERO :
                    exp_temp[EXP_W-1:0];

    // =======================================================
    // 6) Resultado normal
    // =======================================================
    wire [FP_W-1:0] z_normal;
    assign z_normal =
        overflow  ? {sign_a, EXP_MAX,  FRAC_ZERO} : // ±Inf
        underflow ? {sign_a, EXP_ZERO, FRAC_ZERO} : // ±0
                    {sign_a, exp_out,  frac_out};

    // =======================================================
    // 7) Selección final según la clase del operando
    // =======================================================
    assign z =
        (is_zero | is_inf) ? z_special :   // 0 o Inf de entrada
        is_normal          ? z_normal  :   // normales
                             {FP_W{1'b0}}; // NaN/sub

endmodule
