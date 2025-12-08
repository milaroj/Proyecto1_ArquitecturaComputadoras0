// fp_mul_lane.v
// Multiplicación en un solo lane

`include "fp_unpack.v"
`include "fp_classify.v"
`include "fp_special_mul.v"
`include "fp_mantmul.v"
`include "fp_normround.v"

`timescale 1ns/1ps

module fp_mul_lane #(
  parameter integer EXP_W   = 5,
  parameter integer FRAC_W  = 10,
  parameter integer FP_W    = 1 + EXP_W + FRAC_W,
  parameter integer MANT_W  = FRAC_W + 1,
  parameter integer PROD_W  = 2 * MANT_W
)(
  input  [FP_W-1:0] a,
  input  [FP_W-1:0] b,
  output [FP_W-1:0] z,
  output            illegal_sub_in,   // NaN o subnormal en entrada
  output            op_invalid        // ∞ × 0
);

  // 1) Desempaquetar
  wire               sA, sB;
  wire [EXP_W-1:0]   eA, eB;
  wire [FRAC_W-1:0]  fA, fB;

  fp_unpack #(
    .EXP_W (EXP_W),
    .FRAC_W(FRAC_W),
    .FP_W  (FP_W)
  ) UA (
    .a    (a),
    .sign (sA),
    .exp  (eA),
    .frac (fA)
  );

  fp_unpack #(
    .EXP_W (EXP_W),
    .FRAC_W(FRAC_W),
    .FP_W  (FP_W)
  ) UB (
    .a    (b),
    .sign (sB),
    .exp  (eB),
    .frac (fB)
  );

  // 2) Clasificación
  wire zA, iA, nA, norA, subA;
  wire zB, iB, nB, norB, subB;

  fp_classify #(
    .EXP_W (EXP_W),
    .FRAC_W(FRAC_W)
  ) CA (
    .exp       (eA),
    .frac      (fA),
    .is_zero   (zA),
    .is_inf    (iA),
    .is_nan    (nA),
    .is_normal (norA),
    .is_sub    (subA)
  );

  fp_classify #(
    .EXP_W (EXP_W),
    .FRAC_W(FRAC_W)
  ) CB (
    .exp       (eB),
    .frac      (fB),
    .is_zero   (zB),
    .is_inf    (iB),
    .is_nan    (nB),
    .is_normal (norB),
    .is_sub    (subB)
  );

  assign illegal_sub_in = nA | nB | subA | subB;

  // 3) Casos especiales
  wire [FP_W-1:0] z_spec;
  wire            take_spec;
  wire            illegal_input_spec;
  fp_special_mul #(
    .EXP_W  (EXP_W),
    .FRAC_W (FRAC_W),
    .FP_W   (FP_W)
  ) SPEC (
    .sA       (sA),
    .eA       (eA),
    .fA       (fA),
    .is_zeroA (zA),
    .is_infA  (iA),
    .is_nanA  (nA),
    .is_subA  (subA),

    .sB       (sB),
    .eB       (eB),
    .fB       (fB),
    .is_zeroB (zB),
    .is_infB  (iB),
    .is_nanB  (nB),
    .is_subB  (subB),

    .z_out       (z_spec),
    .use_special (take_spec),
    .illegal_input(illegal_input_spec),
    .op_invalid  (op_invalid)
  );

  // 4) Camino aritmético
  wire        sZ = sA ^ sB;

  localparam integer BIAS = (1 << (EXP_W-1)) - 1;

  wire signed [EXP_W+1:0] EA_ext = $signed({2'b00, eA});
  wire signed [EXP_W+1:0] EB_ext = $signed({2'b00, eB});
  wire signed [EXP_W+1:0] Eraw   = EA_ext + EB_ext - $signed(BIAS);

  // Producto de mantisas
  wire [PROD_W-1:0] P;
  fp_mantmul #(
    .FRAC_W (FRAC_W),
    .MANT_W (MANT_W),
    .PROD_W (PROD_W)
  ) MM (
    .fA (fA),
    .fB (fB),
    .P  (P)
  );

  // Normalización + redondeo
  wire [FP_W-1:0] z_mul;
  wire oflow, uflow_ftz;

  fp_normround #(
    .EXP_W  (EXP_W),
    .FRAC_W (FRAC_W),
    .FP_W   (FP_W),
    .MANT_W (MANT_W),
    .PROD_W (PROD_W)
  ) NR (
    .sZ   (sZ),
    .Eraw (Eraw),
    .P    (P),
    .z    (z_mul),
    .oflow(oflow),
    .uflow_ftz(uflow_ftz)
  );

  // 5) Mux final
  assign z = take_spec ? z_spec : z_mul;

endmodule
