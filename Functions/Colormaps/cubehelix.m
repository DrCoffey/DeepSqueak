function [map,lo,hi] = cubehelix(N,start,rots,sat,gamma,irange,domain)
% Generate an RGB colormap of Dave Green's Cubehelix colorscheme. With range and domain control.
%
% (c) 2017 Stephen Cobeldick
%
% Returns a colormap with colors defined by Dave Green's Cubehelix colorscheme.
% The colormap nodes are selected along a tapered helix in the RGB color cube,
% with a continuous increase in perceived intensity. Black-and-white printing
% using postscript results in a monotonically increasing grayscale colorscheme.
%
% This function offers two extra controls over the Cubehelix colorscheme:
%  <irange> specifies the intensity levels of the colormap's endnodes (lightness).
%  <domain> subsamples a part of the helix, so the endnodes are color (not gray).
% These options are both explained in the section below 'Range and Domain'.
%
%%% Syntax:
%  map = cubehelix;
%  map = cubehelix(N);
%  map = cubehelix(N,start,rots,sat,gamma);
%  map = cubehelix(N,start,rots,sat,gamma,irange);
%  map = cubehelix(N,start,rots,sat,gamma,irange,domain);
%  map = cubehelix(N,[start,rots,sat,gamma],...)
%  map = cubehelix([],...)
% [map,lo,hi] = cubehelix(...)
%
% Cubehelix is defined here: http://astron-soc.in/bulletin/11June/289392011.pdf
% For more information and examples: http://www.mrao.cam.ac.uk/~dag/CUBEHELIX/
%
% Note: The original specification (the links above) misnamed the saturation
% option as "hue". In this function the saturation option is named "sat".
%
% See also BREWERMAP RGBPLOT COLORMAP COLORBAR SURF CONTOURF IMAGE CONTOURCMAP JET LBMAP
%
%% Range and Domain %%
%
% Using the default <irange> and <domain> vectors ([0,1]) creates colormaps
% exactly the same as Dave Green's original algorithm: from black to white.
%
% The option <irange> sets the intensity level of the colormap's endnodes:
%  cubehelix(3, [0.5,-1.5,1,1], [0.2,0.8]) % irange=[0.2,0.8]
%  ans = 0.2          0.2          0.2     % <- gray, not black
%        0.62751      0.47498      0.28642
%        0.8          0.8          0.8     % <- gray, not white
%
% The option <domain> sets the sampling window for the Cubehelix, such
% that the tapered-helix does not taper all the way to unsaturated (gray).
% This allows the colormap to end with colors rather than gray shades:
%  cubehelix(3, [0.5,-1.5,1,1], [0.2,0.8], [0.3,0.7]) % domain=[0.3,0.7]
%  ans = 0.020144     0.29948      0.15693 % <- color, not gray shade
%        0.62751      0.47498      0.28642
%        0.91366      0.71351      0.95395 % <- color, not gray shade
%
% The function "colormap_view" demonstrates the effects of these options.
%
%% Examples %%
%
%%% New colors for the COLORMAP example:
% load spine
% image(X)
% colormap(cubehelix)
%
%%% New colors for the SURF example:
% [X,Y,Z] = peaks(30);
% surfc(X,Y,Z)
% colormap(cubehelix([],0.7,-0.7,2,1,[0.2,0.8],[0.4,0.8]))
% axis([-3,3,-3,3,-10,5])
%
%% Input and Output Arguments %%
%
%%% Inputs (*=default):
%  N     = NumericScalar, an integer to define the colormap length.
%        = *[], uses the length of the current figure's colormap.
%  start = NumericScalar, *0.5, the helix's start color (modulus 3): R=1, G=2, B=3.
%  rots  = NumericScalar, *-1.5, the number of R->G->B rotations over the scheme length.
%  sat   = NumericScalar, *1,    controls how saturated the colors are.
%  gamma = NumericScalar, *1,    can be used to emphasize low or high intensity values.
%  irange = NumericVector, *[0,1], range of brightness levels of the scheme's endnodes. Size 1x2.
%  domain = NumericVector, *[0,1], domain of the Cubehelix calculation (endnode positions). Size 1x2.
%
%%% Outputs:
%  map = NumericMatrix, a colormap of RGB values between 0 and 1. Size Nx3
%  lo  = LogicalMatrix, true where <map> values<0 were clipped to 0. Size Nx3
%  hi  = LogicalMatrix, true where <map> values>1 were clipped to 1. Size Nx3
%
% [map,lo,hi] = cubehelix(N, start,rots,sat,gamma, irange, domain)
% OR
% [map,lo,hi] = cubehelix(N, [start,rots,sat,gamma], irange, domain)

