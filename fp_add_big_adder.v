// fp_add_big_adder.v
module fp_add_big_adder #(
    parameter integer MANT_W = 11   // 1+FRAC_W
)(
    input  wire [MANT_W-1:0] A,
    input  wire [MANT_W-1:0] B,
    input  wire              subtract, // 0 = suma, 1 = resta
    output wire [MANT_W-1:0] S,
    output wire              C
);
    wire [MANT_W:0] sum_full;

    assign sum_full = subtract ?
                      ({1'b0, A} - {1'b0, B}) :
                      ({1'b0, A} + {1'b0, B});

    assign C = sum_full[MANT_W];
    assign S = sum_full[MANT_W-1:0];
endmodule
