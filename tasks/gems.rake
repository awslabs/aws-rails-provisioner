desc 'Builds the aws-rails-provisioner gem'
task 'gems:build' do
  sh("rm -f *.gem")
  sh("gem build aws-rails-provisioner.gemspec")
end

task 'gems:push' do
  sh("gem push aws-rails-provisioner-#{$VERSION}.gem")
end
