%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DeepSqueak 1.0                                                          %
% Copyright (c) 2018 Kevin Coffey & Russell Marx                          %
%                                                                         %
% Licensed under the Apache License, Version 2.0 (the "License");         %
% you may not use this file except in compliance with the License.        %
% You may obtain a copy of the License at:                                %
%                                                                         %
% http://www.apache.org/licenses/LICENSE-2.0                              %
%                                                                         %
% Unless required by applicable law or agreed to in writing, software     %
% distributed under the License is distributed on an "AS IS" BASIS,       %
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = DeepSqueak(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @DeepSqueak_OpeningFcn, ...
    'gui_OutputFcn',  @DeepSqueak_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end
if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

% --- Executes just before DeepSqueak is made visible.
function DeepSqueak_OpeningFcn(hObject, eventdata, handles, varargin)
% Very Important Logo (Mouse from hjw)
disp '                                                                                                                                 .---.'
disp '                                                                                                                                /  .  \  '
disp '                                                                                                       ) _     _               |\_/|   |'
disp '                                                                                                      ( (^)-~-(^)              |   |   |'
disp '    ._______________________________________________________________________________________________,-.\_( 0 0 )__,-.__________|___|__,|'
disp '   /  .-.                                                                                           ''M''   \   /   ''M''                  |'
disp '  |  /   \                                                                                                 >o<                         |'
disp '  | |\_.  |                                                                                                                            |  '
disp '  |\|  | /|        ,---,                                    .--.--.                                                         ,-.        |  '
disp '  | `---'' |      .''  .'' `\                      ,-.----.   /  /    ''.   ,----.                                          ,--/ /|        |'
disp '  |       |    ,---.''     \                     \    /  \ |  :  /`. /  /   /  \-.         ,--,                        ,--. :/ |        |'
disp '  |       |    |   |  .`\  |                    |   :    |;  |  |--`  |   :    :|       ,''_ /|                        :  : '' /         |'
disp '  |       |    :   : |  ''  |   ,---.     ,---.  |   | .\ :|  :  ;_    |   | .\  .  .--. |  | :    ,---.     ,--.--.   |  ''  /          |'
disp '  |       |    |   '' ''  ;  :  /     \   /     \ .   : |: | \  \    `. .   ; |:  |,''_ /| :  . |   /     \   /       \  ''  |  :          |'
disp '  |       |    ''   | ;  .  | /    /  | /    /  ||   |  \ :  `----.   \''   .  \  ||  '' | |  . .  /    /  | .--.  .-. | |  |   \         | '
disp '  |       |    |   | :  |  ''.    '' / |.    '' / ||   : .  |  __ \  \  | \   `.   ||  | '' |  | | .    '' / |  \__\/: . . ''  : |. \        |'
disp '  |       |    ''   : | /  ; ''   ;   /|''   ;   /|:     |`-'' /  /`--''  /  `--''""| |:  | : ;  ; | ''   ;   /|  ," .--.; | |  | '' \ \       |'
disp '  |       |    |   | ''` ,/  ''   |  / |''   |  / |:   : :   ''--''.     /     |   | |''  :  `--''   \''   |  / | /  /  ,.  | ''  : |--''        |'
disp '  |       |    ;   :  .''    |   :    ||   :    ||   | :     `--''---''      |   | ::  ,      .-./|   :    |;  :   .''   \;  |,''           |'
disp '  |       |    |   ,.''       \   \  /  \   \  / `---''.|                   `---''.| `--`----''     \   \  / |  ,     .-./''--''             |'
disp '  |       |    ''---''          `----''    `----''    `---`                     `---`                `----''   `--`---''                     |'
disp '  |       |                                                                                                                            |'
disp '  \       |____________________________________________________________________________________________________________________________/'
disp '   \     /'
disp '    `---'''
disp '  '
disp '  '
disp '  '

% Set Handles
hFig = hObject;
handles.hFig=hFig;
% Create a class to hold the data
squeakfolder = fileparts(mfilename('fullpath'));

% Add to MATLAB path and check for toolboxes
if ~isdeployed
    % Add DeepSqueak to the path
    addpath(squeakfolder);
    addpath(genpath(fullfile(squeakfolder, 'Functions')));
    savepath
    
    %% Display error message if running on matlab before 2017b or toolboxes not found
    if verLessThan('matlab','9.3')
        errordlg(['Warning, DeepSqueak requires MATLAB 2017b or later. It looks like you are use MATLAB ' version('-release')],'upgrade your matlab')
    end
    
    try
        verLessThan('nnet','1');
    catch
        warning('Deep Learning Toolbox not found')
    end
    
    try
        verLessThan('curvefit','1');
    catch
        warning('Curve Fitting Toolbox not found')
    end
    
    try
        verLessThan('vision','1');
    catch
        warning('Computer Vision System Toolbox not found')
    end
    
    try
        verLessThan('images','1');
    catch
        warning('Image Processing Toolbox not found')
    end
    
    try
        verLessThan('distcomp','1');
    catch
        warning('Parallel Computing Toolbox not found')
    end
end

handles.data = squeakData(squeakfolder);

set ( hFig, 'Color', [.1 .1 .1] );
handles.output = hObject;
cd(handles.data.squeakfolder);

% Display version
try
    fid = fopen(fullfile(handles.data.squeakfolder,'CHANGELOG.md'));
    txt = fscanf(fid,'%c');
    txt = strsplit(txt);
    changes = find(contains(txt,'##'),1); % Get the values after the bold heading
    handles.DSVersion = txt{changes+1};
    disp(['DeepSqueak version ' handles.DSVersion]);
    fclose(fid);
catch
    handles.DSVersion = '?';
end
% Check if a new version is avaliable by comparing changelog to whats online
try
    WebChangelogTxt= webread('https://raw.githubusercontent.com/DrCoffey/DeepSqueak/master/CHANGELOG.md');
    WebChangelog = strsplit(WebChangelogTxt);
    changes = find(contains(WebChangelog,'##')); % Get the values after the bold heading
    WebVersion = WebChangelog{changes+1};
    if ~strcmp(WebVersion,handles.DSVersion)
        disp ' '
        disp 'A new version of DeepSqueak is avaliable.'
        disp('<a href="https://github.com/DrCoffey/DeepSqueak">Download link</a>')
        changes = strfind(WebChangelogTxt,'##');
        disp(WebChangelogTxt(changes(1)+3:changes(2)-1))
    end
end

handles.spect = imagesc(1,1,1,'Parent', handles.axes1);

if ~(exist(fullfile(handles.data.squeakfolder,'Background.png'), 'file')==2)
    disp('Background image not found')
    background = zeros(280);
    fonts = listTrueTypeFonts;
    background = insertText(background,[10 8],'DeepSqueak','Font',char(datasample(fonts,1)),'FontSize',30);
    background = insertText(background,[10 80],'DeepSqueak','Font',char(datasample(fonts,1)),'FontSize',30);
    background = insertText(background,[10 150],'DeepSqueak','Font',char(datasample(fonts,1)),'FontSize',30);
    background = insertText(background,[10 220],'DeepSqueak','Font',char(datasample(fonts,1)),'FontSize',30);
    handles.background = background;
else
    handles.background=imread('Background.png');
end
if ~(exist(fullfile(handles.data.squeakfolder,'DeepSqueak.fig'), 'file')==2)
    errordlg('"DeepSqueak.fig" not found');
end

% Cool Background Image
imshow(handles.background, 'Parent', handles.axes1);
set(handles.axes1,'XTick',[]);
set(handles.axes1,'YTick',[]);
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);  % Get newest version of handles


