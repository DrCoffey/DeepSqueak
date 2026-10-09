# Background subtraction

An addition to DeepSqueak for removing equipment noise bands from spectrograms. Code is in
[Functions/Background Subtraction/](../Functions/Background%20Subtraction/); tests are in
[Tests/test_background_subtraction.m](../Tests/test_background_subtraction.m).

How the method works and why it was chosen: [BACKGROUND_SUBTRACTION_METHOD.md](BACKGROUND_SUBTRACTION_METHOD.md).

## What it does

You mark stretches of a recording that contain only background: no calls, no passing noises. Those stretches become
a saved **background definition**. You then **assign** that definition to the recordings it suits, as many at once as you like. For a recording
with an assignment, every spectrogram DeepSqueak computes has the background removed: the display, call statistics,
clustering images, training images and what a detector sees.

- Audio files are never changed, and nothing is written beside them.
- Detection files are not changed. A box is a place in time and frequency; what is extracted from that place comes
  from the cleaned spectrogram when the recording has a background. Boxes are locations, not a claim that a
  detection is correct.
- A recording with no assignment is processed exactly as upstream DeepSqueak would (detection output is checked
  against upstream by a test).

## The pieces

| Thing | What it is | Where it lives |
|---|---|---|
| Noise marks | An ordinary DeepSqueak session file whose boxes cover noise-only stretches | Wherever you save it |
| Background definition | One `.mat` file holding the noise audio and an id | The background folder |
| Assignment | One small file per recording, `<recording name>_background.mat`, naming the definition that recording uses | The background folder |

The **background folder** is chosen with *File > Select Background Folder*, like the audio and detection folders.
It defaults to `Backgrounds/` in the repository, which is gitignored.

A recording has a background only if its assignment file is in the current background folder. One definition can be
assigned to any number of recordings, in any locations. A recording uses at most one definition at a time.
Recordings are matched by file name, and the assignment also stores the recording's length and sample rate, so a
different recording that happens to share a name is refused rather than silently cleaned.

## Using it

### 1. Mark noise-only stretches

1. *Load Audio* on a recording.
2. Draw a box (*Draw*, or `d`) over each stretch that has no calls or other passing sounds. Only the start and end
   time of a box are used. The focus window is at most 5 s wide, so draw several.
3. Save (Ctrl+S), under a name that says what it is, for example the recording's name plus `_NoiseMarks`.

Keep these boxes in their own file, separate from call detections. If they must share a file with calls, give the
noise boxes their own label.

### 2. Build the definition

*Tools > Background Subtraction > Define Background from Boxed Noise...*

1. Select the file or files holding the boxes.
2. Confirm. The dialog names the file it read and says how many boxes it found and how many seconds they cover.
   If the file holds more than one label, you choose which label marks noise.
3. Enter a name, the percentile (leave at 50 unless there is a reason), whether to use flicker scaling (leave at
   0; see section 8 of the method document) and optional notes.
4. Save into the background folder. The suggested filename ends in the first 12 characters of the definition's id.
5. Choose whether to assign it to recordings straight away.

How much audio: the code needs at least 50 short windows, a fraction of a second, but that is far too little to be
representative. Tens of seconds spread over the session is a reasonable starting point; this has not been studied.

### 3. Change what a definition is made of

A definition can draw its noise from several files of boxed noise, and a file's worth can be added or removed
later. Each file of boxed noise is one **source**.

- *Add Boxed Noise to a Definition...*: pick the definition, then the file(s) of boxed noise to add.
- *Remove Boxed Noise from a Definition...*: pick the definition, then choose from the list of its sources. Each
  entry shows the source's name, how many stretches and seconds it contributes, and which recording they came
  from. The last remaining source cannot be removed.

A saved definition never changes, because results record the id of the definition they were made with. So both
actions save a **new definition file** beside the old one, with the same name and settings, a new id, and a
record of the id it was derived from. If recordings in the background folder use the old version, you are asked
whether to switch them to the new one. The old file stays where it is; delete it by hand only if nothing made with
it needs to be reproduced.

Good to know:

- The id depends only on which noise is in the definition, not on how it got there. Building from files A and B at
  once, adding B to A, or adding A to B all give the same definition, and removing B again gives back A's.
