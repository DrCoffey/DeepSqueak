function [NewclusterName, NewRejected, NewFinished] = clusteringGUI(clustAssign1,ClusteringData1,JustLooking)
% I know I shouldn't use global variables, but they are so convenient, and I was in a hurry.
clearvars -global
global k clustAssign clusters rejected ClusteringData minfreq d ha ColorData txtbox totalCount count clusterName handle_image page pagenumber finished
clustAssign = clustAssign1;
ClusteringData = ClusteringData1;

rejected = zeros(1,length(clustAssign));

minfreq = floor(min([ClusteringData{:,2}]))-1;
maxfreq = ceil(max([ClusteringData{:,2}] + [ClusteringData{:,9}]));
mfreq = cellfun(@mean,(ClusteringData(:,4)));
ColorData = jet(maxfreq - minfreq); % Color by mean frequency
if iscategorical(clustAssign)
    clusterName =unique(clustAssign);
    clusters = unique(clustAssign);
else
    clusterName = categorical(unique(clustAssign(~isnan(clustAssign))));
    clusters = (unique(clustAssign(~isnan(clustAssign))));
end


% Number of calls in each cluster
for cl = 1:length(clusterName)
    count(cl) = sum(clustAssign==clusters(cl));
end



d = dialog('Visible','off','Position',[360,500,600,600],'WindowStyle','Normal','resize', 'on' );
d.CloseRequestFcn = @windowclosed;
set(d,'color',[.1, .1, .1]);
k = 1;
page = 1;
set(d,'name',['Cluster ' num2str(k) ' of ' num2str(length(count))])
movegui(d,'center');

txt = uicontrol('Parent',d,...
    'BackgroundColor',[.1 .1 .1],...
    'ForegroundColor','w',...
    'Style','text',...
    'Position',[120 565 80 30],...
    'String','Name:');

txtbox = uicontrol('Parent',d,...
    'BackgroundColor',[.149 .251 .251],...
    'ForegroundColor','w',...
    'Style','edit',...
    'String',string(clusterName(k)),...
    'Position',[120 550 80 30],...
    'Callback',@txtbox_Callback);


totalCount = uicontrol('Parent',d,...
    'BackgroundColor',[.1 .1 .1],...
    'ForegroundColor','w',...
    'Style','text',...
    'String',['total count:' char(string(count(k)))],...
    'Position',[330 542.5 200 30],...
    'HorizontalAlignment','left');


back = uicontrol('Parent',d,...
    'BackgroundColor',[.149 .251 .251],...
    'ForegroundColor','w',...
    'Position',[20 550 80 30],...
    'String','Back',...
    'Callback',@back_Callback);

next = uicontrol('Parent',d,...
    'BackgroundColor',[.149 .251 .251],...
    'ForegroundColor','w',...
    'Position',[220 550 80 30],...
    'String','Next',...
    'Callback',@next_Callback);

apply = uicontrol('Parent',d,...
    'BackgroundColor',[.149 .251 .251],...
    'ForegroundColor','w',...
    'Position',[440 550 60 30],...
    'String','Save',...
    'Callback',@apply_Callback);

if nargin == 2
    redo = uicontrol('Parent',d,...
        'BackgroundColor',[.149 .251 .251],...
        'ForegroundColor','w',...
        'Position',[510 550 60 30],...
        'String','Redo',...
        'Callback',@redo_Callback);
else
    redo = uicontrol('Parent',d,...
        'BackgroundColor',[.149 .251 .251],...
        'ForegroundColor','w',...
        'Position',[510 550 60 30],...
        'String','Cancel',...
        'Callback',@redo_Callback);
end
%% Paging
nextpage = uicontrol('Parent',d,...
    'BackgroundColor',[.149 .251 .251],...
    'ForegroundColor','w',...
    'Position',[220 517 80 30],...
    'String','Next Page',...
    'Callback',@nextpage_Callback);

