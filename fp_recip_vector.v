// fp_recip_vector.v
// Módulo vectorial de recíproco en coma flotante (paramétrico)
`include "fp_recip_lane.v"

module fp_recip_vector #(
    parameter integer EXP_W   = 5,
    parameter integer FRAC_W  = 10,
    parameter integer FP_W    = 1 + EXP_W + FRAC_W,
    parameter integer N_LANES = 2,
    parameter integer VEC_W   = N_LANES * FP_W
)(
    input  wire             [VEC_W-1:0] a_vec,
    output wire             [VEC_W-1:0] z_vec,
    output wire             [N_LANES-1:0] illegal_lane, // por lane
    output wire                         illegal_any     // OR de todos
);

    assign illegal_any = |illegal_lane;

    genvar i;
    generate
        for (i = 0; i < N_LANES; i = i + 1) begin : gen_rcp_lane
            wire [FP_W-1:0] a_lane;
            wire [FP_W-1:0] z_lane;

            // Extraer el subvector de entrada
            assign a_lane = a_vec[(i+1)*FP_W-1 : i*FP_W];

       fp_recip_lane #(
      .EXP_W (EXP_W),
      .FRAC_W(FRAC_W),
      .FP_W  (FP_W)
    ) u_recip (
      .a            (a_lane),
      .z            (z_lane),
         .illegal_input(illegal_lane[i])
    );


            // Empacar resultado
            assign z_vec[(i+1)*FP_W-1 : i*FP_W] = z_lane;
        end
    endgenerate

endmodule
