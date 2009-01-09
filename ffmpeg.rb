# LINKS:
# http://www.itbroadcastanddigitalcinema.com/ffmpeg_howto.html#Generic_Syntax
# http://ffmpeg.x264.googlepages.com/mapping
# http://forum.videohelp.com/
# http://forum.doom9.org/
# iPod encoding: http://lists.mplayerhq.hu/pipermail/ffmpeg-devel/2006-March/008990.html
#   http://iambaeba1.wordpress.com/
# crf vs 2-pass: http://forum.handbrake.fr/viewtopic.php?f=6&t=848&start=0
# TODO LONGTERM:
# "compresion test" -- precompress some vid to test optimal encoding
# (http://lists.mplayerhq.hu/pipermail/mplayer-users/2007-January/065236.html)
#
# presets
# http://trac.handbrake.fr/wiki/BuiltInPresets

# TODO SHORTERM:
# -use instance instead of class level run to store output information
# -use title/author/copyright metadata and pass to ffmpeg to brand our vids
#
# TODO REFACTOR:
# ffmpeg instance based
# - launch with params
# - sanity check params

require 'rubygems'
require 'fileutils'
require 'activesupport'

class Ffmpeg
  cattr_reader :presets
  
  class ExecutionError < StandardError; end

  class << self
    # ffmpeg frame sequences must start with a "1" frame  
    # TODO: only do if frame seq is illegal
    # check legal sequence!  make sure same name, in order -- *.jpg won't work, will bring in other jpgs
    def setup_frame_sequence(input_path)
      files = Dir[input_path].sort
      files.each_with_index do |f, i|
        target_filename = 'ffmpeg-' + ("%06d" % (i + 1)) + '.jpg'
        FileUtils.ln_s(f, File.join( File.dirname(f), target_filename))
      end    
    end
  
    def cleanup_frame_sequence(input_path)
      files = Dir[input_path].sort
      files.each_with_index do |f, i|
        target_filename = 'ffmpeg-' + ("%06d" % (i + 1)) + '.jpg'
        FileUtils.rm_f(File.join( File.dirname(f), target_filename))
      end    
    end
  
    # getting fuglier
    # TODO: make this a class instance
    # store input video/audio, params
    def run(*args)
      user_options = HashWithIndifferentAccess.new( args.extract_options! )
      input_path, output_path = args
      input_options, output_options = user_options[:input] || {}, user_options[:output] || {}

      # handle multiple inputs for muxing files
      mux = true if input_path.is_a?(Array)  # if input is array, assume it's audio & video we want to mux
      input_video = mux ? input_path[0] : input_path
    
      # merge user specified options with default preset
      # TODO: use output path extension to automatically determine, e.g.
      # options.merge!(presets[preset || output_type])
      preset = output_options.delete(:preset) || :h264
      output_options.reverse_merge!( presets[preset] )

      # TODO: figure out best way to set threads
      # "0" will bomb ntsc-dvd encodes, but works for mp4
      output_options.reverse_merge!( :threads => 0 )

      # create softlinks with sequence that fits ffmpeg requirements
      sequence = Dir[input_video].length > 1
    
      if sequence
        setup_frame_sequence(input_video)
        massaged_video_path = File.dirname(input_video) + '/ffmpeg-%06d.jpg'
        if mux
          input_path[0] = massaged_video_path
        else
          input_path = massaged_video_path
        end
      end

  # default bitrate type is variable, but if :cqp or :crf specified, use constant   
  #    bitrate_type = (output_options[:cqp] || output_options[:crf]) ? :constant : :variable
  #    options.merge!( presets[bitrate_type] )
    
      (output_options[:pass] ? 2 : 1).times do |i|
        final_options = output_options.dup
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

    # parse ffmpeg metadata information for a video/audio stream
    # NOTE: highly susceptible to breakage as we're relying on parsing
    # FFMPEG output that could easily change
    def metadata(input_path)
      info ={}
      output = `ffmpeg -i #{input_path}`
      field_mappings = {
        'Video' => [:codec, :format, :size, :rate],
        'Audio' => [:codec, :rate, :channels]
      }

      # find all output lines matching "Stream"
      streams = output.split(/\n/).select{ |l| l =~ /^\s*Stream #/ }
    
      # parse audio/video metadata according to field mapping
      streams.each do |s|
        field_mappings.each do |type, fields|
          if s =~ /#{type}:/ 
            data = s.split(/#{type}:/)[1].split(/,/).map{|v| v.strip }
            mapping = [fields, data.slice(0, fields.length)]
            info[type.downcase.to_sym] = Hash[*mapping.transpose.flatten]
          end
        end
      end  
      info
    end
  
    def presets
      ff_presets = HashWithIndifferentAccess.new
      preset_dir = File.dirname(__FILE__) + '/presets'
      Dir[preset_dir + '/*'].each { |f| ff_presets.merge!(YAML.load_file(f) || {}) }
      ff_presets
    end
    
    private
  
    # converts key/value pair to "-key value", handling blank values
    # and single quoting bad chars
    def serialize_option(key, value=nil)
      value = "'#{value}'" if value =~ /[()]/
      '-' + key.to_s + (value ? " #{value}" : '')
    end
  
    def serialize_options(options)
      options.collect{ |key,value| serialize_option(key, value) }.join(' ')
    end

    def compile_ffmpeg_command(input_path, output_path, input_options, output_options)
      # build options strings for input/output
      input_string = serialize_options(input_options)
      output_string = serialize_options(output_options)

      # handle multiple inputs for muxing
      input_path = [input_path] unless input_path.is_a?(Array)  # array-ify input path if not already array
      input_files_string = input_path.map{|path| "-i #{path}"}.join(' ')  # create multiple "-i <path>" entries

      # build complete command
      "ffmpeg #{input_string} #{input_files_string} -y #{output_string} #{output_path}"
    end
  
    def fix_metadata
      # pipe ffmpeg output to STDOUT and then specify filename in flvtool2
      # ffmpeg <blah blah> - | flvtool2 -U stdin video.flv
    end
  end
end