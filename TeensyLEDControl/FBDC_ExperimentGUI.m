function FBDC_ExperimentGUI(geomfile, donefile, logfile)
%FBDC_EXPERIMENTGUI  Real FBDC-J behaviour experiment (MATLAB).
%   A one-button experiment GUI that executes a timed opto protocol on the
%   real TeensyLEDController (COM4, flybowl2015) while BIAS records the
%   video. Mirrors the flocroscope experiment (load protocol -> run trials).
%   Writes each step's wall-clock time to LOGFILE and DONEFILE when finished.
%   The Run button triggers the protocol; for unattended runs the protocol
%   also auto-starts a couple of seconds after the window appears.
if nargin < 1, geomfile = 'geom.json'; end
if nargin < 2, donefile = 'done.flag'; end
if nargin < 3, logfile  = 'proto_log.csv'; end

led = TeensyLEDController('flybowl2015', 'COM4', 19200);
led.connect();

fig = figure('Name', 'FBDC-J Experiment', 'NumberTitle', 'off', ...
    'MenuBar', 'none', 'ToolBar', 'none', 'Position', [320 320 380 200]);
uicontrol(fig, 'Style', 'text', 'Position', [20 150 340 34], 'FontSize', 10, ...
    'String', 'FBDC-J: run opto protocol (recorded via BIAS)');
bRun = uicontrol(fig, 'Style', 'pushbutton', 'Position', [40 55 300 64], ...
    'String', 'Run Experiment', 'FontSize', 13, 'Callback', @(~, ~) runExp());

H = get(groot, 'ScreenSize'); H = H(4);
FX = fig.Position(1); FY = fig.Position(2);
centre = @(b) struct( ...
    'x', round(FX + b.Position(1) + b.Position(3) / 2), ...
    'y', round(H - (FY + b.Position(2) + b.Position(4) / 2)));
geom = struct('run', centre(bRun));
fid = fopen(geomfile, 'w'); fprintf(fid, '%s', jsonencode(geom)); fclose(fid);
figure(fig); drawnow;

pause(2.5);      % let the harness start BIAS recording first
runExp();        % execute the protocol (Run button triggers the same)

    function runExp()
        if strcmp(get(bRun, 'Enable'), 'off'), return; end
        set(bRun, 'String', 'Running...', 'Enable', 'off'); drawnow;
        t0 = posixtime(datetime('now', 'TimeZone', 'local'));
        fid2 = fopen(logfile, 'w'); fprintf(fid2, 't,type,value\n');
        % protocol trials: {type, percent, hold seconds}
        steps = { {'off', 0, 3}, {'ir', 80, 3}, {'off', 0, 3}, ...
                  {'opto', 80, 3}, {'off', 0, 2} };
        for i = 1:numel(steps)
            s = steps{i};
            tt = posixtime(datetime('now', 'TimeZone', 'local')) - t0;
            fprintf(fid2, '%.3f,%s,%g\n', tt, s{1}, s{2});
            switch s{1}
                case 'off',  led.allOff();
                case 'ir',   led.setIR(s{2});
                case 'opto', led.setOpto(s{2});
            end
            pause(s{3});
        end
        led.allOff();
        fprintf(fid2, '%.3f,end,0\n', ...
            posixtime(datetime('now', 'TimeZone', 'local')) - t0);
        fclose(fid2);
        led.disconnect();
        set(bRun, 'String', 'Done'); drawnow;
        fid3 = fopen(donefile, 'w'); fclose(fid3);
    end
end