set(handles.TonalitySlider,'Value',handles.data.settings.EntropyThreshold);
guidata(hObject, handles);

% Make the other figures black
set(handles.axes4,'Color',[0 0 0],'YColor',[1 1 1],'XColor',[1 1 1],'Box','off','Clim',[0,1]);
set(handles.axes4,'XTickLabel',[]);
set(handles.axes4,'XTick',[]);
set(handles.axes4,'YTick',[]);

set(handles.axes7,'Color',[0 0 0],'YColor',[1 1 1],'XColor',[1 1 1],'Box','off','Clim',[0,1]);
set(handles.axes7,'XTickLabel',[]);
set(handles.axes7,'XTick',[]);
set(handles.axes7,'YTick',[]);

set(handles.axes3,'Color',[0 0 0],'YColor',[1 1 1],'XColor',[1 1 1],'Box','off','Clim',[0,1]);
set(handles.axes3,'XTickLabel',[]);
set(handles.axes3,'XTick',[]);
set(handles.axes3,'YTick',[]);




function varargout = DeepSqueak_OutputFcn(hObject, eventdata, handles)

varargout{1} = handles.output;

% --- Executes on button press in PlayCall.
function PlayCall_Callback(hObject, eventdata, handles)
% Play the sound within the boxs
audio =  handles.data.calls.Audio{handles.data.currentcall};
if ~isfloat(audio)
    audio = double(audio) / (double(intmax(class(audio)))+1);
