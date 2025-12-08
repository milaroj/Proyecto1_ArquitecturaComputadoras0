// fp_add_shift_lr.v
module fp_add_shift_lr #(
    parameter integer RES_W   = 12, // 1 + (1+FRAC_W)
    parameter integer SHIFT_W = 4   // suficiente para 0..FRAC_W+1
)(
    input              RST,
    input              ENA,
    input              SEL,        // 1 = left, 0 = right
    input  [RES_W-1:0] A,
    input  [SHIFT_W-1:0] N,
    output reg [RES_W-1:0] Y
);
    // Limitar N a máximo RES_W-1
    wire [SHIFT_W-1:0] N_limited =
        (N > (RES_W-1)) ? (RES_W-1) : N;

    always @* begin
        if (RST) begin
            Y = {RES_W{1'b0}};
        end else if (ENA) begin
            if (SEL)
                Y = A << N_limited;
            else
                Y = A >> N_limited;
        end else begin
            Y = A;
        end
    end
endmodule
