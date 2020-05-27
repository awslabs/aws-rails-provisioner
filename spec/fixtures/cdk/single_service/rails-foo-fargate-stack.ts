import cdk = require('@aws-cdk/core');
import ec2 = require('@aws-cdk/aws-ec2');
import ecs = require('@aws-cdk/aws-ecs');
import ecs_patterns = require('@aws-cdk/aws-ecs-patterns');
import ecr_assets = require('@aws-cdk/aws-ecr-assets');
import rds = require('@aws-cdk/aws-rds');
import secretsmanager = require('@aws-cdk/aws-secretsmanager');

interface RailsFooFargateStackProps {
    vpc: ec2.IVpc,
    cluster: ecs.ICluster,
}

export class RailsFooFargateStack extends cdk.Stack {
    public readonly service: ecs.FargateService;
    public readonly repoName: string;
    public readonly dbUrl: string;
    public readonly db: rds.DatabaseCluster;

    constructor(scope: cdk.App, id: string, props: RailsFooFargateStackProps) {
        super(scope, id);

        // import resources
        const cluster = props.cluster;
        const vpc = props.vpc;

        // Create secret from SecretsManager
        const username = 'RailsFooDBAdminUser';
        const secret = new secretsmanager.Secret(this, 'Secret', {
            generateSecretString: {
                excludePunctuation: true
            }
        });
        const password = secret.secretValue;

        // Import DB cluster ParameterGroup
        const clusterParameterGroup = rds.ClusterParameterGroup.fromParameterGroupName(
            this, 'DBClusterPG', 'aws-rails-provisioner-default-aurora-postgresql');
        // Create DB Cluster
        const db = new rds.DatabaseCluster(this, 'DBCluster', {
            engine: rds.DatabaseClusterEngine.AURORA_POSTGRESQL,
            masterUser: {
                username: username,
                password: password
            },
            instanceProps: {
                instanceType: new ec2.InstanceType('r4.large'),
                vpc: vpc,
                vpcSubnets: {
                  subnetType: ec2.SubnetType.ISOLATED
                }
            },
            defaultDatabaseName: 'app_development',
            removalPolicy: cdk.RemovalPolicy.RETAIN,
            instances: 2,
            parameterGroup: clusterParameterGroup
        });
        const dbUrl = "postgres://" + username + ":" + password + "@" + db.clusterEndpoint.socketAddress + "/app_development";
        this.dbUrl = dbUrl;

        const asset = new ecr_assets.DockerImageAsset(this, 'ImageAssetBuild', {
            directory: '/absolute/path/to/dir/path/to/rails_foo'
        });

        // compute repo name from asset image
        const parts = asset.imageUri.split("@")[0].split("/");
        const repoName = parts.slice(1, parts.length).join("/").split(":")[0];
        this.repoName = repoName;

        const image = ecs.ContainerImage.fromDockerImageAsset(asset);

        // Fargate service
        const lbFargate = new ecs_patterns.ApplicationLoadBalancedFargateService(this, 'LBFargate', {
            serviceName: 'RailsFoo',
            cluster: cluster,
            taskImageOptions: {
              image: image,
              containerName: 'FargateTaskContainer',
              containerPort: 80,
              environment: {
                  'DATABASE_URL': dbUrl,
              },
              enableLogging: true,
            },
            memoryLimitMiB: 512,
            cpu: 256,
            desiredCount: 5,
            publicLoadBalancer: true,
            assignPublicIp: true
        });
        db.connections.allowDefaultPortFrom(lbFargate.service, 'From Fargate');
        this.db = db;
        this.service = lbFargate.service;
    }
}
