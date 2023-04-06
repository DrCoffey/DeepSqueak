# Changelog
## 3.1.0 2023-04-04
## MANY UPDATES & FIXES
Improved Default Clustering
- Default Variational Autoencoder Embeddings + Contour
- Countour parameters only still available (was called: k-means)
- Improved image normalization
- Fixed Cluster Label Issue

Updated Clustering Window
- Removed frequency visualization
- Right click to change clusters

Improved TSNE/UMAp visualization

Added File Name to Excel Batch Output

Checks for File Changes Before Save

## 3.0.4 2022-07-27
## Supervised Clustering Bug Fix
- Fixed an issue where supervised clustering was crashing

## 3.0.3 2022-06-07
## MAJOR BUG FIX - PLEASE DOWNLOAD
- Temporary fix to a bug where cluster assignments weren't correct when clustering files with rejected calls.
- If you want to cluster all calls except rejected calls, be sure to delete rejected calls before clustering.
- Permanent fix incoming, but for now saved cluster assignments will at least match up with the clustering window.

## 3.0.2 2022-03-21
## v3 More Bug Fixes
- Fixed automatic spectrogram scaling issues
- Fixed GUI Axes

## 3.0.1 2021-08-08
## v3 Bug Fixes
- Batch Reject By Threshold Fix
- Export Audio Fix
- Export Spectrogram Fix

## 3.0 2021-07-23

## Main Upgrades
- Brand New YOLO V2 based Detection Architechture
- Navigate Entire Audio Files to Quickly & Easily Refine Detections or Add New Boxes
- Retrain Existing Networks With Your Own Recordings
- Manually add calls not detected by Faster-RCNN.
- Start From Scratch: Hand Box Calls and Train a New Species Detector
- Improved automatic contour extraction
- Contour Invarient Clustering With Variational Auto Encoders
- Upgraded clustering GUI
- Additional "page" spectogram with a larger time window for call contextualization.
- Record Audio Directly in DeepSqueak

## New Navigation Controls
- Click on the lower page spectrogram to jump to that position in the upper "focus" view.
- Click a location on the map bar to jump to that location in the file.
- Up and down arrow keys to slide the focus window forward or backward
- Right click on a detection to remove it.
- Control-click or double click on a detection to change it's label
- Select, move, and modify ROIs of detected calls:

## Minor Upgrades
- Constant time and spectrogram scales.
- Display either spectral amplitude of power spectral density
- Possibility to modify time and spectrogram scales, Focus (upper spectrogram), Page (lower spectrogram).
- Sonic Visualizer export/import.
- Fully compatible with older DeepSqueak detections files.
- Invertible colormaps.
- GUI tweaks.

## Credits: 
**Original DeepSqueak**: Coffey, K., Marx, R., & Neumaier, J.<br>
**Screener**: Lara-Valderrábano, L. and Ciszek, R.

## 2.6.2 2020-08-03

