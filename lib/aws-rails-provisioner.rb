# services
require 'aws-sdk-rds'

# code gen helpers
require_relative 'aws-rails-provisioner/cdk_builder'
require_relative 'aws-rails-provisioner/cdk_deployer'
require_relative 'aws-rails-provisioner/cdk_code_builder'

# utils
require_relative 'aws-rails-provisioner/services'
require_relative 'aws-rails-provisioner/service'
require_relative 'aws-rails-provisioner/utils'
require_relative 'aws-rails-provisioner/errors'

# init stack
require_relative 'aws-rails-provisioner/vpc'
require_relative 'aws-rails-provisioner/subnet_selection'

# CICD stack
require_relative 'aws-rails-provisioner/code_build'
require_relative 'aws-rails-provisioner/build'
require_relative 'aws-rails-provisioner/migration'

# fargate stack
require_relative 'aws-rails-provisioner/db_cluster'
require_relative 'aws-rails-provisioner/fargate'
require_relative 'aws-rails-provisioner/scaling'

# views
require_relative 'aws-rails-provisioner/view'
require_relative 'aws-rails-provisioner/views/init_stack'
require_relative 'aws-rails-provisioner/views/fargate_stack'
require_relative 'aws-rails-provisioner/views/pipeline_stack'
require_relative 'aws-rails-provisioner/views/project'

# version
require_relative 'aws-rails-provisioner/version'

module Aws
  module RailsProvisioner
  end
end
