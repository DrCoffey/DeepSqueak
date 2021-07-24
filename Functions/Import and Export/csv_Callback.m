function csv_Callback(hObject, eventdata, handles)

    function t = loop_calls(Calls, hc,includereject,waitbar_text,handles,call_file,audiodata)
        HZ_IN_kHZ = 1000;
        callboxes = []; 
        for i = 1:height(Calls) % Do this for each call
            waitbar(i/height(Calls),hc,waitbar_text);

            if includereject || Calls.Accept(i)
                Label = Calls.Type(i);
                start_time = Calls.Box(i,1);
                end_time = start_time + Calls.Box(i,3);
                low_frequency = Calls.Box(i,2)*HZ_IN_kHZ;
                high_frequency = low_frequency + Calls.Box(i,4)*HZ_IN_kHZ;
                callboxes = [callboxes; {start_time} {end_time} {low_frequency} {high_frequency}, {Label} ];
            end

        end
        t = cell2table(callboxes);
    end

    export_Calls(@loop_calls,'.csv',hObject, eventdata, handles);
end
