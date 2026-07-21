function led_protocol_test(logfile)
%LED_PROTOCOL_TEST  Drive a stimulus protocol through TeensyLEDController.
%   Runs a timed protocol on the real board (COM4, flybowl2015) and logs
%   the wall-clock time of each command to LOGFILE (posix seconds). A
%   camera recorder running in parallel then reconstitutes the stimulus
%   from the measured brightness and checks it matches this log.

if nargin < 1, logfile = 'led_log.csv'; end

led = TeensyLEDController('flybowl2015', 'COM4', 19200);
led.connect();

% {type, value(percent), hold seconds}
steps = { {'off', 0, 3}, {'opto', 100, 3}, {'off', 0, 3}, ...
          {'opto', 50, 3}, {'off', 0, 3}, {'ir', 100, 3}, ...
          {'off', 0, 3}, {'pulse', 0, 4}, {'off', 0, 2} };

fid = fopen(logfile, 'w');
fprintf(fid, 't,type,value\n');
for i = 1:numel(steps)
    s = steps{i};
    t = posixtime(datetime('now', 'TimeZone', 'local'));
    fprintf(fid, '%.3f,%s,%g\n', t, s{1}, s{2});
    switch s{1}
        case 'off',  led.allOff();
        case 'opto', led.setOpto(s{2});
        case 'ir',   led.setIR(s{2});
        case 'pulse'
            pat = struct('intensity', 0.9, 'pulse_width_ms', 60, ...
                'pulse_period_ms', 160, 'num_pulses', 24, ...
                'inter_iteration_pause_ms', 0, 'num_iterations', 1);
            led.pulse('chrimson', pat);
    end
    pause(s{3});
end
led.allOff();
fprintf(fid, '%.3f,end,0\n', posixtime(datetime('now', 'TimeZone', 'local')));
led.disconnect();
fclose(fid);
disp('PROTOCOL DONE');
end
