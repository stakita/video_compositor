#!/usr/bin/env bash

BUILD_CONFIG = config.py
BUILD_PARAMS = build_params.txt

HERO_RAW_FILES := $(wildcard hero5/*.MP4)
HERO_JOIN_CONFIG = hero_join_config.txt
HERO_JOIN_FILE = hero.join.mp4
HERO_AUDIO_FILE = hero.join.aac
HERO_WAVEFORM_PLOT = hero.wavform.plot.png
HERO_WAVEFORM_FILE = hero.wavform.avi
HERO_PLUS_WAVEFORM = hero_plus_waveform.mp4
HERO_RENDER = hero_render.mp4
HERO_OUTPUT_BITRATE = 30000k
HERO_SCALING_FACTOR = 0.75
HERO_GENERATED_FILES = hero.join.wav

MAX_RAW_FILES := $(wildcard max/*.LRV)
MAX_JOIN_CONFIG = max_join_config.txt
MAX_JOIN_FISHEYE_FILE = max.join.fisheye.mp4
MAX_JOIN_FILE = max.join.mp4
MAX_AUDIO_FILE = max.join.aac
MAX_WAVEFORM_PLOT = max.wavform.plot.png
MAX_WAVEFORM_FILE = max.wavform.avi
MAX_PLUS_WAVEFORM = max_plus_waveform.mp4
MAX_RENDER = max_render.mp4
MAX_OUTPUT_BITRATE = 30000k
MAX_SCALING_FACTOR = 1.0
MAX_GENERATED_FILES = max.join.wav

MERGED_OUTPUT_BITRATE = 30000k
MERGED_SBS = merge_sbs.mp4
MERGED_AUDIO = merged_audio.aac
MERGED_RENDER = merged_render.mp4

# HERO_RAW_FILES := hero5/*.MP4
# HERO_INTERMEDIATE_FILES = $(patsubst %.MP4, )
# MAX_RAW_FILES := max/*.LRV
# TIME_OPTIONS = -t 00:05:00.000
# If apad is enabled in the audio filter (different length video), you need to set a bounding time to complete:
# TIME_OPTIONS = -t 3433.592000
FFMEG_BIN = ~/bin/ffmpeg

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


all: $(BUILD_PARAMS) $(MERGED_RENDER) # merged_full.mp4

.PHONY: build_params all clean clobber distclean

$(BUILD_PARAMS): $(BUILD_CONFIG) Makefile
	@echo recording build parameters
	build_params.py Makefile > $@


clean:
	@echo "${BOLD}clean derivative files - leave join files${NONE}"
	rm -f $(HERO_AUDIO_FILE) $(HERO_WAVEFORM_PLOT) $(HERO_WAVEFORM_FILE) $(HERO_PLUS_WAVEFORM) $(HERO_RENDER) $(HERO_GENERATED_FILES)
	rm -f $(MAX_AUDIO_FILE) $(MAX_WAVEFORM_PLOT) $(MAX_WAVEFORM_FILE) $(MAX_PLUS_WAVEFORM) $(MAX_RENDER)

clobber: clean
	@echo "${BOLD}clobber - kill them all${NONE}"
	rm -f $(HERO_JOIN_CONFIG) $(HERO_JOIN_FILE)
	rm -f $(MAX_JOIN_CONFIG) $(MAX_JOIN_FILE) $(MAX_JOIN_FISHEYE_FILE)
	rm -f $(BUILD_CONFIG) $(BUILD_PARAMS)

distclean:
	@echo "${BOLD}distclean - leave final file and config${NONE}"
	rm -f $(HERO_AUDIO_FILE) $(HERO_WAVEFORM_PLOT) $(HERO_WAVEFORM_FILE) $(HERO_PLUS_WAVEFORM)
	rm -f $(HERO_JOIN_CONFIG) $(HERO_JOIN_FILE)
	#rm -f merged.wav waveform.avi waveplot.png audio_mix.aac


DEFAULT_CONFIG = "TIME_OPTIONS = '-t 00:05:00.000'\nADVANCE_MAX_SECONDS = 0.000\nADVANCE_HERO_SECONDS = 0.000\nVOLUME_HERO = 1.0\nVOLUME_MAX = 0.15\nHERO_AUDIO_OPTS = ', compand=attacks=0:decays=0.4:points=-30/-900|-20/-20|0/0|20/20'"

$(BUILD_CONFIG):
	@echo generate build config file
	@echo $(DEFAULT_CONFIG) > $@

#=======================================================================================================

# generate ffmpeg join config for hero files
$(HERO_JOIN_CONFIG): $(HERO_RAW_FILES)
	@echo "${BOLD}generate hero ffmpeg join config file${NONE}"
	FILE_LIST=`python -c "print('\n'.join(['file \'%s\'' % s for s in '$(HERO_RAW_FILES)'.split()]))"`; \
	echo "$$FILE_LIST" > $@

# join hero files
$(HERO_JOIN_FILE): $(HERO_JOIN_CONFIG)
	@echo "${BOLD}concat hero files${NONE}"
	$(FFMEG_BIN) -y -f concat -safe 0 -i $< -c copy $@

# mix audio tracks
$(HERO_AUDIO_FILE): $(HERO_JOIN_FILE) $(BUILD_CONFIG)
	@echo "${BOLD}extract time offset hero audio track${NONE}"
	$(FFMEG_BIN) \
		-y \
		-ss $(shell $(READ_ADVANCE_HERO)) \
		-i $(HERO_JOIN_FILE) \
		-filter_complex \
		"volume=$(shell $(READ_VOLUME_HERO))$(shell $(READ_HERO_AUDIO_OPTS))" \
		$@

# generate waveform plot
$(HERO_WAVEFORM_PLOT): $(HERO_JOIN_FILE) $(HERO_AUDIO_FILE)
	@echo "${BOLD}generate hero waveform plot${NONE}"
	HERO_JOIN_WIDTH=`video_geometry.py --width $(HERO_JOIN_FILE)`; \
	HERO_SCALED_WIDTH=`python -c "print(int($(HERO_SCALING_FACTOR) * $$HERO_JOIN_WIDTH))"` ; \
	gen_wave_plot.py --height=100 --channels=1 --width=$$HERO_SCALED_WIDTH $(HERO_AUDIO_FILE) --output=$@

# generate waveform file
$(HERO_WAVEFORM_FILE): $(HERO_JOIN_FILE) $(HERO_WAVEFORM_PLOT)
	@echo "${BOLD}generate waveform progress video${NONE}"
	DURATION_SECONDS=`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $(HERO_JOIN_FILE)`; \
	DURATION_TRIMMED=`python -c "print($$DURATION_SECONDS - $(shell $(READ_ADVANCE_HERO_SECONDS)))"`; \
	gen_waveform_slider.py $(HERO_WAVEFORM_PLOT) $$DURATION_SECONDS --output=$(HERO_WAVEFORM_FILE)

# combine video with waveform video
$(HERO_PLUS_WAVEFORM): $(HERO_JOIN_FILE) $(HERO_WAVEFORM_FILE) $(BUILD_CONFIG)
	@echo "${BOLD}combine hero and waveform video vertically${NONE}"

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
			[tmp1][bottom] overlay=shortest=1:y=$$TOP_HEIGHT_SCALED [out] \
			" \
		-map "[out]" \
		-b:v $(HERO_OUTPUT_BITRATE) \
		$(shell $(READ_TIME_OPTIONS)) \
		$@

# mix hereo audio and video
$(HERO_RENDER): $(HERO_PLUS_WAVEFORM) $(HERO_AUDIO_FILE) $(BUILD_CONFIG)
	@echo "${BOLD}mix hero render audio and video${NONE}"
	$(FFMEG_BIN) \
		-y \
		-i $(HERO_PLUS_WAVEFORM) \
		-i $(HERO_AUDIO_FILE) \
		-c copy \
		-acodec copy \
		-b:v $(HERO_OUTPUT_BITRATE) \
		$(shell $(READ_TIME_OPTIONS)) \
		$(HERO_RENDER)

#=======================================================================================================

# generate ffmpeg join config for max files
$(MAX_JOIN_CONFIG): $(MAX_RAW_FILES)
	@echo "${BOLD}generate max ffmpeg join config file${NONE}"
	FILE_LIST=`python -c "print('\n'.join(['file \'%s\'' % s for s in '$(MAX_RAW_FILES)'.split()]))"`; \
	echo "$$FILE_LIST" > $@

# join max files
$(MAX_JOIN_FISHEYE_FILE): $(MAX_JOIN_CONFIG)
	@echo "${BOLD}concat max files${NONE}"
	$(FFMEG_BIN) -y -f concat -safe 0 -i $< -c copy $@

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

# mix audio tracks
$(MAX_AUDIO_FILE): $(MAX_JOIN_FILE) $(BUILD_CONFIG)
	@echo "${BOLD}extract time offset max audio track${NONE}"
	$(FFMEG_BIN) \
		-y \
		-ss $(shell $(READ_ADVANCE_MAX)) \
		-i $(MAX_JOIN_FILE) \
		-filter:a "volume=$(shell $(READ_VOLUME_MAX))" \
		$@

# generate waveform plot
$(MAX_WAVEFORM_PLOT): $(MAX_JOIN_FILE) $(MAX_AUDIO_FILE)
	@echo "${BOLD}generate max waveform plot${NONE}"
	MAX_JOIN_WIDTH=`video_geometry.py --width $(MAX_JOIN_FILE)`; \
	MAX_SCALED_WIDTH=`python -c "print(int($(MAX_SCALING_FACTOR) * $$MAX_JOIN_WIDTH))"` ; \
	gen_wave_plot.py --height=100 --channels=1 --width=$$MAX_SCALED_WIDTH $(MAX_AUDIO_FILE) --output=$@

# generate waveform file
$(MAX_WAVEFORM_FILE): $(MAX_JOIN_FILE) $(MAX_WAVEFORM_PLOT)
	@echo "${BOLD}generate waveform progress video${NONE}"
	DURATION_SECONDS=`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $(MAX_JOIN_FILE)`; \
	DURATION_TRIMMED=`python -c "print($$DURATION_SECONDS - $(shell $(READ_ADVANCE_MAX_SECONDS)))"`; \
	gen_waveform_slider.py $(MAX_WAVEFORM_PLOT) $$DURATION_TRIMMED --output=$(MAX_WAVEFORM_FILE)

# combine video with waveform video
$(MAX_PLUS_WAVEFORM): $(MAX_JOIN_FILE) $(MAX_WAVEFORM_FILE) $(BUILD_CONFIG)
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
			[tmp1][bottom] overlay=shortest=1:y=$$TOP_HEIGHT_SCALED [out] \
			" \
		-map "[out]" \
		-b:v $(MAX_OUTPUT_BITRATE) \
		$(shell $(READ_TIME_OPTIONS)) \
		$@

# mix hereo audio and video
$(MAX_RENDER): $(MAX_PLUS_WAVEFORM) $(MAX_AUDIO_FILE) $(BUILD_CONFIG)
	@echo "${BOLD}mix hero render audio and video${NONE}"
	$(FFMEG_BIN) \
		-y \
		-i $(MAX_PLUS_WAVEFORM) \
		-i $(MAX_AUDIO_FILE) \
		-c copy \
		-acodec copy \
		-b:v $(MAX_OUTPUT_BITRATE) \
		$(shell $(READ_TIME_OPTIONS)) \
		$(MAX_RENDER)



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
$(MERGED_SBS): $(HERO_RENDER) $(MAX_RENDER) $(BUILD_CONFIG) # max.join.mp4
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
			nullsrc=size=$(GEOMETRY) [base]; \
			[0:v] setpts=PTS-STARTPTS [left]; \
			[1:v] setpts=PTS-STARTPTS [right]; \
			[base][left] overlay=shortest=1 [tmp1]; \
			[tmp1][right] overlay=shortest=1:x=$(left_width) [out] \
			" \
		-map "[out]" \
		-b:v $(MERGED_OUTPUT_BITRATE) \
		$(shell $(READ_TIME_OPTIONS)) \
		$@

# https://trac.ffmpeg.org/wiki/AudioChannelManipulation
# filter_audio = " \
# [0:a] volume=$(VOLUME_HERO) [left]; \
# [1:a] volume=$(VOLUME_MAX) [right]; \
# [left][right]amerge=inputs=2,pan=stereo|c0<c0+c1|c1<c2+c3[a] \
# "

# https://trac.ffmpeg.org/wiki/AudioChannelManipulation
filter_audio = " \
[0:a][1:a]amerge=inputs=2,pan=stereo|c0<c0+c1|c1<c2+c3[a] \
"

# mix audio tracks
$(MERGED_AUDIO): $(HERO_AUDIO_FILE) $(MAX_AUDIO_FILE)
	@echo "${BOLD}mix audio tracks${NONE}"
	$(FFMEG_BIN) \
		-y \
		-i $(HERO_AUDIO_FILE) \
		-i $(MAX_AUDIO_FILE) \
		-filter_complex $(filter_audio) \
		-map "[a]" \
		-q:a 4 \
		$(shell $(READ_TIME_OPTIONS)) \
		$@

# mix audio and video
$(MERGED_RENDER): merge_sbs.mp4 merged_audio.aac
	@echo "${BOLD}mix audio and video${NONE}"
	$(FFMEG_BIN) \
		-y \
		-i merge_sbs.mp4 \
		-i merged_audio.aac \
		-c copy \
		-acodec copy \
		-b:v $(MERGED_OUTPUT_BITRATE) \
		$(shell $(READ_TIME_OPTIONS)) \
		$@





