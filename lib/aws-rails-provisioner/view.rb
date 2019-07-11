require 'mustache'

module Aws::RailsProvisioner 
  # @api private
  class View < Mustache

    TEMPLATE_DIR = File.expand_path('../../../templates', __FILE__)

    def self.inherited(subclass)
      parts = subclass.name.split('::')
      parts.shift #=> remove AWS
      parts.shift #=> remove RailsProvisioner 
      parts.shift #=> remove Views
      path = parts.map { |part| underscore(part) }.join('/')
      subclass.template_path = TEMPLATE_DIR
      subclass.template_file = "#{TEMPLATE_DIR}/#{path}.mustache"
      subclass.raise_on_context_miss = true
    end

    private

    def underscore(str)
      string = str.dup
      string.scan(/[a-z0-9]+|\d+|[A-Z0-9]+[a-z]*/).join('_'.freeze)
      string.downcase!
    end

  end
end
