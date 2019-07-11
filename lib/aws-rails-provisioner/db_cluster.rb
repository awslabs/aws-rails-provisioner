require 'aws-sdk-rds'

module Aws::RailsProvisioner 
  class DBCluster

    # Configuration value under :db_cluster
    #
    # @param [Hash] options
    #
    # @option options [String] :username DB username, default
    #   to `SERVICE_NAMEDBAdminUser`
    #
    # @option options [required, String] :engine provide the engine for
    #   the database cluster: `aurora`, `aurora-mysql` or `aurora-postgresql`
    #
    # @option options [String] :engine_version version of the database to start,
    #   when not provided, default for the engine is used.
    #
    # @option options [String] :instance_type type of instance to start
    #   for the replicas, if not provided, a default :instance_type will
    #   be populated responding to the type of engine provided.
    #
    # @option options [String] :instance_subnet where to place the instances
    #   within the VPC, default to `isolated` subnet (recommend)
    #
    # @option options [Hash] :backup backup config for DB databases
    #
    #   @example: at `aws-rails-provisioner.yml`
    #     backup:
    #       retention_days: 7
    #       preferred_window: '01:00-02:00'
    #   @see {Aws::RailsProvisioner::DBCluster::BackUp}
    #
    # @option options [String] :cluster_identifier An optional identifier for
    #   the cluster, If not supplied, a name is automatically generated
    #
    # @option options [required, String] :db_name name for the DB inside the cluster
    #
    # @option options [String] :removal_policy policy to apply when
    #   the cluster and its instances are removed from the stack or replaced during an update.
    #   `retain`, `destroy` available, default to `retain`
    #
    # @option options [String] :instance_identifier every replica is named
    #   by appending the replica number to this string, default to 'Instance'
    #
    # @option options [Integer] :instances how many replicas/instances
    #   to create, defaults to 2
    #
    # @option options [Integer] :port if not provided, default value is
    #   based on :engine
    #
    # @option options [String] :kms_key_arn the he KMS key arn for storage encryption
    #
    # @option options [String] :preferred_maintenance_window daily time
    #   range in 24-hours UTC format in which backups preferably execute
    #
    # @option oprions [Hash] :parameter_group default value is based on engine
    #   following example shows default for aurora postgres
    #
    #   @example: at `aws-rails-provisioner.yml`
    #     parameter_group:
    #       family: 'aurora-postgresql9.6'
    #       description: 'created by AWS RailsProvisioner'
    #       parameters: 
    #         key: value
    #   @see {Aws::RailsProvisioner::DBCluster::ParameterGroup}
    #
    # @see AWS CDK DatabaseClusterProps
    def initialize(options = {})
      @username = options[:username] || 'DBAdminUser'

      @engine = _engine_type(options[:engine])
      @engine_version = options[:engine_version]
      @postgres = @engine == 'AURORA_POSTGRESQL'
      unless @postgres
        # MySql require username between 1 to 16
        @username = options[:username][0..15]
      end

      @instance_type = options[:instance_type] || _default_instance_type
      @instance_subnet = Aws::RailsProvisioner::Utils.subnet_type(
        options[:instance_subnet] || 'isolated')

      @backup = BackUp.new(options[:backup]) if options[:backup]
      @db_name = options.fetch(:db_name)
      @cluster_identifier = options[:cluster_identifier]
      @removal_policy = Aws::RailsProvisioner::Utils.removal_policy(
        options[:removal_policy] || 'retain')

      @instance_identifier = options[:instance_identifier]
      @instances = options[:instances] || 2

      @kms_key = options[:kms_key_arn]

      @port = options[:port]
      @preferred_maintenance_window = options[:preferred_maintenance_window]

      pg_opts = options[:parameter_group] || {}
      pg_opts[:profile] = options[:profile] if options[:profile]
      pg_opts[:stub_client] = options[:stub_client] # test only
      @parameter_group = ParameterGroup.new(@engine, pg_opts)
      @db_port = @port || _default_db_port
    end

    # @return [Boolean]
    attr_reader :postgres

    # @return [String]
    attr_reader :username

    # @return [String]
    attr_reader :engine

    # @return [String]
    attr_reader :engine_version

    # @return [String]
    attr_reader :instance_type

    # @return [String]
    attr_reader :instance_subnet

    # @return [String]
    attr_reader :instance_identifier

    # @return [Integer]
    attr_reader :instances

    # @return [String]
    attr_reader :db_name

    # @return [String]
    attr_reader :cluster_identifier

    # @return [String]
    attr_reader :removal_policy

    # @return [String]
    attr_reader :kms_key

    # @return [Integer]
    attr_reader :port

    # @return [String]
    attr_reader :preferred_maintenance_window

    # @return [ParameterGroup]
    attr_reader :parameter_group

    # @return [BackUp]
    attr_reader :backup

    # @return [Integer]
    attr_reader :db_port

    class BackUp

      # @param [Hash] options
      #
      # @option options [required, Integer] :retention_days
      #   days to retain the backup
      #
      # @option options [String] :preferred_window A daily
      #   time range in 24-hours UTC format in which backups
      #   preferably execute
      #
      def initialize(options = {})
        @retention_days = options[:retention_days]
        @preferred_window = options[:preferred_window]
      end

      # @return [Integer]
      attr_reader :retention_days

      # @return [String]
      attr_reader :preferred_window

    end

    class ParameterGroup
      
      # @param [Hash] options
      #
      # @option options [String] :family
      #
      # @option options [String] :description
      #
      # @option options [Hash] :parameters
      #
      def initialize(engine, options = {})
        # client
        @profile = options[:profile]

        @engine = engine
        @family = options[:family] || _default_family
        @description = options[:description] || 'created by AWS RailsProvisioner'
        @cfn = !!options[:parameters]
        unless @cfn
          suffix = @engine.downcase.gsub(/_/, '-')
          @name = "aws-rails-provisioner-default-#{suffix}"
          _create_default_pg(options[:stub_client])
        else
          @parameters = Aws::RailsProvisioner::Utils.to_pairs(options[:parameters])
        end
      end

      # @return [Boolean]
      attr_reader :cfn

      # @return [String]
      attr_reader :name

      # @return [String]
      attr_reader :family

      # @return [String]
      attr_reader :description

      # @return [Array]
      attr_reader :parameters

      private

      def _default_family
        case @engine
        when 'AURORA_POSTGRESQL' then 'aurora-postgresql9.6'
        when 'AURORA_MYSQL' then 'aurora-mysql5.7'
        when 'AURORA' then 'aurora5.6'
        else
          msg = 'Failed to locate a default family type for :engine'\
            ' provided, please provide :family for :parameter_group'
          raise Aws::RailsProvisioner::Errors::ValidationError, msg
        end
      end

      # CDK creation requires parameters input
      def _create_default_pg(stub_client)
        if stub_client
          rds = Aws::RDS::Client.new(stub_responses: true)
        else
          rds = @profile ? Aws::RDS::Client.new(profile: @profile) :
            Aws::RDS::Client.new
        end

        begin
          rds.create_db_cluster_parameter_group(
            db_parameter_group_family: @family,
            description: @description,
            db_cluster_parameter_group_name: @name
          )
        rescue Aws::RDS::Errors::DBParameterGroupAlreadyExists
          # Cluster Parameter Group already exists
          # do nothing
        end
      end

    end

    private

    def _engine_type(engine)
      type = engine.dup
      case type.downcase
      when 'aurora-postgresql' then 'AURORA_POSTGRESQL'
      when 'aurora-mysql' then 'AURORA_MYSQL'
      when 'aurora' then 'AURORA'
      else
        msg = "DB engine: #{engine.inspect} not supported"
        raise Aws::RailsProvisioner::Errors::ValidationError, msg
      end
    end

    def _default_instance_type
      case @engine
      when 'AURORA_POSTGRESQL' then 'r4.large'
      when 'AURORA_MYSQL' then 'r5.large'
      when 'AURORA' then 'r5.large'
      else
        msg = 'Failed to locate a default instance type for :engine'\
          ' provided, please provide :instance_type' 
        raise Aws::RailsProvisioner::Errors::ValidationError, msg
      end
    end

    def _default_db_port
      case @engine
      when 'AURORA_POSTGRESQL' then 3306
      when 'AURORA_MYSQL' then 3306
      when 'AURORA' then 3306
      else
        msg = 'Failed to locate a default db port for :engine'\
          ' provided, please provide :port' 
        raise Aws::RailsProvisioner::Errors::ValidationError, msg
      end

    end

  end
end
