classdef LegacySerialShim < handle
%LEGACYSERIALSHIM  Drop-in replacement for the removed legacy `serial` object.
%   R2026a deprecated/removed the Instrument Control Toolbox `serial` object
%   (the fopen / fprintf / fscanf / BytesAvailable / fclose surface). The
%   FlyBowl LED code (flyBowl_LED_control, InitializeChRStimulus,
%   LEDControllerStartupShutdown) was written against that old API, so it
%   fails on this machine with "serial will be removed ...".
%
%   This shim presents the exact same small surface those callers use, but
%   drives the port through the modern `serialport` API underneath -- the
%   same shim trick used to run BIAS on the new Spinnaker. Swap
%       s = serial(port,'BaudRate',115200,'Terminator','CR');
%   for
%       s = LegacySerialShim(port,'BaudRate',115200,'Terminator','CR');
%   and fopen/fprintf/fscanf/fclose/delete/BytesAvailable keep working.
%
%   Only the subset the LED code actually calls is implemented.

    properties
        Port = '';
        BaudRate = 9600;
        Terminator = 'CR';
    end
    properties (Access = private)
        sp = [];   % underlying serialport object (empty until fopen)
    end
    properties (Dependent)
        BytesAvailable
    end

    methods
        function obj = LegacySerialShim(port, varargin)
        %LEGACYSERIALSHIM  Mimic serial(port,'BaudRate',b,'Terminator',t).
        %   Like the legacy object, construction does NOT open the port;
        %   call fopen(obj) to open it.
            obj.Port = port;
            for i = 1:2:numel(varargin)-1
                switch lower(varargin{i})
                    case 'baudrate',   obj.BaudRate   = varargin{i+1};
                    case 'terminator', obj.Terminator = varargin{i+1};
                end
            end
        end

        function fopen(obj)
        %FOPEN  Open the port (mirrors fopen on a legacy serial object).
            obj.sp = serialport(obj.Port, obj.BaudRate);
            configureTerminator(obj.sp, obj.mapTerminator(obj.Terminator));
            obj.sp.Timeout = 0.5;
        end

        function fprintf(obj, varargin)
        %FPRINTF  Send a command line (writeline appends the terminator).
        %   Supports fprintf(s,str) and fprintf(s,fmt,args...) like the
        %   legacy object, which defaults to text mode + terminator.
            assert(~isempty(obj.sp), 'LegacySerialShim:notOpen', ...
                'Call fopen before writing.');
            if numel(varargin) == 1
                str = varargin{1};
            else
                str = sprintf(varargin{:});
            end
            writeline(obj.sp, str);
        end

        function out = fscanf(obj)
        %FSCANF  Read one terminated line, returning '' on timeout.
            out = '';
            if isempty(obj.sp), return; end
            line = readline(obj.sp);
            if ~ismissing(line)
                out = char(line);
            end
        end

        function n = get.BytesAvailable(obj)
            if isempty(obj.sp)
                n = 0;
            else
                n = obj.sp.NumBytesAvailable;
            end
        end

        function fclose(obj)
        %FCLOSE  Release the port (the modern object closes on clear).
            obj.sp = [];
        end

        function delete(obj)
            obj.sp = [];
        end
    end

    methods (Static, Access = private)
        function t = mapTerminator(term)
            switch upper(strtrim(char(term)))
                case 'LF',              t = "LF";
                case {'CR/LF','CRLF'},  t = "CR/LF";
                otherwise,              t = "CR";
            end
        end
    end
end
