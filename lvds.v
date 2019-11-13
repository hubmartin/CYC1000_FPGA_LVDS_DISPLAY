// LVDS

/*

LVDS panel LP171WU3
https://www.beyondinfinite.com/lcd/Library/LG-Philips/LP171WU3-TLB3.pdf

180 MHz ok

*/

module lvds (button, clk_in, led,

	rx, rx_even, clk_out,
	x,y,
	color, color_even,
	o_slot
);

	input button;
   input clk_in;
	output [7:0] led;
	
	output [2:0] rx;
	output [2:0] rx_even;
	output clk_out;
	
	output [11:0] x;
	output [11:0] y;
	input [23:0] color, color_even;
	
	output [2:0] o_slot;
	
   reg [7:0] count = 8'b0;

   assign led = count; //{div[3], div[2], div[1], div[0]} == 4'b0 ? count : 6'b0 ;

   // LVDS
   localparam [6:0] ckdata = 7'b1100011;
   wire [0:6] RX0DATA, RX0EDATA;
   wire [0:6] RX1DATA, RX1EDATA;
   wire [0:6] RX2DATA, RX2EDATA;

	localparam [11:0] hfront = 24;
	localparam [11:0] hback = 40;
	localparam [11:0] hactive = 960;
	localparam [11:0] htotal = 960+hback;

	localparam [11:0] vfront = 3;
	localparam [11:0] vback = 26;
	localparam [11:0] vactive = 1200;
	localparam [11:0] vtotal = 1200+vback;

	reg [11:0] hcurrent = 0;
	reg [11:0] vcurrent = 0;

	wire [11:0] x;
	wire [11:0] y;

   reg [5:0] red = 6'b0;
   reg [5:0] green = 6'b0;
   reg [5:0] blue = 6'b0;
	
	reg [5:0] red_even = 6'b0;
   reg [5:0] green_even = 6'b0;
   reg [5:0] blue_even = 6'b0;

   reg [17:0] nextColor = 18'b0;
	reg [17:0] nextColor_even = 18'b0;

   reg [2:0] slot = 0;

   reg hsync = 0;
   reg vsync = 0;

   wire dataenable;

   assign dataenable = vsync & hsync;
		
	// CLOCK
   assign clk_out = ckdata[slot];
	
	assign o_slot = slot;

	//
	// ODD DATA
	//
	//RX2DATA is (DE, vsync, hsync, blue[5:2])
	assign RX2DATA[0] = dataenable;
	assign RX2DATA[1] = hsync;
	assign RX2DATA[2] = vsync;
	assign RX2DATA[3:6] = blue[5:2];

	//RX1DATA is (blue[1:0], green[5:1])
	assign RX1DATA[0:1] = blue[1:0];
	assign RX1DATA[2:6] = green[5:1];

	//RX1DATA is (green[0], red[5:0])
	assign RX0DATA[0] = green[0];
	assign RX0DATA[1:6] = red[5:0];
	
	assign rx[0] = RX0DATA[slot];
	assign rx[1] = RX1DATA[slot];
	assign rx[2] = RX2DATA[slot];
	
	//
	// EVEN DATA
	//
	assign RX2EDATA[0] = dataenable;
	assign RX2EDATA[1] = hsync;
	assign RX2EDATA[2] = vsync;
	assign RX2EDATA[3:6] = blue_even[5:2];

	assign RX1EDATA[0:1] = blue_even[1:0];
	assign RX1EDATA[2:6] = green_even[5:1];

	assign RX0EDATA[0] = green_even[0];
	assign RX0EDATA[1:6] = red_even[5:0];
	
	assign rx_even[0] = RX0EDATA[slot];
	assign rx_even[1] = RX1EDATA[slot];
	assign rx_even[2] = RX2EDATA[slot];
	
	assign x = (hcurrent - hfront >= 0) & (hcurrent - hfront < hactive) ? hcurrent - hfront : 0;
	assign y = (vcurrent - vfront >= 0) & (vcurrent - vfront < vactive) ? vcurrent - vfront : 0;

/*
	always @ (slot)
	begin
		if(slot == 5)
		begin
			nextColor <= {  color[15:10], color[23:18], color[7:2]};
		end
	end*/

	// Slot increment
	always @ (posedge clk_in)
	begin
		
		if(hcurrent < hfront | (hcurrent >= (hfront + hactive)))
			hsync <= 0;
		else
			hsync <= 1;

		if(vcurrent < vfront | (vcurrent >= (vfront + vactive)))
			vsync <= 0;
		else
			vsync <= 1;
			
		if(slot == 5)
		begin
			nextColor <= {  color[15:10], color[23:18], color[7:2]};
			nextColor_even <= {  color_even[15:10], color_even[23:18], color_even[7:2]};
		end

		if(slot == 6)
		begin
			slot <= 0;
			
			green <= dataenable ? nextColor[17:12] : 8'b0;
			red <= dataenable ? nextColor[11:6] : 8'b0;
			blue <= dataenable ? nextColor[5:0] : 8'b0;
			
			green_even <= dataenable ? nextColor_even[17:12] : 8'b0;
			red_even <= dataenable ? nextColor_even[11:6] : 8'b0;
			blue_even <= dataenable ? nextColor_even[5:0] : 8'b0;


			
			if(hcurrent == htotal)
			begin
				hcurrent <= 0;

				if(vcurrent == vtotal)
					vcurrent <= 0;
				else
					vcurrent <= vcurrent + 1;
			end
			else
			begin
				hcurrent <= hcurrent + 1;
			end
		end
		else
		begin
			slot <= slot + 1;
		end


	end


	initial
	begin
		//$monitor("hsync %d", hsync);
	end
	
endmodule