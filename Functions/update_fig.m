function update_fig(hObject, eventdata, handles, force_render_page)
if nargin < 4
    force_render_page = false;
end
% Okay, so this is pretty annoying, but the GUI is a bit slower to update
% when a button is selected rather than the figure. I don't know the best
% way to fix this, but disabling and enabling the button seems to return
% focus to the main figure window
if strcmp(get(handles.figure1.CurrentObject,'type'), 'uicontrol')
    set(handles.figure1.CurrentObject, 'Enable', 'off');
    try
    drawnow nocallbacks
    end
    set(handles.figure1.CurrentObject, 'Enable', 'on');
    handles.figure1.CurrentObject = handles.figure1;
end
drawnow nocallbacks


%% Update focus position
handles.current_focus_position = [
    handles.data.focusCenter - handles.data.settings.focus_window_size ./ 2
    0
    handles.data.settings.focus_window_size
    0];


%% Update the position of the page window by using focus position
jumps = floor(handles.data.focusCenter / handles.data.settings.pageSize);
handles.data.windowposition = jumps*handles.data.settings.pageSize;


%% Position of the gray box in the page view
spectogram_axes_ylim = ylim(handles.focusWindow);
handles.currentWindowRectangle.Position = [
    handles.current_focus_position(1)
    spectogram_axes_ylim(1)
    handles.current_focus_position(3)
    spectogram_axes_ylim(2)
    ];


%% Render the page view if the page changed
if handles.data.lastWindowPosition ~= handles.data.windowposition || force_render_page
    handles = renderEpochSpectogram(hObject,handles);
end

handles = update_focus_display(handles);

% profile on
%% Plot Call Position (updates the little bar with the green lines)
handles = render_call_position(handles, handles.update_position_axes);
% profile off
% profview

%% Plot the boxes on top of the detections
handles = render_call_boxes(handles.spectogramWindow, handles,false,false);
handles = render_call_boxes(handles.focusWindow, handles, true,false);

% Deals with a random figure popping up rarely.... literally no idea why
chkfig = findobj('type','figure');
% Make sure not main window (which has Number == [] and Name = 'DeepSqueak'
if length(chkfig)==1 && ~isempty(chkfig.Number) && ~strcmp(chkfig.Name,'DeepSqueak')
    close(chkfig.Number); 
end

%set(groot,'defaultFigureVisible','on');
set(handles.hFig, 'pointer', 'arrow')
guidata(hObject, handles);


