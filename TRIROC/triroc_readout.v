

module triroc_readout(
	input	clk_160,
	input	clk_40,
	input	clk_80,
	input	clk_10,
	input	sync_reset,

    input	i_oc_Ton_Top,					//	"Transmit On for Top Manager"
    input	i_oc_Ton_0_15,					//	Transmit On for channel 0-15
    input	i_oc_Ton_16_31,					//	Transmit On for channel 16-31
    input	i_oc_Ton_48_63,					//	Transmit On for channel 48-63
    input	i_oc_Ton_32_47,					//	Transmit On for channel 32-47

    input	i_oc_NOR64_time,				//	"Time trigger 64-channel NOR"
    input	i_oc_NOR64_charge,				//	"Charge trigger 64-channel NOR"

	input	i_Dout_48_63n,				//	Data out for channel 48 - 63
	input	i_Dout_48_63p,				//
	input	i_Dout_32_47n,				//	Data out for channel 32 - 47
	input	i_Dout_32_47p,				//
	input	i_Dout_16_31n,				//	Data out for channel 16 - 31
	input	i_Dout_16_31p,				//
	input	i_Dout_0_15n,				//	Data out for channel 0 - 15
	input	i_Dout_0_15p,				//
	input	i_Dout_Topn,				//	"Data out for Top Manager: Global Time Stamp"
	input	i_Dout_Topp,				//

	output	o_val_evt_n,				//	"Time and Charge Trigger fast masking"
	output	o_val_evt_p,				//
	output	o_ck_160n,					//	160 MHz clock (Digital Core)
	output	o_ck_160p,					//
	output	o_ck_40n,					//	40 MHz clock (Time Stamp)
	output	o_ck_40p					//
);
	wire dout_48_63, dout_32_47, dout_16_31, dout_0_15, dout_top;

	reg val_evt;

	always @(posedge clk_40) begin
		if (sync_reset) begin
			val_evt <= 0;
		end else begin
			val_evt <= 1;
		end
	end


	wire s_rd_en_0_15;
	wire [7: 0] s_rd_0_15;
	wire s_rd_en_16_31;
	wire [7: 0] s_rd_16_31;
	wire s_rd_en_32_47;
	wire [7: 0] s_rd_32_47;
	wire s_rd_en_48_63;
	wire [7: 0] s_rd_48_63;

	wire global_rd_en;
	wire [16: 0] global_coarse_time;

	dtop_read u_ddout_top (
		.clk_80         (clk_80),
		.sync_reset     (sync_reset),

		.ton_top        (i_oc_Ton_Top),
		.dout_top       (dout_top),

		.rd_en          (global_rd_en),
		.coarse_time    (global_coarse_time)
	);


	dline_read u_dout_0_15 (
		.clk_80        (clk_80),
		.sync_reset    (sync_reset),

		.ton_top	   (i_oc_Ton_Top),

		.ton           (i_oc_Ton_0_15),
		.dout          (dout_0_15),

		.s_rd_en       (s_rd_en_0_15),
		.s_rd          (s_rd_0_15)
	);

	dline_read u_dout_16_31 (
		.clk_80        (clk_80),
		.sync_reset    (sync_reset),

		.ton_top	   (i_oc_Ton_Top),

		.ton           (i_oc_Ton_16_31),
		.dout          (dout_16_31),

		.s_rd_en       (s_rd_en_16_31),
		.s_rd          (s_rd_16_31)
	);

	dline_read u_dout_32_47 (
		.clk_80        (clk_80),
		.sync_reset    (sync_reset),

		.ton_top	   (i_oc_Ton_Top),

		.ton           (i_oc_Ton_32_47),
		.dout          (dout_32_47),

		.s_rd_en       (s_rd_en_32_47),
		.s_rd          (s_rd_32_47)
	);

	dline_read u_dout_48_63 (
		.clk_80        (clk_80),
		.sync_reset    (sync_reset),

		.ton_top	   (i_oc_Ton_Top),

		.ton           (i_oc_Ton_48_63),
		.dout          (dout_48_63),

		.s_rd_en       (s_rd_en_48_63),
		.s_rd          (s_rd_48_63)
	);


	IBUFDS #(.DIFF_TERM("TRUE"), .IOSTANDARD("LVDS")) ibuf_48_63 (
		.I(i_Dout_48_63p), .IB(i_Dout_48_63n), .O(dout_48_63)
	);
	IBUFDS #(.DIFF_TERM("TRUE"), .IOSTANDARD("LVDS")) ibuf_32_47 (
		.I(i_Dout_32_47p), .IB(i_Dout_32_47n), .O(dout_32_47)
	);
	IBUFDS #(.DIFF_TERM("TRUE"), .IOSTANDARD("LVDS")) ibuf_16_31 (
		.I(i_Dout_16_31p), .IB(i_Dout_16_31n), .O(dout_16_31)
	);
	IBUFDS #(.DIFF_TERM("TRUE"), .IOSTANDARD("LVDS")) ibuf_0_15 (
		.I(i_Dout_0_15p),  .IB(i_Dout_0_15n),  .O(dout_0_15)
	);
	IBUFDS #(.DIFF_TERM("TRUE"), .IOSTANDARD("LVDS")) ibuf_top (
		.I(i_Dout_Topp),   .IB(i_Dout_Topn),   .O(dout_top)
	);


	OBUFDS #(.IOSTANDARD("LVDS")) obuf_evt (
		.I(val_evt), .O(o_val_evt_p), .OB(o_val_evt_n)
	);

	OBUFDS #(.IOSTANDARD("LVDS")) obuf_ck160 (
		.I(clk_160), .O(o_ck_160p), .OB(o_ck_160n)
	);

	OBUFDS #(.IOSTANDARD("LVDS")) obuf_ck40 (
		.I(clk_40), .O(o_ck_40p), .OB(o_ck_40n)
	);