- Noise that is already in a definition is refused, so nothing is counted twice.
- Adding does not need the recordings behind the noise already in the definition; that noise is carried over from
  the definition itself.
- Selecting several files of boxed noise when defining, in step 2, gives one source per file from the start.

### 4. Assign it

Assigning records which definition a recording uses. It can be done for many recordings at once, and no recording
needs to be open.

*Tools > Background Subtraction > Assign Background to Recordings...*: pick a definition, then pick one or more
recordings from the current audio folder. The open recording, if any, is preselected, and recordings that already
have a background are marked. Replacing an existing assignment asks first. To assign to recordings in another
location, select that audio folder and repeat. If the definition came from outside the background folder, a copy
is saved into it.

*Remove Background Assignment from Recordings...* deletes assignments for the recordings you pick. Definitions are
kept.

### 5. Apply it

Applying is what actually removes the background, and in the main window it concerns the open recording only.

- Opening a recording that has an assignment starts with removal **on**.
- *Apply Background Removal to This Recording* is a tick-mark switch. Unticking it shows and measures the open
  recording without removal; the assignment is untouched. It is greyed out when the open recording has no
  assignment. Reopening a recording turns removal back on.
- The window title always says which state you are in:
  `Background removal ON for this recording: <name> (<id>)`, or
  `Background assigned but removal is OFF: <name> (<id>)`, or plain `DeepSqueak` when nothing is assigned.
- *Compare Before and After (current page)* opens a figure with the page before and after on one color scale, and
  the typical level at each frequency. It works whether the switch is on or off.

The switch affects the main window only: the display and the side-panel statistics. Operations that work through
files on their own do not look at it.

**Every operation that works through files asks.** After you select the files, if any of their recordings has a
background assigned, a question says how many do and offers *Apply*, *Do not apply* or *Cancel*.

- *Apply* removes the background from every selected recording that has one. Recordings without one are processed
  without removal either way, and the question warns when that would give a mixed set.
- *Do not apply* processes everything without removal, as upstream DeepSqueak would.
- *Cancel* stops before anything is made.
- If no selected recording has a background, nothing is asked.

| Operation | Menu or button | The choice is recorded in |
|---|---|---|
| Training images | *Tools > Network Training > Create Detection Network Training Images* | `Training/<name>.mat`, and the Command Window |
| Detection | *Detect Calls*, *Multi Detect* | `detection_metadata.background` in each detection file |
| Call statistics | *File > Import / Export > Export Excel Log* | The `Background Definition` column, per row |
| Batch reject | *Tools > Automatic Review > Batch Reject by Threshold* | Not recorded (see below) |
| Clustering, classification, denoising, embedding | Everything under *Tools > Call Classification* that loads detection files, *Post Hoc Denoising*, *Train Post Hoc Denoiser*, *Train Supervised Classifier* | Extracted contours file, per detection file, when saved |
| Splitting long 22 kHz calls | *Tools > Separate Long 22s* | Not recorded |

The boxes are never changed by this choice; only what is measured or drawn from them. Exports that do not use
spectrograms (Sonic Visualiser, Raven) do not ask.

Not recorded means: batch reject rewrites the detection file with updated accept and reject marks and nothing
else, as upstream does, so the file does not say whether those marks were decided with removal on. Note it
yourself if it matters.

### Without the GUI

```matlab
segments   = table({'D:\rec\a.flac'; 'D:\rec\a.flac'}, [120; 300], [135; 320], ...
                   'VariableNames', {'Filename', 'StartTime', 'StopTime'});
Background = createBackgroundDefinition(segments, 'Rig 3, Nov 2024');   % options: 'Percentile', 'FlickerScaling'
saveBackgroundDefinition(Background, 'X:\backgrounds\Rig 3 Nov 2024.mat');

assignBackground({'D:\rec\a.flac', 'E:\other\b.flac'}, Background, 'X:\backgrounds');
Background = backgroundForAudio('E:\other\b.flac', 'X:\backgrounds');   % [] if none assigned
removeBackgroundAssignment('E:\other\b.flac', 'X:\backgrounds');

backgroundSources(Background)                                             % what it is made of
Bigger  = addToBackgroundDefinition(Background, backgroundSegmentsFromDetections('marksB.mat', 'USV'));
Smaller = removeFromBackgroundDefinition(Bigger, 'marksA.mat');            % both return new definitions
repointBackgroundAssignments('X:\backgrounds', Background.id, loadBackgroundDefinition('X:\backgrounds\bigger.mat'));

compareBackgroundSubtraction('D:\rec\a.flac', Background, 600, 5, 'FreqRange', [0 120]);
[s, p] = applyBackgroundSubtraction(Background, s, p, window, nfft, rate);
```

