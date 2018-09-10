# Changelog
## 1.0.4.1 2018-9-10
Added option to specify the range for amplitude augmentation

## 1.0.4 - 2018-9-5
Added data augmentation for training new networks 
 - When using "Create Training Images", each image will now be augmented with a random level of white noise, and multiplied by a random gain factor. This substantially increases detection accuracy across different microphones and recording gain.
