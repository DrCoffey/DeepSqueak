function export_Calls(loop_function, file_postfix, hObject, eventdata, handles)
% hObject    handle to excel (see GCBO)
% This function xports selected call files to excel sheets with stats for each call

%% Select Files
% Select the files
[fname, fpath] = uigetfile([char(handles.data.settings.detectionfolder) '/*.mat'],'Select Files to Export:','MultiSelect', 'on');
if isnumeric(fname); return; end
fname = cellstr(fname);

% Do we include calls that were rejected?
includereject = questdlg('Include Rejected Calls?','Export','Yes','No','No');
if isempty(includereject); return; end
includereject = strcmp(includereject,'Yes');
merge_exported = 'No';
if length(fname) > 1
   merge_exported = questdlg('Merge into a single file?','Merge','Yes', 'No', 'No'); 
end


% Specifiy the output folder
PathName = uigetdir(handles.data.settings.detectionfolder,'Select Output Folder');
if isnumeric(PathName); return; end

t_merged = [];

%% Make the output tables
hc = waitbar(0,'Initializing');
for j = 1:length(fname) % Do this for each file
    currentfile = fullfile(fpath,fname{j});
    audioReader = squeakData([]);
    [Calls, audioReader.audiodata] = loadCallfile(currentfile,handles);
    
    % Name the output file. If the file already exists, delete it so that
    % writetable overwrites the data instead of appending it to the table.    
    [~,FileName,~] = fileparts(fname{j});


    t = loop_function(Calls,hc,includereject,['Exporting calls from file ' num2str(j) ' of ' num2str(length(fname))],handles,currentfile, audioReader);


    outputName = fullfile(PathName,[FileName file_postfix]);
    if exist(outputName, 'file')==2
        delete(outputName);
    end
    if strcmp(merge_exported,'Yes')
        %Skip the header of all files except the first
        if ~isempty(t_merged)
           t = t(2:end,:); 
        end
        t_merged = [t_merged; t];
    else
        writetable(t,outputName,'WriteVariableNames',0');
    end
end

if strcmp(merge_exported,'Yes')
    FileName = [ datestr(datetime('now'), 'mm_dd_yy-HH_MM_SS') '_merged'];
    outputName = fullfile(PathName,[FileName file_postfix]);

    writetable(t_merged,outputName,'WriteVariableNames',0'); 
end


close(hc);
guidata(hObject, handles);
