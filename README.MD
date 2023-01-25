This is a repo of a MLOps POC with Jupyter, Feast, Neptune.io, BentoML and Arize.

This peaces of software provide the full cycle of ML development: 
 - data preparation
 - experiments and model developing 
 - deployment
 - monitoring

### Deploy your own infrastructure

You could deploy this infrastructure in your own AWS account with terraform script in `.\infra` folder.

```bash
cd ./infra
terraform apply
```

In order to run it you need:

1. install terraform
2. install AWS cli
3. configure AWS cli and create profile with the name `gdc`

### Run notebooks locally 

In order to run some notebooks locally you should set these environment variables in every notebook session.

If you created your own AWS environment please change variables accordingly.

To run some notebooks locally you also need AWS CLI installed with `gdc` profile configured. 

```bash
export FEAST_S3_BUCKET="s-mltest2"
export FEAST_IAM_ROLE_ARN="arn:aws:iam::834092605248:role/s-mltest2-for-redshift"
export FEAST_REDSHIFT_CLUSTER="s-mltest2"
export FEAST_REGION="eu-west-3"
export YATAI_HOST="a64acbaff7bb1491d88bc34071c375c1-663950777.eu-west-3.elb.amazonaws.com"
export AWS_DEFAULT_PROFILE="gdc"
```


