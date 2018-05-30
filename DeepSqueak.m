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

% Set Handles
hFig = hObject;
handles.hFig=hFig;
set ( hFig, 'Color', [.1 .1 .1] );
handles.output = hObject;
[handles.squeakfolder] = fileparts(mfilename('fullpath'));
cd(handles.squeakfolder);
handles.cmap ='inferno';
handles.cmapname = {'inferno'};
handles.spect = imagesc(1,1,1,'Parent', handles.axes1);

% Check for missing files
if ~(exist(fullfile(handles.squeakfolder, 'settings.mat'), 'file')==2) % Create settings if it doesn't exist
    handles.settings.detectionfolder = [handles.squeakfolder '\Detections\'];
    handles.settings.networkfolder = [handles.squeakfolder '\Networks\'];
    handles.settings.audiofolder = [handles.squeakfolder '\Audio\'];
    handles.settings.detectionSettings = {'0' '3' '.1' '100' '18' '0.65' '0.5' '1'};
    handles.settings.playback_rate = 0.05;
    handles.settings.LowFreq = 15;
    handles.settings.HighFreq = 115;
    handles.settings.AmplitudeThreshold = 0.15;
    handles.settings.EntropyThreshold = 0.4;
    handles.settings.labels = {'FF','FM','Trill','Split',' ',' ',' ',' ',' ',' '};
    settings = handles.settings;
    save([handles.squeakfolder '/settings.mat'],'-struct','settings')
    disp('Settings not found. New settings file created.')
end

if ~(exist(fullfile(handles.squeakfolder,'Background.png'), 'file')==2)
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
if ~(exist(fullfile(handles.squeakfolder,'DeepSqueak.fig'), 'file')==2)
    errordlg('"DeepSqueak.fig" not found');
end
addpath(handles.squeakfolder);
addpath([handles.squeakfolder '\Functions']); % Add DeepSqueak to the path

% Cool Background Image
imshow(handles.background, 'Parent', handles.axes1);
set(handles.axes1,'XTick',[]);
set(handles.axes1,'YTick',[]);
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);  % Get newest version of handles
guidata(hObject, handles);

function varargout = DeepSqueak_OutputFcn(hObject, eventdata, handles)

varargout{1} = handles.output;

% --- Executes on button press in PlayCall.
function PlayCall_Callback(hObject, eventdata, handles)
% Play the sound within the boxs
   audio =  handles.calls(handles.currentcall).Audio;
if ~isa(audio,'double')
    audio = double(audio) / (double(intmax(class(audio)))+1);
end
rate = handles.calls(handles.currentcall).Rate * handles.settings.playback_rate; % set playback rate
paddedsound = [zeros(3125,1); audio; zeros(3125,1)];
audiostart = handles.calls(handles.currentcall).RelBox(1) * handles.calls(handles.currentcall).Rate;
audiolength = handles.calls(handles.currentcall).RelBox(3) * handles.calls(handles.currentcall).Rate;
sound(paddedsound(round(audiostart:audiostart+audiolength + 6249)),rate);
guidata(hObject, handles);

% --- Executes on button press in NextCall.
function NextCall_Callback(hObject, eventdata, handles)
if handles.currentcall<length(handles.calls) % If not the last call
    handles.currentcall=handles.currentcall+1;
    update_fig(hObject, eventdata, handles);
end
guidata(hObject, handles);

% --- Executes on button press in PreviousCall.
function PreviousCall_Callback(hObject, eventdata, handles)
if handles.currentcall>1 % If not the first call
    handles.currentcall=handles.currentcall-1;
    update_fig(hObject, eventdata, handles);
end
guidata(hObject, handles);

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
handles.calls(handles.currentcall).Accept=1;
update_fig(hObject, eventdata, handles);
guidata(hObject, handles);

% --- Executes on button press in RejectCall.
function RejectCall_Callback(hObject, eventdata, handles)
handles.calls(handles.currentcall).Accept=0;
update_fig(hObject, eventdata, handles);
guidata(hObject, handles);

% --- Executes during MAIN AXES CREATION
function axes1_CreateFcn(hObject, eventdata, handles)

% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
handles.currentcall=ceil(get(hObject,'Value')*length(handles.calls));
if handles.currentcall<1
    handles.currentcall=1;
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

switch eventdata.Key
    case 'p'
        PlayCall_Callback(hObject, eventdata, handles)
    case 'rightarrow'
        NextCall_Callback(hObject, eventdata, handles)
    case 'leftarrow'
        PreviousCall_Callback(hObject, eventdata, handles)
    case 'e'
        NextCall_Callback(hObject, eventdata, handles)
    case 'q'
        PreviousCall_Callback(hObject, eventdata, handles)
    case 'a'
        AcceptCall_Callback(hObject, eventdata, handles)
    case 'r'
        RejectCall_Callback(hObject, eventdata, handles)
    case 'd'
        rectangle_Callback(hObject, eventdata, handles)
    case '1'
        handles.calls(handles.currentcall).Type=handles.settings.labels(1);
        update_fig(hObject, eventdata, handles);
    case '2'
        handles.calls(handles.currentcall).Type=handles.settings.labels(2);
        update_fig(hObject, eventdata, handles);
    case '3'
        handles.calls(handles.currentcall).Type=handles.settings.labels(3);
        update_fig(hObject, eventdata, handles);
    case '4'
        handles.calls(handles.currentcall).Type=handles.settings.labels(4);
        update_fig(hObject, eventdata, handles);
    case '5'
        handles.calls(handles.currentcall).Type=handles.settings.labels(5);
        update_fig(hObject, eventdata, handles);
    case '6'
        handles.calls(handles.currentcall).Type=handles.settings.labels(6);
        update_fig(hObject, eventdata, handles);
    case '7'
        handles.calls(handles.currentcall).Type=handles.settings.labels(7);
        update_fig(hObject, eventdata, handles);
    case '8'
        handles.calls(handles.currentcall).Type=handles.settings.labels(8);
        update_fig(hObject, eventdata, handles);
    case '9'
        handles.calls(handles.currentcall).Type=handles.settings.labels(9);
        update_fig(hObject, eventdata, handles);
end

function figure1_KeyPressFcn(hObject, eventdata, handles)

% --- Executes on selection change in popupmenuColorMap.
function popupmenuColorMap_Callback(hObject, eventdata, handles)
handles.cmapname=get(hObject,'String');
handles.cmapname=handles.cmapname(get(hObject,'Value'));
switch handles.cmapname{1,1}
    case 'magma'
        handles.cmap=magma;
    case 'inferno' 
        handles.cmap=inferno;
    case 'viridis'
        handles.cmap=viridis;
    case 'plasma'
        handles.cmap=plasma;
    case 'hot'
        handles.cmap=hot;
    case 'cubehelix'
        handles.cmap=cubehelix;
    case 'parula'
        handles.cmap=parula;
    case 'jet'
        handles.cmap=jet;
    case 'hsv'
        handles.cmap=hsv;
    case 'cool'
        handles.cmap=cool;
    case 'spring'
        handles.cmap=spring;
    case 'summer'
        handles.cmap=summer;
    case 'autumn'
        handles.cmap=autumn;
    case 'winter'
        handles.cmap=winter;
    case 'gray'
        handles.cmap=gray;
    case 'bone'
        handles.cmap=bone;
    case 'copper'
        handles.cmap=copper;
    case 'pink'
        handles.cmap=pink;
end
update_fig(hObject, eventdata, handles);
guidata(hObject, handles);

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
fcn = makeConstrainToRectFcn('imrect',get(handles.axes1,'XLim'),get(handles.axes1,'YLim')); %constrain to edges
newbox=imrect(handles.axes1,'PositionConstraintFcn',fcn);
handles.pos=getPosition(newbox);
difference = handles.pos - handles.calls(handles.currentcall).RelBox;
handles.calls(handles.currentcall).RelBox=difference + handles.calls(handles.currentcall).RelBox;
handles.calls(handles.currentcall).Box=difference + handles.calls(handles.currentcall).Box;
delete(newbox);
update_fig(hObject, eventdata, handles);
guidata(hObject, handles);

% --------------------------------------------------------------------
function select_audio_Callback(hObject, eventdata, handles)
% Find audio in folder
path=uigetdir(handles.settings.audiofolder,'Select Audio File Folder');
if isnumeric(path);return;end
handles.settings.audiofolder = path;
settings = handles.settings;
save([handles.squeakfolder '/settings.mat'],'-struct','settings')
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);  % Get newest version of handles

% --------------------------------------------------------------------
function load_networks_Callback(hObject, eventdata, handles)
% Find networks
path=uigetdir(handles.settings.networkfolder,'Select Network Folder');
if isnumeric(path);return;end
handles.settings.networkfolder = path;
settings = handles.settings;
save([handles.squeakfolder '/settings.mat'],'-struct','settings')
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);  % Get newest version of handles

