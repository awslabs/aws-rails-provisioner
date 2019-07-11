module Aws::RailsProvisioner 
  class Vpc

    SUBNETS_DEFAULTS = {
      application: {
        cidr_mask: 24,
        type: 'private'
      },
      ingress: {
        cidr_mask: 24,
        type: 'public'
      },
      database: {
        cidr_mask: 28,
        type: 'isolated'
      }
    }

    # Configuration value under :vpc
    # @param [Hash] options
    #
    # @option options [Integer] :max_azs maximum number
    #   of AZs to use in this region, default to 3
    #
    # @option options [String] :cidr CIDR range to use for
    #   the VPC, default to '10.0.0.0/21'
    #
    # @option options [Hash] :subnets subnets configuration
    #   to build for each AZ, default to following example:
    #     
    #     @example: at `aws-rails-provisioner.yml`
    #       subnets:
    #         application:
    #           cidr_mask: 24
    #           type: private
    #         ingress:
    #           cidr_mask: 24
    #           type: public
    #         database:
    #           cidr_mask: 28
    #           type: isolate
    #
    # @option options [Boolean] :enable_dns whether the DNS
    #   resolution is supported for the VPC, default to `true`
    #
    # @option options [Integer] :nat_gateways number of NAT Gateways
    #   to create, default to :maxAz value
    #
    # @option options [Hash] :nat_gateway_subnets choose the subnets
    #   that will have NAT Gateway attached, default to public:
    #     
    #     @example: at `aws-rails-provisioner.yml`
    #       nat_gateway_subnets:
    #         type: public
    #
    #   Note: Either subnet `:type` or `:name` can be provided
    #   @see {Aws::RailsProvisioner::SubnetSelection}
    #
    # @see AWS CDK VpcNetworkProps
    def initialize(options = {})
      @max_azs = options[:max_azs] || 3
      @cidr = options[:cidr] || '10.0.0.0/21'
      subnets_config = options[:subnets] || SUBNETS_DEFAULTS
      @subnets = subnets_config.map do |name, config|
        Subnet.new(
          cidr_mask: config[:cidr_mask],
          subnet_name: name,
          type: config[:type]
        )
      end
      @enable_dns = options[:enable_dns].nil? ? true : !!options[:enable_dns]
      @nat_gateways = options[:nat_gateways] || @max_azs
      @nat_gateway_subnets = Aws::RailsProvisioner::SubnetSelection.new(options[:nat_gateway_subnets]) if options[:nat_gateway_subnets]
    end

    # @return [Integer]
    attr_reader :max_azs

    # @return [Integer]
    attr_reader :nat_gateways

    # @return [Aws::RailsProvisioner::SubnetSelection | nil]
    attr_reader :nat_gateway_subnets

    # @return [String]
    attr_reader :cidr

    # @return [Boolean]
    attr_reader :enable_dns

    # @return [Array|nil]
    attr_reader :subnets

    class Subnet
      
      def initialize(options)
        @subnet_name = options.fetch(:subnet_name)
        @cidr_mask = options.fetch(:cidr_mask)
        @type = Aws::RailsProvisioner::Utils.subnet_type(options.fetch(:type))
      end

      attr_reader :subnet_name

      attr_reader :cidr_mask

      attr_reader :type

    end

  end
end
