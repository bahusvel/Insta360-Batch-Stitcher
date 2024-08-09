#!/bin/bash

IMPORT_PATH=/hdd/media/Insta360/import
CONTAINER_CMD="docker run --rm -v $IMPORT_PATH:/import --cpus 10 insta360-stitcher"

cd $IMPORT_PATH

VIDEOS=$(ls *.insv)
PHOTOS=$(ls *.insp)

for INSV in $VIDEOS; do
	MP4=${INSV/%insv/mp4}
	if [ -e $MP4 ]; then
		continue;
	fi
	IMAGE_HEIGHT=$($CONTAINER_CMD exiftool -s3 -ImageHeight -api largefilesupport=1 import/$INSV)
	IMAGE_SIZE=$(echo $(($IMAGE_HEIGHT * 2))x$IMAGE_HEIGHT)
	echo $INSV $IMAGE_SIZE $MP4

	$CONTAINER_CMD stitcher -stitch_type optflow -enable_flowstate -enable_directionlock -enable_stitchfusion -output_size $IMAGE_SIZE -inputs import/$INSV -output import/$MP4
done

for INSP in $PHOTOS; do
        JPG=${INSP/%insp/jpg}
        if [ -e $JPG ]; then
                continue;
        fi
	IMAGE_SIZE=$($CONTAINER_CMD exiftool -s3 -ImageSize import/$INSP)
        echo $INSP $IMAGE_SIZE $JPG
	SIZE_PARTS=(${IMAGE_SIZE//x/ })
	if [ ${SIZE_PARTS[0]} -eq ${SIZE_PARTS[1]} ]; then
		echo "Single Lens Image"
		# Convert to equirectangular projection
		$CONTAINER_CMD ffmpeg -i import/$INSP -vf v360=fisheye:e:iv_fov=190:ih_fov=190:h_fov=170:v_fov=170,scale=$IMAGE_SIZE -qmin 1 -qmax 1 -q:v 1 -update 1 -frames:v 1 -y import/$JPG
		$CONTAINER_CMD exiftool -overwrite_original -TagsFromFile import/$INSP -all:all import/$JPG
		# Sets the image to 180x180 degree panorama
		$CONTAINER_CMD exiftool -overwrite_original -XMP-GPano:ProjectionType=equirectangular -XMP-GPano:FullPanoHeightPixels=${SIZE_PARTS[1]} -XMP-GPano:FullPanoWidthPixels=$(( ${SIZE_PARTS[0]} * 2 )) -XMP-GPano:CroppedAreaLeftPixels=$(( ${SIZE_PARTS[0]} / 2 )) -XMP-GPano:CroppedAreaImageHeightPixels=${SIZE_PARTS[1]} -XMP-GPano:CroppedAreaImageWidthPixels=${SIZE_PARTS[0]} import/$JPG
		continue
	fi

	$CONTAINER_CMD stitcher -stitch_type optflow -enable_flowstate -output_size $IMAGE_SIZE -inputs import/$INSP -output import/$JPG
	$CONTAINER_CMD exiftool -overwrite_original -TagsFromFile import/$INSV -all:all -XMP-GPano:ProjectionType=equirectangular import/$JPG
done
