%!
% @brief This script transfers from json to deepsqueak
% @details This script converts from predefined json files to .mat file
%   that can be used in deep squeak

files = dir("json/*.json");
for file = files'
    jsontext = fileread(strcat(file.folder, "/", file.name));
    json_data = jsondecode(jsontext);

    % Type conversion for calls
    Calls = json_data.Calls;
    Box = double(Calls.Box);
    Score = double(Calls.Score);
    Type = categorical(Calls.Type);
    Accept = logical(Calls.Accept);
    Calls = table(Box, Score, Type, Accept);

    % Type conversion for audiodata
    audiodata = json_data.audiodata;
    Filename = char(audiodata.Filename);
    CompressionMethod = char(audiodata.CompressionMethod);
    NumChannels = double(audiodata.NumChannels);
    SampleRate = double(audiodata.SampleRate);
    TotalSamples = double(audiodata.TotalSamples);
    Duration = double(audiodata.Duration);
    % These are doubles in the DeepSqueak.
    % To avoid breaking any code I will also convert them resulting in arrays of doubles encoding ASCI
    Title = double(audiodata.Title);
    Comment = double(audiodata.Comment);
    Artist = double(audiodata.Artist);
    BitsPerSample = double(audiodata.BitsPerSample);
    audiodata = struct("Filename", Filename, "CompressionMethod", ...
        CompressionMethod, "NumChannels", NumChannels, "SampleRate", ...
        SampleRate, "TotalSamples", TotalSamples, "Duration", Duration, ...
        "Title", Title, "Comment", Comment, "Artist", Artist, ...
        "BitsPerSample", BitsPerSample);
    deep_squeak_file_name = strcat("./toDeepSqueak/", ...
        replace(file.name, ".json", ".mat"));
    save(deep_squeak_file_name, "Calls", "audiodata")
end
