function tests = test_background_subtraction
%% Tests for Functions/Background Subtraction
% Run from the repository root with:
%   matlab -batch "addpath(genpath('Functions')); results = runtests('Tests'); disp(table(results)); assert(all([results.Passed]))"
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
% Synthetic recording: white noise, a steady tone at 60 kHz, a band of
% noise near 30 kHz, and one upward sweep that crosses the tone.
rng(1, 'twister');
rate = 250000;
t = (0:1/rate:8 - 1/rate)';
x = 0.002 * randn(size(t));
x = x + 0.02 * sin(2*pi*60000*t);
x = x + bandpass(0.03 * randn(size(t)), [29000 31000], rate);
call = t >= 6.0 & t < 6.05;
x(call) = x(call) + 0.05 * chirp(t(call) - 6.0, 40000, 0.05, 80000);

folder = tempname;
mkdir(folder);
testCase.TestData.folder = folder;
testCase.TestData.rate = rate;
testCase.TestData.audiofile = fullfile(folder, 'synthetic.wav');
audiowrite(testCase.TestData.audiofile, x, rate, 'BitsPerSample', 16);

testCase.TestData.segments = table( ...
    repmat({testCase.TestData.audiofile}, 2, 1), [0.5; 2.0], [1.5; 3.5], ...
    'VariableNames', {'Filename', 'StartTime', 'StopTime'});
testCase.TestData.Background = createBackgroundDefinition(testCase.TestData.segments, 'synthetic');
end

function teardownOnce(testCase)
rmdir(testCase.TestData.folder, 's');
end

%% The definition
function testDefinitionStoresExactAudio(testCase)
bg = testCase.TestData.Background;
rate = testCase.TestData.rate;
verifyEqual(testCase, bg.SampleRate, rate);
verifyEqual(testCase, height(bg.segments), 2);
verifyEqual(testCase, bg.totalDuration, 2.5, 'AbsTol', 2/rate);
expected = audioread(testCase.TestData.audiofile, [0.5*rate + 1, 1.5*rate], 'native');
verifyEqual(testCase, bg.samples{1}, expected);
verifyEqual(testCase, bg.segments.StartSample(1), 0.5*rate + 1);
verifyEqual(testCase, bg.segments.StopSample(1), 1.5*rate);
end

function testOverlappingSegmentsAreMerged(testCase)
segments = table(repmat({testCase.TestData.audiofile}, 3, 1), [0.5; 1.0; 2.0], [1.5; 1.2; 3.5], ...
    'VariableNames', {'Filename', 'StartTime', 'StopTime'});
bg = createBackgroundDefinition(segments, 'overlap');
verifyEqual(testCase, height(bg.segments), 2);
verifyEqual(testCase, bg.id, testCase.TestData.Background.id, 'Same audio must give the same id');
end

function testIdIgnoresNameButNotContent(testCase)
a = createBackgroundDefinition(testCase.TestData.segments, 'another name', 'Notes', 'x');
verifyEqual(testCase, a.id, testCase.TestData.Background.id);
b = createBackgroundDefinition(testCase.TestData.segments, 'synthetic', 'Percentile', 75);
verifyNotEqual(testCase, b.id, testCase.TestData.Background.id);
c = createBackgroundDefinition(testCase.TestData.segments(1,:), 'synthetic');
verifyNotEqual(testCase, c.id, testCase.TestData.Background.id);
end

function testBadSegmentsAreRejected(testCase)
seg = testCase.TestData.segments(1,:);
seg.StopTime = 100;
verifyError(testCase, @() createBackgroundDefinition(seg, 'x'), 'DeepSqueak:background:outOfRange');
seg.StopTime = seg.StartTime;
verifyError(testCase, @() createBackgroundDefinition(seg, 'x'), 'DeepSqueak:background:emptySegment');
seg.Filename = {fullfile(testCase.TestData.folder, 'nope.wav')};
verifyError(testCase, @() createBackgroundDefinition(seg, 'x'), 'DeepSqueak:background:missingAudio');
stereo = fullfile(testCase.TestData.folder, 'stereo.wav');
audiowrite(stereo, zeros(1000, 2), testCase.TestData.rate);
seg = table({stereo}, 0, 0.002, 'VariableNames', {'Filename', 'StartTime', 'StopTime'});
verifyError(testCase, @() createBackgroundDefinition(seg, 'x'), 'DeepSqueak:background:multichannel');
end

