module Aws::RailsProvisioner
  class Build < Aws::RailsProvisioner::CodeBuild

    # An AWS CodeBuild Project that build, tag and
    # push image to AWS ECR Repo
    #
    # configuration for :build
    #
    # @param [Hash] options
    #
    # @option options [String] :project_name name for
    #   the CodeBuild project, default to 'RailsProvisionerImageBuild'
    #
    # @option options [String] :description description for this
    #   CodeBuild project, default to 'build, tag and push image to ECR'
    #
    # @option options [String] :buildspec buildspec.yml file path, default
    #   to `buildspec-ecr.yml` under root directory, using template
    #   under `buildspecs/`
    #
    # @option options [String] :build_image default to codebuild `ubuntu_14_04_docker_18_09_0`
    #   full list of supported images see:
    #   https://docs.aws.amazon.com/cdk/api/latest/docs/@aws-cdk_aws-codebuild.LinuxBuildImage.html
    #
    # @option options [Integer] :timeout number of minutes after which
    #   CodeBuild stops the build if it’s not complete
    #
    def initialize(options = {})
      unless options[:description]
        options[:description] = 'build, tag and push image to ECR'
      end
      unless options[:buildspec]
        options[:buildspec] = 'buildspec-ecr.yml'
      end
      unless options[:build_image]
        options[:build_image] = 'ubuntu_14_04_docker_18_09_0'
      end
      super(options)
    end

  end
end

