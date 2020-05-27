module Aws::RailsProvisioner
  module Views

    class FargateStack < View

      # Fargate Stack Generation
      #
      # @param [Hash] options
      #
      # @option options [String] :source_path relative path from `aws-rails-provisioner.yml`
      #   to the directory containing Rails Application source
      #
      # @option options [Hash] :db_cluster
      #   @see {Aws::RailsProvisioner::DBCluster}
      #
      # @option options [Hash] :fargate configurations for
      #   fargate service.
      #   @see {Aws::RailsProvisioner::Fargate}
      #
      # @option options [Hash] :scaling configurations for
      #   scaling setting for Fargate service
      #   @see {Aws::RailsProvisioner::Scaling}
      #
      def initialize(options = {})
        # code gen only
        @service_name = options[:service_name]
        @path_prefix = options[:path_prefix]
        @stack_prefix = options[:stack_prefix]
        @profile = options[:profile]

        dir = File.dirname(File.expand_path(options[:file_path]))
        @source_path = File.join(dir, options[:source_path])
        @rds_config = options[:db_cluster] || {}
        @fargate_config = options[:fargate] || {}
        @scaling_config = options[:scaling] || {}
      end

      # @return [String]
      attr_reader :stack_prefix

      # @return [String]
      attr_reader :source_path

      def services
        base = [
          { abbr: 'ec2', value: 'ec2' },
          { abbr: 'ecs', value: 'ecs' },
          { abbr: 'ecs_patterns', value: 'ecs-patterns' },
          { abbr: 'ecr_assets', value: 'ecr-assets' },
          { abbr: 'rds', value: 'rds' }
        ]
        if @fargate_config && @fargate_config[:certificate]
          base << { abbr: 'certificatemanager', value: 'certificatemanager' }
        end
        if @scaling_config &&
          (@scaling_config[:on_metric] || @scaling_config[:on_custom_metric])
          base << { abbr: 'cloudwatch', value: 'cloudwatch' }
        end
        if @rds_config && !@rds_config.empty?
          base << { abbr: 'secretsmanager', value: 'secretsmanager' }
          if @rds_config[:kms_key_arn]
            base << { abbr: 'kms', value: 'kms'}
          end
        end
        base
      end

      def packages
        keys = services.map {|svc| svc[:value] }
        Aws::RailsProvisioner::Utils.to_pkgs(keys)
      end

      def db_cluster
        if @rds_config && !@rds_config.empty?
          unless @rds_config[:username]
            @rds_config[:username] = "#{stack_prefix}DBAdminUser"
          end
          @rds_config[:profile] = @profile if @profile
          Aws::RailsProvisioner::DBCluster.new(@rds_config)
        end
      end

      def fargate
        if @rds_config && !@rds_config.empty?
          @fargate_config[:has_db] = true
        end
        @fargate_config[:service_name] = @stack_prefix
        Aws::RailsProvisioner::Fargate.new(@fargate_config)
      end

      def scaling
        if @scaling_config && !@scaling_config.empty?
          Aws::RailsProvisioner::Scaling.new(@scaling_config)
        end
      end

    end
  end
end
