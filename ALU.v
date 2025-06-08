module twoToOne(B, sel, out);
    input B, sel;
    output out;
    wire w0, w1;

    assign w0 = B & ~sel;
    assign w1 = 1'b0 & sel;
    assign out = w0 | w1;
endmodule

module threeToOne(A, negA, sel, out, one);
    input A, negA, one;
    input [1:0] sel;
    output out;
    wire w0, w1, w2;

    assign w0 = A & ~sel[1] & ~sel[0];
    assign w1 = one & ~sel[1] & sel[0];
    assign w2 = negA & sel[1] & ~sel[0];
    assign out = w0 | w1 | w2;
endmodule

module oneBitAdder(A, B, Cin, Cout, S);
    input A, B, Cin;
    output S, Cout;
    wire w0, w1, w2;

    assign w0 = A ^ B;
    assign S  = w0 ^ Cin;
    assign w1 = w0 & Cin;
    assign w2 = A & B;
    assign Cout = w1 | w2;
endmodule

module fullAdder(A, B, Cout, sum);
    input [31:0] A, B;
    output [31:0] sum;
    output Cout;

    wire [31:0] carry;
    oneBitAdder a0 (A[0], B[0], 1'b0, carry[0], sum[0]);

    genvar i;
    generate
        for (i = 1; i < 32; i = i + 1) begin : a
            oneBitAdder a1 (A[i], B[i], carry[i-1], carry[i], sum[i]);
        end
    endgenerate
    assign Cout = carry[31];
endmodule

module negate(A, out);
    input [31:0] A;
    output [31:0] out;
    assign out = ~A + 1'b1;
endmodule


module ALU(A, B, add, inc, neg, sub, out, Z, N);
    input [31:0] A, B;
    input add, inc, neg, sub;
    output [31:0] out;
    output Z, N;

    wire [31:0] twos_comp_A;
    wire [31:0] outA, outB, adderout;
    wire [1:0] select;
    wire not_sub;
    wire Cout;
    wire [31:0] one;

    negate n(A, twos_comp_A);

    //3:1 mux select signals
    not n1(not_sub, sub);
    and a1(select[0], inc, not_sub);
    nor n2(select[1], add, inc);

    //1 signal for the 3:1 muxes, only the 0th bit =1 if incrementing
    //check if inc = 1 and sub is off bc otherwise sub interferes w mux creation below
    assign one = (inc & ~sub) ? 32'b1 : 32'b0;

    //make 3:1 muxes
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : m
            threeToOne mux31 (A[i], twos_comp_A[i], select, outA[i], one[i]);
        end
    endgenerate

    //2:1 muxes
    generate
        for (i = 0; i < 32; i = i + 1) begin : m2
            twoToOne mux21 (B[i], neg, outB[i]);
        end
    endgenerate

    fullAdder a(outA, outB, Cout, adderout);
    assign out = adderout;

    assign Z = (out == 32'b0) ? 1'b1 : 1'b0;
    assign N = out[31] ? 1'b1 : 1'b0;
endmodule
