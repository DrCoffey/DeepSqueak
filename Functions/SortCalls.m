function SortCalls(hObject, eventdata, handles, sort_type, show_waitbar, select_added)
% Sort current file by score
set(handles.hFig, 'pointer', 'watch')
if nargin < 5
    show_waitbar = 1;
end
if nargin < 6
   select_added = 0; 
end
if show_waitbar
    h = waitbar(0,'Sorting...');
end
switch sort_type
    case 'score'
        [~,idx] = sort(handles.data.calls.Score);
    case 'time'
        [~,idx] = sortrows(handles.data.calls.Box, 1);
    case 'duration'
        [~,idx] = sortrows(handles.data.calls.Box, 4);
    case 'frequency'
        [~,idx] = sort(sum(handles.data.calls.Box(:, [2, 2, 4]), 2));
end

if select_added == 0
    handles.data.currentcall=1;
elseif select_added == -1
   handles.data.currentcall = find(idx == size(handles.data.calls,1));
else
   handles.data.currentcall = select_added; 
end

handles.data.calls = handles.data.calls(idx, :);
if ~isempty(handles.data.calls)
handles.data.focusCenter = handles.data.calls.Box(handles.data.currentcall,1) + handles.data.calls.Box(handles.data.currentcall,3)/2;
end

update_fig(hObject, eventdata, handles);

if show_waitbar
    close(h);
end

set(handles.hFig, 'pointer', 'arrow');
end
