
# Configuration file for render settings
BUILD_CONFIG = config.py
# Snapshot of the makefile used in the build
BUILD_MAKEFILE = Makefile.build

HERO_RAW_FILES := $(wildcard hero5/*.MP4)
HERO_JOIN_CONFIG = hero_join_config.txt
HERO_JOIN_FILE = $(TEMPFILE_CACHE_DIR)/hero.join.mp4
HERO_WAVEFORM_FILE = $(TEMPFILE_CACHE_DIR)/hero.waveform.mp4
HERO_SCALING_FACTOR = 0.75
HERO_GENERATED_FILES = $(TEMPFILE_CACHE_DIR)/hero.join.wav \
						$(TEMPFILE_CACHE_DIR)/hero.waveform.mp4.background.png

MAX_RAW_FILES := $(wildcard max/*.LRV)
MAX_JOIN_CONFIG = max_join_config.txt
MAX_JOIN_FISHEYE_FILE = $(TEMPFILE_CACHE_DIR)/max.join.fisheye.mp4
MAX_JOIN_FILE = $(TEMPFILE_CACHE_DIR)/max.join.mp4
MAX_WAVEFORM_FILE = $(TEMPFILE_CACHE_DIR)/max.waveform.mp4
MAX_SCALING_FACTOR = 1.0
MAX_GENERATED_FILES = $(TEMPFILE_CACHE_DIR)/max.join.wav \
						$(TEMPFILE_CACHE_DIR)/max.waveform.mp4.background.png

FULL_RENDER_OUTPUT_BITRATE = 40000k
FULL_RENDER = full_render.mp4

AUDIO_TEST_FILE = audio_test.aac

WAVEFORM_VIDEO_TOOL = create_waveform_video

TRACK_GPX = $(TEMPFILE_CACHE_DIR)/track_gps.gpx
GOPRO2GPX_TOOL = gopro2gpx

TRACK_MAP_CACHE_DIR = tiles
TEMPFILE_CACHE_DIR = compositor_build

TRACK_MAP_OVERVIEW_VIDEO_TOOL=create_overview_video
TRACK_MAP_OVERVIEW_VIDEO=$(TEMPFILE_CACHE_DIR)/map_overview.mp4

TRACK_MAP_CHASE_VIDEO_TOOL=create_chase_video
TRACK_MAP_CHASE_ZOOM_FACTOR=16
TRACK_MAP_CHASE_VIDEO=$(TEMPFILE_CACHE_DIR)/map_chase.mp4

TRACK_MAP_FRAMES_PER_SECOND = 5
WAVEFORM_VIDEO_FRAMES_PER_SECOND = 5

TRACK_MAP_GENERATED_FILES = $(TEMPFILE_CACHE_DIR)/track_gps.kpx \
							$(TEMPFILE_CACHE_DIR)/track_gps.kml \
							$(TEMPFILE_CACHE_DIR)/track_gps.bin \
							$(TEMPFILE_CACHE_DIR)/map_overview.mp4.background.png

TRACK_MAP_CACHED_FILES = $(wildcard $(TRACK_MAP_CACHE_DIR)/*.png)

LOG_FILES = $(TEMPFILE_CACHE_DIR)/hero.join.mp4.log \
			$(TEMPFILE_CACHE_DIR)/map_overview.mp4.log \
			$(TEMPFILE_CACHE_DIR)/max.join.mp4.log \
			$(TEMPFILE_CACHE_DIR)/track_gps.gpx.log \
			$(TEMPFILE_CACHE_DIR)/hero.waveform.mp4.log \
			$(TEMPFILE_CACHE_DIR)/map_chase.mp4.log \
			$(TEMPFILE_CACHE_DIR)/max.join.fisheye.mp4.log \
			$(TEMPFILE_CACHE_DIR)/max.waveform.mp4.log \
			full_render.mp4.log

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
# Todo: Fix this work around
op_add_4 = $(shell python -c "print(int($(1) + $(2) + $(3) + $(4)))")
op_max = $(shell python -c "print(max($(1), $(2)))")
# op_string_or: if first parameter is populated, use it, otherwise use the second parameter
op_string_or = $(shell python -c "in1='$(1)'.strip(); in2='$(2)'.strip(); print(in1 if in1 != '' else in2)")

NONE=\033[00m
RED=\033[01;31m
GREEN=\033[01;32m
YELLOW=\033[01;33m
PURPLE=\033[01;35m
CYAN=\033[01;36m
WHITE=\033[01;37m
BOLD=\033[1m
UNDERLINE=\033[4m


all: $(BUILD_CONFIG) audio_test

# Comment "Makefile" out during development to be insensitive to changes in this file
config: $(BUILD_CONFIG) # Makefile

full_render: $(FULL_RENDER)
audio_test: $(AUDIO_TEST_FILE)

.PHONY: all clean clobber distclean

clean:
	@echo "${BOLD}clean derivative files - leave join files${NONE}"
	rm -f $(HERO_WAVEFORM_FILE) $(HERO_GENERATED_FILES)
	rm -f $(MAX_WAVEFORM_FILE) $(MAX_RENDER) $(MAX_GENERATED_FILES)
	rm -f $(TRACK_MAP_CHASE_VIDEO) $(TRACK_MAP_OVERVIEW_VIDEO) $(TRACK_GPX) $(TRACK_MAP_GENERATED_FILES)
	rm -rf __pycache__ config.pyc

clobber: clean logclean
	@echo "${BOLD}clobber - kill them all${NONE}"
	rm -f $(HERO_JOIN_CONFIG) $(HERO_JOIN_FILE)
	rm -f $(MAX_JOIN_CONFIG) $(MAX_JOIN_FILE) $(MAX_JOIN_FISHEYE_FILE)
	rm -f $(TRACK_MAP_CACHED_FILES)
	rm -f $(TRACK_MAP_CACHE_DIR)
	rm -f $(TEMPFILE_CACHE_DIR)
	rm -f $(FULL_RENDER)
	rm -f $(AUDIO_TEST_FILE)
	rm -f $(BUILD_CONFIG) $(BUILD_MAKEFILE)

logclean:
	rm -f $(LOG_FILES)

distclean: clean
	@echo "${BOLD}distclean - leave final files and config${NONE}"
	rm -f $(HERO_JOIN_CONFIG) $(HERO_JOIN_FILE)
	rm -f $(MAX_JOIN_CONFIG) $(MAX_JOIN_FILE) $(MAX_JOIN_FISHEYE_FILE)
	rm -f $(TRACK_MAP_CACHED_FILES)
	rm -f $(AUDIO_TEST_FILE)


DEFAULT_CONFIG = "TIME_OPTIONS = '-t 00:05:00.000'\nADVANCE_MAX_SECONDS = 0.000\nADVANCE_HERO_SECONDS = 0.000\nVOLUME_HERO = 1.0\nVOLUME_MAX = 0.15\nHERO_AUDIO_OPTS = '' \#', compand=attacks=0:decays=0.4:points=-30/-900|-20/-20|0/0|20/20'"

$(BUILD_CONFIG):
	@# Todo: FIX - This does not have per process isolation or most other safety measures
	@echo "${BOLD}create link to local temp cache directory${NONE}"
	$(shell ls compositor_build || mkdir -p /tmp/compositor_build && ln -s /tmp/compositor_build)
	@echo "${BOLD}Snapshot the makefile used for the build${NONE}"
	cp Makefile Makefile.build
	@echo "${BOLD}generate build config file${NONE}"
	@echo $(DEFAULT_CONFIG) > $@

$(AUDIO_TEST_FILE): $(BUILD_CONFIG)
	@echo "${BOLD}generate audio test file${NONE}"
	$(FFMEG_BIN) \
		-y \
		-ss $(READ_ADVANCE_HERO) \
		-i $(firstword $(HERO_RAW_FILES)) \
		-ss $(READ_ADVANCE_MAX) \
		-i $(firstword $(MAX_RAW_FILES)) \
		-filter_complex " \
			[0:a] volume=$(READ_VOLUME_HERO) [left]; \
			[1:a] volume=$(READ_VOLUME_MAX) [right]; \
			[left][right]amerge=inputs=2,pan=stereo|c0<c0+c1|c1<c2+c3[a] \
		" \
		-map "[a]" \
		-q:a 4 \
		$(READ_TIME_OPTIONS) \
		$@

#=======================================================================================================

# generate ffmpeg join config for hero files - needed by ffmpeg concat method
$(HERO_JOIN_CONFIG): $(HERO_RAW_FILES)
	@echo "${BOLD}generate hero ffmpeg join config file${NONE}"
	FILE_LIST=`python -c "print('\n'.join(['file \'%s\'' % s for s in '$(HERO_RAW_FILES)'.split()]))"`; \
	echo "$$FILE_LIST" > $@

# join hero files
$(HERO_JOIN_FILE): $(HERO_JOIN_CONFIG) $(HERO_RAW_FILES)
	@echo "${BOLD}concat hero files${NONE}"
	$(FFMEG_BIN) -y -f concat -safe 0 -i $< -c copy -map 0:v -map 0:a -map 0:3 $@ > $@.log 2>&1

# generate waveform file
$(HERO_WAVEFORM_FILE): $(HERO_JOIN_FILE) $(BUILD_CONFIG)
	@echo "${BOLD}generate hero waveform progress video${NONE}"

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
		--fps=$(WAVEFORM_VIDEO_FRAMES_PER_SECOND) \
		--channels=1 > $@.log 2>&1

#=======================================================================================================

# generate ffmpeg join config for max files
$(MAX_JOIN_CONFIG): $(MAX_RAW_FILES) $(BUILD_CONFIG)
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
$(MAX_JOIN_FISHEYE_FILE): $(MAX_JOIN_CONFIG) $(MAX_RAW_FILES)
	@echo "${BOLD}concat max files${NONE}"
	$(FFMEG_BIN) -y -f concat -safe 0 -i $< -c copy -map 0:v -map 0:a -map 0:3 $@ > $@.log 2>&1

# map max files to hemispherical
$(MAX_JOIN_FILE): $(MAX_JOIN_FISHEYE_FILE) $(BUILD_CONFIG)
	@echo "${BOLD}map max joined (fisheye) to hemispherical${NONE}"
	$(FFMEG_BIN) \
		-y \
		-i $< \
		-vf v360=input=dfisheye:ih_fov=187:iv_fov=187:output=e:yaw=90 \
		-b:v 2500k \
		-c:a copy \
		$(READ_TIME_OPTIONS) \
		$@ > $@.log 2>&1

# generate waveform file
$(MAX_WAVEFORM_FILE): $(MAX_JOIN_FILE) $(BUILD_CONFIG)
	@echo "${BOLD}generate max waveform progress video${NONE}"

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
		--fps=$(WAVEFORM_VIDEO_FRAMES_PER_SECOND) \
		--channels=1 > $@.log 2>&1

#=======================================================================================================

$(TRACK_GPX): $(MAX_RAW_FILES)
	@echo "${BOLD}extract GPX data from videos${NONE}"
	@# This tool adds the gpx (and kpx) extensions automatically, so we "basename" off the extension
	$(GOPRO2GPX_TOOL) -s -vv $? $(basename $@) > $@.log 2>&1

$(TRACK_MAP_CACHE_DIR):
	@# Create link to a tile cache directory
	mkdir -p /var/tmp/tiles && ln -s /var/tmp/tiles

$(TRACK_MAP_OVERVIEW_VIDEO): $(TRACK_GPX) $(TRACK_MAP_CACHE_DIR)
	@echo "${BOLD}generate track map overview video${NONE}"
	$(TRACK_MAP_OVERVIEW_VIDEO_TOOL) $< --output=$@ --tile-cache=tiles --fps=$(TRACK_MAP_FRAMES_PER_SECOND) > $@.log 2>&1

$(TRACK_MAP_CHASE_VIDEO): $(TRACK_GPX) $(TRACK_MAP_CACHE_DIR)
	@echo "${BOLD}generate track map chase video${NONE}"
	$(TRACK_MAP_CHASE_VIDEO_TOOL) $< $(TRACK_MAP_CHASE_ZOOM_FACTOR) --output=$@ --fps=$(TRACK_MAP_FRAMES_PER_SECOND) > $@.log 2>&1

#=======================================================================================================

# combine video into full map render
$(FULL_RENDER): $(BUILD_CONFIG) $(TRACK_MAP_CHASE_VIDEO) $(TRACK_MAP_OVERVIEW_VIDEO) $(MAX_JOIN_FILE) $(MAX_WAVEFORM_FILE) $(HERO_JOIN_FILE) $(HERO_WAVEFORM_FILE)
	@echo "${BOLD}combine video, waveform and map renders into single view${NONE}"

	@ #----------------------------------------------------------
	$(eval HERO_HEIGHT:=$(call video_height, $(HERO_JOIN_FILE)))
	$(eval HERO_HEIGHT_SCALED:=$(call op_multiply, $(HERO_SCALING_FACTOR), $(HERO_HEIGHT)))
	$(eval HERO_WIDTH:=$(call video_width, $(HERO_JOIN_FILE)))
	$(eval HERO_WIDTH_SCALED:=$(call op_multiply, $(HERO_SCALING_FACTOR), $(HERO_WIDTH)))
	$(eval HERO_GEOMETRY="$(HERO_WIDTH_SCALED)"x"$(HERO_HEIGHT_SCALED)")

	$(eval HERO_WAVEFORM_HEIGHT:=$(call video_height, $(HERO_WAVEFORM_FILE)))
	$(eval HERO_WAVEFORM_WIDTH:=$(call video_width, $(HERO_WAVEFORM_FILE)))

	@echo 1: $(HERO_GEOMETRY)

	@ #----------------------------------------------------------

	$(eval MAX_HEIGHT:=$(call video_height, $(MAX_JOIN_FILE)))
	$(eval MAX_HEIGHT_SCALED:=$(call op_multiply, $(MAX_SCALING_FACTOR), $(MAX_HEIGHT)))
	$(eval MAX_WIDTH:=$(call video_width, $(MAX_JOIN_FILE)))
	$(eval MAX_WIDTH_SCALED:=$(call op_multiply, $(MAX_SCALING_FACTOR), $(MAX_WIDTH)))
	$(eval MAX_GEOMETRY="$(MAX_WIDTH_SCALED)"x"$(MAX_HEIGHT_SCALED)")

	$(eval MAX_WAVEFORM_HEIGHT:=$(call video_height, $(MAX_WAVEFORM_FILE)))
	$(eval MAX_WAVEFORM_WIDTH:=$(call video_width, $(MAX_WAVEFORM_FILE)))

	@echo 2: $(MAX_GEOMETRY)

	@ #----------------------------------------------------------

	@# Timing calcs
	$(eval HERO_DURATION_SECONDS:=$(call duration_seconds, $(HERO_JOIN_FILE)))
	$(eval HERO_DURATION_TRIMMED:=$(call op_subract, $(HERO_DURATION_SECONDS), $(READ_ADVANCE_HERO_SECONDS)))
	$(eval MAX_DURATION_SECONDS:=$(call duration_seconds, $(MAX_JOIN_FILE)))
	$(eval MAX_DURATION_TRIMMED:=$(call op_subract, $(MAX_DURATION_SECONDS), $(READ_ADVANCE_MAX_SECONDS)))

	$(eval TOTAL_RENDER_DURATION:=$(call op_max, $(HERO_DURATION_TRIMMED), $(MAX_DURATION_TRIMMED)))
	$(eval TOTAL_RENDER_DURATION_ARG:=-t $(TOTAL_RENDER_DURATION))

	$(eval TIME_ARGUMENT:=$(call op_string_or, $(READ_TIME_OPTIONS), $(TOTAL_RENDER_DURATION_ARG)))

	@echo 5: $(HERO_DURATION_TRIMMED)
	@echo 6: $(MAX_DURATION_TRIMMED)
	@echo 7: $(TOTAL_RENDER_DURATION)
	@echo 8: $(TOTAL_RENDER_DURATION_ARG)
	@echo 9: $(TIME_ARGUMENT)

	$(FFMEG_BIN) \
		-y \
		-ss $(READ_ADVANCE_HERO) \
		-i $(HERO_JOIN_FILE) \
		-ss $(READ_ADVANCE_HERO) \
		-i $(HERO_WAVEFORM_FILE) \
		-ss $(READ_ADVANCE_MAX) \
		-i $(MAX_JOIN_FILE) \
		-ss $(READ_ADVANCE_MAX) \
		-i $(MAX_WAVEFORM_FILE) \
		-ss $(READ_ADVANCE_MAX) \
		-i $(TRACK_MAP_OVERVIEW_VIDEO) \
		-ss $(READ_ADVANCE_MAX) \
		-i $(TRACK_MAP_CHASE_VIDEO) \
		-filter_complex " \
			[0:v] setpts=PTS-STARTPTS,scale=$(HERO_GEOMETRY) [vsized0]; \
			[2:v] setpts=PTS-STARTPTS,scale=$(MAX_GEOMETRY) [vsized2]; \
			[vsized2][3:v] vstack [vmaxstack]; \
			[vmaxstack] pad=width=$(HERO_WIDTH_SCALED):x=(ow-iw):color=black [vmaxstackpad]; \
			[vsized0][1:v] vstack [vherostack]; \
			[vherostack][vmaxstackpad] vstack [leftstack]; \
			[4:v][5:v] vstack [rightstack]; \
			[leftstack][rightstack] hstack [out]; \
			[0:a] apad [0a_pad]; \
			[2:a] apad [1a_pad]; \
			[0a_pad] volume=$(READ_VOLUME_HERO) [left]; \
			[1a_pad] volume=$(READ_VOLUME_MAX) [right]; \
			[left][right] amerge=inputs=2,pan=stereo|c0<c0+c1|c1<c2+c3 \
			" \
		-map "[out]" \
		-b:v $(FULL_RENDER_OUTPUT_BITRATE) \
		$(TIME_ARGUMENT) \
		-r 23.98 \
		$@ > $@.log 2>&1
