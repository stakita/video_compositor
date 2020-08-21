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
import numpy as np
import copy

try:
    import cv2
except ImportError as e:
    sys.stderr.write('Error: %s\nTry:\n    pip install opencv-python\n' % e)
    sys.exit(1)


try:
    from docopt import docopt
except ImportError as e:
    sys.stderr.write('Error: %s\nTry:\n    pip3 install --user docopt\n' % e)
    sys.exit(1)

def generate_waveform_video(background_image, total_seconds, output_file, fps):
    image = cv2.imread(background_image)
    height, width, _ = image.shape

    frames = int(total_seconds * fps)
    color = (40, 40, 255)
    thickness = 2

    fourcc = cv2.VideoWriter_fourcc(*'MP42')
    video = cv2.VideoWriter(output_file, fourcc, float(fps), (width, height))

    for frame in range(frames):
        update_period = 1000
        if frame % update_period == 0:
            print('%3.2f %d %d' % (frame / 24, frame, frames))

        paint_x = int(frame / frames * width)

        frame = copy.copy(image)

        cv2.line(frame, (paint_x, 0), (paint_x, height), color, thickness)
        video.write(frame)

    video.release()


def main(args):
    # print(repr(args))
    background_image = args['<background_image>']
    output_file = args['--output']
    try:
        total_seconds = float(args['<total_seconds>'])
        fps = int(args['--fps'])
    except ValueError as e:
        print('Error: %s\n' % str(e))
        print(__doc__)
        return 2

    generate_waveform_video(background_image, total_seconds, output_file, fps)

    return 0


if __name__ == '__main__':
    arguments = docopt(__doc__)
    sys.exit(main(arguments))
