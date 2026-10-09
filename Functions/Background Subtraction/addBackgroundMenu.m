function handles = addBackgroundMenu(handles)
%% Add the background subtraction menu items to the main window
% Built in code rather than in DeepSqueak.fig, so that it can be reviewed
% and merged like any other change.

% File > Select Background Folder, after the other folder choices
uimenu(handles.folders, 'Label', 'Select Background Folder', 'Position', 4, ...
    'Callback', @(hObject, eventdata) selectBackgroundFolder_Callback(hObject, eventdata, guidata(hObject)));

% Tools > Background Subtraction
menu = uimenu(handles.Untitled_2, 'Label', 'Background Subtraction', 'Separator', 'on', 'Tag', 'backgroundMenu');
uimenu(menu, 'Label', 'Define Background from Boxed Noise...', ...
    'Callback', @(hObject, eventdata) DefineBackground_Callback(hObject, eventdata, guidata(hObject)));
uimenu(menu, 'Label', 'Add Boxed Noise to a Definition...', ...
    'Callback', @(hObject, eventdata) EditBackground_Callback(hObject, eventdata, guidata(hObject), 'add'));
uimenu(menu, 'Label', 'Remove Boxed Noise from a Definition...', ...
    'Callback', @(hObject, eventdata) EditBackground_Callback(hObject, eventdata, guidata(hObject), 'remove'));
uimenu(menu, 'Separator', 'on', 'Label', 'Assign Background to Recordings...', ...
    'Callback', @(hObject, eventdata) AssignBackground_Callback(hObject, eventdata, guidata(hObject)));
uimenu(menu, 'Label', 'Remove Background Assignment from Recordings...', ...
    'Callback', @(hObject, eventdata) RemoveBackground_Callback(hObject, eventdata, guidata(hObject)));
handles.backgroundApplyMenu = uimenu(menu, 'Label', 'Apply Background Removal to This Recording', 'Separator', 'on', ...
    'Callback', @(hObject, eventdata) ApplyBackground_Callback(hObject, eventdata, guidata(hObject)));
handles.backgroundCompareMenu = uimenu(menu, 'Label', 'Compare Before and After (current page)', ...
    'Callback', @(hObject, eventdata) CompareBackground_Callback(hObject, eventdata, guidata(hObject)));
handles.backgroundMenu = menu;
end
