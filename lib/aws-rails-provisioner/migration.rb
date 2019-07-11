module Aws::RailsProvisioner
  class Migration < Aws::RailsProvisioner::CodeBuild

    # An AWS CodeBuild Project that runs DB migration
    # for the Ruby on Rails App inside private subnet of
    # the VPC
    #
    # configuration for :migration
    #
    # @param [Hash] options
    #
    # @option options [String] :project_name name for
    #   the CodeBuild project, default to 'SERVICE_NAMEDBMigration'
    #
    # @option options [String] :description description for this
    #   CodeBuild project, default to 'running DB Migration for
    #    the rails app inside private subnet'
    #
    # @option options [String] :buildspec buildspec.yml file path, default
    #   to `buildspec-db.yml` under root directory, using template under
    #   `buildspecs/`
    #
    # @option options [String] :build_image default to codebuild `standard_1_0`
    #   full list of supported images see:
    #   https://docs.aws.amazon.com/cdk/api/latest/docs/@aws-cdk_aws-codebuild.LinuxBuildImage.html
    #
    # @option options [Integer] :timeout number of minutes after which
    #   CodeBuild stops the build if it’s not complete
    #
    def initialize(options = {})
      unless options[:description]
        options[:description] = 'running DB Migration for'\
          ' the rails app inside private subnet'
      end
      unless options[:buildspec]
        options[:buildspec] = 'buildspec-db.yml'
      end
      unless options[:build_image]
        options[:build_image] = 'standard_1_0'
      end
      # TODO envs support?
      super(options)
    end
  end
end
