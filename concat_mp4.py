#!/usr/bin/env python3
'''concat_mp4

Usage:
  concat_mp4 [--clobber] --output=FILE [<files>...]

Options:
  -o FILE --output=FILE
  -c --clobber
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
except ImportError as e:
    installs = ['sh', 'docopt']
    sys.stderr.write('Error: %s\nTry:\n    pip install --user %s\n' % (e, ' '.join(installs)))
    sys.exit(1)


def main(args):
    logging.debug(args)
    input_files = args['<files>']
    output_file = args['--output']
    clobber = args['--clobber']

    if output_file[-4:].lower() != '.mp4':
        output_file += '.mp4'

    if output_file[-4:].lower() != '.mp4':
        output_file += '.mp4'

    if not clobber and os.path.exists(output_file):
        sys.stderr.write('Error: Output file %s exists. Exiting.\n' % output_file)
        return 1

    fd, tmp_fpath = tempfile.mkstemp()
    try:
        with open(tmp_fpath, 'w+t') as temp:
            logging.debug(tmp_fpath)
            for filename in input_files:
                if not os.path.exists(filename):
                    sys.stderr.write('Error: Missing input file %s. Exiting.\n' % filename)
                    return 1
                temp.write('file \'%s\'\n' % os.path.abspath(filename))

        logging.debug('tmp_fpath: %s' % tmp_fpath)
        sh.ffmpeg('-y', '-safe', '0', '-f', 'concat', '-i', tmp_fpath, '-c', 'copy', output_file)

    finally:
        # os.remove(tmp_fpath)
        pass

if __name__ == '__main__':
    arguments = docopt(__doc__)
    sys.exit(main(arguments))