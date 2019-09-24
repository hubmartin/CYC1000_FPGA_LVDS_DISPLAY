// LVDS tb

`timescale 1 ns/ 1 ps
module stimulus;


reg clk_12mhz;
reg button;

wire [7:0]  led;

wire[2:0] rx;
wire clk_out;

wire [11:0] x;
wire [11:0] y;
wire [23:0] color;


// assign statements (if any)                          
lvds my_lvds (
// port map - connection between master ports and signals/registers   
	.button(button),
	.clk_in(clk_12mhz),
	.led(led),
	
	.clk_out(clk_out),
	.rx(rx),

	.x(x),
	.y(y),
	.color(color)

);
	assign color =  24'b0;

		
	wire [11:0] text_column;
	wire [11:0] text_row;

	assign text_column = x[9:3];
	assign text_row = y[9:3];
	
	reg [9:0] rom_address;
	reg [9:0] next_rom_address;
	reg [7:0] text [0:1023];

	wire [7:0] text_char;
	assign text_char = text[text_column];

	assign text_bit = text_char[0];

	initial begin
			/*text[0] = "A";
			text[1] = "h";
			text[2] = "o";
			text[3] = "j";*/
			
			for(i = 0; i < 1024; i=i+1)
			begin
				text[i] = i;
			end
	end


	always @(posedge clk_12mhz)
	begin
			
		rom_address <= next_rom_address;
		next_rom_address<= { text[text_column][6:0], y[2:0] };

	end



 integer i;
 
 initial begin
 	 clk_12mhz = 0;
	 button = 0;
	 for(i =0; i<=300000; i=i+1)
	 begin
	  #10 clk_12mhz = ~clk_12mhz;
	 end
 end
 
initial 
begin
	$dumpfile("output_lvds_test.vcd");
	$dumpvars; //(2,stimulus);
 
	//reset =1;
	//#2 reset = 0;
	//#2 reset =1;
end
 

initial begin
	$monitor("text_column %d, asii %c, bit: %d", text_column, text_char, text_bit);

end
                                  
endmodule