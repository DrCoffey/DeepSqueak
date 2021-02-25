function [spectogram_y_lims, s, f] = cutSpectogramFrequency(s,f, handles)

    upper_freq = find(f>=handles.data.settings.HighFreq*1000,1);
    if isempty(upper_freq)
        upper_freq = length(f);
    end
    lower_freq = find(f>=handles.data.settings.LowFreq*1000,1);

    % Extract the region within the frequency range
    f = f(lower_freq:upper_freq,:);    
    s = s(lower_freq:upper_freq,:);    
    spectogram_y_lims = [ min(f), max(f)];
end

