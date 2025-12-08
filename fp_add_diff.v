// fp_add_diff.v
module fp_add_diff #(
    parameter integer EXP_W = 5
)(
    input  [EXP_W-1:0] EA,
    input  [EXP_W-1:0] EB,
    output [EXP_W-1:0] diff,
    output             s      // 0: EA>=EB, 1: EA<EB
);
    assign diff = (EA >= EB) ? (EA - EB) : (EB - EA);
    assign s    = (EA >= EB) ? 1'b0      : 1'b1;
endmodule
