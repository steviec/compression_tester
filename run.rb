# test:
# refs:
# qcomp: .5 - 1.0 (def .6)
# bt/b: 1000-3000
# me: dia/hex/umh
# subq: 5/6/7 (def 6)



# test_options = [  {}, #using defaults
#                   { :bt => '500k', :b => '500k', :pass => true},
#                   { :bt => '1000k', :b => '1000k', :pass => true},                  
#                   { :bt => '2000k', :b => '2000k', :pass => true},
#                   { :bt => '500k', :b => '500k'},
#                   { :bt => '1000k', :b => '1000k'},                  
#                   { :bt => '2000k', :b => '2000k'},
#                   { :bt => '3000k', :b => '3000k'},
#                   { :qcomp => 0.4 },
#                   { :qcomp => 1.0 },
#                   { :me => 'dia'},
#                   { :me => 'umh'},                  
#                   { :subq => 5 },
#                   { :subq => 7 }]

# CompressionTest.run(  '0RlQQf02medZl5XK0pOs0w',
#                       '/Users/stephenclifton/code/compression_tester/input/0RlQQf02medZl5XK0pOs0w/jpg/%06d.jpg',
#                       '/Users/stephenclifton/code/compression_tester/output/0RlQQf02medZl5XK0pOs0w',
#                       test_options
#                       )
#                       

require 'compression_test'
CT_ROOT = '/Users/stephenclifton/code/compression_tester/'

def process_one(label, format, kill_old_records)
  # setup paths
  input_root = CT_ROOT + "input/small/#{label}"
  input_sequence = input_root + '/*.jpg'
  input_audio = Dir[input_root + '/*.wav'].first
  output_root = CT_ROOT +  "output/#{label}"      
  
  # setup default test
  CompressionTester.initialize_db
  
  # purge old records with this label
  if kill_old_records
    CompressionTest.delete_all("label = '#{label}'")
    FileUtils.rm_rf(output_root)
  end
  
  FileUtils.mkdir_p(output_root)
  
  default_filename = input_root + "/#{label}.#{format}"
  test = CompressionTest.new
  test.format = format
  test.label = label
  test.size = '%.2f' % (File.size(default_filename) / 1024.0 / 1024.0)
  test.flags = " old mencoder settings "
  test.save
  FileUtils.cp(default_filename, output_root + "/#{test.filename}")
  
  # set different options to test
  test_options = [  { :preset => 'mp4_old'},
                    { :bt => '1000k', :b => '1000k'},
                    { :bt => '500k', :b => '500k', :pass => 2},
                    { :bt => '1000k', :b => '1000k', :pass => 2},
                    { :crf => 12},
                    { :crf => 14},                    
                    { :preset => 'iphone'},
                    { :preset => 'iphone', :crf => 12},                    
                    { :preset => 'iphone', :crf => 11},
    ]
  
  CompressionTester.run( label, [input_sequence, input_audio], output_root, format, test_options )
  CompressionTester.create_html( label, output_root)
end

small_vids = %w(
1zTZLtjTF4Ml0OEMqTakwQ
91pd5FC07QPbN2V0qtfRjA
M6cPfqadYrkvX512DMiwag
QNwMUrvpJsHpnZgGFPK9WA
jqn050bhWIApvrVeCuXASQ
yHP1pRl0HWYoLJaREzxfIA
6vG9SQ66um1l81R0HCHeyQ
IS5R7OkjA0QSFtuQHCUcJg
OLUrS1Sto1hMob5VbsfcmQ
WbI35ONGJVDutIijJrUitw
p5oM1MYLE270fk0sN5Ml4Q
)

#small_vids.each{|o| process_one(o) }

large_vids = %w(
0RlQQf02medZl5XK0pOs0w
U73dWfU0AYC0ZTdR5SKczA
)