%% The background spectrum
function testSpectrumMatchesDirectCalculation(testCase)
% One short stretch, so every frame is used, compared with spectrogram()
% run directly on the same audio.
rate = testCase.TestData.rate;
seg = table({testCase.TestData.audiofile}, 0.5, 1.0, 'VariableNames', {'Filename', 'StartTime', 'StopTime'});
bg = createBackgroundDefinition(seg, 'short');
audio = audioread(testCase.TestData.audiofile, [0.5*rate + 1, 1.0*rate]);
for window = [400, 801]
    [~, ~, ~, p] = spectrogram(audio, window, window - ceil(window/2), window, rate, 'yaxis');
    [B, nFrames] = backgroundSpectrum(bg, window, window, rate);
    verifyEqual(testCase, nFrames, size(p,2));
    verifyEqual(testCase, B, median(p, 2), 'RelTol', 1e-10);
end
end

function testSpectrumIsDeterministic(testCase)
bg = testCase.TestData.Background;
B1 = backgroundSpectrum(bg, 800, 800, testCase.TestData.rate);
clear backgroundSpectrum % empties the cache
B2 = backgroundSpectrum(bg, 800, 800, testCase.TestData.rate);
verifyEqual(testCase, B1, B2);
end

function testSampleRateMismatchIsAnError(testCase)
verifyError(testCase, @() backgroundSpectrum(testCase.TestData.Background, 800, 800, 192000), 'DeepSqueak:background:sampleRate');
end

function testTooLittleNoiseIsAnError(testCase)
seg = table({testCase.TestData.audiofile}, 0.5, 0.52, 'VariableNames', {'Filename', 'StartTime', 'StopTime'});
bg = createBackgroundDefinition(seg, 'tiny');
verifyError(testCase, @() backgroundSpectrum(bg, 800, 800, testCase.TestData.rate), 'DeepSqueak:background:tooShort');
end

%% Applying it
function testNoBackgroundChangesNothing(testCase)
s = complex(rand(5, 4), rand(5, 4));
p = rand(5, 4);
[s2, p2, gain] = applyBackgroundSubtraction([], s, p, 8, 8, 1000);
verifyEqual(testCase, s2, s);
verifyEqual(testCase, p2, p);
verifyEqual(testCase, gain, 1);
end

function testBandsAreRemovedFromHeldOutNoise(testCase)
% Noise from 4 to 5.5 s was not used to build the definition.
rate = testCase.TestData.rate;
bg = testCase.TestData.Background;
audio = audioread(testCase.TestData.audiofile, [4*rate + 1, 5.5*rate]);
window = 800;
[s, f, ~, p] = spectrogram(audio, window, 400, window, rate, 'yaxis');
[s2, p2, gain] = applyBackgroundSubtraction(bg, s, p, window, window, rate);

before = 10*log10(median(p, 2));
after = 10*log10(median(p2, 2));
[~, tone] = min(abs(f - 60000));
band = f > 29500 & f < 30500;
inside = f > 2000 & f < 120000; % away from DC and Nyquist

verifyGreaterThan(testCase, before(tone) - median(before), 20, 'The test signal should contain a strong tone');
verifyGreaterThan(testCase, median(before(band)) - median(before), 10, 'The test signal should contain a noise band');
verifyLessThan(testCase, max(abs(after(inside) - median(after(inside)))), 1.5, 'Every frequency should have the same typical level');
verifyLessThan(testCase, std(after(inside)), 0.5);

% The overall level is kept
verifyEqual(testCase, median(after(inside)), median(before(inside)), 'AbsTol', 1);

% s and p stay consistent with each other, and the gain is what was applied
verifyTrue(testCase, all(isfinite(gain)) && all(gain > 0));
verifyEqual(testCase, p2, p .* gain, 'RelTol', 1e-12);
verifyEqual(testCase, abs(s2).^2 ./ abs(s).^2, repmat(gain, 1, size(s,2)), 'RelTol', 1e-9);
verifyEqual(testCase, angle(s2), angle(s), 'AbsTol', 1e-12);
end

