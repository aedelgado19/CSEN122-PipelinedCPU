// =========================================================================
// Testbench
// =========================================================================

module tb_pipelined_cpu;

    // Clock and Reset signals
    reg clk;
    reg reset;

    // Instantiate the top-level pipelined_datapath module
    pipelined_datapath u_cpu (
        .clk(clk),
        .reset(reset)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period (100 MHz)
    end

    // Testbench Logic
    initial begin
        // Initialize signals
        reset = 1;

        // Apply reset
        #10 reset = 0;

        // Load instructions into instruction memory of the CPU
        // Accessing internal 'mem' of inst_mem module inside pipelined_datapath
	u_cpu.inst_mem.mem[8'h00] = 32'b1111_001101_000000_011110_0000000000; // SVPC x13, 29 (PC+27 = 0x1B = done)
	u_cpu.inst_mem.mem[8'h01] = 32'b1111_001110_000000_010110_0000000000; // SVPC x14, 22 (PC+22 = 0x17 = no_change)
	u_cpu.inst_mem.mem[8'h02] = 32'b1111_001111_000000_000110_0000000000; // SVPC x15, 6 (PC+6 = 0x08 = loop)
	u_cpu.inst_mem.mem[8'h03] = 32'b0100_000100_000001_000010_0000000000; // ADD x4, x1, x2
	u_cpu.inst_mem.mem[8'h04] = 32'b00000000000000000000000000000000; // NOP
	u_cpu.inst_mem.mem[8'h05] = 32'b1110_001010_000000_000100_0000000000; // LD x10, x4
	u_cpu.inst_mem.mem[8'h06] = 32'b00000000000000000000000000000000; // NOP
	u_cpu.inst_mem.mem[8'h07] = 32'b0101_000010_000010_000001_0000000000; // INC x2, x2, 1
	u_cpu.inst_mem.mem[8'h08] = 32'b00000000000000000000000000000000; // NOP (loop:)
	u_cpu.inst_mem.mem[8'h09] = 32'b0111_000111_000011__000010_0000000000; // SUB x7, x3, x2
	u_cpu.inst_mem.mem[8'h0A] = 32'b1011_000000_001101_000000_0000000000; // BRN x13
	u_cpu.inst_mem.mem[8'h0B] = 32'b00000000000000000000000000000000; // NOP (delay slot)
	u_cpu.inst_mem.mem[8'h0C] = 32'b00000000000000000000000000000000; // NOP (delay slot)
	u_cpu.inst_mem.mem[8'h0D] = 32'b0100_000100_000001_000010_0000000000; // ADD x4, x1, x2
	u_cpu.inst_mem.mem[8'h0E] = 32'b00000000000000000000000000000000; // NOP
	u_cpu.inst_mem.mem[8'h0F] = 32'b1110_000101_000100_000000_0000000000; // LD x5, x4
	u_cpu.inst_mem.mem[8'h10] = 32'b00000000000000000000000000000000; // NOP
	u_cpu.inst_mem.mem[8'h11] = 32'b0111_000111_001010_000101_0000000000; // SUB x7, x10, x5
	u_cpu.inst_mem.mem[8'h12] = 32'b1011_000000_001110_000000_0000000000; // BRN x14
	u_cpu.inst_mem.mem[8'h13] = 32'b00000000000000000000000000000000; // NOP (delay slot)
	u_cpu.inst_mem.mem[8'h14] = 32'b00000000000000000000000000000000; // NOP (delay slot)
	u_cpu.inst_mem.mem[8'h15] = 32'b0111_000000_000001_000001_0000000000; // SUB x0, x1, x1
	u_cpu.inst_mem.mem[8'h16] = 32'b0100_001010_000101_000000_0000000000; // ADD x10, x5, x0
	u_cpu.inst_mem.mem[8'h17] = 32'b0101_000010_000010_000001_0000000000; // INC x2, x2, 1 (no_change:)
	u_cpu.inst_mem.mem[8'h18] = 32'b1000_000000_001111_000000_0000000000; // J x15
	u_cpu.inst_mem.mem[8'h19] = 32'b00000000000000000000000000000000; // NOP (delay slot)
	u_cpu.inst_mem.mem[8'h1A] = 32'b00000000000000000000000000000000; // NOP (delay slot)
	u_cpu.inst_mem.mem[8'h1B] = 32'b00000000000000000000000000000000; // NOP (delay slot)
	u_cpu.inst_mem.mem[8'h1C] = 32'b00000000000000000000000000000000; // NOP (delay slot)


        // Run simulation for a sufficient number of clock cycles
        #20; // Allow reset to propagate and PC to initialize to 0
            @(posedge clk);
		repeat (50) begin
		    @(posedge clk);
//		    $display("Time: %0t, PC: %0d, Instruction: %b", $time, u_cpu.pc_out, u_cpu.inst_out);
//		    $display("ALU Result (EX Stage): %0d", u_cpu.exmem_alu_result);
//		    $display("ALU Result (MEM/WB Stage): %0d", u_cpu.memwb_alu_result);
		end

        // Display the minimum value stored in register x10
        $display("\n--- Simulation Complete ---");
        $display("The minimum value found (x10): %0d", u_cpu.reg_file.rf[6'd10]); // MODIFIED: access x10
        $display("---------------------------");

        $finish; // End simulation
    end


endmodule
