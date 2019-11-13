
//`include "pll_bb.v"

/*
font
https://github.com/dhepper/font8x8/blob/master/font8x8_basic.h
*/


module blinky (button, clk_12mhz, led, uart_rx, uart_tx, lvds_clk, lvds_rx, lvds_even_rx,

// SDRAM
	DQ,
	 DQM,
	 A,
	 BA,
	CKE,
	 RAS,
	 WE,
	 CS,
	 CAS,
	 
	 MEM_CLK
);

// SDRAM
	inout [15:0] DQ;
	output [1:0] DQM;
	output [11:0] A;
	output [1:0] BA;

	output CKE;
	output RAS;
	output WE;
	output CS;
	output CAS;
	
	output MEM_CLK;

//12MHz in

   input button;
   input clk_12mhz;
	input uart_rx;
	output uart_tx;
   output [7:0] led;
	
	output lvds_clk;
	output [2:0] lvds_rx;
	output [2:0] lvds_even_rx;
	
	wire lvds_clk_in;
	wire clk_mem_100;
	
	wire [11:0] x;
	wire [11:0] y;
	wire [23:0] color;
	
	wire [2:0] slot;
	
	reg [21:0] sdram_wr_addr;
	reg [21:0] sdram_wr_data;
	reg sdram_ctrl_wr_enable;
	wire sdram_ctrl_wr_complete;
	
	reg [21:0] sdram_rd_addr;
	wire [21:0] sdram_rd_data;
	wire sdram_ctrl_rd_ready;
	reg sdram_ctrl_rd_enable;
	
	wire sdram_ctrl_busy;
	
	assign MEM_CLK = clk_mem_100;
	
	sdram_controller sdram_controlleri (
    // HOST INTERFACE
    .wr_addr       (sdram_wr_addr),
    .wr_data       (sdram_wr_data),
    .wr_enable     (sdram_ctrl_wr_enable), 

    .rd_addr       (sdram_rd_addr), 
    .rd_data       (sdram_rd_data),
    .rd_ready      (sdram_ctrl_rd_ready),
    .rd_enable     (sdram_ctrl_rd_enable),
    
    .busy          (sdram_ctrl_busy),
    .rst_n         (button),
    .clk           (clk_mem_100),

    // SDRAM SIDE
    .addr          (A),
    .bank_addr     (BA),
    .data          (DQ),
    .clock_enable  (CKE),
    .cs_n          (CS),
    .ras_n         (RAS),
    .cas_n         (CAS),
    .we_n          (WE),
    .data_mask_low (DQM[0]),
    .data_mask_high(DQM[1])
);

/*
// nefunguje vrací 00
sdram_controller_arkowski sdram_controller (
	 .iclk(clk_mem_100),
    .ireset(button),
    
    .iwrite_req(sdram_ctrl_wr_enable),
    .iwrite_address(sdram_wr_addr),
    .iwrite_data(sdram_wr_data),
    .owrite_ack(sdram_ctrl_wr_complete),
    
    .iread_req(sdram_ctrl_rd_enable),
    .iread_address(sdram_rd_addr),
    .oread_data(sdram_rd_data),
    .oread_ack(sdram_ctrl_rd_ready),
    
	//////////// SDRAM //////////
	.DRAM_ADDR(A),
	.DRAM_BA(BA),
	.DRAM_CAS_N(CAS),
	.DRAM_CKE(CKE),
	//.DRAM_CLK(clk_mem_100),
	.DRAM_CS_N(CS),
	.DRAM_DQ(DQ),
	.DRAM_LDQM(DQM[0]),
	.DRAM_RAS_N(RAS),
	.DRAM_UDQM(DQM[1]),
	.DRAM_WE_N(WE)
);*/
	
lvds my_lvds (
	.button(button),
	.clk_in(lvds_clk_in),
	
	.clk_out(lvds_clk),
	.rx(lvds_rx),
	.rx_even(lvds_even_rx),
	
	.x(x),
	.y(y),
	.color(r_color),
	.color_even(r_color_even),
	.o_slot(slot)

);

	reg [23:0] r_color, r_color_even;
	
	reg [11:0] next_x;
	reg [11:0] next_y;
	
	reg [7:0] uart_rx_buffer;
	
	/*
	reg [7:0] text [0:(255*255-1)];
	
	reg [7:0] index_x;
	initial begin
		//for(index_y = 0; index_y < 10; index_y=index_y+1)
			for(index_x = 0; index_x < 255; index_x=index_x+1)
			begin
				text[{index_x, 8'b0}] = index_x + 65;
				
				//text[(index_x << 8) + index_x] = index_x + 65;
			end
			
	end*/
		
	wire [7:0] text_column;
	wire [7:0] text_row;
	
	reg [9:0] next_rom_address;
	
	assign text_column = x[9:2]; // because dual-lvds
	assign text_row = y[9:3];
	
	wire [3:0] rom_out_bit_index_odd;
	wire [3:0] rom_out_bit_index_even;
	
	assign rom_out_bit_index_odd = ((x[2:0]) << 1);
	assign rom_out_bit_index_even = ((x[2:0]) << 1) + 1'b1;
	
	reg [15:0] sdram_lvds_rd_buffer;
	reg [15:0] sdram_lvds_rd_buffer_next;
	
	reg [11:0] last_x;
	
	reg ram_write_enable;
	reg [7:0] ram_write_data;
	
	ram	ram_inst (
	.data ( ram_write_data /*65 + text_row[7:0] + text_column[7:0]*/),
	.rdaddress ( {text_column[7:0], text_row[7:0]} ),
	.rdclock ( lvds_clk_in ),
	.wraddress ( {text_column[7:0], text_row[7:0]} ),
	.wrclock ( clk_mem_100 ),
	.wren ( ram_write_enable ),
	.q ( ram_out )
	);
	
	wire [7:0] ram_out;

	
