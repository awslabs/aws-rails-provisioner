require 'set'

module Aws::RailsProvisioner
  class CDKCodeBuilder

    # Generates CDK projects with separate stacks:
    #
    #  * InitStack - VPC and Fargate Cluster
    #  * FargetStack - Fargate Service, AutoScaling, ALB
    #  * PipelineStack - CICD CodePipline (when enabled) that:
    #       * Source: CodeCommit Repository when host rails applications
    #       * Build : CodeBuild Project that takes care of image build, tag(commit id) and push to ECR
    #       * Migration: CodeBuild Project that run migration inside DB subnet (optional)
    #       * Deploy: CodeDeploy that deploys tagged(commit id) image from ECR to Fargate service
    #
    # @param [Hash] options
    #
    # @option options [String] :cdk_dir Directory path for
    #   generated CDK code, defaults to "cdk-sample"
    #
    # @option options [Hash] :vpc VPC configurations 
    #   @see {Aws::RailsProvisioner::Vpc}
    #
    # @option options [Hash] :services
    #
    # @option options [Hash] :db_cluster DB cluster configurations
    #   @see {Aws::RailsProvisioner::DBCluster}
    #
    # @option options [required, String] :source_path path to the directory containing
    #   Rails Application source
    #
    # @option options [Hash] :fargate Fargate service configurations
    #   @example: at `aws-rails-provisioner.yml`
    #     fargate:
    #       desired_count: 5
    #       task:
    #         environment:
    #           RAILS_LOG_TO_STDOUT: true
    #   @see {Aws::RailsProvisioner::Fargate}
    #
    # @option options [Hash] :scaling Scaling definitions for the Fargate service
    #   @example: at `aws-rails-provisioner.yml`
    #     scaling:
    #       max_capacity: 7
    #       on_cpu:
    #         target_util_percent: 40
    #       on_request:
    #         requests_per_target: 20000
    #   @see {Aws::RailsProvisioner::Scaling}
    #
    # @option options [Hash] :loadbalancer Application Loadbalancer that front
    #   the Fargate service
    #   @example: at `aws-rails-provisioner.yml`
    #     loadbalancer:
    #       internet_facing: true
    #   @see {Aws::RailsProvisioner::LoadBalancer}
    #
    # @option options [Hash] :cicd configurations for CICD that covers:
    #   source, build, database migration with code pipline
    #   @see {Aws::RailsProvisioner::Pipeline}
    #
    def initialize(options = {})
      @cdk_dir = options[:cdk_dir] || "cdk-sample"
      @stack_prefix = _stack_prefix

      # init, vpc & fargate cluster
      @vpc = options[:vpc] || {}

      # fargate services defs
      # including related db, alb, scaling, cicd etc.
      @services = Aws::RailsProvisioner::ServiceEnumerator.new(options[:services] || {})

      # npm cdk service packages need to be installed
      @packages = Set.new
    end

    # @return [Enumerable]
    attr_reader :services

    # @return [Set]
    attr_reader :packages

    # @return [String]
    attr_reader :cdk_dir

    # @api private
    # @return [String]
    attr_reader :stack_prefix

    def source_files
      Enumerator.new do |y|
        y.yield("#{@cdk_dir}/lib/#{@cdk_dir}-init-stack.ts", init_stack)
        @services.each do |svc|
          y.yield("#{@cdk_dir}/lib/#{svc.path_prefix}-fargate-stack.ts",
            svc.fargate_stack)
          y.yield("#{@cdk_dir}/lib/#{svc.path_prefix}-pipeline-stack.ts",
            svc.pipeline_stack) if svc.enable_cicd
          @packages.merge(svc.packages)
        end

        y.yield("#{@cdk_dir}/bin/#{@cdk_dir}.ts", project)
      end
    end

    def default_stack
      # CDK init cmd default empty stack
      "#{@cdk_dir}/lib/#{@cdk_dir}-stack.ts"
    end

    def default_test
      # CDK init cmd default test file
      "#{@cdk_dir}/test/#{@cdk_dir}.test.ts"
    end

    # @api private
    def project
      Aws::RailsProvisioner::Views::Project.new(
        stack_prefix: @stack_prefix,
        path_prefix: @cdk_dir,
        services: @services
      ).render
    end

    # @api private
    def init_stack
      init = Aws::RailsProvisioner::Views::InitStack.new(
        vpc: @vpc,
        stack_prefix: @stack_prefix
      )
      @packages.merge(init.packages)
      init.render
    end

    private

    def _stack_prefix
      dir = @cdk_dir.dup
      dir.split('-').map do |part|
        part[0] = part[0].upcase
        part
      end.join
    end

  end
end
