// vim: ts=4:
/*
 * Copyright (c) 2026 Eric Pearson
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
  assign uo_out[7:4]  = 0; 
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, ui_in, uio_in, 1'b0};
	
	wire reset;
	assign reset = !rst_n;

	// Gate input reg CC crossing meta regs
	reg [4:0] gate_cc, gate;
	always @(posedge clk) begin
		gate_cc <= ui_in[6:2];
		gate <= gate_cc;
	end

	// ADC Input
	wire strobe; // 1 cycle pulse every 16 cycles
	wire [11:0] ac_data, dc_data; // 2s comp adc input data
	adc_in i_adc (
		.clk( clk ),
		.reset( reset ),
		.ad_cs( uo_out[0] ),
		.ad_sdata( ui_in[1:0] ),
		.ad_out0( ac_data ),
		.ad_out1( dc_data ),
		.ad_strobe( strobe )
	);

	// Cordic unit
	reg [15:0] angle;
	wire [15:0] sin_out, cos_out;
	wire valid, busy;
	/*
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
	*/

		

	// Count angle every start pulse (-25000 to 24999 )
   	// at 3Mhz (48Mhz/16) this gives us exactly 60 Hz grid freq

	reg polarity;
	reg pdir;
	always @(posedge clk) begin
		if( reset ) begin
			angle <= 12500;
			polarity <= 0;
			pdir <= 0;
		end else begin
			if( strobe ) begin
				angle <= angle + (( pdir ) ? 1 : -1);
		    	polarity <= ( angle == 12499 && pdir == 1 ) ? ~polarity : polarity;
				pdir <= ( pdir == 0 && angle == 1 ) ? 1 : ( pdir == 1 && angle == 12499 ) ? 0 : pdir;
			end
		end
	end

	// Multiply cos by 3: to nicely fill dynamic range
	wire signed [11:0] cos3x;
	//assign cos3x = cos_out[15-:12] + ( cos_out[15-:12] >>> 1 );

    /////////////////////
	// Build a rom
	//reg signed [11:0] cos_rom[255:0];
	//initial for( int ii = 0; ii < 256; ii++ ) 
	//	cos_rom[ii] <= 12'sd0;
	//reg [15:0] prev_angle;
	//always @(posedge clk) begin
	//	prev_angle <= angle;
	//	if( strobe )
	//		if( cos_rom[prev_angle[14-:8]] == 0 )  cos_rom[prev_angle[14-:8]] <= cos3x;
	//end
	//always @(posedge clk) begin
	//	if( strobe && angle == 12499 ) 
	//		for( int ii = 0; ii < 256; ii++ )
	//		$display("cos_rom[%0d] = 12'sd%0d;", ii, cos_rom[ii] );
	//end
	///////////////////
    reg [11:0] cos_rom [127:0];
	initial begin
