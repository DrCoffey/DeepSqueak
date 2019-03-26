function update_fig(hObject, eventdata, handles)
% Update the display

if isempty(handles.data.calls)
    return
end

% Get spectrogram data
[I,windowsize,noverlap,nfft,rate,box,s,fr,ti,audio,AudioRange] = CreateSpectrogram(handles.data.calls(handles.data.currentcall, :));

% Plot Spectrogram
set(handles.axes1,'YDir', 'normal','YColor',[1 1 1],'XColor',[1 1 1],'Clim',[0 2*mean(max(I))]);
set(handles.spect,'CData',imgaussfilt(abs(s)),'XData',ti,'YData',fr/1000);

if handles.data.settings.DisplayTimePadding ~= 0
    meantime = handles.data.calls.RelBox(handles.data.currentcall, 1) + handles.data.calls.RelBox(handles.data.currentcall, 3) / 2;
    set(handles.axes1,'Xlim',[meantime - (handles.data.settings.DisplayTimePadding / 2), meantime + (handles.data.settings.DisplayTimePadding / 2)], 'color', 'k')
else
    set(handles.axes1,'Xlim',[handles.spect.XData(1) handles.spect.XData(end)])
end

set(handles.axes1,'ylim',[handles.data.settings.LowFreq handles.data.settings.HighFreq]);
stats = CalculateStats(I,windowsize,noverlap,nfft,rate,box,handles.data.settings.EntropyThreshold,handles.data.settings.AmplitudeThreshold);

handles.data.calls.Power(handles.data.currentcall) = stats.MaxPower;

% Update slider with the call ID 
set(handles.slider1, 'Value', (handles.data.currentcall-1) / (height(handles.data.calls)-1));

% Box Creation
if handles.data.calls.Accept(handles.data.currentcall)
    set(handles.box,'Position',handles.data.calls.RelBox(handles.data.currentcall, :),'EdgeColor','g')
else
    set(handles.box,'Position',handles.data.calls.RelBox(handles.data.currentcall, :),'EdgeColor','r')
end

% Blur Box
set(handles.filtered_image_plot,'CData',flipud(stats.FilteredImage))
set(handles.axes4,'Color',[.1 .1 .1],'YColor',[1 1 1],'XColor',[1 1 1],'Box','off','Clim',[.2*min(min(stats.FilteredImage)) .2*max(max(stats.FilteredImage))],'XLim',[1 size(stats.FilteredImage,2)],'YLim',[1 size(stats.FilteredImage,1)]);
set(handles.axes4,'YTickLabel',[]);
set(handles.axes4,'XTickLabel',[]);
set(handles.axes4,'XTick',[]);
set(handles.axes4,'YTick',[]);

% plot Ridge Detection
set(handles.ContourScatter,'XData',stats.ridgeTime','YData',stats.ridgeFreq_smooth);
set(handles.axes7,'Xlim',[1 size(I,2)],'Ylim',[1 size(I,1)]);

% Plot Slope
X = [ones(size(stats.ridgeTime)); stats.ridgeTime]';
ls = X \ (stats.ridgeFreq_smooth);
handles.ContourLine.XData = [1 size(I,2)];
handles.ContourLine.YData = [ls(1), ls(1) + ls(2) * size(I,2)];


% Update call statistics text
set(handles.Ccalls,'String',['Call: ' num2str(handles.data.currentcall) '/' num2str(height(handles.data.calls))])
set(handles.score,'String',['Score: ' num2str(handles.data.calls.Score(handles.data.currentcall))])
if handles.data.calls.Accept(handles.data.currentcall)
    set(handles.status,'String','Accepted')
else
    set(handles.status,'String','Rejected')
end
set(handles.text19,'String',['Label: ' char(handles.data.calls.Type(handles.data.currentcall))]);
set(handles.freq,'String',['Frequency: ' num2str(stats.PrincipalFreq,'%.1f') ' kHz']);
set(handles.slope,'String',['Slope: ' num2str(stats.Slope,'%.3f') ' kHz/s']);
set(handles.duration,'String',['Duration: ' num2str(stats.DeltaTime*1000,'%.0f') ' ms']);
set(handles.sinuosity,'String',['Sinuosity: ' num2str(stats.Sinuosity,'%.4f')]);
set(handles.powertext,'String',['Avg. Power: ' num2str(handles.data.calls.Power(handles.data.currentcall)) ' dB/Hz'])
set(handles.tonalitytext,'String',['Avg. Tonality: ' num2str(stats.SignalToNoise,'%.4f')]);

% Waveform
PlotAudio = audio(AudioRange(1):AudioRange(2));
set(handles.Waveform,...
    'XData', length(stats.Entropy) * ((1:length(PlotAudio)) / length(PlotAudio)),...
    'YData', (.5*PlotAudio/max(PlotAudio)-.5))
    
% SNR
y = 0-stats.Entropy;
x = 1:length(stats.Entropy);
z = zeros(size(x));
col = double(stats.Entropy < 1-handles.data.settings.EntropyThreshold);  % This is the color, vary with x in this case.
set(handles.SNR, 'XData', [x;x], 'YData', [y;y], 'ZData', [z;z], 'CData', [col;col]);
set(handles.axes3, 'XLim', [x(1), x(end)]);

% Plot Call Position
calltime = handles.data.calls.Box(handles.data.currentcall, 1);
handles.CurrentCallLinePosition.XData = [calltime, calltime];
if handles.data.calls.Accept(handles.data.currentcall)
    handles.CurrentCallLinePosition.Color = [0,1,0];
else
    handles.CurrentCallLinePosition.Color = [1,0,0];
end
set(handles.CurrentCallLineLext,'Position',[calltime,1.2,0],'String',[num2str(stats.BeginTime,'%.1f') ' s']);
