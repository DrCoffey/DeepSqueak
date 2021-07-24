% Updates folders and config file
function update_folders(hObject, eventdata, handles)

% Reads current config file
handles.data.loadSettings();

% Backwards compatibility from when there were fewer label shortcuts
if length(handles.data.settings.labels) < length(handles.data.labelShortcuts)
    handles.data.settings.labels( length(handles.data.settings.labels)+1 : length(handles.data.labelShortcuts) ) = {' '};
end


% Update Networks
handles.networkfiles = {};
if isempty(handles.data.settings.networkfolder)
    set(handles.neuralnetworkspopup,'String','No Folder Selected','value',1);
elseif exist(handles.data.settings.networkfolder,'dir')==0
    set(handles.neuralnetworkspopup,'String','Invalid Folder','value',1);
else
    handles.networkfiles=dir([handles.data.settings.networkfolder '/*.mat*']);
    handles.networkfilesnames = {handles.networkfiles.name};
    if isempty(handles.networkfilesnames)
        set(handles.neuralnetworkspopup,'String','No Networks in Folder','value',1);
    else
        set(handles.neuralnetworkspopup,'String',handles.networkfilesnames)
        if handles.neuralnetworkspopup.Value > length(handles.neuralnetworkspopup.String)
            set(handles.neuralnetworkspopup,'Value',1);
        end
        
    end
end

% Update Audio
handles.audiofiles = {};
if isempty(handles.data.settings.audiofolder)
    set(handles.AudioFilespopup,'String','No Folder Selected','value',1);
elseif exist(handles.data.settings.audiofolder,'dir')==0
    set(handles.AudioFilespopup,'String','Invalid Folder','value',1);
else
    handles.audiofiles = [
        dir(fullfile(handles.data.settings.audiofolder, '*.wav'))
        dir(fullfile(handles.data.settings.audiofolder, '*.ogg'))
        dir(fullfile(handles.data.settings.audiofolder, '*.flac'))
        dir(fullfile(handles.data.settings.audiofolder, '*.UVD'))
        dir(fullfile(handles.data.settings.audiofolder, '*.au'))
        dir(fullfile(handles.data.settings.audiofolder, '*.aiff'))
        dir(fullfile(handles.data.settings.audiofolder, '*.aif'))
        dir(fullfile(handles.data.settings.audiofolder, '*.mp3'))
        dir(fullfile(handles.data.settings.audiofolder, '*.m4a'))
        dir(fullfile(handles.data.settings.audiofolder, '*.mp4'))
        ];
    handles.audiofilesnames = {handles.audiofiles.name};
    if isempty(handles.audiofilesnames)
        set(handles.AudioFilespopup,'String','No Audio in Folder','value',1);
    else
        set(handles.AudioFilespopup,'String',handles.audiofilesnames)
        if handles.AudioFilespopup.Value > length(handles.AudioFilespopup.String)
            set(handles.AudioFilespopup,'Value',1);
        end
    end
end

% Update Detections
handles.detectionfiles = {};
if isempty(handles.data.settings.detectionfolder)
    set(handles.popupmenuDetectionFiles,'String','No Folder Selected','value',1);
elseif exist(handles.data.settings.detectionfolder,'dir')==0
    set(handles.popupmenuDetectionFiles,'String','Invalid Folder','value',1);
else
    handles.detectionfiles=dir([handles.data.settings.detectionfolder '/*.mat*']);
    
    % Sort the detection files by date modified
    [~, idx] = sort([handles.detectionfiles.datenum],'descend');
    handles.detectionfiles = handles.detectionfiles(idx);
    
    handles.detectionfilesnames = {handles.detectionfiles.name};
    if isempty(handles.detectionfilesnames)
        set(handles.popupmenuDetectionFiles,'String','No Detections in Folder','value',1);
    else
        set(handles.popupmenuDetectionFiles,'String',handles.detectionfilesnames);
        if handles.popupmenuDetectionFiles.Value > length(handles.popupmenuDetectionFiles.String)
            set(handles.popupmenuDetectionFiles,'Value',1);
        end
    end
end

%Update settings
guidata(hObject, handles);

