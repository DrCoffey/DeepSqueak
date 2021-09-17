function handles = render_call_boxes(current_axes,handles,roi, fill_heigth)
%% This function draws rectangles in the focus view and page view

axis_xlim = get(current_axes,'Xlim');
axis_ylim = get(current_axes,'Ylim');


% Find calls within the current window
calls_in_page = find( (handles.data.calls.Box(:,1) >= axis_xlim(1) & handles.data.calls.Box(:,1) < axis_xlim(2)  ) ...
    | ( handles.data.calls.Box(:,1) + handles.data.calls.Box(:,3)  >= axis_xlim(1) & handles.data.calls.Box(:,1) + handles.data.calls.Box(:,3)  <= axis_xlim(2) )...
    | ( handles.data.calls.Box(:,1)<=  axis_xlim(1) & handles.data.calls.Box(:,1) + handles.data.calls.Box(:,3) >=  axis_xlim(2) )...
    );

boxes = handles.data.calls.Box(calls_in_page,:);

% Draw labels if there are any labels other than 'USV'
% if ~isempty(calls_in_page) any(handles.data.calls.Type ~= 'USV')
    LabelVisible = 'on'; % use 'hover' to only display labels on mouse over2
% else
%     LabelVisible = 'off';
% end

% Loop through all calls
for box_number = 1:length(calls_in_page)
    current_tag = num2str(calls_in_page(box_number));
    
    if fill_heigth
        boxes(box_number,2) = axis_ylim(1);
        boxes(box_number,4) = axis_ylim(2);
    end
    
    line_width = 0.5;
    box_color = 'r';
    line_style = '-';
    
    % Make the line thick if current call
    if handles.data.calls.Accept(calls_in_page(box_number))
        box_color = [0 1 0];
    end
    if calls_in_page(box_number) == handles.data.currentcall
        line_width = 2;
    end
    
    if roi
        
        % Only display a label if it isn't just "USV"
        if handles.data.calls.Type(calls_in_page(box_number)) == {'USV'}
            label = '';
        else
            label = char(handles.data.calls.Type(calls_in_page(box_number)));
        end
        
        % Add a new rectangle if there isn't a handle for one yet, or
        % update an existing one
        if box_number > length(handles.FocusWindowRectangles) % draw a new rectangle if we need more
            c = uicontextmenu;
            handles.FocusWindowRectangles{box_number} = drawrectangle(...
                'Position', boxes(box_number, :),...
                'Parent', current_axes,...
                'Color', box_color,...
                'FaceAlpha', 0,...
                'LineWidth', line_width,...
                'Tag', current_tag,...
                'uicontextmenu', c,...
                'label', label,...
                'LabelAlpha', .5,...
                'LabelVisible', LabelVisible);
            addlistener(handles.FocusWindowRectangles{box_number},'ROIClicked',@callBoxDeleteCallback);
            addlistener(handles.FocusWindowRectangles{box_number},'ROIMoved', @roiMovedCallback);
        else
            set(handles.FocusWindowRectangles{box_number},...
                'Position', boxes(box_number, :),...
                'Color', box_color,...
                'LineWidth', line_width,...
                'Tag', current_tag,...
                'Visible', true,...
                'label', label,...
                'LabelVisible', LabelVisible);
        end
        
    else
        % Add a new rectangle if there isn't a handle for one yet, or
        % update an existing one
        if box_number > length(handles.PageWindowRectangles)
            handles.PageWindowRectangles{box_number} = rectangle(current_axes,...
                'Position',  boxes(box_number, :),...
                'LineWidth', line_width,...
                'LineStyle', line_style,...
                'EdgeColor', box_color,...
                'PickableParts', 'none');
        else
            set(handles.PageWindowRectangles{box_number},...
                'Position',  boxes(box_number, :),...
                'EdgeColor', box_color,...
                'LineWidth', line_width,...
                'Visible', true)
        end
        
    end
end

% Make any extra boxes invisible
if roi
    for i = length(calls_in_page)+1:length(handles.FocusWindowRectangles)
        handles.FocusWindowRectangles{i}.Visible = false;
    end
else
    for i = length(calls_in_page)+1:length(handles.PageWindowRectangles)
        handles.PageWindowRectangles{i}.Visible = false;
    end
end

end

