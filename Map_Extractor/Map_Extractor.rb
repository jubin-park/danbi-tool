# encoding: utf-8
# ruby 2.3.3p222 (2016-11-21 revision 56859) [x64-mingw32]

# Title   Map Extractor
# Author  InJung Chung(mu29gl@gmail.com)
# Date    2015.01.23

$:.unshift File.dirname($0)

require 'etc.rb'

$app_path = File.dirname(__FILE__) + "/"
$app_path = File.dirname(ENV["OCRA_EXECUTABLE"]) << "/" if ENV["OCRA_EXECUTABLE"]

# map.id, map.name, map.width, map.height, *passable

def blockMapExtract
  $data_tilesets = load_data("Data/Tilesets.rxdata")
  Game.init
  Dir.mkdir("./Map") if !FileTest.exist?("./Map")
  map_infos = load_data('Data/MapInfos.rxdata')
  map_infos.each do |k, v|
    Game.map.setup(k)
    puts mapfile = sprintf("Map/Map%d.map", k)
    File.open(mapfile, "w") do |fw|
      writeMapData(fw, k, v)
      fw.close
    end
  end
  puts "-" * 64
  print "맵 데이터 추출 완료"
  gets
end

def writeMapData(fw, id, info)
  map = load_data(sprintf("Data/Map%03d.rxdata", id))
  fw.write("#{id},#{info.name},#{Game.map.width},#{Game.map.height},")
  for y in 0...(Game.map.height)
    for x in 0...(Game.map.width)
      flag = Game.map.passable?(x, y, 0) ? 0 : 1
      fw.write("#{flag},")
    end
  end
end

blockMapExtract()