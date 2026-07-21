function status = flyBowl_LED_control(s1,token, param, docheckstatus)

dispstatus = nargout == 0;
if nargin < 4,
  docheckstatus = true;
end

% FBDC-J: if handed a selectable-firmware TeensyLEDController, route the
% command through it so the same bias-branch code drives a board flashed
% with either the old ('flybowl2015') or new ('rgb_cmdarduino') firmware.
% The raw-serial path below is kept unchanged for the original controller.
if isa(s1,'TeensyLEDController')
  status = {};
  switch upper(strtrim(token))
    case 'CONNECT',            s1.connect();
    case 'IR',                 s1.setIR(round(param));
    case {'CHR','OPTO'},       s1.setOpto(round(param));
    case 'PULSE'
      pat = struct('intensity',1, ...
        'pulse_width_ms',param.pulse_width, ...
        'pulse_period_ms',param.pulse_period, ...
        'num_pulses',param.number_of_pulses, ...
        'inter_iteration_pause_ms',param.pulse_train_interval, ...
        'num_iterations',param.iteration);
      s1.pulse('opto',pat);
    case {'OFF','ALLOFF','RESET'}, s1.allOff();
    case 'STOP',               s1.stop();
    case {'ON','ALLON'}        % quadrant enable handled inside setOpto per firmware
    case 'DISCONNECT',         s1.disconnect();
    otherwise                  % LOG/LIN/PATT/RUN not needed via the controller
  end
  return;
end

switch upper(strtrim(token))
    case 'CONNECT'
        s1 = serial(COMPort, 'BaudRate', 115200, 'Terminator', 'CR');
        try
            fopen(s1);
        catch
            fclose(s1);
            delete(s1);
            fopen(s1);
        end
        
    case 'IR'
        Ir_int_val = round(param);
        
        %send command to controller
        fprintf(s1, ['IR ',num2str(Ir_int_val)]);
        if docheckstatus, [~,status] = checkControllerStatus(s1,dispstatus); end
        
    case 'CHR'
        Chr_int_val = round(param);   % this is done so only one dec place
        
        %send command to controller
        fprintf(s1, ['CHR ',num2str(Chr_int_val)]);
        if docheckstatus, [~,status] = checkControllerStatus(s1,dispstatus); end
        
    case 'LOG'
        fprintf(s1, 'LOG');
        if docheckstatus, [~,status] = checkControllerStatus(s1,dispstatus); end
        
    case 'LIN'
        fprintf(s1, 'LIN');
        if docheckstatus, [~,status] = checkControllerStatus(s1,dispstatus); end
        
    case 'PULSE'
        fprintf(s1, ['PULSE,', num2str(param.pulse_width),',',num2str(param.pulse_period),',',num2str(param.number_of_pulses), ',', ...
            num2str(param.pulse_train_interval),',',num2str(param.delay_time),',',num2str(param.iteration)]);
        if docheckstatus, [~,status] = checkControllerStatus(s1,dispstatus); end
        
    case 'PATT'

        fprintf(s1, ['PATT, ' param]);
        if docheckstatus, [~,status] = checkControllerStatus(s1,dispstatus); end
        
    case 'RUN'
        fprintf(s1, 'RUN');
        if docheckstatus, [~,status] = checkControllerStatus(s1,dispstatus); end
        
    case 'STOP'
        fprintf(s1, 'STOP');
        if docheckstatus, [~,status] = checkControllerStatus(s1,dispstatus); end
        
    case 'ON'
        fprintf(s1, 'ON');
        if docheckstatus, [~,status] = checkControllerStatus(s1,dispstatus); end
        
    case 'OFF'
        fprintf(s1, 'OFF');
        if docheckstatus, [~,status] = checkControllerStatus(s1,dispstatus); end
        
    case 'ALLOFF'
        fprintf(s1, 'OFF 0,0');
        if docheckstatus, [~,status] = checkControllerStatus(s1,dispstatus); end
        
    case 'ALLON'
        fprintf(s1, 'ON 0,0');
        if docheckstatus, [~,status] = checkControllerStatus(s1,dispstatus); end
        
    case 'DISCONNECT'
        fclose(s1);
        delete(s1);
        
    case 'RESET'
        fprintf(s1, 'CHR 0');
        fprintf(s1, 'OFF 0,0');
        fprintf(s1, 'STOP');
        
        if docheckstatus, [~,status] = checkControllerStatus(s1,dispstatus); end
            
    otherwise
        disp('Unknown command for the LED control.')   
end

    function [checReslt,status] = checkControllerStatus(s1,dispstatus)
        %pause(0.1);
        starttime = tic;
        maxwaittime = .5;
        waittime = 0;
        while s1.BytesAvailable <= 1,
          waittime = toc(starttime);
          if waittime >= maxwaittime,
            break;
          end
        end
        fprintf('Waited %f seconds for controller status\n',waittime);
        status = {};
        while s1.BytesAvailable > 1
          s = strtrim(fscanf(s1));
          if isempty(s),
            continue;
          end
          if dispstatus,
            fprintf([s,'\n']);
          else
            status{end+1} = s; %#ok<AGROW>
          end
        end
        checReslt = 1;
    end

end


