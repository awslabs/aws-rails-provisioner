require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('test') do |t|
   t.rspec_opts = "-I #{$REPO_ROOT}/lib"
   t.rspec_opts << " -I #{$REPO_ROOT}/spec"
   t.pattern = "#{$REPO_ROOT}/spec"
end
