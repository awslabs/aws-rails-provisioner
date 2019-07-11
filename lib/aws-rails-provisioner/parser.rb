require 'yaml'

module Aws::RailsProvisioner
  module Parser

    def parse(file_path)
      config = YAML.load(File.read(file_path))
      symbolize_keys(config)
    end

    private

    def symbolize_keys(hash)
      hash.inject({}) do |h, (k,v)|
        v = symbolize_keys(v) if v.respond_to?(:keys)
        h[k.to_sym] = v
        h
      end
    end

  end
end
