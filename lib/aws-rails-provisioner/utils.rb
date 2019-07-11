require 'yaml'

module Aws::RailsProvisioner
  # @api private
  module Utils

    def self.ip_address_type(str)
      types = %w(ipv4, dualstack)
      if types.include?(str.downcase)
        str.upcase
      else
        msg = "Unsupported ip address type, please choose from #{types}"
        raise Aws::RailsProvisioner::Errors::ValidationError, msg
      end
    end

    def self.subnet_type(str)
      types = %w(isolated private public)
      if types.include?(str.downcase)
        str.upcase
      else
        msg = "Unsupported subnet type, please choose from #{types}" 
        raise Aws::RailsProvisioner::Errors::ValidationError, msg
      end
    end

    def self.removal_policy(str)
      types = %w(retain destroy)
      if types.include?(str.downcase)
        str.upcase
      else
        msg = "Unsupported removal policy, please choose from #{types}"
        raise Aws::RailsProvisioner::Errors::ValidationError, msg
      end
    end

    def self.protocol(str)
      types = %w(https http tcp tls)
      if types.include?(str.downcase)
        str.upcase
      else
        msg = "Unsupported protocol type, please choose from #{types}"
        raise Aws::RailsProvisioner::Errors::ValidationError, msg
      end
    end

    def self.adjustment_type(str)
      types = %w(change_in_capacity percent_change_in_capacity exact_capacity)
      if types.include?(str.downcase)
        str.upcase
      else
        msg = "Unsupported adjustment type, please choose from #{types}"
        raise Aws::RailsProvisioner::Errors::ValidationError, msg
      end
    end

    def self.parse(file_path)
      config = YAML.load(File.read(file_path))
      symbolize_keys(config)
    rescue
      raise Aws::RailsProvisioner::Errors::InvalidYAMLFile.new
    end

    def self.to_pairs(hash)
      hash.inject([]) do |arr, (key, value)|
        arr << "'#{key}': '#{value}',"
        arr
      end
    end

    def self.to_pkgs(services)
      services.inject([]) do |pkgs, svc|
        pkgs << "@aws-cdk/aws-#{svc}"
        pkgs
      end
    end

    private

    def self.symbolize_keys(hash)
      hash.inject({}) do |h, (k,v)|
        v = symbolize_keys(v) if v.respond_to?(:keys)
        h[k.to_sym] = v
        h
      end
    end

  end
end
