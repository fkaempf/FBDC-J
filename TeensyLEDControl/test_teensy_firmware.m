function test_teensy_firmware()
%TEST_TEENSY_FIRMWARE  Hardware-free unit tests for the firmware layer.
%   Verifies that each selectable Teensy firmware emits the exact serial
%   command lines.  Errors on the first failure (non-zero exit under
%   `matlab -batch`); prints a summary on success.
%
%   Run:  matlab -batch "cd('TeensyLEDControl'); test_teensy_firmware"

    n = 0;
    function check(cond, msg)
        n = n + 1;
        assert(cond, 'TEST FAILED: %s', msg);
    end
    eq = @(a, b) isequal(a, b);

    pat = struct('intensity', 0.5, 'pulse_width_ms', 10, ...
        'pulse_period_ms', 50, 'num_pulses', 3, ...
        'inter_iteration_pause_ms', 0, 'num_iterations', 1);

    % ---- flybowl2015 (old firmware) ----
    fw = teensy_firmware('flybowl2015');
    check(eq(fw.setChannel('ir', 40), {'IR 40'}), 'fb ir');
    check(eq(fw.setChannel('chrimson', 40), {'CHR 40', 'ON 0,0'}), ...
        'fb chrimson enables quadrants');
    check(eq(fw.setChannel('chrimson', 0), {'CHR 0', 'OFF 0,0'}), ...
        'fb chrimson zero disables');
    check(eq(fw.setChannel('opto', 100), {'CHR 100', 'ON 0,0'}), ...
        'fb opto alias -> chrimson');
    check(eq(fw.allOff(), {'CHR 0', 'IR 0', 'OFF 0,0', 'STOP'}), ...
        'fb all off');
    check(eq(fw.pulse('chrimson', pat), ...
        {'CHR 50', 'ON 0,0', 'PULSE,10,50,3,0,0,1', 'RUN'}), ...
        'fb pulse train');

    % ---- rgb_cmdarduino (new firmware) ----
    fw2 = teensy_firmware('rgb_cmdarduino');
    check(eq(fw2.setChannel('red', 40), {'RED 40', 'ON 0'}), 'rgb red');
    check(eq(fw2.setChannel('green', 0), {'GRN 0', 'OFF 0'}), ...
        'rgb green zero');
    check(eq(fw2.setChannel('ir', 50), {'IR 50', 'ON 0'}), 'rgb ir');
    check(eq(fw2.setChannel('chrimson', 100), {'RED 100', 'ON 0'}), ...
        'rgb chrimson alias -> red');
    check(eq(fw2.allOff(), ...
        {'RED 0', 'GRN 0', 'BLU 0', 'IR 0', 'OFF 0', 'STOP'}), ...
        'rgb all off');
    check(eq(fw2.pulse('red', pat), ...
        {'RED 50', 'PULSE 10,50,3,0,0,1,R', 'RUN'}), 'rgb pulse train');

    % ---- firmware selection + error handling ----
    threw = false;
    try
        teensy_firmware('nope');
    catch e
        threw = strcmp(e.identifier, 'teensy_firmware:unknownFirmware');
    end
    check(threw, 'unknown firmware rejected');

    threw = false;
    try
        fw.setChannel('blue', 10);  % flybowl2015 has no blue channel
    catch e
        threw = strcmp(e.identifier, 'teensy_firmware:unknownChannel');
    end
    check(threw, 'unknown channel rejected');

    fprintf('ALL %d TEENSY FIRMWARE TESTS PASSED\n', n);
end
