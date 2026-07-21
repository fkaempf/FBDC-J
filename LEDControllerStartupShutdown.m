function paramsfile = LEDControllerStartupShutdown(mode,paramsfile)

% set up path
if isempty(which('flyBowl_LED_control')) && exist('../flyBowl','dir'),
  addpath('../flyBowl');
end

% FBDC-J: make the selectable-firmware Teensy classes available
tdir = fullfile(fileparts(mfilename('fullpath')),'TeensyLEDControl');
if exist(tdir,'dir') && isempty(which('TeensyLEDController')),
  addpath(tdir);
end

if ~ismember(mode,{'startup','shutdown'}),
  error('mode should be either startup or shutdown');
end

if nargin < 2,

  defaultparamsfile = '';
  if exist('.FlyBowlDataCapture_rc.mat','file'),
    tmp = load('.FlyBowlDataCapture_rc.mat');
    if isfield(tmp,'params_file'),
      defaultparamsfile = tmp.params_file;
    end
  end
  if isempty(defaultparamsfile) && exist('C:\Users\bransonk\Documents\FlyBubbleParamFiles','dir'),
    defaultparamsfile = 'C:\Users\bransonk\Documents\FlyBubbleParamFiles';
  end
  [n,p] = uigetfile('*.txt','Select FBDC config file',defaultparamsfile);
  if ~ischar(p),
    return;
  end
  paramsfile = fullfile(p,n);

end
  
params = ReadParams(paramsfile,...
  'fns_list',{'ChR_serial_port_for_LED_Controller','ChR_LED_firmware'},...
  'fns_numeric',{'ChR_IrInt'});

[~,ComputerName] = system('hostname');
ComputerName = strtrim(ComputerName);
m = regexp(params.ChR_serial_port_for_LED_Controller,':','split');
m = cat(1,m{:});
i = find(strcmp(ComputerName,m(:,1)));
if numel(i) ~= 1,
  error('Error matching computer name to ChR_serial_port_for_LED_Controller parameter');
end
params.ChR_serial_port_for_LED_Controller = m{i,2};

global FBDC_CHR_LED_CONTROLLER_FID;

% FBDC-J: if a firmware is named (ChR_LED_firmware = flybowl2015 | rgb_cmdarduino),
% drive the board through the selectable TeensyLEDController; otherwise keep the
% original raw-serial controller.
ledfirmware = '';
if isfield(params,'ChR_LED_firmware'),
  v = params.ChR_LED_firmware; if iscell(v), v = v{1}; end
  ledfirmware = strtrim(char(v));
end
if strcmpi(ledfirmware,'rgb_cmdarduino'),
  % FlyDisco board -> selectable TeensyLEDController (rgb_cmdarduino dialect)
  hLEDController = TeensyLEDController(ledfirmware, ...
    params.ChR_serial_port_for_LED_Controller, 115200);
  hLEDController.connect();
else
  % Incubator board (flybowl2015) or unset -> original raw-serial protocol
  % over the serialport shim (R2026a removed the legacy `serial` object).
  hLEDController = LegacySerialShim(params.ChR_serial_port_for_LED_Controller,...
    'BaudRate', 115200, 'Terminator', 'CR');
  fopen(hLEDController);
end

if isempty(FBDC_CHR_LED_CONTROLLER_FID)
  FBDC_CHR_LED_CONTROLLER_FID = hLEDController;
else
  FBDC_CHR_LED_CONTROLLER_FID(end+1) = hLEDController;
end

% reset LED controller
flyBowl_LED_control(hLEDController,'RESET',[],false);

% set IR LED intensity
switch mode,
  case 'startup'
    flyBowl_LED_control(hLEDController,'IR',params.ChR_IrInt,false);
  case 'shutdown'
    flyBowl_LED_control(hLEDController,'IR',0,false);
end

flyBowl_LED_control(hLEDController, 'STOP',[],false);
flyBowl_LED_control(hLEDController, 'OFF',[],false);
if isa(hLEDController,'TeensyLEDController'),
  hLEDController.disconnect();
else
  fclose(hLEDController);
end
FBDC_CHR_LED_CONTROLLER_FID = setdiff(FBDC_CHR_LED_CONTROLLER_FID,hLEDController);
