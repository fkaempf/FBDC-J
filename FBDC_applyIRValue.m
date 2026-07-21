function handles = FBDC_applyIRValue(handles, v)
%FBDC_APPLYIRVALUE  Clamp, store and (if connected) push an IR value.
%   Shared by the IR edit box (FBDC_setIR) and the up/down ticker buttons
%   (FBDC_stepIR). Clamps v to 0-100, stores it in handles.params.ChR_IrInt,
%   updates the edit box text, and -- if the LED controller is already open
%   (after Initialize Camera) -- sends it to the board live.
v = round(v);
v = max(0, min(100, v));
handles.params.ChR_IrInt = v;

if isfield(handles,'edit_IR') && ishandle(handles.edit_IR),
    set(handles.edit_IR,'String',num2str(v));
end

islive = isfield(handles,'ChRStuff') && isstruct(handles.ChRStuff) && ...
    isfield(handles.ChRStuff,'hLEDController') && ...
    ~isempty(handles.ChRStuff.hLEDController);
if islive,
    try
        flyBowl_LED_control(handles.ChRStuff.hLEDController,'IR',v,false);
        addToStatus(handles,{sprintf('IR backlight set to %d (live).',v)});
    catch ME,
        addToStatus(handles,{sprintf('IR set failed: %s',ME.message)});
    end
else
    try
        addToStatus(handles,{sprintf('IR backlight set to %d (applies on Initialize Camera).',v)});
    catch
    end
end
end
