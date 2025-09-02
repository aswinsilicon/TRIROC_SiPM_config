`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.09.2025 09:36:22
// Design Name: 
// Module Name: triroc_config_design
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


//triroc_config_design.v
//1256-bit shift register implementation targeting TRIROC slow-control interface
//Shifts on ck_sr posedge 
//sr_out     is driven from an extra flop updated on ck_sr negedge 
//rstb_sr    is active-low reset: when 0, shift register is loaded with RESET_PATTERN.
//load_sc    is active-low load for input DACs; this module detects falling edge and
//  generates a one-cycle synchronous pulse 'load_event' on the next posedge ck_sr.


module triroc_config_design #(
    parameter integer WIDTH = 1256,
    //providing a default reset pattern width    
    parameter [WIDTH-1:0] reset_pattern = {WIDTH{1'b0}}
)(
    input  wire               ck_sr,     //shift clock (<10MHz)
    input  wire               rstb_sr,   //active-low reset (when 0 => load default values)
    input  wire               sr_in,     //serial data in (to be shifted)
    output wire               sr_out,    //serial data out (extra ff add on falling edge)
    input  wire               select,    //select: '1' => Slow Control, '0' => Probe/Read
    input  wire               load_sc,   //active-low load signal for input DACs
    output reg                load_event //one-clock synchronous pulse when load_sc asserted low on next posedge ck_sr
);

    //defining internal shift register
    reg [WIDTH-1:0] shift_reg;
    //defining extra ff for sr_out updated on negedge ck_sr
    reg sr_out_ff;

    //defining sample load_sc for edge detection (synchronous to ck_sr)
    reg load_sc_d;

    //Shift on positive edge (leading edge)
    //rstb_sr is active low: when rstb_sr==0 we load reset_pattern
    always @(posedge ck_sr or negedge rstb_sr) begin
        if (!rstb_sr) begin
            //if rstb_sr is 0:
            //load defaults
            shift_reg <= reset_pattern;
            load_sc_d <= 1'b1;    //initially assume released
            load_event <= 1'b0;
        end else begin
            //if rstb_sr is 1:
            //shift operation: LSB-first shift: new bit becomes shift_reg[0],
            //data moves toward MSB (so sr_out is shift_reg[WIDTH-1]).
            shift_reg <= {shift_reg[WIDTH-2:0], sr_in};

            //detect falling edge of load_sc (active low). We generate a single-cycle pulse
            //       (synchronous to ck_sr) the cycle after we see load_sc asserted low.
            //We use previous sampled value load_sc_d to detect edge.
            if (load_sc == 1'b0 && load_sc_d == 1'b1) begin
                load_event <= 1'b1;   //one-cycle pulse to signal load
            end else begin
                load_event <= 1'b0;
            end
            load_sc_d <= load_sc;
        end
    end

    //sr_out is fed from an extra ff that updates on falling edge of ck_sr
    //The extra ff samples the MSB of the shift register.
    always @(negedge ck_sr or negedge rstb_sr) begin
        if (!rstb_sr) begin
            sr_out_ff <= reset_pattern[WIDTH-1];
        end else begin
            sr_out_ff <= shift_reg[WIDTH-1];
        end
    end

    assign sr_out = sr_out_ff;

endmodule

