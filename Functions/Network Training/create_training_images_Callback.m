function create_training_images_Callback(hObject, eventdata, handles)
% hObject    handle to create_training_images (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Select the files to make images from
[trainingdata, trainingpath] = uigetfile([char(handles.data.settings.detectionfolder) '/*.mat'],'Select Detection File for Training ','MultiSelect', 'on');
if isnumeric(trainingdata); return; end
trainingdata = cellstr(trainingdata);

% Get training settings
prompt = {'Window Length (s)','Overlap (%)','NFFT (s)','Image Length (s)',...
    'Number of augmented duplicates'};
dlg_title = 'Spectrogram Settings';
num_lines=[1 40]; options.Resize='off'; options.windStyle='modal'; options.Interpreter='tex';
spectSettings = str2double(inputdlg(prompt,dlg_title,num_lines,{num2str(handles.data.settings.spect.windowsize,3),'50',num2str(handles.data.settings.spect.nfft,3),'.5','0'},options));
if isempty(spectSettings); return; end

wind = spectSettings(1);
noverlap = spectSettings(2) * spectSettings(1) / 100;
nfft = spectSettings(3);
imLength = spectSettings(4);
repeats = spectSettings(5)+1;
AmplitudeRange = [.5, 1.5];
StretchRange = [0.75, 1.25];
h = waitbar(0,'Initializing');

for k = 1:length(trainingdata)
    TTable = table({},{},'VariableNames',{'imageFilename','USV'});
    
    % Load the detection and audio files
    audioReader = squeakData();
    [Calls, audioReader.audiodata] = loadCallfile([trainingpath trainingdata{k}],handles);
    
    % Make a folder for the training images
    [~, filename] = fileparts(trainingdata{k});
    fname = fullfile(handles.data.squeakfolder,'Training','Images',filename);
    mkdir(fname);
    
    % Remove Rejects
    Calls = Calls(Calls.Accept == 1, :);
    
    % Find max call frequency for cutoff
    % freqCutoff = max(sum(Calls.Box(:,[2,4]), 2));
    freqCutoff = audioReader.audiodata.SampleRate / 2;
    
    %% Calculate Groups of Calls
    % Calculate the distance between the end of each box and the
    % beginning of the next
    Distance = pdist2(Calls.Box(:, 1), Calls.Box(:, 1) + Calls.Box(:, 3));
    % Remove calls further apart than the bin size
    Distance(Distance > imLength) = 0;
    % Get the indices of the calls by bout number by using the connected
    % components of the graph
    
    % Create chuncks of audio file that contain non-overlapping call bouts
    bn=1;
    while bn<height(Distance)
        lst=find(Distance(bn,:)>0,1,'last');
        for ii=bn+1:lst
            Distance(ii,lst+1:end)=zeros(length(Distance(ii,lst+1:end)),1);
        end
        bn=lst+1;
    end
    
    G = graph(Distance,'upper');
    bins = conncomp(G);
    
    for bin = 1:length(unique(bins))
        BoutCalls = Calls(bins == bin, :);
        
        StartTime = max(min(BoutCalls.Box(:,1)), 0);
        FinishTime = max(BoutCalls.Box(:,1) + BoutCalls.Box(:,3));
        CenterTime = (StartTime+(FinishTime-StartTime)/2);
        StartTime = CenterTime - (imLength/2);
        FinishTime = CenterTime + (imLength/2);

        %% Read Audio
        audio = audioReader.AudioSamples(StartTime, FinishTime);
        
        % Subtract the start of the bout from the box times
        BoutCalls.Box(:,1) = BoutCalls.Box(:,1) - StartTime;
        
        try
        for replicatenumber = 1:repeats
            IMname = sprintf('%g_%g.png', bin, replicatenumber);
            [~,box] = CreateTrainingData(...
                audio,...
                audioReader.audiodata.SampleRate,...
                BoutCalls,...
                wind,noverlap,nfft,...
                freqCutoff,...
                fullfile(fname,IMname),...
                AmplitudeRange,...
                replicatenumber,...
                StretchRange);
            TTable = [TTable;{fullfile('Training','Images',filename,IMname), box}];
        end
        catch
            disp("Image/Box is Bad... You Should Feel Bad");
        end
        waitbar(bin/length(unique(bins)), h, sprintf('Processing File %g of %g', k, length(trainingdata)));        
        
    end
    save(fullfile(handles.data.squeakfolder,'Training',[filename '.mat']),'TTable','wind','noverlap','nfft','imLength');
    disp(['Created ' num2str(height(TTable)) ' Training Images']);
end
close(h)
end


% Create training images and boxes
function [im, box] = CreateTrainingData(audio,rate,Calls,wind,noverlap,nfft,freqCutoff,filename,AmplitudeRange,replicatenumber,StretchRange)

% Augment by adjusting the gain
% The first training image should not be augmented
if replicatenumber > 1
    AmplitudeFactor = range(AmplitudeRange).*rand() + AmplitudeRange(1);
    StretchFactor = range(StretchRange).*rand() + StretchRange(1);
else
    AmplitudeFactor = 1;
    StretchFactor = 1;
end
if width(audio)>height(audio)
    audio=audio';
end

% Make the spectrogram
[~, fr, ti, p] = spectrogram(audio(:,1),...
    round(rate * wind*StretchFactor),...
    round(rate * noverlap*StretchFactor),...
    round(rate * nfft*StretchFactor),...
    rate,...
    'yaxis');

% -- remove frequencies bellow well outside of the box
lowCut=(min(Calls.Box(:,2))-(min(Calls.Box(:,2))*.75))*1000;
min_freq  = find(fr>lowCut);
p = p(min_freq,:);

% % Add brown noise to adjust the amplitude
% if replicatenumber > 1
%     AmplitudeFactor = spatialPattern(size(p), -3);
%     AmplitudeFactor = AmplitudeFactor ./ std(AmplitudeFactor, [], 'all');
%     AmplitudeFactor = AmplitudeFactor .* range(AmplitudeRange) ./ 2 + mean(AmplitudeRange);
% end
% im = log10(p);
% im = (im - mean(im, 'all')) * std(im, [],'all');
% im = rescale(im + AmplitudeFactor .* im.^3 ./ (im.^2+2), 'InputMin',-1 ,'InputMax', 5);


% -- convert power spectral density to [0 1]
p(p==0)=.01;
p = log10(p);
p = rescale(imcomplement(abs(p)));

% Create adjusted image from power spectral density
alf=.4*AmplitudeFactor;

% Create Adjusted Image for Identification
xTile=ceil(size(p,1)/50);
yTile=ceil(size(p,2)/50);
if xTile>1 && yTile>1
im = adapthisteq(flipud(p),'NumTiles',[xTile yTile],'ClipLimit',.005,'Distribution','rayleigh','Alpha',alf);
else
im = adapthisteq(flipud(p),'NumTiles',[2 2],'ClipLimit',.005,'Distribution','rayleigh','Alpha',alf);    
end

% Find the box within the spectrogram
x1 = axes2pix(length(ti), ti, Calls.Box(:,1));
x2 = axes2pix(length(ti), ti, Calls.Box(:,3));
y1 = axes2pix(length(fr), fr./1000, Calls.Box(:,2));
y2 = axes2pix(length(fr), fr./1000, Calls.Box(:,4));
box = ceil([x1, length(fr)-y1-y2, x2, y2]);
box = box(Calls.Accept == 1, :);

% resize images for 300x300 YOLO Network (Could be bigger but works nice)
targetSize = [300 300];
sz=size(im);
im = imresize(im,targetSize);
box = bboxresize(box,targetSize./sz);

% Insert box for testing
% im = insertShape(im, 'rectangle', box);
imwrite(im, filename, 'BitDepth', 8);
end
