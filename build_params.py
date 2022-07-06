#!/usr/bin/env python3
'''build_params.py

Generate build parmeters based on a file reference

Usage:
  build_params.py <file>
'''

import sys
import tempfile
import logging
import os.path
import json

logging.basicConfig(level=logging.INFO,
                    format='(%(threadName)-10s) %(message)-s')

try:
    import sh
    from docopt import docopt
except ImportError as e:
    installs = ['sh', 'docopt']
    sys.stderr.write('Error: %s\nTry:\n    pip install --user %s\n' % (e, ' '.join(installs)))
    sys.exit(1)


def get_build_params(filename):
    real_file = os.path.realpath(filename)
    real_dir = os.path.dirname(real_file)
    is_git_repo = os.path.exists(real_dir + '/.git')
    git_rev = None
    git_branch = None
    git_status = None
    if is_git_repo:
        git_rev = sh.git('-c', 'color.status=false', 'rev-parse', 'HEAD', _cwd=real_dir).strip()
        git_branch = sh.git('-c', 'color.status=false', 'branch', '--show-current', _cwd=real_dir).strip()
        git_status = sh.git('-c', 'color.status=false', 'status', '-s', filename, _cwd=real_dir).strip()

    params = {
        'real_file': real_file,
        'real_dir': real_dir,
        'is_git_repo': is_git_repo,
        'git_branch': git_branch,
        'git_rev': git_rev,
        'git_status': git_status,
    }
    return params



def main(args):
    logging.debug(args)
    filename = args['<file>']

    results = get_build_params(filename)
    print(json.dumps(results, sort_keys=True, indent=4, separators=(',', ': ')))


if __name__ == '__main__':
    arguments = docopt(__doc__)
    sys.exit(main(arguments))
