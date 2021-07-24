function  handles = render_call_position(handles, all_calls)
%% This function makes and updates the little window with the green lines
% Timestamp for each call

% Initialize the display
if all_calls
    CallTime = handles.data.calls.Box(:,1) + handles.data.calls.Box(:,3)/2;
    handles.update_position_axes = 0;
    %     line([0 max(CallTime)],[0 0],'LineWidth',1,'Color','w','Parent', handles.detectionAxes);
    %     line([0 max(CallTime)],[1 1],'LineWidth',1,'Color','w','Parent', handles.detectionAxes);
    set(handles.detectionAxes,'XLim',[0 handles.data.audiodata.Duration]);
    set(handles.detectionAxes,'YLim',[0 1]);
    
    set(handles.detectionAxes,'Color',[.1 .1 .1],'YColor',[1 1 1],'XColor',[1 1 1],'Box','on','Clim',[0 1]);
    set(handles.detectionAxes,'YTickLabel',[]);
    
    set(handles.detectionAxes,'YTick',[]);
    set(handles.detectionAxes,'XTick',[]);
    %set(handles.detectionAxes,'XColor','none');
    %     guidata(hObject, handles);
    %     handles = guidata(hObject);
    
    cla(handles.detectionAxes);
    
    screen_size = get(0,'screensize');
    min_call_render_difference = 2*handles.data.audiodata.Duration / (screen_size(3));
    calls_to_plot = diff([0;CallTime]) > min_call_render_difference;
    
    % Plot the little green lines
%     for accepted = 0:1
%         xdata = CallTime(calls_to_plot & handles.data.calls.Accept == accepted);
%         if any(xdata)
%             xdata = repelem(xdata,2,1);
%             % This lets us make the plot with a single line, since the vertical
%             % lines are connected, but above the range of the plot
%             % x = [x(1) x(1) x(2) x(2) x(3) x(3) x(4) x(4) x(5) x(5) ...]
%             % y = [0    1    1    0    0    1    1    0    0    1    ...]
%             ydata = zeros(size(xdata)) - 1;
%             ydata(2:4:end) = 2;
%             ydata(3:4:end) = 2;
%             line(xdata, ydata,'Parent', handles.detectionAxes,'Color',[1,0,0] + accepted.*[-1,.5,0], 'PickableParts','none');
%         end
%     end
    
    % Plot kernal densityp
    if any(handles.data.calls.Accept)
        [f,xi] = ksdensity(CallTime(handles.data.calls.Accept == true), linspace(0,handles.data.audiodata.Duration,300),...
            'Bandwidth', handles.data.audiodata.Duration / 300,...
            'Kernel', 'normal');
        f(1) = 0;
        f(end) = 0;
        patch(handles.detectionAxes, xi, rescale(f,.05,.95), [0,.6,0], 'PickableParts', 'none');
    end
    
    % Initialize the timestamp text and current call line
    handles.CurrentCallLineText = text(0, 20, ' ', 'Color', 'W', 'HorizontalAlignment', 'center', 'Parent', handles.detectionAxes);
    handles.CurrentCallLinePosition = line([0,0],[0 1],'LineWidth',3,'Color','g','Parent', handles.detectionAxes,'PickableParts','none');
    handles.CurrentCallWindowRectangle = rectangle('Position',[0 0 1 1], 'Parent',handles.detectionAxes,'LineWidth',1,'EdgeColor',[1 1 1 1],'FaceColor',[1 1 1 .15]);
    
end


calltime = handles.data.focusCenter;
if ~isempty(handles.data.calls)
    calltime = handles.data.calls.Box(handles.data.currentcall, 1);
    if handles.data.calls.Accept(handles.data.currentcall)
        handles.CurrentCallLinePosition.Color = [0,1,0];
    else
        handles.CurrentCallLinePosition.Color = [1,0,0];
    end
end

sec = mod(calltime, 60);
min = floor(calltime / 60);
set(handles.CurrentCallLineText,'Position',[calltime,1.4,0],'String',sprintf('%.0f:%.2f', min, sec));
set(handles.CurrentCallLinePosition,'XData',[calltime(1) calltime(1)]);

handles.CurrentCallWindowRectangle.Position = [  handles.data.windowposition 0 handles.data.settings.pageSize  1];

