# aws-rails-provisioner

[![Build Status](https://travis-ci.org/awslabs/aws-rails-provisioner.svg?branch=master)](https://travis-ci.org/awslabs/aws-rails-provisioner)

A tool for defining and deploying containerized Ruby on Rails applications on AWS.

`aws-rails-provisioner` is a command line tool using your configurations defined in `aws-rails-provisioner.yml` file to generate 
[AWS CDK](https://github.com/awslabs/aws-cdk) stacks on your behalf, provisioning required AWS resources
for running your containerized Ruby on Rails applications on AWS (current supported platform: AWS Fargate) within
few commands.

<!--BEGIN STABILITY BANNER-->
---
![Stability: Experimental](https://img.shields.io/badge/stability-Experimental-important.svg?style=for-the-badge)
> This tool is under developer preview (beta) stage, with active development, releases might lack features and might have future breaking changes.
---
<!--END STABILITY BANNER-->

## Links of Interest

* [Change Log](./CHANGELOG.md)
* [Issues](https://github.com/awslabs/aws-rails-provisioner/issues)
* [License](http://aws.amazon.com/apache2.0/)

## Getting Started

### Prerequisites

Before using the `aws-rails-provisioner` gem, you need to have 

* a [Ruby on Rails](https://rubyonrails.org/) application with Dockerfile 
* install or update the [AWS CDK Toolkit] from npm (requires [Node.js ≥ 8.11.x](https://nodejs.org/en/download)):

  ```bash
  $ npm i -g aws-cdk
  ```
* docker daemon vailable for building images

### Install aws-rails-provisioner

`aws-rails-provisioner` gem is available from RubyGems, currently with [preview versions](https://rubygems.org/gems/aws-rails-provisioner).

```
gem install 'aws-rails-provisioner' -v 0.0.0.rc1
```

### Define aws-rails-provisioner.yml

`aws-rails-provisioner.yml` is a configuration file defining how `aws-rails-provisioner` boostrap required AWS resources
for your Ruby on Rails applications.

```
version: '0'

vpc:
  max_az: 2
  enable_dns: true
services:
  my_rails_foo:
    source_path: ./path/to/my_rails_foo # relative path from `aws-rails-provisioner.yml`
    fargate:
      desired_count: 3
      memory: 512
      cpu: 256
      envs:
        PORT: 80
        RAILS_LOG_TO_STDOUT: true
      public: true
    db_cluster:
      engine: aurora-postgresql
      db_name: app_development
    scaling:
      max_capacity: 5
      on_cpu:
        target_util_percent: 80
        scale_in_cool_down: 300
      on_requests:
        requests_per_target: 1000
  my_another_rails:
    ...
```
More `aws-rails-provisioner` examples see `./examples` (see `tiny.yml` for a minimal `aws-rails-provisioner.yml` configuration example),
full configuration options documentation see release doc source (Online documentation coming soon ❤️ ).

### Build and Deploy

Once `aws-rails-provisioner.yml` is defined, run build command as following will boostrap AWS CDK stacks in code
defining all required AWS resources and connections.

```
aws-rails-provisioner build
```

By default, it defines a VPC with public and private subnets, Amazon RDS Database Cluster, an ECS cluster with
AWS Fargate services containing application images, when run build with `--with-cicd` option as following
an CICD stack will be defined automatically (including data migration step)

```
aws-rails-provisioner build --with-cicd
```

After build complete, run the deploy command to deploy all defined AWS resources

```
aws-rails-provisioner deploy
```

Instead of deploy everything all at once, you can deploy stack by stack, application by application

```
# only deploys the stack creates VPC and ECS cluster
aws-rails-provisioner deploy --init

# deploys fargate service and database cluster when defined
aws-rails-provisioner deploy --fargate

# deploy CICD stack
aws-rails-provisioner deploy --cicd

# deploy only :rails_foo application
aws-rails-provisioner deploy --fargate --service rails_foo
```

After deployment completes, your applications are running on AWS Fargate fronted with AWS Application
LoadBalancer.

> Note: for applications with databases, rails migration is needed, CICD stack contains a migration phase
by default, running DB migration commands insides private subnets, talking to DB Cluster.

### CICD

When have `--with-cicd` enabled at build, a CICD stack is available. Once deployment completes, an AWS
CodePipeline is available with source, build, migration and deploy phases. You need to commit
your local Rails application to the source repository in the pipeline with `buildspec` to activate the pipeline.
Sample `buildspec`s are availble under `./buildspecs` handling application image build and rails migration.

Full `aws-rails-provisioner` command line options see:

```
aws-rails-provisioner -h
```

## Contributing

We welcome community contributions and pull requests. See [CONTRIBUTING](./CONTRIBUTING.md) for details.

## Getting Help

Please use these community resources for getting help. We use the GitHub issues
for tracking bugs and feature requests.

* Ask a question on [Stack Overflow](https://stackoverflow.com/questions/tagged/aws-rails-provisioner)
    and tag it with `aws-rails-provisioner`
* If it turns out that you may have found a bug, or want to submit a feature request, please open an [issue](https://github.com/awslabs/aws-cdk/issues/new)

## License

The `aws-rails-provisioner` is distributed under [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).
See [LICENSE](./LICENSE.txt) for more information.
