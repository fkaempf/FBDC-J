classdef TeensyLEDController < handle
%TEENSYLEDCONTROLLER  Firmware-selectable Teensy LED controller.
%   Drives the FlyBowl / Olfactory-Arena optogenetics board over a serial
%   port.  The firmware dialect is chosen at construction so the same
%   FBDC-J code runs boards flashed with either the old ('flybowl2015')
%   or the new ('rgb_cmdarduino') Teensy software -- see TEENSY_FIRMWARE.
%
%   Example:
%     led = TeensyLEDController('flybowl2015', 'COM4');
%     led.connect();
%     led.setIR(50);      % IR backlight to 50 %
%     led.setOpto(40);    % Chrimson to 40 % (auto-enables quadrants)
%     led.allOff();
%     led.disconnect();
%
%   Command construction lives in TEENSY_FIRMWARE (pure and unit-tested);
%   this class only performs serial I/O.

    properties (SetAccess = immutable)
        firmware   % firmware name, e.g. 'flybowl2015'
        port       % serial port, e.g. 'COM4'
        baud       % baud rate (USB-CDC ignores it)
    end

    properties (Access = private)
        fw         % firmware driver struct from teensy_firmware()
        s = []     % serialport object (empty until connect())
    end

    methods
        function obj = TeensyLEDController(firmware, port, baud)
        %TEENSYLEDCONTROLLER  Build a controller for the named firmware.
            if nargin < 3 || isempty(baud), baud = 19200; end
            obj.firmware = firmware;
            obj.port = port;
            obj.baud = baud;
            obj.fw = teensy_firmware(firmware);  % errors if unknown
        end

        function connect(obj)
        %CONNECT  Open the serial port (CR-terminated lines).
            obj.s = serialport(obj.port, obj.baud);
            configureTerminator(obj.s, "CR");
            obj.s.Timeout = 0.5;
        end

        function disconnect(obj)
        %DISCONNECT  Turn everything off and release the port.
            if ~isempty(obj.s)
                try
                    obj.sendLines(obj.fw.allOff());
                catch
                end
                obj.s = [];
            end
        end

        function setIR(obj, intensityPercent)
        %SETIR  Set the IR backlight, percent 0-100.
            obj.sendLines(obj.fw.setChannel('ir', intensityPercent));
        end

        function setOpto(obj, intensityPercent, channel)
        %SETOPTO  Set the opto (Chrimson/colour) channel, percent 0-100.
            if nargin < 3, channel = 'opto'; end
            obj.sendLines(obj.fw.setChannel(channel, intensityPercent));
        end

        function allOff(obj)
        %ALLOFF  Turn all channels off and halt any pattern.
            obj.sendLines(obj.fw.allOff());
        end

        function pulse(obj, channel, pattern)
        %PULSE  Program and run a pulse train (PATTERN struct).
        %   PATTERN fields: intensity (0-1), pulse_width_ms,
        %   pulse_period_ms, num_pulses, inter_iteration_pause_ms,
        %   num_iterations.
            obj.sendLines(obj.fw.pulse(channel, pattern));
        end

        function stop(obj)
        %STOP  Stop a running pulse train.
            obj.sendLines({'STOP'});
        end

        function v = version(obj)
        %VERSION  Query and return the firmware identity string.
            writeline(obj.s, obj.fw.versionCmd());
            v = '';
            t = tic;
            while toc(t) < 0.5
                line = readline(obj.s);
                if strlength(line) > 0
                    v = [v char(line) ' ']; %#ok<AGROW>
                end
            end
            v = strtrim(v);
        end
    end

    methods (Access = private)
        function sendLines(obj, lines)
        %SENDLINES  Write a cellstr of command lines to the port.
            assert(~isempty(obj.s), 'TeensyLEDController:notConnected', ...
                'Call connect() before sending commands.');
            for i = 1:numel(lines)
                writeline(obj.s, lines{i});
            end
        end
    end
end
