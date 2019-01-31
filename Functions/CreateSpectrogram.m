function [I,windowsize,noverlap,nfft,rate,box,s,fr,ti,audio,AudioRange] = CreateSpectrogram(call)
%% Extract call features for CalculateStats and display

rate = call.Rate;
box = call.Box;

audio =  call.Audio;
if ~isfloat(audio)
    audio = double(audio) / (double(intmax(class(audio)))+1);
end


%% Make Spectrogram and box
% Spectrogram Settings
if (call.RelBox(3) < .4 ) || call.RelBox(2) > 25 && (call.RelBox(3) < .4 )% Spect settings for short calls
    windowsize = round(rate * 0.0032);
    noverlap = round(rate * 0.0028);
    nfft = round(rate * 0.0032);
else % long calls
    windowsize = round(rate * 0.01);
    noverlap = round(rate * 0.005);
    nfft = round(rate * 0.01);
end

% Spectrogram
[s, fr, ti] = spectrogram(audio,windowsize,noverlap,nfft,rate,'yaxis');


%% Get the part of the spectrogram within the box
x1=find(ti>=call.RelBox(1),1);
x2=find(ti>=(call.RelBox(1)+call.RelBox(3)),1);
if isempty(x2)
   x2=length(ti); 
end
y1=find(fr./1000>=round(call.RelBox(2)),1);
y2=find(fr./1000>=round(call.RelBox(2)+call.RelBox(4)),1);
I=abs(s(y1:y2,x1:x2));

% Audio range of box, for display
AudioRange = round((length(audio)/length(s(1,:)))* [x1,x2]);
