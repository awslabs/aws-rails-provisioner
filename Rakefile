require 'rspec/core/rake_task'

$REPO_ROOT = File.dirname(__FILE__)
$LOAD_PATH.unshift(File.join($REPO_ROOT, 'lib'))
$VERSION = ENV['VERSION'] || File.read(File.join($REPO_ROOT, 'VERSION')).strip

task 'test:coverage:clear' do
  sh("rm -rf #{File.join($REPO_ROOT, 'coverage')}")
end

desc 'run unit tests'
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = "-I #{$REPO_ROOT}/lib -I #{$REPO_ROOT}/spec"
  t.pattern = "#{$REPO_ROOT}/spec"
end

task :spec => 'test:coverage:clear'
task :default => :spec
task 'release:test' => :spec

Dir.glob('**/*.rake').each do |task_file|
  load task_file
end