function testCallKeepsItsLevelAboveBackground(testCase)
% Away from the bands, the sweep must stand as far above the noise after
% cleaning as before. Where it crosses the tone, it is reduced, not removed.
rate = testCase.TestData.rate;
bg = testCase.TestData.Background;
window = 800;
audio = audioread(testCase.TestData.audiofile, [5.9*rate + 1, 6.15*rate]);
[~, f, t, p] = spectrogram(audio, window, 400, window, rate, 'yaxis');
[~, p2, gain] = applyBackgroundSubtraction(bg, [], p, window, window, rate);
B = backgroundSpectrum(bg, window, window, rate);

% Sweep is at 50 kHz a quarter of the way through
[~, col] = min(abs(t - (0.1 + 0.0125)));
[~, row] = min(abs(f - 50000));
verifyEqual(testCase, p2(row,col) / (B(row) * gain(row)), p(row,col) / B(row), 'RelTol', 1e-12);
verifyGreaterThan(testCase, 10*log10(p2(row,col) / median(p2(row,:))), 15);

% At the tone the cleaned value is the original scaled by a finite gain
[~, tone] = min(abs(f - 60000));
verifyGreaterThan(testCase, gain(tone), 0);
verifyLessThan(testCase, 10*log10(gain(tone)), -20);
end

function testRowMismatchIsAnError(testCase)
bg = testCase.TestData.Background;
verifyError(testCase, @() applyBackgroundSubtraction(bg, [], rand(10, 3), 800, 800, testCase.TestData.rate), 'DeepSqueak:background:rows');
end

%% The reference level
function testReferenceIsMedianOfAllRows(testCase)
bg = testCase.TestData.Background;
verifyEqual(testCase, bg.formatVersion, 3);
B = backgroundSpectrum(bg, 800, 800, testCase.TestData.rate);
[R, isFloor] = backgroundReference(bg, B, 800, testCase.TestData.rate);
verifyEqual(testCase, R, median(B));
verifyTrue(testCase, all(isFloor));
[~, ~, gain] = applyBackgroundSubtraction(bg, [], rand(401, 3), 800, 800, testCase.TestData.rate);
verifyEqual(testCase, gain, median(B) ./ B, 'RelTol', 1e-12);
end

function testFormat2DefinitionsKeepFloorRowReference(testCase)
% Definitions made while the floor-row rule was in use must still give
% the results they gave then.
rate = 384000; nfft = 1228;
f = (0:nfft/2)' * rate / nfft;
floorLevel = 1e-11 * 10.^(-(f / 192000) * 1.0);
B = floorLevel;
banded = (f > 20000 & f < 24000) | (f > 40000 & f < 45000) | (f > 60000 & f < 65000) | mod(floor(f / 3000), 3) == 0 & f > 80000;
B(banded) = B(banded) * 100;
[R, isFloor] = backgroundReference(struct('formatVersion', 2), B, nfft, rate);
verifyEqual(testCase, isFloor, ~banded);
verifyEqual(testCase, R, median(floorLevel(~banded)), 'RelTol', 1e-12);
verifyEqual(testCase, backgroundReference(struct('formatVersion', 1), B, nfft, rate), median(B));
verifyEqual(testCase, backgroundReference(struct('formatVersion', 3), B, nfft, rate), median(B));
end

%% Flicker scaling
function testFlickerScalingIsOffByDefaultAndPartOfTheId(testCase)
bg = testCase.TestData.Background;
verifyFalse(testCase, bg.flickerScaling);
on = createBackgroundDefinition(testCase.TestData.segments, 'synthetic', 'FlickerScaling', true);
verifyTrue(testCase, on.flickerScaling);
verifyNotEqual(testCase, on.id, bg.id);
verifyTrue(testCase, backgroundInfo(on).flickerScaling);
verifyFalse(testCase, backgroundInfo(bg).flickerScaling);
end

