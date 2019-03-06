classdef GUIdata < handle
    properties
        calls
        currentcall = 1
        cmap = 'inferno'
        cmapName = {'inferno'}
        settings = struct()
        squeakfolder
        % Keyboard shortcuts for labelling calls
        labelShortcuts = {'1','2','3','4','5','6','7','8','9','0','-','='}
    end
    methods
        function obj = GUIdata(squeakfolder)
            obj.squeakfolder = squeakfolder;
            createSettings(obj);
        end
        
        function obj = createSettings(obj)
            % Check if the settings file exists. Create it if it doesn't.
            if exist(fullfile(obj.squeakfolder,'settings.mat'), 'file') ~= 2
                obj.settings.detectionfolder = fullfile(obj.squeakfolder, 'Detections/');
                obj.settings.networkfolder = fullfile(obj.squeakfolder, 'Networks/');
                obj.settings.audiofolder = fullfile(obj.squeakfolder, 'Audio/');
                obj.settings.detectionSettings = {'0' '6' '.1' '100' '18' '0' '1'};
                obj.settings.playback_rate = 0.05;
                obj.settings.LowFreq = 15;
                obj.settings.HighFreq = 115;
                obj.settings.AmplitudeThreshold = 0;
                obj.settings.EntropyThreshold = 0.3;
                obj.settings.labels = {'FF','FM','Trill','Split',' ',' ',' ',' ',' ',' '};
                obj.settings.DisplayTimePadding = 0;
                disp('Settings file not found. Create a new one...')
                saveSettings(obj)
            end
        end
        
        function saveSettings(obj)
            settings = obj.settings;
            save(fullfile(obj.squeakfolder, 'settings.mat'), '-struct', 'settings')
        end
        
        function loadSettings(obj)
            obj.settings = load(fullfile(obj.squeakfolder, 'settings.mat'));
        end
        
    end
end
