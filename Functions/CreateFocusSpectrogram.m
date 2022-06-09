function [I,windowsize,noverlap,nfft,rate,box,s,fr,ti,audio,p] = CreateFocusSpectrogram(call,handles, make_spectrogram, options, audioReader)
%% Extract call features for CalculateStats and display

if nargin < 3
    make_spectrogram = true;
end

if nargin < 4 || isempty(options)
    yRange = mean(call.Box(1,4));
    xRange = mean(call.Box(1,3));
    noverlap = .5;
    optimalWindow = sqrt(xRange/(2000*yRange));
    optimalWindow = optimalWindow + optimalWindow.*noverlap;
    options = struct;
    options.windowsize = optimalWindow;
    options.overlap = optimalWindow .* noverlap;
    options.nfft = optimalWindow;
    options.frequency_padding = 0;
    options.freq_range = [];
end

box = call.Box;

if isfield(options, 'freq_range') && ~isempty(options.freq_range)
    box(2) = options.freq_range(1);
    box(4) = options.freq_range(2) - options.freq_range(1);
end

rate = audioReader.audiodata.SampleRate;
windowsize = round(rate * options.windowsize);
noverlap = round(rate * options.overlap);
nfft = round(rate * options.nfft);
    
if make_spectrogram
    audio = audioReader.AudioSamples(box(1), box(1) + box(3));
    [s, fr, ti, p] = spectrogram(audio,windowsize,noverlap,nfft,rate,'yaxis');
else
    s  = handles.data.page_spect.s(:,handles.data.page_spect.t > call.Box(1) & handles.data.page_spect.t < sum(call.Box([1,3])));
    ti = handles.data.page_spect.t(  handles.data.page_spect.t > call.Box(1) & handles.data.page_spect.t < sum(call.Box([1,3])));
    fr = handles.data.page_spect.f;

end
    
%% Get the part of the spectrogram within the box
x1 = 1;
x2 = length(ti);

min_freq = find(fr./1000 >= box(2) - options.frequency_padding,1);
min_freq = max(min_freq, 1);

max_freq = find(fr./1000 <= box(4) + box(2) + options.frequency_padding, 1, 'last');
max_freq = min(round(max_freq), length(fr));

I=abs(s(min_freq:max_freq,x1:x2));
p=p(min_freq:max_freq,x1:x2);
end