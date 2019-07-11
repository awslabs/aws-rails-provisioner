module Aws::RailsProvisioner
  class CodeBuild

    def initialize(options = {})
      @project_name = options[:project_name]
      @description = options[:description]
      @buildspec = options[:buildspec]
      @image = options[:build_image].upcase
      @timeout = options[:timeout]
    end

    # @return [String]
    attr_reader :project_name

    # @return [String]
    attr_reader :description

    # @return [String]
    attr_reader :buildspec

    # @return [Integer]
    attr_reader :timeout

    # @return [String]
    attr_reader :image

  end
end
