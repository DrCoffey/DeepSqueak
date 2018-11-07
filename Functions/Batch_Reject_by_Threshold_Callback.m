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

% Get the settings
[...
    power_low_checkbox,...
    power_low,...
    power_max_checkbox,...
    power_max,...
    score_low_checkbox,...
    score_low,...
    score_max_checkbox,...
    score_max,...
    tonality_low_checkbox,...
    tonality_low,...
    tonality_max_checkbox,...
    tonality_max,...
    selections,...
    cancelled] = thresholds(handles.detectionfilesnames,currentfile);

if cancelled; return; end;

h = waitbar(0,'Initializing');
for currentfile =selections % Do this for each file
    % Load the file, skip files if variable: 'Calls' doesn't exist
    lastwarn('');
    load([handles.detectionfiles(currentfile).folder '/' handles.detectionfiles(currentfile).name],'Calls');
    if ~isempty(lastwarn)
        disp([handles.detectionfiles(currentfile).name ' is not a Call file, skipping...'])
        continue
    end
    
    % Reject calls where reject == true, accept calls where accept == true
    
    % Get tonality
    if tonality_low_checkbox && tonality_low_checkbox
        tonality = [];
        for i = Calls'
            [I,windowsize,noverlap,nfft,rate,box,s,fr,ti,audio,AudioRange] = CreateSpectrogram(i);
            stats = CalculateStats(I,windowsize,noverlap,nfft,rate,box,handles.settings.EntropyThreshold,handles.settings.AmplitudeThreshold);
            tonality = [tonality; stats.SignalToNoise];
        end
    end
    
    Calls = struct2table(Calls);
    reject = false(height(Calls),1);
    accept = false(height(Calls),1);
    
    reject = reject | (Calls.Power < power_low) & power_low_checkbox;
    accept = accept | (Calls.Power > power_max) & power_max_checkbox;
    
    reject = reject | (Calls.Score < score_low) & score_low_checkbox;
    accept = accept | (Calls.Score > score_max) & score_max_checkbox;
    
    if tonality_low_checkbox && tonality_low_checkbox
        reject = reject | (tonality < tonality_low) & tonality_low_checkbox;
        accept = accept | (tonality > tonality_max) & tonality_max_checkbox;
    end
    
    Calls.Accept(accept) = true;
    Calls.Accept(reject) = false;
    
    Calls = table2struct(Calls);
    save([handles.detectionfiles(currentfile).folder '/' handles.detectionfiles(currentfile).name],'Calls','-v7.3');
    
    %update the display
    if isfield(handles,'current_file_id') && currentfile == handles.current_file_id
        handles.calls = Calls;
    end
    waitbar(find(selections == currentfile) ./ length(selections), h, ['Processing file ' num2str(find(selections == currentfile)) ' of ' num2str(length(selections))]);
    
end

close(h);
update_fig(hObject, eventdata, handles);
guidata(hObject, handles);


