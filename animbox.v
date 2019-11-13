

module animbox(clk, x, y, out);

parameter P_MAX_X = 500;
parameter P_MAX_Y = 493;
parameter DIVIDER_BIT = 20;

input clk;
input [11:0] x;
input [11:0] y;
output out;

localparam [11:0] max_x = P_MAX_X;
localparam [11:0] max_y = P_MAX_Y;

reg [22:0] divider = 22'b0;

reg [11:0] pos_x = 12'd10;
reg [11:0] pos_y = 12'd10;

reg direction_x = 1'b1;
reg direction_y = 1'b1;

reg r_out = 1'b0;

always @(posedge clk)
begin
	divider <= divider + 1;
	
	r_out <= ((y > pos_y & y < pos_y + 32) & (x > pos_x & x < pos_x + 32)) ? 1'b1 : 1'b0;
end

assign out = r_out;

//assign out = ((y > pos_y & y < pos_y + 32) & (x > pos_x & x < pos_x + 32)) ? 1'b1 : 1'b0;

always @(posedge divider[DIVIDER_BIT])
begin
	if(direction_x == 1'b1)
		pos_x <= pos_x + 1;
	else
		pos_x <= pos_x - 1;
		
	if(direction_y == 1'b1)
		pos_y <= pos_y + 1;
	else
		pos_y <= pos_y - 1;
		
		
	if(pos_x > max_x)
		direction_x <= 1'b0;
	else if(pos_x < 10)
		direction_x <= 1'b1;		
		
	if(pos_y > max_y)
		direction_y <= 1'b0;
	else if(pos_y < 10)
		direction_y <= 1'b1;
		
end

endmodule