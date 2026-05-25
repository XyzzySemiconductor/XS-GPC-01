<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

output bits to drive two(2) FET H-Bridge, one for reference (stimulus) 60 Hz AC generation, and one for AC Load simulating the hydro grid.
The pwm waveforms are generated from cordic sin/cos generation. Serial ADC feedback is used to modulate the AC Load based feedback phase.

## How to test

Will provide some test controls
certainly allow free run sin/cos 60Hz PWM output with simple R/C can view on a osciloscope.A
Sync a wave generator to the generated AC,
Should also allow for ADC sin wave input, ( stretch: convert to PWM for output ), 
Observe teh AC load pwm gating while varying generated AC wave.

Alt: FPGA with system model, or stretch for BIST

## External hardware

The system (real or simulated)
Stimulus drivers, Hbridge
AC Load drivers, Hbridge
Resistive dump load
Grid tie solar inverter(s)
Instrumented serial ADC for feedback



