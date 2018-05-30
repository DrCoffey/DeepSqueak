function removereject_Callback(hObject, eventdata, handles)

h = waitbar(0,'Removing Rejections');
c=0;
for p=1:length(handles.calls)
    h = waitbar(p/length(handles.calls),h);
    if handles.calls(p).Accept==1;
        c=c+1;
       tmp(c)=handles.calls(p); 
    end
end
handles.calls=tmp;
handles.currentcall=1;

handles.CallTime=[];
for i=1:length(handles.calls)
    handles.CallTime(i,1)=handles.calls(i).Box(1);
end



close(h);
update_fig(hObject, eventdata, handles);
guidata(hObject, handles);