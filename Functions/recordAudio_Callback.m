% --- Executes on button press in recordAudio.
function recordAudio_Callback(hObject, eventdata, handles)
% hObject    handle to recordAudio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
get(hObject,'Value');
handles = guidata(hObject);

%Check if detection file has changed to save file before loading a new one.
if ~isempty(handles.data.calls)
    [tmpcalls, ~] = loadCallfile(fullfile(handles.detectionfiles(handles.current_file_id).folder,  handles.current_detection_file), handles);
    if ismember('Power',tmpcalls.Properties.VariableNames)
        tmpcalls = removevars(tmpcalls,'Power');
    end
    if ~isequal(tmpcalls, handles.data.calls)
        opts.Interpreter = 'tex';
        opts.Default='Yes';
        saveChanges = questdlg('\color{red}\bf WARNING! \color{black} Detection file has been modified. Would you like to save changes?','Save Detection File?','Yes','No',opts);
        switch saveChanges
            case 'Yes'
                savesession_Callback(hObject, eventdata, handles);
            case 'No'
        end
    end
end

if eventdata.Source.Value==1
    if isfield(handles,'epochSpect')
        % Clear everything if calls are present
        cla(handles.contourWindow);
        cla(handles.detectionAxes);
        cla(handles.focusWindow);
        cla(handles.spectogramWindow);
        cla(handles.waveformWindow);
        Calls = table(zeros(0,4),[],[],[], 'VariableNames', {'Box', 'Score', 'Type', 'Accept'});
        set(handles.Ccalls,'String','Call: ');
        set(handles.score,'String','Score: ');
        set(handles.status,'String','');
        set(handles.text19,'String','Label: ');
        set(handles.freq,'String','Frequency: ');
        set(handles.slope,'String','Slope: ');
        set(handles.duration,'String','Duration: ');
        set(handles.sinuosity,'String','Sinuosity: ');
        set(handles.powertext,'String','Power: ');
        set(handles.tonalitytext,'String','Tonality: ');
    end
    hObject.String='Recording';
    hObject.BackgroundColor=[0.84,0.08,0.18];
    prompt = {'Recording Length (Seconds; 0 = Continuous)','Sample Rate (Max=250,000)','Filename'};
    dlg_title = 'Rercording Settings (Uses Default Microphone)';
    num_lines=[1 100]; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
    detectiontime=datestr(datetime('now'),'yyyy-mm-dd HH_MM PM');
    def = {'0','44100',strcat(detectiontime,' -Live')};
    recSettings=inputdlg(prompt,dlg_title,num_lines,def,options);
    if isempty(recSettings)==0
    deviceReader = audioDeviceReader(str2num(recSettings{2}),round(str2num((recSettings{2}))*handles.data.settings.focus_window_size));
    fileWriter = dsp.AudioFileWriter('SampleRate',deviceReader.SampleRate,'Filename',fullfile(handles.data.settings.audiofolder,[recSettings{3} '.flac']),'FileFormat','FLAC');
    rate = deviceReader.SampleRate;
    if str2num(recSettings{1})<=0;
        recTime=inf;
    else
        recTime=str2num(recSettings{1});
    end
    
    %Optimal Spectrogram Settings
    noverlap = .5;
    optimalWindow = sqrt(handles.data.settings.focus_window_size/(rate));
    optimalWindow = optimalWindow + optimalWindow.*noverlap;
    options = struct;
    options.windowsize = round(rate*optimalWindow);
    options.overlap = round(rate*optimalWindow .* noverlap);
    options.nfft = round(rate*optimalWindow);
    
    loop=1;
    tic
    while toc<recTime && eventdata.Source.Value==1
        audio = deviceReader();
        fileWriter(audio);
        
        if loop==1;
            % Blank Epoch spectogram
            c=0;
            [~, fr, ti, p] = spectrogram(audio,options.windowsize,options.overlap,options.nfft,rate,'yaxis');
            p(p==0)=.01;
            p = log10(p);
            p = rescale(imcomplement(abs(p)));
            % Create Adjusted Image for Identification
            xTile=ceil(size(p,1)/50);
            yTile=ceil(size(p,2)/50);
            if xTile>1 && yTile>1
                p = adapthisteq(p,'NumTiles',[xTile yTile],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);
            else
                p = adapthisteq(p,'NumTiles',[5 5],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);
            end
            handles.liveSpect = imagesc(ti,fr/1000,p,'Parent', handles.focusWindow,prctile(p,[1,100], 'all')');
            colormap(handles.data.cmap);
            cb=colorbar(handles.focusWindow);
            cb.Label.String = handles.data.settings.spect.type;
            cb.Color = [1 1 1];
            cb.FontSize = 11;
            ylabel(handles.focusWindow,'Frequency (kHz)','Color','w','FontSize',11);
            xlabel(handles.focusWindow,'Time (s)','Color','w');
            set(handles.focusWindow,'YDir', 'normal','YColor',[1 1 1],'XColor',[1 1 1]);
            set(handles.focusWindow,'Clim',prctile(p,[1,100], 'all')');
            loop=2;
            drawnow;
        end
        
        if loop==2;
            c=c+1;
            lT=handles.data.settings.focus_window_size*c;
            [~, fr, ti, p] = spectrogram(audio,options.windowsize,options.overlap,options.nfft,rate,'yaxis');
            p(p==0)=.01;
            p = log10(p);
            p = rescale(imcomplement(abs(p)));
            % Create Adjusted Image for Identification
            if xTile>1 && yTile>1
                p = adapthisteq(p,'NumTiles',[xTile yTile],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);
            else
                p = adapthisteq(p,'NumTiles',[5 5],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);
            end
            set(handles.liveSpect,'CData',p,'XData', ti, 'YData',fr/1000);
            %set(handles.focusWindow,'CLim',prctile(p,[1,100], 'all')');
            xt = xticks;
            xticklabels(xt+lT);
            drawnow;
        end
    end
    release(deviceReader);
    release(fileWriter);
    drawnow nocallbacks;
    end
end

hObject.String='Record';
hObject.BackgroundColor=[0.20,0.83,0.10];
eventdata.Source.Value=0;
update_folders(hObject, eventdata, handles);