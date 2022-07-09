#!/usr/bin/env python3
'''create_waveform_video.py
Generate audio waveform progress video.

Usage:
  create_waveform_video.py <input_media_file> <total_seconds> [--output=<OUTPUT_FILE>] [--width=<WIDTH>] [--height=<HEIGHT>] [--channels=<CHANNELS>] [--fps=<FPS>]
  create_waveform_video.py (-h | --help)

Options:
  -h --help                 Show this screen.
  --output=<OUTPUT_FILE>    Output file name [default: waveform.mp4]
  --width=<WIDTH>           Width of the image [default: 2262]
  --height=<HEIGHT>         Width of the image [default: 200]
  --channels=<CHANNELS>     Set mono(1) or stereo(2) [default: 1]
  --fps=<FPS>               Override frames per second [default: 24]
'''
import sys
import copy

try:
    from cv2 import cv2
    from docopt import docopt
    import numpy as np
    from sksound.sounds import Sound
    import matplotlib.pyplot as plt
except ImportError as e:
    installs = ['opencv-python', 'docopt', 'numpy', 'scikit-sound', 'matplotlib']
    sys.stderr.write('Error: %s\nTry:\n    pip install --user %s\n' % (e, ' '.join(installs)))
    sys.exit(1)


def generate_waveform_image(input_file, height, width, channels):
    ''' Generate an waveform image, two dimensional representation of the input audio '''
    mysound = Sound(input_file)

    # print(repr(mysound.data.view()))
    # print(len(mysound.data))
    # print(repr(mysound))
    # print('rate:    %d' % mysound.rate)
    # print('samples: %d' % mysound.totalSamples)

    x = mysound.data

    dpi = 20
    # fig = plt.figure(dpi=dpi, figsize=(width / dpi, height / dpi))

    if channels == 2:
        plt.subplot(2, 1, 1)
        plt.axis([ 0, len(x[:,0]), int(-((2**16 / 2) - 1)), int(2**16 / 2)])
        plt.axis('off')
        plt.subplots_adjust(left=0, right=1, bottom=0, top=1)
        plt.plot(x[:, 0])

        plt.subplot(2, 1, 2)
        plt.axis([ 0, len(x[:,0]), int(-((2**16 / 2) - 1)), int(2**16 / 2)])
        plt.axis('off')
        plt.subplots_adjust(left=0, right=1, bottom=0, top=1)
        plt.plot(x[:, 1])
    else:
        plt.axis([ 0, len(x[:,0]), int(-((2**16 / 2) - 1)), int(2**16 / 2)])
        plt.axis('off')
        plt.subplots_adjust(left=0, right=1, bottom=0, top=1)
        plt.plot(x[:, 0])

    # plt.show()
    return plt


def generate_waveform_video(background_image, total_seconds, output_file, fps):
    image = cv2.imread(background_image)
    height, width, _ = image.shape

    frames = int(total_seconds * fps)
    color = (40, 40, 255)
    thickness = 2

    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
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
    input_file = args['<input_media_file>']
    output_file = args['--output']
    try:
        total_seconds = float(args['<total_seconds>'])
        height = int(args['--height'])
        width = int(args['--width'])
        channels = int(args['--channels'])
        fps = int(args['--fps'])
    except ValueError as e:
        print('Error: %s\n' % str(e))
        print(__doc__)
        return 2

    background_filename = output_file + '.background.png'

    im_background = generate_waveform_image(input_file, height, width, channels)
    im_background.savefig(background_filename)

    generate_waveform_video(background_filename, total_seconds, output_file, fps)

    return 0


if __name__ == '__main__':
    arguments = docopt(__doc__)
    sys.exit(main(arguments))
