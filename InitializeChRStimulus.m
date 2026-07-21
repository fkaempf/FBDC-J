function [success,hComm,errmsg] = InitializeChRStimulus(params)

success = false;
hComm = struct;
errmsg = '';

global FBDC_CHR_LED_CONTROLLER_FID;

%% open the LED controller (FBDC-J: firmware-selectable)
try
  ledfw = '';
  if isfield(params,'ChR_LED_firmware'),
    ledfw = strtrim(char(params.ChR_LED_firmware));
  end
  % Resolve the serial port. Params store it per-computer as "hostname:COMx",
  % but ParseComputerSpecificParam only strips the "hostname:" prefix when
  % several comma-separated entries are present -- so a single-machine value
  % like "jefferis-pc-15:COM4" arrives here unstripped and would be handed to
  % serialport verbatim (and fail). Pull the real port out here.
  ledport = strtrim(char(params.ChR_serial_port_for_LED_Controller));
  tok = regexp(ledport,'COM\d+','match','once');
  if ~isempty(tok),
    ledport = tok;                         % Windows COM port
  elseif any(ledport==':'),
    parts = regexp(ledport,':','split');
    ledport = parts{end};                  % generic host:port -> port
  end
  if strcmpi(ledfw,'rgb_cmdarduino'),
    % FlyDisco board -> selectable TeensyLEDController
    hComm.hLEDController = TeensyLEDController(ledfw, ledport, 115200);
    hComm.hLEDController.connect();
  else
    % Incubator board (flybowl2015) or unset -> original raw serial protocol,
    % but over the serialport shim since R2026a removed the legacy `serial`.
    hComm.hLEDController = LegacySerialShim(ledport,...
      'BaudRate', 115200, 'Terminator', 'CR');
    fopen(hComm.hLEDController);
  end
catch ME,
  ReleaseLEDController(hComm);
  errmsg = sprintf('Error initializing LED controller: %s',getReport(ME,'basic'));
  return;
end

%% configure protocol + LED, releasing the port if anything fails
% Once the port is open, ANY later failure must close it, otherwise the COM
% port leaks (a stale handle keeps it busy) and the next attempt fails with
% "port in use".
try
  % TODO move this elsewhere
  % %initialize precon sensor
  % THSensor = PreconSensor(serial_port_for_precon_sensor);

  %initialize the daq card if there is one
  if isfield(params,'ChR_isDaqCard') && params.ChR_isDaqCard,
    daqC = daq.createSession('ni');
    addAnalogInputChannel(daqC,DanalogInput, 0:1, 'Voltage');
    hComm.daqC = daqC;
  else
    hComm.daqC = [];
  end

  % read stimulus protocol
  [okproto,hComm.protocol,protomsg] = ReadStimulusProtocol(params);
  if ~okproto,
    error('FBDC:ReadStimulusProtocol','%s',protomsg);
  end

  % compute total stimulus time
  hComm.TotalDuration_Seconds = sum(hComm.protocol.duration)/1000;

  % reset LED controller
  flyBowl_LED_control(hComm.hLEDController,'RESET',[],false);

  % set IR LED intensity
  flyBowl_LED_control(hComm.hLEDController,'IR',params.ChR_IrInt,false);

  % set LED pattern
  LEDPatt = sprintf('%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d',params.ChR_LEDpattern);
  flyBowl_LED_control(hComm.hLEDController, 'PATT', LEDPatt,false);

catch ME,
  ReleaseLEDController(hComm);
  errmsg = sprintf('Error initializing LED controller: %s',getReport(ME,'basic'));
  return;
end

%% only now, after full success, register the controller for later cleanup
if isempty(FBDC_CHR_LED_CONTROLLER_FID),
  FBDC_CHR_LED_CONTROLLER_FID = hComm.hLEDController;
else
  FBDC_CHR_LED_CONTROLLER_FID(end+1) = hComm.hLEDController;
end

success = true;

end

function ReleaseLEDController(hComm)
%RELEASELEDCONTROLLER  Close the LED port if it was opened, ignoring errors.
if isfield(hComm,'hLEDController') && ~isempty(hComm.hLEDController),
  try
    if isa(hComm.hLEDController,'TeensyLEDController'),
      hComm.hLEDController.disconnect();
    else
      fclose(hComm.hLEDController);
    end
  catch
  end
end
end
