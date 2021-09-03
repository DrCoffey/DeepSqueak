function stats = CalculateStats(I,windowsize,noverlap,nfft,SampleRate,Box,EntropyThreshold,AmplitudeThreshold,verbose)
if nargin <= 8
    verbose = 1;
end

%% Ridge Detection
% Calculate entropy at each time point
stats.Entropy = geomean(I,1) ./ mean(I,1);
stats.Entropy = smooth(stats.Entropy,0.1,'rlowess')';
% % EntropyThreshold=prctile(1-stats.Entropy,20);
% % Find maximum amplitude and corresponding at each time point
% [amplitude,ridgeFreq] = max((I));
% amplitude = smooth(amplitude,0.1,'rlowess')';
% 
% % Get index of the time points where entropy and aplitude are greater than their thesholds
% % iteratively lower threshholds until at least 6 points are selected
% iter = 0;
% greaterthannoise = false(1, size(I, 2));
% while sum(greaterthannoise)<5
%     greaterthannoise = greaterthannoise | 1-stats.Entropy > EntropyThreshold   / 1.1 ^ iter;
%     greaterthannoise = greaterthannoise & amplitude       > AmplitudeThreshold / 1.1 ^ iter;
%     if iter > 10
% %         disp('Could not detect contour')
%         greaterthannoise = true(1, size(I, 2));
%         break;
%     end
%     iter = iter + 1;
%     if iter > 1
%         disp('lowering threshold')
%     end
% end
% I=imadjust(I);
% I = medfilt2(I,[2 3]);
% I=imgaussfilt(I,1);
if AmplitudeThreshold > .001 & AmplitudeThreshold < .999
    brightThreshold=prctile(I(:),AmplitudeThreshold*100);
else
    disp('Warning! Amplitude Percentile Threshold Must be (0 > 1), Reverting to Default (.825)');
    brightThreshold=prctile(I(:),82.5);
end

if EntropyThreshold < .001 | EntropyThreshold > .999 
    disp('Warning! Entropy Threshold Must be (0 > 1), Reverting to Default (.215)');
    EntropyThreshold=.215;
end

% % Get index of the time points where aplitude is greater than theshold
% % iteratively lower threshholds until at least 6 points are selected
[amplitude,ridgeFreq] = max(I,[],1);
%amplitude = smooth(amplitude,0.1,'rlowess')';
iter = 1;
greaterthannoise = false(1, size(I, 2));
while sum(greaterthannoise)<5
    if iter==1
        greaterthannoise = greaterthannoise | amplitude  > brightThreshold;
        greaterthannoise = greaterthannoise & 1-stats.Entropy  > EntropyThreshold;
    else
        greaterthannoise = greaterthannoise | amplitude  > brightThreshold / 1.1 ^ iter;
        greaterthannoise = greaterthannoise & 1-stats.Entropy  > EntropyThreshold / 1.1 ^ iter;
    end
    iter = iter + 1;
    if iter > 2
        disp('Not enough pts for contour - lowering threshold')
    end
end


% index of time points
stats.ridgeTime = find(greaterthannoise);
stats.ridgeFreq = ridgeFreq(greaterthannoise);
% Smoothed frequency of the call contour
try
    stats.ridgeFreq_smooth = smooth(stats.ridgeTime,stats.ridgeFreq,0.1,'rlowess');
    %stats.ridgeFreq_smooth = stats.ridgeFreq;
catch
    disp('Cannot apply smoothing. The line is probably too short');
    stats.ridgeFreq_smooth=stats.ridgeFreq';
end


%% Calculate the scaling factors of the spectrogram
spectrange = SampleRate / 2000; % get frequency range of spectrogram in KHz
FreqScale = spectrange / (1 + floor(nfft / 2)); % kHz per pixel
TimeScale = (windowsize - noverlap) / SampleRate; % seconds per pixel


%% Frequency gradient of spectrogram
[~, stats.FilteredImage] = imgradientxy(I);


%% Signal to Noise Ratio
stats.SignalToNoise = mean(1 - stats.Entropy(stats.ridgeTime));

%% Time Stats
stats.BeginTime = Box(1) + min(stats.ridgeTime)*TimeScale;
stats.EndTime = Box(1) + max(stats.ridgeTime)*TimeScale;
stats.DeltaTime = stats.EndTime - stats.BeginTime;

%% Frequency Stats
% Median frequency of the call contour
stats.PrincipalFreq= FreqScale * median(stats.ridgeFreq_smooth) + Box(2);

% Low frequency of the call contour
stats.LowFreq = FreqScale * min(stats.ridgeFreq_smooth) + Box(2);

% High frequency of the call contour
stats.HighFreq = FreqScale * max(stats.ridgeFreq_smooth) + Box(2);

% Delta frequency of the call contour
stats.DeltaFreq = stats.HighFreq - stats.LowFreq;

% Frequency standard deviation of the call contour
stats.stdev = std(FreqScale*stats.ridgeFreq_smooth);

% Slope of the call contour
try
    X = [ones(length(stats.ridgeTime),1), TimeScale*stats.ridgeTime.'];
    ls = X \ (FreqScale*stats.ridgeFreq_smooth);
    stats.Slope = ls(2);
catch
    stats.Slope = 0;
end

%% Max Power ( PSD )
% Magnitude
ridgePower = amplitude(stats.ridgeTime);
% Magnitude sqaured divided by sum of squares of hamming window
ridgePower = ridgePower.^2 / sum(hamming(windowsize).^2);
ridgePower = 2*ridgePower / SampleRate;
% Mean power of the call contour (mean needs to be before log)
stats.MeanPower = 10 * log10(mean(ridgePower));
% Convert power to db
ridgePower = 10 * log10(ridgePower);

% Max power of the call contour
stats.MaxPower = max(ridgePower);
% Power of the call contour
stats.Power = ridgePower;

% Peak frequency of the call contour
stats.RidgeFreq = FreqScale*stats.ridgeFreq_smooth + Box(2);
stats.PeakFreq = stats.RidgeFreq(stats.Power==max(ridgePower));

%% Sinuosity - path length / duration
try
    D = pdist([stats.ridgeTime' stats.ridgeFreq_smooth],'Euclidean');
    Z = squareform(D);
    leng=Z(1,end);
    c=0;
    for ll=2:length(Z)
        c=c+1;
        totleng(c)=Z(ll-1,ll);
    end
    stats.Sinuosity=sum(totleng)/leng;
catch
    stats.Sinuosity = 1;
end

end


