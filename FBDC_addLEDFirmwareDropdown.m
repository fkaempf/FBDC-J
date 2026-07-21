function handles = FBDC_addLEDFirmwareDropdown(handles)
%FBDC_ADDLEDFIRMWAREDROPDOWN  Add the LED-board selector + live IR control.
%   Adds a "LED board:" label + popupmenu to the FBDC main window so the
%   operator can switch, at runtime, which Teensy firmware dialect the ChR
%   stimulus drives:
%       Incubator -> flybowl2015     (the currently connected board)
%       FlyDisco  -> rgb_cmdarduino
%   The choice is stored in handles.params.ChR_LED_firmware and consumed by
%   InitializeChRStimulus / LEDControllerStartupShutdown when the LED connects.
%
%   In the same row it adds an "IR:" edit box for the IR backlight intensity.
%   It is initialised from ChR_IrInt in the params file, and changing it
%   pushes the value to the board live once the LED is connected (see
%   FBDC_setIR).

labels = {'Incubator','FlyDisco'};
vals   = {'flybowl2015','rgb_cmdarduino'};

% default the dropdown to whatever the params currently say (Incubator otherwise)
defidx = 1;
if isfield(handles.params,'ChR_LED_firmware'),
  fw = handles.params.ChR_LED_firmware; if iscell(fw), fw = fw{1}; end
  j = find(strcmpi(strtrim(char(fw)),vals),1);
  if ~isempty(j), defidx = j; end
end

% initial IR value from the params file (ChR_IrInt, already numeric here)
irval = 50;
if isfield(handles.params,'ChR_IrInt') && isnumeric(handles.params.ChR_IrInt) ...
    && isscalar(handles.params.ChR_IrInt) && ~isnan(handles.params.ChR_IrInt),
  irval = round(handles.params.ChR_IrInt);
end

% Position the row in the empty gap between the Condition and Incubator
% dropdowns, matching the existing label+field layout. Fall back to a
% top-left placement if those controls can't be found. The row holds:
%   [LED board:] [dropdown]   [IR:] [ir box]
labelPos   = [8 592 62 18];
popPos     = [72 590 100 22];
irLabelPos = [176 592 18 18];
irBoxPos   = [196 590 46 22];
try
  set(handles.popupmenu_Condition,'Units','pixels');
  set(handles.popupmenu_Rearing_IncubatorID,'Units','pixels');
  cond = get(handles.popupmenu_Condition,'Position');           % above the gap
  inc  = get(handles.popupmenu_Rearing_IncubatorID,'Position'); % below the gap
  h    = cond(4);
  gapBottom = inc(2) + inc(4);
  gapTop    = cond(2);
  y = gapBottom + max(0,(gapTop - gapBottom - h)/2);
  dropW = 100;
  popPos     = [cond(1) y dropW h];
  labelPos   = [max(2,cond(1)-72) y+1 66 h-4];
  irLabelPos = [cond(1)+dropW+8 y+1 18 h-4];
  irBoxPos   = [cond(1)+dropW+28 y max(46,cond(3)-dropW-28) h];
catch
end

% split the IR field into an edit box + up/down ticker buttons
btnW  = 16;
editW = max(26, irBoxPos(3) - btnW);
editPos = [irBoxPos(1) irBoxPos(2) editW irBoxPos(4)];
upH   = ceil(irBoxPos(4)/2);
dnH   = floor(irBoxPos(4)/2);
upPos = [irBoxPos(1)+editW, irBoxPos(2)+dnH, btnW, upH];
dnPos = [irBoxPos(1)+editW, irBoxPos(2),      btnW, dnH];

set(handles.figure_main,'Units','pixels');

handles.text_LEDFirmware = uicontrol(handles.figure_main,'Style','text',...
  'Units','pixels','Position',labelPos,...
  'String','LED board:','HorizontalAlignment','right',...
  'Tag','text_LEDFirmware');

handles.popupmenu_LEDFirmware = uicontrol(handles.figure_main,'Style','popupmenu',...
  'Units','pixels','Position',popPos,...
  'String',labels,'Value',defidx,'Tag','popupmenu_LEDFirmware',...
  'TooltipString','Which Teensy LED firmware the ChR stimulus drives',...
  'Callback',@FBDC_setLEDFirmware);

handles.text_IR = uicontrol(handles.figure_main,'Style','text',...
  'Units','pixels','Position',irLabelPos,...
  'String','IR:','HorizontalAlignment','right',...
  'Tag','text_IR');

irtip = 'IR backlight 0-100 (live once camera is initialized); on flybowl2015, 8 and below = off (verified)';
handles.edit_IR = uicontrol(handles.figure_main,'Style','edit',...
  'Units','pixels','Position',editPos,...
  'String',num2str(irval),'Tag','edit_IR',...
  'TooltipString',irtip,...
  'Callback',@FBDC_setIR);

handles.pushbutton_IRup = uicontrol(handles.figure_main,'Style','pushbutton',...
  'Units','pixels','Position',upPos,...
  'String',char(9650),'FontSize',6,'UserData',1,...
  'Tag','pushbutton_IRup','TooltipString',irtip,...
  'Callback',@FBDC_stepIR);

handles.pushbutton_IRdown = uicontrol(handles.figure_main,'Style','pushbutton',...
  'Units','pixels','Position',dnPos,...
  'String',char(9660),'FontSize',6,'UserData',-1,...
  'Tag','pushbutton_IRdown','TooltipString',irtip,...
  'Callback',@FBDC_stepIR);

% make sure params reflect the shown selections
handles.params.ChR_LED_firmware = vals{defidx};
handles.params.ChR_IrInt = irval;

end
