function FBDC_setLEDFirmware(src,~)
%FBDC_SETLEDFIRMWARE  Callback for the LED-board firmware dropdown.
%   Maps the operator-facing label to the firmware dialect and stores it in
%   handles.params.ChR_LED_firmware, which InitializeChRStimulus /
%   LEDControllerStartupShutdown use to pick the controller.
%     Incubator -> flybowl2015      FlyDisco -> rgb_cmdarduino
handles = guidata(src);
vals = {'flybowl2015','rgb_cmdarduino'};
v = get(src,'Value');
handles.params.ChR_LED_firmware = vals{v};
guidata(src,handles);
lbls = get(src,'String');
try
    addToStatus(handles,{sprintf('LED board set to %s (%s firmware)', lbls{v}, vals{v})});
catch
end
end
