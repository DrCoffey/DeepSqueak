function ImportFromXBAT(hObject, eventdata, handles)

[fname, fpath] = uigetfile('*.mat','multiselect','on','Select X-BAT logs');
if isnumeric(fpath); return; end
[outpath] = uigetdir(handles.settings.detectionfolder,'Select Output Folder');
if isnumeric(outpath); return; end

if ischar(fname)
    fname = {fname};
end

hc = waitbar(0,'Importing Calls from Raven Log');

for file = fname
    %Load the data
    data = load([fpath file{:}]);
    data = struct2cell(data);
    data = data{:};
    audiofile = [data.sound.path data.sound.file];
    rate = data.sound.samplerate;
    clear Calls
    
    if exist(audiofile,'file') == 0
        [audioname, audiopath] = uigetfile({'*.wav;*.flac;*.UVD' 'Audio File';'*.wav' 'WAV(*.wav)'; '*.flac' 'FLAC (*.flac)'; '*.UVD' 'Ultravox File (*.UVD)'},'Select Audio File',handles.settings.audiofolder);
        audiofile = [audiopath, audioname];
    end
        
    for i = 1:length(data.event)
        waitbar(i/length(data.event),hc);
        deltaT = data.event(i).selection(3) - data.event(i).selection(1);
        
        Calls(i).Rate = rate;
        % X-BAT seems to use boxes offet by padding, so subtract the pad
        Calls(i).Box = [
            data.event(i).selection(1) + data.event(i).time(1) - data.pad,...
            data.event(i).selection(2)/1000,...
            deltaT,...
            data.event(i).selection(4)/1000 - data.event(i).selection(2)/1000
            ];
        
        windL = Calls(i).Box(1) - deltaT;
        windR = Calls(i).Box(1) + Calls(i).Box(3) + deltaT;
        
        if windL < 0
            windL = 1 / rate;
        end
        Calls(i).RelBox=[
            deltaT,...
            data.event(i).selection(2)/1000,...
            deltaT,...
            data.event(i).selection(4)/1000 - data.event(i).selection(2)/1000
            ];
        Calls(i).Score = data.event(i).score;
        Calls(i).Audio=audioread(audiofile,round([windL windR]*rate),'native');
        
        if contains(data.event(i).tags,'Accept')
            Calls(i).Accept=1;
        else
            Calls(i).Accept=0;
        end
        Calls(i).Type=data.event(i).annotation.name;
        Calls(i).Power = 0;
        
    end
    save([outpath '/' data.file],'Calls','-v7.3');
end
    close(hc);
    update_folders(hObject, eventdata, handles);


    
    
    
    
    
    
