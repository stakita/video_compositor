
# Configuration file for render settings
BUILD_CONFIG = config.py
# Snapshot of the makefile used in the build
BUILD_MAKEFILE = Makefile.build

HERO_RAW_FILES := $(wildcard hero5/*.MP4)
HERO_JOIN_CONFIG = hero_join_config.txt
HERO_JOIN_FILE = hero.join.mp4
HERO_WAVEFORM_FILE = hero.waveform.mp4
HERO_RENDER = hero_render.mp4
HERO_OUTPUT_BITRATE = 30000k
HERO_SCALING_FACTOR = 0.75
HERO_GENERATED_FILES = hero.join.wav hero.waveform.mp4.background.png

MAX_RAW_FILES := $(wildcard max/*.LRV)
MAX_JOIN_CONFIG = max_join_config.txt
MAX_JOIN_FISHEYE_FILE = max.join.fisheye.mp4
MAX_JOIN_FILE = max.join.mp4
MAX_WAVEFORM_FILE = max.waveform.mp4
MAX_RENDER = max_render.mp4
MAX_OUTPUT_BITRATE = 30000k
MAX_SCALING_FACTOR = 1.0
MAX_GENERATED_FILES = max.join.wav max.waveform.mp4.background.png

MERGED_OUTPUT_BITRATE = 30000k
MERGED_RENDER = merged_render.mp4

MERGED_MAP_OUTPUT_BITRATE = 40000k
MERGED_MAP_RENDER = merged_map_render.mp4

WAVEFORM_VIDEO_TOOL = create_waveform_video

TRACK_GPX = track_gps.gpx
GOPRO2GPX_TOOL = gopro2gpx

TRACK_MAP_CACHE_DIR = tiles

TRACK_MAP_OVERVIEW_VIDEO_TOOL=create_overview_video
TRACK_MAP_OVERVIEW_VIDEO=map_overview.mp4

TRACK_MAP_CHASE_VIDEO_TOOL=create_chase_video
TRACK_MAP_CHASE_ZOOM_FACTOR=16
TRACK_MAP_CHASE_VIDEO=map_chase.mp4

# combined map render video
TRACK_MAP_RENDER=track_map_render.mp4
TRACK_MAP_OUTPUT_BITRATE=10000k

TRACK_MAP_GENERATED_FILES = track_gps.kpx track_gps.bin map_overview.mp4.background.png
TRACK_MAP_CACHED_FILES = $(wildcard $(TRACK_MAP_CACHE_DIR)/*.png)

LOG_FILES = log_hero.join.mp4.txt \
			log_hero_render.mp4.txt \
			log_map_overview.mp4.txt \
			log_max.join.mp4.txt \
			log_max_render.mp4.txt \
			log_track_gps.gpx.txt \
			log_hero.waveform.mp4.txt \
			log_map_chase.mp4.txt \
			log_max.join.fisheye.mp4.txt \
			log_max.waveform.mp4.txt \
			log_merged_map_render.mp4.txt \
			log_merged_render.mp4.txt \
			log_track_map_render.mp4.txt

FFMEG_BIN = ffmpeg

READ_TIME_OPTIONS = $(shell python -c "import config; print(config.TIME_OPTIONS)")
READ_ADVANCE_MAX_SECONDS = $(shell python -c "import config; print(config.ADVANCE_MAX_SECONDS)")
READ_ADVANCE_HERO_SECONDS = $(shell python -c "import config; print(config.ADVANCE_HERO_SECONDS)")

# convert seconds into ffmpeg time format (ugly hack)
READ_ADVANCE_MAX = $(shell python -c "h, r =divmod($(READ_ADVANCE_MAX_SECONDS), 3600); m, s = divmod(r, 60); print('{:0>2}:{:0>2}:{:05.3f}'.format(int(h), int(m), s))")
READ_ADVANCE_HERO = $(shell python -c "h, r =divmod($(READ_ADVANCE_HERO_SECONDS), 3600); m, s = divmod(r, 60); print('{:0>2}:{:0>2}:{:05.3f}'.format(int(h), int(m), s))")

READ_VOLUME_HERO = $(shell python -c "import config; print(config.VOLUME_HERO)")
READ_VOLUME_MAX = $(shell python -c "import config; print(config.VOLUME_MAX)")
READ_HERO_AUDIO_OPTS = $(shell python -c "import config; print(config.HERO_AUDIO_OPTS)")

# functions for retrieving video parameters from ffmpeg
# these typically export the ffprobe data as json, then we parse and extract with "jq"
video_height = $(shell ffprobe -v quiet -print_format json -i $(1) -show_streams | jq '.streams[] | select(.codec_type == "video") | .height')
video_width = $(shell ffprobe -v quiet -print_format json -i $(1) -show_streams | jq '.streams[] | select(.codec_type == "video") | .width')
duration_seconds = $(shell ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $(1))
# basic inline operators for string numeric operations
op_multiply = $(shell python -c "print(int($(1) * $(2)))")
op_subract = $(shell python -c "print(int($(1) - $(2)))")
op_add = $(shell python -c "print(int($(1) + $(2)))")
op_max = $(shell python -c "print(max($(1), $(2)))")

NONE=\033[00m
RED=\033[01;31m
GREEN=\033[01;32m
YELLOW=\033[01;33m
PURPLE=\033[01;35m
CYAN=\033[01;36m
WHITE=\033[01;37m
BOLD=\033[1m
UNDERLINE=\033[4m


all: $(BUILD_CONFIG) merged_map

# Comment "Makefile" out during development to be insensitive to changes in this file
config: $(BUILD_CONFIG) # Makefile

# Side by side video
merged: $(MERGED_RENDER)

# Full merged map
merged_map: $(MERGED_MAP_RENDER)

.PHONY: all clean clobber distclean

snapshot_makefile:
	@echo "${BOLD}Snapshot the makefile used for the build${NONE}"
	cp Makefile Makefile.build

clean:
	@echo "${BOLD}clean derivative files - leave join files${NONE}"
	rm -f $(HERO_WAVEFORM_FILE) $(HERO_GENERATED_FILES)  $(HERO_RENDER)
	rm -f $(MAX_WAVEFORM_FILE) $(MAX_RENDER) $(MAX_GENERATED_FILES)
	rm -f $(TRACK_MAP_CHASE_VIDEO) $(TRACK_MAP_OVERVIEW_VIDEO) $(TRACK_MAP_RENDER) $(TRACK_GPX) $(TRACK_MAP_GENERATED_FILES)
	rm -rf __pycache__ config.pyc

clobber: clean logclean
	@echo "${BOLD}clobber - kill them all${NONE}"
	rm -f $(HERO_JOIN_CONFIG) $(HERO_JOIN_FILE)
	rm -f $(MAX_JOIN_CONFIG) $(MAX_JOIN_FILE) $(MAX_JOIN_FISHEYE_FILE)
	rm -f $(TRACK_MAP_CACHED_FILES)
	rm -f $(TRACK_MAP_CACHE_DIR)
	rm -f $(MERGED_RENDER) $(MERGED_MAP_RENDER)
	rm -f $(BUILD_CONFIG) $(BUILD_MAKEFILE)

logclean:
	rm -f $(LOG_FILES)

distclean: clean
	@echo "${BOLD}distclean - leave final files and config${NONE}"
	rm -f $(HERO_JOIN_CONFIG) $(HERO_JOIN_FILE)
	rm -f $(MAX_JOIN_CONFIG) $(MAX_JOIN_FILE) $(MAX_JOIN_FISHEYE_FILE)
	rm -f $(TRACK_MAP_CACHED_FILES)


DEFAULT_CONFIG = "TIME_OPTIONS = '-t 00:05:00.000'\nADVANCE_MAX_SECONDS = 0.000\nADVANCE_HERO_SECONDS = 0.000\nVOLUME_HERO = 1.0\nVOLUME_MAX = 0.15\nHERO_AUDIO_OPTS = '' \#', compand=attacks=0:decays=0.4:points=-30/-900|-20/-20|0/0|20/20'"

$(BUILD_CONFIG):
	@echo "${BOLD}generate build config file${NONE}"
	@echo $(DEFAULT_CONFIG) > $@

# filter_audio_test = " \
# [0:a] volume=$(shell $(READ_VOLUME_HERO)) [left]; \
# [1:a] volume=$(shell $(READ_VOLUME_MAX)) [right]; \
# [left][right]amerge=inputs=2,pan=stereo|c0<c0+c1|c1<c2+c3[a] \
# "

# audio_test: $(BUILD_PARAMS)
# 	@echo "${BOLD}generate audio test file${NONE}"
# 	HERO_FILE=$(firstword $(HERO_RAW_FILES)); \
# 	MAX_FILE=$(firstword $(MAX_RAW_FILES)); \
# 	$(FFMEG_BIN) \
# 		-y \
# 		-ss $(shell $(READ_ADVANCE_HERO)) \
# 		-i $$HERO_FILE \
# 		-ss $(shell $(READ_ADVANCE_MAX)) \
# 		-i $$MAX_FILE \
# 		-filter_complex $(filter_audio_test) \
# 		-map "[a]" \
# 		-q:a 4 \
# 		$(shell $(READ_TIME_OPTIONS)) \
# 		$@.aac

#=======================================================================================================

# generate ffmpeg join config for hero files - needed by ffmpeg concat method
$(HERO_JOIN_CONFIG): $(HERO_RAW_FILES) $(BUILD_CONFIG) snapshot_makefile
	@echo "${BOLD}generate hero ffmpeg join config file${NONE}"
	FILE_LIST=`python -c "print('\n'.join(['file \'%s\'' % s for s in '$(HERO_RAW_FILES)'.split()]))"`; \
	echo "$$FILE_LIST" > $@

# join hero files
$(HERO_JOIN_FILE): $(HERO_JOIN_CONFIG)
	@echo "${BOLD}concat hero files${NONE}"
	$(FFMEG_BIN) -y -f concat -safe 0 -i $< -c copy -map 0:v -map: 0:a -map: 0:3 $@ > log_$@.txt 2>&1

# generate waveform file
$(HERO_WAVEFORM_FILE): $(HERO_JOIN_FILE)
	@echo "${BOLD}generate waveform progress video${NONE}"

	$(eval MAXIMUM_JOIN_WIDTH:=$(call video_width, $(HERO_JOIN_FILE)))
	$(eval MAXIMUM_SCALED_WIDTH:=$(call op_multiply, $(HERO_SCALING_FACTOR), $(MAXIMUM_JOIN_WIDTH)))
	$(eval DURATION_SECONDS:=$(call duration_seconds, $(HERO_JOIN_FILE)))
	$(eval DURATION_TRIMMED:=$(call op_subract, $(DURATION_SECONDS), $(READ_ADVANCE_HERO_SECONDS)))

	@echo 1: $(MAXIMUM_JOIN_WIDTH)
	@echo 2: $(MAXIMUM_SCALED_WIDTH)
	@echo 3: $(DURATION_SECONDS)
	@echo 4: $(DURATION_TRIMMED)
	@echo 5: $(READ_ADVANCE_HERO_SECONDS)

	$(WAVEFORM_VIDEO_TOOL) \
		$(HERO_JOIN_FILE) \
		$(DURATION_TRIMMED) \
		--output=$(HERO_WAVEFORM_FILE) \
		--width=$(MAXIMUM_SCALED_WIDTH) \
		--height=100 \
		--channels=1 > log_$@.txt 2>&1

# combine video with waveform video
$(HERO_RENDER): $(HERO_JOIN_FILE) $(HERO_WAVEFORM_FILE) $(BUILD_CONFIG)
	@echo "${BOLD}combine hero and waveform video vertically and audio${NONE}"

	$(eval TOP_HEIGHT:=$(call video_height, $(HERO_JOIN_FILE)))
	$(eval TOP_HEIGHT_SCALED:=$(call op_multiply, $(HERO_SCALING_FACTOR), $(TOP_HEIGHT)))
	$(eval TOP_WIDTH:=$(call video_width, $(HERO_JOIN_FILE)))
	$(eval TOP_WIDTH_SCALED:=$(call op_multiply, $(HERO_SCALING_FACTOR), $(TOP_WIDTH)))
	$(eval BOTTOM_HEIGHT:=$(call video_height, $(HERO_WAVEFORM_FILE)))
	$(eval OUTPUT_WIDTH:=$(TOP_WIDTH_SCALED))
	$(eval OUTPUT_HEIGHT:=$(call op_add, $(TOP_HEIGHT_SCALED), $(BOTTOM_HEIGHT)))
	$(eval TOP_GEOMETRY:="$(TOP_WIDTH_SCALED)"x"$(TOP_HEIGHT_SCALED)")
	$(eval GEOMETRY="$(OUTPUT_WIDTH)"x"$(OUTPUT_HEIGHT)")

	@echo 1: $(TOP_HEIGHT)
	@echo 2: $(TOP_HEIGHT_SCALED)
	@echo 3: $(TOP_WIDTH)
	@echo 4: $(TOP_WIDTH_SCALED)
	@echo 5: $(BOTTOM_HEIGHT)
	@echo 6: $(OUTPUT_WIDTH)
	@echo 7: $(OUTPUT_HEIGHT)
	@echo 8: $(TOP_GEOMETRY)
	@echo 9: $(GEOMETRY)

	$(FFMEG_BIN) \
		-y \
		-ss $(READ_ADVANCE_HERO) \
		-i $(HERO_JOIN_FILE) \
		-i $(HERO_WAVEFORM_FILE) \
		-filter_complex " \
			nullsrc=size=$(GEOMETRY) [base]; \
			[0:v] setpts=PTS-STARTPTS,scale=$(TOP_GEOMETRY) [top]; \
			[1:v] setpts=PTS-STARTPTS [bottom]; \
			[base][top] overlay=shortest=1 [tmp1]; \
			[tmp1][bottom] overlay=shortest=1:y=$(TOP_HEIGHT_SCALED) [out]; \
			[0:a]volume=1.0" \
		-map "[out]" \
		-b:v $(HERO_OUTPUT_BITRATE) \
		$(READ_TIME_OPTIONS) \
		$@ > log_$@.txt 2>&1


#=======================================================================================================

# generate ffmpeg join config for max files
$(MAX_JOIN_CONFIG): $(MAX_RAW_FILES) $(BUILD_CONFIG) snapshot_makefile
	@echo "${BOLD}generate max ffmpeg join config file${NONE}"
	FILE_LIST=`python -c "print('\n'.join(['file \'%s\'' % s for s in '$(MAX_RAW_FILES)'.split()]))"`; \
	echo "$$FILE_LIST" > $@

# join max files
# mapping:
#    0:v - all video
#    0:a - all audio
#    0:3 - the "GoPro MET" temmetry channel including GPS data
# NOTE: The reference to the telemetry is hard coded current, but we can query this with ffprobe if necessary
#       to make it dynamic
$(MAX_JOIN_FISHEYE_FILE): $(MAX_JOIN_CONFIG)
	@echo "${BOLD}concat max files${NONE}"
	$(FFMEG_BIN) -y -f concat -safe 0 -i $< -c copy -map 0:v -map: 0:a -map: 0:3 $@ > log_$@.txt 2>&1

# map max files to hemispherical
$(MAX_JOIN_FILE): $(MAX_JOIN_FISHEYE_FILE)
	@echo "${BOLD}map max files to hemispherical${NONE}"
	$(FFMEG_BIN) \
		-y \
		-i $< \
		-vf v360=input=dfisheye:ih_fov=187:iv_fov=187:output=e:yaw=90 \
		-b:v 2500k \
		-c:a copy \
		$(READ_TIME_OPTIONS) \
		$@ > log_$@.txt 2>&1

# generate waveform file
$(MAX_WAVEFORM_FILE): $(MAX_JOIN_FILE)
	@echo "${BOLD}generate waveform progress video${NONE}"

	$(eval MAXIMUM_JOIN_WIDTH:=$(call video_width, $(MAX_JOIN_FILE)))
	$(eval MAXIMUM_SCALED_WIDTH:=$(call op_multiply, $(MAX_SCALING_FACTOR), $(MAXIMUM_JOIN_WIDTH)))
	$(eval DURATION_SECONDS:=$(call duration_seconds, $(MAX_JOIN_FILE)))
	$(eval DURATION_TRIMMED:=$(call op_subract, $(DURATION_SECONDS), $(READ_ADVANCE_MAX_SECONDS)))

	@echo 1: $(MAXIMUM_JOIN_WIDTH)
	@echo 2: $(MAXIMUM_SCALED_WIDTH)
	@echo 3: $(DURATION_SECONDS)
	@echo 4: $(DURATION_TRIMMED)
	@echo 5: $(READ_ADVANCE_MAX_SECONDS)

	$(WAVEFORM_VIDEO_TOOL) \
		$(MAX_JOIN_FILE) \
		$(DURATION_TRIMMED) \
		--output=$(MAX_WAVEFORM_FILE) \
		--width=$(MAXIMUM_SCALED_WIDTH) \
		--height=100 \
		--channels=1 > log_$@.txt 2>&1

# combine video with waveform video
$(MAX_RENDER): $(MAX_JOIN_FILE) $(MAX_WAVEFORM_FILE) $(BUILD_CONFIG)
	@echo "${BOLD}combine max and waveform video vertically${NONE}"

	$(eval TOP_HEIGHT:=$(call video_height, $(MAX_JOIN_FILE)))
	$(eval TOP_HEIGHT_SCALED:=$(call op_multiply, $(MAX_SCALING_FACTOR), $(TOP_HEIGHT)))
	$(eval TOP_WIDTH:=$(call video_width, $(MAX_JOIN_FILE)))
	$(eval TOP_WIDTH_SCALED:=$(call op_multiply, $(MAX_SCALING_FACTOR), $(TOP_WIDTH)))
	$(eval BOTTOM_HEIGHT:=$(call video_height, $(MAX_WAVEFORM_FILE)))
	$(eval OUTPUT_WIDTH:=$(TOP_WIDTH_SCALED))
	$(eval OUTPUT_HEIGHT:=$(call op_add, $(TOP_HEIGHT_SCALED), $(BOTTOM_HEIGHT)))
	$(eval TOP_GEOMETRY:="$(TOP_WIDTH_SCALED)"x"$(TOP_HEIGHT_SCALED)")
	$(eval GEOMETRY="$(OUTPUT_WIDTH)"x"$(OUTPUT_HEIGHT)")

	@echo 1: $(TOP_HEIGHT)
	@echo 2: $(TOP_HEIGHT_SCALED)
	@echo 3: $(TOP_WIDTH)
	@echo 4: $(TOP_WIDTH_SCALED)
	@echo 5: $(BOTTOM_HEIGHT)
	@echo 6: $(OUTPUT_WIDTH)
	@echo 7: $(OUTPUT_HEIGHT)
	@echo 8: $(TOP_GEOMETRY)
	@echo 9: $(GEOMETRY)

	$(FFMEG_BIN) \
		-y \
		-ss $(READ_ADVANCE_MAX) \
		-i $(MAX_JOIN_FILE) \
		-i $(MAX_WAVEFORM_FILE) \
		-filter_complex " \
			nullsrc=size=$(GEOMETRY) [base]; \
			[0:v] setpts=PTS-STARTPTS,scale=$(TOP_GEOMETRY) [top]; \
			[1:v] setpts=PTS-STARTPTS [bottom]; \
			[base][top] overlay=shortest=1 [tmp1]; \
			[tmp1][bottom] overlay=shortest=1:y=$(TOP_HEIGHT_SCALED) [out]; \
			[0:a]volume=1.0" \
		-map "[out]" \
		-b:v $(MAX_OUTPUT_BITRATE) \
		$(READ_TIME_OPTIONS) \
		$@ > log_$@.txt 2>&1


#=======================================================================================================


$(TRACK_GPX): $(MAX_JOIN_FISHEYE_FILE)
	@echo "${BOLD}extract GPX data from video${NONE}"
	@# This tool adds the gpx (and kpx) extensions automatically, so we "basename" off the extension
	$(GOPRO2GPX_TOOL) -s -vv $< $(basename $@) > log_$@.txt 2>&1

$(TRACK_MAP_OVERVIEW_VIDEO): $(TRACK_GPX)
	@echo "${BOLD}generate track map overview video${NONE}"
	@# Create link to a tile cache directory
	ls $(TRACK_MAP_CACHE_DIR) > /dev/null 2>&1 || (mkdir -p /var/tmp/tiles && ln -s /var/tmp/tiles)
	$(TRACK_MAP_OVERVIEW_VIDEO_TOOL) $< --output=$@ --tile-cache=tiles > log_$@.txt 2>&1


#-------------------------------------------------------------------------------------------------------


$(TRACK_MAP_CHASE_VIDEO): $(TRACK_GPX)
	@echo "${BOLD}generate track map chase video${NONE}"
	@# Create link to a tile cache directory
	ls $(TRACK_MAP_CACHE_DIR) || (mkdir -p /var/tmp/tiles && ln -s /var/tmp/tiles)
	$(TRACK_MAP_CHASE_VIDEO_TOOL) $< $(TRACK_MAP_CHASE_ZOOM_FACTOR) --output=$@ > log_$@.txt 2>&1


$(TRACK_MAP_RENDER): $(TRACK_MAP_CHASE_VIDEO) $(TRACK_MAP_OVERVIEW_VIDEO) $(MAX_JOIN_FILE)
	@echo "${BOLD}generate combined track render stack${NONE}"
	$(eval MAX_DURATION_SECONDS := $(call duration_seconds, $(MAX_JOIN_FILE)))
	$(eval TRACK_MAP_CHASE_DURATION_SECONDS := $(call duration_seconds, $(TRACK_MAP_CHASE_VIDEO)))
	# review the timing calculations here
	$(eval START_PAD := $(READ_ADVANCE_MAX_SECONDS))

	@echo 1: $(MAX_DURATION_SECONDS)
	@echo 2: $(TRACK_MAP_CHASE_DURATION_SECONDS)
	@echo 3: $(START_PAD)

	# MAX_DURATION_SECONDS=`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $(MAX_JOIN_FILE)`; \
	# TILEMAP_CLOSE_DURATION_SECONDS=`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $(TILE_MAP_CLOSE_VIDEO)`; \
	# START_PAD=`python -cR "print(round($$MAX_DURATION_SECONDS - $$TILEMAP_CLOSE_DURATION_SECONDS - $(READ_ADVANCE_MAX_SECONDS), 2))"`; \
	# echo start_pad: $$START_PAD;

	$(FFMEG_BIN) \
		-y \
		-itsoffset $(START_PAD) \
		-i $(TRACK_MAP_CHASE_VIDEO) \
		-itsoffset $(START_PAD) \
		-i $(TRACK_MAP_OVERVIEW_VIDEO) \
		-filter_complex " \
			[0:v][1:v] vstack \
			" \
		-b:v $(MERGED_OUTPUT_BITRATE) \
		$(READ_TIME_OPTIONS) \
		$@ > log_$@.txt 2>&1


#=======================================================================================================

# combine video into single side-by-side
$(MERGED_RENDER): $(HERO_RENDER) $(MAX_RENDER) $(BUILD_CONFIG)
	@echo "${BOLD}combine video into single side-by-side${NONE}"

	$(eval LEFT_WIDTH := $(call video_width, $(HERO_RENDER)))
	$(eval LEFT_HEIGHT := $(call video_height, $(HERO_RENDER)))
	$(eval RIGHT_WIDTH := $(call video_width, $(MAX_RENDER)))
	$(eval RIGHT_HEIGHT := $(call video_height, $(MAX_RENDER)))

	$(eval OUTPUT_WIDTH := $(call op_add, $(LEFT_WIDTH), $(RIGHT_WIDTH)))
	$(eval OUTPUT_HEIGHT := $(call op_max, $(LEFT_HEIGHT), $(RIGHT_HEIGHT)))

	$(eval GEOMETRY := $(OUTPUT_WIDTH)x$(OUTPUT_HEIGHT))

	@echo 1: $(LEFT_WIDTH)
	@echo 2: $(RIGHT_WIDTH)
	@echo 3: $(LEFT_HEIGHT)
	@echo 4: $(RIGHT_HEIGHT)
	@echo 5: $(OUTPUT_WIDTH)
	@echo 6: $(OUTPUT_HEIGHT)
	@echo 7: $(GEOMETRY)

	$(FFMEG_BIN) \
		-y \
		-i $(HERO_RENDER) \
		-i $(MAX_RENDER) \
		-filter_complex " \
			color=size=$(GEOMETRY):duration=1.0:color=Black [base]; \
			[0:v] setpts=PTS-STARTPTS [left]; \
			[1:v] setpts=PTS-STARTPTS [right]; \
			[base][left] overlay=shortest=0 [tmp1]; \
			[tmp1][right] overlay=shortest=0:x=$(LEFT_WIDTH) [out]; \
			[0:a][1:a] amerge=inputs=2,pan=stereo|c0<c0+c1|c1<c2+c3 \
			" \
		-map "[out]" \
		-b:v $(MERGED_OUTPUT_BITRATE) \
		$(READ_TIME_OPTIONS) \
		$@ > log_$@.txt 2>&1


#=======================================================================================================

# combine video into full map render
$(MERGED_MAP_RENDER):  $(TRACK_MAP_RENDER) $(HERO_RENDER) $(MAX_RENDER)
	@echo "${BOLD}combine video and map renders into single view${NONE}"

	$(eval HERO_WIDTH := $(call video_width, $(HERO_RENDER)))
	$(eval MAX_WIDTH := $(call video_width, $(MAX_RENDER)))
	$(eval LEFT_WIDTH := $(call op_max, $(HERO_WIDTH), $(MAX_WIDTH)))

	@echo 1: $(LEFT_WIDTH)
	@echo 2: $(HERO_WIDTH)
	@echo 3: $(MAX_WIDTH)

	$(eval TIME_MAX_RENDER := $(call duration_seconds, $(MAX_RENDER)))
	$(eval TIME_HERO_RENDER := $(call duration_seconds, $(HERO_RENDER)))
	$(eval TIME_FULL := $(call op_max, $(TIME_MAX_RENDER), $(TIME_HERO_RENDER)))

	@echo 8: $(TIME_MAX_RENDER)
	@echo 9: $(TIME_HERO_RENDER)
	@echo 10: $(TIME_FULL)

	$(FFMEG_BIN) \
		-y \
		-i $(HERO_RENDER) \
		-i $(MAX_RENDER) \
		-i $(TRACK_MAP_RENDER) \
		-filter_complex " \
			[1:v] pad=width=$(LEFT_WIDTH):height=0:x=(ow-iw):y=0:color=black [vid1pad]; \
			[0:v][vid1pad] vstack [vintleft]; \
			[vintleft][2:v] hstack [out]; \
			[0:a] apad [0a_pad]; \
			[1:a] apad [1a_pad]; \
			[0a_pad][1a_pad] amerge=inputs=2,pan=stereo|c0<c0+c1|c1<c2+c3 \
			" \
		-map "[out]" \
		-b:v $(MERGED_MAP_OUTPUT_BITRATE) \
		-t $(TIME_FULL) \
		$@ > log_$@.txt 2>&1


