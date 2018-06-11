function update_fig(hObject, eventdata, handles)
% Update the display
if isempty(handles.calls)
    errordlg('No calls in file')
    return
end
audio =  handles.calls(handles.currentcall).Audio;
if ~isa(audio,'double')
    audio = double(audio) / (double(intmax(class(audio)))+1);
end

%Make Spectrogram and box
if (handles.calls(handles.currentcall).RelBox(3) < .4 ) || handles.calls(handles.currentcall).RelBox(2) > 25 && (handles.calls(handles.currentcall).RelBox(3) < .4 )% Spect settings for short calls
    windowsize = round(handles.calls(handles.currentcall).Rate * 0.0032);
    noverlap = round(handles.calls(handles.currentcall).Rate * 0.0028);
    nfft = round(handles.calls(handles.currentcall).Rate * 0.0032);
else % long calls
    windowsize = round(handles.calls(handles.currentcall).Rate * 0.01);
    noverlap = round(handles.calls(handles.currentcall).Rate * 0.005);
    nfft = round(handles.calls(handles.currentcall).Rate * 0.01);
end

[s, fr, ti] = spectrogram(audio,windowsize,noverlap,nfft,handles.calls(handles.currentcall).Rate,'yaxis');

x1=find(ti>=handles.calls(handles.currentcall).RelBox(1),1);
x2=find(ti>=(handles.calls(handles.currentcall).RelBox(1)+handles.calls(handles.currentcall).RelBox(3)),1);
y1=find(fr./1000>=round(handles.calls(handles.currentcall).RelBox(2)),1);
y2=find(fr./1000>=round(handles.calls(handles.currentcall).RelBox(2)+handles.calls(handles.currentcall).RelBox(4)),1);
I=abs(s(y1:y2,x1:x2)); % Get the part of the spectrogram within the box
FR=(fr(y1:y2));

% Plot Spectrogram
set(handles.axes1,'YDir', 'normal','YColor',[1 1 1],'XColor',[1 1 1],'Clim',[0 2*mean(max(I))]);
colormap(handles.axes1,handles.cmap);
set(handles.spect,'CData',imgaussfilt(abs(s)),'XData',ti,'YData',fr/1000);
set(handles.axes1,'Xlim',[handles.spect.XData(1) handles.spect.XData(end)])

set(handles.axes1,'ylim',[handles.settings.LowFreq handles.settings.HighFreq]);
% xlim([min(ti) max(ti)]);

stats = CalculateStats(I,windowsize,noverlap,nfft,handles.calls(handles.currentcall).Rate,handles.calls(handles.currentcall).Box,handles.settings.EntropyThreshold,handles.settings.AmplitudeThreshold);
handles.calls(handles.currentcall).Power=stats.MaxPower;

% Set Text
set(handles.text19,'String',['Label: ' char(handles.calls(handles.currentcall).Type)]);
set(handles.score,'String',['Score: ' num2str(handles.calls(handles.currentcall).Score)])
set(handles.slider1,'Value',((handles.currentcall-1)/(length(handles.calls)-1)));
set(handles.Ccalls,'String',['Call: ' num2str(handles.currentcall) '/' num2str(length(handles.calls))])
if handles.calls(handles.currentcall).Accept==1
    set(handles.status,'String','Accepted')
else
    set(handles.status,'String','Rejected')
end

% Box Creation
if handles.calls(handles.currentcall).Accept==1
    set(handles.box,'Position',handles.calls(handles.currentcall).RelBox,'EdgeColor','g')
else
    set(handles.box,'Position',handles.calls(handles.currentcall).RelBox,'EdgeColor','r')
end

% Blur Box
imagesc(flipud(stats.FilteredImage),'Parent', handles.axes4);
set(handles.axes4,'Color',[.1 .1 .1],'YColor',[1 1 1],'XColor',[1 1 1],'Box','off','Clim',[.2*min(min(stats.FilteredImage)) .2*max(max(stats.FilteredImage))]);
colormap(handles.axes4,handles.cmap);
% colormap(handles.axes4,'gray');
set(handles.axes4,'YTickLabel',[]);
set(handles.axes4,'XTickLabel',[]);
set(handles.axes4,'XTick',[]);
set(handles.axes4,'YTick',[]);


