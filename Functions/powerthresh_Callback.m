function powerthresh_Callback(hObject, eventdata, handles)

prompt = 'Reject Calls Below Power:                 (0-10)'
            dlg_title = 'Power Threshold';
            num_lines=1; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
            '.5';   
Settings = str2double(inputdlg(prompt,dlg_title,num_lines,{'.75'},options));
if ~isempty(Settings)
for p=1:length(handles.calls)
    if handles.calls(p).Power>Settings
       handles.calls(p).Accept=1;
    else
       handles.calls(p).Accept=0; 
    end
end

end
update_fig(hObject, eventdata, handles);
guidata(hObject, handles);
