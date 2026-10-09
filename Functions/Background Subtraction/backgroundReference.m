function [R, isFloor] = backgroundReference(Background, B, nfft, SampleRate)
%% The reference level that cleaned spectrograms are brought to
% Background subtraction multiplies each frequency row by R / B(f). R is
% one number, so it sets the overall level and nothing else.
%
% B        background power spectral density from backgroundSpectrum
% R        reference level, same units as B
% isFloor  true for the rows counted as noise floor (all rows for format 1)
%
% R is the median of B over all rows (formats 1 and 3).
%
% Format 2 definitions, made briefly on 2026-10-08, are the exception and
% keep the rule they were made with so that their results can be
% reproduced: R is the median of B over the floor rows only.
% A row is floor if its background is no more than 3 dB above the local
% baseline, where the baseline is the 25th percentile of the background (in
% dB) within 5 kHz either side of the row. The low percentile keeps the
% baseline on the floor even where bands fill most of that span.

if Background.formatVersion ~= 2
    isFloor = true(size(B));
    R = median(B);
    return
end

baselineSpan = 10000;   % Hz, full width
baselinePercentile = 25;
floorMargin = 3;        % dB

B_dB = 10 * log10(B(:));
rowsInSpan = 2 * floor(baselineSpan / (SampleRate / nfft) / 2) + 1;
rowsInSpan = max(3, min(rowsInSpan, 2 * floor((length(B_dB) - 1) / 2) + 1));
order = max(1, round(baselinePercentile / 100 * rowsInSpan));
baseline = ordfilt2(B_dB, order, ones(rowsInSpan, 1), 'symmetric');

isFloor = reshape(B_dB - baseline <= floorMargin, size(B));
R = median(B(isFloor));
end
