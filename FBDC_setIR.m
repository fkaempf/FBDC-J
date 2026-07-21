function FBDC_setIR(src,~)
%FBDC_SETIR  Callback for the IR-backlight edit box.
%   Reads the typed value and applies it via FBDC_applyIRValue (clamp 0-100,
%   store in handles.params.ChR_IrInt, push to the board live if connected).
%   Invalid text reverts to the last good value. Range 0-100 (on the
%   flybowl2015 board IR 8 and below = off, verified on camera).
handles = guidata(src);

v = str2double(get(src,'String'));
if isnan(v),
    set(src,'String',num2str(handles.params.ChR_IrInt));
    try
        addToStatus(handles,{'IR value must be a number 0-100.'});
    catch
    end
    return;
end

handles = FBDC_applyIRValue(handles, v);
guidata(src,handles);
end
