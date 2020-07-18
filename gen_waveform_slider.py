#!/usr/bin/env python3
'''gen_waveform_slider.py
Generate waveform progress slider overlay.

Usage:
  gen_waveform_slider.py <background_image> <total_seconds> [--output=<OUTPUT_FILE>] [--fps=<FPS>]
  gen_waveform_slider.py (-h | --help)

Options:
  -h --help                 Show this screen.
  --output=<OUTPUT_FILE>    Output file name [default: waveform.avi]
  --fps=<FPS>               Override frames per second [default: 24]
'''
import sys
import cv2
import numpy as np
from cv2 import VideoWriter, VideoWriter_fourcc
import copy


try:
    from docopt import docopt
except ImportError as e:
    sys.stderr.write('Error: %s\nTry:\n    pip3 install --user docopt\n' % e)
    sys.exit(1)

def generate_waveform_video(background_image, total_seconds, output_file, fps):
    image = cv2.imread(background_image)
    height, width, _ = image.shape

    video = VideoWriter(output_file, fourcc, float(fps), (width, height))

    frames = int(total_seconds * fps)
    color = (40, 40, 255)
    thickness = 2

    fourcc = VideoWriter_fourcc(*'MP42')
    video = VideoWriter(output_file, fourcc, float(fps), (width, height))

    for frame in range(frames):
        if frame % 24 == 0:
            print(frame / 24, frame, frames)

        paint_x = int(frame / frames * width)

        frame = copy.copy(image)

        cv2.line(frame, (paint_x, 0), (paint_x, height), color, thickness)
        video.write(frame)

    video.release()


def main(argv):
    # print(repr(argv))
    background_image = argv['<background_image>']
    output_file = argv['--output']
    try:
        total_seconds = int(argv['<total_seconds>'])
        fps = int(argv['--fps'])
    except ValueError as e:
        print('Error: %s\n' % str(e))
        print(__doc__)
        return 2

    generate_waveform_video(background_image, total_seconds, output_file, fps, width, height)

    return 0


if __name__ == '__main__':
    arguments = docopt(__doc__)
    sys.exit(main(arguments))
