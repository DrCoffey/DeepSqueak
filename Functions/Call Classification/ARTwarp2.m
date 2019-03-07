
function [net, clustAssign] = ARTwarp2(LineData,settings)
% Based on ARTwarp:
% Deecke, V. B. & Janik, V. M. 2006. Automated categorization of bioacoustic signals: Avoiding perceptual pitfalls. Journal of the Acoustical Society of America, 119, 645-653.
% Deecke and Janik (2006) modified fuzzy ART by Aaron Garrett:
% (https://www.mathworks.com/matlabcentral/fileexchange/4306-fuzzy-art-and-fuzzy-artmap-neural-networks)
% However, Fuzzy ART was designed to accept inputs representing
% probabilities, so ARTwarp2 removes the resonance part of ART, and instead
% of probabilities, it uses euclidean distances.
h = waitbar(0,'Initializing');
% LineData = LineData(randperm(5000));

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

MatchThresh = str2num(settings{1}); % 5.5;
MinDifference = str2num(settings{3}); % 7
learningRate = str2num(settings{4}); % .01;
maxIterations = str2num(settings{5}); % 5;
CombineVigilance = str2num(settings{2}); % Distance for combining templates

shapeImportance  = str2num(settings{6});
freqImportance  = str2num(settings{7});
timeImportance  = str2num(settings{8});

weights = {};
lengths = []; % length of templates, to prevent rounding errors
freqs = [];
ClusterSize = [];

for iteration = 1:maxIterations
    numChanges = 0; % Number of samples where category has changed.
    for sample = 1:length(LineData)
        currentContour =   imresize((LineData{idx(sample)}) - mean((LineData{idx(sample)})),[100 1]); % Subtract mean, and resize
        currentLength = CallLengths(idx(sample));
        currentFreq = CallFreqs(idx(sample));
        
        oldCategory = clustAssign(idx(sample));
        
        % Create category if none exist
        if length(weights) == 0
            weights(1) = {currentContour};
            lengths(1) = currentLength;
            freqs(1) = currentFreq;
            ClusterSize(1) = 1;
            clustAssign(idx(sample)) = 1;
            
            continue
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
        if minD <= (MatchThresh)
            
            %             warpfun = zeros(length(weights{Match}),1);
            %             for i = 1:length(weights{Match})
            %                 warpfun(i) = round(mean(iy{Match}(ix{Match}==i)));
            %             end
            weights{Match} = weights{Match} + learningRate*(currentContour - weights{Match}); % Update weight
            newLength = lengths(Match) + learningRate*(currentLength - lengths(Match));
            lengths(Match) = newLength;
            %             weights{Match} = imresize(weights{Match},[round(lengths(Match)*CallLengthsSTD + CallLengthsMean), 1]);
            freqs(Match) = freqs(Match) + learningRate*(currentFreq - freqs(Match));
            clustAssign(idx(sample)) = Match;
            
        elseif minD <= MinDifference
            clustAssign(idx(sample)) = Match;
        else
            % If no matches are found, create a weights category
            weights(length(weights)+1) = {currentContour};
            lengths(length(lengths)+1) = currentLength;
            freqs(length(freqs)+1) = currentFreq;
            ClusterSize(length(ClusterSize)+1) = 1;
            clustAssign(idx(sample)) = length(weights)+1;
        end
        
        if mod(sample,100)==0; % Combine overlapping clusters
            if ~ishandle(h)
                net = {weights, lengths, freqs, ClusterSize};
                return
            end
            waitbar(sample / length(LineData),h,sprintf(['Iteration ' num2str(iteration) ' of ' num2str(maxIterations) '\n Number of clusters: ' num2str(length(weights))]));
            try
                [weights, lengths, freqs, ClusterSize, clustAssign] = combine(weights, lengths, freqs, ClusterSize,CombineVigilance,DistScale,clustAssign);
            catch ME
                disp('Error in combine.m')
                disp(ME)
            end
        end
        %         if mod(sample,10)==0;
        %             hold on
        %             scatter((length(LineData)*(interation-1))+sample,DistanceThisBatch/10)
        %             DistanceThisBatch = 0;
        %             ylim([0 6])
        %             drawnow
        %         end
        
        numChanges = numChanges + (oldCategory ~= clustAssign(idx(sample)));
    end
    disp(['Changes this iteration: ' num2str(numChanges)])
    learningRate = learningRate * .75; % Reduced learning rate between iterations
    %     CombineVigilance = CombineVigilance * .75;
    %     MatchThresh = MatchThresh * .75;
    %     MinDifference = MinDifference * .75;
end
try
    [weights, lengths, freqs, ClusterSize, clustAssign] = combine(weights, lengths, freqs, ClusterSize,CombineVigilance,DistScale,clustAssign);
catch ME
    disp(ME)
end
net = {weights, lengths, freqs, ClusterSize};
close(h)
end

function [weights, lengths, freqs, ClusterSize, clustAssign] = combine(weights, lengths, freqs, ClusterSize,CombineVigilance,DistScale,clustAssign)

%% combine similar
Similarity = [];
Neuron = 1:length(weights);
for j = 1:length(weights)
    
    % Get activations
    D = [];
    ix = {};
    iy = {};
    for category = 1:length(weights)
        %             [dist, ix{category}, iy{category}] = dtw(weights{category},weights{j},10);
        %             D(category) = dist/length(ix{category});
        
        [dist, ix{category}, iy{category}] = dtw(weights{category},weights{j},30);
        if isnan(dist)
            D(category) = 1000;
        else
            freqDiff = abs(freqs(j) - freqs(category));
            timeDiff = abs(lengths(j) - lengths(category));
            D(category) = freqDiff + timeDiff + (dist / DistScale);
        end
    end
    Similarity(j,:) = D;
end

G = graph(Similarity);
Lidx = 1:length(G.Edges.Weight);
Nidx = Lidx(G.Edges.Weight > CombineVigilance);
H =  rmedge(G,Nidx);
bins = conncomp(H);
UpdatedWeight = {};
UpdatedLengths = [];
UpdatedClusterSize = [];
for p = 1:length(unique(bins))
    NN = (Neuron(bins==p));
    clustAssign(ismember(clustAssign,NN)) = p;
    
    %     NewWeight = weights{NN(1)};
    %     newLength = lengths(NN(1));
    %     NewFreq = freqs(NN(1));
    %     NewClusterSize = ClusterSize(NN(1));
    %     for jk = 2:length(NN)
    %
    %         [~, ix, iy] = dtw(NewWeight,weights{NN(jk)},10);
    %         warpfun = zeros(length(NewWeight),1);
    %         for i = 1:length(NewWeight)
    %             warpfun(i) = round(mean(iy(ix==i)));
    %         end
    %         NewWeight = NewWeight + (1 / length(NN)) * (weights{NN(jk)}(warpfun) - NewWeight); % Update weight
    %         newLength = newLength + (1 / length(NN)) * (lengths(NN(jk)) - newLength);
    %         NewFreq = NewFreq + (1 / length(NN)) * (freqs(NN(jk)) - NewFreq);
    % %         NewWeight = imresize(NewWeight,[round(newLength), 1]);
    %         NewClusterSize = NewClusterSize + (1.2 * NewClusterSize);
    %     end
    %     UpdatedWeight(p) = {NewWeight};
    %     UpdatedLengths(p) = newLength;
    %     UpdatedFreqs(p) = NewFreq;
    %     UpdatedClusterSize(p) = min(NewClusterSize,1.5);
    
    UpdatedWeight(p) = {mean([weights{NN}],2)};
    UpdatedLengths(p) = mean(lengths(NN));
    UpdatedFreqs(p) = mean(freqs(NN));
    UpdatedClusterSize(p) = min(ClusterSize(NN(1)) + (length(NN)-1)*.2,1.8);
end
weights = UpdatedWeight;
lengths = UpdatedLengths;
freqs = UpdatedFreqs;
ClusterSize = UpdatedClusterSize;
end
