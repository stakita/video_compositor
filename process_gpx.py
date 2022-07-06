#!/usr/bin/env python3
'''process_gpx.py

Parse and transform gpx files

Usage:
  process_gpx.py [--output=<file>] <file>

Options:
  -h --help         Show this screen.
  --output=<file>   Output filename [default: output.json].
'''

import sys
import logging
import json

try:
    from docopt import docopt
    import xmltodict
except ImportError as e:
    installs = ['docopt', 'xmltodict']
    sys.stderr.write('Error: %s\nTry:\n    pip install --user %s\n' % (e, ' '.join(installs)))
    sys.exit(1)

logging.basicConfig(level=logging.INFO,
                    format='(%(threadName)-10s) %(message)-s')


def process_gpx(filename, output_file):
    parsed_points = []
    start_time = None

    logging.info('For file: ' + filename)
    with open(filename, 'r') as fd:
        body = fd.read()

    logging.info('  load the xml')
    doc = xmltodict.parse(body)

    logging.info('  parse import the xml features')
    if start_time is None:
        start_time = doc['gpx']['metadata']['time']
        logging.info('start_time: %s' % [start_time])
        # hack in a start time marker
        element = {}
        element['time'] = start_time
        element['lat'] = 0
        element['lon'] = 0
        element['ele'] = 0
        element['speed'] = 0
        parsed_points.append(element)

    track_points = doc['gpx']['trk']['trkseg']['trkpt']
    for point in track_points:
        lat = float(point['@lat'])
        lon = float(point['@lon'])
        time_s = point['time']
        ele = float(point['ele'])
        speed = float(point['extensions']['gpxtpx:TrackPointExtension']['gpxtpx:speed'])
        logging.info('%s - lat: %f, lon: %f, ele: %f, speed: %f' % (time_s, lat, lon, ele, speed))
        element = {}
        element['time'] = time_s
        element['lat'] = lat
        element['lon'] = lon
        element['ele'] = ele
        element['speed'] = speed
        parsed_points.append(element)

    # pp track_points[0]
    # $logger.debug(doc.css('trkseg').children.length())
    logging.debug('len(parsed_points): %d' % len(parsed_points))

    logging.info('Write data to output json file ' + output_file)
    output_json = json.dumps(parsed_points, indent=2, separators=(',', ': '))
    with open(output_file, 'w+') as fd:
        fd.write(output_json)


def main(args):
    logging.debug(args)
    input_file = args['<file>']
    output_file = args['--output']

    process_gpx(input_file, output_file)


if __name__ == '__main__':
    arguments = docopt(__doc__)
    sys.exit(main(arguments))