% --------------------------------------------------------------------
function folders_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function export_raven_Callback(hObject, eventdata, handles)
% Export current file as a txt file for viewing in Raven
% http://www.birds.cornell.edu/brp/raven/RavenOverview.html
raventable = [{'Selection'} {'View'} {'Channel'} {'Begin Time (s)'} {'End Time (s)'} {'Low Freq (Hz)'} {'High Freq (Hz)'} {'Delta Time (s)'} {'Delta Freq (Hz)'} {'Avg Power Density (dB FS)'} {'Annotation'}];
View = 'Spectrogram 1';
Channel = 1;
for i = 1:length(handles.calls)
    if handles.calls(i).Accept
        Selection = i;
        BeginTime = handles.calls(i).Box(1);
        EndTime = handles.calls(i).Box(1) + handles.calls(i).Box(3);
        LowFreq = (handles.calls(i).Box(2))*1000;
        HighFreq = (handles.calls(i).Box(2)+handles.calls(i).Box(4))*1000;
        DeltaTime = EndTime - BeginTime;
        DeltaFreq = HighFreq - LowFreq;
        AvgPwr = 1;
        Annotation = handles.calls(i).Accept;
        raventable = [raventable; {Selection} {View} {Channel} {BeginTime} {EndTime} {LowFreq} {HighFreq} {DeltaTime} {DeltaFreq} {AvgPwr} {Annotation}];
    end
