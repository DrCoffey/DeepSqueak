function initialize_display(hObject, eventdata, handles)

% Remove anything currently in the axes
cla(handles.contourWindow);
cla(handles.detectionAxes);
cla(handles.focusWindow);
cla(handles.spectogramWindow);
cla(handles.waveformWindow);

%
handles.data.currentcall = 1;
handles.data.current_call_valid = true;

handles.data.windowposition = 0;
handles.data.lastWindowPosition = -1;
handles.update_position_axes = 1;
    
if handles.data.settings.LowFreq >= handles.data.audiodata.SampleRate/2000
    handles.data.settings.LowFreq = 0;
end

%% Create plots for update_fig to update

% Waveform
handles.Waveform = line(handles.waveformWindow,1,1,'Color',[219/255 82/255 56/255]);
handles.SNR = surface(handles.waveformWindow,[],[],[],[],...
    'facecol','r',...
    'edgecol','interp',...
    'linew',2);
set(handles.waveformWindow,...
    'YTickLabel',[],...
    'XTickLabel',[],...
    'XTick',[],...
    'YTick',[],...
    'Color',[.1 .1 .1],'YColor',[1 1 1],'XColor',[1 1 1],...
    'Box','off',...
    'Ylim',[-1 0],...
    'Clim',[0 1],...
    'Colormap', parula);

% Contour
handles.ContourScatter = scatter(1:5,1:5,20,[242/255 115/255 26/255],'filled', 'LineWidth',1.5,'Parent',handles.contourWindow,'XDataSource','x','YDataSource','y');
set(handles.contourWindow,'Color',[.1 .1 .1],'YColor',[1 1 1],'XColor',[1 1 1],'Box','off');
set(handles.contourWindow,'YTickLabel',[]);
set(handles.contourWindow,'XTickLabel',[]);
set(handles.contourWindow,'XTick',[]);
set(handles.contourWindow,'YTick',[]);
handles.ContourLine = line(handles.contourWindow,[1,5],[1,5],'LineStyle','--','Color',[145/255 36/255 102/255]);

% Focus spectogram
handles.spect = imagesc([],[],handles.background,'Parent', handles.focusWindow);
cb=colorbar(handles.focusWindow);
cb.Label.String = handles.data.settings.spect.type;
cb.Color = [1 1 1];
cb.FontSize = 11;
ylabel(handles.focusWindow,'Frequency (kHz)','Color','w','FontSize',11);
%xlabel(handles.focusWindow,'Time (s)','Color','w');
set(handles.focusWindow,'Color',[.1 .1 .1]);


% Epoch spectogram
handles.epochSpect = imagesc([],[],handles.background,'Parent', handles.spectogramWindow);
cb=colorbar(handles.spectogramWindow);
cb.Label.String = handles.data.settings.spect.type;
cb.Color = [1 1 1];
cb.FontSize = 11;
ylabel(handles.spectogramWindow,'Frequency (kHz)','Color','w','FontSize',11);
xlabel(handles.spectogramWindow,[]);
set(handles.spectogramWindow,'YDir', 'normal','YColor',[1 1 1],'XColor',[1 1 1],'Clim',[0 1]);
set(handles.spectogramWindow,'Color',[.1 .1 .1]);
set(handles.spectogramWindow,'Visible', 'on');
set(handles.epochSpect,'Visible', 'on');
set(handles.epochSpect,'ButtonDownFcn', @(hObject,eventdata) mousePositionSelection_Callback(hObject,eventdata,guidata(hObject)));


%Make the top scroll button visible
set(handles.topRightButton, 'Visible', 'on');
set(handles.topLeftButton, 'Visible', 'on');

handles.PageWindowRectangles = {};
handles.FocusWindowRectangles = {};

colormap(handles.focusWindow,handles.data.cmap);
colormap(handles.spectogramWindow,handles.data.cmap);

callPositionAxesXLim = xlim(handles.detectionAxes);
callPositionAxesXLim(1) = 0;
callPositionAxesXLim(2) = handles.data.audiodata.Duration;
xlim(handles.detectionAxes,callPositionAxesXLim);

% Rectangle that shows the current position in the spectrogram
handles.currentWindowRectangle = rectangle(handles.spectogramWindow,...
    'Position',[0,0,0,0],...
    'FaceColor', [1, 1, 1, 0.15],...
    'EdgeColor', [1, 1, 1, 1], 'LineWidth',1.5,...
    'LineStyle','--',...
    'PickableParts', 'none');

update_fig(hObject, eventdata, handles);
handles = guidata(hObject);

%% Find the color scale limits
%handles.data.clim = prctile(handles.data.page_spect.s_display(20:10:end-20, 1:20:end),[10,90], 'all')';
handles.data.clim = prctile(handles.data.page_spect.s_display,[10,90], 'all')';
change_spectogram_contrast_Callback(hObject,[],handles);
