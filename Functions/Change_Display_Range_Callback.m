function Change_Display_Range_Callback(hObject, eventdata, handles)

% handles.data.settings.LowFreq = 15;
% handles.data.settings.HighFreq = 75;
% handles.data.settings.spect.type = 'Amplitude';
% handles.data.settings.spect.windowsize = 0.0032;
% handles.data.settings.spect.noverlap = 0.0016;
% handles.data.settings.spect.nfft = 0.0032;
hfig = dialog(...
    'menu','none',...
    'Position', [360,500,350,500],...
    'Visible','off');
movegui(hfig,'center');

prompt = struct(...
    'LowFreq', 'Low frequency cutoff (kHz):',...
    'HighFreq', 'High frequency cutoff (kHz):',...
    'type', 'Spectrogram Units:',...
    'windowsize', 'window size (s):',...
    'noverlap', 'overlap (%):',...
    'nfft', 'nfft (s):');


% values = struct(...
%     'LowFreq', handles.data.settings.LowFreq,...
%     'HighFreq', handles.data.settings.HighFreq,...
%     'spect', struct(...
%     'type', {'Amplitude', 'Power Spectral Density'},...
%     'windowsize', handles.data.settings.windowsize,...
%     'noverlap', handles.data.settings.noverlap,...
%     'nfft', handles.data.settings.nfft));
values = handles.data.settings;
values.spect.type = {'Amplitude', 'Power Spectral Density'};
%
% values = {
%     handles.data.settings.LowFreq
%     handles.data.settings.HighFreq
%     {'Amplitude', 'Power Spectral Density'}
%     handles.data.settings.spect.windowsize
%     handles.data.settings.spect.noverlap
%     handles.data.settings.spect.nfft
%     };




AxesHandle=axes('Parent',hfig,'Position',[0 0 1 1],'Visible','off');

%%
ui.LowFreq = uicontrol('Style', 'Edit', 'String', values.LowFreq, ...
    'Parent',hfig,'Units','Normalized', ...
    'Position', [.55, .88, .4, .07]);
text('Parent', AxesHandle,...
    'Position', [.05, .88+.07/2],...
    'String', prompt.LowFreq,...
    'VerticalAlignment', 'middle');


ui.HighFreq = uicontrol('Style', 'Edit', 'String', values.HighFreq, ...
    'Parent',hfig,'Units','Normalized', ...
    'Position', [.55, .78, .4, .07]);
text('Parent', AxesHandle,...
    'Position', [.05, .78+.07/2],...
    'String', prompt.HighFreq,...
    'VerticalAlignment', 'middle');


ui.type = uicontrol('Style', 'popupmenu', 'String', values.spect.type, ...
    'Parent',hfig,'Units','Normalized', ...
    'Position', [.55, .68, .4, .055],...
    'Value', find(strcmp(values.spect.type, handles.data.settings.spect.type)));
text('Parent', AxesHandle,...
    'Position', [.05, .68+.07/2],...
    'String', prompt.type,...
    'VerticalAlignment', 'middle');


%%


c = uicontrol('Style','text',...
    'Parent',hfig,'Units','Normalized', ...
    'Position', [.05, .5, .9, .1],...
    'HorizontalAlignment', 'left',...
    'String', 'Spectrogram parameters are defined in units of seconds to account for variable sample rates');
% [wrappedtext,position] = textwrap(c,c.String,32)
% c.String = wrappedtext;
% c.Position = position;

ui.windowsize = uicontrol('Style', 'Edit', 'String', values.spect.windowsize, ...
    'Parent',hfig,'Units','Normalized', ...
    'Position', [.65, .45, .25, .06]);
text('Parent', AxesHandle,...
    'Position', [.55, .45+.06/2],...
    'String', prompt.windowsize,...
    'HorizontalAlignment', 'right',...
    'VerticalAlignment', 'middle');

ui.noverlap = uicontrol('Style', 'Edit', 'String', 100 * values.spect.noverlap ./ values.spect.windowsize, ...
    'Parent',hfig,'Units','Normalized', ...
    'Position', [.65, .38, .25, .06]);
text('Parent', AxesHandle,...
    'Position', [.55, .38+.06/2],...
    'String', prompt.noverlap,...
    'HorizontalAlignment', 'right',...
    'VerticalAlignment', 'middle');

ui.nfft = uicontrol('Style', 'Edit', 'String', values.spect.nfft, ...
    'Parent',hfig,'Units','Normalized', ...
    'Position', [.65, .31, .25, .06]);
