function cancelled = checkForUnsavedChanges(hObject, eventdata, handles)
%% Check if the current file has been modified. If it has, prompt the user to save it
% cancelled = false if the user pressed "Yes" or "No"
% cancelled = true if user pressed "Cancel"

cancelled = false;
if ~isempty(handles.data.calls)
    if isfile(handles.current_detection_file)
        oldCalls = loadCallfile(handles.current_detection_file, handles);
        % Check if the "box", "type", and "accept" fields in the currently loaded
        % file are the same as the old file. Do this instead of comparing
        % all fields because previous versions of DS had additional
        % variables, so this prevents compatibility errors.
        % isequal doesn't work when categorical variables have undefined
        % entries, so test them seperately.
        if ~isequal(handles.data.calls(:,{'Box', 'Accept'}), oldCalls(:,{'Box', 'Accept'})) || ~isequal(cellstr(handles.data.calls.Type), cellstr(oldCalls.Type))
            response = questdlg('Calls have been modified, save changes?', 'Save changes', 'Yes', 'No', 'Cancel', 'Yes');
            switch response
                case 'Yes'
                    cancelled = savesession_Callback(hObject, eventdata, handles);
                case 'No'
                    cancelled = false;
                case 'Cancel'
                    cancelled = true;
            end
        end
    end
end