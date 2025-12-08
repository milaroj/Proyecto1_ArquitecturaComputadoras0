// fp_unpack.v
// Desempaqueta un número en coma flotante genérico:
// [ sign | exponent (EXP_W bits) | fraction (FRAC_W bits) ]

module fp_unpack #(
    parameter integer EXP_W  = 5,
    parameter integer FRAC_W = 10,
    parameter integer FP_W   = 1 + EXP_W + FRAC_W
)(
    input  [FP_W-1:0]   a,
    output              sign,
    output [EXP_W-1:0]  exp,
    output [FRAC_W-1:0] frac
);
    // MSB = signo
    assign sign = a[FP_W-1];

    // Exponente: bits "del medio"
    assign exp  = a[FP_W-2 : FRAC_W];

    // Fracción: LSBs
    assign frac = a[FRAC_W-1 : 0];

endmodule
