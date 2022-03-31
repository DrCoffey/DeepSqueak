function [ClRdg,RwRdg] = e_CntMap(I, rt, rf)
% Ridge, river and edge detection. 
% From 'Rapid Contour Detection for Image Classification'
% http://digital-library.theiet.org/content/journals/10.1049/iet-ipr.2017.1066
% DOI 10.1049/iet-ipr.2017.1066
% https://www.researchgate.net/publication/321218540_Rapid_Contour_Detection_for_Image_Classification
[m n] 	= size(I);
Bns   	= [1:200];  	% bins for histogramming contrast

%% -----    Parameters
s       = 1 ;       % search radius
minCtr  = 0.2;

%% ------------------   Subimages & Indices     -----------------
rr	= s+1:m-s;      rrN	= rr-s;     rrS = rr+s;
cc 	= s+1:n-s;      ccE = cc+s;     ccW = cc-s;
CEN	= I(rr,	cc);                        % center
NN 	= I(rrN,cc);   	SS = I(rrS,cc);  	% north, south
EE  = I(rr, ccE);  	WW = I(rr, ccW);   	% east, west
NE  = I(rrN,ccE);  	SE = I(rrS,ccE);   	% north east, south east
SW  = I(rrS,ccW);  	NW = I(rrN,ccW);   	% south west, north west

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                  R I D G E S  &  R I V E R S
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% =============	EXTREMA Along Axes & Diagonals
% --- Maxima (counter-clockwise)
MX1     = padarray(CEN>NN & CEN>SS, [s s]);  % max north-south
MX2     = padarray(CEN>NW & CEN>SE, [s s]);  % max diag 1
MX3     = padarray(CEN>WW & CEN>EE, [s s]);  % max west-east
MX4     = padarray(CEN>NE & CEN>SW, [s s]);  % max diag 2
% --- Minima
MN1     = padarray(CEN<NN & CEN<SS, [s s]);  % min north-south
MN2     = padarray(CEN<NE & CEN<SW, [s s]);  % min diag 1
MN3     = padarray(CEN<WW & CEN<EE, [s s]);  % min west-east
MN4     = padarray(CEN<NW & CEN<SE, [s s]);  % min diag 2

Cmax	= uint8(MX1+MX2+MX3+MX4);      % map of maxima count
Cmin    = uint8(MN1+MN2+MN3+MN4);      % map of minima count

%% =============	Suppress Low RR Contrast
R           = colfilt(I,[2 2]+s, 'sliding', @range);    % range image
CtrXtr      = R(logical(Cmax) | logical(Cmin));         % [nExtrema 1]
thrXtr     	= max(CtrXtr)*minCtr;       % threshold for low contrast
Blow       	= R < thrXtr;               % map with low contrast pixels
Cmax(Blow) 	= 0;                        % eliminate low contrast
Cmin(Blow)	= 0;

%% =============	Ridge/River Maps
Mrdg       	= Cmax >= 2;
Mriv       	= Cmin >= 2;

rrr = [rt' rf']; rrr = sub2ind(size(Mrdg),rf, rt);
Mrdg(rrr) = 1;
Mrdg      	= bwmorph(Mrdg, 'clean'); Mrdg = bwmorph(Mrdg, 'spur'); 
Mriv      	= bwmorph(Mriv, 'clean'); Mrdg = bwmorph(Mrdg, 'clean'); 
%Mrdg     	= bwmorph(Mrdg, 'thin', 'inf');
%Mriv     	= bwmorph(Mriv, 'thin', 'inf');

% %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%                          E D G E S
% %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% %% ------------------   Subimages of Range Image
% RCN     = R(rr, cc);        	% center
% Rnn     = R(rrN,cc);          	% north
% Rss     = R(rrS,cc);          	% south
% Ree     = R(rr, ccE);        	% east
% Rww     = R(rr, ccW);        	% west
% Rne     = R(rrN,ccE);           % north east
% Rse     = R(rrS,ccE);           % south east
% Rsw     = R(rrS,ccW);           % south west
% Rnw     = R(rrN,ccW);       	% north west
% 
% %% =================	MAXIMA Along Axes & Diagonals
% RX1     = padarray(RCN>Rnn & RCN>Rss, [s s]);   % max north-south
% RX2     = padarray(RCN>Rnw & RCN>Rse, [s s]);   % max diag 1
% RX3     = padarray(RCN>Rww & RCN>Ree, [s s]);   % max west-east
% RX4     = padarray(RCN>Rne & RCN>Rsw, [s s]);   % max diag 2
% Cedg 	= uint8(RX1+RX2+RX3+RX4);               % maxima count
%     
% %% =================	Suppress Low Contrast
% Cedg        = padarray(Cedg(rr,cc), [s s]);     % blank borders
% BWedg     	= logical(Cedg);
% CtrEdg      = R(BWedg);                 % range value at edge candidates
% 
% thrEdg      = max(CtrEdg)*minCtr*2;     % threshold for low contrast
% BlowEdg     = CtrEdg < thrEdg;          % identify low-contrast edges
% IxEdg       = find(BWedg);              % linear index of edge candidates
% IxLow       = IxEdg(BlowEdg);           
% Cedg(IxLow) = 0;                        % eliminate low contrast
% 
% %% =================	Edge Map (Ridges in RangeImage)
% Medg    	= Cedg >= 2;                
% Medg        = bwmorph(Medg, 'clean');
% Medg        = bwmorph(Medg, 'thin', 'inf');

%% ---------    Plotting    --------
[RwRdg ClRdg]   = find(Mrdg);
% [RwRiv ClRiv]   = find(Mriv);
% [RwEdg ClEdg]   = find(Medg);

% figure(1); clf;
% imagesc(I); hold on;
% plot(ClRdg,RwRdg,'g.');
% plot(ClRiv,RwRiv,'b.');
% plot(ClEdg,RwEdg,'c.');
end

