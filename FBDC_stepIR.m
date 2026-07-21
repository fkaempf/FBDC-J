function FBDC_stepIR(src,~)
%FBDC_STEPIR  Callback for the IR up/down ticker buttons.
%   The button's UserData holds the step (+1 for up, -1 for down). Reads the
%   current value from the IR edit box, applies the step, and pushes it via
%   FBDC_applyIRValue (which clamps 0-100 and sends it live if connected).
%   Note: on the flybowl2015 board IR 8 and below = off (verified on camera;
%   the threshold is hysteretic, so re-lighting from off needs a value >9).
handles = guidata(src);

step = get(src,'UserData');
if isempty(step) || ~isnumeric(step), step = 0; end

cur = handles.params.ChR_IrInt;
if isfield(handles,'edit_IR') && ishandle(handles.edit_IR),
    tmp = str2double(get(handles.edit_IR,'String'));
    if ~isnan(tmp), cur = tmp; end
end

handles = FBDC_applyIRValue(handles, cur + step);
guidata(src,handles);
end
