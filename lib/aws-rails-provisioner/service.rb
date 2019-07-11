require 'set'

module Aws::RailsProvisioner
  # @api private
  class Service
    
    def initialize(name, options = {})
      @name = name.to_s 
      @file_path = options[:file_path] || 'aws-rails-provisioner.yml'
      @stack_prefix = _camel_case(@name)
      @path_prefix = _path_prefix(@name)
      @const_prefix = _const_prefix(@stack_prefix)
      @enable_cicd = !!options[:enable_cicd]
      @profile = options[:profile]
      @packages = Set.new

      # fargate stack
      @source_path = options.fetch(:source_path)
      @fargate = options[:fargate] || {}

      @db_cluster = options[:db_cluster]
      @scaling = options[:scaling]

      # pipeline stack
      @cicd = options[:cicd] || {}
    end

    # @return [String]
    attr_reader :name

    # @return [String]
    attr_reader :stack_prefix

    # @return [String]
    attr_reader :path_prefix

    # @return [String]
    attr_reader :const_prefix

    # @return [Boolean]
    attr_reader :enable_cicd

    # @return [Set]
    attr_reader :packages

    def fargate_stack
      stack = Aws::RailsProvisioner::Views::FargateStack.new(
        file_path: @file_path,
        service_name: @name,
        path_prefix: @path_prefix,
        stack_prefix: @stack_prefix,
        profile: @profile,
        source_path: @source_path,
        db_cluster: @db_cluster,
        fargate: @fargate,
        scaling: @scaling,
      )
      @packages.merge(stack.packages)
      stack.render
    end

    def pipeline_stack
      if @db_cluster.nil? || @db_cluster.empty?
        @cicd[:skip_migration] = true
      end
      @cicd[:source_path] = @source_path
      @cicd[:stack_prefix] = @stack_prefix
      stack = Aws::RailsProvisioner::Views::PipelineStack.new(@cicd)
      @packages.merge(stack.packages)
      stack.render
    end

    private

    def _camel_case(str)
      str.split('_').collect(&:capitalize).join
    end

    def _path_prefix(str)
      str.downcase.gsub('_', '-')
    end

    def _const_prefix(str)
      dup = str.dup
      dup[0] = dup[0].downcase
      dup
    end

  end
end
