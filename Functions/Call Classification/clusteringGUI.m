classdef clusteringGUI < handle
    
    properties
        currentCluster = 1
        page = 1
        thumbnail_size = [50 100]
        clustAssign
        clusters
        rejected
        ClusteringData
        minfreq
        maxfreq
        fig
        image_axes = gobjects()
        handle_image = gobjects()
        ColorData
        totalCount
        count
        clusterName
        pagenumber
        finished
        call_id_text      
        txtbox
    end
    
    methods
        function [obj, NewclusterName, NewRejected, NewFinished, NewClustAssign] = clusteringGUI(clustAssign, ClusteringData)
            
            
            
            obj.clustAssign = clustAssign;
            %Image, Lower freq, delta time, Time points, Freq points, File path, Call ID in file, power, RelBox
            obj.ClusteringData = ClusteringData;
            obj.rejected = zeros(1,length(obj.clustAssign));
            
            obj.minfreq = prctile(ClusteringData.MinFreq, 5);
            obj.maxfreq = prctile(ClusteringData.MinFreq + ClusteringData.Bandwidth, 95);
            obj.ColorData = jet(256); % Color by mean frequency
            % obj.ColorData = HSLuv_to_RGB(256, 'H',  [270 0], 'S', 100, 'L', 75, 'type', 'HSL'); % Make a color map for each category
            obj.ColorData = reshape(obj.ColorData,size(obj.ColorData,1),1,size(obj.ColorData,2));
            
            if iscategorical(obj.clustAssign)
                obj.clusterName =unique(obj.clustAssign);
                obj.clusters = unique(obj.clustAssign);
            else
                obj.clusterName = categorical(unique(obj.clustAssign(~isnan(obj.clustAssign))));
                obj.clusters = (unique(obj.clustAssign(~isnan(obj.clustAssign))));
            end
            
            obj.fig = dialog('Visible','off','Position',[360,500,600,600],'WindowStyle','Normal','resize', 'on','WindowState','maximized' );
            obj.fig.CloseRequestFcn = @(src,event) finished_Callback(obj, src, event);
            set(obj.fig,'color',[.1, .1, .1]);
            
            movegui(obj.fig,'center');
            %             set(obj.fig,'WindowButtonMotionFcn', @(hObject, eventdata) mouse_over_Callback(obj, hObject, eventdata));
            
            txt = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.1 .1 .1],...
                'ForegroundColor','w',...
                'Style','text',...
                'Position',[120 565 80 30],...
                'String','Name:');
            
            obj.txtbox = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.149 .251 .251],...
                'ForegroundColor','w',...
                'Style','edit',...
                'String','',...
                'Position',[120 550 80 30],...
                'Callback',@(src,event) txtbox_Callback(obj,src,event));
            
            
            obj.totalCount = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.1 .1 .1],...
                'ForegroundColor','w',...
                'Style','text',...
                'String','',...
                'Position',[330 542.5 200 30],...
                'HorizontalAlignment','left');
            
            
            back = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.149 .251 .251],...
                'ForegroundColor','w',...
                'Position',[20 550 80 30],...
                'String','Back',...
                'Callback',@(src,event) back_Callback(obj, src, event));
            
            next = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.149 .251 .251],...
                'ForegroundColor','w',...
                'Position',[220 550 80 30],...
                'String','Next',...
                'Callback',@(src,event) next_Callback(obj, src, event));
            
            apply = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.149 .251 .251],...
                'ForegroundColor','w',...
                'Position',[440 550 60 30],...
                'String','Save',...
                'Callback',@(src,event)  finished_Callback(obj, src, event));
            
            if nargin == 2
                redo = uicontrol('Parent',obj.fig,...
                    'BackgroundColor',[.149 .251 .251],...
                    'ForegroundColor','w',...
                    'Position',[510 550 60 30],...
                    'String','Redo',...
                    'Callback',@(src,event) finished_Callback(obj, src, event));
            else
                redo = uicontrol('Parent',obj.fig,...
                    'BackgroundColor',[.149 .251 .251],...
                    'ForegroundColor','w',...
                    'Position',[510 550 60 30],...
                    'String','Cancel',...
                    'Callback',@(src,event) finished_Callback(obj, src, event));
            end
            %% Paging
            nextpage = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.149 .251 .251],...
                'ForegroundColor','w',...
                'Position',[220 517 80 30],...
                'String','Next Page',...
                'Callback',@(src,event) nextpage_Callback(obj, src, event));
            
            backpage = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.149 .251 .251],...
                'ForegroundColor','w',...
                'Position',[20 517 80 30],...
                'String','Previous Page',...
                'Callback',@(src,event, h) backpage_Callback(obj, src, event));
            
            obj.pagenumber = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.1 .1 .1],...
                'ForegroundColor','w',...
                'Style','text',...
                'String','',...
                'Position',[118 509 80 30],...
                'HorizontalAlignment','center');
            
            
            obj.call_id_text = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.1 .1 .1],...
                'ForegroundColor','w',...
                'Style','text',...
                'String','',...
                'FontSize',12,...
                'Position',[100 470 400 30],...
                'HorizontalAlignment','center');
            
            
            obj.render_GUI();
            
            % Wait for d to close before running to completion
            set( findall(obj.fig, '-property', 'Units' ), 'Units', 'Normalized');
            obj.fig.Visible = 'on';
            
            % Enable pointer management for the figure for mouse hover over
            iptPointerManager(obj.fig, 'enable');
                    
            uiwait(obj.fig);
            NewclusterName = obj.clusterName;
            NewRejected = obj.rejected;
            NewFinished = obj.finished;
            NewClustAssign = obj.clustAssign;
            
        end
        
        function render_GUI(obj)
            
            %% Colormap