function testFlickerScalingEvensOutFlicker(testCase)
rate = testCase.TestData.rate;
window = 800;
off = testCase.TestData.Background;
on = createBackgroundDefinition(testCase.TestData.segments, 'synthetic', 'FlickerScaling', true);
audio = audioread(testCase.TestData.audiofile, [4*rate + 1, 5.5*rate]);
[s, f, ~, p] = spectrogram(audio, window, 400, window, rate, 'yaxis');
[B, ~, spread] = backgroundSpectrum(on, window, window, rate);
[s1, p1, gain, k] = applyBackgroundSubtraction(on, s, p, window, window, rate);
[~, p0, ~, k0] = applyBackgroundSubtraction(off, [], p, window, window, rate);
verifyEqual(testCase, k0, ones(size(B)));

[~, tone] = min(abs(f - 60000));
ordinary = f > 2000 & f < 120000 & abs(f - 60000) > 3000 & abs(f - 30000) > 3000;

% The exponents: about 1 in random noise, limited to 2 at the steady tone
verifyEqual(testCase, median(spread(ordinary)), 6.83, 'AbsTol', 0.5, 'Random noise has an interquartile range of 6.83 dB');
verifyEqual(testCase, median(k(ordinary)), 1, 'AbsTol', 0.02);
verifyLessThan(testCase, max(abs(k(ordinary) - 1)), 0.2);
verifyEqual(testCase, k(tone), 2);
verifyGreaterThanOrEqual(testCase, min(k), 0.5);
verifyLessThanOrEqual(testCase, max(k), 2);

% Exactly the stated formula, for both outputs, and consistent with a call that has only s
expected = gain .* B .* (p ./ B) .^ k;
verifyEqual(testCase, p1, expected, 'RelTol', 1e-10);
verifyEqual(testCase, abs(s1).^2 ./ abs(s).^2, p1 ./ p, 'RelTol', 1e-9);
verifyEqual(testCase, angle(s1), angle(s), 'AbsTol', 1e-12);
sOnly = applyBackgroundSubtraction(on, s, [], window, window, rate);
verifyEqual(testCase, abs(sOnly), abs(s1), 'RelTol', 1e-6);

% The typical level of every row is unchanged by flicker scaling ...
verifyEqual(testCase, 10*log10(median(p1(ordinary,:), 2)), 10*log10(median(p0(ordinary,:), 2)), 'AbsTol', 0.5);
% ... and the tone row's flicker is doubled, the most the limit allows
flicker = @(q) diff(prctile(10*log10(q(tone,:)), [25 75]));
verifyEqual(testCase, flicker(p1), 2 * flicker(p0), 'RelTol', 1e-9);
end

%% Saving and loading
function testSaveLoadRoundTrip(testCase)
bg = testCase.TestData.Background;
file = fullfile(testCase.TestData.folder, 'roundtrip.mat');
saveBackgroundDefinition(bg, file);
loaded = loadBackgroundDefinition(file);
verifyEqual(testCase, loaded.sourceFile, file);
verifyEqual(testCase, rmfield(loaded, 'sourceFile'), bg);
rate = testCase.TestData.rate;
verifyEqual(testCase, backgroundSpectrum(loaded, 640, 640, rate), backgroundSpectrum(bg, 640, 640, rate));

info = backgroundInfo(loaded);
verifyTrue(testCase, info.used);
verifyEqual(testCase, info.id, bg.id);
verifyEqual(testCase, info.file, file);
verifyFalse(testCase, backgroundInfo([]).used);
end

function testDefinitionsAreNotOverwritten(testCase)
bg = testCase.TestData.Background;
file = fullfile(testCase.TestData.folder, 'once.mat');
saveBackgroundDefinition(bg, file);
verifyError(testCase, @() saveBackgroundDefinition(bg, file), 'DeepSqueak:background:exists');
end

function testAlteredDefinitionIsRejected(testCase)
Background = testCase.TestData.Background;
Background.samples{1}(10) = Background.samples{1}(10) + 1;
file = fullfile(testCase.TestData.folder, 'altered.mat');
save(file, 'Background', '-v7.3');
verifyError(testCase, @() loadBackgroundDefinition(file), 'DeepSqueak:background:corrupt');
verifyError(testCase, @() saveBackgroundDefinition(Background, fullfile(testCase.TestData.folder, 'altered2.mat')), 'DeepSqueak:background:corrupt');