elseif ~isa(audio,'double')
    audio = double(audio);
end

playbackRate = handles.data.calls.Rate(handles.data.currentcall) * handles.data.settings.playback_rate; % set playback rate

% Bandpass Filter
% audio = bandpass(audio,[handles.data.calls.RelBox(handles.data.currentcall, 2), handles.data.calls.RelBox(handles.data.currentcall, 2) + handles.data.calls.RelBox(handles.data.currentcall, 4)] * 1000,handles.data.calls.Rate(handles.data.currentcall));
paddedsound = [zeros(3125,1); audio; zeros(3125,1)];
audiostart = handles.data.calls.RelBox(handles.data.currentcall, 1) * handles.data.calls.Rate(handles.data.currentcall);
audiolength = handles.data.calls.RelBox(handles.data.currentcall, 3) * handles.data.calls.Rate(handles.data.currentcall);
soundsc(paddedsound(round(audiostart:audiostart+audiolength + 6249)),playbackRate);
guidata(hObject, handles);

% --- Executes on button press in NextCall.
function NextCall_Callback(hObject, eventdata, handles)
if handles.data.currentcall < height(handles.data.calls) % If not the last call
    handles.data.currentcall=handles.data.currentcall+1;
    update_fig(hObject, eventdata, handles);
end
% guidata(hObject, handles);

% --- Executes on button press in PreviousCall.
function PreviousCall_Callback(hObject, eventdata, handles)
if handles.data.currentcall>1 % If not the first call
    handles.data.currentcall=handles.data.currentcall-1;
    update_fig(hObject, eventdata, handles);
end

% --- Executes on selection change in Networks Folder Pop up.
function neuralnetworkspopup_Callback(hObject, eventdata, handles)
guidata(hObject, handles);

% --- Executes during Networks Folder Pop up.
function neuralnetworkspopup_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in Audio Folder Pop up.
function AudioFilespopup_Callback(hObject, eventdata, handles)
guidata(hObject, handles);

% --- Executes during Audio Folder Pop up.
function AudioFilespopup_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in Detection Folder Pop up.
function popupmenuDetectionFiles_Callback(hObject, eventdata, handles)
guidata(hObject, handles);

% --- Executes during Detection Folder Pop up.
function popupmenuDetectionFiles_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in AcceptCall.
function AcceptCall_Callback(hObject, eventdata, handles)
handles.data.calls.Accept(handles.data.currentcall) = 1;
update_fig(hObject, eventdata, handles);
guidata(hObject, handles);

% --- Executes on button press in RejectCall.
function RejectCall_Callback(hObject, eventdata, handles)
handles.data.calls.Accept(handles.data.currentcall) = 0;
update_fig(hObject, eventdata, handles);
guidata(hObject, handles);

% --- Executes during MAIN AXES CREATION
function axes1_CreateFcn(hObject, eventdata, handles)

% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
handles.data.currentcall = ceil(get(hObject,'Value')*height(handles.data.calls));
if handles.data.currentcall < 1
    handles.data.currentcall = 1;
end
update_fig(hObject, eventdata, handles);

% --- Executes during slider creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function score_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function score_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function status_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function status_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Probably an unlabeled menu?
function Untitled_2_Callback(hObject, eventdata, handles)

% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
switch eventdata.Character
    case 'p'
        PlayCall_Callback(hObject, eventdata, handles)
    case {'e', char(29)} % char(29) is right arrow key
        NextCall_Callback(hObject, eventdata, handles)
    case {'q', char(28)} % char(28) is left arrow key
        PreviousCall_Callback(hObject, eventdata, handles)
    case 'a'
        AcceptCall_Callback(hObject, eventdata, handles)
    case 'r'
        RejectCall_Callback(hObject, eventdata, handles)
    case 'd'
        rectangle_Callback(hObject, eventdata, handles)
    case handles.data.labelShortcuts
        %% Update the call labels
        % Index of the shortcut
        idx = contains(handles.data.labelShortcuts, eventdata.Character);
        handles.data.calls.Type(handles.data.currentcall) = categorical(handles.data.settings.labels(idx));
        update_fig(hObject, eventdata, handles);
end
% drawnow

function figure1_KeyPressFcn(hObject, eventdata, handles)

% --- Executes on selection change in popupmenuColorMap.
function popupmenuColorMap_Callback(hObject, eventdata, handles)
handles.data.cmapName=get(hObject,'String');
handles.data.cmapName=handles.data.cmapName(get(hObject,'Value'));
switch handles.data.cmapName{1,1}
    case 'magma'
        handles.data.cmap=magma;
    case 'inferno'
        handles.data.cmap=inferno;
    case 'viridis'
        handles.data.cmap=viridis;
    case 'plasma'
        handles.data.cmap=plasma;
    case 'hot'
        handles.data.cmap=hot;
    case 'cubehelix'
        handles.data.cmap=cubehelix;
    case 'parula'
        handles.data.cmap=parula;
    case 'jet'
        handles.data.cmap=jet;
    case 'hsv'
        handles.data.cmap=hsv;
    case 'cool'
        handles.data.cmap=cool;
    case 'spring'
        handles.data.cmap=spring;
    case 'summer'
        handles.data.cmap=summer;
    case 'autumn'
        handles.data.cmap=autumn;
    case 'winter'
        handles.data.cmap=winter;
    case 'gray'
        handles.data.cmap=gray;
    case 'bone'
        handles.data.cmap=bone;
    case 'copper'
        handles.data.cmap=copper;
    case 'pink'
        handles.data.cmap=pink;
end
colormap(handles.axes1,handles.data.cmap);
colormap(handles.axes4,handles.data.cmap);

% --- Executes during object creation, after setting all properties.
function popupmenuColorMap_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function freq_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in rectangle.
function rectangle_Callback(hObject, eventdata, handles)
% Re-draw the box
fcn = makeConstrainToRectFcn('imrect',[handles.spect.XData(1),handles.spect.XData(end)],[handles.spect.YData(1),handles.spect.YData(end)]); %constrain to edges of window
newbox=imrect(handles.axes1,'PositionConstraintFcn',fcn);
handles.pos=getPosition(newbox);
difference = handles.pos - handles.data.calls{handles.data.currentcall, 'RelBox'};
handles.data.calls{handles.data.currentcall, 'RelBox'} = difference + handles.data.calls{handles.data.currentcall, 'RelBox'};
handles.data.calls{handles.data.currentcall, 'Box'} = difference + handles.data.calls{handles.data.currentcall, 'Box'};
delete(newbox);
update_fig(hObject, eventdata, handles);

% --------------------------------------------------------------------
function select_audio_Callback(hObject, eventdata, handles)
% Find audio in folder
path=uigetdir(handles.data.settings.audiofolder,'Select Audio File Folder');
if isnumeric(path);return;end
handles.data.settings.audiofolder = path;
handles.data.saveSettings();
update_folders(hObject, eventdata, handles);

