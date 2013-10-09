Dir.glob(File.expand_path('**/*.rake', File.dirname(__FILE__))) \
   .each { |r| import r }