notOne = fullfile(testCase.TestData.folder, 'other.mat');
x = 1; save(notOne, 'x');
verifyError(testCase, @() loadBackgroundDefinition(notOne), 'DeepSqueak:background:notDefinition');
verifyError(testCase, @() loadBackgroundDefinition(fullfile(testCase.TestData.folder, 'absent.mat')), 'DeepSqueak:background:missing');
end

%% Noise stretches marked as boxes
function testSegmentsFromDetectionFile(testCase)
audiodata = audioinfo(testCase.TestData.audiofile);
Calls = table([0.5 20 1.0 30; 6.0 40 0.05 40; 2.0 10 1.5 5], [1; 1; 1], categorical({'Background'; 'USV'; 'Background'}), true(3,1), ...
    'VariableNames', {'Box', 'Score', 'Type', 'Accept'});
file = fullfile(testCase.TestData.folder, 'marked.mat');
save(file, 'Calls', 'audiodata', '-v7.3');

[segments, labels] = backgroundSegmentsFromDetections(file);
verifyEmpty(testCase, segments);
verifyEqual(testCase, sort(labels(:)), {'Background'; 'USV'});

segments = backgroundSegmentsFromDetections(file, 'Background');
verifyEqual(testCase, segments.StartTime, [0.5; 2.0]);
verifyEqual(testCase, segments.StopTime, [1.5; 3.5]);
verifyEqual(testCase, segments.Source, {'marked.mat'; 'marked.mat'});
bg = createBackgroundDefinition(segments, 'from boxes');
verifyEqual(testCase, backgroundSources(bg).Source, {'marked.mat'});
verifyEqual(testCase, bg.id, testCase.TestData.Background.id);
end

%% Adding and removing a file's worth of noise
function testAddAndRemoveSources(testCase)
rate = testCase.TestData.rate;
folder = fullfile(testCase.TestData.folder, 'sources'); mkdir(folder);
rng(3, 'twister');
audio = cell(1, 3);
for i = 1:3
    audio{i} = fullfile(folder, sprintf('rec%d.wav', i));
    audiowrite(audio{i}, 0.01 * randn(2 * rate, 1), rate, 'BitsPerSample', 16);
end
seg = @(i, name) table(repmat(audio(i), 2, 1), [0.1; 1.0], [0.6; 1.7], repmat({name}, 2, 1), ...
    'VariableNames', {'Filename', 'StartTime', 'StopTime', 'Source'});
A = seg(1, 'marksA.mat'); B = seg(2, 'marksB.mat'); C = seg(3, 'marksC.mat');

one = createBackgroundDefinition(A, 'rig', 'Percentile', 60, 'Notes', 'n');
two = addToBackgroundDefinition(one, B);
three = addToBackgroundDefinition(two, C);

% The original is untouched and the new ones say where they came from
verifyEqual(testCase, one.id, backgroundHash(one));
verifyEqual(testCase, height(one.segments), 2);
verifyEqual(testCase, two.derivedFrom, one.id);
verifyEqual(testCase, three.derivedFrom, two.id);
verifyEqual(testCase, {three.name, three.percentile, three.notes}, {'rig', 60, 'n'});

% What it is made of
sources = backgroundSources(three);
verifyEqual(testCase, sources.Source, {'marksA.mat'; 'marksB.mat'; 'marksC.mat'});
verifyEqual(testCase, sources.AudioFile, {'rec1.wav'; 'rec2.wav'; 'rec3.wav'});
verifyEqual(testCase, sources.Stretches, [2; 2; 2]);
verifyEqual(testCase, sources.Seconds, [1.2; 1.2; 1.2], 'AbsTol', 3 / rate);
verifyEqual(testCase, three.totalDuration, 3.6, 'AbsTol', 9 / rate);

