classdef squeakData < handle
    properties
        calls
        currentcall = 1
        current_call_valid = true
        windowposition = 1;
        lastWindowPosition = -1;
        cmap = 'inferno'
        cmapName = {'inferno'}
        settings = struct()
        defaultSettings = struct()
        squeakfolder
        audiodata
        % Keyboard shortcuts for labelling calls
        labelShortcuts = {'1','2','3','4','5','6','7','8','9','0','-','=','!','@','#','$','%','^','&','*','(',')','_','+'}
        page_spect = struct() % spectrogram of the page view
        focusCenter = 0; % center of the current focus window
        pageSizes = [2, 3, 5, 10, 30] % List of page size values in the dropdown box
        focusSizes = [.25, .5, 1, 2, 5] % List of focus size values in the dropdown box
        clim = [0 1];
    end
    properties (Access = private)
        AudioStartSample = 0;
        AudioStopSample = 0;
        StoredSamples = [];
        SamplesToRead = 192000 .* 10;
    end
    
    methods
        function obj = squeakData(squeakfolder)
            if nargin < 1
                squeakfolder = [];
            end
            obj.squeakfolder = squeakfolder;
            obj.defaultSettings = struct();
            obj.defaultSettings.detectionfolder = fullfile(obj.squeakfolder, 'Detections/');
            obj.defaultSettings.networkfolder = fullfile(obj.squeakfolder, 'Networks/');
            obj.defaultSettings.audiofolder = fullfile(obj.squeakfolder, 'Audio/');
            obj.defaultSettings.detectionSettings = {'0' '100' '18' '0' '1'};
            obj.defaultSettings.playback_rate = 0.05;
            obj.defaultSettings.LowFreq = 0;
            obj.defaultSettings.HighFreq = 115;
            obj.defaultSettings.AmplitudeThreshold = 0.825;
            obj.defaultSettings.EntropyThreshold = 0.215;
            obj.defaultSettings.labels = {'1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24'};
            obj.defaultSettings.pageSize = 3; % Size of page view in seconds
            obj.defaultSettings.spectogram_ticks = 11;
            obj.defaultSettings.focus_window_size = 0.5;
            obj.defaultSettings.spectrogramContrast = [-.6, 3];
            % Spectrogram fft settings in seconds
            obj.defaultSettings.spect.windowsize = 0.0032;
            obj.defaultSettings.spect.noverlap = 0.0016;
            obj.defaultSettings.spect.nfft = 0.0032;
            obj.defaultSettings.spect.type = 'Amplitude';
        end
        
        
        function saveSettings(obj)
            settings = obj.settings;
            save(fullfile(obj.squeakfolder, 'settings.mat'), '-struct', 'settings')
        end
        
        
        function loadSettings(obj)
            % Check if the settings file exists. Create it if it doesn't.
            if ~exist(fullfile(obj.squeakfolder,'settings.mat'), 'file')
                obj.settings = obj.defaultSettings;
                disp('Settings file not found. Create a new one...')
                saveSettings(obj)
            end
            obj.settings = load(fullfile(obj.squeakfolder, 'settings.mat'));
            % Add any missing settings
            missingSettings = setdiff(fieldnames(obj.defaultSettings), fieldnames(obj.settings));
            for i = missingSettings'
                obj.settings = setfield(obj.settings, i{:}, getfield(obj.defaultSettings,i{:}));
            end
        end
        
        function set.audiodata(obj, audiodata)
            obj.StoredSamples = [];
            obj.AudioStartSample = 0;
            obj.AudioStopSample = 0;
            obj.audiodata = audiodata;
        end
        
        
        function samples = AudioSamples(obj, startTime, finalTime)
            startTime = max(startTime, 0);
            startSample = round(startTime*obj.audiodata.SampleRate);
            finalSample = round(finalTime*obj.audiodata.SampleRate);
            
            startSample = max(startSample, 1);
            finalSample = min(finalSample, obj.audiodata.TotalSamples);
            
            if finalSample > obj.AudioStopSample || startSample < obj.AudioStartSample
                obj.AudioStartSample = round(obj.audiodata.SampleRate .* startTime);
                obj.AudioStartSample = max(obj.AudioStartSample,1);
                obj.AudioStopSample  = round(obj.audiodata.SampleRate .* (finalTime));
                obj.AudioStopSample  = min(obj.AudioStopSample, obj.audiodata.TotalSamples);
                obj.StoredSamples = audioread(obj.audiodata.Filename, [obj.AudioStartSample, obj.AudioStopSample]);
            end
            
            startSample = startSample - obj.AudioStartSample + 1;
            finalSample = finalSample - obj.AudioStartSample;
            samples = obj.StoredSamples(startSample:finalSample);
        end
        
    end
    
end