%% Input Wrangling %%
%
if nargin==0 || (isnumeric(N)&&isempty(N))
	N = size(get(gcf,'colormap'),1);
else
	assert(isnumeric(N)&&isscalar(N),'First input <N> must be a scalar numeric.')
	assert(isreal(N)&&isfinite(N)&&fix(N)==N,'First input <N> must be real and whole: %g+%gi',N,imag(N))
	N = double(N);
end
%
if N==0
	map = ones(0,3);
	lo = false(0,3);
	hi = false(0,3);
	return
end
%
iss = @(x)isnumeric(x)&&isreal(x)&&isscalar(x)&&isfinite(x);
isn = @(x,n)isnumeric(x)&&isreal(x)&&numel(x)==n&&all(isfinite(x(:)));
%
% Parameters:
if nargin<2
	% Default parameter values.
	start = 0.5;
	rots  = -1.5;
	sat   = 1.5;
	gamma = .65;
elseif nargin<5
	% Parameters are in a vector.
	if nargin>2
		irange = rots;
	end
	if nargin>3
		domain = sat;
	end
	assert(isn(start,4)&&isvector(start),'Second input can be a 1x4 real numeric of parameter values.')
	start = double(start);
	gamma = start(4); sat = start(3); rots = start(2); start = start(1);
else
	% Parameters as individual scalar values.
	assert(iss(start),'Input <start> must be a real scalar numeric.')
	assert(iss(rots), 'Input <rots> must be a real scalar numeric.')
	assert(iss(sat),  'Input <sat> must be a real scalar numeric.')
	assert(iss(gamma),'Input <gamma> must be a real scalar numeric.')
	start=double(start); rots=double(rots); sat=double(sat); gamma=double(gamma);
end
%
% Range:
if any(nargin==[0,1,2,5])
	irange = [0,1];
else
	assert(isn(irange,2),'Input <irange> must be a 1x2 real numeric.')
	irange = double(irange);
end
%
% Domain:
if any(nargin==[0,1,2,3,5,6])
	domain = [0,1];
else
	assert(isn(domain,2),'Input <domain> must be a 1x2 real numeric.')
	domain = double(domain);
end
%
%% Core Function %%
%
vec = linspace(domain(1),domain(2),abs(N)).';
ang = 2*pi * (start/3+1+rots*vec);
csm = [cos(ang),sin(ang)].';
fra = vec.^gamma;
amp = sat .* fra .* (1-fra)/2;
%
tmp = linspace(0,1,abs(N)).'.^gamma;
tmp = irange(1)*(1-tmp) + irange(2)*(tmp);
%
cof = [-0.14861,1.78277;-0.29227,-0.90649;1.97294,0];
%
vec = sign(N)*(1:abs(N)) - min(0,N-1);
for m = abs(N):-1:1
	n = vec(m);
	map(m,:) = tmp(n) + amp(n) * (cof*csm(:,n));
end
%
lo = map<0;
hi = map>1;
map = max(0,min(1,map));
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cubehelix
% Copyright (c) 2017 Stephen Cobeldick
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
% http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and limitations under the License.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%license
