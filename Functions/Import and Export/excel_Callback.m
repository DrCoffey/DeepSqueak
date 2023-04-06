function excel_Callback(hObject, eventdata, handles)

    function t = loop_calls(Calls, hc,includereject,waitbar_text,handles,call_file, audioReader)
            exceltable = [{'File'} {'ID'} {'Label'} {'Accepted'} {'Score'} {'Begin Time (s)'} {'End Time (s)'} {'Call Length (s)'} {'Principal Frequency (kHz)'} {'Low Freq (kHz)'} {'High Freq (kHz)'} {'Delta Freq (kHz)'} {'Frequency Standard Deviation (kHz)'} {'Slope (kHz/s)'} {'Sinuosity'} {'Mean Power (dB/Hz)'} {'Tonality'} {'Peak Freq (kHz)'}];        for i = 1:height(Calls) % Do this for each call
            waitbar(i/height(Calls),hc,waitbar_text);

            if includereject || Calls.Accept(i)
                
                if Calls.Box(i,1) + Calls.Box(i,3) > audioReader.audiodata.Duration
                   warning('Call box start beyond audio duration. Skipping call %i in file %s',i,call_file); 
                   continue;
                end
                %Skip boxes with zero time of frequency span
                if Calls.Box(i,3) == 0 || Calls.Box(i,4) == 0
                   continue; 
                end
                
                % Get spectrogram data
                [I,windowsize,noverlap,nfft,rate,box] = CreateFocusSpectrogram(Calls(i, :),handles,true, [], audioReader);
                % Calculate statistics
                stats = CalculateStats(I,windowsize,noverlap,nfft,rate,box,handles.data.settings.EntropyThreshold,handles.data.settings.AmplitudeThreshold);

                ID = i;
                Label = Calls.Type(i);
                Score = Calls.Score(i);
                accepted = Calls.Accept(i);
                File = call_file;
                exceltable = [exceltable; {File} {ID} {Label} {accepted} {Score} {stats.BeginTime} {stats.EndTime} {stats.DeltaTime} {stats.PrincipalFreq} {stats.LowFreq} {stats.HighFreq} {stats.DeltaFreq} {stats.stdev} {stats.Slope} {stats.Sinuosity} {stats.MeanPower} {stats.SignalToNoise} {stats.PeakFreq}];            end

        end
        t = cell2table(exceltable);

    end

    export_Calls(@loop_calls,'_Stats.xlsx',hObject, eventdata, handles);
end