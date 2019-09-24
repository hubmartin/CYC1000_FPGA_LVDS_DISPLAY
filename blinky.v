
//`include "pll_bb.v"

/*
font
https://github.com/dhepper/font8x8/blob/master/font8x8_basic.h
*/


module blinky (button, clk_12mhz, led, uart_rx, uart_tx, lvds_clk, lvds_rx);

//12MHz in

   input button;
   input clk_12mhz;
	input uart_rx;
	output uart_tx;
   output [7:0] led;
	
	output lvds_clk;
	output [2:0] lvds_rx;
	
	wire lvds_clk_in;
	
	wire [11:0] x;
	wire [11:0] y;
	wire [23:0] color;

	// assign statements (if any)                          
lvds my_lvds (
// port map - connection between master ports and signals/registers   
	.button(button),
	.clk_in(lvds_clk_in),
	
	.clk_out(lvds_clk),
	.rx(lvds_rx),
	
	.x(x),
	.y(y),
	.color(color)

);

	//assign color = {y[7:4], x[7:4]}; // (x > 10 & x < 42 & y > 10 & y < 42) ? memory[{y[4:0]-5'd11, x[4:0]-5'd11}] : 8'b0;
	reg [23:0] r_color;
	
	assign color = r_color;
	
	reg [11:0] next_x;
	reg [11:0] next_y;
	
	reg [7:0] uart_rx_buffer;
	
	
	reg [6:0] text [0:127];
	
	integer i;
	initial begin
			for(i = 0; i < 128; i=i+1)
			begin
				text[i] = i;
			end
	end
	
	
	wire [6:0] text_column;
	wire [6:0] text_row;
	
	reg [9:0] next_rom_address;
	
	assign text_column = x[8:3];
	assign text_row = y[8:3];
	
	//reg [6:0] next_character;
	
	always @(posedge lvds_clk_in)
	begin
		
		/*
		if(x == 0)
			r_color = 24'h0000FF;
		else if(x == 1920/2 - 1)
			r_color = 24'h00FF00;
			
		else if(y == y_pos)
			r_color = 24'hFF0000;
		else if(y == 1200 - 1)
			r_color = 24'hFF0000;
			*/
			
			
		if(animbox_r_out == 1'b1)
			r_color = 24'hFF0000;
			
		else if(animbox_b_out == 1'b1)
			r_color = 24'h0000FF;
			
		else if(rom_out[x[2:0]] == 1'b1)
			r_color = 24'hFF0000;	
		else
			r_color = 24'hFFFFFF;
			
		rom_address <= next_rom_address;
		
		next_rom_address<= {text[text_column], y[2:0]};
		//text[text_column][6:0]
		//x[9:3]
		
	
	end
	
		
/*
	reg [7:0] memory [0:(32*32)-1];
	
	initial begin
		$display("Loading memory.");
      $readmemh("rom_image.mem", memory);
	end*/
	
	wire animbox_r_out;
	
	animbox animbox_r(
		.clk(clk_12mhz),
		.x(x),
		.y(y),
		.out(animbox_r_out)
	);
	
	wire animbox_b_out;
		animbox #(.P_MAX_X(477), .P_MAX_Y(433)) animbox_b(
		.clk(lvds_clk_in),
		.x(x),
		.y(y),
		.out(animbox_b_out)
	);
	
	wire [7:0] rom_out;
	reg [9:0] rom_address;
	
	rom	rom_inst (
	.address ( rom_address ),
	.clock ( lvds_clk_in ),
	.q ( rom_out )
	);
	


	
	pll  myPLL (0,	clk_12mhz, lvds_clk_in);
	
		
	reg [21:0] divider = 22'b0;
	
	assign led[0] = divider[21];
	
	always @(posedge clk_12mhz)
	begin
	
		divider <= divider + 1'd1;
		
		if(divider == 0)
			uart_transmit <= 1;
		else
			uart_transmit <= 0;
	
	end
	
	reg uart_led;
	reg [7:0] y_pos = 8'd10;
	
	assign led[1] = uart_led;
	assign led[7:2] = 6'b000000;
	
	always @(posedge clk_12mhz)
	begin
		if(uart_received == 1)
		begin
			uart_led <= ~uart_led;
			
			y_pos <= uart_rx_byte;
			text[4] <= uart_rx_byte[6:0];
			
			 uart_tx_byte <= text[4];
		end
	end
	
	
	reg uart_transmit = 0;
	wire uart_received;
	reg [7:0] uart_tx_byte = 8'd65;
	wire [7:0] uart_rx_byte;
	
	uart my_uart(
    .clk(clk_12mhz), // The master clock for this module
    .rst(0), // Synchronous reset.
    .rx(uart_rx), // Incoming serial line
    .tx(uart_tx), // Outgoing serial line
    .transmit(uart_transmit), // Signal to transmit
    .tx_byte(uart_tx_byte), // Byte to transmit
    .received(uart_received), // Indicated that a byte has been received.
    .rx_byte(uart_rx_byte) // Byte received
   /* output is_receiving, // Low when receive line is idle.
    output is_transmitting, // Low when transmit line is idle.
    output recv_error // Indicates error in receiving packet.*/
    );
	
	//nios_II myNios (.reset_reset_n(button), .clk_clk(clk_50mhz));
	/*
	always @(posedge tx_done) begin
	if(tx_done)
		data_valid <= 0;
	end*/
	/*
	wire [7:0] uart_data = 65;
	
	   uart_tx #(.CLKS_PER_BIT(104)) insta_tx (
        .i_Clock( clk_50mhz ),
        .i_Tx_DV( data_valid ),
        .i_Tx_Byte( uart_data ),
        .o_Tx_Serial( uart_tx ),
		.o_Tx_Done ( tx_done )
      );*/


	//assign uart_tx = uart_rx;
	//assign lvds = clk_50mhz;

endmodule
