function FBDC_J()
%FBDC_J  Launch the BIAS FlyBowlDataCapture (FBDC-J) on this workstation.
%   Adds the FBDC-J folder (and its subfolders) to the path and starts the
%   real FlyBowlDataCapture GUI. Remembers FlyBowlDataCaptureParams_flydisco.txt
%   so the config-file prompt defaults to it (records via BIAS; LED on COM4).
%
%   Just type:  FBDC_J

here = fileparts(mfilename('fullpath'));
addpath(genpath(here));

% make the config-file prompt default to this machine's params
try
  params_file = fullfile(here,'param_flo','FlyBowlDataCaptureParams_flydisco.txt'); %#ok<NASGU>
  save(fullfile(here,'.FlyBowlDataCapture_rc.mat'),'params_file');
catch
end

FlyBowlDataCapture();
end
