function change_spectogram_contrast_Callback(hObject, eventdata, handles)
clim_change = [0,0];
if ~isempty(eventdata)
    switch eventdata.Source.Tag
        case 'high_clim_plus'
            clim_change = [0, .1];
        case 'high_clim_minus'
            clim_change = [0, -.1];
        case 'low_clim_plus'
            clim_change = [.1, 0];
        case 'low_clim_minus'
            clim_change = [-.1, 0];
    end
end

handles.data.settings.spectrogramContrast = handles.data.settings.spectrogramContrast + range(handles.data.settings.spectrogramContrast) .* clim_change;

% Don't let the clim go below zero if using amplitude
if strcmp(handles.data.settings.spect.type, 'Amplitude')
    handles.data.settings.spectrogramContrast(1) = max(handles.data.settings.spectrogramContrast(1), -mean(handles.data.clim) ./ range(handles.data.clim));
end

clim = mean(handles.data.clim) + range(handles.data.clim) .* handles.data.settings.spectrogramContrast;
set(handles.spectogramWindow,'Clim',clim)
set(handles.focusWindow,'Clim',clim)
% handles.data.saveSettings();
guidata(hObject.Parent, handles);
