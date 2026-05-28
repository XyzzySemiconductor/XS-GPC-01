// vim: ts=4:
module adc_in
(
	// Input clock,
	input logic clk,
	input logic reset,
	
	// External A/D Converters (2.5v)
	output logic  ad_cs,
	input  logic  ad_sdata,
	
	// ADC monitor outputs
	output logic [11:0] ad_out,
	output logic ad_strobe
);

// ADC sample pulse 
// RUn ADCs in-continuous mode.
// The fall of the CS signal is actually the moment of sampling, and MSB becomes valid
parameter HOLD_SEL = 15;  // select output hold delay bit 1 cyclce early but account for input regs
parameter ADCS_SEL = 15;  // early CS output cycle 


reg [3:0] sample_div = 0;
initial sample_div = 0;
always_ff @(posedge clk) sample_div <= ( reset ) ? 0 : sample_div + 1;

// ad_cs reg is to be I/O_reg
// ad_cs is active during sample_div == 0;
always_ff @(posedge clk) 
	ad_cs <= ( sample_div == ADCS_SEL ) ? 1'b1 : 1'b0;

// DATA Input I/O registers
logic ad_ireg;
always_ff @(posedge clk)
	ad_ireg <= ad_sdata;

// Data input shift regisers MSB first
reg [11:0] ad_sreg;
always_ff @(posedge clk) begin
  if( reset ) begin
	ad_sreg <= 0;
  end else begin
		ad_sreg <= { ad_sreg[10:0], ad_ireg };
  end
end

// Data hold registers
logic ad_hold_en;
always_ff @(posedge clk) 
	ad_hold_en <= ( sample_div == HOLD_SEL ) ? 1'b1 : 1'b0;
logic [11:0] ad_hold;
always_ff @(posedge clk) 
  if( reset ) begin
	ad_hold <= 0;
  end else begin
	for( int ii =  0; ii < 4; ii++ ) 
		ad_hold <= ( ad_hold_en ) ? ad_sreg : ad_hold;
  end
// ad_strobe reg
always_ff @(posedge clk) ad_strobe <= ad_hold_en;

// Output optional negation
// data outputs with negation
assign ad_out = ad_hold ^ 12'h800;

endmodule
