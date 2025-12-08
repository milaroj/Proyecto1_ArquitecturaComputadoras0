// fp_mul_vector.v
// Módulo vectorial de multiplicación en coma flotante

module fp_mul_vector #(
    // Formato FP
    parameter integer EXP_W   = 5,
    parameter integer FRAC_W  = 10,
    parameter integer FP_W    = 1 + EXP_W + FRAC_W,

    // Vector
    parameter integer N_LANES = 2,
    parameter integer VEC_W   = N_LANES * FP_W
)(
    input  wire [VEC_W-1:0] a_vec,
    input  wire [VEC_W-1:0] b_vec,
    output wire [VEC_W-1:0] z_vec,
    output wire             illegal_sub_any,
    output wire             op_invalid_any
);

    // Señales internas de flags por lane
    wire [N_LANES-1:0] illegal_sub_lane;
    wire [N_LANES-1:0] op_invalid_lane;

    // OR global de flags
    assign illegal_sub_any = |illegal_sub_lane;
    assign op_invalid_any  = |op_invalid_lane;

    genvar i;
    generate
        for (i = 0; i < N_LANES; i = i + 1) begin : gen_mul_lane
            wire [FP_W-1:0] a_lane;
            wire [FP_W-1:0] b_lane;
            wire [FP_W-1:0] z_lane;

            // Extraer sub-vectores para este lane
            assign a_lane = a_vec[(i+1)*FP_W-1 : i*FP_W];
            assign b_lane = b_vec[(i+1)*FP_W-1 : i*FP_W];

            // Instancia del lane genérico (NUEVO)
            fp_mul_lane #(
                .EXP_W (EXP_W),
                .FRAC_W(FRAC_W),
                .FP_W  (FP_W)
            ) u_mul_lane (
                .a             (a_lane),
                .b             (b_lane),
                .z             (z_lane),
                .illegal_sub_in(illegal_sub_lane[i]),
                .op_invalid    (op_invalid_lane[i])
            );

            // Empacar resultado de este lane
            assign z_vec[(i+1)*FP_W-1 : i*FP_W] = z_lane;
        end
    endgenerate

endmodule