`backgroundSegmentsFromDetections(files, labels)` turns boxed stretches into the `segments` table.

## What the files contain

**Definition** (`Background` struct, plus `BackgroundId` saved on its own so a file can be recognised quickly):

| Field | Contents |
|---|---|
| `id` | SHA-256 of the noise audio, sample rate, sample format, percentile, flicker-scaling choice and format version. Same id, same result |
| `name`, `notes`, `created` | Description. Not part of the id |
| `SampleRate` | A definition only applies to audio at this rate |
| `percentile` | Statistic taken over time at each frequency |
| `flickerScaling` | Whether flicker scaling is applied. Off unless chosen |
| `segments` | Table: audio file, source (the file of boxed noise each stretch came from), start and stop sample and time, audio file length and size |
| `derivedFrom` | Present on a definition made by adding to or removing from another: that definition's id |
| `samples` | The noise audio itself, in its original integer format |
| `formatVersion` | 3 for current definitions. Formats 1 and 2, from 2026-10-08, still load and still give their original results; format 2 is the short-lived floor-rows reference |
| `totalDuration`, `sampleClass`, `method`, `software` | Bookkeeping, including MATLAB version, DeepSqueak version and git commit |

It stores audio rather than a spectrum because the background has to be re-measured for every spectrogram size
DeepSqueak uses. Cost: about 0.5 MB per second of noise at 384 kHz.

Definitions are immutable. Saving refuses to overwrite a file, and loading recomputes the id and refuses a file
whose content no longer matches. Changing a definition (step 3) makes a new one. A definition is found by id, so renaming
its file does not break assignments.

**Assignment** (`BackgroundAssignment` struct): recording file name, its total samples and sample rate, the
definition's id and name, the definition's file name when assigned, and the date. Assignments can be replaced or
removed; results record the definition id they were computed with.

## Where it is applied

| Code path | Feeds |
|---|---|
| `CreateFocusSpectrogram` | Side-panel statistics, Excel export, *Batch Reject by Threshold*, clustering and denoiser images, contours |
| `renderEpochSpectogram` | Page and focus display |
| `SqueakDetect` | Detection |
| `CreateTrainingData` in `create_training_images_Callback` | Detector training images |
| `SeperateLong22s_Callback` | Splitting long 22 kHz detections |

Each place that opens a recording looks up that recording's background with `backgroundForAudio`. A `squeakData`
reader marks its background `'unresolved'` whenever a new recording is set, and computing a spectrogram in that
state is an error, so a code path that forgets the lookup fails instead of silently skipping the cleaning.

Not affected: playback, *Export Audio* and the waveform panel, because audio is never modified.

### What gets recorded

| Output | Record |
|---|---|
| Detection file, at detection | `detection_metadata.background` (used, id, name, file, percentile) |
| `Training/<name>.mat` | variable `background` |
| Network trained from those tables | variable `background`. `SqueakDetect` warns when a network trained on cleaned images is run on a recording without a background, or the reverse |
| Extracted contours `.mat` | variable `background`, one entry per detection file |
| Excel export | last column `Background Definition`: `name (id)` or `none`, per row. Present in every export |

Not recorded: `savesession_Callback` rewrites a detection file with only `Calls` and `audiodata`, as upstream does,
so `detection_metadata` is lost on a manual save. Clustering model files do not record it.

## When something is wrong

| Situation | What happens |
|---|---|
| Recording has no assignment in the background folder | No cleaning. Title shows plain `DeepSqueak` |
| Recording has an assignment but the apply switch is off | No cleaning in the main window; the title says so. Batch operations still use the assignment |
| Background folder does not exist | Treated as no assignments. This includes a network folder that is unreachable, so check the title |
| Assignment exists but the definition is missing or has been altered | Error. The recording does not open, and batch operations stop |
| Assignment was made for a different recording with the same name | Error |
| Definition's sample rate differs from the recording's | Refused at assignment; error if met later |

