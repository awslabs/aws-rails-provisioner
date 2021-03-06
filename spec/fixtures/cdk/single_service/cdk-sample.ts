#!/usr/bin/env node

import cdk = require('@aws-cdk/core');
import { CdkSampleInitStack } from '../lib/cdk-sample-init-stack';
import { RailsFooFargateStack } from '../lib/rails-foo-fargate-stack';
import { RailsFooPipelineStack } from '../lib/rails-foo-pipeline-stack';

const app = new cdk.App();
const initStack = new CdkSampleInitStack(app, 'CdkSampleInitStack');

// for service :rails_foo
const railsFooFargateStack = new RailsFooFargateStack(app, 'RailsFooFargateStack', {
    vpc: initStack.vpc,
    cluster: initStack.cluster
});

new RailsFooPipelineStack(app, 'RailsFooPipelineStack', {
    vpc: initStack.vpc,
    dbUrl: railsFooFargateStack.dbUrl,
    db: railsFooFargateStack.db,
    repoName: railsFooFargateStack.repoName,
    service: railsFooFargateStack.service
});

app.synth();
