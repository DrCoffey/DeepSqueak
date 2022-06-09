function Batch_Reject_by_Threshold_Callback(hObject, eventdata, handles)
% hObject    handle to Batch_Reject_by_Threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Set the current call in the settings figure

if ~(isfield(handles,'detectionfilesnames') && ~isempty(handles.detectionfilesnames))
    msgbox('Please select a non-empty detection folder first')
    return
end


if isfield(handles,'current_file_id')
    currentfile = handles.current_file_id;
else
    currentfile = 1;
end

%% Selection GUI
d = dialog('Position',[200,500,500,600],'WindowStyle','Normal','resize', 'on', 'Visible', 'off');
movegui(d,'center')
movegui(d,'onscreen')

d.UserData = 2;

uitText = uicontrol('Parent',d,...
    'Units','normalized',...
    'Style','text',...
    'Position', [.02 .95 .96 .033],...
    'String',{'Set rules for accepting/rejecting calls (ACCEPT SUPERSEDES REJECT!)'});

uit = uitable('Parent',d,...
    'Units','normalized',...
    'ColumnFormat',{
    {' ','Reject calls with','Accept calls with'}, {'Tonality','Frequency (kHz)','Power (dB/Hz)','Duration (s)', 'Score', 'Category'}, {'Greater than','Less than','Equals'}, 'char'},...
    'ColumnWidth',{130,130,130,90},...
    'Data',[{'Reject calls with', 'Score', 'Less than', []}; cell(7,4)],...
    'ColumnEditable', true,...
    'RowName',[],...
    'ColumnName',[],...
    'Position', [.02 .7 .96 .25]);

listboxText = uicontrol('Parent',d,...
    'Units','normalized',...
    'Style','text',...
    'Position', [.02 .63 .96 .05],...
    'String','Select file(s) to process');

listbox = uicontrol('Parent',d,...
    'Units','normalized',...
    'Style','listbox',...
    'Position',[.02 .14 .96 .517],...
    'Max',inf,...
    'String', handles.detectionfilesnames,...
    'Value', currentfile);

btnProceed = uicontrol('Parent',d,...
    'Units','normalized',...
    'Position',[.2 .0167 .2 .083],...
    'String','Process Files',...
    'Callback',@(popup,event) set(d,'UserData',0));

btnCancel = uicontrol('Parent',d,...
    'Units','normalized',...
    'Position',[.6 .0167 .2 .083],...
    'String','Close',...
    'Callback',@(popup,event) set(d,'UserData',1));
d.Visible = 'on';

waitfor(d,'UserData')
selections  = listbox.Value;
rules = uit.Data;
cancelled = d.UserData;
delete(d)
clear d

if cancelled; return; end

% Select rules were accept or reject is chosen
rules = rules(~cellfun(@isempty,rules(:,1)),:);
rules(:,1) = num2cell(contains(rules(:,1),'Accept'));

%% Loop
h = waitbar(0,'Initializing');
for currentfile = selections % Do this for each file
    [Calls,  audiodata, loaded_ClusteringData] = loadCallfile(fullfile(handles.detectionfiles(currentfile).folder, handles.detectionfiles(currentfile).name),handles);

    reject = false(height(Calls),1);
    accept = false(height(Calls),1);
    audioReader = squeakData([]);
    audioReader.audiodata = audiodata;
        
    for i = 1:height(Calls)
        waitbar(i ./ height(Calls), h, ['Processing file ' num2str(find(selections == currentfile)) ' of ' num2str(length(selections))]);
        
        [I,wind,noverlap,nfft,rate,box,~,~,~,~,pow] = CreateFocusSpectrogram(Calls(i,:), handles, true, [], audioReader);
        stats = CalculateStats(I,wind,noverlap,nfft,rate,box,handles.data.settings.EntropyThreshold,handles.data.settings.AmplitudeThreshold);

        % For each rule, test the appropriate value, and accept or reject.
        for rule = rules'
            switch rule{2}
                case 'Tonality'
                    testValue = stats.SignalToNoise;
                    if ischar(rule{4}); rule{4}=str2num(rule{4}); end
                case 'Frequency (kHz)'
                    testValue = stats.PrincipalFreq;
                    if ischar(rule{4}); rule{4}=str2num(rule{4}); end
                case 'Power (dB/Hz)'
                    testValue = stats.MeanPower;
                    if ischar(rule{4}); rule{4}=str2num(rule{4}); end
                case 'Duration (s)'
                    testValue = stats.DeltaTime;
                    if ischar(rule{4}); rule{4}=str2num(rule{4}); end
                case 'Score'
                    testValue = Calls.Score(i);
                    if ischar(rule{4}); rule{4}=str2num(rule{4}); end
                case 'Category'
                    testValue = Calls.Type(i);
                    if ischar(rule{4}); rule{4}=categorical(rule(4)); end
            end

            change = false;
            switch rule{3}
                case 'Greater than'
                    change = testValue >= rule{4};
                case 'Less than'
                    change = testValue <= rule{4};
                case 'Equals'
                    change = testValue == rule{4};
            end

            if change
                if rule{1}
                    accept(i) = true;
                else
                    reject(i) = true;
                end
            end

        end
    end


    Calls.Accept(reject) = false;
    Calls.Accept(accept) = true;
    save(fullfile(handles.detectionfiles(currentfile).folder,handles.detectionfiles(currentfile).name),'Calls','audiodata', '-v7.3');

end
close(h);

%update the display
update_folders(hObject, eventdata, handles);
if isfield(handles,'current_detection_file')
    loadcalls_Callback(hObject, eventdata, handles, true)
end