%             xdata = obj.minfreq:obj.maxfreq;
%             caxis = axes(obj.fig,'Units','Normalized','Position',[.88 .05 .04 .8]);
%             image(1,xdata,obj.ColorData,'parent',caxis)
%             caxis.YDir = 'normal';
%             set(caxis,'YColor','w','box','off','YAxisLocation','right');
%             ylabel(caxis, 'Frequency (kHz)')
            
            %% Make the axes
            aspectRatio = median(cellfun(@(im) size(im,1) ./ size(im,2), obj.ClusteringData.Spectrogram));
            
            % Choose a number of rows and columns to fill the space with
            % the average call aspect ratio
            % nFrames = 10;
            % figureAspectRatio = 1;
            % x_grids = sqrt(aspectRatio * figureAspectRatio * nFrames);
            % x_grids = ceil(x_grids);
            % y_grids = ceil(nFrames / x_grids);
        
            obj.thumbnail_size = round(sqrt(20000 .* [aspectRatio, 1/aspectRatio]));

            axes_spacing = .70; % Relative width of each image
            y_range = [.05, .75]; % [Start, End] of the grid
            x_range = [.05, .95];
            x_grids = 8; % Number of x grids
            y_grids = 3; % Number of y grids

            ypos = linspace(y_range(1), y_range(2) - axes_spacing * range(y_range) / y_grids, y_grids );
            xpos = linspace(x_range(1), x_range(2) - axes_spacing * range(x_range) / x_grids, x_grids );
            xpos = fliplr(xpos);

            pos = [];
            for i = 1:length(ypos)
                for j = 1:length(xpos)
                    pos(end+1,:) = [xpos(j), ypos(i), (xpos(1)-xpos(2)) * axes_spacing, (ypos(2)-ypos(1)) * axes_spacing];
                end
            end
            pos = flipud(pos);
            for i = 1 : length(ypos) * length(xpos)
                    im = zeros([obj.thumbnail_size, 3]);
                    obj.image_axes(i) = axes(obj.fig,'Units','Normalized','Position',pos(i,:));
                    obj.handle_image(i) = image(im,'parent',obj.image_axes(i));
                    set(obj.image_axes(i),'Visible','off')
                    set(get(obj.image_axes(i),'children'),'Visible','off');
            end
            plotimages(obj);
        end
        
        function [colorIM, rel_x, rel_y] = create_thumbnail(obj, ClusteringData,clustIndex,callID)
            % Resize the image while maintaining the aspect ratio by
            % padding with zeros
            im_size = size(ClusteringData.Spectrogram{clustIndex(callID)}) ;
            new_size = floor(im_size .* min(obj.thumbnail_size ./ im_size));
            im = double(imresize(ClusteringData.Spectrogram{clustIndex(callID)}, new_size));
            pad = (obj.thumbnail_size - size(im)) / 2;
            im = padarray(im, floor(pad), 'pre');
            im = padarray(im, ceil(pad), 'post');
            
            % Relative offsets for setting the tick values
            rel_size = pad ./ obj.thumbnail_size;
            rel_x = [rel_size(2), 1-rel_size(2)];
            rel_y = [rel_size(1), 1-rel_size(1)];
            
            % Apply color to the greyscale images
            freqRange = [ClusteringData.MinFreq(clustIndex(callID)),...
                ClusteringData.MinFreq(clustIndex(callID)) + ClusteringData.Bandwidth(clustIndex(callID))];
            % Account for any padding on the y axis
            freqRange = freqRange + range(freqRange) .* rel_y(1) .* [-1, 1];

            freqdata = linspace(freqRange(2) ,freqRange(1), obj.thumbnail_size(1));
            %colorMask = interp1(linspace(obj.minfreq, obj.maxfreq, size(obj.ColorData,1)), obj.ColorData, freqdata, 'nearest', 'extrap');
            
            % colorIM = im .* colorMask ./ 255;
            Map       = inferno(255);
            colorIM      = ind2rgb(im, Map);
        end
        
        function obj = config_axis(obj, axis_handles,i, rel_x, rel_y)
            set(axis_handles,'xcolor','w');
            set(axis_handles,'ycolor','w');
            
            x_lim = xlim(axis_handles);
            x_span = x_lim(2) - x_lim(1);
            xtick_positions = linspace(x_span*rel_x(1)+x_lim(1), x_span*rel_x(2)+x_lim(1),4);
            x_ticks = linspace(0,obj.ClusteringData.Duration(i),4);
            x_ticks = arrayfun(@(x) sprintf('%.3f',x),x_ticks(2:end),'UniformOutput',false);
            
            y_lim = ylim(axis_handles);
            y_span = y_lim(2) - y_lim(1);
            ytick_positions = linspace(y_span*rel_y(1)+y_lim(1), y_span*rel_y(2)+y_lim(1),3);            
            
            y_ticks = linspace(obj.ClusteringData.MinFreq(i),obj.ClusteringData.MinFreq(i)+obj.ClusteringData.Bandwidth(i),3);
            y_ticks = arrayfun(@(x) sprintf('%.1f',x),y_ticks(1:end),'UniformOutput',false);
            y_ticks = flip(y_ticks);
            
            yticks(axis_handles,ytick_positions);
            xticks(axis_handles,xtick_positions(2:end));
            xticklabels(axis_handles,x_ticks);
            yticklabels(axis_handles,y_ticks);
            xlabel(axis_handles,'Time (s)');
            ylabel(axis_handles,'Frequency (kHz)');
        end
        
        function obj = plotimages(obj)
            % Number of calls in each cluster
            for cl = 1:length(obj.clusterName)
                obj.count(cl) = sum(obj.clustAssign==obj.clusters(cl));
            end
            
            clustIndex = find(obj.clustAssign==obj.clusters(obj.currentCluster));
            
            for i=1:length(obj.image_axes)
                if i <= length(clustIndex) - (obj.page - 1)*length(obj.image_axes)
                    % set(image_axes(i),'Visible','off')
                    
                    set(get(obj.image_axes(i),'children'),'Visible','on');
                    
                    callID = i + (obj.page - 1)*length(obj.image_axes);
                    [colorIM, rel_x, rel_y] = obj.create_thumbnail(obj.ClusteringData,clustIndex,callID);
                    set(obj.handle_image(i), 'ButtonDownFcn',@(src,event) clicked(obj,src,event,clustIndex(callID),i,callID));
                    obj.add_cluster_context_menu(obj.handle_image(i),clustIndex(callID));
                    
                    
                    % Display the file ID and call number on mouse hover
                    [~,call_file,~] = fileparts(obj.ClusteringData.Filename(clustIndex(callID)));
                    call_id = sprintf('Call: %u', obj.ClusteringData.callID(clustIndex(callID)));                   
                    pointerBehavior.enterFcn = @(~,~) set(obj.call_id_text, 'string', {call_id, call_file});
                    pointerBehavior.traverseFcn = [];
                    pointerBehavior.exitFcn = @(~,~) set(obj.call_id_text, 'string', '');
                    iptSetPointerBehavior(obj.handle_image(i), pointerBehavior);



                    % Make the image red if the call is rejected
                    if obj.rejected(clustIndex(callID))
                        colorIM(:,:,1) = colorIM(:,:,1) + .5;
                    end
                    
                    set(obj.handle_image(i),'CData',colorIM, 'XData', []);
                    
                    obj.config_axis(obj.image_axes(i),clustIndex(callID), rel_x, rel_y);
                    
                    set(obj.image_axes(i),'Visible','on')
                    
                else
                    set(obj.image_axes(i),'Visible','off')
                    set(get(obj.image_axes(i),'children'),'Visible','off');
                end
                
            end
            
            % Update text
            obj.pagenumber.String = sprintf('Page %u of %u', obj.page, ceil(obj.count(obj.currentCluster) / length(obj.image_axes)));
            obj.txtbox.String = string(obj.clusterName(obj.currentCluster));
            obj.totalCount.String = sprintf('total count: %u', obj.count(obj.currentCluster));
            obj.fig.Name = sprintf('Cluster %u of %u', obj.currentCluster, length(obj.count));
            
        end
        
        function obj = add_cluster_context_menu(obj, hObject, i)
            unique_clusters = unique(obj.clusterName);
            
            c = uicontextmenu(obj.fig);
            for ci=1:length(unique_clusters)
                uimenu(c,'text',string(obj.clusterName(ci)),'Callback',@(src,event) assign_cluster(obj, src, event,i,unique_clusters(ci)));
            end
            
            set(hObject, 'UIContextMenu',c);
        end
        
        function obj = assign_cluster(obj, hObject,eventdata,i, clusterLabel)
            obj.clustAssign(i) = clusterLabel;
            obj.plotimages();
        end
        
        function obj = clicked(obj, hObject,eventdata,i,plotI,callID)
            if( eventdata.Button ~= 1 ) % Return if not left clicked
                return
            end
            
            clustIndex = find(obj.clustAssign == obj.clusters(obj.currentCluster));
            
            obj.rejected(i) = ~obj.rejected(i);
            
            [colorIM, ~, ~] = obj.create_thumbnail(obj.ClusteringData,clustIndex,callID);
           
            if obj.rejected(i)
                colorIM(:,:,1) = colorIM(:,:,1) + .5;
            end            
            set(obj.handle_image(plotI),'CData',colorIM);
        end
        
        function obj = next_Callback(obj, hObject, eventdata)
            obj.clusterName(obj.currentCluster) = get(obj.txtbox,'String');
            if obj.currentCluster < length(obj.clusterName)
                obj.currentCluster = obj.currentCluster + 1;
                obj.page = 1;
                obj.plotimages();
            end
        end
        
        function obj = back_Callback(obj, hObject, eventdata)
            obj.clusterName(obj.currentCluster) = get(obj.txtbox,'String');
            if obj.currentCluster > 1
                obj.currentCluster = obj.currentCluster-1;
                obj.page = 1;
                obj.plotimages();
            end
        end
        
        function obj = nextpage_Callback(obj, hObject, eventdata)
            if obj.page < ceil(obj.count(obj.currentCluster) / length(obj.image_axes))
                obj.page = obj.page + 1;
                obj.plotimages();
            end
        end
        
        function obj = backpage_Callback(obj, hObject, eventdata)
            if obj.page > 1
                obj.page = obj.page - 1;
                obj.plotimages();
            end
        end
        
        function obj = txtbox_Callback(obj, hObject, eventdata)
            obj.clusterName(obj.currentCluster) = get(hObject,'String');
        end

        function obj = finished_Callback(obj, hObject, eventdata)
            % If window is closed, finished = 2
            % If clicked apply, finished = 1
            % If clicked redo, finished = 0
            switch eventdata.EventName
                case 'Close'
                    obj.finished = 2;
                otherwise
                    switch hObject.String
                        case 'Save'
                            obj.finished = 1;
                        case 'Redo'
                            obj.finished = 0;
                    end
            end
            set(obj.fig,  'closerequestfcn', '');
            delete(obj.fig);
            obj.fig = [];
        end
        
    end
end
