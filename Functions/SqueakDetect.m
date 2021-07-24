function  Calls=SqueakDetect(inputfile,networkfile,fname,Settings,currentFile,totalFiles,networkname)
% Find Squeaks
Calls = table();
h = waitbar(0,'Initializing');

% Get the audio info
audio_info = audioinfo(inputfile);

if audio_info.NumChannels > 1
    warning('Audio file contains more than one channel. Detection will use the mean of all channels.')
end

% Get network and spectrogram settings
network=networkfile.detector;
wind=networkfile.wind;
noverlap=networkfile.noverlap;
nfft=networkfile.nfft;

% Adjust settings, so spectrograms are the same for different sample rates
wind = round(wind * audio_info.SampleRate);
noverlap = round(noverlap * audio_info.SampleRate);
nfft = round(nfft * audio_info.SampleRate);

%% Get settings
% (1) Detection length (s)
if Settings(1)>audio_info.Duration
    DetectLength=audio_info.Duration;
    disp([fname ' is shorter then the requested analysis duration. Only the first ' num2str(audio_info.Duration) ' will be processed.'])
elseif Settings(1)==0
    DetectLength=audio_info.Duration;
else
    DetectLength=Settings(1);
end

%Detection chunk size (s)
chunksize=networkfile.imLength*.8;

%Overlap between chucks (s)
overlap=networkfile.imLength*.2;

% (2) High frequency cutoff (kHz)
if audio_info.SampleRate < (Settings(2)*1000)*2
    disp('Warning: Upper Range Above Nyquist Frequency');
    HighCutoff=floor(audio_info.SampleRate/2000);
else
    HighCutoff = Settings(2);
end

% (3) Low frequency cutoff (kHz)
LowCutoff = Settings(3);

% (4) Score cutoff (kHz)
score_cuttoff=Settings(4);

%% Detect Calls
% Initialize variables
AllBoxes=[];
AllScores=[];
AllClass=[];
AllPowers=[];

% Break the audio file into chunks
chunks = linspace(1,(DetectLength - overlap) * audio_info.SampleRate,round(DetectLength / chunksize));
for i = 1:length(chunks)-1
    try
        DetectStart = tic;
        
        % Get the audio windows
        windL = chunks(i);
        windR = chunks(i+1) + overlap*audio_info.SampleRate;
        
        % Read the audio
        audio = audioread(audio_info.Filename,floor([windL, windR]));
        
        %% Mix multichannel audio:
        % By default, take the mean of multichannel audio.
        % Another method could be to take the max of the multiple channels,
        % or just take the first channel.
        audio = audio - mean(audio,1);
        switch 'mean'
            case 'first'
                audio = audio(:,1);
            case 'mean'
                audio = mean(audio,2);
            case 'max'
                [~,index] = max(abs(audio'));
                audio = audio(sub2ind(size(audio),1:size(audio,1),index));
        end
        
        [~,fr,ti,p] = spectrogram(audio(:,1),wind,noverlap,nfft,audio_info.SampleRate,'yaxis'); % Just use the first audio channel
        upper_freq = find(fr<=HighCutoff*1000,1,'last');
        lower_freq = find(fr>=LowCutoff*1000,1,'first');
        p = p(lower_freq:upper_freq,:);
        p(p==0)=.01;
        p = log10(p);
        p = rescale(imcomplement(abs(p)));
        
        % Create Adjusted Image for Identification
        xTile=ceil(size(p,1)/50);
        yTile=ceil(size(p,2)/50);
        if xTile>1 && yTile>1
        im = adapthisteq(flipud(p),'NumTiles',[xTile yTile],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);
        else
        im = adapthisteq(flipud(p),'NumTiles',[2 2],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);    
        end

        % Detect!
        [bboxes, scores, Class] = detect(network, im2uint8(im), 'ExecutionEnvironment','auto','SelectStrongest',1);
        
        % Calculate each call's power
        Power = [];
        for j = 1:size(bboxes,1)
            % Get the maximum power of the region within the box
            callPower = max(max(...
                p(bboxes(j,2):bboxes(j,2)+bboxes(j,4)-1,bboxes(j,1):bboxes(j,3)+bboxes(j,1)-1)));
            callPower = 10 * log10(callPower);
            Power = [Power
                callPower];
        end
        
        % Convert boxes from pixels to time and kHz
        bboxes(:,1) = ti(bboxes(:,1)) + (windL ./ audio_info.SampleRate);
        bboxes(:,2) = fr(upper_freq - (bboxes(:,2) + bboxes(:,4))) ./ 1000;
        bboxes(:,3) = ti(bboxes(:,3));
        bboxes(:,4) = fr(bboxes(:,4)) ./ 1000;
        
        % Concatinate the results
        AllBoxes=[AllBoxes
            bboxes(Class == 'USV',:)];
        AllScores=[AllScores
            scores(Class == 'USV',:)];
        AllClass=[AllClass
            Class(Class == 'USV',:)];
        AllPowers=[AllPowers
            Power(Class == 'USV',:)];
        
        t = toc(DetectStart);
        waitbar(...
            i/(length(chunks)-1),...
            h,...
            sprintf(['Detection Speed: ' num2str((chunksize + overlap) / t,'%.1f') 'x  Call Fragments Found:' num2str(length(AllBoxes(:,1)),'%.0f') '\n File ' num2str(currentFile) ' of ' num2str(totalFiles)]));
        
    catch ME
        waitbar(...
            i/(length(chunks)-1),...
            h,...
            sprintf('Error in Network, Skiping Audio Chunk'));
        disp('Error in Network, Why Broken?');
        warning( getReport( ME, 'extended', 'hyperlinks', 'on' ) );
    end
end
% Return is nothing was found
if isempty(AllScores); close(h); return; end

h = waitbar(1,h,'Merging Boxes...');
Calls = merge_boxes(AllBoxes, AllScores, AllClass, AllPowers, audio_info, 1, score_cuttoff, 0);

% Merge long 22s if detected with a long 22 network
if contains(networkname,'long','IgnoreCase',true)
    try
        Calls = SeperateLong22s_Callback([],[],[],inputfile,Calls);
    catch ME
        disp(ME)
    end
end
close(h);
end


