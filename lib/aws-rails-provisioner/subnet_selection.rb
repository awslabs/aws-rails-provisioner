module Aws::RailsProvisioner 
  class SubnetSelection

    def initialize(options = {})
      @name = options[:name]
      @type = Aws::RailsProvisioner::Util.subnet_type(options[:type]) if options[:type]
      if @name && @type
        msg = "At most one of :type and :name can be supplied."
        raise Aws::RailsProvisioner::Errors::ValidationError, msg
      end
    end

    # @return [String]
    attr_reader :name

    # @return [String]
    attr_reader :type

  end
end
