# LINKS:
# http://www.itbroadcastanddigitalcinema.com/ffmpeg_howto.html#Generic_Syntax
# http://ffmpeg.x264.googlepages.com/mapping
# iPod encoding: http://lists.mplayerhq.hu/pipermail/ffmpeg-devel/2006-March/008990.html
#   http://iambaeba1.wordpress.com/
# crf vs 2-pass: http://forum.handbrake.fr/viewtopic.php?f=6&t=848&start=0
# TODO LONGTERM:
# "compresion test" -- precompress some vid to test optimal encoding
# (http://lists.mplayerhq.hu/pipermail/mplayer-users/2007-January/065236.html)
#
# TODO SHORTERM:
# -use instance instead of class level run to store output information

require 'rubygems'
require 'fileutils'
require 'activesupport'

class Ffmpeg
  cattr_reader :presets
  
  class ExecutionError < StandardError; end

  # ffmpeg frame sequences must start with a "1" frame  
  def self.setup_frame_sequence(input_path)
    files = Dir[input_path].sort
    files.each_with_index do |f, i|
      target_filename = ("%06d" % (i + 1)) + '.jpg'
      FileUtils.ln_s(f, File.join( File.dirname(f), target_filename))
    end    
  end
  
  def self.cleanup_frame_sequence(input_path)
    files = Dir[input_path].sort
    files.each_with_index do |f, i|
      target_filename = ("%06d" % (i + 1)) + '.jpg'
      FileUtils.rm_f(File.join( File.dirname(f), target_filename))
    end    
  end
  
  def self.run(input_path, output_path, input_options={}, output_options={})
    options = HashWithIndifferentAccess.new

    # handle multiple inputs for muxing files
    mux = true if input_path.is_a?(Array)  # if input is array, assume it's audio & video we want to mux
    input_video = mux ? input_path[0] : input_path
    sequence = Dir[input_video].length > 1
    
    # merge user specified options with default preset
    # TODO: use output path extension to automatically determine, e.g.
    # options.merge!(presets[preset || output_type])
    options.merge!( presets[:h264] )

    # create softlinks with sequence that fits ffmpeg requirements
    setup_frame_sequence(input_video) if sequence

    # default bitrate type is variable, but if :cqp or :crf specified, use constant
    bitrate_type = (output_options[:cqp] || output_options[:crf]) ? :constant : :variable
    options.merge!( presets[bitrate_type] )
    
    # merge user overrides
    options.merge!( output_options )
    options.merge!( :threads => 0 ) # automatically chooses threading
    
    (options[:pass] ? 2 : 1).times do |i|
      final_options = options.dup
      if final_options[:pass]
        final_options[:pass] = i + 1
        final_options.merge!( presets[:first_pass_overrides]) if final_options[:pass] == 1        
      end
      system_call = compile_ffmpeg_command(input_path, output_path, input_options, final_options)
      puts "RUNNING: #{system_call}"

      output = []
      IO.popen(system_call + ' 2>&1') do |pipe|
        while line = pipe.gets
          output << line
        end
      end
      raise ExecutionError, "#{output.last}" unless $?.success?
    end

  ensure
    cleanup_frame_sequence(input_video) if sequence
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
  
  def self.serialize_options(options)
    options.collect{ |key,value| serialize_option(key, value) }.join(' ')
  end

  def self.compile_ffmpeg_command(input_path, output_path, input_options, output_options)
    # build options strings for input/output
    input_string = serialize_options(input_options)
    output_string = serialize_options(output_options)

    # handle multiple inputs for muxing
    input_path = [input_path] unless input_path.is_a?(Array)  # array-ify input path if not already array
    input_files_string = input_path.map{|path| "-i #{path}"}.join(' ')  # create multiple "-i <path>" entries

    # build complete command
    "ffmpeg #{input_string} #{input_files_string} -y #{output_string} #{output_path}"
  end
  
end