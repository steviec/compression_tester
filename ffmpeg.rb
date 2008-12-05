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
ROOT_DIR = File.dirname(__FILE__)

$:.reject! { |e| e.include? 'TextMate' }
require 'rubygems'
require 'yaml'
require 'benchmark'
require 'activesupport'
require 'fileutils'
require 'erb'
#require 'animoto_extensions'

class Ffmpeg
  attr_reader :presets, :results

  # ffmpeg frame sequences must start with a "1" frame  
  def self.rename_frame_sequence
    Dir['*.jpg'].each_with_index do |f, i| 
      target_filename = ("%06d" % (i + 1)) + '.jpg'
      FileUtils.mv(f, target_filename)
    end
  end
  
  def initialize
    load_presets
  end

  def test_compression(input_path, test_options)
    require 'benchmark'
    @results = []

    # version this test so that subsequent tests don't overwrite
    render_id = Time.now.strftime('%Y%m%d%H%M')
    output_dir = ROOT_DIR + "/output/#{render_id}"
    FileUtils.mkdir_p(output_dir)

    test_options.each_with_index do |test_option, index|
      @results[index] = {}

      # setup file paths
      output_filename = "#{index}.mp4"
      output_path = output_dir + '/' + output_filename

      # merge user specified options with default preset
      options = @presets[:h264]
      options.merge!( test_option )
    
      # special handling for multiple passes
      time = Benchmark.realtime do     
        (options[:pass] ? 2 : 1).times do |i|
          options[:pass] = i + 1 if options[:pass]
          final_options = options
          final_options.merge!(first_pass_overrides) if options[:pass] && options[:pass] == 1
          `#{ compile_ffmpeg_command(input_path, output_path, final_options) }`
        end
      end
    
      # setup results hash
      @results[index][:time] = time
      @results[index][:size] = File.size(output_path) / 1000.0 / 1000.0
      @results[index][:filename] = "../output/#{render_id}/#{output_filename}"
      @results[index][:options] = test_option
    end
    
    # create html
    output_path = ROOT_DIR + '/output/side_by_side.html'
    create_html(output_path)
    FileUtils.cp(output_path, output_dir) # make backup copy in versioned dir
  end
  
  def pretty_print_results
    puts "NAME\tTIME\tSIZE"
    @results.each_with_index do |result, index|
      puts "#{result[:filename]}\t#{'%.2f' % result[:time]}\t#{'%.2f' % result[:size]}"
    end
  end
  
  def create_html(output_path)
    rhtml = ERB.new( File.read('side_by_side.rhtml') )
    File.open(output_path, 'w') {|f| f.write( rhtml.result(binding) ) }
  end
  
  private

  def load_presets
    @presets = HashWithIndifferentAccess.new
    preset_dir = File.dirname(__FILE__) + '/presets'
    Dir[preset_dir + '/*'].each {|f| @presets.merge!(YAML.load_file(f)) }
  end
  
  # converts key/value pair to "-key value", handling blank values
  # and single quoting bad chars
  def serialize_option(key, value=nil)
    value = "'#{value}'" if value =~ /[()]/
    '-' + key.to_s + (value ? " #{value}" : '')
  end

  def compile_ffmpeg_command(input_path, output_path, options)
    options_string = options.collect{ |key,value| serialize_option(key, value) }.join(' ')
    "ffmpeg -i #{input_path} -y #{options_string} #{output_path}"
  end
  
end

# test:
# refs:
# qcomp: .5 - 1.0
# bt/b: 1000-3000
# me: dia/hex/umh
# subq: 5/6/7

test_options = [  {}, #using defaults
                  # { :qcomp => 1.0 },
                  # { :bt => '2000k', :b => '2000k'},
                  # { :bt => '3000k', :b => '3000k'},
                  # { :me => 'dia'},
                  # { :subq => 5 },
                  { :subq => 7 }]
                  

f = Ffmpeg.new
f.test_compression('/Users/stephenclifton/code/compression_tests/input/0RlQQf02medZl5XK0pOs0w/jpg/%06d.jpg', test_options)