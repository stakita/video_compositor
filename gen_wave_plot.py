'''gen_wave_plot.py
Generate waveform plot of audio channels in input file (video/audio).

Usage:
  gen_wave_plot.py <input_media_file> [--output=<OUTPUT_FILE>] [--width=<WIDTH>] [--height=<HEIGHT>]
  gen_wave_plot.py (-h | --help)

Options:
  -h --help                 Show this screen.
  --output=<OUTPUT_FILE>    Output file name [default: waveplot.png]
  --width=<WIDTH>           Width of the image [default: 2262]
  --height=<HEIGHT>         Width of the image [default: 200]
'''
import sys
try:
    from docopt import docopt
except ImportError as e:
    sys.stderr.write('Error: %s\nTry:\n    pip3 install --user docopt\n' % e)
    sys.exit(1)

from sksound.sounds import Sound
import matplotlib.pyplot as plt

def gen_wave_plot(input_file, output_file, height, width):
    mysound = Sound(input_file)

    # print(repr(mysound.data.view()))
    # print(len(mysound.data))
    # print(repr(mysound))
    # print('rate:    %d' % mysound.rate)
    # print('samples: %d' % mysound.totalSamples)

    x = mysound.data

    dpi = 20
    fig = plt.figure(dpi=dpi, figsize=(width / dpi, height / dpi))

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

    # plt.show()
    plt.savefig('output_file')


def main(args):
    # print(repr(args))
    input_file = argv['<input_media_file>']
    output_file = argv['--output']
    try:
        height = int(argv['--height'])
        width = int(argv['--width'])
    except ValueError as e:
        print('Error: %s\n' % str(e))
        print(__doc__)
        return 2

    gen_wave_plot(input_file, output_file, height, width)

    return 0


if __name__ == '__main__':
    arguments = docopt(__doc__)
    sys.exit(main(arguments))