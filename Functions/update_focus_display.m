function handles = update_focus_display(handles)


% Values for the spectrogram are already calculated in renderEpochSpectogram
s_f  = handles.data.page_spect.s_display(:,handles.data.page_spect.t > handles.current_focus_position(1) & handles.data.page_spect.t < sum(handles.current_focus_position([1,3])));
ti_f = handles.data.page_spect.t(handles.data.page_spect.t > handles.current_focus_position(1) & handles.data.page_spect.t < sum(handles.current_focus_position([1,3])));
fr_f = handles.data.page_spect.f;


% Plot Spectrogram
% set(handles.focusWindow,'YDir', 'normal','YColor',[1 1 1],'XColor',[1 1 1],'Clim',prctile(s_f,[1,99.9],'all'))


set(handles.spect,'CData',s_f,'XData', ti_f,'YData',fr_f/1000);
set(handles.focusWindow,...
    'Xlim', [handles.current_focus_position(1), handles.current_focus_position(1) + handles.current_focus_position(3)],...
    'Ylim',[handles.data.settings.LowFreq, min(handles.data.settings.HighFreq, handles.data.audiodata.SampleRate/2000)]);
%     'YDir', 'normal',...
%     'YColor',[1 1 1],...
%     'XColor',[1 1 1]);

%Update spectogram ticks and transform labels to
%minutes:seconds.milliseconds
set_tick_timestamps(handles.focusWindow, true);

% set(handles.focusWindow,'ylim',[spectogram_y_lims(1)/1000 spectogram_y_lims(2)/1000]);

% Don't update the call info the there aren't any calls in the page view
if isempty(handles.data.calls) || ~any(handles.data.calls.Box(handles.data.currentcall,1) > ti_f(1) &...
        sum(handles.data.calls.Box(handles.data.currentcall,[1,3]),2) < ti_f(end))
    return
end

% If Tonality and Amplitude were previously changed, apply the saved values
% to the global settings
if handles.data.calls.EntThresh(handles.data.currentcall) ~= 0
    handles.data.settings.EntropyThreshold = handles.data.calls.EntThresh(handles.data.currentcall);
end
if handles.data.calls.AmpThresh(handles.data.currentcall) ~= 0
    handles.data.settings.AmplitudeThreshold = handles.data.calls.AmpThresh(handles.data.currentcall);
end

% Set the sliders to the saved values
set(handles.TonalitySlider, 'Value', handles.data.settings.EntropyThreshold);

[I,windowsize,noverlap,nfft,rate,box,~,~,~] = CreateFocusSpectrogram(handles.data.calls(handles.data.currentcall,:),handles,false, [], handles.data);
stats = CalculateStats(I,windowsize,noverlap,nfft,rate,box,handles.data.settings.EntropyThreshold,handles.data.settings.AmplitudeThreshold);

handles.data.calls.Power(handles.data.currentcall) = stats.MeanPower;
handles.data.calls.EntThresh(handles.data.currentcall) = handles.data.settings.EntropyThreshold;
handles.data.calls.AmpThresh(handles.data.currentcall) = handles.data.settings.AmplitudeThreshold;


% plot Ridge Detection
set(handles.ContourScatter,'XData',stats.ridgeTime','YData',stats.ridgeFreq_smooth);
set(handles.contourWindow,'Xlim',[1 size(I,2)],'Ylim',[1 size(I,1)]);

% Plot Slope
X = [ones(size(stats.ridgeTime)); stats.ridgeTime]';
ls = X \ (stats.ridgeFreq_smooth);
handles.ContourLine.XData = [1 size(I,2)];
handles.ContourLine.YData = [ls(1), ls(1) + ls(2) * size(I,2)];


% Update call statistics text
set(handles.Ccalls,'String',['Call: ' num2str(handles.data.currentcall) '/' num2str(height(handles.data.calls))]);
set(handles.score,'String',['Score: ' num2str(handles.data.calls.Score(handles.data.currentcall))]);
if handles.data.calls.Accept(handles.data.currentcall)
    set(handles.status,'String','Accepted');
    set(handles.status,'ForegroundColor',[0,1,0]); 
else
    set(handles.status,'String','Rejected');
    set(handles.status,'ForegroundColor',[1,0,0])       
end
set(handles.text19,'String',['Label: ' char(handles.data.calls.Type(handles.data.currentcall))]);
set(handles.freq,'String',['Frequency: ' num2str(stats.PrincipalFreq,'%.1f') ' kHz']);
set(handles.slope,'String',['Slope: ' num2str(stats.Slope,'%.3f') ' kHz/s']);
set(handles.duration,'String',['Duration: ' num2str(stats.DeltaTime*1000,'%.0f') ' ms']);
set(handles.sinuosity,'String',['Sinuosity: ' num2str(stats.Sinuosity,'%.4f')]);
set(handles.powertext,'String',['Rel Power: ' num2str(handles.data.calls.Power(handles.data.currentcall)) ' dB/Hz'])
set(handles.tonalitytext,'String',['Tonality: ' num2str(stats.SignalToNoise,'%.4f')]);

% Waveform
PlotAudio = handles.data.AudioSamples(handles.data.calls.Box(handles.data.currentcall,1),...
    sum(handles.data.calls.Box(handles.data.currentcall,[1,3])));
% PlotAudio = highpass(PlotAudio, box(4)*500, handles.data.audiodata.SampleRate);
% set(handles.Waveform,...
%     'XData', length(stats.Entropy) * ((1:length(PlotAudio)) / length(PlotAudio)),...
%     'YData', 0.5 .* PlotAudio ./ max(PlotAudio) - 0.5)

PlotAudio = PlotAudio - movmean(PlotAudio, 100);
set(handles.Waveform,...
'XData', length(stats.Entropy) * ((1:length(PlotAudio)) / length(PlotAudio)),...
'YData', (PlotAudio - min(PlotAudio)) / (max(PlotAudio) - min(PlotAudio)) - 1);

% % SNR
y = 0-stats.Entropy;
x = 1:length(stats.Entropy);
z = zeros(size(x));
col = double(stats.Entropy < 1-handles.data.settings.EntropyThreshold);  % This is the color, vary with x in this case.
set(handles.SNR, 'XData', [x;x], 'YData', [y;y], 'ZData', [z;z], 'CData', [col;col]);
set(handles.waveformWindow, 'XLim', [x(1), x(end)]);

% guidata(hObject, handles);
end

