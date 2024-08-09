# What is this?
Quick and dirty batch video and photo stitching pipleine for Insta360 cameras. I developed this primarily because I'm lazy, and want to have streamlined experience of accessing my videos and photos without using Insta360 Studio or mobile app. This pipeline produces 360 degree MP4 and JPEGs, which are compatible with many viewers including Immich (what I use).

The stitching functionality is provided mostly by example code from Insta360 with one addition for automatic accessory type detection. Single lens photos are handled using ffmpeg and are turned into 180x180 degree panoramas.

# Building
1. This project expects you to provide sdk/libMediaSDK-dev_2.0-4.tar.xz from Insta360 by applying for it on their website.
2. `make stitcher` to build the docker image that is used by the scripts.

# Using
Example import.sh and stitch.sh are provided which utilize the above container image. In my setup:
* import.sh is triggered via a udev rule, when I plug the camera into my server.
* stitch.sh is triggered via a cron job, when the power is cheap.

This way I can have fully automated stitching experience where I only need to plug in the camera, and stitched 360 degree MP4s and JPEGs come out on the other end. 

# Status
Works for me, on Insta360 X4 for the video and image formats I use. The SDK is compatible with other cameras too, but you may need to customize a few parameters according to your needs. I'm publishing this primarily as a backup for myself, but also in case anyone wants to do the same thing, Insta360's documentation is rather poor, so you may find additional data points this provides useful. 