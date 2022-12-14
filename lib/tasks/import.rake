require 'rake'
require './ad_parameters'

desc 'process XML file'
task :import, [:filename] do |tasks, args|
  args.with_defaults(:filename => './file.xml')
  puts AdParameters.new(args[:filename]).execute
end