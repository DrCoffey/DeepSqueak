% --------------------------------------------------------------------
function set_static_box_height_Callback(hObject, eventdata, handles)
% hObject    handle to set_static_box_height (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%% Set the frequency of each box to be a single value

response = questdlg('This function sets the upper and/or lower frequency of each detected call to a constant value. This cannot be undone.','Set Static Box Height','Continue','Cancel', 'Continue');
if ~strcmp(response,'Continue'); return; end

response = inputdlg({'New lower frequency (kHz) (leave empty to ignore)', 'New upper frequency (kHz) (leave empty to ignore)'});
if isempty(response); return; end

[fname, fpath] = uigetfile(fullfile(handles.data.settings.detectionfolder,'*.mat'),'Select Detection File(s)','MultiSelect', 'on');
if isnumeric(fname); return; end
fname = cellstr(fname);

new_high_freq = str2double(response{2});
new_low_freq = str2double(response{1});


h = waitbar(0,'Initializing');
% For each file
for i = 1:length(fname)
    [Calls, audiodata] = loadCallfile(fullfile(fpath, fname{i}),handles);

    waitbar(i/length(fname),h,['Processing File ' num2str(i) ' of '  num2str(length(fname))]);

    % For each call
    for j = 1:height(Calls)

        if ~isnan(new_low_freq)
            Calls.Box(j, 4) = Calls.Box(j, 4) + Calls.Box(j, 2) - new_low_freq;
            Calls.Box(j, 2) = new_low_freq;
        end

        if ~isnan(new_high_freq)
            Calls.Box(j, 4) = new_high_freq - Calls.Box(j, 2);
            Calls.Box(j, 4) = max(new_high_freq - Calls.Box(j, 2), 1);
        end

        % Make sure the new high frequency fits within the spectrogram
        Calls.Box(j, 4) = min(Calls.Box(j, 4), audiodata.SampleRate ./ 2000 - Calls.Box(j, 2));
        Calls.Box(j, 4) = max(Calls.Box(j, 4), 1);

    end

    save(fullfile(fpath, fname{i}),'Calls', '-append');

end

close(h);
guidata(hObject, handles);

%% Update display
update_folders(hObject, eventdata, handles);
if isfield(handles,'current_detection_file')
    loadcalls_Callback(hObject, eventdata, handles, true)
end
