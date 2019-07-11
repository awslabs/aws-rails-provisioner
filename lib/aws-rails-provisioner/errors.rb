module Aws::RailsProvisioner
  module Errors

    class ValidationError < RuntimeError; end

    class InvalidCommandOption < RuntimeError

      def initialize(type, option)
        msg = "invalid option: #{option}, #{option} is valid for `#{type}` command."
        super(msg)
      end

    end

    class InvalidYAMLFile < RuntimeError

      def initialize
        msg = "Invalid `aws-rails-provisioner.yml` file provided."
        super(msg)
      end

    end
  end
end
