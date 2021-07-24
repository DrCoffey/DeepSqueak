function ImportFromXBAT(hObject, eventdata, handles)

[fname, fpath] = uigetfile('*.mat','multiselect','on','Select X-BAT logs');
if isnumeric(fpath); return; end
[outpath] = uigetdir(handles.data.settings.detectionfolder,'Select Output Folder');
if isnumeric(outpath); return; end

if ischar(fname)
    fname = {fname};
end

hc = waitbar(0,'Importing Calls from XBAT file');

for file = fname
    %Load the data
    data = load([fpath file{:}]);
    data = struct2cell(data);
    data = data{:};
    audiofile = [data.sound.path data.sound.file];
    Calls = [];
    
    if ~exist(audiofile,'file')
        [audioname, audiopath] = uigetfile({
            '*.wav;*.ogg;*.flac;*.UVD;*.au;*.aiff;*.aif;*.aifc;*.mp3;*.m4a;*.mp4' 'Audio File'
            '*.wav' 'WAVE'
            '*.flac' 'FLAC'
            '*.ogg' 'OGG'
            '*.UVD' 'Ultravox File'
            '*.aiff;*.aif', 'AIFF'
            '*.aifc', 'AIFC'
            '*.mp3', 'MP3 (it''s probably a bad idea to record in MP3'
            '*.m4a;*.mp4' 'MPEG-4 AAC'
            }, 'Select Audio File',handles.data.settings.audiofolder);
        if audioname == 0
            return
        end
        audiofile = fullfile(audiopath, audioname);
    end
    audiodata = audioinfo(audiofile);

    for i = 1:length(data.event)
        waitbar(i/length(data.event),hc);
        deltaT = data.event(i).selection(3) - data.event(i).selection(1);
        
        % X-BAT seems to use boxes offet by padding, so subtract the pad
        Calls(i).Box = [
            data.event(i).selection(1) + data.event(i).time(1) - data.pad,...
            data.event(i).selection(2)/1000,...
            deltaT,...
            data.event(i).selection(4)/1000 - data.event(i).selection(2)/1000
            ];
        
        Calls(i).Score = data.event(i).score;
                        
        if contains(data.event(i).tags,'Accept')
            Calls(i).Accept=1;
        else
            Calls(i).Accept=0;
        end
        Calls(i).Type=data.event(i).annotation.name;
        Calls(i).Power = 0;
        
    end
    Calls = struct2table(Calls);
    save(fullfile(outpath, data.file), 'Calls', 'audiodata', '-v7.3');
end
close(hc);
update_folders(hObject, eventdata, handles);
