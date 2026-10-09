function Background = createBackgroundDefinition(segments, name, varargin)
%% Build a background definition from stretches of audio that contain noise only
% A background definition is a self-contained, immutable record of what
% "background" means for one recording apparatus. It stores the raw audio of
% the chosen noise-only stretches, so the background spectrum can be
% recomputed exactly for any spectrogram resolution, on any machine, even if
% the source recordings move. See docs/BACKGROUND_SUBTRACTION.md.
%
% segments   table (or struct array) with variables:
%              Filename   - audio file containing the stretch
%              StartTime  - start of the stretch (s)
%              StopTime   - end of the stretch (s)
%              Source     - optional: where the stretch was marked, usually
%                           the name of the file of boxed noise. Stretches
%                           are added to and removed from a definition one
%                           source at a time. Defaults to the audio file name.
%            Stretches may come from several files, but all files must be
%            single channel and share one sample rate.
% name       short descriptive name, e.g. 'Rig 3 chambers 1-4 2024-11'
%
% Optional name-value pairs:
%   'Percentile'  percentile of the noise power taken at each frequency
%                 (default 50 = median, robust to brief transients)
%   'FlickerScaling'  true to also make every frequency flicker by the
%                 same amount (default false). See backgroundExponent.
%   'Notes'       free text stored with the definition
%
% The same stretches give the same definition id whatever order they are
% listed in. To change the stretches of an existing definition, see
% addToBackgroundDefinition and removeFromBackgroundDefinition.

p = inputParser;
addRequired(p, 'name', @(x) (ischar(x) || isstring(x)) && strlength(x) > 0);
addParameter(p, 'Percentile', 50, @(x) isnumeric(x) && isscalar(x) && x > 0 && x < 100);
addParameter(p, 'FlickerScaling', false, @(x) isscalar(x) && (islogical(x) || ismember(x, [0 1])));
addParameter(p, 'Notes', '', @(x) ischar(x) || isstring(x));
parse(p, name, varargin{:});

if isstruct(segments)
    segments = struct2table(segments, 'AsArray', true);
end
required = {'Filename', 'StartTime', 'StopTime'};
if ~istable(segments) || ~all(ismember(required, segments.Properties.VariableNames))
    error('DeepSqueak:background:badSegments', 'segments must be a table with variables Filename, StartTime and StopTime.');
end
if isempty(segments)
    error('DeepSqueak:background:noSegments', 'No noise segments were given.');
end
segments.Filename = cellstr(string(segments.Filename));
if ismember('Source', segments.Properties.VariableNames)
    segments.Source = cellstr(string(segments.Source));
else
    [~, names, exts] = cellfun(@fileparts, segments.Filename, 'UniformOutput', false);
    segments.Source = strcat(names, exts);
end

%% Convert times to sample ranges, one audio file at a time, in a fixed order
files = unique(segments.Filename);
Filename = {}; Source = {}; StartSample = []; StopSample = []; FileTotalSamples = []; FileBytes = [];
SampleRate = [];
for i = 1:length(files)
    if ~isfile(files{i})
        error('DeepSqueak:background:missingAudio', 'Audio file not found: %s', files{i});
    end
    info = audioinfo(files{i});
    if info.NumChannels ~= 1
        error('DeepSqueak:background:multichannel', ...
            'Background definitions only support single channel audio. %s has %d channels.', files{i}, info.NumChannels);
    end
    if isempty(SampleRate)
        SampleRate = info.SampleRate;
    elseif info.SampleRate ~= SampleRate
        error('DeepSqueak:background:sampleRate', ...
            'All noise segments must share one sample rate. %s is %g Hz, expected %g Hz.', files{i}, info.SampleRate, SampleRate);
    end

    rows = find(strcmp(segments.Filename, files{i}));
    ranges = [round(segments.StartTime(rows) * SampleRate) + 1, round(segments.StopTime(rows) * SampleRate)];
    if any(ranges(:,1) < 1 | ranges(:,2) > info.TotalSamples)
        error('DeepSqueak:background:outOfRange', 'A noise segment extends beyond the audio in %s.', files{i});
    end
    if any(ranges(:,2) <= ranges(:,1))
        error('DeepSqueak:background:emptySegment', 'A noise segment in %s has no duration.', files{i});
    end

    % Merge overlapping stretches so that no audio is counted twice. A
    % merged stretch keeps the source of its earliest part.
    [ranges, order] = sortrows(ranges);
    sources = segments.Source(rows(order));
    merged = ranges(1,:);
    mergedSource = sources(1);
    for j = 2:size(ranges,1)
        if ranges(j,1) <= merged(end,2) + 1
            merged(end,2) = max(merged(end,2), ranges(j,2));
        else
            merged = [merged; ranges(j,:)];
            mergedSource = [mergedSource; sources(j)];
        end
    end

    n = size(merged,1);
    d = dir(files{i});
    Filename = [Filename; repmat(files(i), n, 1)];
    Source = [Source; mergedSource];
    StartSample = [StartSample; merged(:,1)];
    StopSample = [StopSample; merged(:,2)];
    FileTotalSamples = [FileTotalSamples; repmat(info.TotalSamples, n, 1)];
    FileBytes = [FileBytes; repmat(d.bytes, n, 1)];
end

%% Read the audio in its native integer format, which is exact and compact
samples = cell(length(Filename), 1);
sampleClass = '';
for i = 1:length(Filename)
    x = audioread(Filename{i}, [StartSample(i), StopSample(i)], 'native');
    if ~ismember(class(x), {'int16', 'int32'})
        error('DeepSqueak:background:sampleFormat', ...
            'Unsupported sample format "%s" in %s. Use 16, 24 or 32 bit integer audio.', class(x), Filename{i});
    end
    if isempty(sampleClass)
        sampleClass = class(x);
    elseif ~strcmp(sampleClass, class(x))
        error('DeepSqueak:background:sampleFormat', 'All noise segments must share one sample format.');
    end
    samples{i} = x;
end

%% Assemble the definition
Background = struct();
Background.formatVersion = 3; % See backgroundReference for what each format means
Background.name = char(p.Results.name);
Background.notes = char(p.Results.Notes);
Background.created = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
Background.SampleRate = SampleRate;
Background.percentile = p.Results.Percentile;
Background.flickerScaling = logical(p.Results.FlickerScaling);
Background.method = 'dB scale: cleaned = R + k(f) * (p - B(f)); R = median of B over all rows; k = 1, or with flicker scaling median spread / spread(f) limited to 0.5-2';
Background.segments = table(Filename, Source, StartSample, StopSample, ...
    (StartSample - 1) / SampleRate, StopSample / SampleRate, FileTotalSamples, FileBytes, ...
    'VariableNames', {'Filename', 'Source', 'StartSample', 'StopSample', 'StartTime', 'StopTime', 'FileTotalSamples', 'FileBytes'});
Background.totalDuration = sum(StopSample - StartSample + 1) / SampleRate;
Background.samples = samples;
Background.sampleClass = sampleClass;
Background.software = backgroundSoftwareInfo();
Background.id = backgroundHash(Background);
end
