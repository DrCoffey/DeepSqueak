function Batch_Reject_by_Threshold_Callback(hObject, eventdata, handles)
% hObject    handle to Batch_Reject_by_Threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Set the current call in the settings figure


if isfield(handles,'current_file_id')
    currentfile = handles.current_file_id;
else
    currentfile = 1;
end

%% Selection GUI
d = dialog('Position',[200,200,500,600]);
d.UserData = 2;

uitText = uicontrol('Parent',d,...
    'Style','text',...
    'Position', [10 570 480 20],...
    'String',{'Set rules for accepting/rejecting calls'});

uit = uitable('Parent',d,...
    'ColumnFormat',{
    {' ','Reject calls with','Accept calls with'}, {'Tonality','Frequency (kHz)','Power (dB/Hz)','Duration (s)', 'Score', 'Category'}, {'Greater than','Less then','Equals'}, 'char'},...
    'ColumnWidth',{130,130,130,70},...
    'Data',[{'Reject calls with', 'Score', 'Less than', 0.5}; cell(6,4)],...
    'ColumnEditable', true,...
    'RowName',[],...
    'ColumnName',[],...
    'Position', [10 420 480 150]);

listboxText = uicontrol('Parent',d,...
    'Style','text',...
    'Position', [10 380 480 30],...
    'String','Select file(s) to process');

listbox = uicontrol('Parent',d,...
    'Style','listbox',...
    'Position',[10 70 480 310],...
    'Max',inf,...
    'String', handles.detectionfilesnames,...
    'Value', currentfile);

btnProceed = uicontrol('Parent',d,...
    'Position',[100 10 100 50],...
    'String','Process Files',...
    'Callback',@(popup,event) set(d,'UserData',0));

btnCancel = uicontrol('Parent',d,...
    'Position',[300 10 100 50],...
    'String','Close',...
    'Callback',@(popup,event) set(d,'UserData',1));

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
    Calls = loadCallfile(fullfile(handles.detectionfiles(currentfile).folder, handles.detectionfiles(currentfile).name));

    
    reject = false(height(Calls),1);
    accept = false(height(Calls),1);
    
    for i = 1:height(Calls)
        waitbar(i ./ height(Calls), h, ['Processing file ' num2str(find(selections == currentfile)) ' of ' num2str(length(selections))]);

        [I,windowsize,noverlap,nfft,rate,box] = CreateSpectrogram(Calls(i, :));
        stats = CalculateStats(I,windowsize,noverlap,nfft,rate,box,handles.data.settings.EntropyThreshold,handles.data.settings.AmplitudeThreshold);
        
        % For each rule, test the appropriate value, and accept or reject.
        for rule = rules'
            switch rule{2}
                case 'Tonality'
                    testValue = stats.SignalToNoise;
                case 'Frequency (kHz)'
                    testValue = stats.PrincipalFreq;
                case 'Power (dB/Hz)'
                    testValue = stats.MaxPower;
                case 'Duration (s)'
                    testValue = stats.DeltaTime;
                case 'Score'
                    testValue = Calls.Score(i);
                case 'Category'
                    testValue = Calls.Type(i);
            end
            
            change = false;
            switch rule{3}
                case 'Greater than'
                    change = testValue >= rule{4};
                case 'Less than'
                    change = testValue <= rule{4};
                case 'Equals'
                    change = testValue == num2str(rule{4});
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

    save(fullfile(handles.detectionfiles(currentfile).folder,handles.detectionfiles(currentfile).name),'Calls','-v7.3');
    
end
close(h);


%update the display
if isfield(handles,'current_detection_file') && any(ismember(handles.detectionfilesnames(selections),handles.current_detection_file))
    loadcalls_Callback(hObject, eventdata, handles, handles.current_file_id)
end

