// fp_mantmul.v
// Multiplica mantisas (1.frac) de ancho FRAC_W

module fp_mantmul #(
  parameter integer FRAC_W = 10,
  parameter integer MANT_W = FRAC_W + 1,        // 1 + frac
  parameter integer PROD_W = 2 * MANT_W        // ancho del producto
)(
  input  [FRAC_W-1:0] fA,
  input  [FRAC_W-1:0] fB,
  output [PROD_W-1:0] P
);

  wire [MANT_W-1:0] MA = {1'b1, fA};
  wire [MANT_W-1:0] MB = {1'b1, fB};
  assign P = MA * MB;

endmodule
