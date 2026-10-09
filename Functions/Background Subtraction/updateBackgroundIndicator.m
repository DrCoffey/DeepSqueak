function updateBackgroundIndicator(handles)
%% Show in the window title what is happening to the open recording
% Background removal changes every spectrogram of that recording, so
% whether it is on must always be visible.

assigned = handles.data.backgroundAssigned;
isAssigned = ~isempty(assigned);
isApplied = isAssigned && handles.data.applyBackground;

if isApplied
    set(handles.figure1, 'Name', sprintf('DeepSqueak   |   Background removal ON for this recording: %s (%s)', assigned.name, assigned.id(1:12)));
elseif isAssigned
    set(handles.figure1, 'Name', sprintf('DeepSqueak   |   Background assigned but removal is OFF: %s (%s)', assigned.name, assigned.id(1:12)));
else
    set(handles.figure1, 'Name', 'DeepSqueak');
end

onoff = {'off', 'on'};
set(handles.backgroundApplyMenu, 'Enable', onoff{isAssigned + 1}, 'Checked', onoff{isApplied + 1});
set(handles.backgroundCompareMenu, 'Enable', onoff{isAssigned + 1});
end
