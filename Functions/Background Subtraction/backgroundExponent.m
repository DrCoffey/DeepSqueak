function k = backgroundExponent(Background, spread)
%% Per-row exponent used by flicker scaling, or all ones when it is off
% With flicker scaling, each row's deviations from its own background (in
% dB) are stretched or squeezed so that the row flickers as much as a
% typical row does:
%
%     p_clean [dB] = R [dB] + k(f) * ( p [dB] - B(f) [dB] )
%
% k(f) = typical spread / this row's spread, where spread is the
% interquartile range in dB of the row's noise power and "typical" is the
% median over all rows. A steady tone, which flickers little, gets k > 1.
% A pulsing source gets k < 1. Random noise gets k close to 1.
%
% k is limited to between 1/2 and 2. Without a limit a very steady tone
% would get a very large k, and any small difference between the
% recording and the definition would be magnified without bound.

k = ones(size(spread));
if ~isfield(Background, 'flickerScaling') || ~Background.flickerScaling
    return
end
k = median(spread) ./ spread;
k = min(max(k, 0.5), 2);
end
