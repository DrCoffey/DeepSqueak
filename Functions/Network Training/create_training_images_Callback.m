function create_training_images_Callback(hObject, eventdata, handles)
% hObject    handle to create_training_images (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cd(handles.squeakfolder);
[trainingdata, trainingpath] = uigetfile([char(handles.settings.detectionfolder) '/*.mat'],'Select Detection File for Training ','MultiSelect', 'on');
if isnumeric(trainingdata); return; end
trainingdata = cellstr(trainingdata);

% Get training settings
prompt = {'Window Length (s)','Overlap (s)','NFFT (s)','Bout Length (s) [Requires Single Files & Audio]',...
    'Number of augmented duplicates'};
dlg_title = 'Spectrogram Settings';
num_lines=[1 40]; options.Resize='off'; options.windStyle='modal'; options.Interpreter='tex';
spectSettings = str2double(inputdlg(prompt,dlg_title,num_lines,{'0.0032','0.0016','0.0022','1','1'},options));
if isempty(spectSettings); return; end

wind = spectSettings(1);
noverlap = spectSettings(2);
nfft = spectSettings(3);
bout = spectSettings(4);
repeats = spectSettings(5)+1;
AmplitudeRange = [0.25, 1.25];
StretchRange = [0.75, 1.25];

if bout ~= 0
    if length(trainingdata) > 1
        warndlg('Creating images from bouts is only possible with single files at a time. Please select a single detection file, or set bout length to 0.');
        return
    end
    [audioname, audiopath] = uigetfile({'*.wav;*.wmf;*.flac;*.UVD' 'Audio File';'*.wav' 'WAV (*.wav)'; '*.wmf' 'WMF (*.wmf)'; '*.flac' 'FLAC (*.flac)'; '*.UVD' 'Ultravox File (*.UVD)'},['Select Audio File for ' trainingdata{1}] ,handles.settings.audiofolder);
    if isnumeric(audioname); return; end
end



h = waitbar(0,'Initializing');

c=0;
for k = 1:length(trainingdata)
    TTable = table({},{},'VariableNames',{'imageFilename','USV'});
    load([trainingpath trainingdata{k}], 'Calls');
    % Backwards compatibility with struct format for detection files
    if isstruct(Calls); Calls = struct2table(Calls); end
    
    [p, filename] = fileparts(trainingdata{k});
    fname = fullfile(handles.squeakfolder,'Training','Images',filename);
    mkdir(fname);
    
    % Remove Rejects
    Calls = Calls(Calls.Accept, :);
    
    % Find max call frequency for cutoff
    maxFR = max(sum(Calls.Box(:,[2,4])));
    %cutoff = min([Calls.Rate, maxFR*2000]) / 2;
    
    if bout ~= 0
        %% Calculate Groups of Calls
        Distance = [];
        for i = 1:height(Calls)
            for j = 1:height(Calls)
                Distance(i,j) = min([
                    abs(Calls.Box(i, 1) - Calls.Box(j, 1))
                    abs(Calls.Box(i, 1) - Calls.Box(j, 1) - Calls.Box(j, 3))
                    abs(Calls.Box(i, 1) + Calls.Box(i, 3) - Calls.Box(j, 1))
                    abs(Calls.Box(i, 1) + Calls.Box(i, 3) - Calls.Box(j, 1) - Calls.Box(j, 3))
                    ]);
            end
        end
        G = graph(Distance,'upper');
        Lidx = 1:length(G.Edges.Weight);
        Nidx = Lidx(G.Edges.Weight > bout);
        H =  rmedge(G,Nidx);
        bins = conncomp(H);
        
        % Get the audio info
        info = audioinfo([audiopath audioname]);
        if info.NumChannels > 1
            warning('Audio file contains more than one channel. Use channel 1...')
        end
        rate = info.SampleRate;
            
        for i = 1:length(unique(bins))
            CurrentSet = Calls(bins == i, :);
            Boxes = CurrentSet.Box;
            
            Start = min(Boxes(:,1));
            Finish = max(Boxes(:,1) + Boxes(:,3));
            
            
            %% Read Audio
            windL = Start - mean(Boxes(:,3));
            if windL < 0
                windL = 1 / rate;
            end
            windR = Finish + mean(Boxes(:,3));
            audio=audioread([audiopath audioname],round([windL windR]*rate));
            Boxes(:,1) = Boxes(:,1)-windL;
            
            
            for j = 1:repeats
                IMname = [num2str(c) '_' num2str(j) '.png'];
                [~,box] = CreateTrainingData(...
                    mean(audio - mean(audio,1,'native'),2,'native'),...
                    rate,...
                    Boxes,...
                    1,...
                    wind,noverlap,nfft,rate/2,fullfile(fname,IMname),AmplitudeRange,j,StretchRange);
                TTable = [TTable;{fullfile('Training','Images',filename,IMname), box}];
                
            end
            waitbar(i/length(unique(bins)),h,['Processing File ' num2str(k) ' of '  num2str(length(trainingdata))]);
            c=c+1;
            
            
        end
        
    elseif bout == 0
        for i = 1:height(Calls)
            c=c+1;
            
            % Augment audio by adding write noise, and change the amplitude
            for j = 1:repeats
                IMname = [num2str(c) '_' num2str(j) '.png'];
                [~,box] = CreateTrainingData(...
                    Calls.Audio{i},...
                    Calls.Rate(i),...
                    Calls.RelBox(i, :),...
                    Calls.Accept(i),...
                    wind, noverlap, nfft, Calls.Rate(i) / 2, fullfile(fname, IMname), AmplitudeRange, j, StretchRange);
                
                %                 imwrite(im,filename,'BitDepth',8)
                TTable = [TTable;{fullfile('Training','Images',filename,IMname), box}];
            end
            
            waitbar(i/height(Calls),h,['Processing File ' num2str(k) ' of '  num2str(length(trainingdata))]);
        end
    end
    save(fullfile(handles.squeakfolder,'Training',[filename '.mat']),'TTable','wind','noverlap','nfft');
    disp(['Created ' num2str(height(TTable)) ' Training Images']);
end
close(h)
end


% Create training images and boxes
function [im, box] = CreateTrainingData(audio,rate,RelBox,Accept,wind,noverlap,nfft,cutoff,filename,AmplitudeRange,replicatenumber,StretchRange)

% Convert audio to double, if it is not already
if ~isfloat(audio)
    audio = double(audio) / (double(intmax(class(audio)))+1);
elseif ~isa(audio,'double')
    audio = double(audio);
end

% Augment by adjusting the gain
% The first training image should not be augmented
if replicatenumber > 1
    AmplitudeFactor = range(AmplitudeRange).*rand() + AmplitudeRange(1);
    StretchFactor = range(StretchRange).*rand() + StretchRange(1);
else
    AmplitudeFactor = 1;
    StretchFactor = 1;
end

% Make the spectrogram
[s, fr, ti] = spectrogram(audio(:,1),...
    round(rate * wind*StretchFactor),...
    round(rate * noverlap*StretchFactor),...
    round(rate * nfft*StretchFactor),...
    rate,...
    'yaxis');


% Find the box within the spectrogram
x1 = axes2pix(length(ti),ti,RelBox(:,1));
x2 = axes2pix(length(ti),ti,RelBox(:,3));
y1 = axes2pix(length(fr),fr./1000,RelBox(:,2));
y2 = axes2pix(length(fr),fr./1000,RelBox(:,4));
maxfreq = find(fr<cutoff,1,'last');
%maxfreq = find(fr<40000,1,'last');

fr = fr(1:maxfreq);
s = s(1:maxfreq,:);
if Accept
    box = round([x1 (length(fr)-y1-y2) x2 y2]);
else
    box = [];
end

s = flipud(abs(s));
med = median(s(:))*AmplitudeFactor;
im = mat2gray(s,[med*.1 med*35]);
while size(im,2)<25
   box = [box;[box(:,1)+size(im,2) box(:,2:4)]];
   im = [im im];
end
%im = insertObjectAnnotation(im, 'rectangle', box, ' ');
imwrite(im,filename,'BitDepth',8);

end

