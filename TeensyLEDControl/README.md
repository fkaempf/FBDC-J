# TeensyLEDControl — selectable Teensy LED firmware for FBDC-J

Drive the FlyBowl / Olfactory-Arena optogenetics Teensy from MATLAB, with
the **firmware dialect chosen at runtime** so the same FBDC-J code works
whichever software is flashed on the board.

## Choosing the firmware

| firmware | channels | notes |
|----------|----------|-------|
| `flybowl2015` | IR, Chrimson | old *"Fly Bowl interface 20150615"*. Chrimson needs `CHR n` **and** `ON 0,0` (quadrant enable) to emit — camera-verified on the physical board. |
| `rgb_cmdarduino` | RED/GRN/BLU/IR | new `RGB_LED.ino` (CmdArduino). |

```matlab
% pick the firmware for this rig (e.g. from your FBDC parameter file)
led = TeensyLEDController('flybowl2015', 'COM4');   % or 'rgb_cmdarduino'
led.connect();
led.setIR(50);        % IR backlight to 50 %
led.setOpto(40);      % Chrimson to 40 % (auto-enables quadrants)

pat = struct('intensity',0.6,'pulse_width_ms',20,'pulse_period_ms',100, ...
             'num_pulses',10,'inter_iteration_pause_ms',0,'num_iterations',1);
led.pulse('chrimson', pat);   % programmed pulse train + RUN
led.allOff();
led.disconnect();
```

To wire it into the FBDC GUI, read a `LEDControllerFirmware` value from the
rig parameter file and pass it to the constructor — everything downstream
is firmware-agnostic.

## Design

- **`teensy_firmware.m`** — factory: `teensy_firmware(name)` returns a
  struct of function handles that *build* the serial command lines for the
  chosen firmware (pure, so it is unit-tested with no hardware). This is
  the single seam that selects the dialect.
- **`TeensyLEDController.m`** — a `handle` class that opens the serial port
  and *writes* the lines the firmware produces.
- **`test_teensy_firmware.m`** — hardware-free tests asserting the exact
  command strings for both firmwares.

Mirrors the Python implementation in
[`flocroscope` `hardware/opto`](https://github.com/fkaempf/flocroscope),
and is modelled on the original `olfactoryArena_LED_control.m`.

## Running the tests

```
matlab -batch "cd('TeensyLEDControl'); test_teensy_firmware"
```
