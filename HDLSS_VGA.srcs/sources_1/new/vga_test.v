`timescale 1ns / 1ps

module vga_test(
	input  wire         clk_100MHz,     
	input  wire         reset,
	input  wire [2:0]   sw,      
	output wire         hsync,
	output wire         vsync,
	output wire [11:0]  rgb  //0000_0000_1111 -> b   
);
	
	reg [11:0] rgb_reg;    
	wire       video_on;  
    reg [63:0] count;
    
    vga_controller vga_c
    (
        .clk_100MHz(clk_100MHz), 
        .reset     (reset), 
        .hsync     (hsync), 
        .vsync     (vsync),
        .video_on  (video_on), 
        .p_tick    (), 
        .x         (), 
        .y         ()
    );

    always @(posedge clk_100MHz or posedge reset) begin
        if (reset) begin
            rgb_reg <= 1'b0;
            count   <= 1'b0;
        end else begin
            if(count >= 99_99_9999) begin
              rgb_reg <= er;
              count   <= 1'b0;
            end else begin
              count <= count + 1'b1;
            end 
        end
    end   
    
assign rgb = (video_on) ? rgb_reg : 12'b0;   
        
endmodule