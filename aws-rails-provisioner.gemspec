version = File.read(File.expand_path('../VERSION', __FILE__)).strip

Gem::Specification.new do |spec|
  spec.name         = "aws-rails-provisioner"
  spec.version      = version 
  spec.authors      = ["Amazon Web Services"]
  spec.email        = ["mamuller@amazon.com", "alexwoo@amazon.com"]

  spec.summary      = "Deploy a Ruby on Rails application on AWS."
  spec.description  = "Define and deploy containerized Ruby on Rails Applications on AWS."
  spec.homepage     = "http://github.com/awslabs/aws-rails-provisioner"
  spec.license      = "Apache-2.0"

  spec.require_paths = ["lib"]
  spec.files         = Dir['lib/**/*.rb', 'templates/*']
  spec.bindir        = 'bin'
  spec.executables   << 'aws-rails-provisioner'

  spec.add_dependency('aws-sdk-rds', '~> 1')
  spec.add_dependency('aws-sdk-secretsmanager', '~> 1')
  spec.add_dependency('mustache', '~> 1')
end
