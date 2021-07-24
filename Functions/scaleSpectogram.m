function values = scaleSpectogram(values, spectrogramType, windowsize, samplerate)

%     contents = cellstr(get(handles.spectogramScalePopup,'String'));
%     scale = contents{get(handles.spectogramScalePopup,'Value')};
% spectrogramType = "absolute";
% spectrogramType = 'absolute';
switch spectrogramType
    case 'Power Spectral Density'
        win = hamming(windowsize);
        values = abs(values).^2;
        values = 1 / (samplerate * norm(win,2)^2) * values;
        values(2:end-1) = 2*values(2:end-1);
        values = 10*log10(values);
        
    case 'Amplitude'
        values =  abs(values);
end
