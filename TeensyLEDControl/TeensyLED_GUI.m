function TeensyLED_GUI(geomfile, stopfile)
%TEENSYLED_GUI  Minimal MATLAB GUI to drive the Teensy LED board.
%   A window with IR / Chrimson / All-off buttons wired to
%   TeensyLEDController. Writes each button's on-screen centre (top-left
%   origin) to GEOMFILE so an automated "real user" cursor driver can
%   click them, and stays open until STOPFILE appears.

if nargin < 1, geomfile = 'matlab_geom.json'; end
if nargin < 2, stopfile = 'matlab_stop.flag'; end

led = TeensyLEDController('flybowl2015', 'COM4', 19200);
led.connect();

fig = figure('Name', 'FBDC-J Teensy LED', 'NumberTitle', 'off', ...
    'MenuBar', 'none', 'ToolBar', 'none', 'Position', [320 320 360 240]);
uicontrol(fig, 'Style', 'text', 'Position', [20 195 320 24], ...
    'String', 'firmware: flybowl2015', 'FontWeight', 'bold', ...
    'FontSize', 11);
bIR = uicontrol(fig, 'Style', 'pushbutton', 'Position', [20 140 150 44], ...
    'String', 'IR 60%', 'FontSize', 11, ...
    'Callback', @(s, e) led.setIR(60));
bCH = uicontrol(fig, 'Style', 'pushbutton', 'Position', [190 140 150 44], ...
    'String', 'Chrimson 60%', 'FontSize', 11, ...
    'Callback', @(s, e) led.setOpto(60));
bOFF = uicontrol(fig, 'Style', 'pushbutton', 'Position', [20 80 320 44], ...
    'String', 'All off', 'FontSize', 11, ...
    'Callback', @(s, e) led.allOff());
drawnow;

% Button centres in screen pixels, converted to a top-left origin.
ss = get(0, 'ScreenSize'); H = ss(4);
FX = fig.Position(1); FY = fig.Position(2);
centre = @(b) struct( ...
    'x', round(FX + b.Position(1) + b.Position(3) / 2), ...
    'y', round(H - (FY + b.Position(2) + b.Position(4) / 2)));
geom = struct('ir', centre(bIR), 'chr', centre(bCH), 'off', centre(bOFF));
fid = fopen(geomfile, 'w');
fprintf(fid, '%s', jsonencode(geom));
fclose(fid);

% Keep the GUI open until the driver signals completion (or a timeout).
t0 = tic;
while exist(stopfile, 'file') == 0 && toc(t0) < 120
    pause(0.2);
    drawnow;
end

led.allOff();
led.disconnect();
if isvalid(fig), close(fig); end
end