always @(posedge lvds_clk_in)
begin
	
	// slot 4 prepare data
	// slot5-library is copying color
	/*
	if(last_x[11:6] != x[11:6])
	begin
		last_x <= x;
	
		sdram_rd_addr <= {15'b0,x[11:6]};
		sdram_ctrl_rd_enable <= 1'b1;
		sdram_lvds_rd_buffer <= sdram_lvds_rd_buffer_next;
	
	end
	else
	begin
		sdram_ctrl_rd_enable <= 1'b0;
	end
	
	if(slot == 4)
		begin
			r_color <= {8'b0, sdram_lvds_rd_buffer};
			r_color_even <= {8'b0, sdram_lvds_rd_buffer};
		end*/
	
		/*
	else if(slot == 0)
	begin
		sdram_ctrl_rd_enable <= 1'b0;
	end*/
	
		if(rom_out[rom_out_bit_index_odd] == 1'b1)
		begin
			r_color <= 24'hFF0000;
		end
		else
		begin
			r_color <= 24'hFFFFFF;
		end
		
		if(rom_out[rom_out_bit_index_even] == 1'b1)
		begin
			r_color_even <= 24'hFF0000;
		end
		else
		begin
			r_color_even <= 24'hFFFFFF;			
		end
	
		rom_address <= {ram_out, y[2:0]};
end
	
	wire [7:0] rom_out;
	reg [9:0] rom_address;
	
	rom	rom_inst (
	.address ( rom_address ),
	.clock ( lvds_clk_in ),
	.q ( rom_out )
	);
	

	pll  myPLL (.areset(0),	.inclk0(clk_12mhz), .c0(lvds_clk_in), .c1(clk_mem_100));
	
		
	reg [21:0] divider = 22'b0;
	
	always @(posedge clk_12mhz)
	begin
	
		divider <= divider + 1'd1;
		
		if(divider == 0)
			uart_transmit <= 1;
		else
			uart_transmit <= 0;
	
	end
	
	always @(posedge divider[20])
	begin
		r_led[0] <= ~ r_led[0];
	end	
	
	
	reg [7:0] r_led = 8'b000000;
	assign led = /*divider[7:4] == 4'b0000 ?*/ r_led /*: 8'b000000*/;
	
	reg [7:0] text_index = 1'b0;
	
	always @(posedge clk_mem_100)
	begin
	
		r_led[4] <= sdram_ctrl_busy;
	
		if(sdram_ctrl_rd_ready)
		begin
			uart_tx_byte <= sdram_rd_data[7:0];
			sdram_lvds_rd_buffer_next <= sdram_rd_data[15:0];
			r_led[3] <= ~r_led[3];
		end
	
		if(uart_received)
		begin
			
			//text[text_index][0] <= uart_rx_byte[6:0];
						
			if(uart_rx_byte == 8'h0d)
				text_index <= 0;
			else
				text_index <= text_index + 1;
			

			if(uart_rx_byte[7:0] > "B" && uart_rx_byte[7:0] < "Z")
			begin
				sdram_wr_addr <= 22'h00;
				sdram_wr_data <= {9'b0, uart_rx_byte[6:0]};
				sdram_ctrl_wr_enable <= 1'b1;
				
				ram_write_data <= {1'b0, uart_rx_byte[6:0]};
				ram_write_enable <= 1'b1;
				
				r_led[1] <= ~r_led[1];
			end
			else if(uart_rx_byte[6:0] == "B")
			begin
				//sdram_rd_data[7:0] <= 8'b0;
			end
			else if(uart_rx_byte[6:0] == "A")
			begin
				/*sdram_rd_addr <= 22'h00;
				sdram_ctrl_rd_enable <= 1'b1;
				 
				 r_led[2] <= ~r_led[2];*/
				
				//uart_tx_byte <= "R";
			end
		 
		end
		else
		begin
			//sdram_ctrl_rd_enable <= 1'b0;
			//sdram_rd_addr <= 22'b0;
			
			sdram_ctrl_wr_enable <= 1'b0;
			sdram_wr_addr <= 22'b0;
			
			ram_write_enable <= 1'b0;
		end

	end
	
	reg uart_transmit = 0;
	wire uart_received;
	reg [7:0] uart_tx_byte = "X";
	wire [7:0] uart_rx_byte;
	
	uart my_uart(
    .clk(clk_mem_100), // The master clock for this module
    .rst(~button), // Synchronous reset.
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
	

endmodule
