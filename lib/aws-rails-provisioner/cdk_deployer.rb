require 'open3'

module Aws::RailsProvisioner
  class CDKDeployer

    def initialize(options = {})
      @cdk_dir = options[:cdk_dir]
      @services = options[:services]
      @stack_prefix = options[:stack_prefix]

      both = options[:fargate].nil? && options[:cicd].nil?
      @fargate_stack = both || !!options[:fargate]
      @pipeline_stack = both || !!options[:cicd]

      @init_stack_only = !!options[:init]

      @svc_name = options[:service_name]
      @profile = options[:profile]
    end

    def run
      Dir.chdir(@cdk_dir) do
        `cdk bootstrap`
        deploy_init_stack
        unless @init_stack_only
          if @svc_name
            deploy_svc(@services[@svc_name].stack_prefix)
          else
            @services.each do |svc|
              deploy_svc(svc.stack_prefix)
            end
          end
        end
      end
    end

    private

    def deploy_init_stack
      opts = @profile ? " --profile #{@profile}" : ''
      # disable prompts in deploy command
      opts += " --require-approval never"
      cmd = "cdk deploy #{@stack_prefix}InitStack#{opts}"
      Open3.popen3(cmd) do |_, stdout, stderr, _|
        puts stdout.read
        puts stderr.read
      end
    end

    def deploy_svc(stack_prefix)
      opts = @profile ? " --profile #{@profile}" : ''
      # disable prompts in deploy command
      opts += " --require-approval never"
      if @fargate_stack
        `cdk deploy #{stack_prefix}FargateStack#{opts}`
      end
      if @pipeline_stack
        `cdk deploy #{stack_prefix}PipelineStack#{opts}`
      end
    end

  end
end