end
a  = cell2table(raventable);
handles.v_call = get(handles.popupmenuDetectionFiles,'Value');
current_detection_file = handles.detectionfiles(handles.v_call).name;
ravenname=[strtok(current_detection_file,'.') '_Raven.txt'];
[FileName,PathName] = uiputfile(ravenname,'Save Raven Truth Table (.txt)');
writetable(a,[PathName FileName],'delimiter','\t','WriteVariableNames',false);
guidata(hObject, handles);

% --------------------------------------------------------------------
function export_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function training_Callback(hObject, eventdata, handles)

% --- Executes on button press in sortbytime.
function sortbytime_Callback(hObject, eventdata, handles)
% Sort current file by time
h = waitbar(0,'Sorting...');
A = [handles.calls.Box];
[sorted,ix] = sort(A(1:4:end));
handles.calls = handles.calls(ix);
handles.currentcall=1;
for i=1:length(handles.calls);
    handles.CallTime(i,1)=handles.calls(i).Box(1);
end
update_fig(hObject, eventdata, handles);
close(h);
guidata(hObject, handles);

% --- Executes on button press in sortbyscore.
function sortbyscore_Callback(hObject, eventdata, handles)
% Sort current file by score
h = waitbar(0,'Sorting...');
% A = struct2cell(handles.calls);
[sorted,ix] = sort([handles.calls.Score]);
handles.calls = handles.calls(ix);
handles.currentcall=1;
for i=1:length(handles.calls)
    handles.CallTime(i,1)=handles.calls(i).Box(1);
end
update_fig(hObject, eventdata, handles);
close(h);
guidata(hObject, handles);

