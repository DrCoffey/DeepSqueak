function spectogramMax = get_spectogram_max(hObject, handels)
    spectogramMax = str2double(get(handels.SpectogramMax,'String'));
    
    contents = cellstr(get(handels.spectogramScalePopup,'String'));
    scale = contents{get(handels.spectogramScalePopup,'Value')};
    
    if ( isnan(spectogramMax) | spectogramMax == 0 ) & scale == 'log10' 
        spectogramMax = 1;
    end
    if (isnan(spectogramMax)| spectogramMax == 0) & scale == 'absolute'
        spectogramMax = 5;
    end    
end

