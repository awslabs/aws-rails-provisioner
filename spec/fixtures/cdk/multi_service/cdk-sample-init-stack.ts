import cdk = require('@aws-cdk/core');
import ec2 = require('@aws-cdk/aws-ec2');
import ecs = require('@aws-cdk/aws-ecs');

export class CdkSampleInitStack extends cdk.Stack {
    public readonly vpc: ec2.IVpc;
    public readonly cluster: ecs.ICluster;

    constructor(scope: cdk.App, id: string, props?: cdk.StackProps) {
        super(scope, id, props);

        // Setting up VPC with subnets
        const vpc = new ec2.Vpc(this, 'Vpc', {
            maxAzs: 2,
            cidr: '10.0.0.0/21',
            enableDnsSupport: true,
            natGateways: 2,
            subnetConfiguration: [
                {
                  cidrMask: 24,
                  name: 'application',
                  subnetType: ec2.SubnetType.PRIVATE
                },
                {
                  cidrMask: 24,
                  name: 'ingress',
                  subnetType: ec2.SubnetType.PUBLIC
                },
                {
                  cidrMask: 28,
                  name: 'database',
                  subnetType: ec2.SubnetType.ISOLATED
                },
            ]
        });
        this.vpc = vpc;

        this.cluster = new ecs.Cluster(this, 'FargateCluster', {
            vpc: vpc  
        });

    }
}
