require 'rake/testtask'

desc 'run unit tests'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.test_files = FileList['test/*.rb']
  test.verbose = true
end

task :default => :test