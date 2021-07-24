function recordingOver=recordAudioFun(settings,toggle,handles)
%% Create input and output objects
% Use the sample rate of your input as the sample rate of your output.

    deviceReader = audioDeviceReader(str2num(settings{2}),round(str2num(settings{2})/8));
    fileWriter = dsp.AudioFileWriter('SampleRate',deviceReader.SampleRate,'Filename',fullfile(handles.data.settings.audiofolder,[settings{4} '.flac']),'FileFormat','FLAC');
    rate = deviceReader.SampleRate;
    windowsize = round(rate * .0024);
    noverlap = round(rate * .0012);
    nfft = round(rate * .0024);
    dispTime=str2num(settings{3});
    
    f1=figure('Color',[.1 .1 .1]);
    audio = deviceReader();
    [~, fr, ti, p] = spectrogram(audio,windowsize,noverlap,nfft,rate,'yaxis');
    timePix=round(dispTime/(ti(2)-ti(1)));
    f=zeros(length(fr),timePix);
    dShift = -length(ti);
    map = inferno(255);
    h=imshow(uint8(floor(f*255)),map);

    if str2num(settings{1})<=0;
        recTime=inf;
    else
        recTime=str2num(settings{1});
    end
    
tic
while ishandle(f1)
    audio = deviceReader();
    fileWriter(audio);
    [~, fr, ti, p] = spectrogram(audio,windowsize,noverlap,nfft,rate,'yaxis');
    p(p==0)=.01;
    p = log10(p);
    p = rescale(imcomplement(abs(p)));
    dataFirstCol = 1;
    dataLastCol = size (f,2);
    dataShiftedFirstCol = 1;
    dataShiftedLastCol = size (f,2);
	dataFirstCol = dataFirstCol + abs(dShift);
	dataShiftedLastCol = dataShiftedLastCol - abs(dShift);
    f(:,dataShiftedFirstCol:dataShiftedLastCol) = f(:,dataFirstCol:dataLastCol);
    f(:,end+dShift+1:end)=flipud(p);
    %imshow(uint8(floor(f*255)),map);
    set(h,'CData',uint8(floor(f*255)));
    title(['Close Figure To Stop Recording | Recording Time: ' num2str(toc)],'Color','white','FontSize',14,'FontWeight','bold');
    drawnow;
    if toc>recTime
       close(f1);
    end
end

release(deviceReader);
release(fileWriter);
recordingOver=1;
end