% plot Ridge Detection
scatter(stats.ridgeTime,stats.ridgeFreq_smooth,'LineWidth',1.5,'Parent',handles.axes7);
set(handles.axes7,'Color',[.1 .1 .1],'YColor',[1 1 1],'XColor',[1 1 1],'Box','off','Xlim',[1 length(stats.FilteredImage(1,:))],'Ylim',[1 length(stats.FilteredImage(:,1))]);
set(handles.axes7,'YTickLabel',[]);
set(handles.axes7,'XTickLabel',[]);
set(handles.axes7,'XTick',[]);
set(handles.axes7,'YTick',[]);
hl = lsline(handles.axes7);
set(hl,'LineStyle','--','Color','y');

set(handles.slope,'String',['Slope: ' num2str(stats.Slope,'%.3f') ' KHz/s']);
set(handles.duration,'String',['Duration: ' num2str(stats.DeltaTime*1000,'%.0f') ' ms']);
set(handles.sinuosity,'String',['Sinuosity: ' num2str(stats.Sinuosity,'%.4f')]);
set(handles.powertext,'String',['Avg. Power: ' num2str(handles.calls(handles.currentcall).Power)])
set(handles.freq,'String',['Frequency: ' num2str(stats.PrincipalFreq,'%.1f') ' KHz']);

% Waveform
cla(handles.axes3)
hold(handles.axes3,'on')
lef=(length(audio)/length(s(1,:)))*x1;
rig=(length(audio)/length(s(1,:)))*x2;
PlotAudio = audio(round(lef:rig));
plot(handles.axes3,length(stats.Entropy) * ((1:length(PlotAudio)) / length(PlotAudio)),(.5*PlotAudio/max(PlotAudio)-.5),'Color',[.5 .5 .1]);

% SNR
y = 0-stats.Entropy;
x = 1:length(stats.Entropy);
z = zeros(size(x));
col = double(stats.Entropy < 1-handles.settings.EntropyThreshold);  % This is the color, vary with x in this case.
surface(handles.axes3,[x;x],[y;y],[z;z],[col;col],...
    'facecol','r',...
    'edgecol','interp',...
    'linew',2);
set(handles.axes3,'YTickLabel',[]);
set(handles.axes3,'XTickLabel',[]);
set(handles.axes3,'XTick',[]);
set(handles.axes3,'YTick',[]);
set(handles.axes3,'Color',[.1 .1 .1],'YColor',[1 1 1],'XColor',[1 1 1],'Box','off','Xlim',[0 length(stats.Entropy)],'Ylim',[-1 0],'Clim',[0 1]);
hold(handles.axes3,'off')

% Plot Call Position
cla(handles.axes5)
line([0 max(handles.CallTime(:,1))],[0 0],'LineWidth',1,'Color','w','Parent', handles.axes5);
line([0 max(handles.CallTime(:,1))],[1 1],'LineWidth',1,'Color','w','Parent', handles.axes5);
set(handles.axes5,'XLim',[0 max(handles.CallTime(:,1))]);
set(handles.axes5,'YLim',[0 1]);

set(handles.axes5,'Color',[.1 .1 .1],'YColor',[.1 .1 .1],'XColor',[.1 .1 .1],'Box','off','Clim',[0 1]);
set(handles.axes5,'YTickLabel',[]);
set(handles.axes5,'XTickLabel',[]);
set(handles.axes5,'XTick',unique(sort(handles.CallTime(:,1))));
set(handles.axes5,'YTick',[]);
handles.axes5.XAxis.Color = 'w';

handles.axes5.XAxis.TickLength = [0.035 1]; % Update display with time in file

if handles.calls(handles.currentcall).Accept==1
    line([handles.CallTime(handles.currentcall,1) handles.CallTime(handles.currentcall,1)],[0 1],'LineWidth',3,'Color','g','Parent', handles.axes5);
else
    line([handles.CallTime(handles.currentcall,1) handles.CallTime(handles.currentcall,1)],[0 1],'LineWidth',3,'Color','r','Parent', handles.axes5);
end
text((max(handles.CallTime(handles.currentcall,1))),1.2,[num2str(stats.BeginTime,'%.1f') ' s'],'Color','W', 'HorizontalAlignment', 'center','Parent',handles.axes5)
guidata(hObject, handles);
end
