
module triroc_slow_control #(
    parameter integer WIDTH        = 1256,          // total bits
    parameter integer SYS_CLK_FREQ = 100_000_000,   // FPGA sys_clk
    parameter integer CLK_SR_HZ    = 1_000_000      // TRIROC shift clk
)(
    input  wire                 sys_clk,
    input  wire                 sys_rst_n,

    // Control interface
    input  wire                 start,       // start shifting
    input  wire                 load_after,  // 1 => pulse load_sc after shift
    output reg                  busy,
    output reg                  done,

    // ---------------- BRAM Port B interface ----------------
    output reg  [7:0]           addrb,   // BRAM Port B address
    output wire                 clkb,    // BRAM Port B clock
    output wire [7:0]           dinb,    // BRAM Port B data input (unused)
    output reg                  enb,     // BRAM Port B enable
    output wire                 rstb,    // BRAM Port B reset
    output wire                 web,     // BRAM Port B write enable (unused)
    input  wire [7:0]           doutb,   // BRAM Port B data output

    // ---------------- TRIROC pins ----------------
    output reg                  clk_sr,   // serial clock (<10 MHz)
    output reg                  sr_in,    // serial data in
    output reg                  rstb_sr,  // reset (active low)
    output reg                  sc_select,   // 1 => Slow Control
    output reg                  load_sc,  // active-low load pulse
    output reg                  load_event // pulse when load_sc asserted
    
);

    localparam integer BYTES = (WIDTH + 7) / 8; // 157
    localparam integer DIV   = (SYS_CLK_FREQ / (2*CLK_SR_HZ));
    localparam integer DIVW  = $clog2(DIV);

    // Tie-offs for unused BRAM Port B signals
    assign clkb = sys_clk;
    assign rstb = ~sys_rst_n;
    assign dinb = 8'd0;
    assign web  = 1'b0;

    // Clock divider for clk_sr (~1 MHz)
    reg [DIVW-1:0] div_cnt;
    reg clk_edge, clk_rising, clk_falling;

    // Byte/bit trackers
    reg [$clog2(WIDTH+1)-1:0] bit_index;
    reg [7:0] byte_index;
    reg [2:0] bit_in_byte;
    reg [7:0] current_byte;
    reg       byte_valid;

    // FSM helpers
    reg req_load_pulse;
    reg load_pulse_active;

    // ---------------- Clock Divider ----------------
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            div_cnt     <= DIV-1;
            clk_sr      <= 1'b0;
            clk_edge    <= 1'b0;
            clk_rising  <= 1'b0;
            clk_falling <= 1'b0;
        end else begin
            if (div_cnt == 0) begin
                div_cnt <= DIV-1;
                clk_sr  <= ~clk_sr;
                clk_edge <= 1'b1;

                if (~clk_sr) begin
                    clk_rising  <= 1'b1;
                    clk_falling <= 1'b0;
                end else begin
                    clk_rising  <= 1'b0;
                    clk_falling <= 1'b1;
                end
            end else begin
                div_cnt     <= div_cnt - 1;
                clk_edge    <= 1'b0;
                clk_rising  <= 1'b0;
                clk_falling <= 1'b0;
            end
        end
    end

    // ---------------- Main FSM ----------------
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            busy        <= 1'b0;
            done        <= 1'b0;
            bit_index   <= 0;
            byte_index  <= 0;
            bit_in_byte <= 0;
            current_byte<= 8'd0;
            byte_valid  <= 1'b0;
            sr_in       <= 1'b0;
            addrb       <= 8'd0;
            enb         <= 1'b0;
            rstb_sr     <= 1'b1;
            sc_select   <= 1'b1;
            load_sc     <= 1'b1;
            req_load_pulse   <= 1'b0;
            load_pulse_active<= 1'b0;
            load_event  <= 1'b0;
        end else begin
            done <= 1'b0;
            load_event <= 1'b0;

            // ---------- START ----------
            if (start && !busy) begin
                busy        <= 1'b1;
                bit_index   <= 0;
                byte_index  <= 0;
                bit_in_byte <= 0;
                addrb       <= 0;
                enb         <= 1'b1; // enable BRAM read
                byte_valid  <= 1'b0;
                req_load_pulse <= load_after;
                load_sc     <= 1'b1;
            end

            // ---------- Latch BRAM Data ----------
            if (busy && !byte_valid) begin
                current_byte <= doutb;
                byte_valid   <= 1'b1;
                sr_in        <= doutb[7]; // MSB first
                bit_in_byte  <= 0;
            end

            // ---------- Shifting on rising clk_sr ----------
            if (busy && clk_edge && clk_rising) begin
                bit_index   <= bit_index + 1;
                bit_in_byte <= bit_in_byte + 1;

                if (bit_in_byte < 7) begin
                    sr_in <= current_byte[7 - (bit_in_byte+1)];
                end else begin
                    if (byte_index + 1 < BYTES) begin
                        byte_index <= byte_index + 1;
                        addrb <= byte_index + 1;
                        byte_valid <= 1'b0;
                        sr_in <= 1'b0;
                    end else begin
                        sr_in <= 1'b0; // finished
                    end
                end
            end

            // ---------- End of shifting ----------
            if (busy && (bit_index >= WIDTH)) begin
                busy <= 1'b0;
                if (req_load_pulse) begin
                    load_sc <= 1'b0;
                    load_pulse_active <= 1'b1;
                end else begin
                    done <= 1'b1;
                end
            end

            // ---------- Handle load_sc pulse ----------
            if (load_pulse_active && clk_edge && clk_rising) begin
                load_sc <= 1'b1;
                load_event <= 1'b1;
                done <= 1'b1;
                load_pulse_active <= 1'b0;
            end
        end
    end

endmodule



