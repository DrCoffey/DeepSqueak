function esportspect_Callback(hObject, eventdata, handles)
% Plotting Defferntial Expression

[~,detectionName] = fileparts(handles.current_detection_file);
spectname = [detectionName ' Call ' num2str(handles.data.currentcall) '.png'];
[FileName,PathName] = uiputfile(spectname,'Save Spectrogram');

% Cancel if cancelled
if isnumeric(FileName)
    return
end

% Get the spectrogram from the display
I = get(handles.spect,'CData');
Ydata = get(handles.spect,'Ydata');
Ylim = get(handles.focusWindow,'Ylim');

% Set limits
Ymax = find(Ydata>=Ylim(2),1);
Ymin = find(Ydata>=Ylim(1),1);
I = flipud(I(Ymin:Ymax,:));

Clim = get(handles.focusWindow,'Clim');
I = mat2gray(I,Clim);
fullFileName = fullfile(PathName, FileName); % Add Figure Path
cmap = handles.data.cmap;
I2 = gray2ind(I,256);
RGB3 = ind2rgb(I2, inferno(255));
imwrite(RGB3,fullFileName,'png','BitDepth',8); % Re-change it to colored one 

