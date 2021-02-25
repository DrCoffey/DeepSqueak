function  roiMovedCallback(rectangle,evt)
% This runs when a box's rectangle is resized or moved
hObject = get(rectangle,'Parent');
handles = guidata(hObject);
tag = str2double(get(rectangle,'Tag'));
handles.data.calls{tag,'Box'} = rectangle.Position;
SortCalls(hObject, [], handles, 'time', 0, tag);
end