endmodule


module dtop_read(
	input clk_80,
	input sync_reset,

	input ton_top,
	input dout_top,

	output reg rd_en,
	output reg [16: 0] coarse_time
);
	reg	 [10: 0] val_prev;
	reg  [10: 0] val;

	reg [7: 0] f_state;
	reg [7: 0] f_ton_top;

	reg [5: 0] f_step_count;


	parameter FSM_GLOBAL_COARSE_TIME	= 8;

	parameter FSM_EXCEPTION				= 6;
	parameter FSM_IDLE					= 7;

	always @(posedge clk_80) begin
		if (sync_reset) begin
			f_state			<= FSM_IDLE;
			f_step_count	<= 0;
			f_ton_top			<= 0;

			coarse_time	<= 0;

			val			<= 0;
			val_prev	<= 0;
		end else begin
			val_prev		<= val;
			f_step_count	<= f_step_count - 1;
			val				<= (val << 1) | dout_top;

			if (ton_top == 0) begin
				f_ton_top <= 0;
			end

			if (rd_en) begin
				rd_en <= 0;
			end

			case (f_state)
				FSM_IDLE: begin
					if (ton_top) begin
						f_ton_top		<= 1;
						f_step_count	<= 16;
						f_state			<= FSM_GLOBAL_COARSE_TIME;
					end
				end

				FSM_GLOBAL_COARSE_TIME: begin
					if (f_step_count == 0) begin
						coarse_time <= val[16: 0];

						if (f_ton_top) begin
							rd_en	<= 1;
							f_state <= FSM_IDLE;
						end else begin
							f_state	<= FSM_EXCEPTION;
						end
					end
				end

				FSM_EXCEPTION: $finish;
			endcase
		end
	end
endmodule