backpage = uicontrol('Parent',d,...
    'BackgroundColor',[.149 .251 .251],...
    'ForegroundColor','w',...
    'Position',[20 517 80 30],...
    'String','Previous Page',...
    'Callback',@backpage_Callback);




%% Colormap
xdata = minfreq:.3:maxfreq;
color = jet(length(xdata));
caxis = axes(d,'Units','Normalized','Position',[.88 .05 .04 .8]);
cm(:,:,1) = color(:,1);
cm(:,:,2) = color(:,2);
cm(:,:,3) = color(:,3);
image(1,xdata,cm,'parent',caxis)
caxis.YDir = 'normal';
set(caxis,'YColor','w','box','off','YAxisLocation','right');
ylabel(caxis, 'Frequency (KHz)')


%% Make the axes
clustIndex = find(clustAssign==clusters(k));
ypos = .05:.1:.75;
xpos = .02:.14:.8;
xpos = fliplr(xpos);
c = 0;
for i = 1:length(ypos)
    for j = 1:length(xpos)
        c = c+1;
        pos(c,:) = [ypos(i), xpos(j)];
    end
end
pos = flipud(pos);
for i=1:i*j
    if i <= length(clustIndex) - (page - 1)*length(ha)
        
        im = imresize(ClusteringData{clustIndex(i),1},[60 100]);
        freqdata = round(linspace(ClusteringData{clustIndex(i),2} + ClusteringData{clustIndex(i),9},ClusteringData{clustIndex(i),2},60));
        colorIM(:,:,1) =  single(im).*.0039.*ColorData(freqdata - minfreq,1);
        colorIM(:,:,2) =  single(im).*.0039.*ColorData(freqdata - minfreq,2);
        colorIM(:,:,3) =  single(im).*.0039.*ColorData(freqdata - minfreq,3);
        
        ha(i) = axes(d,'Units','Normalized','Position',[pos(i,2),pos(i,1),.13,.09]);
        handle_image(i) = image(colorIM + .5 .* rejected(clustIndex(i)),'parent',ha(i));
        set(handle_image(i), 'ButtonDownFcn',{@clicked,clustIndex(i),i});
        axis(ha(i),'off');
    else
        ha(i) = axes(d,'Units','Normalized','Position',[pos(i,2),pos(i,1),.13,.09]);
        handle_image(i) = image(colorIM,'parent',ha(i));
        set(ha(i),'Visible','off')
        set(get(ha(i),'children'),'Visible','off');
        axis(ha(i),'off');
        
    end
end

pagenumber = uicontrol('Parent',d,...
    'BackgroundColor',[.1 .1 .1],...
    'ForegroundColor','w',...
    'Style','text',...
    'String',['Page ' char(string(page)) ' of ' char(string(ceil(count(k) / length(ha))))],...
    'Position',[118 509 80 30],...
    'HorizontalAlignment','center');

% Wait for d to close before running to completion
set( findall(d, '-property', 'Units' ), 'Units', 'Normalized')
d.Visible = 'on';
uiwait(d);
NewclusterName = clusterName;
NewRejected = rejected;
NewFinished = finished;
clearvars -global



    function txtbox_Callback(hObject, eventdata, handles)
        clusterName(k) = get(hObject,'String');
    end









end
function redo_Callback(hObject, eventdata, handles)
global finished
finished = 0;
delete(gcf)
end

function apply_Callback(hObject, eventdata, handles)
global finished
finished = 1;
delete(gcf)
end

function plotimages
global k clustAssign clusters rejected ClusteringData minfreq d ha ColorData handle_image page
clustIndex = find(clustAssign==clusters(k));