% --------------------------------------------------------------------
function load_networks_Callback(hObject, eventdata, handles)
% Find networks
path=uigetdir(handles.data.settings.networkfolder,'Select Network Folder');
if isnumeric(path);return;end
handles.data.settings.networkfolder = path;
handles.data.saveSettings();
update_folders(hObject, eventdata, handles);

function load_detectionFolder_Callback(hObject, eventdata, handles)
% Find audio in folder
path=uigetdir(handles.data.settings.detectionfolder,'Select Detection File Folder');
if isnumeric(path);return;end
handles.data.settings.detectionfolder = path;
handles.data.saveSettings();
update_folders(hObject, eventdata, handles);

% --------------------------------------------------------------------
function folders_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function export_raven_Callback(hObject, eventdata, handles)
% Export current file as a txt file for viewing in Raven
% http://www.birds.cornell.edu/brp/raven/RavenOverview.html
raventable = [{'Selection'} {'View'} {'Channel'} {'Begin Time (s)'} {'End Time (s)'} {'Low Freq (Hz)'} {'High Freq (Hz)'} {'Delta Time (s)'} {'Delta Freq (Hz)'} {'Avg Power Density (dB FS)'} {'Annotation'}];
View = 'Spectrogram 1';
Channel = 1;
for i = 1:height(handles.data.calls)
    if handles.data.calls.Accept(i)
        Selection = i;
        BeginTime = handles.data.calls.Box(i, 1);
        EndTime = sum(handles.data.calls.Box(i ,[1, 3]));
        LowFreq = handles.data.calls.Box(i, 2) * 1000;
        HighFreq = sum(handles.data.calls.Box(i, [2, 4])) * 1000;
        DeltaTime = EndTime - BeginTime;
        DeltaFreq = HighFreq - LowFreq;
        AvgPwr = 1;
        Annotation = handles.data.calls.Accept(i);
        raventable = [raventable; {Selection} {View} {Channel} {BeginTime} {EndTime} {LowFreq} {HighFreq} {DeltaTime} {DeltaFreq} {AvgPwr} {Annotation}];
    end
end
a  = cell2table(raventable);
handles.current_file_id = get(handles.popupmenuDetectionFiles,'Value');
current_detection_file = handles.detectionfiles(handles.current_file_id).name;
ravenname=[strtok(current_detection_file,'.') '_Raven.txt'];
[FileName,PathName] = uiputfile(ravenname,'Save Raven Truth Table (.txt)');
writetable(a,[PathName FileName],'delimiter','\t','WriteVariableNames',false);
guidata(hObject, handles);

% --------------------------------------------------------------------
function export_Callback(hObject, eventdata, handles)

function training_Callback(hObject, eventdata, handles)

function SortCalls(hObject, eventdata, handles, type)
% Sort current file by score
h = waitbar(0,'Sorting...');
switch type
    case 'score'
        [~,idx] = sort(handles.data.calls.Score);
    case 'time'
        [~,idx] = sortrows(handles.data.calls.Box, 1);
    case 'duration'
        [~,idx] = sortrows(handles.data.calls.Box, 4);
    case 'frequency'
        [~,idx] = sort(sum(handles.data.calls.Box(:, [2, 2, 4]), 2));
end
handles.data.calls = handles.data.calls(idx, :);
handles.data.currentcall=1;

update_fig(hObject, eventdata, handles);
close(h);
guidata(hObject, handles);

% --------------------------------------------------------------------
function customlabels_Callback(hObject, eventdata, handles)
% Define call categories
prompt = {
    'Label 1  --- Key 1'
    'Label 2  --- Key 2'
    'Label 3  --- Key 3'
    'Label 4  --- Key 4'
    'Label 5  --- Key 5'
    'Label 6  --- Key 6'
    'Label 7  --- Key 7'
    'Label 8  --- Key 8'
    'Label 9  --- Key 9'
    'Label 10  --- Key 0'
    'Label 11  --- Key -'
    'Label 12  --- Key ='
    };
