module Aws::RailsProvisioner
  class Fargate

    # Configuration value under :fargate
    #
    # @param [Hash] options
    #
    # @option options [Integer] :desired_count number of
    #   desired copies of running tasks, default to 2
    #
    # @option options [Boolean] :public when `true` (default)
    #   Application Load Balancer will be internet-facing
    #
    # @option options [String] :domain_name domain name for the service,
    #   e.g. api.example.com
    #
    # @option options [String] :domain_zone route53 hosted zone for the domain,
    #   e.g. "example.com.".
    #
    # @option options [String] :service_name name for the Fargate service
    #
    # @option options [Integer] :memory default to 512 (MB)
    #
    # @option options [Integer] :cpu default to 256 (units)
    #
    # @option options [Hash] :envs environment variable pairs
    #   for the container used by this Fargate task
    #
    # @option options [String] :container_name defaults to `FargateTaskContainer`
    #
    # @option options [Integer] :container_port defaults to 80
    #
    # @option options [String] :certificate certificate arn. Certificate Manager
    #   certificate to associate with the load balancer. Setting this option
    #   will set the load balancer port to 443.
    #
    def initialize(options = {})
      # code gen only
      @has_db = !!options[:has_db]

      @service_name = options[:service_name]
      @desired_count = options[:desired_count] || 2
      @public = !!options[:public]
      @domain_name = options[:domain_name]
      @domain_zone = options[:domain_zone]
      @certificate = options[:certificate]

      @memory = options[:memory] || 512
      @cpu = options[:cpu] || 256
      @envs = Aws::RailsProvisioner::Utils.to_pairs(options[:envs]) if options[:envs]
      @container_port = options[:container_port] || 80
      @container_name = options[:container_name] || 'FargateTaskContainer'
    end

    # @api private
    # @return [Boolean]
    attr_reader :has_db

    # @return [Integer]
    attr_reader :desired_count

    # @return [String]
    attr_reader :service_name

    # @return [Boolean]
    attr_reader :public

    # @return [String]
    attr_reader :domain_name

    # @return [String]
    attr_reader :domain_zone

    # @return [String]
    attr_reader :certificate

    # @return [Array]
    attr_reader :envs

    # @return [Integer]
    attr_reader :memory

    # @return [Integer]
    attr_reader :cpu

    # @return [Integer]
    attr_reader :container_port

    # @return [String]
    attr_reader :container_name

  end
end
