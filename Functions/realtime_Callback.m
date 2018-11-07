function realtime_Callback(hObject, eventdata, handles)
% --- Executes on button press in realtime.
% hObject    handle to realtime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of realtime
if ~hObject.Value
    return
end

% Seconds to display
displaytime = 3;
starttime = tic;

minfrequency = 750;
maxdisplayfreq = 6500;
maxdetectfreq = 3500;
Fs = 16000;
recObj = audiorecorder(Fs,16,1,1);
StartRecording = tic;
record(recObj, 180);


%% Load the network
networkselections = get(handles.neuralnetworkspopup,'Value');
networkname = handles.networkfiles(networkselections).name;
NeuralNetwork=load([handles.networkfiles(networkselections).folder '\' networkname],'detector');%get currently selected option from menu

window = round(1000 * (Fs / 44100));
noverlap = round(400 * (Fs / 44100));
nfft = round(2000 * (Fs / 44100));

loadcalls_Callback(hObject, eventdata, handles,0,0)
handles = guidata(hObject);
set(handles.box,'Visible','off')

%%
% wait for data collection to start;
% pause(displaytime-toc(starttime))
pause(5);
c = 1;
while(hObject.Value)
    audio = getaudiodata(recObj,'double');
    
    [s, fr, ti] = spectrogram(audio(end-(Fs*displaytime):end),window,noverlap,nfft,Fs,'yaxis');
    s = abs(s);
    
    minfreq = find(fr>minfrequency,1);
    maxf = find(fr>maxdetectfreq,1);
    
    [bboxes, scores, Class] = detect(NeuralNetwork.detector, im2uint8(flipud(s(minfreq:maxf,:))), 'ExecutionEnvironment','auto'); % Matlab 2018 doesn't auto-convert to uint8
    bboxes(:,2) = length(fr) - (bboxes(:,2) + bboxes(:,4)-2) - (size(s,1)-maxf);
    
            bboxes = bboxes(scores > .9,:);
        scores = scores(scores > .9,:);

    if ~isempty(bboxes)
        
        % Tonality threshold
        tonalitythreshold = .45;

                
        for i = 1:size(bboxes,1)
            box = s(bboxes(i,2):bboxes(i,2)+bboxes(i,4)+10,...
                bboxes(i,1):bboxes(i,1)+bboxes(i,3)-1);
            tonaliy = 1-geomean(box) ./ mean(box);
            [~,C] = kmeans(tonaliy',2);
            scores(i) =  max(C);
            %scores(i) = scores(i) .*  (prctile(tonaliy,80) > tonalitythreshold);
        end
        
                bboxes = bboxes(scores > .5,:);
                scores = scores(scores > .5,:);
        
        %% Merge box
        OverBoxes=bboxes;
        OverBoxes(:,2)=1;
        OverBoxes(:,4)=100;
        xmin = bboxes(:,1);
        ymin = bboxes(:,2);
        xmax = xmin + bboxes(:,3) - 1;
        ymax = ymin + bboxes(:,4) - 1;
        overlapRatio = bboxOverlapRatio(OverBoxes, OverBoxes);
        n = size(overlapRatio,1);
        overlapRatio(1:n+1:n^2) = 0;
        %                 overlapRatio(overlapRatio<.2)=0; %Change Overlap Ratio Acceptance
        g = graph(overlapRatio);
        componentIndices = conncomp(g);
        xmin = accumarray(componentIndices', xmin, [], @min);
        ymin = accumarray(componentIndices', ymin, [], @min);
        xmax = accumarray(componentIndices', xmax, [], @max);
        ymax = accumarray(componentIndices', ymax, [], @max);
        merged_boxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
        bboxes = merged_boxes;
        scores = accumarray(componentIndices', scores, [], @max);
        %% 
        
        % Display boxes
        im = insertShape((abs(s)),'Rectangle',bboxes);
        set(handles.spect,'CData',im(:,:,1),'XData',ti,'YData',fr./1000);
        
    else
        set(handles.spect,'CData',(s),'XData',ti,'YData',fr./1000);
    end
    
    % Set display range te first time
    if c == 1
        c = 2;
        set(handles.axes1,'Xlim',[0 ti(end)])
        set(handles.axes1,'Ylim',[0, maxdisplayfreq./1000])
        set(handles.axes1,'YDir', 'normal','YColor',[1 1 1],'XColor',[1 1 1],'Clim',[0 1]);
    end
    
    drawnow
    if toc(starttime) > 180;
        recObj = audiorecorder(Fs,16,1,0);
        record(recObj, 180);
        starttime = tic;
        pause(4)
    end
end