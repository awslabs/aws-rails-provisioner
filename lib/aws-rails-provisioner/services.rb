module Aws::RailsProvisioner
  # @api private
  class ServiceEnumerator

    include Enumerable

    def initialize(options = {})
      @configs = options || {}
    end

    # @param [String] name
    def [](name)
      if services.key?(name)
        services[name]
      else
        msg = "unknown service #{name} under :services"
        raise Aws::RailsProvisioner::Errors::ValidationError, msg
      end
    end
    alias service []

    def each(&block)
      services.values.each(&block)
    end

    private

    def services
      @service ||= begin
        @configs.inject({}) do |hash, (name, config)|
          hash[name] = build_service(name, config)
          hash
        end
      end
    end

    def build_service(name, config)
      Aws::RailsProvisioner::Service.new(name, config)
    end

  end

  Services = ServiceEnumerator.new
end
