// fp_normround.v

module fp_normround #(
  parameter integer EXP_W   = 5,
  parameter integer FRAC_W  = 10,
  parameter integer FP_W    = 1 + EXP_W + FRAC_W,
  parameter integer MANT_W  = FRAC_W + 1,
  parameter integer PROD_W  = 2 * MANT_W
)(
  input                    sZ,    
  input  signed [EXP_W+1:0] Eraw,   
  input  [PROD_W-1:0]      P,

  output [FP_W-1:0]        z,
  output                   oflow,
  output                   uflow_ftz
);
  // 1) Normalización
  reg signed [EXP_W+1:0] Enorm;
  reg [PROD_W-1:0]       Pnorm;

  always @* begin
    if (P[PROD_W-1]) begin
      Pnorm = P >> 1;
      Enorm = Eraw + $signed(1);
    end else begin
      Pnorm = P;
      Enorm = Eraw;
    end
  end

  // 2) GRS y redondeo
  localparam integer INT_BIT   = PROD_W - 2;
  localparam integer FRAC_MSB  = INT_BIT - 1;
  localparam integer FRAC_LSB  = INT_BIT - FRAC_W;

  wire [FRAC_W-1:0] frac   = Pnorm[FRAC_MSB : FRAC_LSB];
  wire              guard  = Pnorm[FRAC_LSB-1];
  wire              roundb = Pnorm[FRAC_LSB-2];
  wire              sticky = |Pnorm[FRAC_LSB-3:0];

  wire              incr   = guard & (roundb | sticky | frac[0]);
  wire [FRAC_W:0]   frac_plus = {1'b0, frac} + incr;

  reg [FRAC_W-1:0]  frac_r;
  reg signed [EXP_W+1:0] Eadj;

  always @* begin
    if (frac_plus[FRAC_W]) begin
      // carry → otro shift de 1 y E+1
      frac_r = {FRAC_W{1'b0}};
      Eadj   = Enorm + $signed(1);
    end else begin
      frac_r = frac_plus[FRAC_W-1:0];
      Eadj   = Enorm;
    end
  end

  // 3) Overflow / underflow
  localparam integer EXP_INF    = (1 << EXP_W) - 1;  // código de INF/NaN
  localparam integer MIN_NORM_E = 1;                 // exponente real mínimo normal

  assign oflow     = (Eadj >= $signed(EXP_INF)); // → INF
  assign uflow_ftz = (Eadj <= 0);                // → flush-to-zero

  wire [EXP_W-1:0] exp_field = Eadj[EXP_W-1:0];

  wire [FP_W-1:0] Z_INF = {sZ, {EXP_W{1'b1}},  {FRAC_W{1'b0}}};
  wire [FP_W-1:0] Z_ZER = {sZ, {EXP_W{1'b0}},  {FRAC_W{1'b0}}};
  wire [FP_W-1:0] Z_NRM = {sZ, exp_field,      frac_r};

  assign z = oflow     ? Z_INF :
             uflow_ftz ? Z_ZER :
                         Z_NRM;
endmodule
