# DeepSqueakFeed

This script is made to facilitate the interaction of DeepSqueak with other programs.
To achive this goal we create json files as intermediaries.
This means that if you manage to supply the required data as a json this script will
then transform into the necessary ".mat" files.

## Python sample

The pythons script used to create the json-files is supplied to better understand the creation process.
It works on a folder structure were every "audio.wav" is accompanied by a "audio_labels.txt".
The later file is a tab-seperated value file, containing two time-stamps and a label.
The first time-stamp is the beginning the second the end of the labeled call.
Here is a example for this files content:

```
0.1234  0.5678  call
1.2345  1.6789  call
```

## Contents of the json-file

The json file follows the structure of DeepSqueak ".mat"-files.
This results in a file like example.json

```JSON
{
    "audiodata": {
        "Filename": "..\\Annotated audio files\\example\\audio.wav",
        "CompressionMethod": "NONE",
        "NumChannels": 2,
        "SampleRate": 48000,
        "TotalSamples": 140393039,
        "Duration": 2924.8549791666665,
        "Title": "audio.wav",
        "Comment": "",
        "Artist": "",
        "BitsPerSample": 16
    },
    "Calls": {
        "Box": [
            [
                1801.644187,
                0.0,
                0.14722299999993993,
                60.0
            ],
            [
                1801.79141,
                0.0,
                0.2024309999999332,
                60.0
            ]
        ],
        "Score": [
            1.0,
            1.0
        ],
        "Type": [
            "Call",
            "Call"
        ],
        "Accept": [
            true,
            true
        ]
    }
}
```

Please note that the properties in "Calls" form connected lists.
So "Box", "Score", "Type" and "Accept" need to have the same length.
Now a schema-like json desribing the properties:

```Json
{
    "title": "Data",
    "description": "A set of labeled calls for DeepQeuak",
    "type": "object",
    "properties": {
        "audiodata": {
            "description": "The data describing the wav-file",
            "type": "object",
            "properties": {
                "Filename":{
                    "description": "The full path to the wav-file",
                    "type": "string"
                },
                "CompressionMethod":{
                    "description": "The method used for the compression",
                    "type": "string"
                },
                "NumChannels":{
                    "description": "The number of channels",
                    "type": "number",
                },
                "SampleRate":{
                    "description": "The number of samples per second",
                    "type": "number"
                },
                "TotalSamples":{
                    "description": "The total number of samples in the file",
                    "type": "number"
                },
                "Duration":{
                    "description": "The number of seconds the file runs",
                    "type": "number"
                },
                "Title": "audio.wav":{
                    "description": "The title of the audio-file",
                    "type": "string"
                },
                "Comment":{
                    "description": "A comment on the file",
                    "type": "string"
                },
                "Artist":{,
                    "description": "The artist or rodent that produced the file",
                    "type": "string"
                },
                "BitsPerSample":{
                    "description": "The number of bits per sample",
                    "type": "number"
                },
            }
        },
        "Calls":{
            "description": "The calls that can be found in the wav-file the properties are 4 colums of a table",
            "type": "object",
            "properties": {
                "Box": {
                    "description": "An array of arrays describing the calls as boxes in a spectrogram",
                    "type": "array",
                    "items":{
                        "description": "The boxes are described by their lower-corner and size, so first comes the lowest time, then the lowest frequency, then the extent in time than the extent in frequency.",
                        "type":"array",
                        "items":{
                            "type":"number"
                        }
                    }
                },
                "Score": {
                    "description": "An array describing the confidence that this is a call",
                    "type": "array",
                    "items":{
                        "type":"number"
                    }
                },
                "Type": {
                    "description": "An array defining the type of the call, these are the labels for the network",
                    "type": "array",
                    "items":{
                        "type":"string"
                    }
                },
                "Accept": {
                    "description": "An array (presumably) deteriming if the call will be used for training or not",
                    "type": "array",
                    "items":{
                        "type":"boolean"
                    }
                }
            }
        }
    }
}
```

## Structure of the .mat files

The ".mat"-files used by deep squeak have a rather particular type choice.
In case you do with to create them directly they will be described here.

The file itself contains 3 variables:
- Calls
- audiodata
- detection_metadata

Only "Calls" and **audiodata" are necessary.

### Calls

"Calls" is a table containing 4 variables.
These represent 4 lists with the length N, where N is the number of marked calls.
The first list is "Box" it is a Nx4 matrix of doubles.
The first value denotes the temporal beginning of the box,
the second value denotes the lowest frequency of the box,
the third value denotes the duration in time of the box
and the fourth value denotes the extension along the frequency axis of the box.

Assuming time is x and frequency is y the box is given as:
```
    [lower_x, lower_y, extension_x, extension_y]
```

The second list "Score" is a double representing the score of the network.
If you have labeled this yourself you should set this to 1.0 as in "100% sure this is correctly labeled".

The third list "Type" contains the label or type of the call. The type of this list is categorical.

The fourth list "Accept" determines if the call should be accepted (probably for training).
The type is logical.

To rephrase the structures in an explicitly typed language like C:
```C
enum CallType{
    // Your text labels
}

struct Calls{
    double Box[NUMBER_OF_CALLS][4];
    double Score[NUMBER_OF_CALLS];
    CallType Type[NUMBER_OF_CALLS];
    bool Accept[NUMBER_OF_CALLS];
};
```

### Audiodata

Audio data is used to refer and read in the original ".wav" files.
It is a struct with the following members:

| Member Name       | Data-type | Content                                     |
| ----------------- | --------- | ------------------------------------------- |
| Filename          | char      | Full path to the ".wav"-file                |
| CompressionMethod | char      | The method used for compression as a string |
| NumChannels       | double    | The number of channels                      |
| SampleRate        | double    | The number of samples per second            |
| TotalSamples      | double    | The total number of samples in the file     |
| Duration          | double    | The number of seconds the file runs         |
| Title             | double    | The title of the audio-file                 |
| Comment           | double    | A comment on the file                       |
| Artist            | double    | The artist or rodent that produced the file |
| BitsPerSample     | double    | The number of bits per sample               |
