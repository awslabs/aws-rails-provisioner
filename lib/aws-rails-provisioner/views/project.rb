module Aws::RailsProvisioner
  module Views
    # @api private
    class Project < View

      def initialize(options = {})
        @services = options[:services]
        @stack_prefix = options[:stack_prefix]
        @path_prefix = options[:path_prefix]
      end

      # @return [String]
      attr_reader :stack_prefix

      # @return [String]
      attr_reader :path_prefix

      def stacks
        stacks = []
        @services.each do |svc|
          stacks << {
            name: svc.name,
            const_prefix: svc.const_prefix,
            path_prefix: svc.path_prefix,
            stack_prefix: svc.stack_prefix,
            enable_cicd: svc.enable_cicd
          }
        end
      end

    end
  end
end
