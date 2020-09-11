#!/usr/bin/env ruby
require 'docopt'
require 'logger'
require 'nokogiri'
require 'json'

doc = <<DOCOPT
Concatenate, parse and process gpx files

Usage:
  #{__FILE__} [--output=<file>] <file>...

Options:
  -h --help         Show this screen.
  --output=<file>   Output filename [default: output.json].
DOCOPT

$logger = Logger.new(STDOUT)
$logger.level = Logger::DEBUG


def process(file_list, output_file)
  parsed_points = []
  start_time = nil

  $logger.info('Iterate through each file in the list')
  file_list.each { |file|
    $logger.info('For file: ' + file)
    body = File.open(file).read

    $logger.info('  load the xml')
    doc = Nokogiri.XML(body)

    $logger.info('  parse import the xml features')
    if start_time == nil then
      start_time = doc.css('metadata/time').text
      $logger.info('start_time: %s' % [start_time])
      # hack in a start time marker
      element = {}
      element['time'] = start_time
      element['lat'] = 0
      element['lon'] = 0
      element['ele'] = 0
      element['speed'] = 0
      parsed_points.append element
    end

    track_points = doc.css('trkseg/trkpt')
    track_points.each { |point|
      lat = point.attributes['lat'].to_s.to_f
      lon = point.attributes['lon'].to_s.to_f
      time_s = point.css('time').text
      ele = point.css('ele').text.to_s.to_f
      speed = point.css('gpxtpx|TrackPointExtension/gpxtpx|speed').text.to_f
      # $logger.info('%s - lat: %f, lon: %f, ele: %f, speed: %f' % [time_s, lat, lon, ele, speed])
      element = {}
      element['time'] = time_s
      element['lat'] = lat
      element['lon'] = lon
      element['ele'] = ele
      element['speed'] = speed
      parsed_points.append element
    }
    # pp track_points[0]
    # $logger.debug(doc.css('trkseg').children.length())
    pp parsed_points.length

    # $logger.info('  export the gps locations to output json file')
  }
  $logger.info('Write data to output json file ' + output_file)
  out_fd = File.write(output_file, JSON.pretty_generate(parsed_points))

end


def main(args)
  $logger.debug('args:')
  $logger.debug(args)
  input_files = args['<file>']
  output_file = args['--output']
  process input_files, output_file
end


if __FILE__ == $0
  begin
    args = Docopt::docopt(doc)
    # $logger.debug(args)
    main(args)
  rescue Docopt::Exit => e
    puts e.message
  end
end
