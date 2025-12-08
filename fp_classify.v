// fp_classify.v
// Clasifica un número FP genérico en:
// cero, infinito, NaN, normal, subnormal.

module fp_classify #(
    parameter integer EXP_W  = 5,
    parameter integer FRAC_W = 10
)(
    input  [EXP_W-1:0]  exp,
    input  [FRAC_W-1:0] frac,
    output              is_zero,
    output              is_inf,
    output              is_nan,
    output              is_normal,
    output              is_sub
);
    // exp = 0
    wire exp_zero = (exp == {EXP_W{1'b0}});

    // exp = todos 1s
    wire exp_all1 = (exp == {EXP_W{1'b1}});

    // frac = 0
    wire frac_zero = (frac == {FRAC_W{1'b0}});

    assign is_zero   =  exp_zero &  frac_zero;
    assign is_inf    =  exp_all1 &  frac_zero;
    assign is_nan    =  exp_all1 & ~frac_zero;
    assign is_sub    =  exp_zero & ~frac_zero;
    assign is_normal = ~exp_zero & ~exp_all1;

endmodule
