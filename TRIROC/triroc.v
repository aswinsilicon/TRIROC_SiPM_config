

module i_triroc(
    input	sys_clk,
    input	sys_reset,

    input	i_oc_Ton_Top,					//	"Transmit On for Top Manager"
    input	i_oc_Ton_0_15,					//	Transmit On for channel 0-15
    input	i_oc_Ton_16_31,					//	Transmit On for channel 16-31
    input	i_oc_Ton_48_63,					//	Transmit On for channel 48-63
    input	i_oc_Ton_32_47,					//	Transmit On for channel 32-47
    input	i_oc_NOR64_time,				//	"Time trigger 64-channel NOR"
    input	i_oc_NOR64_charge,				//	"Charge trigger 64-channel NOR"

    input	i_lvcs_D_probe,					//	Digital signals probe(monitoring)
    input	i_lvcs_Trig_MUX,				//	"Time Trigger multiplexed output"
    input	i_lvcs_sr_out,					//	"Shift Output for Slow Control registers (select='1') or Probe registers (select='0')"

    output	o_lvcs_pwron_dac,				//	Dual 10-bit DACs power on
    output	o_lvcs_hold,					//	External ADC Hold input
    output	o_lvcs_ext_trig,				//	External Time Trigger input
    output	o_lvcs_pwron_a,					//	Analog core power on
    output	o_lvcs_pwron_adc,				//	ADC power on
    output	o_lvcs_OvfCptTop,				//	Digital core top manager counter overflow
    output	o_lvcs_resetb,					//	Digital core reset
    output	o_lvcs_ForceConvb,				//	"Digital core force conversion external input"
    output	o_lvcs_RazChn,					//	"Digital core channel trigger reset external input"
    output	o_lvcs_StartSyst,				//	"Digital core start conversion external input"
    output	o_lvcs_pwron_d,					//	Digital part (LVDS transmitter) power on
    output	o_lvcs_sr_in,					//	"Shift Input for Slow Control registers (select='1') or Probe registers (select='0')"
    output	o_lvcs_rstb_sr,					//	"Reset for Slow Control registers (select='1') or Probe registers (select='0')"
    output	o_lvcs_ck_sr,					//	"Clk for Slow Control registers (select='1') or Probe registers (select='0')"
    output	o_lvcs_select,					//	"Select signal for ck_read, ck_sr, rstb_sr,,sr_in and sr_out"
    output	o_lvcs_load_sc,					//	Slow Control load signal for input DACs
    output	o_lvcs_ck_read,					//	"Clk for bias (select='1') or Read (select='0') registers"
    output	o_lvcs_sel_monitoring,			//	"Select leakage current/temperature monitoring"

    input	i_lvds_Dout_48_63n,				//	Data out for channel 48 - 63
    input	i_lvds_Dout_48_63p,				//
    input	i_lvds_Dout_32_47n,				//	Data out for channel 32 - 47
    input	i_lvds_Dout_32_47p,				//
    input	i_lvds_Dout_16_31n,				//	Data out for channel 16 - 31
    input	i_lvds_Dout_16_31p,				//
    input	i_lvds_Dout_0_15n,				//	Data out for channel 0 - 15
    input	i_lvds_Dout_0_15p,				//
    input	i_lvds_Dout_Topn,				//	"Data out for Top Manager: Global Time Stamp"
    input	i_lvds_Dout_Topp,				//

    output	o_lvds_val_evt_n,				//	"Time and Charge Trigger fast masking"
    output	o_lvds_val_evt_p,				//
    output	o_lvds_ck_160n,					//	160 MHz clock (Digital Core)
    output	o_lvds_ck_160p,					//
    output	o_lvds_ck_40n,					//	40 MHz clock (Time Stamp)
    output	o_lvds_ck_40p					//
);
    wire clk_160, clk_40, clk_20, clk_5;

    wire sync_reset;

    triroc_clk_gen u_triroc_clk_gen (
        .sys_clk       (sys_clk),
        .sys_reset     (sys_reset),

        .clk_160       (clk_160),
        .clk_40        (clk_40),
        .clk_20        (clk_20),
        .clk_5         (clk_5),

        .sync_reset    (sync_reset)
    );


    localparam SR_WIDTH = 1256;

    triroc_slow_cntrl #(
        .WIDTH            (SR_WIDTH),				//providing a default reset pattern width
        .reset_pattern    ({SR_WIDTH{1'b0}})
    ) u_triroc_slow_cntrl (
        .ck_sr            (o_lvcs_ck_sr),			//shift clock (<10MHz)
        .rstb_sr          (o_lvcs_rstb_sr),			//active-low reset (when 0 => load default values)
        .sr_in            (o_lvcs_sr_in),			//serial data in (to be shifted)
        .sr_out           (i_lvcs_sr_out),			//serial data out (extra ff add on falling edge)
        .select           (o_lvcs_select),			//select: '1' => Slow Control, '0' => Probe/Read
        .load_sc          (o_lvcs_load_sc),			//active-low load signal for input DACs
        .load_event       ()						//one-clock synchronous pulse when load_sc asserted low on next posedge ck_sr
    );


    triroc_readout u_triroc_readout (
        // .sys_clk          (sys_clk),
        .clk_160            (clk_160),
        .clk_40             (clk_40),
        .clk_20             (clk_20),
        .sync_reset         (sync_reset),

        .i_Dout_48_63n    (i_lvds_Dout_48_63n),			//	Data out for channel 48 - 63
        .i_Dout_48_63p    (i_lvds_Dout_48_63p),			//
        .i_Dout_32_47n    (i_lvds_Dout_32_47n),			//	Data out for channel 32 - 47
        .i_Dout_32_47p    (i_lvds_Dout_32_47p),			//
        .i_Dout_16_31n    (i_lvds_Dout_16_31n),			//	Data out for channel 16 - 31
        .i_Dout_16_31p    (i_lvds_Dout_16_31p),			//
        .i_Dout_0_15n     (i_lvds_Dout_0_15n),			//	Data out for channel 0 - 15
        .i_Dout_0_15p     (i_lvds_Dout_0_15p),			//
        .i_Dout_Topn      (i_lvds_Dout_Topn),			//	"Data out for Top Manager: Global Time Stamp"
        .i_Dout_Topp      (i_lvds_Dout_Topp),			//

        .o_val_evt_n      (o_lvds_val_evt_n),			//	"Time and Charge Trigger fast masking"
        .o_val_evt_p      (o_lvds_val_evt_p),			//
        .o_ck_160n        (o_lvds_ck_160n),				//	160 MHz clock (Digital Core)
        .o_ck_160p        (o_lvds_ck_160p),				//
        .o_ck_40n         (o_lvds_ck_40n),				//	40 MHz clock (Time Stamp)
        .o_ck_40p         (o_lvds_ck_40p)				//
    );
endmodule


// page 1

// 1, 	srin_sc.digital_triroc, 	EN_TRIG_MUX,	1, Enable output on Trig_Mux pad. 			 			Recommended value ‘1’ for Enable
// 2, 								SEL_80MHz,		1, Enable internal clock divider for Readout. 			Recommended value ‘1’ for Enable (80MHz 			 readout)
// 3, 								DIS_Transmit,	1, Disable Transmit ON signals for all I/O banks. 		Recommended value ‘0’ for Enable
// 4, 								testb_ota,		1, Enable OTAs for signal monitoring in « Test Mode ». 	Recommended Value ‘1’ for Enable
// 5, 								EN_ota_time,	1, Enable ’Time Channels’ OTA monitoring. 			 	Recommended Value ‘1’
// 6, 								PP_ota_time,	0, Power ON/OFF ’Time Channels’ OTA monitoring. 		Recommended Value ‘0’ for ON
// 7, 								EN_OTA_charge,	1, Enable ’Charge Channels’ OTA monitoring. 			Recommended Value ‘1’
// 8, 								PP_ota_charge,	0, Power ON/OFF ’Charge Channels’ OTA monitoring. 		Recommended Value ‘0’ for ON
// 9, 								EN_ota_probe,	1, Enable ’analog signal’ OTA monitoring. 			 	Recommended Value ‘0’ for ON
// 10, 								PP_ota_probe,	0, Power ON/OFF ’analog signal’ OTA monitoring. 		Recommended Value ‘0’ for ON
// 11, 								EN_OR64T,		1, Enable output on NOR64_Time pad. 			 		Recommended value ‘1’ for Enable
// 12, 								EN_OR64Q,		1, Enable output on NOR64_Charge pad. 			 		Recommended value ‘1’ for Enable
// 13, 								DIS_out_trig,	1, Disable 64 channels trigger outputs. 			 	Recommended Value ‘1’ for disable outputs
// 14, 								sel_pwron_d,	1, Power on digital. 									Recommended Value ‘1’ for Power on digital and transmissions

// 15 								nc
// 16 								nc
// 17 								nc
// 18 								nc
// 19 								nc
// 20 								nc
// 21 								nc


// 22,								EN_transmitter,			1,		Enable LVDS Transmitter. 				Recommended Value ‘1’
// 23,								PP_bias_transmitter,	0, 		Power ON/OFF LVDS Transmitter. 			Recommended Value ‘0’ for ON
// 24,								ON/OFF 1mA,				1,		LVDS Transmitter current level. 		Recommended Value ‘11’ for 4mA
// 25,								ON/OFF 2mA,				1,
// 26,								EN_receiver,			1, 		Enable LVDS Receiver.					Recommended Value ‘1’

// page 2

// 27,								PP_bias_receiver,		0,		Power ON/OFF LVDS Receiver.	Recommended Value ‘0’ for ON
// 28,								ON/OFF 40M,				1,		ON/OFF 40MHz clock.					Recommended value ‘1’ for ON
// 29,								ON/OFF 160M,			1,		ON/OFF 160MHz clock.				Recommended value ‘1’ for ON

// 30 PLL           EN_PLL 1 Enable PLL. Recommended Value ‘0’
// 31               PP_PLL 0 Power ON/OFF PLL. Recommended Value ‘1’ for OFF
// 32               Ext_Vctl/Vctlb 1 No particular recommendation since PLL is OFF. Stay to default value
// 33               DividerN<4> 0 No particular recommendation since PLL is OFF. Stay to default value
// 34               DividerN<3> 0 No particular recommendation since PLL is OFF. Stay to default value
// 35               DividerN<2> 0 No particular recommendation since PLL is OFF. Stay to default value
// 36               DividerN<1> 0 No particular recommendation since PLL is OFF. Stay to default value
// 37               DividerN<0> 1 No particular recommendation since PLL is OFF. Stay to default value
// 38 ADC_ramp_Q    EN_adc_ramp_Q 1 Enable ADC Ramp – Charge Channels. Recommended Value ‘1’
// 39               PP_adc_ramp_Q 0 Power ON/OFF ADC Ramp – Charge Channels. Recommended Value ‘0’ for ON
// 40               nc NC – Spare bit
// 41               use/useb_compensation_Q 0
// 42 Ramp_adc_T    EN_adc_ramp_T 1 Enable ADC Ramp – Time Channels. Recommended Value ‘1’
// 43               PP_adc_ramp_T 0 Power ON/OFF ADC Ramp – Time Channels. Recommended Value ‘0’ for ON
// 44               nc NC – Spare bit
// 45               use/useb_compensation_T 0
// 46 Delay_box_triroc choice_OR_delay 1 Select either Charge or Time trigger for internal Track/Hold generation. Recommended value ‘1’ for Charge Trigger
// 47               sel_holdb 0 Select either internal Track/Hold signal or external source from Holdb pad. Recommended value ‘0’ for internal Track/Hold signal
// 48               EN_delay 1 Enable Delay generation for Charge or Time Trigger. Recommended Value ‘1’
// 49               PP_delay 0 Power Delay generation for Charge or Time Trigger. Recommended Value ‘0’ for ON

// 50               delay/delayb<7> 0 Delay for internal Track/Hold generation. Delay value ~ 19 ns + (BCD( delay<7:0>) * 0.8( ns)) . Recommended value will be defined later with selected value of shaper feedback. Refer Section 3.2.1.
// 51               delay/delayb<6> 0
// 52               delay/delayb<5> 0
// 53               delay/delayb<4> 1
// 54               delay/delayb<3> 0
// 55               delay/delayb<2> 0
// 56               delay/delayb<1> 1
// 57               delay/delayb<0> 0