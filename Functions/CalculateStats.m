function stats = CalculateStats(I,windowsize,noverlap,nfft,SampleRate,Box,EntropyThreshold,AmplitudeThreshold,verbose)
if ~(exist('verbose') == 1)
    verbose = 1;
end

spectrange = SampleRate / 2000; % get frequency range of spectrogram in KHz
FreqScale = spectrange / (1 + floor(nfft / 2)); % size of frequency pixels
TimeScale = (windowsize - noverlap) / SampleRate; % size of time pixels
[~, gy] = imgradientxy(I);
stats.FilteredImage =  gy;
stats.Entropy = geomean(I,1) ./ mean(I,1);

% Ridge Detection
[mx,ridgeFreq] = max((I));

greaterthannoise=smooth(stats.Entropy,5)' < 1-EntropyThreshold & (mx>(max(mx*AmplitudeThreshold))); % Select points greater than 0.2 time max
iter = 0;
while sum(greaterthannoise)<5
    iter = iter+1;
    if iter > 5;
        if verbose
            disp('Could not detect contour');
        end
        greaterthannoise = [1 1];
        break;
    end
    greaterthannoise=stats.Entropy < 1-EntropyThreshold+iter*.1 & (mx>(max(mx*AmplitudeThreshold - iter*.1))); % Select points greater than 0.2 time max
    if iter > 10; disp('Help!');end;
end
try
    ridgeFreq=ridgeFreq(greaterthannoise);
catch
    ridgeFreq = [1 2];
end
stats.ridgeTime=find(greaterthannoise==1);
try
    stats.ridgeFreq_smooth=smooth(stats.ridgeTime,ridgeFreq,7,'sgolay'); % Smooth fitted lime
catch
    if verbose
        disp('Cannot apply smoothing. The line is probably too short');
    end
    stats.ridgeFreq_smooth=ridgeFreq';
end
% Signal to Noise Ratio
stats.SignalToNoise = mean(1 - stats.Entropy(stats.ridgeTime));


% Frequency Stats
stats.PrincipalFreq= FreqScale * median(stats.ridgeFreq_smooth) + Box(2); % median frequency
stats.LowFreq = FreqScale * min(stats.ridgeFreq_smooth) + Box(2);
stats.HighFreq = FreqScale * max(stats.ridgeFreq_smooth) + Box(2);
stats.DeltaFreq = stats.HighFreq - stats.LowFreq;
stats.stdev = std(FreqScale*stats.ridgeFreq_smooth);

% Slope
try
    X = [ones(length(stats.ridgeTime),1), TimeScale*stats.ridgeTime.'];
    ls = X \ (FreqScale*stats.ridgeFreq_smooth);
    stats.Slope = ls(2);
catch
    stats.Slope = 0;
end

% Max Power
stats.MaxPower = mean(mx(stats.ridgeTime));
stats.Power = mx(stats.ridgeTime);

% Time Stats
stats.BeginTime = Box(1) + min(stats.ridgeTime)*TimeScale;
stats.EndTime = Box(1) + max(stats.ridgeTime)*TimeScale;
stats.DeltaTime = stats.EndTime - stats.BeginTime;

% Sinuosity
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