% Built in steps, in any order, or all at once: the same definition
atOnce = createBackgroundDefinition([C; A; B], 'rig', 'Percentile', 60);
otherOrder = addToBackgroundDefinition(addToBackgroundDefinition(createBackgroundDefinition(C, 'rig', 'Percentile', 60), A), B);
verifyEqual(testCase, three.id, atOnce.id);
verifyEqual(testCase, otherOrder.id, atOnce.id);
verifyEqual(testCase, three.samples, atOnce.samples);
verifyEqual(testCase, backgroundSpectrum(three, 800, 800, rate), backgroundSpectrum(atOnce, 800, 800, rate));

% Removing a source gives what building without it gives
without = removeFromBackgroundDefinition(three, 'marksB.mat');
verifyEqual(testCase, without.id, createBackgroundDefinition([A; C], 'rig', 'Percentile', 60).id);
verifyEqual(testCase, without.derivedFrom, three.id);
verifyEqual(testCase, backgroundSources(without).Source, {'marksA.mat'; 'marksC.mat'});
verifyEqual(testCase, removeFromBackgroundDefinition(three, {'marksB.mat', 'marksC.mat'}).id, one.id);

% Refusals
verifyError(testCase, @() addToBackgroundDefinition(three, B), 'DeepSqueak:background:alreadyIncluded');
partly = table(audio(2), 0.5, 0.9, {'other.mat'}, 'VariableNames', {'Filename', 'StartTime', 'StopTime', 'Source'});
verifyError(testCase, @() addToBackgroundDefinition(three, partly), 'DeepSqueak:background:alreadyIncluded');
verifyError(testCase, @() removeFromBackgroundDefinition(three, 'nope.mat'), 'DeepSqueak:background:unknownSource');
verifyError(testCase, @() removeFromBackgroundDefinition(one, 'marksA.mat'), 'DeepSqueak:background:noSegments');
slow = fullfile(folder, 'slow.wav'); audiowrite(slow, zeros(96000, 1), 96000, 'BitsPerSample', 16);
slowSeg = table({slow}, 0.1, 0.6, 'VariableNames', {'Filename', 'StartTime', 'StopTime'});
verifyError(testCase, @() addToBackgroundDefinition(three, slowSeg), 'DeepSqueak:background:sampleRate');

% Saved and reloaded, a changed definition verifies like any other,
% and one loaded from disk can itself be changed
file = fullfile(folder, 'three.mat');
saveBackgroundDefinition(three, file);
loaded = loadBackgroundDefinition(file);
verifyEqual(testCase, loaded.id, three.id);
verifyEqual(testCase, removeFromBackgroundDefinition(loaded, 'marksC.mat').id, two.id);

% A definition saved before sources were recorded: the source is the audio file
old = one; old.segments.Source = [];
verifyEqual(testCase, backgroundSources(old).Source, {'rec1.wav'});
verifyEqual(testCase, addToBackgroundDefinition(old, B).id, two.id);
end

function testSwitchingRecordingsToAChangedDefinition(testCase)
rate = testCase.TestData.rate;
folder = fullfile(testCase.TestData.folder, 'repoint');
bg = testCase.TestData.Background;
other = createBackgroundDefinition(testCase.TestData.segments(1,:), 'other');
rng(4, 'twister');
recs = cell(1, 3);
for i = 1:3
    recs{i} = fullfile(testCase.TestData.folder, sprintf('repoint_rec%d.wav', i));
    audiowrite(recs{i}, 0.01 * randn(rate, 1), rate, 'BitsPerSample', 16);
end
assignBackground(recs(1:2), bg, folder);
assignBackground(recs(3), other, folder);

extra = table({recs{3}}, 0.1, 0.6, 'VariableNames', {'Filename', 'StartTime', 'StopTime'});
changed = addToBackgroundDefinition(bg, extra);
[count, names] = repointBackgroundAssignments(folder, bg.id, []);
verifyEqual(testCase, count, 2);
verifyEqual(testCase, sort(names), {'repoint_rec1.wav', 'repoint_rec2.wav'});
verifyEqual(testCase, backgroundForAudio(recs{1}, folder).id, bg.id, 'Counting must not change anything');

