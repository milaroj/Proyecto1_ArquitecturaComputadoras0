// fp_special_mul.v
// Casos especiales de multiplicación FP genérico

`ifndef FP_SPECIAL_MUL_V
`define FP_SPECIAL_MUL_V

module fp_special_mul #(
  parameter integer EXP_W   = 5,
  parameter integer FRAC_W  = 10,
  parameter integer FP_W    = 1 + EXP_W + FRAC_W,
  parameter [FP_W-1:0] ERR_CODE = {1'b0, {EXP_W{1'b1}}, {1'b1, {FRAC_W-1{1'b0}}}} 
)(
  // A
  input               sA,
  input  [EXP_W-1:0]  eA,
  input  [FRAC_W-1:0] fA,
  input               is_zeroA,
  input               is_infA,
  input               is_nanA,
  input               is_subA,

  // B
  input               sB,
  input  [EXP_W-1:0]  eB,
  input  [FRAC_W-1:0] fB,
  input               is_zeroB,
  input               is_infB,
  input               is_nanB,
  input               is_subB,

  // Salidas
  output [FP_W-1:0]   z_out,
  output              use_special,
  output              illegal_input,
  output              op_invalid
);

  // Signo para los casos especiales válidos
  wire sZ = sA ^ sB;

  // Entradas no permitidas (NaN o subnormal)
  assign illegal_input = is_nanA | is_nanB | is_subA | is_subB;

  // ∞ × 0 => operación inválida
  wire inf_times_zero = (is_infA & is_zeroB) | (is_zeroA & is_infB);
  assign op_invalid = inf_times_zero;

  // Casos especiales válidos
  wire inf_times_finite =
      (is_infA & ~is_zeroB & ~is_infB & ~is_nanB & ~is_subB) |
      (is_infB & ~is_zeroA & ~is_infA & ~is_nanA & ~is_subA);

  wire zero_times_finite =
      (is_zeroA & ~is_zeroB & ~is_infB & ~is_nanB & ~is_subB) |
      (is_zeroB & ~is_zeroA & ~is_infA & ~is_nanA & ~is_subA);

  // Patrones empacados
  wire [FP_W-1:0] INF = {sZ, {EXP_W{1'b1}},  {FRAC_W{1'b0}}};
  wire [FP_W-1:0] ZER = {sZ, {EXP_W{1'b0}},  {FRAC_W{1'b0}}};

  // Selección de salida
  assign use_special =
         illegal_input |
         op_invalid    |
         inf_times_finite |
         zero_times_finite;

  assign z_out =
         illegal_input    ? ERR_CODE :
         op_invalid       ? ERR_CODE :
         inf_times_finite ? INF      :
         zero_times_finite? ZER      :
                            {FP_W{1'b0}}; //

endmodule

`endif