module dline_read(
	input clk_80,
	input sync_reset,

	input ton_top,

	input ton,
	input dout,

	output reg s_rd_en,
	output reg [7: 0] s_rd
);
	reg	 [10: 0] val_prev;
	reg  [10: 0] val;


	reg b_wr_en;
	reg [4: 0] b_wr_addr;
	reg [4 + 10 - 1: 0] bram[0: 15];


	reg [7: 0] f_state;
	reg [7: 0] f_state_prev;
	reg [7: 0] f_ton;

	// reg f_bit;

	reg f_d;
	reg [3: 0] f_channel_no;
	reg [9: 0] f_coarse_time;

	reg [10: 0] f_fine_time;
	reg [10: 0] f_charge;

	reg [5: 0] f_step_count;


	parameter FSM_OP1_D_BIT			= 1;
	parameter FSM_OP1_CHANNEL_NO	= 2;
	parameter FSM_OP1_COARSE_TIME	= 3;

	parameter FSM_OP2_FINE_TIME		= 4;
	parameter FSM_OP2_CHARGE		= 5;

	parameter FSM_EXCEPTION			= 6;
	parameter FSM_IDLE				= 7;

	always @(posedge clk_80) begin
		if (sync_reset) begin
			f_state			<= FSM_IDLE;
			f_state_prev	<= 0;
			f_d				<= 0;
			f_channel_no	<= 0;
			f_coarse_time	<= 0;
			f_fine_time		<= 0;
			f_charge		<= 0;
			f_step_count	<= 0;
			f_ton			<= 0;

			val				<= 0;
			val_prev		<= 0;

			b_wr_addr		<= -1;
			b_wr_en			<= 0;
		end else begin
			f_state_prev	<= f_state;
			val_prev		<= val;
			f_step_count	<= f_step_count - 1;
			val				<= (val << 1) | dout;

			if (ton == 0) begin
				f_ton <= 0;
			end

			if (b_wr_en) begin
				b_wr_en <= 0;
			end

			case (f_state)
				FSM_IDLE: begin
					if (ton) begin
						f_ton			<= 1;

						if (ton_top) begin
							f_step_count <= 0;
							f_state <= FSM_OP1_D_BIT;
						end else begin
							f_step_count <= 10;
							f_state <= FSM_OP2_FINE_TIME;
						end
					end
				end

				FSM_OP1_D_BIT: begin
					if (f_step_count == 0) begin
						f_d <= val[0];

						f_step_count <= 3;
						f_state <= ton ? FSM_OP1_CHANNEL_NO: FSM_IDLE;
						f_ton <= ton;
					end
				end

				FSM_OP1_CHANNEL_NO: begin
					if (f_step_count == 0) begin
						f_channel_no <= val[3: 0];

						if (f_ton) begin
							b_wr_addr <= b_wr_addr + 1;

							if (f_d) begin
								f_step_count <= 9;
								f_state <= FSM_OP1_COARSE_TIME;
							end else begin
								b_wr_en <= 1;

								f_step_count <= 0;
								f_state <= FSM_OP1_D_BIT;
							end
						end else begin
							f_state <= FSM_EXCEPTION;
						end
					end
				end

				FSM_OP1_COARSE_TIME: begin
					if (f_step_count == 0) begin
						f_coarse_time <= val[9: 0];

						if (f_ton) begin
							b_wr_en <= 1;

							f_step_count <= 0;
							f_state <= FSM_OP1_D_BIT;
						end else begin
							f_state <= FSM_EXCEPTION;
						end
					end
				end


				FSM_OP2_FINE_TIME: begin
					if (f_step_count == 0) begin
						f_fine_time <= val[10: 0];

						f_step_count <= 10;
						f_state <= ton ? FSM_OP2_CHARGE: FSM_IDLE;
						f_ton <= ton;

						if (ton == 0) begin

						end
					end
				end

				FSM_OP2_CHARGE: begin
					if (f_step_count == 0) begin
						f_fine_time <= val[10: 0];

						if (f_ton) begin
							b_wr_addr <= b_wr_addr - 1;

							f_step_count <= 10;
							f_state <= FSM_OP2_FINE_TIME;
						end else begin
							f_state <= FSM_EXCEPTION;
						end
					end
				end

				FSM_EXCEPTION: $finish;
			endcase
		end
	end
endmodule
