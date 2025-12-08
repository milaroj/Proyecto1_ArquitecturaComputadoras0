// fp_add_mux2.v
module fp_add_mux2 #(
    parameter integer W = 5
)(
    input  wire [W-1:0] A,
    input  wire [W-1:0] B,
    input  wire         SEL,
    output wire [W-1:0] Y
);
    assign Y = SEL ? B : A;
endmodule