dlg_title = 'Set Custom Label Names';
num_lines=[1,60]; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
old_labels = handles.data.settings.labels;
new_labels = inputdlg(prompt,dlg_title,num_lines,old_labels,options);
if ~isempty(new_labels)
    handles.data.settings.labels = new_labels;
    handles.data.saveSettings();
    update_folders(hObject, eventdata, handles);
end
guidata(hObject, handles);

% --------------------------------------------------------------------
function Change_Playback_Rate_Callback(hObject, eventdata, handles)
prompt = {'Playback Rate: (default = 0.0.5)'};
dlg_title = 'Change Playback Rate';
num_lines=1; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
defaultans = {num2str(handles.data.settings.playback_rate)};
rate = inputdlg(prompt,dlg_title,num_lines,defaultans);
if isempty(rate); return; end

[newrate,~,errmsg] = sscanf(rate{1},'%f',1);
disp(errmsg);
if ~isempty(newrate)
    handles.data.settings.playback_rate = newrate;
    handles.data.saveSettings();
    update_folders(hObject, eventdata, handles);
end
guidata(hObject, handles);

% --------------------------------------------------------------------
function Change_Display_Range_Callback(hObject, eventdata, handles)
% Change the x and y axis in the spectrogram viewer
prompt = {'Low Frequency (kHz):', 'High Frequency (kHz):', 'Fixed Display Range (s) (Set to 0 to autoscale)'};
dlg_title = 'New Display Range:';
num_lines=[1 80]; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
defaultans = {num2str(handles.data.settings.LowFreq),num2str(handles.data.settings.HighFreq),num2str(handles.data.settings.DisplayTimePadding)};
dispRange = inputdlg(prompt,dlg_title,num_lines,defaultans);
if isempty(dispRange); return; end

[LowFreq,~,errmsg] = sscanf(dispRange{1},'%f',1);
disp(errmsg);
[HighFreq,~,errmsg] = sscanf(dispRange{2},'%f',1);
disp(errmsg);
[DisplayTimePadding,~,errmsg] = sscanf(dispRange{3},'%f',1);
disp(errmsg);
if ~isempty(LowFreq) && ~isempty(HighFreq) && ~isempty(DisplayTimePadding)
    if HighFreq > LowFreq
        handles.data.settings.LowFreq = LowFreq;
        handles.data.settings.HighFreq = HighFreq;
        handles.data.settings.DisplayTimePadding = DisplayTimePadding;
        handles.data.saveSettings();
        update_folders(hObject, eventdata, handles);
        update_fig(hObject, eventdata, handles);
        
    else
        errordlg('High cutoff must be greater than low cutoff.')
    end
end
guidata(hObject, handles);

% --------------------------------------------------------------------
function Help_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function Untitled_3_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function CallClassification_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function ChangeContourThreshold_Callback(hObject, eventdata, handles)
% Change the contour threshold
prompt = {'Tonality Threshold: (default = 0.25)', 'Amplitude Threshold: (default = 0.075)'};
dlg_title = 'New Contour Threshold:';
num_lines=[1 50]; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
defaultans = {num2str(handles.data.settings.EntropyThreshold),num2str(handles.data.settings.AmplitudeThreshold)};
threshold = inputdlg(prompt,dlg_title,num_lines,defaultans);
if isempty(threshold); return; end

[Tonality,~,errmsg] = sscanf(threshold{1},'%f',1);
disp(errmsg);
[Amplitude,~,errmsg] = sscanf(threshold{2},'%f',1);
disp(errmsg);

if ~isempty(Tonality) && ~isempty(Amplitude)
    handles.data.settings.EntropyThreshold = Tonality;
    handles.data.settings.AmplitudeThreshold = Amplitude;
    handles.data.saveSettings();
    update_folders(hObject, eventdata, handles);
    try
        update_fig(hObject, eventdata, handles);
    catch
        disp('Could not update figure. Is a call loaded?')
    end
end
guidata(hObject, handles);

% --------------------------------------------------------------------
function ViewManual_Callback(hObject, eventdata, handles)
web('https://github.com/DrCoffey/DeepSqueak/wiki','-browser');