file = fullfile(folder, 'changed.mat');
saveBackgroundDefinition(changed, file);
verifyEqual(testCase, repointBackgroundAssignments(folder, bg.id, loadBackgroundDefinition(file)), 2);
verifyEqual(testCase, backgroundForAudio(recs{1}, folder).id, changed.id);
verifyEqual(testCase, backgroundForAudio(recs{2}, folder).id, changed.id);
verifyEqual(testCase, backgroundForAudio(recs{3}, folder).id, other.id, 'Recordings on another definition are left alone');
verifyEqual(testCase, repointBackgroundAssignments(folder, bg.id, []), 0);
end

%% Pointing recordings at a definition
function testAssignmentsArePerRecording(testCase)
bg = testCase.TestData.Background;
rate = testCase.TestData.rate;
folder = fullfile(testCase.TestData.folder, 'bgfolder_a');

% Three recordings in three places; two get the background
elsewhere = fullfile(testCase.TestData.folder, 'elsewhere'); mkdir(elsewhere);
second = fullfile(elsewhere, 'second.wav');
third = fullfile(elsewhere, 'third.wav');
rng(2, 'twister');
audiowrite(second, 0.01 * randn(rate, 1), rate, 'BitsPerSample', 16);
audiowrite(third, 0.01 * randn(rate, 1), rate, 'BitsPerSample', 16);

written = assignBackground({testCase.TestData.audiofile, second}, bg, folder);
verifyEqual(testCase, numel(written), 2);
verifyTrue(testCase, all(cellfun(@isfile, written)));
verifyTrue(testCase, all(startsWith(written, folder)), 'Nothing may be written beside the audio');

[found, assignment] = backgroundForAudio(testCase.TestData.audiofile, folder);
verifyEqual(testCase, found.id, bg.id);
verifyEqual(testCase, assignment.backgroundId, bg.id);
verifyEqual(testCase, backgroundForAudio(audioinfo(second), folder).id, bg.id);
verifyEmpty(testCase, backgroundForAudio(third, folder));

% The definition was copied into the folder once
definitions = dir(fullfile(folder, '*.mat'));
definitions = definitions(~endsWith({definitions.name}, '_background.mat'));
verifyEqual(testCase, numel(definitions), 1);

% It is still found after being renamed
movefile(fullfile(folder, definitions.name), fullfile(folder, 'renamed.mat'));
verifyEqual(testCase, backgroundForAudio(second, folder).id, bg.id);

% A second definition for one recording replaces the first, for that recording only
other = createBackgroundDefinition(testCase.TestData.segments, 'other', 'Percentile', 90);
assignBackground(second, other, folder);
verifyEqual(testCase, backgroundForAudio(second, folder).id, other.id);
verifyEqual(testCase, backgroundForAudio(testCase.TestData.audiofile, folder).id, bg.id);

% Removing
verifyTrue(testCase, removeBackgroundAssignment(second, folder));
verifyEmpty(testCase, backgroundForAudio(second, folder));
verifyFalse(testCase, removeBackgroundAssignment(second, folder));

% A folder that does not exist means no recording has a background
verifyEmpty(testCase, backgroundForAudio(second, fullfile(testCase.TestData.folder, 'no such folder')));
end

function testBrokenAssignmentsFailLoudly(testCase)
bg = testCase.TestData.Background;
rate = testCase.TestData.rate;
folder = fullfile(testCase.TestData.folder, 'bgfolder_b');

% Wrong sample rate: refused, and nothing is assigned
slow = fullfile(testCase.TestData.folder, 'slow.wav');
audiowrite(slow, zeros(1000, 1), 96000, 'BitsPerSample', 16);
verifyError(testCase, @() assignBackground({testCase.TestData.audiofile, slow}, bg, folder), 'DeepSqueak:background:sampleRate');
verifyEmpty(testCase, backgroundForAudio(testCase.TestData.audiofile, folder));

% A different recording that happens to share the name
assignBackground(testCase.TestData.audiofile, bg, folder);
impostorFolder = fullfile(testCase.TestData.folder, 'impostor'); mkdir(impostorFolder);
impostor = fullfile(impostorFolder, 'synthetic.wav');
audiowrite(impostor, zeros(rate, 1), rate, 'BitsPerSample', 16);
verifyError(testCase, @() backgroundForAudio(impostor, folder), 'DeepSqueak:background:wrongRecording');

