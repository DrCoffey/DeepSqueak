function varargout = thresholds(varargin)
% THRESHOLDS MATLAB code for thresholds.fig
%      THRESHOLDS, by itself, creates a new THRESHOLDS or raises the existing
%      singleton*.
%
%      H = THRESHOLDS returns the handle to a new THRESHOLDS or the handle to
%      the existing singleton*.
%
%      THRESHOLDS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in THRESHOLDS.M with the given input arguments.
%
%      THRESHOLDS('Property','Value',...) creates a new THRESHOLDS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before thresholds_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to thresholds_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help thresholds

% Last Modified by GUIDE v2.5 26-Sep-2018 16:31:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @thresholds_OpeningFcn, ...
    'gui_OutputFcn',  @thresholds_OutputFcn, ...
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
% End initialization code - DO NOT EDIT


% --- Executes just before thresholds is made visible.
function thresholds_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to thresholds (see VARARGIN)

% Choose default command line output for thresholds
handles.output = hObject;
if ~isempty(varargin)
    handles.filelist.String = varargin{1};
    handles.filelist.Value = varargin{2};
end

% Update handles structure
guidata(hObject, handles);

% Make the GUI modal
set(handles.figure1,'WindowStyle','modal')

% UIWAIT makes untitled1 wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = thresholds_OutputFcn(hObject, eventdata, handles)

% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.power_low_checkbox.Value;
varargout{2} = str2double(handles.power_low.String);
varargout{3} = handles.power_high_checkbox.Value;
varargout{4} = str2double(handles.power_high.String);
varargout{5} = handles.score_low_checkbox.Value;
varargout{6} = str2double(handles.score_low.String);
varargout{7} = handles.score_high_checkbox.Value;
varargout{8} = str2double(handles.score_high.String);
varargout{9} = handles.tonality_low_checkbox.Value;
varargout{10} = str2double(handles.tonality_low.String);
varargout{11} = handles.tonality_high_checkbox.Value;
varargout{12} = str2double(handles.tonality_high.String);
varargout{13} = handles.filelist.Value;
varargout{14}= handles.cancelled;
delete(handles.figure1);




function power_low_Callback(hObject, eventdata, handles)
% hObject    handle to power_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of power_low as text
%        str2double(get(hObject,'String')) returns contents of power_low as a double


% --- Executes during object creation, after setting all properties.
function power_low_CreateFcn(hObject, eventdata, handles)
% hObject    handle to power_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in power_low_checkbox.
function power_low_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to power_low_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of power_low_checkbox


% --- Executes on button press in ok_button.
function ok_button_Callback(hObject, eventdata, handles)
% hObject    handle to ok_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.cancelled = false;
guidata(hObject, handles);
uiresume(handles.figure1);

% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.cancelled = true;
guidata(hObject, handles);
uiresume(handles.figure1);

function power_high_Callback(hObject, eventdata, handles)
% hObject    handle to power_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of power_high as text
%        str2double(get(hObject,'String')) returns contents of power_high as a double


% --- Executes during object creation, after setting all properties.
function power_high_CreateFcn(hObject, eventdata, handles)
% hObject    handle to power_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in power_high_checkbox.
function power_high_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to power_high_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of power_high_checkbox


% --- Executes on button press in score_low_checkbox.
function score_low_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to score_low_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of score_low_checkbox


% --- Executes on button press in score_high_checkbox.
function score_high_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to score_high_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of score_high_checkbox



function score_low_Callback(hObject, eventdata, handles)
% hObject    handle to score_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of score_low as text
%        str2double(get(hObject,'String')) returns contents of score_low as a double


% --- Executes during object creation, after setting all properties.
function score_low_CreateFcn(hObject, eventdata, handles)
% hObject    handle to score_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function score_high_Callback(hObject, eventdata, handles)
% hObject    handle to score_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of score_high as text
%        str2double(get(hObject,'String')) returns contents of score_high as a double


% --- Executes during object creation, after setting all properties.
function score_high_CreateFcn(hObject, eventdata, handles)
% hObject    handle to score_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on selection change in filelist.
function filelist_Callback(hObject, eventdata, handles)
% hObject    handle to filelist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns filelist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from filelist


% --- Executes during object creation, after setting all properties.
function filelist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filelist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in tonality_low_checkbox.
function tonality_low_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to tonality_low_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tonality_low_checkbox


% --- Executes on button press in tonality_high_checkbox.
function tonality_high_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to tonality_high_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tonality_high_checkbox



function tonality_low_Callback(hObject, eventdata, handles)
% hObject    handle to tonality_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tonality_low as text
%        str2double(get(hObject,'String')) returns contents of tonality_low as a double


% --- Executes during object creation, after setting all properties.
function tonality_low_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tonality_low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tonality_high_Callback(hObject, eventdata, handles)
% hObject    handle to tonality_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tonality_high as text
%        str2double(get(hObject,'String')) returns contents of tonality_high as a double


% --- Executes during object creation, after setting all properties.
function tonality_high_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tonality_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
