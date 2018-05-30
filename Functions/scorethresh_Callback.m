function scorethresh_Callback(hObject, eventdata, handles)

prompt = 'Reject Calls Below Score:                 (0-1)';
            dlg_title = 'Score Threshold';
            num_lines=1; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
            '.75';   
Settings = str2double(inputdlg(prompt,dlg_title,num_lines,{'.75'},options));
if isempty(Settings)
    return
end
for p=1:length(handles.calls)
    if handles.calls(p).Score>Settings
       handles.calls(p).Accept=1;
    else
       handles.calls(p).Accept=0; 
    end
end

update_fig(hObject, eventdata, handles);
guidata(hObject, handles);