% The definition has gone missing: an error, not "no background"
definitions = dir(fullfile(folder, '*.mat'));
definitions = definitions(~endsWith({definitions.name}, '_background.mat'));
delete(fullfile(folder, definitions.name));
verifyError(testCase, @() backgroundForAudio(testCase.TestData.audiofile, folder), 'DeepSqueak:background:definitionMissing');
end

%% Integration with DeepSqueak
function testCreateFocusSpectrogramUsesActiveBackground(testCase)
% The same call, with and without an active background, through the
% function that feeds statistics, export and clustering.
bg = testCase.TestData.Background;
call = table([6.0 35 0.05 50], 1, categorical({'USV'}), true, 'VariableNames', {'Box', 'Score', 'Type', 'Accept'});
reader = squeakData([]);
reader.audiodata = audioinfo(testCase.TestData.audiofile);
handles = struct('data', squeakData([]));

% A recording whose background has not been looked up must not be processed
verifyError(testCase, @() CreateFocusSpectrogram(call, handles, true, [], reader), 'DeepSqueak:background:unresolved');

reader.background = [];
[I0, window, ~, nfft, rate, ~, s0, ~, ~, ~, p0] = CreateFocusSpectrogram(call, handles, true, [], reader);
reader.background = bg;
[I1, ~, ~, ~, ~, ~, s1, fr, ~, ~, p1] = CreateFocusSpectrogram(call, handles, true, [], reader);

% Opening another recording forgets the background
reader.audiodata = audioinfo(testCase.TestData.audiofile);
verifyEqual(testCase, reader.background, 'unresolved');
reader.audiodata = [];
verifyEmpty(testCase, reader.background);

B = backgroundSpectrum(bg, window, nfft, rate);
gain = backgroundReference(bg, B, nfft, rate) ./ B;
rows = find(fr/1000 >= 35, 1) : find(fr/1000 <= 85, 1, 'last');
verifyEqual(testCase, p1, p0 .* gain(rows), 'RelTol', 1e-12);
verifyEqual(testCase, I1, I0 .* sqrt(gain(rows)), 'RelTol', 1e-12);
verifyEqual(testCase, abs(s1), abs(s0) .* sqrt(gain), 'RelTol', 1e-12);

% The tone no longer captures the contour
[~, ridge0] = max(I0, [], 1);
[~, ridge1] = max(I1, [], 1);
toneRow = find(abs(fr(rows) - 60000) == min(abs(fr(rows) - 60000)), 1);
verifyGreaterThan(testCase, mean(abs(ridge0 - toneRow) <= 1), mean(abs(ridge1 - toneRow) <= 1));
end

function testDetectionUnchangedWithoutBackground(testCase)
% With no background, detection must give exactly what upstream gives.
squeakfolder = fileparts(fileparts(mfilename('fullpath')));
[status, upstream] = system(sprintf('git -C "%s" show 465db14:Functions/SqueakDetect.m', squeakfolder));
assumeEqual(testCase, status, 0, 'git or the upstream baseline commit is not available');
upstream = strrep(upstream, 'Calls=SqueakDetect(', 'Calls=SqueakDetect_upstream(');
fid = fopen(fullfile(testCase.TestData.folder, 'SqueakDetect_upstream.m'), 'w');
fwrite(fid, upstream); fclose(fid);
addpath(testCase.TestData.folder);
testCase.addTeardown(@() rmpath(testCase.TestData.folder));

audiofile = fullfile(squeakfolder, 'Audio', 'Example Rat Recording.flac');
networkname = '2025.02.04.Rat.YoloR2.mat';
network = load(fullfile(squeakfolder, 'Networks', networkname));
Settings = [10; 100; 18; 0; 1];

expected = SqueakDetect_upstream(audiofile, network, 'Example Rat Recording.flac', Settings, 1, 1, networkname);
actual = SqueakDetect(audiofile, network, 'Example Rat Recording.flac', Settings, 1, 1, networkname);
verifyGreaterThan(testCase, height(expected), 0, 'The example should contain calls');
verifyEqual(testCase, actual, expected);
end
