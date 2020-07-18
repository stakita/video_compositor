#!/usr/bin/env bash

HERO_RAW_FILES := hero5/*.LRV
MAX_RAW_FILES := max/*.LRV
TIME_OPTIONS = #-t 00:01:00.000
ADVANCE_MAX = 00:00:00.000
ADVANCE_HERO = 00:00:02.029
VOLUME_HERO = 18.0
VOLUME_MAX = 0.15
FFMEG_BIN = ~/bin/ffmpeg

all: merged.mp4

clean:
	rm -f merged.mp4 merge_sbs.mp4 audio_mix.aac

distclean:
	rm -f merged.mp4 merge_sbs.mp4 audio_mix.aac hero.join.mp4 max.join.mp4 max.join.hemi.mp4

# join hero5 lrv files
hero.join.mp4: $(HERO_RAW_FILES)
	@echo concat hero5 files: $(HERO_RAW_FILES)
	concat_mp4.py $(HERO_RAW_FILES) --output=hero.join.mp4 --clobber

# join max lrv files
max.join.mp4: $(MAX_RAW_FILES)
	@echo concat max files
	concat_mp4.py $(MAX_RAW_FILES) --output=max.join.mp4

# map max files to hemispherical
max.join.hemi.mp4: max.join.mp4
	@echo map max files to hemispherical
	$(FFMEG_BIN) \
		-y \
		-i max.join.mp4 \
		-vf v360=input=dfisheye:ih_fov=187:iv_fov=187:output=e \
		-b:v 2500k \
		-c:a copy \
		max.join.hemi.mp4

# https://trac.ffmpeg.org/wiki/AudioChannelManipulation
filter_audio = " \
[0:a] volume=$(VOLUME_HERO) [left]; \
[1:a] volume=$(VOLUME_MAX) [right]; \
[left][right]amerge=inputs=2,pan=stereo|c0<c0+c1|c1<c2+c3[a] \
"

# mix audio tracks
audio_mix.aac: hero.join.mp4 max.join.hemi.mp4
	@echo mix audio tracks
	$(FFMEG_BIN) \
		-ss $(ADVANCE_HERO) \
		-i hero.join.mp4 \
		-ss $(ADVANCE_MAX) \
		-i max.join.hemi.mp4 \
		-filter_complex $(filter_audio) \
		-map "[a]" \
		-q:a 4 \
		$(TIME_OPTIONS) \
		audio_mix.aac

# # [0:a][1:a]amerge=inputs=2[a];
# # [a][out]concat=n=2

# # filter="
# # [0:v]pad=iw[join.hero]+iw[join.max.hemi]:ih[int];[int][1:v]overlay=W/2:0[vid]' \
# #  -filter:a "channelmap=0-0|0-1|1-0|1-1" \

# https://trac.ffmpeg.org/wiki/Create%20a%20mosaic%20out%20of%20several%20input%20videos
filter_video = " \
	nullsrc=size=$(GEOMETRY) [base]; \
	[0:v] setpts=PTS-STARTPTS [left]; \
	[1:v] setpts=PTS-STARTPTS [right]; \
	[base][left] overlay=shortest=1 [tmp1]; \
	[tmp1][right] overlay=shortest=1:x=$(RIGHT_OFFSET) [out] \
	"


# combine video into single side-by-side
merge_sbs.mp4: hero.join.mp4 max.join.hemi.mp4 # max.join.mp4
	@echo combine video into single side-by-side

	$(eval left_width := `video_geometry.py --width hero.join.mp4`)
	$(eval right_width := `video_geometry.py --width max.join.hemi.mp4`)
	$(eval left_height := `video_geometry.py --height hero.join.mp4`)
	$(eval right_height := `video_geometry.py --height max.join.hemi.mp4`)

	$(eval output_width := $(shell python -c "print($(left_width) + $(right_width))"))
	$(eval output_height := $(shell python -c "print(max($(left_height), $(right_height)))"))

	$(eval GEOMETRY := $(output_width)x$(output_height))

	$(FFMEG_BIN) \
		-ss $(ADVANCE_HERO) \
		-i hero.join.mp4 \
		-ss $(ADVANCE_MAX) \
		-i max.join.hemi.mp4 \
		-filter_complex " \
			nullsrc=size=$(GEOMETRY) [base]; \
			[0:v] setpts=PTS-STARTPTS [left]; \
			[1:v] setpts=PTS-STARTPTS [right]; \
			[base][left] overlay=shortest=1 [tmp1]; \
			[tmp1][right] overlay=shortest=1:x=$(left_width) [out] \
			" \
		-map "[out]" \
		-b:v 2500k \
		$(TIME_OPTIONS) \
		merge_sbs.mp4

# mix audio and video
merged.mp4: merge_sbs.mp4 audio_mix.aac
	@echo mix audio and video
	$(FFMEG_BIN) \
		-y \
		-i merge_sbs.mp4 \
		-i audio_mix.aac \
		-c copy \
		-acodec copy \
		-b:v 2500k \
		$(TIME_OPTIONS) \
		merged.mp4