Modifications to increase contributor and community engagement
 - New [Community Hub on Gitter](https://gitter.im/DeepSqueak_Community)
 - New [DeepSqueak Twitter](https://twitter.com/DeepSqueak_USV)
 - New Contributor Guidlines
 - New Contributor Code of Conduct
 - New Background Image!

Minor bug fixes 

## 2.6.1 2019-07-16

Fixed bug when importing call classifications from Raven .txt files.
  - DeepSqueak will now look for a column called 'Tags'.
  - If the 'Tags' column doesn't exist, DeepSqueak will use the 'Annotation' column.
  - If the 'Annotation' column doesn't exist, the category will be set to 'USV' by default.
  
Fixed issue when calls file is empty in unsupervised clustering.

## 2.6.0 2019-04-17

Improved the accuracy of the post-hoc denoising network.

Improved Call classification
  - Included a newly trained supervised classifier based on Wright et al.'s rat USV categories.
  - Included a k-means model from human-selected exemplar calls, based on Wright et al.'s rat USV categories.
  - Supervised network training now trains from the region of the spectrogram contained within the box, rather than a constant frequency range. This might make old networks incompatible.
  - Automatically merge clusters with the same names but different case.

t-SNE plots now have the option to assign colors by call classification, rather than call pitch. If coloring by classification, you must load detection files, rather than pre-extracted contours. This requires call files that have already been classified, either manually, or by supervised/unsupervised classification.

Added better support for non-ultrasonic animals, such as zebras.

## 2.5.0 2019-03-04
Fixed possible bug when updating files after clustering.

Made syntax analysis compatible with exported excel files.

Generally cleaned the code.

Made box merging much faster, detected audio is now always stored ad 16-bit.

K-means clustering models are now saved with the cluster names, so that when clustering with an existing model, the names don't need to be re-entered.

Improved the "Tools > Automatic Review > Batch Reject by Threshold" menu to allow for more permutations of score, duration, tonality, frequency, power, and category.

Detection files are now tables instead of structures. Everything should be backwards compatible.

## 2.4.1 2019-03-01
Updated threshold rejection to use power instead of amplitude.

Added buttons to sort calls by frequency and duration.

Improved support for multichannel audio by taking the mean of all audio channels.
Alternatively, a max intensity projection can be applied to the audio, or a single channel can be used.
See line 79 of SqueakDetect.m for details.

## 2.3.0 2019-02-20
Detection is now no longer limited to two Networks.

Improved separation of densely packed calls.

## 2.2.0 2019-01-25

Drastically improved detection of low signal vocalizations!
- New slider to set precision to recall tradeoff
- When slider is set to high precision, USV detection will be fast and accurate but may miss some quiet calls
- When slider is set to high recall, USV detection is slightly slower but will detect even extremely low signal calls
- When slider is set to high recall, DeepSqueak will likely detect more noise
- Default slider position is in the middle, and balances both approaches

Added a link to the "Issues" section of our GitHub in the Help Menu

Included a pdf of the published paper

## 2.1.2 2019-01-14
Multichannel audio no longer breaks DeepSqueak.
If audio files have more than one channel, only the first channel is used.

Added support for more categories for manual call classification

Added a function to set the upper and/or lower frequency of each call to a constant value. Located under "Tools > Automatic Review > Set Static Box Height".

## 2.1.0 2019-01-03
Call power is now calculated as power spectral density (units are dB/Hz), rather than amplitude.

Switch KHz to kHz

Added support for .wmf files

## 2.0.2 2018-12-31
Fixed issue when the first samples in an audio file contain calls

## 2.0.1 2018-12-18
Fixed minor bugs in 2.0 release

## 2.0.0 2018-12-14
**DeepSqueak 2.0**
```
 (                   (                                         
 )\ )                )\ )                      )      )     )  
(()/(    (   (      (()/(  (    (    (    ) ( /(   ( /(  ( /(  
 /(_))  ))\ ))\`  )  /(_)( )\  ))\  ))\( /( )\())  )(_)) )\())
(_))_  /((_/((_/(/( (_)) )(( )/((_)/((_)(_)((_)\  ((_)  ((_)\  
 |   \(_))(_))((_)_\/ __((_)_(_))((_))((_)_| |(_) |_  ) /  (_)
 | |) / -_/ -_| '_ \\__ / _` | || / -_/ _` | / /   / / | () |  
 |___/\___\___| .__/|___\__, |\_,_\___\__,_|_\_\  /___(_\__/   
              |_|          |_|                                 
```

**Major Improvements to Speed**
 * DeepSqueak now detects at 20x - 40x
 * Speed improvements come from optimized spectrogram settings and network architechture

**Improved Networks**
 * New All Short Calls Network for detecting rat and mouse call with the same network
 * New Mouse Short Call Network
 * New Rat Short Call Network
 * New Long Rat call Network
 * New Post-Hoc Denoising Network
 * New Wright Category Classification Network

**Automatic Audio Scaling**
 * Gain setting is removed and instead DeepSqueak will automatically scale all audio to the proper volume for detection

**Simplified Network Training**
 * Netowork training only works in 2018a (currently working with Matlab to find the problem with faster-RCNN in 2018b)

**Various minor quality of life improvements**

## 1.1.9 2018-12-5
Fixed bug in k-means feature weighting

Added tool to create t-sne image of calls. "Tools -> Call Classification -> Create t-sne"

## 1.1.8 2018-11-30
Added figure with cluster exemplars for k-means clustering

Calls in the clustering GUI are now sorted by how well they match the cluster

## 1.1.7 2018-11-27
Various bug Fixes

Improved syntax analyses

DS now checks to see if a newer version is online

## 1.1.6 2018-11-19
Fixed error in importing files from Ultravox.

Fixed error when simultaneously detecting with multiple networks.

## 1.1.5.2 2018-11-16
Changed export audio so that all audio is exported, not just what's in the boxes.

Improved file names in export spectrogram and export audio.

## 1.1.5.1 2018-11-15
Fixed bug in kmeans optimization by removing dependency on export_fig

## 1.1.5 2018-11-7
Probably fixed unix compatibility by changes slashes to ones that one on both windows and unix.

Fixed error in export to excel, when filenames were cut off when the name contained periods.

When creating training images, augmented duplicates are now created in addition to, rather than instead of the original.
 - Reduced the amount of white noise augmentation
 - Fixed incorrect file path for training tables

Added manifestos.

## 1.1.4 2018-11-1
Switched most file saving to "fullfile" function, rather than concatinating strings.

Made detection files smaller by saving the audio as the native format, rather than double.

Saved files now include metadata such as detection time, settings, audio file path, and detection network.


## 1.1.3 2018-10-23
Added k-means optimization into unsupervised clustering, using the knee method. When using k-means, their is now an option to enter the number of means, or try many different means and select the one at the knee point.

Improved data preperation for unsupervised clustering. Now, paramaters include duration, slope, and frequency. Each each call is split into eight chunks, and each parameter is calculated for each chunk. Users can define the paramater weights to optimize cluster quality.


## 1.1.2 2018-9-28
Users can now set the time scale on the spectrogram to a constant value, in the "Update Display Range" menu.

Added amplitude (power) to k-means clustering. Each call is split into chunks, and the power from each chunk is put into k-means.

K-means clustering breaks the contours into chunks, which are are now equally spaced in time, rather than removing gaps in time.

## 1.1.1 2018-9-27
Added the ability to accept or reject calls based on score, power, and tonality, in batches.

Added tonality slider, so users can easily adjust tonality.
 - Changed default tonality to 0.3, made amplitude threshold 0 by default

The gradient display now only displays the verticle gradient, which better represents how tonality is calculated.

Updating the display is now significantly faster, because the data in the existing figures is updated rather than being redrawn.

During detection, boxes are padded slightly, to make contour detection better.

## 1.0.5 2018-9-12
Added a new rat call detection network
 - Trained with the new options in 1.0.4.1

SqueakDetect now subtracts the 5th percentile from the spectrogram across the temporal dimension.
 - This increases detection accuracy by filtering out noise bands from low quality microphones.
## 1.0.4.1 2018-9-10
Added option to specify the range for amplitude augmentation

## 1.0.4 - 2018-9-5
Added data augmentation for training new networks
 - When using "Create Training Images", each image will now be augmented with a random level of white noise, and multiplied by a random gain factor. This substantially increases detection accuracy across different microphones and recording gain.
