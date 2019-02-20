function  Calls=SqueakDetect(inputfile,networkfile,fname,Settings,currentFile,totalFiles,networkname,number_of_repeats)
% Find Squeaks
h = waitbar(0,'Initializing');

% Get the audio info
audio_info = audioinfo(inputfile);

if audio_info.NumChannels > 1
    warning('Audio file contains more than one channel. Use channel 1...')
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

% (2) Detection chunk size (s)
chunksize=Settings(2);

% (3) Overlap between chucks (s)
overlap=Settings(3);

% (4) High frequency cutoff (kHz)
if audio_info.SampleRate < (Settings(4)*1000)*2
    disp('Warning: Upper Range Above Samplng Frequency');
    HighCutoff=floor(audio_info.SampleRate/2000);
else
    HighCutoff = Settings(4);
end

% (5) Low frequency cutoff (kHz)
LowCutoff = Settings(5);

% (6) Score cutoff (kHz)
score_cuttoff=Settings(6);

% Used for calculated PSD
U = sum(hamming(wind).^2);

%% Detect Calls
% Initialize variables
AllBoxes=[];
AllScores=[];
AllClass=[];
AllPowers=[];
Calls = [];

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
        
        % Create the spectrogram
        [s,fr,ti] = spectrogram(audio(:,1),wind,noverlap,nfft,audio_info.SampleRate,'yaxis'); % Just use the first audio channel
        upper_freq = find(fr>=HighCutoff*1000,1);
        lower_freq = find(fr>=LowCutoff*1000,1);
        
        % Extract the region within the frequency range
        s = s(lower_freq:upper_freq,:);
        s = flip(abs(s),1);
        
        % Normalize gain setting (Allows for modified precision/recall
        % tolerance)
        med=median(s(:));
        
        scale_factor = [
            .1 .65 .9  
            30 20 10
            ];

        for iteration = 1:number_of_repeats
            
            im = mat2gray(s,[scale_factor(1,iteration)*med scale_factor(2,iteration)*med]);
            
            % Subtract the 5th percentile to remove horizontal noise bands
            im = im - prctile(im,5,2);
            
            % Detect!
            [bboxes, scores, Class] = detect(network, im2uint8(im), 'ExecutionEnvironment','auto','NumStrongestRegions',Inf);
            
            % Calculate each call's power
            Power = [];
            for j = 1:size(bboxes,1)
                % Get the maximum amplitude of the region within the box
                amplitude = max(max(...
                    s(bboxes(j,2):bboxes(j,2)+bboxes(j,4)-1,bboxes(j,1):bboxes(j,3)+bboxes(j,1)-1)));
                
                % convert amplitude to PSD
                callPower = amplitude.^2 / U;
                callPower = 2*callPower / audio_info.SampleRate;
                % Convert power to db
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
        end

            t = toc(DetectStart);
            waitbar(...
                i/(length(chunks)-1),...
                h,...
                sprintf(['Detection Speed: ' num2str((chunksize + overlap) / t,'%.1f') 'x  Call Fragments Found:' num2str(length(AllBoxes(:,1))/number_of_repeats,'%.0f') '\n File ' num2str(currentFile) ' of ' num2str(totalFiles)]));
          
    catch ME
        waitbar(...
            i/(length(chunks)-1),...
            h,...
            sprintf(['Error in Network, Skiping Audio Chunk']));
        disp('Error in Network, Skiping Audio Chunk');
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


