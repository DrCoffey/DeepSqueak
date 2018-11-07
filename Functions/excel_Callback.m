function excel_Callback(hObject, eventdata, handles)
% hObject    handle to excel (see GCBO)
% This function xports selected call files to excel sheets with stats for each call

%% Select Files
selections = listdlg('PromptString','Select Files for Export:','ListSize',[500 300],'ListString',handles.detectionfilesnames);
if isempty(selections); return; end

includereject = questdlg('Include Rejected Calls?','Export','Yes','No','No');

PathName = uigetdir(handles.settings.detectionfolder,'Select Output Folder');
if isnumeric(PathName); return; end


hc = waitbar(0,'Initializing');
for j = 1:length(selections) % Do this for each file
    currentfile = selections(j);
    tmp=load([handles.detectionfiles(currentfile).folder '/' handles.detectionfiles(currentfile).name]);%get currently selected option from menu
    current_detection_file = handles.detectionfiles(currentfile).name;
    excelname=[strtok(current_detection_file,'.') '_Stats.xlsx'];
    FileName = excelname;
    
    exceltable = [{'ID'} {'Label'} {'Accepted'} {'Score'}  {'Begin Time (s)'} {'End Time (s)'} {'Call Length (s)'} {'Principal Frequency (KHz)'} {'Low Freq (KHz)'} {'High Freq (KHz)'} {'Delta Freq (KHz)'} {'Frequency Standard Deviation (KHz)'} {'Slope (KHz / s)'} {'Sinuosity'} {'Max Power'} {'Tonality'}];
    for i = 1:length(tmp.Calls) % Do this for each call
        waitbar(i/length(tmp.Calls),hc,['Calculating call statistics for file ' num2str(j) ' of ' num2str(length(selections))]);
        
        if (tmp.Calls(i).Accept==1) | strcmp(includereject,'Yes');
            

            % Get spectrogram data
            [I,windowsize,noverlap,nfft,rate,box] = CreateSpectrogram(tmp.Calls(i));
            
            
            % Calculate statistics
            stats = CalculateStats(I,windowsize,noverlap,nfft,rate,box,handles.settings.EntropyThreshold,handles.settings.AmplitudeThreshold);
            
            
            ID = i;
            Label = tmp.Calls(i).Type;
            Score = tmp.Calls(i).Score;
            accepted = tmp.Calls(i).Accept;
            exceltable = [exceltable; {ID} {Label} {accepted} {Score} {stats.BeginTime} {stats.EndTime} {stats.DeltaTime} {stats.PrincipalFreq} {stats.LowFreq} {stats.HighFreq} {stats.DeltaFreq} {stats.stdev} {stats.Slope} {stats.Sinuosity} {stats.MaxPower} {stats.SignalToNoise}];
        end
        
    end
    % xlswrite([PathName '/' FileName],exceltable)
    t = cell2table(exceltable);
    clear exceltable
    
    if exist([PathName '/' FileName], 'file')==2
        delete([PathName '/' FileName]);
    end

    writetable(t,[PathName '/' FileName],'WriteVariableNames',0');
    
end
close(hc);
guidata(hObject, handles);
