function CloseBIAS(handles)
%CLOSEBIAS  Shut down the BIAS application when FBDC closes.
%   BIAS is launched by StartBIAS as a separate process (run_bias.cmd ->
%   test_gui.exe) and otherwise keeps running after the FBDC GUI closes.
%   This helper first tries to stop capture + disconnect the camera over the
%   HTTP control API (graceful), then terminates the BIAS process so nothing
%   is left holding the camera.
%
%   The process image name defaults to 'test_gui.exe' (what run_bias.cmd
%   starts) and can be overridden with the BIASProcessName param.

if ~isfield(handles,'params') || ~isfield(handles.params,'Imaq_Adaptor') ...
    || ~strcmpi(handles.params.Imaq_Adaptor,'bias'),
  return;
end

% graceful: stop capture + disconnect any reachable BIAS windows
try
  if isfield(handles,'BIASParams'),
    openbiases = GetBIASWindowsOpen(handles.BIASParams);
    for c = openbiases(:)',
      biasurl = GetBIASURL(handles.BIASParams,c);
      try %#ok<TRYNC>
        BIASStop(biasurl);
      end
    end
  end
catch
end

% hard stop: terminate the BIAS process so it does not linger
procname = 'test_gui.exe';
if isfield(handles.params,'BIASProcessName') && ~isempty(handles.params.BIASProcessName),
  procname = strtrim(char(handles.params.BIASProcessName));
end
try
  if ispc,
    system(sprintf('taskkill /F /IM "%s" /T', procname));
  else
    system(sprintf('pkill -f "%s"', procname));
  end
catch
end
end
