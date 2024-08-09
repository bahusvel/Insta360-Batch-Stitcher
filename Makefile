CONTAINER_CMD = docker run --rm -v ./test/:/test insta360-stitcher

dev:
	docker build -f docker/Dockerfile.dev -t insta360-dev .

stitcher: dev
	docker build -f docker/Dockerfile.stitcher -t insta360-stitcher .

build: src/main.cc
	docker run -it --rm -v ./src:/src insta360-dev g++ src/main.cc -std=c++11 -lMediaSDK -o src/stitcher

dev-run: build
	docker run -it --rm -v ./src:/src insta360-dev

run:
	docker run -it --rm insta360-stitcher

decoder: src/decoder.cc
	g++ -Iinclude $^ -o $@

test-decoder: decoder
	ls test/* | xargs -t -n 1 ./decoder 

test-video: test/VID_20240808_104035_00_001.insv
	$(eval IMAGE_HEIGHT := $(shell $(CONTAINER_CMD) exiftool -s3 -ImageHeight -api largefilesupport=1 $^))
	$(eval IMAGE_WIDTH := $(shell echo $$(($(IMAGE_HEIGHT) * 2)) ))
	echo $(IMAGE_WIDTH)x$(IMAGE_HEIGHT)
	$(CONTAINER_CMD) stitcher -stitch_type optflow -enable_flowstate -enable_directionlock -enable_stitchfusion -output_size $(IMAGE_WIDTH)x$(IMAGE_HEIGHT) -inputs $^ -output test/flowstate.mp4

gpano-fix:
	# exiftool -overwrite_original "-XMP-GPano:all>all:all" test/x4.jpg # This command fixes broken GPano metadata from camera
	# exiftool -overwrite_original -TagsFromFile test/x2.jpg -XMP-GPano:all test/x4.jpg # Copy gpano meta from donor

test-image: test/IMG_20240705_185109_00_032.insp
	$(eval IMAGE_SIZE := $(shell $(CONTAINER_CMD) exiftool -s3 -ImageSize $^))
	$(CONTAINER_CMD) stitcher -stitch_type optflow -enable_flowstate -output_size $(IMAGE_SIZE) -inputs $^ -output test/IMG_20240705_185109_00_032.jpg
	$(CONTAINER_CMD) exiftool -overwrite_original -TagsFromFile $^ -all:all -XMP-GPano:ProjectionType=equirectangular test/IMG_20240705_185109_00_032.jpg

flat-image: test/flat.insp
	$(eval IMAGE_SIZE := $(shell $(CONTAINER_CMD) exiftool -s3 -ImageSize $^))
	$(CONTAINER_CMD) ffmpeg -i $^ -vf v360=fisheye:e:iv_fov=190:ih_fov=190:h_fov=170:v_fov=170,scale=$(IMAGE_SIZE) -qmin 1 -qmax 1 -q:v 1 -update 1 -frames:v 1 -y test/flat.jpg
	$(CONTAINER_CMD) exiftool -overwrite_original -TagsFromFile $^ -all:all test/flat.jpg

test/180-pano.jpg: test/180-2.jpg
	$(CONTAINER_CMD) exiftool -overwrite_original -XMP-GPano:ProjectionType=equirectangular -XMP-GPano:FullPanoHeightPixels=5984 -XMP-GPano:FullPanoWidthPixels=11968 -XMP-GPano:CroppedAreaLeftPixels=2992 -XMP-GPano:CroppedAreaImageHeightPixels=5984 -XMP-GPano:CroppedAreaImageWidthPixels=5984 $^