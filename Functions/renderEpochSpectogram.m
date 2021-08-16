function  handles = renderEpochSpectogram(hObject, handles)
%Plot current spectogram window

handles.data.lastWindowPosition = handles.data.windowposition;
windowsize = round(handles.data.audiodata.SampleRate * handles.data.settings.spect.windowsize);
noverlap = round(handles.data.audiodata.SampleRate * handles.data.settings.spect.noverlap);
nfft = round(handles.data.audiodata.SampleRate * handles.data.settings.spect.nfft);

%% Get audio within the page range, padded by focus window size
window_start = max(handles.data.windowposition - handles.data.settings.focus_window_size/2, 0);
window_stop = handles.data.windowposition + handles.data.settings.pageSize + handles.data.settings.focus_window_size/2;
audio = handles.data.AudioSamples(window_start, window_stop);

%% Make the spectrogram
[s, f, t] = spectrogram(audio,windowsize,noverlap,nfft,handles.data.audiodata.SampleRate,'yaxis');
t = t + window_start; % Add the start of the window the time units
s_display = scaleSpectogram(s, handles.data.settings.spect.type, windowsize, handles.data.audiodata.SampleRate);

%% Find the color scale limits
% handles.data.clim = prctile(s_display(20:10:end-20, 1:20:end),[10,90], 'all')';
% handles.data.clim = prctile(handles.data.clim,90,1);
% clim = handles.data.clim + range(handles.data.clim) * [.1, 1] * handles.data.settings.spectrogramContrast;

%% Plot Spectrogram in the page view
% set(handles.spectogramWindow,...
%     'Xlim', [handles.data.windowposition, handles.data.windowposition + handles.data.settings.pageSize],...
%     'Ylim',[handles.data.settings.LowFreq, min(handles.data.settings.HighFreq, handles.data.audiodata.SampleRate/2000)]);
set(handles.spectogramWindow,...
    'Xlim', [handles.data.windowposition, handles.data.windowposition + handles.data.settings.pageSize],...
    'Ylim',f([1,end])/1000);
set(handles.epochSpect,'CData',s_display,'XData', t, 'YData',f/1000);


% set(handles.spectogramWindow,'YDir', 'normal','YColor',[1 1 1],'XColor',[1 1 1],'Clim', clim);
set_tick_timestamps(handles.spectogramWindow, false);


%% Plot Spectrogram in the focus view
% set(handles.focusWindow,'YDir', 'normal','YColor',[1 1 1],'XColor',[1 1 1],'Clim',[0 get_spectogram_max(hObject,handles)]);
set(handles.focusWindow,'YDir', 'normal','YColor',[1 1 1],'XColor',[1 1 1])
% set(handles.spect,'Parent',handles.focusWindow);
% set(handles.spect,'CData',zoomed_s,'XData', zoomed_t,'YData',zoomed_f/1000);


%% Send the spectrogram back to handles
handles.data.page_spect.s = s;
handles.data.page_spect.f = f;
handles.data.page_spect.t = t;
handles.data.page_spect.s_display = s_display;