% --------------------------------------------------------------------
function customlabels_Callback(hObject, eventdata, handles)
% Define call categories
prompt = {'Label 1:','Label 2:','Label 3:','Label 4:','Label 5:','Label 6:','Label 7:','Label 8:','Label 9:'};
dlg_title = 'Create Custom Labels';
num_lines=1; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
def = handles.settings.labels;% {'FF','FM','Trill','Split',' ',' ',' ',' ',' ',' '};
tmp_labels = (inputdlg(prompt,dlg_title,num_lines,def,options));
if ~isempty(tmp_labels)
    handles.settings.labels = tmp_labels;
    settings = handles.settings;
    save([handles.squeakfolder '/settings.mat'],'-struct','settings');
    update_folders(hObject, eventdata, handles);
end
guidata(hObject, handles);

% --------------------------------------------------------------------
function Change_Playback_Rate_Callback(hObject, eventdata, handles)
prompt = {'Playback Rate: (default = 0.0.5)'};
dlg_title = 'Change Playback Rate';
num_lines=1; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
defaultans = {num2str(handles.settings.playback_rate)};
rate = inputdlg(prompt,dlg_title,num_lines,defaultans);
[newrate,~,errmsg] = sscanf(rate{1},'%f',1);
disp(errmsg);
if ~isempty(newrate)
handles.settings.playback_rate = newrate;
settings = handles.settings;
save([handles.squeakfolder '/settings.mat'],'-struct','settings')
update_folders(hObject, eventdata, handles);
end
guidata(hObject, handles);

% --------------------------------------------------------------------
function Change_Display_Range_Callback(hObject, eventdata, handles)
% Change the y axis in the spectrogram viewer
prompt = {'Low Frequency:', 'High Frequency (KHz):'};
dlg_title = 'New Display Range (KHz):';
num_lines=[1 50]; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
defaultans = {num2str(handles.settings.LowFreq),num2str(handles.settings.HighFreq)};
dispRange = inputdlg(prompt,dlg_title,num_lines,defaultans);
[LowFreq,~,errmsg] = sscanf(dispRange{1},'%f',1);
disp(errmsg);
[HighFreq,~,errmsg] = sscanf(dispRange{2},'%f',1);
disp(errmsg);
if ~isempty(LowFreq) && ~isempty(HighFreq)
if HighFreq > LowFreq
handles.settings.LowFreq = LowFreq;
handles.settings.HighFreq = HighFreq;
settings = handles.settings;
save([handles.squeakfolder '/settings.mat'],'-struct','settings')
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
defaultans = {num2str(handles.settings.EntropyThreshold),num2str(handles.settings.AmplitudeThreshold)};
threshold = inputdlg(prompt,dlg_title,num_lines,defaultans);

[Tonality,~,errmsg] = sscanf(threshold{1},'%f',1);
disp(errmsg);
[Amplitude,~,errmsg] = sscanf(threshold{2},'%f',1);
disp(errmsg);

if ~isempty(Tonality) && ~isempty(Amplitude)
handles.settings.EntropyThreshold = Tonality;
handles.settings.AmplitudeThreshold = Amplitude;
settings = handles.settings;
save([handles.squeakfolder '/settings.mat'],'-struct','settings')
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
% Sorry
system(['powershell Unblock-File -Path ''' handles.squeakfolder '\DeepSqueak Manual.chm''']);
winopen([handles.squeakfolder '\DeepSqueak Manual.chm'])

% --------------------------------------------------------------------
function AboutDeepSqueak_Callback(hObject, eventdata, handles)
title = 'About DeepSqueak';
message = [
    {'DeepSqueak Version 1.0'}
    {'\copyright 2018'}
    ];
d = dialog('Position',[300 350 250  300],'Name',title,'WindowStyle','Normal');
tx = axes(d,'Units','Normalized','Position',[.2 .7 .6 .4],'Visible', 'off');
text(tx,.5,.5,message,'HorizontalAlignment','Center')
ha = axes(d,'Units','Normalized','Position',[.1 .15 .8 .6]);
handle_image = image(handles.background,'parent',ha);
axis off;
btn = uicontrol('Parent',d,...
    'Position',[100 10 50 25],...
    'String','Ok',...
    'Callback','delete(gcf)');


           
