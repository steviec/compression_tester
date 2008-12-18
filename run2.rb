AVFILE_PATH = '/home/render_worker/current/lib'
FFMPEG_PATH = '/tmp/compression_tester'
$LOAD_PATH.unshift(AVFILE_PATH)
$LOAD_PATH.unshift(FFMPEG_PATH)

test_options = [  { :refs => 6, :bf => 16 },
                  { :refs => 6, :bf => 16, :crf => 16},
                  { :refs => 6, :bf => 16, :crf => 20},
                  { :refs => 6, :bf => 16, :crf => 24}]
                  
                  
CompressionTest.run( 'U73dWfU0AYC0ZTdR5SKczA',
                     '/Users/stephenclifton/code/compression_tester/input/U73dWfU0AYC0ZTdR5SKczA/jpg/%06d.jpg',
                      '/Users/stephenclifton/code/compression_tester/output/U73dWfU0AYC0ZTdR5SKczA',
                      test_options
)

