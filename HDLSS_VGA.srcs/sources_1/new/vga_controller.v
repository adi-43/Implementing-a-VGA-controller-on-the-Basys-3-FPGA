`timescale 1ns / 1ps


module vga_controller
(
    input  wire       clk_100MHz,   // from Basys 3
    input  wire       reset,        // system reset
    output wire       video_on,    // ON while pixel counts for x and y and within display area
    output wire       hsync,       // horizontal sync
    output wire       vsync,       // vertical sync
    output wire       p_tick,      // the 25MHz pixel/second rate signal, pixel tick
    output wire [9:0] x,     // pixel count/position of pixel x, max 0-799
    output wire [9:0] y      // pixel count/position of pixel y, max 0-524
);
    
    // Based on VGA standards found at vesa.org for 640x480 resolution
    // Total horizontal width of screen = 800 pixels, partitioned  into sections
    parameter HD   = 640;             // horizontal display area width in pixels
    parameter HF   = 48;              // horizontal front porch width in pixels
    parameter HB   = 16;              // horizontal back porch width in pixels
    parameter HR   = 96;              // horizontal retrace width in pixels
    parameter HMAX = HD+HF+HB+HR-1; // max value of horizontal counter = 799
    // Total vertical length of screen = 525 pixels, partitioned into sections
    parameter VD   = 480;             // vertical display area length in pixels 
    parameter VF   = 10;              // vertical front porch length in pixels  
    parameter VB   = 33;              // vertical back porch length in pixels   
    parameter VR   = 2;               // vertical retrace length in pixels  
    parameter VMAX = VD+VF+VB+VR-1; // max value of vertical counter = 524   
    
    // *** Generate 25MHz from 100MHz *********************************************************
	reg  [1:0] r_25MHz;
	wire       w_25MHz;
	
	always @(posedge clk_100MHz or posedge reset) begin
		if(reset)
		    r_25MHz <= 1'b0;
		else
		    r_25MHz <= r_25MHz + 1'b1;
	end
	
	assign w_25MHz = (r_25MHz == 0) ? 1'b1 : 1'b0; // assert tick 1/4 of the time
    // ****************************************************************************************
    
    // Counter Registers, two each for buffering to avoid glitches
    reg [9:0] h_count_reg, h_count_next;
    reg [9:0] v_count_reg, v_count_next;
    
    // Output Buffers
    reg  v_sync_reg, h_sync_reg;
    wire v_sync_next, h_sync_next;
    
    // Register Control
    always @(posedge clk_100MHz or posedge reset) begin
    	if(reset) begin
            v_count_reg <= 1'b0;
            h_count_reg <= 1'b0;
            v_sync_reg  <= 1'b0;
            h_sync_reg  <= 1'b0;
        end else begin
            v_count_reg <= v_count_next;
            h_count_reg <= h_count_next;
            v_sync_reg  <= v_sync_next;
            h_sync_reg  <= h_sync_next;
        end
    end
        
         
    //Logic for horizontal counter
    always @(posedge w_25MHz or posedge reset) begin
    	if(reset) begin
            h_count_next = 1'b0;
        end else begin
        	if(h_count_reg == HMAX)                 
                h_count_next = 1'b0;
            else
                h_count_next = h_count_reg + 1'b1;
        end                
    end      
        
    always @(posedge w_25MHz or posedge reset) begin
    	if(reset) begin
            v_count_next = 1'b0;
        end else begin
            if(h_count_reg == HMAX) begin
            	if((v_count_reg == VMAX))           
                    v_count_next = 1'b0;
                else
                    v_count_next = v_count_reg + 1'b1;
            end                
        end
    end
        
        
    // h_sync_next asserted within the horizontal retrace area
    assign h_sync_next = (h_count_reg >= (HD+HB) && h_count_reg <= (HD+HB+HR-1));
    
    // v_sync_next asserted within the vertical retrace area
    assign v_sync_next = (v_count_reg >= (VD+VB) && v_count_reg <= (VD+VB+VR-1));
    
    // Video ON/OFF - only ON while pixel counts are within the display area
    assign video_on = (h_count_reg < HD) && (v_count_reg < VD); // 0-639 and 0-479 respectively
            
    // Outputs
    assign hsync  = h_sync_reg;
    assign vsync  = v_sync_reg;
    assign x      = h_count_reg;
    assign y      = v_count_reg;
    assign p_tick = w_25MHz;
            
endmodule