text('Parent', AxesHandle,...
    'Position', [.55, .31+.06/2],...
    'String', prompt.nfft,...
    'HorizontalAlignment', 'right',...
    'VerticalAlignment', 'middle');

autoscale = uicontrol('Style', 'pushbutton', 'String', 'Auto window size', ...
    'Parent',hfig,'Units','Normalized', ...
    'Position', [.05, .31, .3, .06],...
    'Callback', @autoScale);

%%
ok_button = uicontrol('Style', 'pushbutton', 'String', 'OK', ...
    'Parent',hfig,'Units','Normalized', ...
    'Position', [.1 .05 .2 .1],...
    'Callback',@pressed_ok,...
    'Tag','0');
cancel=uicontrol('Style', 'pushbutton', 'String', 'Cancel', ...
    'Parent',hfig,'Units','Normalized', ...
    'Position', [.4 .05 .2 .1],...
    'Tag','0','Callback',@cancelfun);
helpbutton=uicontrol('Style', 'pushbutton', 'String', 'Help', ...
    'Parent',hfig,'Units','Normalized', ...
    'Position', [.7 .05 .2 .1],...
    'Callback',@helpfun);
%wait for figure being closed (with OK button or window close)

hfig.Visible = 'on';

% uiwait(hfig)
% %figure is now closing
% if strcmp(ok_button.Tag,'1')%not canceled, get actual inputs
% lowFreq.String
% end
% %actually close the figure
% delete(hfig)



    function pressed_ok(h,~)
        %% Validate the new values and save them
     
        % Extract numbers from the numeric fields and return if any values
        % aren't valid
        newValues = struct();
        for numericFields = {'LowFreq', 'HighFreq', 'windowsize', 'noverlap', 'nfft'}
            newValues.(numericFields{:}) =  sscanf(ui.(numericFields{:}).String,'%f', 1);
            if isempty(newValues.(numericFields{:}))
                errordlg(['Invalid value for ' prompt.(numericFields{:})])
                return
            end
        end
        
        % Make sure that the low frequency cutoff is less than high cutoff
        if newValues.LowFreq >= newValues.HighFreq
            errordlg('High frequency cutoff must be greater than low frequency cutoff!')
            return
        end
        
        if newValues.noverlap >= 95
            errordlg('Spectrogram overlap must be less than 95%')
            return
        end
        
        
        handles.data.settings.LowFreq = newValues.LowFreq;
        handles.data.settings.HighFreq = newValues.HighFreq;
        handles.data.settings.spect.type = ui.type.String{ui.type.Value};
        handles.data.settings.spect.windowsize = newValues.windowsize;
        handles.data.settings.spect.noverlap = newValues.noverlap * newValues.windowsize / 100;
        handles.data.settings.spect.nfft = newValues.nfft;
        
        delete(hfig)
        
        
        handles.data.saveSettings();
        if ~isempty(handles.data.audiodata)
            update_fig(hObject, eventdata, handles, true);
            % Update the color limits because changing from amplitude to
            % power would mess with them
            handles.data.clim = prctile(handles.data.page_spect.s_display(20:10:end-20, 1:20:end),[10,90], 'all')';
            change_spectogram_contrast_Callback(hObject,[],handles);

            handles.focusWindow.Colorbar.Label.String = handles.data.settings.spect.type;
            handles.spectogramWindow.Colorbar.Label.String = handles.data.settings.spect.type;
        end
        guidata(hObject, handles);
        
    end


    function helpfun(~,~)
        helpdlg('Meep!')
    end

    function cancelfun(~,~)
        % uiresume
        delete(hfig)
    end

    function autoScale(~,~)
        % Optimize the window size so that the pixels are square
        yRange(1) = sscanf(ui.LowFreq.String,'%f', 1);
        yRange(2) = sscanf(ui.HighFreq.String,'%f', 1);
        yRange(2) = min(yRange(2), handles.data.audiodata.SampleRate / 2000);
        yRange = yRange(2) - yRange(1);
        % yRange = handles.focusWindow.YLim(2) - handles.focusWindow.YLim(1);
        xRange = handles.focusWindow.XLim(2) - handles.focusWindow.XLim(1);
        noverlap = sscanf(ui.noverlap.String,'%f', 1) / 100;
        optimalWindow = sqrt(xRange/(2000*yRange));
        optimalWindow = optimalWindow + optimalWindow.*noverlap;
        ui.windowsize.String = num2str(optimalWindow, 3);
        ui.nfft.String = num2str(optimalWindow, 3);
    end

end
