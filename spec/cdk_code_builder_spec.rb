require_relative 'spec_helper'

module Aws::RailsProvisioner
  describe CDKCodeBuilder do
  
    it 'supports providing :cdk_dir' do
      builder = CDKCodeBuilder.new
      expect(builder.cdk_dir).to eq('cdk-sample')

      builder = CDKCodeBuilder.new(cdk_dir: 'foo')
      expect(builder.cdk_dir).to eq('foo')
    end

    it 'caculates required cdk :packages' do
      builder = CDKCodeBuilder.new(SpecHelper.single_service)
      builder.source_files.each {|_|}
      expect(builder.packages).to contain_exactly(
        "@aws-cdk/aws-ec2", "@aws-cdk/aws-ecs",
        "@aws-cdk/aws-ecr", "@aws-cdk/aws-ecr-assets",
        "@aws-cdk/aws-ecs-patterns", "@aws-cdk/aws-rds",
        "@aws-cdk/aws-secretsmanager", "@aws-cdk/aws-codebuild",
        "@aws-cdk/aws-codecommit", "@aws-cdk/aws-codepipeline",
        "@aws-cdk/aws-codepipeline-actions", "@aws-cdk/aws-iam"
      )
    end

    it 'supports single fargate service' do
      allow(File).to receive(:expand_path).with('aws-rails-provisioner.yml').and_return('/absolute/path/to/dir/aws-rails-provisioner.yml')
      builder = CDKCodeBuilder.new(SpecHelper.single_service)
      expected = SpecHelper.cdk_single_service

      expect(builder.services.to_a.size).to eq(1)
      generate_code_as_expected(builder, expected)
    end

    it 'supports rails without db' do
      allow(File).to receive(:expand_path).with('aws-rails-provisioner.yml').and_return('/absolute/path/to/dir/aws-rails-provisioner.yml')
      builder = CDKCodeBuilder.new(SpecHelper.no_db)
      expected = SpecHelper.cdk_no_db
      generate_code_as_expected(builder, expected)
    end

    it 'supports multiple fargate services' do
      allow(File).to receive(:expand_path).with('aws-rails-provisioner.yml').and_return('/absolute/path/to/dir/aws-rails-provisioner.yml')
      builder = CDKCodeBuilder.new(SpecHelper.multi_service)
      expected = SpecHelper.cdk_multi_service

      expect(builder.services.to_a.size).to eq(2)
      generate_code_as_expected(builder, expected)
    end

    private

    def generate_code_as_expected(builder, expected)
      expect(builder.project).to eq(expected[:app])
      expect(builder.init_stack).to eq(expected[:init])
      builder.services.each do |svc|
        expect(svc.fargate_stack).to eq(
          expected[:services][svc.path_prefix][:fargate])
        expect(svc.pipeline_stack).to eq(
          expected[:services][svc.path_prefix][:pipeline])
      end
    end

  end
end
