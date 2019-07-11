module Aws::RailsProvisioner 
  module Views
    class PipelineStack < View

      # Pipeline (CICD) Generation under :cicd
      #
      # @param [Hash] options
      #
      # @option options [String] :pipeline_name Name for the 
      #   AWS CodePipeline generated
      #
      # @option options [String] :source_repo CodeCommit Repo
      #   name for holding your rails app source, default to
      #   folder name where your rails app lives
      #  
      # @option options [String] :source_description Description for
      #   the CodeCommit Repo, default to 'created by aws-rails-provisioner'
      #
      # @option options [Hash] :build configurations for codebuild project
      #   for building images
      #   @see {Aws::RailsProvisioner::Build}
      #
      # @option options [Hash] :migration configuration for db migration
      #   codebuild, available if :db_cluster is configured
      #   @see {Aws::RailsProvisioner::Migration}
      #
      def initialize(options = {})
        @stack_prefix = options[:stack_prefix]

        @pipeline_name = options[:pipeline_name] || "#{@stack_prefix}Pipeline"
        @source_repo = options[:source_repo] || _extract_repo_name(options[:source_path])
        @source_description = options[:source_description] || "created by aws-rails-provisioner with AWS CDK for #{@stack_prefix}"

        @build_config = options[:build] || {}
        unless @build_config[:project_name]
          @build_config[:project_name] = "#{@stack_prefix}ImageBuild"
        end

        @skip_migration = options[:skip_migration] || false
        unless @skip_migration
          @migration_config = options[:migration] || {}
          unless @migration_config[:project_name]
            @migration_config[:project_name] = "#{@stack_prefix}DBMigration"
          end
        end
      end

      def services
        [
          { abbr: 'iam', value: 'iam'},
          { abbr: 'ec2', value: 'ec2'},
          { abbr: 'ecr', value: 'ecr' },
          { abbr: 'ecs', value: 'ecs' },
          { abbr: 'rds', value: 'rds' },
          { abbr: 'codebuild', value: 'codebuild'},
          { abbr: 'codecommit', value: 'codecommit'},
          { abbr: 'codepipeline', value: 'codepipeline' },
          { abbr: 'pipelineactions', value: 'codepipeline-actions'}
        ] 
      end

      def packages
        keys = services.map {|svc| svc[:value] }
        Aws::RailsProvisioner::Utils.to_pkgs(keys)
      end

      # @return [String]
      attr_reader :stack_prefix

      # @return [String]
      attr_reader :pipeline_name

      # @return [String]
      attr_reader :source_repo

      # @return [String]
      attr_reader :source_description

      # @return [Aws::RailsProvisioner::Build]
      attr_reader :build

      # @return [Aws::RailsProvisioner::Migration]
      attr_reader :migration

      # @return [Boolean]
      attr_reader :skip_migration

      def build
        Aws::RailsProvisioner::Build.new(@build_config)
      end

      def migration
        if @migration_config
          Aws::RailsProvisioner::Migration.new(@migration_config)
        end
      end

      private

      def _extract_repo_name(path)
        path.split('/')[-1] || 'AwsRailsProvisionerRailsAppSource'
      end

    end
  end
end