## Checked, and not checked

Automated tests (26, all passing; the command is at the top of the test file) cover: exact storage of the noise
audio; the background spectrum against an independent calculation; removal of a tone and a noise band from
held-out synthetic noise; a synthetic call keeping its level relative to background; save, load, refusal to
overwrite, refusal of altered files; assignments per recording across folders, replacement, removal, finding a
renamed definition; loud failure for a missing definition, a same-named different recording, and a sample-rate
mismatch; the unresolved-background guard; and exact equality of detection output with upstream when a recording
has no background.

The real menu code was run by script on a lab noise-marks file (10 boxes, 29.3 s), with each dialog answered by
the script:
select background folder, load audio, define, assign to the open recording, compare, open a detection file,
reopen the audio (background shown), remove. In a second scripted run the marks file was split in two to stand for two files of
boxed noise: define from the first, add the second (the open recording was switched to the new definition),
add the second again (refused), remove the first, try to remove the last (refused); all three definitions were
kept on disk. The display changed on assignment and returned
exactly to the original on removal.

The operations that ask were run for real by script on the repository's example rat recording (40 boxes), with a
background built from arbitrary stretches purely to exercise the code, answering *Apply*, *Do not apply* and
*Cancel* in turn:

- Excel export: the column read `example rat (c6660ece6c91)` or `none`; tonality differed in all 40 rows and
  principal frequency in 8; *Cancel* wrote no file; the Sonic Visualiser export asked nothing.
- Clustering data: all 40 call images and 29 contours differed between the two answers.
- Batch reject (rule: tonality below 0.35): 17 calls rejected with removal, 16 without; 3 calls had a different
  outcome.
- Detection (first 20 s, shipped rat network): the metadata recorded the definition's id or none; *Do not apply*
  gave exactly the boxes of detection with no background; *Cancel* wrote no file. (30 boxes with removal, 33
  without; no conclusion can be drawn from that.)
- Training images (19 images): *Apply* recorded the
definition's id and *Do not apply* recorded none; all 19 images differed between the two while the boxes were
identical; repeating *Apply* gave byte-identical images; a recording with no assignment raised no question; a
mixed selection applied removal only to the assigned recording; *Cancel* made nothing.

**Not exercised:** the dialogs as a person sees and clicks them; training a network from such images; the
clustering and classification steps after their data is loaded; *Multi Detect* with several files (single-file
detection goes through the same code); *Separate Long 22s* from the menu. Those paths parse and share tested
functions, but have not been run end to end.

### What it looked like

On that lab recording, the page had a strong band near 22 kHz and several between about 43 and 49 kHz. After
cleaning they were gone, apart from a faint line near 46 kHz; the largest attenuation was 23.9 dB. This is
from one 30 s comparison figure and has not been formally assessed. **The 22 kHz band sits where 22 kHz calls are**, so those
calls will be dimmed there by up to that amount; see "What it costs" in the method document.

## Limitations

- **One fixed background per recording.** Noise that changes within a recording is not handled (out of scope by
  design). Recordings that differ get their own definitions.
- **Pulsed bands are only partly handled.** No special treatment, by design; the per-definition percentile is
  the only control.
- **Assignments are looked up in the current background folder only.** Switch the folder and a recording's
  assignment is no longer seen. The title bar and the recorded ids are the safeguards.
- **Power statistics change meaning** for recordings with a background: values are relative to background. Do not
  mix statistics computed with and without; the Excel column says which each row is.
- **Calls are dimmed where they cross a band**, by the band's height.
- **Faint dark or light stripes can remain at band frequencies**, mainly because bands change strength over time.
  Measured on one lab recording in section 8 of the method document, along with two remedies that were tried.
  Marking noise stretches across the whole session is the practical mitigation.
- **`autoScale` and steady tones.** After cleaning, a steady tone's row is unusually smooth, and `autoScale` turns
  such rows into a thin dark line in detector images, as it also does without cleaning. Whether that matters for
  training is unknown.
- **Single channel only.**
- **Shipped networks were trained on unprocessed images.** Expect them to behave differently on recordings with a
  background. The intended use is to train new networks from cleaned images.
