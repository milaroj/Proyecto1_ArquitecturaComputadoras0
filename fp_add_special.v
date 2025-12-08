// fp_add_special.v
// Manejo de casos especiales para suma FP genérica (NaN, Inf, ceros, dif. grande)

module fp_add_special #(
    parameter integer EXP_W  = 5,
    parameter integer FRAC_W = 10,
    parameter integer FP_W   = 1 + EXP_W + FRAC_W
)(
    input  [FP_W-1:0] A,
    input  [FP_W-1:0] B,
    input  [FP_W-1:0] normal_result,
    output reg [FP_W-1:0] final_result,
    output reg            special_case
);

    localparam integer SIGN_BIT = FP_W-1;
    localparam integer EXP_MSB  = FRAC_W + EXP_W - 1;
    localparam integer EXP_LSB  = FRAC_W;

    // qNaN canónico: exp=all1, MSB de mantisa = 1
    localparam [FP_W-1:0] QNAN  =
        {1'b0, {EXP_W{1'b1}}, {1'b1, {FRAC_W-1{1'b0}}}};
    localparam [FP_W-1:0] PZERO = {FP_W{1'b0}}; // +0

    // Campos de A
    wire [EXP_W-1:0]  expA  = A[EXP_MSB : EXP_LSB];
    wire [FRAC_W-1:0] fracA = A[FRAC_W-1:0];

    // Campos de B
    wire [EXP_W-1:0]  expB  = B[EXP_MSB : EXP_LSB];
    wire [FRAC_W-1:0] fracB = B[FRAC_W-1:0];

    // Campos de normal_result
    wire [EXP_W-1:0]  expNR  = normal_result[EXP_MSB : EXP_LSB];
    wire [FRAC_W-1:0] fracNR = normal_result[FRAC_W-1:0];

    // Clasificación de A y B
    wire a_is_zero = (A[FP_W-2:0] == {FP_W-1{1'b0}});
    wire b_is_zero = (B[FP_W-2:0] == {FP_W-1{1'b0}});

    wire a_is_inf  = (&expA) && (fracA == {FRAC_W{1'b0}});
    wire b_is_inf  = (&expB) && (fracB == {FRAC_W{1'b0}});

    wire a_is_nan  = (&expA) && (fracA != {FRAC_W{1'b0}});
    wire b_is_nan  = (&expB) && (fracB != {FRAC_W{1'b0}});

    // Clasificación del resultado normalizado
    wire nr_is_inf = (&expNR) && (fracNR == {FRAC_W{1'b0}});
    wire nr_is_nan = (&expNR) && (fracNR != {FRAC_W{1'b0}});

    // Diferencia significativa de exponentes
    wire [EXP_W-1:0] exp_diff =
        (expA > expB) ? (expA - expB) : (expB - expA);

    // Umbral = FRAC_W (igual que "10" en fp16: 10 bits de mantisa)
    localparam [EXP_W-1:0] SIG_DIFF_TH =
        (FRAC_W > ((1<<EXP_W)-1)) ? {EXP_W{1'b1}} : FRAC_W[EXP_W-1:0];

    wire significant_difference = (exp_diff > SIG_DIFF_TH);

    always @(*) begin
        // Por defecto asumimos "caso especial";
        // anulamos más abajo si es caso normal
        special_case = 1'b1;

        // 1) NaN en la entrada -> qNaN
        if (a_is_nan || b_is_nan) begin
            final_result = QNAN;
        end

        // 2) Inf con Inf
        else if (a_is_inf && b_is_inf) begin
            if (A[SIGN_BIT] == B[SIGN_BIT]) begin
                // +Inf + +Inf / -Inf + -Inf
                final_result = A;
            end else begin
                // +Inf + -Inf = NaN
                final_result = QNAN;
            end
        end

        // 3) Inf con finito -> Inf
        else if (a_is_inf || b_is_inf) begin
            final_result = a_is_inf ? A : B;
        end

        // 4) Cero con cero
        else if (a_is_zero && b_is_zero) begin
            // Si los signos coinciden, conserva uno; si no, usa +0
            final_result = (A[SIGN_BIT] == B[SIGN_BIT]) ? A : PZERO;
        end

        // 5) Cero con número -> número
        else if (a_is_zero) begin
            final_result = B;
        end else if (b_is_zero) begin
            final_result = A;
        end

        // 6) Diferencia grande de exponentes -> domina el mayor
        else if (significant_difference) begin
            final_result = (expA > expB) ? A : B;
        end

        // 7) Si el resultado normalizado ya es NaN/Inf, respétalo
        else if (nr_is_nan) begin
            final_result = QNAN;
        end else if (nr_is_inf) begin
            final_result = normal_result;
        end

        // 8) Caso normal
        else begin
            final_result = normal_result;
            special_case = 1'b0;
        end
    end

endmodule
