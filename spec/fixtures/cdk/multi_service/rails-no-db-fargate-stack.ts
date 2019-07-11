import cdk = require('@aws-cdk/core');
import ec2 = require('@aws-cdk/aws-ec2');
import ecs = require('@aws-cdk/aws-ecs');
import ecr = require('@aws-cdk/aws-ecr');
import ecs_patterns = require('@aws-cdk/aws-ecs-patterns');
import ecr_assets = require('@aws-cdk/aws-ecr-assets');
import rds = require('@aws-cdk/aws-rds');

interface RailsNoDbFargateStackProps {
    vpc: ec2.IVpc,
    cluster: ecs.ICluster,
}

export class RailsNoDbFargateStack extends cdk.Stack {
    public readonly service: ecs.FargateService;
    public readonly repoName: string;
    public readonly dbUrl: string;
    public readonly db: rds.DatabaseCluster;

    constructor(scope: cdk.App, id: string, props: RailsNoDbFargateStackProps) {
        super(scope, id);

        // import resources
        const cluster = props.cluster;

        const asset = new ecr_assets.DockerImageAsset(this, 'ImageAssetBuild', {
            directory: '/absolute/path/to/dir/path/to/no_db'
        });

        // compute repo name from asset image
        const parts = asset.imageUri.split("@")[0].split("/");
        const repoName = parts.slice(1, parts.length).join("/").split(":")[0];
        this.repoName = repoName;

        const ecrRepo = ecr.Repository.fromRepositoryName(this, 'EcrRepo', repoName);
        const image = ecs.ContainerImage.fromEcrRepository(ecrRepo);

        // Fargate service
        const lbFargate = new ecs_patterns.LoadBalancedFargateService(this, 'LBFargate', {
            serviceName: 'RailsNoDb',
            cluster: cluster,
            image: image,
            containerName: 'FargateTaskContainer',
            containerPort: 80,
            memoryLimitMiB: 512,
            cpu: 256,
            environment: {
                'PORT': '80',
            },
            enableLogging: true,
            desiredCount: 1,
            publicLoadBalancer: true,
            publicTasks: true
        });
        this.service = lbFargate.service;
    }
}
