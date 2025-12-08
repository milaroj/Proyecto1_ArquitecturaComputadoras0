// fp_vector_alu.v
// ALU vectorial parametrizable basada en fp_add_vector, fp_mul_vector, fp_recip_vector

`include "fp_add_vector.v"
`include "fp_mul_vector.v"
`include "fp_recip_vector.v"

`timescale 1ns/1ps

module fp_vector_alu #(
  // Formato FP
  parameter integer EXP_W   = 5,
  parameter integer FRAC_W  = 10,
  parameter integer FP_W    = 1 + EXP_W + FRAC_W,

  // Vector
  parameter integer N_LANES = 2,
  parameter integer VEC_W   = N_LANES * FP_W,

  // Códigos de operación
  parameter [1:0] OP_ADD = 2'b00,
  parameter [1:0] OP_MUL = 2'b01,
  parameter [1:0] OP_RCP = 2'b10
)(
  input               RST,
  input               ENA,
  input  [VEC_W-1:0]  a,
  input  [VEC_W-1:0]  b,      // (no se usa en RCP)
  input  [1:0]        op_sel,

  output [VEC_W-1:0]  res,

  output              illegal_any,
  output              op_invalid_any,

  // Señales específicas por operación
  output              mul_illegal_sub,  // OR de subnormales en MUL
  output              mul_op_invalid,   // op_invalid_any de MUL
  output [N_LANES-1:0] rcp_illegal_vec  // {laneN-1, ..., lane0} de RCP
);

  // -------------------------
  // Instancias de los 3 DUTs vectoriales
  // -------------------------

  // Suma vectorial
  wire [VEC_W-1:0] add_res;
  fp_add_vector #(
    .EXP_W  (EXP_W),
    .FRAC_W (FRAC_W),
    .FP_W   (FP_W),
    .N_LANES(N_LANES),
    .VEC_W  (VEC_W)
  ) U_ADD (
    .RST   (RST),
    .ENA   (ENA),
    .a_vec (a),
    .b_vec (b),
    .z_vec (add_res)
  );

  // Multiplicación vectorial
  wire [VEC_W-1:0] mul_res;
  wire             mul_illegal_sub_w;
  wire             mul_op_invalid_w;

  fp_mul_vector #(
    .EXP_W  (EXP_W),
    .FRAC_W (FRAC_W),
    .FP_W   (FP_W),
    .N_LANES(N_LANES),
    .VEC_W  (VEC_W)
  ) U_MUL (
    .a_vec          (a),
    .b_vec          (b),
    .z_vec          (mul_res),
    .illegal_sub_any(mul_illegal_sub_w),
    .op_invalid_any (mul_op_invalid_w)
  );

  // Recíproco vectorial
  wire [VEC_W-1:0] rcp_res;
  wire [N_LANES-1:0] rcp_illegal_vec_w;
  wire             rcp_any_illegal_w;

  fp_recip_vector #(
    .EXP_W  (EXP_W),
    .FRAC_W (FRAC_W),
    .FP_W   (FP_W),
    .N_LANES(N_LANES),
    .VEC_W  (VEC_W)
  ) U_RCP (
    .a_vec       (a),
    .z_vec       (rcp_res),
    .illegal_lane(rcp_illegal_vec_w),
    .illegal_any (rcp_any_illegal_w)
  );

  // -------------------------
  // Multiplexor de resultados
  // -------------------------

  reg [VEC_W-1:0] res_r;
  always @* begin
    unique case (op_sel)
      OP_ADD: res_r = add_res;
      OP_MUL: res_r = mul_res;
      OP_RCP: res_r = rcp_res;
      default: res_r = {VEC_W{1'b0}};
    endcase
  end
  assign res = res_r;

  // -------------------------
  // Multiplexor de flags específicos
  // -------------------------

  reg mul_illegal_sub_r, mul_op_invalid_r;
  reg [N_LANES-1:0] rcp_illegal_vec_r;

  always @* begin
    mul_illegal_sub_r = 1'b0;
    mul_op_invalid_r  = 1'b0;
    rcp_illegal_vec_r = {N_LANES{1'b0}};

    unique case (op_sel)
      OP_MUL: begin
        mul_illegal_sub_r = mul_illegal_sub_w;
        mul_op_invalid_r  = mul_op_invalid_w;
      end
      OP_RCP: begin
        rcp_illegal_vec_r = rcp_illegal_vec_w;
      end
      default: ;
    endcase
  end

  assign mul_illegal_sub = mul_illegal_sub_r;
  assign mul_op_invalid  = mul_op_invalid_r;
  assign rcp_illegal_vec = rcp_illegal_vec_r;

  // -------------------------
  // Flags globales illegal_any y op_invalid_any
  // -------------------------

  reg illegal_any_r, op_invalid_any_r;
  always @* begin
    illegal_any_r    = 1'b0;
    op_invalid_any_r = 1'b0;

    unique case (op_sel)
      OP_MUL: begin
        illegal_any_r    = mul_illegal_sub_w | mul_op_invalid_w;
        op_invalid_any_r = mul_op_invalid_w;
      end
      OP_RCP: begin
        illegal_any_r    = rcp_any_illegal_w;
        op_invalid_any_r = 1'b0;
      end
      default: begin
        illegal_any_r    = 1'b0;
        op_invalid_any_r = 1'b0;
      end
    endcase
  end

  assign illegal_any    = illegal_any_r;
  assign op_invalid_any = op_invalid_any_r;

endmodule
