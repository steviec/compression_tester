# LINKS:
# http://www.itbroadcastanddigitalcinema.com/ffmpeg_howto.html#Generic_Syntax
# http://ffmpeg.x264.googlepages.com/mapping
# iPod encoding: http://lists.mplayerhq.hu/pipermail/ffmpeg-devel/2006-March/008990.html
#   http://iambaeba1.wordpress.com/
# crf vs 2-pass: http://forum.handbrake.fr/viewtopic.php?f=6&t=848&start=0
# TODO:
# "compresion test" -- precompress some vid to test optimal encoding
# (http://lists.mplayerhq.hu/pipermail/mplayer-users/2007-January/065236.html)

require 'rubygems'
require 'activesupport'

class Ffmpeg
  cattr_reader :presets
  
  class ExecutionError < StandardError; end

  # ffmpeg frame sequences must start with a "1" frame  
  def self.rename_frame_sequence(input_path)
    Dir[ File.dirname(input_path) + '/*.jpg' ].each_with_index do |f, i|
      target_filename = ("%06d" % (i + 1)) + '.jpg'
      puts "RENAMING: #{f} => #{target_filename}"
      FileUtils.mv(f, target_filename)
    end
  end
  
  def self.run(input_path, output_path, user_options={})
    # merge user specified options with default preset
    options = presets[:h264]
    
    # default bitrate type is variable, but if :cqp or :crf specified, use constant
    bitrate_type = (user_options[:cqp] || user_options[:crf]) ? :constant : :variable
    options.merge!( presets[bitrate_type] )
    
    # merge user overrides
    options.merge!( user_options )
    options.merge!( :threads => 0 ) # automatically chooses threading
    
    (options[:pass] ? 2 : 1).times do |i|
      final_options = options.dup
      if final_options[:pass]
        final_options[:pass] = i + 1
        final_options.merge!( presets[:first_pass_overrides]) if final_options[:pass] == 1        
      end
      system_call = compile_ffmpeg_command(input_path, output_path, final_options)
      puts "RUNNING: #{system_call}"

      output = []
      IO.popen(system_call + ' 2>&1') do |pipe|
        while line = pipe.gets
          output << line
        end
      end
      raise ExecutionError, "#{output.last}" unless $?.success?
    end
  end
  
  private

  def self.presets
    ff_presets = HashWithIndifferentAccess.new
    preset_dir = File.dirname(__FILE__) + '/presets'
    Dir[preset_dir + '/*'].each {|f| ff_presets.merge!(YAML.load_file(f)) }
    ff_presets
  end
  
  # converts key/value pair to "-key value", handling blank values
  # and single quoting bad chars
  def self.serialize_option(key, value=nil)
    value = "'#{value}'" if value =~ /[()]/
    '-' + key.to_s + (value ? " #{value}" : '')
  end

  def self.compile_ffmpeg_command(input_path, output_path, options)
    options_string = options.collect{ |key,value| serialize_option(key, value) }.join(' ')
    "ffmpeg -i #{input_path} -y #{options_string} #{output_path}"
  end
  
end