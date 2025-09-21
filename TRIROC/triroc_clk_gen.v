
module triroc_clk_gen(
	input sys_clk,
	input sys_reset,

	output clk_160,
	output clk_40,
	output clk_20,
	output clk_5,

	output reg sync_reset
);
	wire clkfb, mmcm_locked;

	MMCME2_BASE #(
		.CLKIN1_PERIOD(10.0),   // if sys_clk = 100 MHz (10 ns period)
		.CLKFBOUT_MULT_F(16.0), // VCO = 100 * 16 = 1600 MHz
		.DIVCLK_DIVIDE(1),
		.CLKOUT0_DIVIDE_F(10.0),// 1600 / 10 = 160 MHz
		.CLKOUT1_DIVIDE(40),    // 1600 / 40 = 40 MHz
		.CLKOUT2_DIVIDE(80),     // 1600 / 80 = 40 MHz
		.CLKOUT3_DIVIDE(320)     // 1600 / 80 = 40 MHz
	) mmcm_inst (
		.CLKIN1(sys_clk),
		.CLKFBIN(clkfb),
		.RST(sys_reset),
		.CLKFBOUT(clkfb),
		.CLKOUT0(clk_160),
		.CLKOUT1(clk_40),
		.CLKOUT2(clk_20),
		.CLKOUT3B(clk_5),
		.LOCKED(mmcm_locked)
	);

	always @(posedge sys_clk) begin
		sync_reset <= sys_reset || (mmcm_locked == 0);
	end
endmodule