require 'rspec'

$:.unshift(File.expand_path('../../lib', __FILE__))
require 'aws-rails-provisioner'

module SpecHelper
  class << self

    YML_DIR = File.join([
      File.dirname(__FILE__),
      'fixtures',
      'yml'
    ])

    CDK_DIR = File.join([
      File.dirname(__FILE__),
      'fixtures',
      'cdk'
    ])

    def single_service
      config = yml_fixtures('single_service')
      config[:services][:rails_foo][:enable_cicd] = true
      config
    end

    def cdk_single_service
      cdk_fixtures('single_service')
    end

    def multi_service
      config = yml_fixtures('multi_service')
      config[:services][:rails_foo][:enable_cicd] = true
      config[:services][:rails_no_db][:enable_cicd] = true
      config
    end

    def cdk_multi_service
      cdk_fixtures('multi_service')
    end

    def no_db 
      config = yml_fixtures('no_db')
      config[:services][:rails_no_db][:enable_cicd] = true
      config
    end

    def cdk_no_db
      cdk_fixtures('no_db')
    end

    private

    def yml_fixtures(suite)
      Aws::RailsProvisioner::Utils.parse("#{YML_DIR}/#{suite}.yml")
    end

    def cdk_fixtures(suite)
      Dir.glob("#{CDK_DIR}/#{suite}/*").inject({}) do |h, path|
        file = path.split("#{suite}/")[-1]
        if file == "cdk-sample.ts"
          h[:app] = File.read(path)
        elsif file == "cdk-sample-init-stack.ts"
          h[:init] = File.read(path)
        else
          h[:services] ||= {}
          if file.include?("fargate-stack.ts")
            svc = file.split("-fargate-stack.ts")[0]
            h[:services][svc] ||= {}
            h[:services][svc][:fargate] = File.read(path)
          else
            svc = file.split("-pipeline-stack.ts")[0]
            h[:services][svc] ||= {}
            h[:services][svc][:pipeline] = File.read(path)
          end
        end

        h
      end
    end

  end
end