% --------------------------------------------------------------------
function AboutDeepSqueak_Callback(hObject, eventdata, handles)
title = 'About DeepSqueak';

d = dialog('Position',[300 350 500  600],'Name',title,'WindowStyle','Normal','Visible', 'off','Color', [0,0,0]);
movegui(d,'center');
ha = axes(d,'Units','Normalized','Position',[0,0,1,1]);

A = zeros(128);
A = insertText(A,[64,20],'Coffey & Marx, 2019','TextColor','white','BoxColor','Black','AnchorPoint','Center','FontSize',11);
A = insertText(A,[64,64],'DeepSqueak','TextColor','white','BoxColor','Black','AnchorPoint','Center');
A = insertText(A,[64,80],['Version ' handles.DSVersion],'TextColor','white','BoxColor','Black','AnchorPoint','Center','FontSize',11);

A = A(:,:,1);

P = [64, 64];
D = 3;
T = [1,0,-1,0;0,1,0,-1];	% 4 directions
k = 0;

handle_image = imshow(A,[0,1],'parent',ha);

btn = uicontrol('Parent',d,...
    'Units','Normalized',...
    'Position',[.42 .01 .16 .06],...
    'String','Okay',...
    'Callback','delete(gcf)');
set(d,'Visible','on')

while isvalid(handle_image)
    k = k+1;
    a = A(P(1),P(2));
    A(P(1),P(2)) = ~a;
    if ( a )
        D = mod(D+1,4);
    else
        D = mod(D-1,4);
    end
    P = P+T(:,D+1);
    handle_image.CData = A;
    pause(.01)
end


% --- Executes on slider movement.
function TonalitySlider_Callback(hObject, eventdata, handles)
handles.data.settings.EntropyThreshold=(get(hObject,'Value'));
handles.data.saveSettings();
update_fig(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function TonalitySlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TonalitySlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function Manifesto_Callback(hObject, eventdata, handles)
% Open the file

% If a text file
if exist(fullfile(handles.data.squeakfolder,'Manifestos',[hObject.Text '.txt']),'file') == 2
    fname = fullfile(handles.data.squeakfolder,'Manifestos',[hObject.Text '.txt']);
    fid = fopen(fname);
    chr = fscanf(fid,'%c');
    % Remove extra line end chars
    chr = strrep(chr,char(10),'');
    fprintf(1,'\n\n\n\n\n\n\n\n\n');
    fprintf(1,'%c',chr);
    fprintf(1,'\n\n');
    
    fclose(fid);
    
    % Display
    S.fh = figure('units','pixels',...
        'position',[40 40 760 640],...
        'menubar','none',...
        'resize','on',...
        'numbertitle','off',...
        'name',hObject.Text);
    S.tx = uicontrol('style','edit',...
        'units','pix',...
        'position',[10 10 750 630],...
        'backgroundcolor','w',...
        'HorizontalAlign','left',...
        'min',0,'max',10,...
        'String',chr,...
        'FontName','Courier',...
        'FontSize',11,...
        'BackgroundColor',[0,0,.1],...
        'ForegroundColor',[.6,1,1],...
        'enable','inactive');
    % If a pdf
elseif  exist(fullfile(handles.data.squeakfolder,'Manifestos',[hObject.Text '.pdf']),'file') == 2
    fname = fullfile(handles.data.squeakfolder,'Manifestos',[hObject.Text '.pdf']);
    open(fname)
elseif  strcmp(hObject.Text,'Read the Paper')
    fname = fullfile(handles.data.squeakfolder,'DeepSqueak.pdf');
    open(fname)
end


% --------------------------------------------------------------------
function submit_a_bug_Callback(hObject, eventdata, handles)
% hObject    handle to submit_a_bug (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
web('https://github.com/DrCoffey/DeepSqueak/issues','-browser');

% --- Executes on slider movement.
function optimization_slider_Callback(hObject, eventdata, handles)
hObject.Value = round(hObject.Value);
