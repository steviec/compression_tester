# test:
# refs:
# qcomp: .5 - 1.0 (def .6)
# bt/b: 1000-3000
# me: dia/hex/umh
# subq: 5/6/7 (def 6)

require 'compression_test'

test_options = [  {}, #using defaults
                  { :bt => '500k', :b => '500k', :pass => true},
                  { :bt => '1000k', :b => '1000k', :pass => true},                  
                  { :bt => '2000k', :b => '2000k', :pass => true},
                  { :bt => '500k', :b => '500k'},
                  { :bt => '1000k', :b => '1000k'},                  
                  { :bt => '2000k', :b => '2000k'},
                  { :bt => '3000k', :b => '3000k'},
                  { :qcomp => 0.4 },
                  { :qcomp => 1.0 },
                  { :me => 'dia'},
                  { :me => 'umh'},                  
                  { :subq => 5 },
                  { :subq => 7 }]
                  

CompressionTest.run(  
                      '/Users/stephenclifton/code/compression_tester/input/0RlQQf02medZl5XK0pOs0w/jpg/%06d.jpg',
                      '/Users/stephenclifton/code/compression_tester/output/0RlQQf02medZl5XK0pOs0w',
                      test_options
                      )
                      
CompressionTest.run(
                     '/Users/stephenclifton/code/compression_tester/input/U73dWfU0AYC0ZTdR5SKczA/jpg/%06d.jpg',
                      '/Users/stephenclifton/code/compression_tester/output/U73dWfU0AYC0ZTdR5SKczA',
                      test_options
)