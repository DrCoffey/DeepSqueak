% --- Executes on button press in LOAD CALLS.
function loadcalls_Callback(hObject, eventdata, handles)
h = waitbar(0,'Loading Calls Please wait...');
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);
handles.v_call = get(handles.popupmenuDetectionFiles,'Value');
handles.current_detection_file = handles.detectionfiles(handles.v_call).name;
tmp=load([handles.detectionfiles(handles.v_call).folder '\' handles.detectionfiles(handles.v_call).name],'Calls');%get currently selected option from menu
handles.calls=tmp.Calls;
handles.currentcall=1;
handles.CallTime=[];

handles.spect = imagesc([],[],handles.background,'Parent', handles.axes1);
cb=colorbar(handles.axes1);
cb.Label.String = 'Power';
cb.Color = [1 1 1];
cb.FontSize = 12;
ylabel(handles.axes1,'Frequency (kHZ)','Color','w');
xlabel(handles.axes1,'Time (s)','Color','w');
handles.box=rectangle('Position',[1 1 1 1],'Curvature',0.2,'EdgeColor','g',...
    'LineWidth',3,'Parent', handles.axes1);

for i=1:length([handles.calls(:).Rate])
    waitbar(i/length(handles.calls),h,'Loading Calls Please wait...');
    handles.CallTime(i,1)=handles.calls(i).Box(1);
end
close(h);
update_fig(hObject, eventdata, handles);
guidata(hObject, handles);

