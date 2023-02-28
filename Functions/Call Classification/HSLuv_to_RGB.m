function RGB = HSLuv_to_RGB(varargin)
%{

RGB = HSLuv_to_RGB(HSV)
    Returns RGB values for an n by 3 matrix of [H, S, L] values.

RGB = HSLuv_to_RGB(n)
    Returns n columns of RGB values for a pastel colormap.

RGB = HSLuv_to_RGB([n], 'H',H, 'S',S, 'L',L)
    Returns n columns of RGB values for linearly spaced values of H, S, and V.
    H, S, and V may be scalers or 1x2 vectors.
    Hue is expressed in degrees, saturation and lightness scale between 0 and 100.

RGB = HSLuv_to_RGB(___, 'type', 'HSL')
    HSLuv scales chroma as an relative percent for each color.

RGB = HSLuv_to_RGB(___, 'type', 'HPL')
    HPLuv scales chroma as an absolute percent of the minumum chroma of all colors. 


2013 Marc van Wanrooij (marcvanwanrooij@neural-code.com)
modified by Pierre Morel 2016

modified by Ruby Marx 2019, Based on http://www.hsluv.org/
%}

p = inputParser;
p.addOptional('HSL_or_ncol',16); % Number of columns, or an n by 3 matrix of [H, S, L] values.
p.addParameter('H',[25, 385]); % Hue range, scaler or [min, max]
p.addParameter('L',70); % Lightness range, scaler or [min, max]
p.addParameter('S',100); % Saturation range, scaler or [min, max]
p.addParameter('colorspace', 'sRGB', @(x) any(validatestring(x,{'sRGB','adobeRGB','adobeWideRGB'})));
p.addParameter('type', 'HSL', @(x) any(validatestring(x,{'HSL','HPL'}))); %HSL stretches chroma to max, HPL uses max chroma without distortion
p.addParameter('plot', 'none', @(x) any(validatestring(x,{'none','surface','scatter','image'})));
p.parse(varargin{:});


if size(p.Results.HSL_or_ncol, 2) == 3 % If HSL is given as a vector
    H = p.Results.HSL_or_ncol(:,1);
    S = p.Results.HSL_or_ncol(:,2);
    L = p.Results.HSL_or_ncol(:,3);
else
    H = linspace(p.Results.H(1), p.Results.H(end), p.Results.HSL_or_ncol);
    S = linspace(p.Results.S(1), p.Results.S(end), p.Results.HSL_or_ncol);
    L = linspace(p.Results.L(1), p.Results.L(end), p.Results.HSL_or_ncol);
end

% [H,S,L] = meshgrid(H,S,L);
H = reshape(H,[],1);
S = reshape(S,[],1);
L = reshape(L,[],1);




%% Select RGB Colorspace
switch p.Results.colorspace
    case 'adobeRGB'
        T = [ 2.0413690, -0.5649464, -0.3446944
            -0.9692660,  1.8760108,  0.0415560
            0.0134474, -0.1183897,  1.0154096];
        gammaFcn = @(u) u .^ (256 / 563);
        whitePoint = [0.9504, 1.0000, 1.0888]; % D65
    case 'sRGB'
        T = [3.2406, -1.5372, -0.4986
            -0.9689, 1.8758, 0.0415
            0.0557, -0.2040, 1.0570];
        gammaFcn = @(u) ((u > 0.0031307) * 1.055 .* u .^ (1 / 2.4) - 0.055) + ((u <= 0.0031307) * 12.92 .* u);
        whitePoint = [0.9504, 1.0000, 1.0888]; % D65
    case 'adobeWideRGB'
        T = [1.4625, -0.1845, -0.2734
            -0.5228, 1.4479, 0.0681
            0.0346, 0.0958, 1.2875];
        gammaFcn = @(u) u .^ (256 / 563);
        whitePoint = [0.9642, 1.0000, 0.8251]; % D50
end
    
epsilon = 216 / 24389;
kappa = 24389 / 27;



%% Find the Maximum chroma value and scale saturation by max chroma
X = ((L + 16) / 116) .^ 3;

X(X <= epsilon) = L(X <= epsilon) / kappa;

top1 = [284517, -94839] * T(:,[1,3])' .* X;
top1 = [top1, top1];

top2 = [731718, 769860, 838422] * T' .* L .* X;
top2 = [top2, top2 - 769860 .* L];

bottom = [632260, -126452] * T(:,[3,2])' .* X;
bottom = [bottom, bottom + 126452];

% Slope and intercept of the lines bounding the gamut
slope =  top1 ./ bottom;
intercept = top2 ./ bottom;

% Intersection between the S and the chroma bound
chromaMax = intercept ./ (sind(H) - slope .* cosd(H));
chromaMax(chromaMax < 0) = Inf;

switch p.Results.type
    case 'HSL'
        chromaMax = min(chromaMax, [], 2);
    case 'HPL'
        chromaMax = min(min(chromaMax));
end
C = S .* chromaMax ./ 100;
C(isnan(C)) = 0;
C(L == 100) = 0;
C(L == 0)   = 0;


%% Convert CIE L*CH to CIE L*ab
a = cosd(H) .* C;
b = sind(H) .* C;

%% L*ab -> XYZ from http://www.brucelindbloom.com/index.html?Eqn_Lab_to_XYZ.html
f_y = (L + 16) / 116;
f_x	= f_y + a / 500;
f_z	= f_y - b / 200;

X = f_x .^ 3;
sel = X <= epsilon;
X(sel) = (116 * f_x (sel) - 16) / kappa;

Y = ((L + 16) / 116) .^ 3;
sel = L <= kappa * epsilon;
Y(sel) = L(sel) / kappa;

Z = f_z .^ 3;
sel = f_z <= epsilon;
Z(sel) = (116 * f_z(sel) - 16) / kappa;

XYZ = [X, Y, Z];

%% Reference white point
XYZ = XYZ .* whitePoint;

%% XYZ -> RGB
RGB = XYZ * T';

%% Clamp RGB Between 0 and 1 and apply gamma
RGB = max(RGB,0);
RGB = gammaFcn(RGB);
RGB = min(RGB,1);
RGB = max(RGB,0);

%% Plot the output
switch p.Results.plot
    case 'surface'
        figure('Color','w')
        k = boundary(a,b,L);
        trisurf(k,a,b,L,'FaceColor','interp',...
            'FaceVertexCData',RGB,'EdgeColor','none')
        xlabel('a*')
        ylabel('b*')
        zlabel('L*')
    case 'scatter'
        figure('Color','w')
        scatter3(a,b,L,10,RGB,'filled')
        xlabel('a*')
        ylabel('b*')
        zlabel('L*')
    case 'image'
        figure('Color','w')
        image(reshape(RGB,[],1,3))
end

