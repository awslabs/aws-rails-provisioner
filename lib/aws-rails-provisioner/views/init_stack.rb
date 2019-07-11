module Aws::RailsProvisioner 
  module Views
    class InitStack < View

      # For InitStack Generation
      #
      # @param [Hash] options
      #
      # @option options [Hash] :vpc
      #   @see {Aws::RailsProvisioner::Vpc}
      #
      def initialize(options = {})
        @vpc_config = options[:vpc]
        @stack_prefix = options[:stack_prefix]
      end

      # @api private
      # @return [String]
      attr_reader :stack_prefix

      def services
        ['ec2', 'ecs']
      end

      def packages
        Aws::RailsProvisioner::Utils.to_pkgs(services)
      end

      def vpc
        Aws::RailsProvisioner::Vpc.new(@vpc_config)
      end

    end
  end
end
