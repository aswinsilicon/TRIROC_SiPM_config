`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.09.2025 09:56:28
// Design Name: 
// Module Name: triroc_config1_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module triroc_config1_tb();

    // Parameters
    localparam WIDTH = 16; 

    reg  ck_sr;
    reg  rstb_sr;
    reg  sr_in;
    reg  select;
    reg  load_sc;
    reg  load_scd;
    
    wire sr_out;
    wire load_event_dac;
    wire load_event_dig;

    
    triroc_config_design #(
        .WIDTH(WIDTH),
        .reset_pattern({WIDTH{1'b0}})
    ) triroc_uut (
        .ck_sr(ck_sr),
        .rstb_sr(rstb_sr),
        .sr_in(sr_in),
        .sr_out(sr_out),
        .select(select),
        .load_sc(load_sc),
        .load_event(load_event_dac)
    );

    reg load_scd_d;
    reg load_event_dig_r;
    assign load_event_dig = load_event_dig_r;
    always @(posedge ck_sr or negedge rstb_sr) begin
        if (!rstb_sr) begin
            load_scd_d <= 1'b1;
            load_event_dig_r <= 1'b0;
        end else begin
            if (load_scd == 1'b0 && load_scd_d == 1'b1)
                load_event_dig_r <= 1'b1;
            else
                load_event_dig_r <= 1'b0;
            load_scd_d <= load_scd;
        end
    end

    
    initial ck_sr = 0;
    always #25 ck_sr = ~ck_sr;

    
    integer i;
    reg [WIDTH-1:0] data_to_shift = 16'b1101_1010_1111_0001;

    initial begin
        // Dump waves
        $dumpfile("triroc_config1_tb.vcd");
        $dumpvars(0, triroc_config1_tb);

        // Initial values
        rstb_sr = 0; sr_in = 0; select = 1; load_sc = 1; load_scd = 1;

        // Hold reset for a few cycles
        repeat(4) @(posedge ck_sr);
        rstb_sr = 1; // release reset

        // Shift data bits LSB first
        for (i = 0; i < WIDTH; i = i + 1) begin
            sr_in = data_to_shift[i];
            @(posedge ck_sr);
            @(negedge ck_sr); // wait full cycle to see sr_out update
        end

        // Pulse load_sc (active low) to latch DACs
        @(negedge ck_sr);
        load_sc = 0;
        @(posedge ck_sr);
        load_sc = 1;

        // Pulse load_scd (active low) to latch digital config
        @(negedge ck_sr);
        load_scd = 0;
        @(posedge ck_sr);
        load_scd = 1;

        // Observe sr_out bits shifting out
        repeat(10) @(posedge ck_sr);

        $finish;
    end

endmodule
