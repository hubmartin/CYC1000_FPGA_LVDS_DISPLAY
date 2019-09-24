// LVDS

/*

LVDS panel LP171WU3
https://www.beyondinfinite.com/lcd/Library/LG-Philips/LP171WU3-TLB3.pdf

180 MHz ok

*/

module lvds (button, clk_in, led,

	rx, clk_out,
	x,y,
	color
);

	input button;
   input clk_in;
	output [7:0] led;
	
	output [2:0] rx;
	output clk_out;
	
	output [11:0] x;
	output [11:0] y;
	input [23:0] color;
	
   reg [7:0] count = 8'b0;

   assign led = count; //{div[3], div[2], div[1], div[0]} == 4'b0 ? count : 6'b0 ;

   // LVDS
   localparam [6:0] ckdata = 7'b1100011;
   wire [0:6] RX0DATA;
   wire [0:6] RX1DATA;
   wire [0:6] RX2DATA;

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

   reg [17:0] nextColor = 18'b0;

   reg [2:0] slot = 0;

   reg hsync = 0;
   reg vsync = 0;

   wire dataenable;

   assign dataenable = vsync & hsync;

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

	// Assign data to slots
   	assign clk_out = ckdata[slot];
	assign rx[0] = RX0DATA[slot];
	assign rx[1] = RX1DATA[slot];
	assign rx[2] = RX2DATA[slot];
	
	assign x = (hcurrent - hfront >= 0) & (hcurrent - hfront < hactive) ? hcurrent - hfront : 0;
	assign y = (vcurrent - vfront >= 0) & (vcurrent - vfront < vactive) ? vcurrent - vfront : 0;


	always @ (slot)
	begin
		if(slot == 5)
		begin
			//nextColor <= 18'b0;
			
			//nextColor <= {hcurrent[5:0], vcurrent[5:0], 6'b0};

			nextColor <= {  color[15:10], color[23:18], color[7:2]};
			
			/*
			if(hcurrent == 50)
				nextColor <= 18'b111111000000000000;
				
			if(hcurrent == 970)
				nextColor <= 18'b000000000000111111;
				
			if(vcurrent == 4)
				nextColor <= 18'b000000111111000000;
				
			if(vcurrent == 1199)
				nextColor <= 18'b000000111111000000;
				*/
/*
			if(hcurrent > 800)
				nextColor <= 18'b000000111111000000;
			else if(hcurrent > 600)
				nextColor <= 18'b111111000000000000;
			else if(hcurrent > 400)
				nextColor <= 18'b000000000000111111;
			else if(hcurrent > 200)
				nextColor <= 18'b111111000000111111;		
			else if(hcurrent > 100)
				nextColor <= 18'b000000111111111111;			
			else if(hcurrent > 50)
				nextColor <= 18'b111111111111111111;
				*/
		end
	end

	// Slot increment
	always @ (posedge clk_in)
	//always @ (*)
	begin

		//hsync = next_hsync;
		
		if(hcurrent < hfront | (hcurrent >= (hfront + hactive)))
			hsync <= 0;
		else
			hsync <= 1;

		if(vcurrent < vfront | (vcurrent >= (vfront + vactive)))
			vsync <= 0;
		else
			vsync <= 1;

		if(slot == 6)
		begin
			slot = 0;
			
			if(dataenable)
			begin
				green <= nextColor[17:12];
				red <= nextColor[11:6];
				blue <= nextColor[5:0];
			end
			else
			begin
				green <= 8'b0;
				red <= 8'b0;
				blue <= 8'b0;
			end
			
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