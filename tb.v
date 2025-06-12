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
        //u_cpu.inst_mem.mem[8'h00] = 32'b0100_000100_000001_000010_0000000000; // ADD x4, x1, x2
        //u_cpu.inst_mem.mem[8'h00] = 32'b0111_000100_000001_000010_0000000000; // SUB x4, x1, x2
        //u_cpu.inst_mem.mem[8'h00] = 32'b0110_000100_000001_111111_0000000000; // NEG x4, x1
        //u_cpu.inst_mem.mem[8'h00] = 32'b0101_000100_000001_0000000000000001; // INC x4, x1, y
        //u_cpu.inst_mem.mem[8'h00] = 32'b1110_000100_000001_111111_0000000000; // LD x4, x1
        //u_cpu.inst_mem.mem[8'h00] = 32'b0011_111111_000001_000010_1111111111; // ST x2, x1 (ST rt, rs)
        //u_cpu.inst_mem.mem[8'h00] = 32'b1000_111111_000001_111111_1111111111; // J x1
        //u_cpu.inst_mem.mem[8'h00] = 32'b1010_111111_000001_111111_1111111111; // JM x1
        //u_cpu.inst_mem.mem[8'h01] = 32'b1001_111111_000010_111111_1111111111; // BRZ x2
        //u_cpu.inst_mem.mem[8'h01] = 32'b1011_111111_000010_111111_1111111111; // BRN x2
        //u_cpu.inst_mem.mem[8'h00] = 32'b1111_000100_0000000000000000000010; // SVPC x4, 2 (PC+2 = 3)
        

        u_cpu.inst_mem.mem[0] = 32'b1111_001101_000000_000000_0000001011; // SVPC x13, end = PC+23 = 23
        u_cpu.inst_mem.mem[1] = 32'b1111_001110_000000_000000_0000010100; // SVPC x14, no_change = PC+20 = 21
        u_cpu.inst_mem.mem[2] = 32'b1111_001111_000000_000000_0000001000; // SVPC x15, loop = PC+8 = 10
        u_cpu.inst_mem.mem[3] = 32'b0100_000100_000001_000010_1111111111; // ADD x4, x1, x2
        u_cpu.inst_mem.mem[4] = 32'b00000000000000000000000000000000; //NOP
        u_cpu.inst_mem.mem[5] = 32'b00000000000000000000000000000000; //NOP
        u_cpu.inst_mem.mem[6] = 32'b1110_001010_000001_111111_1111111111; // LD x10, x4
        u_cpu.inst_mem.mem[7] = 32'b00000000000000000000000000000000; //NOP
        u_cpu.inst_mem.mem[8] = 32'b0101_000010_000010_000000_0000000001; // INC x2, x2, 1
        u_cpu.inst_mem.mem[9] = 32'b00000000000000000000000000000000; //NOP
        
        u_cpu.inst_mem.mem[10] = 32'b0111_001000_000011__000010_1111111111; // SUB x7, x3, x2, (loop)
        u_cpu.inst_mem.mem[11] = 32'b1011_000000_001101_000000_0000000000; // BRN x13
        u_cpu.inst_mem.mem[12] = 32'b0100_000100_000001_000010_1111111111; // ADD x4, x1, x2
        u_cpu.inst_mem.mem[13] = 32'b00000000000000000000000000000000; //NOP
        u_cpu.inst_mem.mem[14] = 32'b00000000000000000000000000000000; //NOP
        u_cpu.inst_mem.mem[15] = 32'b1110_000101_000100_111111_1111111111; // LD x5, x4
        u_cpu.inst_mem.mem[16] = 32'b00000000000000000000000000000000; //NOP
        u_cpu.inst_mem.mem[17] = 32'b0111_000111_001010_001001_1111111111; // SUB x7, x10, x5
        u_cpu.inst_mem.mem[18] = 32'b1011_000000_001110_111111_1111111111; // BRN x14
        u_cpu.inst_mem.mem[19] = 32'b0111_000000_000001_000001_1111111111; // SUB x0, x1, x1
        u_cpu.inst_mem.mem[20] = 32'b0100_001010_000101_000000_1111111111; // ADD x10, x5, x0
        
        u_cpu.inst_mem.mem[21] = 32'b0101_000010_000010_000001_1111111111; // INC x2, x2, 1 (no_change:)
        u_cpu.inst_mem.mem[22] = 32'b1000_000000_001111_111111_1111111111; // J x15
//        u_cpu.inst_mem.mem[13] = 32'b00000000000000000000000000000000; //NOP  (end)

//        u_cpu.inst_mem.mem[1] = 32'b00000000000000000000000000000000; //NOPS



        // Run simulation for a sufficient number of clock cycles
        #20; // Allow reset to propagate and PC to initialize to 0
            @(posedge clk);
		repeat (300) begin
		    @(posedge clk);
//		    $display("Time: %0t, PC: %0d, Instruction: %b", $time, u_cpu.pc_out, u_cpu.inst_out);
//		    $display("ALU Result (EX Stage): %0d", u_cpu.exmem_alu_result);
//		    $display("ALU Result (MEM/WB Stage): %0d", u_cpu.memwb_alu_result);
		end

           // --- Display d_mem content after simulation ---
        $display("\n--- Contents of Data Memory (d_mem) ---");
        // Loop through the first few relevant locations, or a specific range.
        // Adjust the loop bounds (0 to 10 here) based on which memory locations you expect to be used.
        for (integer i = 0; i < 10; i=i+1) begin
            // You need to know the instance name of data_mem inside pipelined_datapath.
            // Let's assume it's instantiated as 'u_data_mem' within 'pipelined_datapath'.
            // So the path would be u_cpu.u_data_mem.d_mem[i]
            // If you don't know the instance name, you'll need to check your pipelined_datapath module.
            $display("d_mem[%0d] = %0d (0x%0h)", i, u_cpu.data_mem.d_mem[i], u_cpu.data_mem.d_mem[i]);
        end
        $display("---------------------------------------");

        // Display the minimum value stored in register x10
        $display("\n--- Simulation Complete ---");
        $display("The minimum value found (x10): %0d", u_cpu.reg_file.rf[6'd10]); // MODIFIED: access x10
        $display("---------------------------");

        $finish; // End simulation
    end


endmodule
