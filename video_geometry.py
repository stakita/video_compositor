#!/usr/bin/env python3
'''video_geometry.py

Usage:
  video_geometry.py [--width] [--height] <file>

Options:
  -w, --width    Display width
  -h, --height   Display height
'''

import sys
import tempfile
import logging
import os.path

logging.basicConfig(level=logging.INFO,
                    format='(%(threadName)-10s) %(message)-s')

try:
    import sh
    from docopt import docopt
    import ffmpeg
except ImportError as e:
    installs = ['sh', 'docopt', 'ffmpeg-python']
    sys.stderr.write('Error: %s\nTry:\n    pip install --user %s\n' % (e, ' '.join(installs)))
    sys.exit(1)


def main(args):
    logging.debug(args)
    filename = args['<file>']
    display_width = args['--width']
    display_height = args['--height']

    results = ffmpeg.probe(filename)

    geometry = None

    for stream in results['streams']:
        if stream['codec_type'] == 'video':
            stream_geometry = (stream['width'], stream['height'])
            if geometry is None:
                geometry = stream_geometry
            else:
                if geometry != stream_geometry:
                    logging.error('Multiple video streams with differing geometry')

    if display_width:
        print(geometry[0])
    elif display_height:
        print(geometry[1])
    else:
        print(geometry[0], geometry[1])


if __name__ == '__main__':
    arguments = docopt(__doc__)
    sys.exit(main(arguments))
