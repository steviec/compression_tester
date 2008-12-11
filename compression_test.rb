# fix for annoying textmate issue when running from TM
$:.reject! { |e| e.include? 'TextMate' }

require 'rubygems'
require 'yaml'
require 'fileutils'
require 'activerecord'
require 'activesupport'
require 'benchmark'
require 'erb'

# my libs
require 'ffmpeg'

# TODO
# -split into CompressionTester and CompressionTest, like Migrator/Migration

class CompressionTest < ActiveRecord::Base
  attr_accessible :label, :time, :size, :flags, :error
  
  def self.run(label, input_path, output_dir, test_options)
    initialize_db
    FileUtils.mkdir_p(output_dir)
    
    test_options.each do |test_option|
      ct = CompressionTest.new
      ct.label = label
      ct.save
      
      # setup file paths
      output_path = "#{output_dir}/#{ct.filename}"

      # special handling for multiple passes
      time = Benchmark.realtime do
        puts "FFMPEG: using options: #{test_option.inspect}"
        Ffmpeg.run(input_path, output_path, test_option)
      end
    
      ct.error = "Could not find output file: #{output_path}" unless File.exists?(output_path)
      ct.update_attributes!( :time => time, :size => File.size(output_path), :flags => test_option)
    end
    
    # create html
    create_html(output_dir + '/side_by_side.html')
  end
  
  # def pretty_print_results
  #   puts "NAME\tTIME\tSIZE"
  #   @results.each_with_index do |result, index|
  #     puts "#{result[:filename]}\t#{'%.2f' % result[:time]}\t#{'%.2f' % result[:size]}"
  #   end
  # end
  #
  
  def self.initialize_db
    # setup connection
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.establish_connection(
        :adapter => "sqlite3",
        :dbfile  => "db/compression_tests.sqlite"
    )
    
    # create tables if they don't exist
    unless File.exists?('db/compression_tests.sqlite')
      ActiveRecord::Schema.define do
        create_table :compression_tests do |table|
          table.column :time, :string
          table.column :size, :string
          table.column :flags, :string
          table.column :error, :string
          table.column :label, :string
        end
      end
    end
  end

  def self.create_html(label, output_path)
    # copy all source files over
    FileUtils.cp(Dir['public/*'], File.dirname(output_path))
    
    # generate html file
    @@results = CompressionTest.find(:all, :conditions => ["label == ?", label])
    rhtml = ERB.new( File.read('side_by_side.rhtml') )
    File.open(output_path, 'w') {|f| f.write( rhtml.result(binding) ) }
  end
  
  def filename
    "#{id}.mp4"
  end

end



