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

interface RailsNoDbPipelineStackProps {
    vpc: ec2.IVpc,
    dbUrl: string,
    repoName: string,
    service: ecs.FargateService,
    db: rds.DatabaseCluster
}

export class RailsNoDbPipelineStack extends cdk.Stack {
    constructor(scope: cdk.App, id: string, props: RailsNoDbPipelineStackProps) {
        super(scope, id);

        const pipeline = new codepipeline.Pipeline(this, 'FargatePipeline', {
            pipelineName: 'RailsNoDbPipeline',
        });

        const repo = new codecommit.Repository(this, 'CodeCommitRepo', {
            repositoryName: 'rails',
            description: 'created by aws-rails-provisioner with AWS CDK for RailsNoDb'
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
            projectName: 'RailsNoDbImageBuild',
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

        pipeline.addStage({
            stageName: 'Deploy',
            placement: {
                justAfter: buildStage
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
