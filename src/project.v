// vim: ts=4:
/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_60hz_load(
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out[7:5]  = 0; 
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, ui_in, uio_in, 1'b0};
	
	wire reset;
	assign reset = !rst_n;

	// Gate input reg
	reg [1:0] gate;
	always @(posedge clk) 
		gate <= ( reset ) ? 0 : ui_in[2:1];

	// ADC Input
	wire strobe; // 1 cycle pulse every 16 cycles
	wire [11:0] ad_data; // 2s comp adc input data
	adc_in i_adc (
		.clk( clk ),
		.reset( reset ),
		.ad_cs( uo_out[2] ),
		.ad_sdata( ui_in[0] ),
		.ad_out( ad_data ),
		.ad_strobe( strobe )
	);

	// Cordic unit
	logic [15:0] angle;
	logic [15:0] sin_out, cos_out;
	logic valid, busy;
	cordic_sincos_50000_core_20 i_dut(
		.clk( clk ),
		.rst( reset ),
		.start( strobe ),
		.angle_in( angle ),
		.sin_out ( sin_out ),
		.cos_out ( cos_out ),
		.valid( valid ),
		.busy( busy )
	);
		

	// Count angle every start pulse (-25000 to 24999 )
   	// at 3Mhz (48Mhz/16) this gives us exactly 60 Hz grid freq

	reg polarity;
	always @(posedge clk) begin
		if( reset ) begin
			angle <= -12500;
			polarity <= 0;
		end else begin
			if( strobe ) begin
				angle <= ( angle == 12499 ) ? -12500 : angle + 1;
		    	polarity <= ( angle == 12499 ) ? ~polarity : polarity;
			end
		end
	end
	wire half_cycle;
	assign half_cycle = ( strobe && angle == 12499 ) ? 1'b1 : 1'b0;

	// Correct Polarity (just negate)
	logic signed [15:0] sin, cos;
	always @(posedge clk) begin
		if( reset ) begin
			sin <= 0;
		end else if( valid ) begin
			sin <= ( polarity ) ? ~cos_out : cos_out; // use cos as it aligns with polarity
		end
	end

	// Accumulate error function
	// and gates PWM outputs with
	// guaranteed min pulse width of 4us
	logic signed [31:0] sin_err, cos_err;
	logic sin_pwm_p, sin_pwm_n;

	always @(posedge clk) begin
		if( reset ) begin
			sin_pwm_p <= 0;
			sin_pwm_n <= 0;
			sin_err <= 0;
		end else begin
			sin_pwm_p <= ( sin_err >  16465 * 12 * 16 ) ? 1 : ( sin_err < 0 ) ? 0 : sin_pwm_p;
			sin_pwm_n <= ( sin_err < -16465 * 12 * 16 ) ? 1 : ( sin_err > 0 ) ? 0 : sin_pwm_n;
			sin_err <= sin_err + ((gate[0])?sin:0) + ((sin_pwm_p)?-16465:(sin_pwm_n)?16465:0);
		end
 	end

	assign uo_out[0] = sin_pwm_p;
	assign uo_out[1] = sin_pwm_n;

	// Accumulate error over half wave 
	// quick/dirty


	wire [11:0] delta;
	assign delta = ( polarity ) ? ad_data - sin[15-:12] : sin[15-:12] - ad_data;
	reg [31:0] err;
	always @(posedge clk) begin
		if( reset ) begin
			err <= 0;
		end else begin
			err <= ( half_cycle ) ? {{20{delta[11]}},delta} : 
                       ( strobe ) ? {{20{delta[11]}},delta} + err : err;
		end
	end

	// Each half cycle update the load duty cycle
	// if error > thresh, then duty_cycle++, and the opposite

	reg [3:0] duty;
	always @(posedge clk) 
		duty <= ( reset ) ? 0 : 
                ( half_cycle && !err[31] && err[31-:12] != 12'h000 && duty != 15 ) ? duty + 1 :
                ( half_cycle &&  err[31] && err[31-:12] != 12'hFFF && duty !=  0 ) ? duty - 1 : duty;

    // Use duty cycel to generate load PWM guantee 4us min width
	// at 48 Mhz,  4 Usec == 192 cyc, or 12 strobve cycles
	// during a half cycle we have 400K clocks and 25000 strobes
	// we also have the angle counter from -25000 to 24999 each half cycle

	reg [7:0] outer, inner;
	reg [3:0] dcount;
	reg pwm;
	always @(posedge clk) begin
		if( reset || half_cycle ) begin
			outer <= 0;
			inner <= 0;
			dcount <= 0;
			pwm<= 0;
		end else begin
			inner <= ( inner == 249 ) ? 0 : inner + 1;
			dcount<= ( inner == 249 && dcount == 15 ) ? 0 : ( inner == 249 ) ? dcount + 1 : dcount;
			outer <= ( inner == 249 && dcount == 15 ) ? outer + 1 : outer;
			pwm <= ( inner == 249 ) ? ((duty>dcount)?1'b1:1'b0) : pwm;
		end
	end

	assign uo_out[3] = pwm;

	// Accumdulate the delta error (rectified half wave errot)
	// Have reasonable hard clamps because it can accumulate forever
	// Run at 48 Mhz, with thresh TH * 192 and PWM when on adds in -TH.
    // PWM turns on if acc > 192 * TH, and turns off when acc < 0; give 4us min pulse width
	// PWM edge placement will have teh 48Mhz resoution (~20ns)

	// Use 4 input bits to provide control over the 4us threshold 
	reg [31:0] thresh, thresh4us;
	reg [3:0] th_sel;
	always @(posedge clk) begin
    	th_sel 		<= ui_in[7:4]; // register inputs
		thresh    	<= 2'b01 << (7+th_sel); // ranges from 2^7 to 2^22
		thresh4us	<= 2'b11 << (13+th_sel);// is 192 * thresh
	end;

	reg [31:0] fast_acc;
	wire [31:0] next_acc;
	assign next_acc = fast_acc + ((gate[1])?{{24{delta[11]}},delta[11:0]}:0) - ((pwm)?thresh:0);
	reg fast_pwm;
	always @(posedge clk) begin
		if( reset ) begin
			fast_acc <= 0;
			fast_pwm <= 0;
		end else begin
			fast_acc <= ( next_acc[31:30] == 2'b01 ) ? 32'h3FFF_FFFF :
                       	( next_acc[31:30] == 2'b10 ) ? 32'hC000_0000 : next_acc;
			fast_pwm <= ( !fast_acc[31] && fast_acc > thresh4us ) ? 1'b1 : 
                        (  fast_acc[31]                         ) ? 1'b0 : fast_pwm;
		end
	end

	assign uo_out[4] = fast_pwm;

endmodule
