function [clustAssign] = GetARTwarpClusters(LineData, net, settings)
% Return clusters from existing ARTwarp2 model after training
h = waitbar(0,'Initializing');


%% Standardize all data, determine scaling factor for shape distance
CallLengths = zscore(cellfun(@length,(LineData)));
CallLengthsMean = mean(cellfun(@length,(LineData)));
CallLengthsSTD = std(cellfun(@length,(LineData)));
CallFreqs = zscore(cellfun(@mean,(LineData)));

distances = [];
for j = 1:1000
    c1 = datasample(LineData,1);
    c2 = datasample(LineData,1);
    c1 =  imresize(c1{:} - mean(c1{:}),[100 1]);;
    c2 =  imresize(c2{:} - mean(c2{:}),[100 1]);;
    [distances(j), ix, iy] = dtw(c1,c2,30);
end
DistScale = nanstd(distances);




clustAssign = zeros(length(LineData),1);
idx = randperm(length(LineData)); % Randomize the order of the input

weights = net{1};
lengths = net{2};
freqs = net{3};
ClusterSize = net{4};

shapeImportance  = str2num(settings{6});
freqImportance  = str2num(settings{7});
timeImportance  = str2num(settings{8});

for sample = 1:length(LineData)
        currentContour =   imresize((LineData{idx(sample)}) - mean((LineData{idx(sample)})),[100 1]); % Subtract mean, and resize
        currentLength = CallLengths(idx(sample));
        currentFreq = CallFreqs(idx(sample));
    
    if mod(sample,100)==0; % Combine overlapping clusters
        waitbar(sample / length(LineData),h,['Classifying...']);
    end
    
    % Get activations
    D = [];
    ix = {};
    iy = {};
        for category = 1:length(weights)
            [dist, ix{category}, iy{category}] = dtw(weights{category},currentContour,30);
            freqDiff = abs(currentFreq - freqs(category)); %max(currentFreq,freqs(category)) / min(currentFreq,freqs(category));
            timeDiff = abs(currentLength - lengths(category)); %max(currentLength + 10,lengths(category) + 10) / min(currentLength + 10,lengths(category) + 10);

            D(category) = sqrt(...
                freqDiff*freqImportance^2 ...
                + timeDiff*shapeImportance^2 ...
                + shapeImportance * (dist / DistScale)^2);

        end
    
    % Check if match, and update weights
    [minD, Match] = min(D ./ ClusterSize);
    clustAssign(idx(sample)) = Match;
end
close(h)
end
