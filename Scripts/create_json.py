"""!
    @brief This script prepares labeled calls for DeepSqueak
    @details I was struggling with moving labels from my application to deepsqueak so I prepared
        a script that exports everything to json, before I create the files using matlab.

        The script ends in a main with an example of usage.
"""

import wave
import csv
import json
import pathlib

def get_audio_data(audio_path:pathlib.Path) -> dict:
    """!
        @brief This funtion gets the audio-data to save
        @param audio_path The path to the audio-file
        @return a dict that corresponds to DeepSquaks audio data
    """
    if not isinstance(audio_path, pathlib.Path):
        raise ValueError(f"{audio_path} should have been a pathlib.Path")
    if not audio_path.is_file():
        raise ValueError(f"{audio_path} should have lead to a file")

    with audio_path.open("rb") as audio_file:
        wav_file = wave.open(audio_file, "rb")
        audio_data = {
            "Filename": str(audio_file.name),
            "CompressionMethod": wav_file.getcomptype(),
            "NumChannels": wav_file.getnchannels(),
            "SampleRate": wav_file.getframerate(),
            "TotalSamples": wav_file.getnframes(),
            "Duration": wav_file.getnframes() / wav_file.getframerate(),
            "Title": audio_path.name,
            "Comment" : "",
            "Artist": "",
            "BitsPerSample": wav_file.getsampwidth() * 8
        }
        return audio_data
    
def get_calls(labels_csv:pathlib.Path) -> dict:
    """!
        @brief This file creates the calls from a csv-file
        @param labels_csv the path to the labels
        @return a dict corresponding to DeepSqueaks calls
        @warning Please note that you will have to adapt this to your csv file
    """
    if not isinstance(labels_csv, pathlib.Path):
        raise ValueError(f"{labels_csv} should have been a pathlib.Path")
    if not labels_csv.is_file():
        raise ValueError(f"{labels_csv} should have lead to a file")
    boxes = list()
    scores = list()
    types = list()
    accepts = list()
    with labels_csv.open("r") as csv_file:
        csv_reader = csv.reader(csv_file, delimiter="\t")
        for row in csv_reader:
            begin, end, _ = row
            begin_time = float(begin)
            duration_time = float(end) - float(begin)
            begin_frequency = 0
            length_frequency = 60
            box = [begin_time, begin_frequency, duration_time, length_frequency]
            boxes.append(box)
            scores.append(1.0)
            types.append("Call")
            accepts.append(True)
    calls = {
        "Box": boxes,
        "Score": scores,
        "Type": types,
        "Accept": accepts
    }
    return calls

if __name__ == "__main__":
    source_folder = pathlib.Path("../Annotated audio files")
    destination_folder = pathlib.Path("./json")
    delimiter = "\t"
    for folder in source_folder.iterdir():
        if folder.is_dir():
            json_file_path = destination_folder / (folder.name + ".json")
            with json_file_path.open("w") as json_file:
                audio = get_audio_data(folder / "audio.wav")
                calls = get_calls(folder / "audio_labels.txt")
                to_save = {
                    "audiodata": audio,
                    "Calls": calls,
                }
                # In the intrest of readability let us use indent
                json.dump(to_save, json_file, indent=4)
