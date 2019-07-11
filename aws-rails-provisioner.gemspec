Gem::Specification.new do |spec|
  spec.name         = "aws-rails-provisioner"
  spec.version      = File.read(File.expand_path('../VERSION', __FILE__)).strip 
  spec.authors      = ["Amazon Web Services"]
  spec.email        = ["chejingy@amazon.com"]
  spec.summary      = "aws-rails-provisioner"
  spec.description  = "Define and deploy containerized Ruby on Rails Applications on AWS."
  spec.homepage     = "http://github.com/awslabs/aws-rails-provisioner"
  spec.license      = "Apache-2.0"

  spec.require_paths = ["lib"]
  spec.files         = Dir['lib/**/*.rb']
  spec.files        += Dir['templates/*']
  spec.bindir        = 'bin'
  spec.executables   << 'aws-rails-provisioner'

  spec.add_dependency('aws-sdk-rds', '~> 1')
  spec.add_dependency('aws-sdk-secretsmanager', '~> 1')
  spec.add_dependency('mustache', '~> 1')
end
