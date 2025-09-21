
module interface(
	input clk,

	input btnC,
	input btnL,

	input uart_RX,
	output uart_TX,

	output reg [15: 0] led
);
	wire reset = btnC;
endmodule
