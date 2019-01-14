% Updates folders and config file
function update_folders(hObject, eventdata, handles)

% Reads current config file
handles.settings = load([handles.squeakfolder '/settings.mat']);
% Backwards compatibility from when there were fewer label shortcuts
if length(handles.settings.labels) < length(handles.LabelShortcuts)
    handles.settings.labels( length(handles.settings.labels)+1 : length(handles.LabelShortcuts) ) = {' '};
end


% Update Networks
    handles.networkfiles = {}; 
if isempty(handles.settings.networkfolder)
    set(handles.neuralnetworkspopup,'String','No Folder Selected');
elseif exist(handles.settings.networkfolder,'dir')==0
    set(handles.neuralnetworkspopup,'String','Invalid Folder');
else
    handles.networkfiles=dir([handles.settings.networkfolder '/*.mat*']);
    handles.networkfilesnames = {handles.networkfiles.name};
    if isempty(handles.networkfilesnames)
        set(handles.neuralnetworkspopup,'String','No Networks in Folder');
        if handles.neuralnetworkspopup.Value > length(handles.neuralnetworkspopup.String)
            set(handles.neuralnetworkspopup,'Value',1);
        end
    else
        set(handles.neuralnetworkspopup,'String',handles.networkfilesnames)
        if handles.neuralnetworkspopup.Value > length(handles.neuralnetworkspopup.String)
            set(handles.neuralnetworkspopup,'Value',1);
        end        
    
    end
end

% Update Audio
    handles.audiofiles = {}; 
if isempty(handles.settings.audiofolder)
    set(handles.AudioFilespopup,'String','No Folder Selected');
elseif exist(handles.settings.audiofolder,'dir')==0
    set(handles.AudioFilespopup,'String','Invalid Folder');
else
    handles.audiofiles=[
        dir([handles.settings.audiofolder '/*.wav*'])
        dir([handles.settings.audiofolder '/*.UVD*'])
        dir([handles.settings.audiofolder '/*.wmf*'])
        dir([handles.settings.audiofolder '/*.flac*'])
        ];
    handles.audiofilesnames = {handles.audiofiles.name};
    if isempty(handles.audiofilesnames)
        set(handles.AudioFilespopup,'String','No Audio in Folder');
        if handles.AudioFilespopup.Value > length(handles.AudioFilespopup.String)
            set(handles.AudioFilespopup,'Value',1);
        end
    else
        set(handles.AudioFilespopup,'String',handles.audiofilesnames)
        if handles.AudioFilespopup.Value > length(handles.AudioFilespopup.String)
            set(handles.AudioFilespopup,'Value',1);
        end
    end
end

% Update Detections
    handles.detectionfiles = {}; 
if isempty(handles.settings.detectionfolder)
    set(handles.popupmenuDetectionFiles,'String','No Folder Selected');
elseif exist(handles.settings.detectionfolder,'dir')==0
    set(handles.popupmenuDetectionFiles,'String','Invalid Folder');
else
    handles.detectionfiles=dir([handles.settings.detectionfolder '/*.mat*']);
    tosort=struct2cell(handles.detectionfiles)';
    tosort=datetime(tosort(:,3));
    [tosort idx] = sortrows(tosort,'descend');
    handles.detectionfiles=handles.detectionfiles(idx);
    handles.detectionfilesnames = {handles.detectionfiles.name};
    if isempty(handles.detectionfilesnames)
        set(handles.popupmenuDetectionFiles,'String','No Detections in Folder');
        if handles.popupmenuDetectionFiles.Value > length(handles.popupmenuDetectionFiles.String)
            set(handles.popupmenuDetectionFiles,'Value',1);
        end
    else
        set(handles.popupmenuDetectionFiles,'String',handles.detectionfilesnames);
        if handles.popupmenuDetectionFiles.Value > length(handles.popupmenuDetectionFiles.String)
            set(handles.popupmenuDetectionFiles,'Value',1);
        end
    end
end

%Update settings
guidata(hObject, handles);
handles = guidata(hObject);

