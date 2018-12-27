function excel_Callback(hObject, eventdata, handles)
% hObject    handle to excel (see GCBO)
% This function xports selected call files to excel sheets with stats for each call

%% Select Files
% Select the files
[fname, fpath] = uigetfile([char(handles.settings.detectionfolder) '/*.mat'],'Select Files to Export:','MultiSelect', 'on');
if isnumeric(fname); return; end
fname = cellstr(fname);

% Do we include calls that were rejected?
includereject = questdlg('Include Rejected Calls?','Export','Yes','No','No');
if isempty(includereject); return; end
includereject = strcmp(includereject,'Yes');

% Specifiy the output folder
PathName = uigetdir(handles.settings.detectionfolder,'Select Output Folder');
if isnumeric(PathName); return; end

%% Make the output tables
hc = waitbar(0,'Initializing');
for j = 1:length(fname) % Do this for each file
    currentfile = fullfile(fpath,fname{j});
    tmp=load(currentfile);
    
    exceltable = [{'ID'} {'Label'} {'Accepted'} {'Score'}  {'Begin Time (s)'} {'End Time (s)'} {'Call Length (s)'} {'Principal Frequency (KHz)'} {'Low Freq (KHz)'} {'High Freq (KHz)'} {'Delta Freq (KHz)'} {'Frequency Standard Deviation (KHz)'} {'Slope (KHz / s)'} {'Sinuosity'} {'Max Power'} {'Tonality'}];
    for i = 1:length(tmp.Calls) % Do this for each call
        waitbar(i/length(tmp.Calls),hc,['Calculating call statistics for file ' num2str(j) ' of ' num2str(length(fname))]);
        
        if includereject || tmp.Calls(i).Accept==1;
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
    t = cell2table(exceltable);
    
    % Name the output file. If the file already exists, delete it so that
    % writetable overwrites the data instead of appending it to the table.
    [~,FileName]=fileparts(currentfile);
    outputName = fullfile(PathName,[FileName '_Stats.xlsx']);
    if exist(outputName, 'file')==2
        delete(outputName);
    end
    
    writetable(t,outputName,'WriteVariableNames',0');
    
end
close(hc);
guidata(hObject, handles);
