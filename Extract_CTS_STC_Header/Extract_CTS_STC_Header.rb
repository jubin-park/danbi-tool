# encoding: utf-8

# 2017.08.02
# ruby 2.3.3p222 (2016-11-21 revision 56859) [x64-mingw32]

require 'zlib'
$:.unshift File.dirname($0)

$app_path = File.dirname(__FILE__) + "/"
$app_path = File.dirname(ENV["OCRA_EXECUTABLE"]) << "/" if ENV["OCRA_EXECUTABLE"]

$dirname = "CTS_STC_Header_Constants_List" << "/"

def load_data(filename)
  File.open(filename, "rb") { |f|
    obj = Marshal.load(f)
  }
end

def create_CTS_STC_Constants(filename, ctsname, stcname, ctsname_p, stcname_p)

  Dir.mkdir($app_path + $dirname) rescue $!

  filename = $app_path + filename
  ctsname = $app_path + $dirname + ctsname
  stcname = $app_path + $dirname + stcname
  ctsname_p = $app_path + $dirname + ctsname_p
  stcname_p = $app_path + $dirname + stcname_p

  data = load_data(filename)

  isCTSFounded = false
  isSTCFounded = false
  script_CTS = ""
  script_STC = ""
  
  for i in 0...data.size
    break if isCTSFounded && isSTCFounded
    script = Zlib::Inflate.inflate(data[i][2]).force_encoding("UTF-8")
    if script.include?("module CTSHeader")
      isCTSFounded = true
      script_CTS = script
      eval(script_CTS)
    end
    if script.include?("module STCHeader")
      isSTCFounded = true
      script_STC = script
      eval(script_STC)
    end
  end

  # CTS

  @old_L = 0
  if isCTSFounded
    @f = File.open(ctsname, "wb")
    @f.write "package packet;\r\n\r\n"
	@f.write "public final class CTSHeader {\r\n"
    CTSHeader.constants.each do |c|
      value = CTSHeader.const_get(c).to_i
      line = value / 100
      if @old_L != line
        @f.write("\r\n")
        @old_L = line
      end
      @f.write("\tpublic final static int #{c} = #{value};")
      @f.write("\r\n")
    end
    @f.write("}")
    @f.close
  end

  @old_L = 0
  if isCTSFounded
    @f = File.open(ctsname_p, "wb")
    CTSHeader.constants.each do |c|
      value = CTSHeader.const_get(c).to_i
      line = value / 100
      if @old_L != line
        @f.write("\r\n")
        @old_L = line
      end
      @f.write("#{c} = #{value}")
      @f.write("\r\n")
    end
    @f.close
  end

  # STC

  @old_L = 0
  if isSTCFounded
    @f = File.open(stcname, "wb")
    @f.write "package packet;\r\n\r\n"
	@f.write "public final class STCHeader {\r\n"
    STCHeader.constants.each do |c|
      value = STCHeader.const_get(c).to_i
      line = value / 100
      if @old_L != line
        @f.write("\r\n")
        @old_L = line
      end
      @f.write("\tpublic final static int #{c} = #{value};")
      @f.write("\r\n")
    end
    @f.write("}")
    @f.close
  end

  @old_L = 0
  if isSTCFounded
    @f = File.open(stcname_p, "wb")
    STCHeader.constants.each do |c|
      value = STCHeader.const_get(c).to_i
      line = value / 100
      if @old_L != line
        @f.write("\r\n")
        @old_L = line
      end
      @f.write("#{c} = #{value}")
      @f.write("\r\n")
    end
    @f.close
  end

end

begin
	create_CTS_STC_Constants("Scripts.rxdata",
   "CTSHeader-java.txt", "STCHeader-java.txt",
   "CTSHeader-plain.txt", "STCHeader-plain.txt")
	puts "*" * 64
  puts "패킷 헤더상수들을 추출하였습니다."
  puts "\"" + $dirname[0...-1] + "\" 폴더를 확인하세요."
  puts "-" * 64
  puts "엔터 키를 눌러 종료하세요."
	gets
end