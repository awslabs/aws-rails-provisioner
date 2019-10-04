desc 'Delete the locally generated docs' if ENV['ALL']
task 'docs:clobber' do
  rm_rf '.yardoc'
  rm_rf 'doc'
  rm_rf 'docs.zip'
end

desc 'Generates api-docs.zip'
task 'docs:zip' => 'docs' do
  sh('zip -9 -r -q docs.zip doc/')
end

desc 'Generate the API documentation.'
task 'docs' => 'docs:clobber' do
  env = {}
  env['DOCSTRINGS'] = '1'
  env['BASEURL'] = 'http://docs.aws.amazon.com/'
  env['SITEMAP_BASEURL'] = 'http://docs.aws.amazon.com/awsrailsprovisioner/api/'
  sh(env, 'bundle exec yard')
end
