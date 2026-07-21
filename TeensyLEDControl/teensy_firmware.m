function fw = teensy_firmware(name)
% TEENSY_FIRMWARE  Factory for a selectable Teensy LED firmware driver.
%
%   fw = TEENSY_FIRMWARE(NAME) returns a struct of function handles that
%   build the serial command lines for the named Teensy firmware dialect.
%   This is the single seam that lets FBDC-J drive either the old or the
%   new LED controller software -- choose it from your rig settings.
%
%   Supported NAME values:
%     'flybowl2015'    - "Fly Bowl interface 20150615" (IR + Chrimson).
%                        Chrimson needs CHR n AND ON 0,0 (quadrant enable)
%                        to emit; camera-verified on the physical board.
%     'rgb_cmdarduino' - RGB_LED.ino CmdArduino (RED/GRN/BLU/IR).
%
%   The returned struct FW has fields:
%     .name                     firmware name
%     .channels                 cellstr of canonical channel names
%     .setChannel(channel,pct)  -> cellstr of command lines
%     .allOff()                 -> cellstr of command lines
%     .pulse(channel,pattern)   -> cellstr of command lines
%     .versionCmd()             -> char, the identity query command
%
%   PATTERN is a struct with fields: intensity (0-1), pulse_width_ms,
%   pulse_period_ms, num_pulses, inter_iteration_pause_ms, num_iterations.
%
%   The command lines are returned (not sent) so they can be unit-tested
%   without hardware; TeensyLEDController writes them to the serial port.

switch lower(strtrim(name))
  case 'flybowl2015'
    fw = flybowl2015();
  case 'rgb_cmdarduino'
    fw = rgb_cmdarduino();
  otherwise
    error('teensy_firmware:unknownFirmware', ...
      'Unknown LED firmware "%s". Options: flybowl2015, rgb_cmdarduino', ...
      name);
end

end  % function


% =====================================================================
% flybowl2015 : "Fly Bowl interface 20150615"
% =====================================================================
function fw = flybowl2015()
fw.name       = 'flybowl2015';
fw.channels   = {'ir', 'chrimson'};
fw.setChannel = @flybowl_setChannel;
fw.allOff     = @flybowl_allOff;
fw.pulse      = @flybowl_pulse;
fw.versionCmd = @() '???';
end  % function

function lines = flybowl_setChannel(channel, pct)
ch  = resolveChannel(channel, {'ir', 'chrimson'}, ...
        struct('opto', 'chrimson', 'red', 'chrimson', ...
               'stim', 'chrimson', 'backlight', 'ir'));
pct = clampPercent(pct);
if strcmp(ch, 'ir')
  lines = {sprintf('IR %d', pct)};
else  % chrimson: set level and toggle the quadrant-enable pins
  if pct > 0
    lines = {sprintf('CHR %d', pct), 'ON 0,0'};
  else
    lines = {'CHR 0', 'OFF 0,0'};
  end
end
end  % function

function lines = flybowl_allOff()
lines = {'CHR 0', 'IR 0', 'OFF 0,0', 'STOP'};
end  % function

function lines = flybowl_pulse(channel, pattern)
setLines = flybowl_setChannel(channel, 100 * pattern.intensity);
pulseLine = sprintf('PULSE,%d,%d,%d,%d,%d,%d', ...
  round(pattern.pulse_width_ms), round(pattern.pulse_period_ms), ...
  pattern.num_pulses, round(pattern.inter_iteration_pause_ms), ...
  0, pattern.num_iterations);
lines = [setLines, {pulseLine, 'RUN'}];
end  % function


% =====================================================================
% rgb_cmdarduino : RGB_LED.ino (CmdArduino)
% =====================================================================
function fw = rgb_cmdarduino()
fw.name       = 'rgb_cmdarduino';
fw.channels   = {'red', 'green', 'blue', 'ir'};
fw.setChannel = @rgb_setChannel;
fw.allOff     = @rgb_allOff;
fw.pulse      = @rgb_pulse;
fw.versionCmd = @() '???';
end  % function

function cmd = rgb_levelCmd(ch)
map = struct('red', 'RED', 'green', 'GRN', 'blue', 'BLU', 'ir', 'IR');
cmd = map.(ch);
end  % function

function lines = rgb_setChannel(channel, pct)
ch  = resolveChannel(channel, {'red', 'green', 'blue', 'ir'}, ...
        struct('chrimson', 'red', 'opto', 'red', ...
               'grn', 'green', 'blu', 'blue', 'backlight', 'ir'));
pct = clampPercent(pct);
if pct > 0
  lines = {sprintf('%s %d', rgb_levelCmd(ch), pct), 'ON 0'};
else
  lines = {sprintf('%s %d', rgb_levelCmd(ch), pct), 'OFF 0'};
end
end  % function

function lines = rgb_allOff()
lines = {'RED 0', 'GRN 0', 'BLU 0', 'IR 0', 'OFF 0', 'STOP'};
end  % function

function lines = rgb_pulse(channel, pattern)
ch  = resolveChannel(channel, {'red', 'green', 'blue', 'ir'}, ...
        struct('chrimson', 'red', 'opto', 'red', ...
               'grn', 'green', 'blu', 'blue', 'backlight', 'ir'));
pct = clampPercent(100 * pattern.intensity);
colourLetter = struct('red', 'R', 'green', 'G', 'blue', 'B', 'ir', 'S');
pulseLine = sprintf('PULSE %d,%d,%d,%d,%d,%d,%s', ...
  round(pattern.pulse_width_ms), round(pattern.pulse_period_ms), ...
  pattern.num_pulses, round(pattern.inter_iteration_pause_ms), ...
  0, pattern.num_iterations, colourLetter.(ch));
lines = {sprintf('%s %d', rgb_levelCmd(ch), pct), pulseLine, 'RUN'};
end  % function


% =====================================================================
% shared helpers
% =====================================================================
function ch = resolveChannel(channel, channels, aliases)
key = lower(strtrim(channel));
if isfield(aliases, key)
  key = aliases.(key);
end
if ~any(strcmp(key, channels))
  error('teensy_firmware:unknownChannel', ...
    'Unknown channel "%s". Available: %s', channel, strjoin(channels, ', '));
end
ch = key;
end  % function

function pct = clampPercent(intensity)
% Accepts either a fraction in [0,1] or an already-scaled percent.
pct = round(intensity);
pct = max(0, min(100, pct));
end  % function
