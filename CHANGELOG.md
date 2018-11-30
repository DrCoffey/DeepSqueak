# Changelog

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
