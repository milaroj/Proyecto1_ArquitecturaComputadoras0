// fp_add_small_adder.v
module fp_add_small_adder #(
    parameter integer EXP_W = 5
)(
    input  [EXP_W-1:0] A,
    input  [EXP_W-1:0] B,
    input              OP,       // 1 = resta, 0 = suma
    output [EXP_W-1:0] Y,
    output             overflow
);
    wire [EXP_W:0] extA = {1'b0, A};
    wire [EXP_W:0] extB = {1'b0, B};
    wire [EXP_W:0] extR = OP ? (extA - extB) : (extA + extB);

    assign overflow = (~OP) & extR[EXP_W];
    assign Y        = extR[EXP_W-1:0];
endmodule
