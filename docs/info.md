# **60 Hz Grid‑Forming ASIC with DC‑Link Dump‑Load Control**  
*A TinyTapeout ASIC for grid‑aware AC generation and power balancing*

This ASIC implements a **self‑contained, grid‑aware control loop** capable of generating a clean 60 Hz reference waveform while simultaneously regulating real‑power flow using a **DC‑link dump load**. It is designed for small AC micro‑systems where PV inverters, a low‑power grid‑former, and a resistive dump load must coexist without external controllers.

The chip senses the AC waveform, compares it to an internal CORDIC‑generated reference, and adjusts a DC‑side dump FET to maintain long‑term phase and amplitude stability. All control is performed on‑chip using add/shift arithmetic, a fast error accumulator, a slow IIR loop, and a minimum‑pulse‑width PWM engine.

---

## **Core Features**

- **CORDIC‑locked 60 Hz sine generator**  
  Produces a stable, phase‑accurate reference for a low‑power H‑bridge grid‑former.

- **AC‑side sensing (single ADC input)**  
  Samples the AC waveform at 3 MHz and compares it to the internal reference.

- **Fast error accumulator + slow IIR controller**  
  Forms a linear, stable control loop without multipliers.

- **DC‑link dump‑load PWM output**  
  Drives a single high‑voltage FET with enforced **4 µs minimum ON/OFF** times.

- **Four real‑time tuning gates**  
  External PWM or logic‑level inputs adjust loop behavior on the fly:
  - `gain_sine` — trims generated sine amplitude  
  - `gain_dump` — limits dump‑PWM strength (max dump power)  
  - `gain_loop` — adjusts IIR loop gain (loop stiffness)  
  - `gain_error` — scales fast error accumulation (effective threshold)

- **Safe, simple power topology**  
  Intended for use with a **rectified 240 V AC DC‑link** (VFD‑style front end) and a resistive dump load such as a water heater.

---

## **I/O Summary**

### **Inputs (`ui`)**
```
ui[0]  adc_sdata       # AC ADC serial data input (3 MHz sample stream)
ui[1]  gain_sine       # Sine amplitude trim (generation gain)
ui[2]  gain_dump       # Dump-PWM gain trim (max dump power)
ui[3]  gain_loop       # IIR loop feedback gain trim (loop stiffness)
ui[4]  error_error     # Error accumulation trim (effective threshold)
ui[5]  (unused)
ui[6]  (unused)
ui[7]  (unused)
```

### **Outputs (`uo`)**
```
uo[0]  adc_cs          # ADC chip-select / sample strobe
uo[1]  gen_pwm_p       # Grid-former PWM (positive leg)
uo[2]  gen_pwm_n       # Grid-former PWM (negative leg)
uo[3]  dump_pwm        # DC-link dump FET PWM (4 µs min pulse width)
uo[4]  (unused)
uo[5]  (unused)
uo[6]  (unused)
uo[7]  (unused)
```

---

## **Intended Use Case**

This ASIC is designed for experimental AC micro‑systems where:

- a **low‑power grid‑former** establishes the AC waveform  
- **PV inverters** inject unpredictable power
- **AC Appliances** use less energy than available
- a **DC‑link dump load** must absorb surplus energy  
- the system must remain stable without external controllers  

The chip maintains long‑term phase and amplitude alignment by modulating the dump load based solely on AC‑side sensing.

---

## **Status**

- RTL complete  
- Clean synthesis  
- Verified P&R on **1×2 tile**  
- ~87.5% utilization on 1×1 → **1×2 chosen**  
- Ready for TinyTapeout submission  
- verification pending
- validation pending
  
## Why is it?

Use my 10kw grid-tied solar system to power my home on the second day of a power outage.

A grid tied solar system becomes useless without the grid. Hybrid systems involve using batteries fix this, but are a big expense. If a grid tied solar system is disconnected from the grid and provided with a simulated grid the solar system will generate hydro AC. The issue is that grid tied inverters work by maximizing the energy delivery without restriction knowing that the grid can accept it, and it will vary with available sunlight.
If the energy is not dissipated the voltage and frequiency of the simulated grid will be driven out of spec and the grid tied inverters will shutdown (usually for at least 5 min). 

The energy from the sun needs to be always and exactly dissipated. This dissipation can be partially done by any electrical devices in the home, but something else needs dissipate the remainder. Heating water is a good way of dumping energy.

A device is proposed which will generate a reference 60Hz AC, and control dumping extra energy into a resistive load without needed a battery system.

Its a good fit for a tiny tapeout chip with low I/O count PWM and serial data, and 20ns PWM edge resolution
gives fine control, while maintaiing minimum pulse widths. 

Fitting this device into a tiny tapeout would remove all cost from the control part of the problem.

## How it works

A free running angle counter is input into a cordic rotational block and polarity corrected to calculate a 60Hz sine wave.
The sine wave is gated and then accumulated in PWM modulator produce bi-polar PWM signals which can be used to drive an H Bridge and
the low side of a transformer, with the high side providing the grid reference.

The AC 'grid' voltage is sampled by ADC. A psuedo energy error is calculated by accumulating the delta between ADC data and calculated sine, 
PLUS the gated PWM gating -|ADC| when energy is dumped into a load resistance (water heater). The accumulated energy error is low pass filtered and compared against a positive threshold and used along with an external gate to gate |sin| and accumulate to produce a PWM signal to drive the dump switch (fet).

The I/O is minimal with 2 I/O for the ADC, 3 pwm outputs and 4 pwm (gain control) inputs.  Total of 5 inputs and 3 outputs and a 48Mhz clock and rest signal.

## How to test

Tests I used to bring up the RTL with.

## External hardware

It will need a real or simulated (fpga) system to test:

    -Grid-tied solar system, sunlight
    -Hbridge and drivers
    -Step up transformer
    -Bridge Rectifier, DCLink Capactors
    -Dump FET and driver
    -Resistive Water Heater, water
    -ADC with isolated instrumentation.
    -external control panel (pwm base loop controls))


