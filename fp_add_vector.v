// fp_add_vector.v
// Módulo vectorial de suma en coma flotante

`include "fp_add_lane.v"

module fp_add_vector #(
    // Parámetros del formato
    parameter integer EXP_W   = 5,    // bits de exponente
    parameter integer FRAC_W  = 10,   // bits de fracción
    parameter integer FP_W    = 1 + EXP_W + FRAC_W, // ancho total del FP

    // Parámetros del vector
    parameter integer N_LANES = 2,                  // número de lanes
    parameter integer VEC_W   = N_LANES * FP_W      // ancho total del bus
)(
    input  wire             RST,    // se propaga a todos los lanes
    input  wire             ENA,    // se propaga a todos los lanes
    input  wire [VEC_W-1:0] a_vec,  // vector de operandos A
    input  wire [VEC_W-1:0] b_vec,  // vector de operandos B
    output wire [VEC_W-1:0] z_vec   // vector de resultados Z
);

    // Generador de lanes
    genvar i;
    generate
        for (i = 0; i < N_LANES; i = i + 1) begin : gen_add_lane
            // Señales internas para este lane
            wire [FP_W-1:0] a_lane;
            wire [FP_W-1:0] b_lane;
            wire [FP_W-1:0] z_lane;

            // Extraer el sub-vector correspondiente al lane i
            assign a_lane = a_vec[(i+1)*FP_W-1 : i*FP_W];
            assign b_lane = b_vec[(i+1)*FP_W-1 : i*FP_W];

            // Instancia del sumador escalar parametrizado
            fp_add_lane #(
                .EXP_W (EXP_W),
                .FRAC_W(FRAC_W),
                .FP_W  (FP_W)
            ) u_add_lane (
                .RST (RST),
                .ENA (ENA),
                .a   (a_lane),
                .b   (b_lane),
                .z   (z_lane)
            );

            // Empacar el resultado del lane i en la salida vectorial
            assign z_vec[(i+1)*FP_W-1 : i*FP_W] = z_lane;
        end
    endgenerate

endmodule
