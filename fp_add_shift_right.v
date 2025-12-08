// fp_add_shift_right.v
module fp_add_shift_right #(
    parameter integer MANT_W = 11, // 1+FRAC_W
    parameter integer N_W    = 5   // ancho del desplazamiento
)(
    input              RST,
    input              ENA,
    input              SEL,       // 1 = shift izquierda, 0 = derecha
    input  [MANT_W-1:0] A,
    input  [N_W-1:0]    N,
    output reg [MANT_W-1:0] Y
);
    always @* begin
        if (RST) begin
            Y = {MANT_W{1'b0}};
        end else if (ENA) begin
            if (SEL) begin
                Y = A << N;
            end else begin
                // Si N >= MANT_W, todo se pierde
                if (N >= MANT_W[N_W-1:0])
                    Y = {MANT_W{1'b0}};
                else
                    Y = A >> N;
            end
        end else begin
            Y = A;
        end
    end
endmodule
