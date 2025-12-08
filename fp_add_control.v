// fp_add_control.v
module fp_add_control #(
    parameter integer EXP_W  = 5,
    parameter integer FRAC_W = 10
)(
    input  [EXP_W-1:0]  A,        // diferencia de exponente
    input               S_rest,   // 0: A>=B, 1: A<B
    input  [FRAC_W+1:0] Res_big, 
    input               sign_a,
    input               sign_b,
    input  [FRAC_W-1:0] mant_a,
    input  [FRAC_W-1:0] mant_b,

    output              mux_ExpM,
    output              mux_menor,
    output              mux_mayor,
    output [EXP_W-1:0]  shift_right,
    output reg [$clog2(FRAC_W+2)-1:0] shift_amt,
    output reg          shift_dir,
    output reg          subtract,
    output reg          result_sign
);
    localparam integer MANT_W  = FRAC_W + 1;
    localparam integer RES_W   = MANT_W + 1;
    localparam integer SHIFT_W = $clog2(FRAC_W + 2);

    assign shift_right = A;
    assign mux_ExpM    = S_rest;
    assign mux_menor   = S_rest;
    assign mux_mayor   = !S_rest;

    // Magnitud absoluta
    wire [MANT_W-1:0] full_mant_a = {1'b1, mant_a};
    wire [MANT_W-1:0] full_mant_b = {1'b1, mant_b};

    wire a_greater_abs =
        (S_rest == 1'b0) ?
        (full_mant_a > full_mant_b) :
        (full_mant_b > full_mant_a);

    // Detección de operación y signo
    always @* begin
        if (sign_a == sign_b) begin
            subtract    = 1'b0;
            result_sign = sign_a;
        end else begin
            subtract = 1'b1;
            // signo del número de mayor magnitud
            if (a_greater_abs)
                result_sign = sign_a;
            else
                result_sign = sign_b;
        end
    end

    // Normalización
    integer k;
    always @* begin
        shift_amt = {SHIFT_W{1'b0}};
        shift_dir = 1'b0;

        // overflow tipo 10.xxxx
        if (Res_big[RES_W-1]) begin
            shift_amt = {{(SHIFT_W-1){1'b0}}, 1'b1};
            shift_dir = 1'b0; // derecha
        end
        // menor que 1.0 y no cero
        else if ((Res_big[RES_W-2] == 1'b0) && |Res_big[RES_W-3:0]) begin
            shift_dir = 1'b1; // izquierda
            shift_amt = {SHIFT_W{1'b0}};

            // buscar el primer 1 desde abajo
            for (k = RES_W-3; k >= 0; k = k - 1) begin
                if (Res_big[k] && (shift_amt == {SHIFT_W{1'b0}})) begin
                    shift_amt = (RES_W-2) - k;
                end
            end
        end
    end
endmodule
