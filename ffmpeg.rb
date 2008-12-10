# 
# ffmpeg -i %06d.jpg -acodec libfaac -ab 128k -vcodec libx264 -b 4M -flags +loop -cmp +chroma -partitions +parti8x8+parti4x4+partp8x8+partp4x4+partb8x8 -flags2 +dct8x8+wpred+bpyramid+mixed_refs -me_method umh -subq 7 -trellis 1 -refs 6 -bf 16 -directpred 3 -b_strategy 1 -coder 1 -me_range 16 -g 250 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -bt 4M -qcomp 0.6 -qmin 10 -qmax 51 -qdiff 4 -threads 0 low.mp4
# 
# ffmpeg -i %06d.jpg -acodec libfaac -ab 128k -vcodec libx264 -b 4M -flags +loop -cmp +chroma -partitions +parti8x8+parti4x4+partp8x8+partp4x4+partb8x8 -flags2 +dct8x8+wpred+bpyramid+mixed_refs -me_method umh -subq 7 -trellis 1 -refs 6 -bf 16 -directpred 3 -b_strategy 1 -coder 1 -me_range 16 -g 250 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -bt 4M -qcomp 0.6 -qmin 10 -qmax 51 -qdiff 4 -threads 0 low.mp4
# 
# 
# ffmpeg -i %06d.jpg -y -f mov -acodec libfaac -vcodec libx264 -coder 1 -flags +loop -cmp +chroma -partitions +parti4x4+partp8x8+partb8x8 -me umh -subq 5 -me_range 16 -g 250 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -rc_eq 'blurCplx^(1-qComp)' -qcomp 0.6 -qmin 10 -qmax 51 -qdiff 4 -refs 3 -bf 3 -trellis 1 -ab 128kb -b 1321k -f mov low2.mov

# LINKS:
# http://www.itbroadcastanddigitalcinema.com/ffmpeg_howto.html#Generic_Syntax
# http://ffmpeg.x264.googlepages.com/mapping

require 'rubygems'
require 'activesupport'

class Ffmpeg
  cattr_reader :presets

  # ffmpeg frame sequences must start with a "1" frame  
  def self.rename_frame_sequence
    Dir['*.jpg'].each_with_index do |f, i| 
      target_filename = ("%06d" % (i + 1)) + '.jpg'
      FileUtils.mv(f, target_filename)
    end
  end
  
  def self.run(input_path, output_path, user_options={})
    # merge user specified options with default preset
    options = presets[:h264]
    options.merge!( user_options )
    
    (options[:pass] ? 2 : 1).times do |i|
      final_options = options.dup
      if final_options[:pass]
        final_options[:pass] = i + 1
        final_options.merge!( presets[:first_pass_overrides]) if final_options[:pass] == 1        
      end
      command_string = compile_ffmpeg_command(input_path, output_path, final_options)
      puts "RUNNING: #{command_string}"
      `#{ command_string }`
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