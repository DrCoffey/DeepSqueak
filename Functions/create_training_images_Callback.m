function create_training_images_Callback(hObject, eventdata, handles)
% hObject    handle to create_training_images (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cd(handles.squeakfolder);
[trainingdata trainingpath] = uigetfile([char(handles.settings.detectionfolder) '\*.mat'],'Select Detection File for Training ','MultiSelect', 'on');
if isnumeric(trainingdata); return; end

if ischar(trainingdata)
    tmp{1}=trainingdata;
    clear trainingdata
    trainingdata=tmp;
end

% Spectrogram Settings
prompt = {'Window Length (s)','Overlap (s)','NFFT (s)','Amplitude Cutoff (3 for 55s, 1 for 22s)', 'High Frequency Cutoff (KHz)', 'Bout Length (s) [Requires Single Files & Audio]'};
dlg_title = 'Spectrogram Settings';
num_lines=[1 40]; options.Resize='off'; options.windStyle='modal'; options.Interpreter='tex';
spectSettings = str2double(inputdlg(prompt,dlg_title,num_lines,{'0.0032','0.0028','0.0032','1','80','0'},options));
if isempty(spectSettings); return; end

if bout ~= 0
    if length(trainingdata) > 1
        warndlg('Creating images from bouts is only possible with single files at a time. Please select a single detection file, or set bout length to 0.');
        return
    end
    [audioname, audiopath] = uigetfile({'*.wav;*.flac;*.UVD' 'Audio File';'*.wav' 'WAV(*.wav)'; '*.flac' 'FLAC (*.flac)'; '*.UVD' 'Ultravox File (*.UVD)'},['Select Audio File for ' trainingdata{1}] ,handles.settings.audiofolder);
end
if isnumeric(audioname); return; end

wind = spectSettings(1);
noverlap = spectSettings(2);
nfft = spectSettings(3);
cont = spectSettings(4);
cutoff = spectSettings(5)*1000;
bout = spectSettings(6);

h = waitbar(0,'Initializing');

c=0;
for k = 1:length(trainingdata)
    TTable = table({},{},'VariableNames',{'imageFilename','USV'});
    load([trainingpath trainingdata{k}]);
    [p, filename] = fileparts(trainingdata{k});
    mkdir(['Training\Images\' filename])
    
    % Remove Rejects
    Calls = Calls([Calls.Accept] == 1);
    
    if bout ~= 0
        %% Calculate Groups of Calls
        Distance = [];
        for i = 1:length(Calls)
            for j = 1:length(Calls)
                Distance(i,j) = min([
                    abs(Calls(i).Box(1) - Calls(j).Box(1))
                    abs(Calls(i).Box(1) - Calls(j).Box(1) - Calls(j).Box(3))
                    abs(Calls(i).Box(1) + Calls(i).Box(3) - Calls(j).Box(1))
                    abs(Calls(i).Box(1) + Calls(i).Box(3) - Calls(j).Box(1)-Calls(j).Box(3))
                    ]);
            end
        end
        G = graph(Distance,'upper');
        Lidx = 1:length(G.Edges.Weight);
        Nidx = Lidx(G.Edges.Weight > bout);
        H =  rmedge(G,Nidx);
        bins = conncomp(H);
        
        for i = 1:length(unique(bins))
            CurrentSet = Calls(bins==i);
            Boxes =reshape([CurrentSet.Box],4,length([CurrentSet.Box])/4)';
            Start = min(Boxes(:,1));
            Finish = max(Boxes(:,1) + Boxes(:,3));
            
            info = audioinfo([audiopath audioname]);
            rate = info.SampleRate;
            
            %% Read Audio
            windL = Start - mean(Boxes(:,3));
            if windL < 0
                windL = 1 / rate;
            end
            windR = Finish + mean(Boxes(:,3));
            Audio=audioread([audiopath audioname],round([windL windR]*rate));
            
            [s, fr, ti] = spectrogram(Audio,round(rate * wind),round(rate * noverlap),round(rate * nfft),rate,'yaxis');
            x1 = axes2pix(length(ti),ti,Boxes(:,1)-windL);
            x2 = axes2pix(length(ti),ti,Boxes(:,3));
            y1 = axes2pix(length(fr),fr./1000,Boxes(:,2));
            y2 = axes2pix(length(fr),fr./1000,Boxes(:,4));
            maxfreq = find(fr<cutoff,1,'last');
            fr = fr(1:maxfreq);
            s = s(1:maxfreq,:);
            box = round([x1 (length(fr)-y1-y2) x2 y2]);
            
            im = mat2gray(flipud(abs(s)),[0 cont]);
            
            
            waitbar(i/length(unique(bins)),h,['Processing File ' num2str(k) ' of '  num2str(length(trainingdata))]);
            c=c+1;
            
            imwrite(im,[handles.squeakfolder '\Training\Images\' filename '\' num2str(c) '.png'],'BitDepth',16)
            TTable = [TTable;{['Training\Images\' filename '\' num2str(c) '.png'] box}];
            
        end
        
    elseif bout == 0
        for i = 1:length(Calls)
            [s, fr, ti] = spectrogram(Calls(i).Audio,round(Calls(i).Rate * wind),round(Calls(i).Rate * noverlap),round(Calls(i).Rate * nfft),Calls(i).Rate,'yaxis');
            x1 = axes2pix(length(ti),ti,Calls(i).RelBox(1));
            x2 = axes2pix(length(ti),ti,Calls(i).RelBox(3));
            y1 = axes2pix(length(fr),fr./1000,Calls(i).RelBox(2));
            y2 = axes2pix(length(fr),fr./1000,Calls(i).RelBox(4));
            maxfreq = find(fr<cutoff,1,'last');
            fr = fr(1:maxfreq);
            s = s(1:maxfreq,:);
            if Calls(i).Accept == 1;
                box = round([x1 (length(fr)-y1-y2) x2 y2]);
            else
                box = [];
            end
            s=flipud(abs(s));
            im = mat2gray(s,[prctile(s(:),7.5) cont]);
            imwrite(im,[handles.squeakfolder '\Training\Images\' filename '\' num2str(c) '.png'],'BitDepth',16)
            TTable = [TTable;{['Training\Images\' filename '\' num2str(c) '.png'] box}];
        end
    end
    save(['Training\' filename '.mat'],'TTable','wind','noverlap','nfft','cont');
    disp(['Created ' num2str(height(TTable)) ' Training Images']);
end
close(h)
handles = guidata(hObject);  % Get newest version of handles