for i=1:length(ha)
    if i <= length(clustIndex) - (page - 1)*length(ha)
        set(ha(i),'Visible','off')
        set(get(ha(i),'children'),'Visible','on');
        callID = i + (page - 1)*length(ha);
        im = imresize(ClusteringData{clustIndex(callID),1},[60 100]);
        freqdata = round(linspace(ClusteringData{clustIndex(callID),2} + ClusteringData{clustIndex(callID),9},ClusteringData{clustIndex(callID),2},60));
        colorIM(:,:,1) =  single(im).*.0039.*ColorData(freqdata - minfreq,1);
        colorIM(:,:,2) =  single(im).*.0039.*ColorData(freqdata - minfreq,2);
        colorIM(:,:,3) =  single(im).*.0039.*ColorData(freqdata - minfreq,3);
        %
        %     ha(i) = axes(d,'Units','Normalized','Position',[pos(i,2),pos(i,1),.14,.14]);
        %     handle_image(i) = image(colorIM + .5 .* rejected(clustIndex(i)),'parent',ha(i));
        set(handle_image(i), 'ButtonDownFcn',{@clicked,clustIndex(callID),i});
        if rejected(clustIndex(callID))
            colorIM(:,:,1) = colorIM(:,:,1) + .5;
        end
        set(handle_image(i),'CData',colorIM);
    else
        set(ha(i),'Visible','off')
        set(get(ha(i),'children'),'Visible','off');
    end
    
end

end

function clicked(hObject,eventdata,i,plotI)
global k clustAssign clusters rejected ClusteringData minfreq d ha ColorData handle_image
rejected(i) = ~rejected(i);
im = imresize(ClusteringData{i,1},[60 100]);
freqdata = round(linspace(ClusteringData{i,2} + ClusteringData{i,9},ClusteringData{i,2},60));
colorIM(:,:,1) =  single(im).*.0039.*ColorData(freqdata - minfreq,1);
colorIM(:,:,2) =  single(im).*.0039.*ColorData(freqdata - minfreq,2);
colorIM(:,:,3) =  single(im).*.0039.*ColorData(freqdata - minfreq,3);

set(handle_image(plotI),'CData',(colorIM + .5 .* rejected(i)));

if rejected(i)
    colorIM(:,:,1) = colorIM(:,:,1) + .5;
end
set(handle_image(plotI),'CData',colorIM);

set(handle_image(plotI), 'ButtonDownFcn',{@clicked,i,plotI});

end

function next_Callback(hObject, eventdata, handles)
global k d txtbox totalCount count clusterName pagenumber page ha
clusterName(k) = get(txtbox,'String');
if k < length(clusterName)
    k = k+1;
    page = 1;
    pagenumber.String = ['Page ' char(string(page)) ' of ' char(string(ceil(count(k) / length(ha))))];
    plotimages
end

set(txtbox,'string',string(clusterName(k)))
set(totalCount,'string',['total count:' char(string(count(k)))])
set(d,'name',['Cluster ' num2str(k) ' of ' num2str(length(count))])
end

function back_Callback(hObject, eventdata, handles)
global k d txtbox totalCount count clusterName pagenumber page ha
clusterName(k) = get(txtbox,'String');
if k > 1
    k = k-1;
    page = 1;
    pagenumber.String = ['Page ' char(string(page)) ' of ' char(string(ceil(count(k) / length(ha))))];
    plotimages
end

set(txtbox,'string',string(clusterName(k)))
set(totalCount,'string',['total count:' char(string(count(k)))])
set(d,'name',['Cluster ' num2str(k) ' of ' num2str(length(count))])
end

function nextpage_Callback(hObject, eventdata, handles)
global page pagenumber count k ha
if page < ceil(count(k) / length(ha))
    page = page + 1;
    pagenumber.String = ['Page ' char(string(page)) ' of ' char(string(ceil(count(k) / length(ha))))];
    plotimages
end
end

function backpage_Callback(hObject, eventdata, handles)
global page pagenumber count k ha
if page > 1
    page = page - 1;
    pagenumber.String = ['Page ' char(string(page)) ' of ' char(string(ceil(count(k) / length(ha))))];
    plotimages
end
end

function windowclosed(hObject, eventdata, handles)
global finished
finished = 2;
delete(hObject)
end