cos_rom[0] = 12'sd1543;
cos_rom[1] = 12'sd1542;
cos_rom[2] = 12'sd1542;
cos_rom[3] = 12'sd1540;
cos_rom[4] = 12'sd1539;
cos_rom[5] = 12'sd1537;
cos_rom[6] = 12'sd1536;
cos_rom[7] = 12'sd1533;
cos_rom[8] = 12'sd1530;
cos_rom[9] = 12'sd1527;
cos_rom[10] = 12'sd1522;
cos_rom[11] = 12'sd1518;
cos_rom[12] = 12'sd1513;
cos_rom[13] = 12'sd1509;
cos_rom[14] = 12'sd1503;
cos_rom[15] = 12'sd1498;
cos_rom[16] = 12'sd1492;
cos_rom[17] = 12'sd1485;
cos_rom[18] = 12'sd1479;
cos_rom[19] = 12'sd1471;
cos_rom[20] = 12'sd1462;
cos_rom[21] = 12'sd1455;
cos_rom[22] = 12'sd1447;
cos_rom[23] = 12'sd1438;
cos_rom[24] = 12'sd1429;
cos_rom[25] = 12'sd1419;
cos_rom[26] = 12'sd1410;
cos_rom[27] = 12'sd1399;
cos_rom[28] = 12'sd1389;
cos_rom[29] = 12'sd1377;
cos_rom[30] = 12'sd1366;
cos_rom[31] = 12'sd1354;
cos_rom[32] = 12'sd1342;
cos_rom[33] = 12'sd1330;
cos_rom[34] = 12'sd1317;
cos_rom[35] = 12'sd1305;
cos_rom[36] = 12'sd1290;
cos_rom[37] = 12'sd1276;
cos_rom[38] = 12'sd1263;
cos_rom[39] = 12'sd1248;
cos_rom[40] = 12'sd1233;
cos_rom[41] = 12'sd1218;
cos_rom[42] = 12'sd1203;
cos_rom[43] = 12'sd1186;
cos_rom[44] = 12'sd1171;
cos_rom[45] = 12'sd1155;
cos_rom[46] = 12'sd1138;
cos_rom[47] = 12'sd1122;
cos_rom[48] = 12'sd1104;
cos_rom[49] = 12'sd1089;
cos_rom[50] = 12'sd1071;
cos_rom[51] = 12'sd1053;
cos_rom[52] = 12'sd1035;
cos_rom[53] = 12'sd1015;
cos_rom[54] = 12'sd997;
cos_rom[55] = 12'sd978;
cos_rom[56] = 12'sd958;
cos_rom[57] = 12'sd939;
cos_rom[58] = 12'sd919;
cos_rom[59] = 12'sd900;
cos_rom[60] = 12'sd879;
cos_rom[61] = 12'sd859;
cos_rom[62] = 12'sd838;
cos_rom[63] = 12'sd816;
cos_rom[64] = 12'sd795;
cos_rom[65] = 12'sd774;
cos_rom[66] = 12'sd753;
cos_rom[67] = 12'sd730;
cos_rom[68] = 12'sd709;
cos_rom[69] = 12'sd687;
cos_rom[70] = 12'sd664;
cos_rom[71] = 12'sd642;
cos_rom[72] = 12'sd619;
cos_rom[73] = 12'sd597;
cos_rom[74] = 12'sd573;
cos_rom[75] = 12'sd550;
cos_rom[76] = 12'sd528;
cos_rom[77] = 12'sd504;
cos_rom[78] = 12'sd480;
cos_rom[79] = 12'sd456;
cos_rom[80] = 12'sd432;
cos_rom[81] = 12'sd408;
cos_rom[82] = 12'sd384;
cos_rom[83] = 12'sd360;
cos_rom[84] = 12'sd336;
cos_rom[85] = 12'sd312;
cos_rom[86] = 12'sd288;
cos_rom[87] = 12'sd262;
cos_rom[88] = 12'sd238;
cos_rom[89] = 12'sd214;
cos_rom[90] = 12'sd190;
cos_rom[91] = 12'sd165;
cos_rom[92] = 12'sd141;
cos_rom[93] = 12'sd115;
cos_rom[94] = 12'sd90;
cos_rom[95] = 12'sd66;
cos_rom[96] = 12'sd40;
cos_rom[97] = 12'sd16;
cos_rom[98] = 12'sd0;
cos_rom[99] = 12'sd0;
cos_rom[100] = 12'sd0;
cos_rom[101] = 12'sd0;
cos_rom[102] = 12'sd0;
cos_rom[103] = 12'sd0;
cos_rom[104] = 12'sd0;
cos_rom[105] = 12'sd0;
cos_rom[106] = 12'sd0;
cos_rom[107] = 12'sd0;
cos_rom[108] = 12'sd0;
cos_rom[109] = 12'sd0;
cos_rom[110] = 12'sd0;
cos_rom[111] = 12'sd0;
cos_rom[112] = 12'sd0;
cos_rom[113] = 12'sd0;
cos_rom[114] = 12'sd0;
cos_rom[115] = 12'sd0;
cos_rom[116] = 12'sd0;
cos_rom[117] = 12'sd0;
cos_rom[118] = 12'sd0;
cos_rom[119] = 12'sd0;
cos_rom[120] = 12'sd0;
cos_rom[121] = 12'sd0;
cos_rom[122] = 12'sd0;
cos_rom[123] = 12'sd0;
cos_rom[124] = 12'sd0;
cos_rom[125] = 12'sd0;
cos_rom[126] = 12'sd0;
cos_rom[127] = 12'sd0;
	end
    assign valid = 1;
	assign cos3x = cos_rom[angle[13-:7]];
	
	// Correct Polarity (just negate)
	reg signed [11:0] sin, absin;
	always @(posedge clk) begin
		if( reset ) begin
			sin <= 0;
			absin <= 0;
		end else if( valid ) begin
			sin   <= ( polarity ) ? ~cos3x : cos3x; // use cos as it aligns with polarity
			absin <= cos3x; // since cordic works over -/+pi/2
		end
	end

	// Accumulate error function
	// and gates PWM outputs with
	// guaranteed min pulse width of 4us
	reg signed [19:0] sin_err;
	reg sin_pwm_p, sin_pwm_n;

	always @(posedge clk) begin
		if( reset ) begin
			sin_pwm_p <= 0;
			sin_pwm_n <= 0;
			sin_err <= 0;
		end else begin
			sin_pwm_p <= ( sin_err >  1544 * 12 * 16 ) ? 1 : ( sin_err < 0 ) ? 0 : sin_pwm_p;
			sin_pwm_n <= ( sin_err < -1544 * 12 * 16 ) ? 1 : ( sin_err > 0 ) ? 0 : sin_pwm_n;
			sin_err <= sin_err + ((gate[0])?sin:0) + ((sin_pwm_p)?-1544:(sin_pwm_n)?1544:0);
		end
 	end

	assign uo_out[1] = sin_pwm_p;
	assign uo_out[2] = sin_pwm_n;

	// Output PWM based on gated absin.

	reg signed [19:0] absin_err, absin_in;
	reg absin_pwm;
	reg th_gate, dc_th_gate; // U > thresh gate
	always @(posedge clk) begin
		if( reset ) begin
			absin_in <= 0;
			absin_pwm <= 0;
			absin_err <= 0;
		end else begin
			absin_pwm <= ( absin_err >  1544 * 12 * 16 ) ? 1 : ( absin_err < 0 ) ? 0 : absin_pwm;
			absin_in  <= (gate[1]&&(th_gate|dc_th_gate))?absin:0;
			absin_err <= absin_err + absin_in - ((absin_pwm)?1544:0);
		end
 	end

	assign uo_out[3] = absin_pwm;

	/////////////
	//	AC Loop
	/////////////

	// Pseduo energy is the voltage error from leading AC, ie phase error from generator energy
	reg signed [11:0] delta;
	wire dc_very_low;
	always @(posedge clk) begin
		delta  <= ( gate[2] && !dc_very_low ) ? ac_data - sin : 0;
	end


	// Accumdulate the delta error 'u' 
	// Have reasonable hard clamps because it can accumulate forever
	reg signed [25:0] fast_acc;
	wire signed [25:0] next_acc;
	assign next_acc = fast_acc + delta - (( !fast_acc[25] && (|fast_acc[24-:5]) ) ? absin : 'sd0 );
	always @(posedge clk) begin
		if( reset ) begin
			fast_acc <= 0;
		end else begin
			fast_acc <= ( next_acc[25] != next_acc[24] ) ? {next_acc[25], {25{~next_acc[25]}}} : next_acc;
		end
	end

	// Low pass filter u : TBD

	// Threhold filterer u;
	always @(posedge clk)
		th_gate <= !fast_acc[25] & |fast_acc[24-:5]; // can be modulate down

	/////////////
	//	DC Loop
	/////////////

	// Pseduo energy is the voltage error from Vref DC
	reg signed [30:0] dc_delta;
	always @(posedge clk) begin
		dc_delta  <= ( gate[3] ) ? dc_data - (( gate[4] ) ? 12'h800 : 0 ) : 0;; 
	end

	// Accumdulate the delta error 'u' 
	// Have reasonable hard clamps because it can accumulate forever
	reg signed [30:0] dc_fast_acc;
	wire signed [30:0] dc_next_acc;
	assign dc_next_acc = dc_fast_acc + dc_delta - ((!dc_fast_acc[30] & |dc_fast_acc[29-:6] ) ? absin : 0 );
	always @(posedge clk) begin
		if( reset ) begin
			dc_fast_acc <= 0;
		end else begin
			dc_fast_acc <= ( dc_next_acc[30] != dc_next_acc[29] ) ? {dc_next_acc[30], {30{~dc_next_acc[30]}}} : dc_next_acc;
		end
	end

	assign dc_very_low = dc_fast_acc[30] & !dc_fast_acc[28];

	// Low pass filter u : TBD

	// Threhold filterer u;

	always @(posedge clk)
		dc_th_gate <= !dc_fast_acc[30] & |dc_fast_acc[29-:6];

endmodule
