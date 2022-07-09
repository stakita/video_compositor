#!/usr/bin/env bash

# Configuration file for render settings
BUILD_CONFIG = config.py
# Snapshot of the makefile used in the build
BUILD_MAKEFILE = Makefile.build

HERO_RAW_FILES := $(wildcard hero5/*.MP4)
HERO_JOIN_CONFIG = hero_join_config.txt
HERO_JOIN_FILE = hero.join.mp4
HERO_AUDIO_FILE = hero.join.aac
HERO_WAVEFORM_FILE = hero.waveform.mp4
HERO_RENDER = hero_render.mp4
HERO_OUTPUT_BITRATE = 30000k
HERO_SCALING_FACTOR = 0.75
HERO_GENERATED_FILES = hero.join.wav hero.waveform.mp4.background.png

MAX_RAW_FILES := $(wildcard max/*.LRV)
MAX_JOIN_CONFIG = max_join_config.txt
MAX_JOIN_FISHEYE_FILE = max.join.fisheye.mp4
MAX_JOIN_FILE = max.join.mp4
MAX_AUDIO_FILE = max.join.aac
MAX_WAVEFORM_FILE = max.waveform.mp4
MAX_RENDER = max_render.mp4
MAX_OUTPUT_BITRATE = 30000k
MAX_SCALING_FACTOR = 1.0
MAX_GENERATED_FILES = max.join.wav max.waveform.mp4.background.png

MERGED_OUTPUT_BITRATE = 30000k
MERGED_SBS = merge_sbs.mp4
MERGED_AUDIO = merged_audio.aac
MERGED_RENDER = merged_render.mp4

MERGED_MAP_OUTPUT_BITRATE = 40000k
MERGED_MAP_RENDER = merged_map_render.mp4

WAVEFORM_VIDEO_TOOL = create_waveform_video.py

TRACK_GPX = track_gps.gpx
GOPRO2GPX_TOOL = gopro2gpx

TRACK_MAP_CACHE_DIR = tiles

TRACK_MAP_OVERVIEW_VIDEO_TOOL=create_overview_video
TRACK_MAP_OVERVIEW_VIDEO=map_overview.mp4

TRACK_MAP_CHASE_VIDEO_TOOL=create_chase_video
TRACK_MAP_CHASE_ZOOM_FACTOR=16
TRACK_MAP_CHASE_VIDEO=map_chase.mp4

TRACK_MAP_RENDER=track_map_render.mp4
TRACK_MAP_OUTPUT_BITRATE=10000k

TRACK_MAP_GENERATED_FILES = track_gps.kpx map_overview.mp4.background.png
TRACK_MAP_CACHED_FILES = $(wildcard $(TRACK_MAP_CACHE_DIR)/*.png)

# HERO_RAW_FILES := hero5/*.MP4
# TIME_OPTIONS = -t 00:05:00.000
# If apad is enabled in the audio filter (different length video), you need to set a bounding time to complete:
# TIME_OPTIONS = -t 3433.592000
FFMEG_BIN = ffmpeg

READ_TIME_OPTIONS = python -c "import config; print(config.TIME_OPTIONS)"
READ_ADVANCE_MAX_SECONDS = python -c "import config; print(config.ADVANCE_MAX_SECONDS)"
READ_ADVANCE_HERO_SECONDS = python -c "import config; print(config.ADVANCE_HERO_SECONDS)"
# next two lines horrible hacks - will get rid of these soon
READ_ADVANCE_MAX = python -c "h, r =divmod($(shell $(READ_ADVANCE_MAX_SECONDS)), 3600); m, s = divmod(r, 60); print('{:0>2}:{:0>2}:{:05.3f}'.format(int(h), int(m), s))"
READ_ADVANCE_HERO = python -c "h, r =divmod($(shell $(READ_ADVANCE_HERO_SECONDS)), 3600); m, s = divmod(r, 60); print('{:0>2}:{:0>2}:{:05.3f}'.format(int(h), int(m), s))"
READ_VOLUME_HERO = python -c "import config; print(config.VOLUME_HERO)"
READ_VOLUME_MAX = python -c "import config; print(config.VOLUME_MAX)"
READ_HERO_AUDIO_OPTS = python -c "import config; print(config.HERO_AUDIO_OPTS)"

NONE=\033[00m
RED=\033[01;31m
GREEN=\033[01;32m
YELLOW=\033[01;33m
PURPLE=\033[01;35m
CYAN=\033[01;36m
WHITE=\033[01;37m
BOLD=\033[1m
UNDERLINE=\033[4m

# echo -e "This text is ${RED}red${NONE} and ${GREEN}green${NONE} and ${BOLD}bold${NONE} and ${UNDERLINE}underlined${NONE}."


all: $(BUILD_MAKEFILE) $(MERGED_RENDER) # merged_full.mp4

.PHONY: all clean clobber distclean

$(BUILD_MAKEFILE): Makefile
	@echo "${BOLD}Snapshot the makefile used for the build${NONE}"
	cp Makefile Makefile.build

map: $(TRACK_MAP_RENDER) $(MERGED_MAP_RENDER)

clean:
	@echo "${BOLD}clean derivative files - leave join files${NONE}"
	rm -f $(HERO_AUDIO_FILE) $(HERO_WAVEFORM_PLOT) $(HERO_WAVEFORM_FILE) $(HERO_GENERATED_FILES)  $(HERO_RENDER)
	rm -f $(MAX_AUDIO_FILE) $(MAX_WAVEFORM_PLOT) $(MAX_WAVEFORM_FILE) $(MAX_RENDER) $(MAX_GENERATED_FILES)
	rm -f audio_test
	rm -f tilemap_close.avi tilemap_close.png tilemap_close.png.meta.txt tilemap_close.png.raw.png
	rm -f tilemap_wide.avi tilemap_wide.png tilemap_wide.png.meta.txt tilemap_wide.png.raw.png tilemap_wide.png.resize_crop.png

clobber: clean
	@echo "${BOLD}clobber - kill them all${NONE}"
	rm -f $(HERO_JOIN_CONFIG) $(HERO_JOIN_FILE)
	rm -f $(MAX_JOIN_CONFIG) $(MAX_JOIN_FILE) $(MAX_JOIN_FISHEYE_FILE)
	rm -f $(MERGED_SBS) $(MERGED_AUDIO) $(MERGED_RENDER)
	rm -f $(BUILD_CONFIG) $(BUILD_MAKEFILE)
	rm -f $(TRACK_MAP_CACHED_FILES)
	rm -rf __pycache__

distclean:
	@echo "${BOLD}distclean - leave final file and config${NONE}"
	rm -f $(HERO_AUDIO_FILE) $(HERO_WAVEFORM_PLOT) $(HERO_WAVEFORM_FILE) $(HERO_GENERATED_FILES)
	rm -f $(HERO_JOIN_CONFIG) $(HERO_JOIN_FILE)
	rm -f $(MAX_AUDIO_FILE) $(MAX_WAVEFORM_PLOT) $(MAX_WAVEFORM_FILE) $(MAX_GENERATED_FILES)
	rm -f $(MAX_JOIN_CONFIG) $(MAX_JOIN_FISHEYE_FILE) $(MAX_JOIN_FILE)
	rm -f $(MERGED_SBS) $(MERGED_AUDIO)
	rm -f audio_test
	rm -rf __pycache__
	rm -rf tiles
	rm -f tilemap_close.avi tilemap_close.png tilemap_close.png.meta.txt tilemap_close.png.raw.png
	rm -f tilemap_wide.avi tilemap_wide.png tilemap_wide.png.meta.txt tilemap_wide.png.raw.png tilemap_wide.png.resize_crop.png
	rm -f gps_inter.json join_gps.gpx.bin join_gps.gpx.kml


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
$(HERO_JOIN_CONFIG): $(HERO_RAW_FILES)
	@echo "${BOLD}generate hero ffmpeg join config file${NONE}"
	FILE_LIST=`python -c "print('\n'.join(['file \'%s\'' % s for s in '$(HERO_RAW_FILES)'.split()]))"`; \
	echo "$$FILE_LIST" > $@

# join hero files
$(HERO_JOIN_FILE): $(HERO_JOIN_CONFIG)
	@echo "${BOLD}concat hero files${NONE}"
	$(FFMEG_BIN) -y -f concat -safe 0 -i $< -c copy $@

# extract audio track - needed for generating audio waveform video
$(HERO_AUDIO_FILE): $(HERO_JOIN_FILE) $(BUILD_CONFIG)
	@echo "${BOLD}extract time offset hero audio track${NONE}"
	$(FFMEG_BIN) \
		-y \
		-ss $(shell $(READ_ADVANCE_HERO)) \
		-i $(HERO_JOIN_FILE) \
		-filter_complex \
		"volume=$(shell $(READ_VOLUME_HERO))$(shell $(READ_HERO_AUDIO_OPTS))" \
		$@

# generate waveform file
$(HERO_WAVEFORM_FILE): $(HERO_JOIN_FILE) $(HERO_AUDIO_FILE)
	@echo "${BOLD}generate waveform progress video${NONE}"
	MAX_JOIN_WIDTH=`video_geometry.py --width $(HERO_JOIN_FILE)`; \
	MAX_SCALED_WIDTH=`python -c "print(int($(HERO_SCALING_FACTOR) * $$MAX_JOIN_WIDTH))"` ; \
	DURATION_SECONDS=`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $(HERO_JOIN_FILE)`; \
	DURATION_TRIMMED=`python -c "print($$DURATION_SECONDS - $(shell $(READ_ADVANCE_HERO_SECONDS)))"`; \
	$(WAVEFORM_VIDEO_TOOL) \
		$(HERO_AUDIO_FILE) \
		$$DURATION_TRIMMED \
		--output=$(HERO_WAVEFORM_FILE) \
		--width=$$MAX_SCALED_WIDTH \
		--height=100 \
		--channels=1 

# combine video with waveform video
$(HERO_RENDER): $(HERO_JOIN_FILE) $(HERO_WAVEFORM_FILE) $(HERO_AUDIO_FILE) $(BUILD_CONFIG)
	@echo "${BOLD}combine hero and waveform video vertically and audio${NONE}"

	TOP_HEIGHT=`video_geometry.py --height $(HERO_JOIN_FILE)`; \
	TOP_HEIGHT_SCALED=`python -c "print(int($(HERO_SCALING_FACTOR) * $$TOP_HEIGHT))"` ; \
	TOP_WIDTH=`video_geometry.py --width $(HERO_JOIN_FILE)`; \
	TOP_WIDTH_SCALED=`python -c "print(int($(HERO_SCALING_FACTOR) * $$TOP_WIDTH))"` ; \
	echo TWS: $$TOP_WIDTH_SCALED; \
	echo THS: $$TOP_HEIGHT_SCALED; \
	BOTTOM_HEIGHT=`video_geometry.py --height $(HERO_WAVEFORM_FILE)`; \
	OUTPUT_WIDTH=$$TOP_WIDTH_SCALED; \
	OUTPUT_HEIGHT=`python -c "print($$TOP_HEIGHT_SCALED + $$BOTTOM_HEIGHT)"`; \
	TOP_GEOMETRY="$$TOP_WIDTH_SCALED"x"$$TOP_HEIGHT_SCALED"; \
	GEOMETRY="$$OUTPUT_WIDTH"x"$$OUTPUT_HEIGHT"; \
	echo G: $$GEOMETRY; \
	$(FFMEG_BIN) \
		-y \
		-ss $(shell $(READ_ADVANCE_HERO)) \
		-i $(HERO_JOIN_FILE) \
		-i $(HERO_WAVEFORM_FILE) \
		-filter_complex " \
			nullsrc=size=$$GEOMETRY [base]; \
			[0:v] setpts=PTS-STARTPTS,scale=$$TOP_GEOMETRY [top]; \
			[1:v] setpts=PTS-STARTPTS [bottom]; \
			[base][top] overlay=shortest=1 [tmp1]; \
			[tmp1][bottom] overlay=shortest=1:y=$$TOP_HEIGHT_SCALED [out]; \
			[0:a]volume=1.0" \
		-map "[out]" \
		-b:v $(HERO_OUTPUT_BITRATE) \
		$(shell $(READ_TIME_OPTIONS)) \
		$@


#=======================================================================================================

# generate ffmpeg join config for max files
$(MAX_JOIN_CONFIG): $(MAX_RAW_FILES)
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
	$(FFMEG_BIN) -y -f concat -safe 0 -i $< -c copy -map 0:v -map: 0:a -map: 0:3 $@

# map max files to hemispherical
$(MAX_JOIN_FILE): $(MAX_JOIN_FISHEYE_FILE)
	@echo "${BOLD}map max files to hemispherical${NONE}"
	$(FFMEG_BIN) \
		-y \
		-i $< \
		-vf v360=input=dfisheye:ih_fov=187:iv_fov=187:output=e:yaw=90 \
		-b:v 2500k \
		-c:a copy \
		$@

# mix audio track
$(MAX_AUDIO_FILE): $(MAX_JOIN_FILE) $(BUILD_CONFIG)
	@echo "${BOLD}extract time offset max audio track${NONE}"
	$(FFMEG_BIN) \
		-y \
		-ss $(shell $(READ_ADVANCE_MAX)) \
		-i $(MAX_JOIN_FILE) \
		-filter:a "volume=$(shell $(READ_VOLUME_MAX))" \
		$@

# generate waveform file
$(MAX_WAVEFORM_FILE): $(MAX_JOIN_FILE) $(MAX_AUDIO_FILE)
	@echo "${BOLD}generate waveform progress video${NONE}"
	MAX_JOIN_WIDTH=`video_geometry.py --width $(MAX_JOIN_FILE)`; \
	MAX_SCALED_WIDTH=`python -c "print(int($(MAX_SCALING_FACTOR) * $$MAX_JOIN_WIDTH))"` ; \
	DURATION_SECONDS=`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $(MAX_JOIN_FILE)`; \
	DURATION_TRIMMED=`python -c "print($$DURATION_SECONDS - $(shell $(READ_ADVANCE_MAX_SECONDS)))"`; \
	$(WAVEFORM_VIDEO_TOOL) \
		$(MAX_AUDIO_FILE) \
		$$DURATION_TRIMMED \
		--output=$(MAX_WAVEFORM_FILE) \
		--width=$$MAX_SCALED_WIDTH \
		--height=100 \
		--channels=1 

# combine video with waveform video
$(MAX_RENDER): $(MAX_JOIN_FILE) $(MAX_WAVEFORM_FILE) $(MAX_AUDIO_FILE) $(BUILD_CONFIG)
	@echo "${BOLD}combine hero and waveform video vertically${NONE}"

	TOP_HEIGHT=`video_geometry.py --height $(MAX_JOIN_FILE)`; \
	TOP_HEIGHT_SCALED=`python -c "print(int($(MAX_SCALING_FACTOR) * $$TOP_HEIGHT))"` ; \
	TOP_WIDTH=`video_geometry.py --width $(MAX_JOIN_FILE)`; \
	TOP_WIDTH_SCALED=`python -c "print(int($(MAX_SCALING_FACTOR) * $$TOP_WIDTH))"` ; \
	echo TWS: $$TOP_WIDTH_SCALED; \
	echo THS: $$TOP_HEIGHT_SCALED; \
	BOTTOM_HEIGHT=`video_geometry.py --height $(MAX_WAVEFORM_FILE)`; \
	OUTPUT_WIDTH=$$TOP_WIDTH_SCALED; \
	OUTPUT_HEIGHT=`python -c "print($$TOP_HEIGHT_SCALED + $$BOTTOM_HEIGHT)"`; \
	TOP_GEOMETRY="$$TOP_WIDTH_SCALED"x"$$TOP_HEIGHT_SCALED"; \
	GEOMETRY="$$OUTPUT_WIDTH"x"$$OUTPUT_HEIGHT"; \
	echo G: $$GEOMETRY; \
	$(FFMEG_BIN) \
		-y \
		-ss $(shell $(READ_ADVANCE_MAX)) \
		-i $(MAX_JOIN_FILE) \
		-i $(MAX_WAVEFORM_FILE) \
		-filter_complex " \
			nullsrc=size=$$GEOMETRY [base]; \
			[0:v] setpts=PTS-STARTPTS,scale=$$TOP_GEOMETRY [top]; \
			[1:v] setpts=PTS-STARTPTS [bottom]; \
			[base][top] overlay=shortest=1 [tmp1]; \
			[tmp1][bottom] overlay=shortest=1:y=$$TOP_HEIGHT_SCALED [out]; \
			[0:a]volume=1.0" \
		-map "[out]" \
		-b:v $(MAX_OUTPUT_BITRATE) \
		$(shell $(READ_TIME_OPTIONS)) \
		$@


#=======================================================================================================


$(TRACK_GPX): $(MAX_JOIN_FISHEYE_FILE)
	@# This tool adds the gpx (and kpx) extensions automatically, so we "basename" off the extension
	$(GOPRO2GPX_TOOL) -s -vv $< $(basename $@)

$(TRACK_MAP_OVERVIEW_VIDEO): $(TRACK_GPX)
	@# Create link to a tile cache directory
	ls $(TRACK_MAP_CACHE_DIR) || (mkdir -p /var/tmp/tiles && ln -s /var/tmp/tiles)
	$(TRACK_MAP_OVERVIEW_VIDEO_TOOL) $< --output=$@ --tile-cache=tiles


#-------------------------------------------------------------------------------------------------------


$(TRACK_MAP_CHASE_VIDEO): $(TRACK_GPX)
	@# Create link to a tile cache directory
	ls $(TRACK_MAP_CACHE_DIR) || (mkdir -p /var/tmp/tiles && ln -s /var/tmp/tiles)
	$(TRACK_MAP_CHASE_VIDEO_TOOL) $< $(TRACK_MAP_CHASE_ZOOM_FACTOR) --output=$@


$(TRACK_MAP_RENDER): $(TRACK_MAP_CHASE_VIDEO) $(TRACK_MAP_OVERVIEW_VIDEO)
	MAX_DURATION_SECONDS=`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $(MAX_JOIN_FILE)`; \
	TILEMAP_CLOSE_DURATION_SECONDS=`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $(TILE_MAP_CLOSE_VIDEO)`; \
	START_PAD=`python -c "print(round($$MAX_DURATION_SECONDS - $$TILEMAP_CLOSE_DURATION_SECONDS - $(shell $(READ_ADVANCE_MAX_SECONDS)), 2))"`; \
	echo start_pad: $$START_PAD; \
	$(FFMEG_BIN) \
		-y \
		-itsoffset $$START_PAD \
		-i $(TRACK_MAP_CHASE_VIDEO) \
		-itsoffset $$START_PAD \
		-i $(TRACK_MAP_OVERVIEW_VIDEO) \
		-filter_complex " \
			[0:v][1:v] vstack \
			" \
		-b:v $(MERGED_OUTPUT_BITRATE) \
		$(shell $(READ_TIME_OPTIONS)) \
		$@


#=======================================================================================================

# # [0:a][1:a]amerge=inputs=2[a];
# # [a][out]concat=n=2

# # filter="
# # [0:v]pad=iw[join.hero]+iw[join.max.hemi]:ih[int];[int][1:v]overlay=W/2:0[vid]' \
# #  -filter:a "channelmap=0-0|0-1|1-0|1-1" \

# https://trac.ffmpeg.org/wiki/Create%20a%20mosaic%20out%20of%20several%20input%20videos
# filter_video = " \
# 	nullsrc=size=$(GEOMETRY) [base]; \
# 	[0:v] setpts=PTS-STARTPTS [left]; \
# 	[1:v] setpts=PTS-STARTPTS [right]; \
# 	[base][left] overlay=shortest=1 [tmp1]; \
# 	[tmp1][right] overlay=shortest=1:x=$(RIGHT_OFFSET) [out] \
# 	"


# combine video into single side-by-side
$(MERGED_RENDER): $(HERO_RENDER) $(MAX_RENDER) $(BUILD_CONFIG)
	@echo "${BOLD}combine video into single side-by-side${NONE}"

	$(eval left_width := `video_geometry.py --width $(HERO_RENDER)`)
	$(eval right_width := `video_geometry.py --width $(MAX_RENDER)`)
	$(eval left_height := `video_geometry.py --height $(HERO_RENDER)`)
	$(eval right_height := `video_geometry.py --height $(MAX_RENDER)`)

	$(eval output_width := $(shell python -c "print($(left_width) + $(right_width))"))
	$(eval output_height := $(shell python -c "print(max($(left_height), $(right_height)))"))

	$(eval GEOMETRY := $(output_width)x$(output_height))

	$(FFMEG_BIN) \
		-y \
		-i $(HERO_RENDER) \
		-i $(MAX_RENDER) \
		-filter_complex " \
			color=size=$(GEOMETRY):duration=1.0:color=Black [base]; \
			[0:v] setpts=PTS-STARTPTS [left]; \
			[1:v] setpts=PTS-STARTPTS [right]; \
			[base][left] overlay=shortest=0 [tmp1]; \
			[tmp1][right] overlay=shortest=0:x=$(left_width) [out]; \
			[0:a][1:a] amerge=inputs=2,pan=stereo|c0<c0+c1|c1<c2+c3 \
			" \
		-map "[out]" \
		-b:v $(MERGED_OUTPUT_BITRATE) \
		$(shell $(READ_TIME_OPTIONS)) \
		$@


#=======================================================================================================

# combine video into single side-by-side
$(MERGED_MAP_RENDER):  $(TRACK_MAP_RENDER) #$(HERO_RENDER) $(MAX_RENDER)
	@echo "${BOLD}combine video and map renders into single view${NONE}"

	$(eval left_width := `video_geometry.py --width $(HERO_RENDER)`)
	$(eval right_width := `video_geometry.py --width $(MAX_RENDER)`)
	$(eval left_height := `video_geometry.py --height $(HERO_RENDER)`)
	$(eval right_height := `video_geometry.py --height $(MAX_RENDER)`)

	$(eval output_width := $(shell python -c "print($(left_width) + $(right_width))"))
	$(eval output_height := $(shell python -c "print(max($(left_height), $(right_height)))"))

	$(eval GEOMETRY := $(output_width)x$(output_height))

	$(eval TIME_MAX_RENDER := $(shell ffprobe -i $(MAX_RENDER) -show_entries format=duration -v quiet -of csv="p=0"))
	$(eval TIME_HERO_RENDER := $(shell ffprobe -i $(HERO_RENDER) -show_entries format=duration -v quiet -of csv="p=0"))
	$(eval TIME_FULL := $(shell python -c "print(max($(TIME_MAX_RENDER), $(TIME_HERO_RENDER)))"))

	$(FFMEG_BIN) \
		-y \
		-i $(HERO_RENDER) \
		-i $(MAX_RENDER) \
		-i $(TRACK_MAP_RENDER) \
		-filter_complex " \
			[1:v] pad=width=$(left_width):height=0:x=(ow-iw):y=0:color=black [vid1pad]; \
			[0:v][vid1pad] vstack [vintleft]; \
			[vintleft][2:v] hstack [out]; \
			[0:a] apad [0a_pad]; \
			[1:a] apad [1a_pad]; \
			[0a_pad][1a_pad] amerge=inputs=2,pan=stereo|c0<c0+c1|c1<c2+c3 \
			" \
		-map "[out]" \
		-b:v $(MERGED_MAP_OUTPUT_BITRATE) \
		-t $(TIME_FULL) \
		$@


