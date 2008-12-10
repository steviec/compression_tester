# test:
# refs:
# qcomp: .5 - 1.0 (def .6)
# bt/b: 1000-3000
# me: dia/hex/umh
# subq: 5/6/7 (def 6)

require 'compression_test'

test_options = [  {}, #using defaults
                  # { :qcomp => 1.0 },
                  # { :bt => '2000k', :b => '2000k'},
                  # { :bt => '3000k', :b => '3000k'},
                  # { :me => 'dia'},
                  # { :subq => 5 },
                  { :subq => 7 }]
                  

CompressionTest.run(  
                      '/Users/stephenclifton/code/compression_tester/input/0RlQQf02medZl5XK0pOs0w/jpg/%06d.jpg',
                      '/Users/stephenclifton/code/compression_tester/output',
                      test_options
                      )