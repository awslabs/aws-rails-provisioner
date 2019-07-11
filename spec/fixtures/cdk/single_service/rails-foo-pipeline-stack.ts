import cdk = require('@aws-cdk/core');
import iam = require('@aws-cdk/aws-iam');
import ec2 = require('@aws-cdk/aws-ec2');
import ecr = require('@aws-cdk/aws-ecr');
import ecs = require('@aws-cdk/aws-ecs');
import rds = require('@aws-cdk/aws-rds');
import codebuild = require('@aws-cdk/aws-codebuild');
import codecommit = require('@aws-cdk/aws-codecommit');
import codepipeline = require('@aws-cdk/aws-codepipeline');
import pipelineactions = require('@aws-cdk/aws-codepipeline-actions');

interface RailsFooPipelineStackProps {
    vpc: ec2.IVpc,
    dbUrl: string,
    repoName: string,
    service: ecs.FargateService,
    db: rds.DatabaseCluster
}

export class RailsFooPipelineStack extends cdk.Stack {
    constructor(scope: cdk.App, id: string, props: RailsFooPipelineStackProps) {
        super(scope, id);

        const pipeline = new codepipeline.Pipeline(this, 'FargatePipeline', {
            pipelineName: 'RailsFoo',
        });

        const repo = new codecommit.Repository(this, 'CodeCommitRepo', {
            repositoryName: 'rails_foo',
            description: 'created by aws-rails-provisioner with AWS CDK for RailsFoo'
        });

        const sourceOutput = new codepipeline.Artifact();
        const sourceStage = pipeline.addStage({
            stageName: 'Source',
            actions: [
                new pipelineactions.CodeCommitSourceAction({
                    actionName: 'SourceAction',
                    repository: repo,
                    output: sourceOutput
                })
            ]
        });

        const ecrRepo = ecr.Repository.fromRepositoryName(this, 'ImageRepo', props.repoName);

        const role = new iam.Role(this, 'ImageBuildRole', {
            assumedBy: new iam.ServicePrincipal('codebuild.amazonaws.com')
        });
        const policy = new iam.PolicyStatement();
        policy.addAllResources();
        policy.addActions(
            "ecr:BatchCheckLayerAvailability",
            "ecr:CompleteLayerUpload",
            "ecr:GetAuthorizationToken",
            "ecr:InitiateLayerUpload",
            "ecr:PutImage",
            "ecr:UploadLayerPart"
        );
        role.addToPolicy(policy);

        const build = new codebuild.PipelineProject(this, 'ImageBuildToECR', {
            projectName: 'RailsFooImageBuild',
            description: 'build, tag and push image to ECR',
            environmentVariables: {
                'REPO_NAME': {
                  value: ecrRepo.repositoryName,
                  type: codebuild.BuildEnvironmentVariableType.PLAINTEXT
                },
                'REPO_PREFIX': {
                  value: ecrRepo.repositoryUri,
                  type: codebuild.BuildEnvironmentVariableType.PLAINTEXT
                },
            },
            environment: {
                buildImage: codebuild.LinuxBuildImage.UBUNTU_14_04_DOCKER_18_09_0,
                privileged: true
            },
            buildSpec: codebuild.BuildSpec.fromSourceFilename('buildspec-ecr.yml'),
            role: role
        });

        const buildOutput = new codepipeline.Artifact();
        const buildStage = pipeline.addStage({
            stageName: 'Build',
            placement: {
                justAfter: sourceStage
            },
            actions: [
                new pipelineactions.CodeBuildAction({
                    actionName: 'ImageBuildAction',
                    input: sourceOutput,
                    outputs: [ buildOutput ],
                    project: build
                })
            ]
        });

        const migration = new codebuild.PipelineProject(this, 'DBMigration', {
            projectName: 'RailsFooDBMigration',
            description: 'running DB Migration for the rails app inside private subnet',
            environmentVariables: {
                'DATABASE_URL': {
                  value: props.dbUrl,
                  type: codebuild.BuildEnvironmentVariableType.PLAINTEXT
                }
            },
            environment:{
                buildImage: codebuild.LinuxBuildImage.STANDARD_1_0
            },
            buildSpec: codebuild.BuildSpec.fromSourceFilename('buildspec-db.yml'),
            vpc: props.vpc,
            subnetSelection: {
                subnetType: ec2.SubnetType.PRIVATE
            }
        });
        migration.connections.allowToDefaultPort(props.db, 'DB Migration CodeBuild');

        const migrationStage = pipeline.addStage({
            stageName: 'DBMigration',
            placement: {
                justAfter: buildStage
            },
            actions: [
                new pipelineactions.CodeBuildAction({
                    actionName: 'DBMigrationAction',
                    project: migration,
                    input: sourceOutput
                })
            ]
        });

        pipeline.addStage({
            stageName: 'Deploy',
            placement: {
                justAfter: migrationStage
            },
            actions: [
                new pipelineactions.EcsDeployAction({
                    actionName: 'FargateDeployAction',
                    service: props.service,
                    input: buildOutput
                })
            ]
        });
    }
}
