resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "lc" {
    name      = var.project_name
    on_start = base64encode(<<SCRIPT
#!/bin/bash
set -e
sudo -u ec2-user -i <<'EOF'
ENVIRONMENT=python3
conda activate "$ENVIRONMENT"
pip install --upgrade feast[aws]
pip install neptune-client[sklearn]
pip install sklearn-genetic-opt
pip install bentoml
pip install arize
conda env config vars set FEAST_S3_BUCKET="${aws_s3_bucket.bucket.bucket}"
conda env config vars set FEAST_IAM_ROLE_ARN="${aws_iam_role.for_redshift.arn}"
conda env config vars set FEAST_REDSHIFT_CLUSTER="${aws_redshift_cluster.feast_redshift_cluster.cluster_identifier}"
conda env config vars set FEAST_REGION="${var.aws_region}"
conda env config vars set YATAI_HOST="${local.yatai-ui}"
conda deactivate
# Install Jupyter extension
source /home/ec2-user/anaconda3/bin/activate JupyterSystemEnv
pip install neptune-notebooks
jupyter nbextension enable --py neptune-notebooks --sys-prefix
jupyter labextension install neptune-notebooks
source /home/ec2-user/anaconda3/bin/deactivate
EOF
SCRIPT
    )
}

resource "aws_iam_role" "for_notebooks" {
    name = "${var.project_name}-for-notebooks"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "sagemaker.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "for_notebooks_sage_full" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
    role       = aws_iam_role.for_notebooks.name
}

resource "aws_iam_role_policy_attachment" "for_notebooks_s3_full" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    role       = aws_iam_role.for_notebooks.name
}

resource "aws_iam_role_policy_attachment" "for_notebooks_dynamo_full" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
    role       = aws_iam_role.for_notebooks.name
}

resource "aws_iam_role_policy_attachment" "for_notebooks_redshift_full" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess"
    role       = aws_iam_role.for_notebooks.name
}


resource "aws_sagemaker_code_repository" "repo" {
    code_repository_name = var.project_name

    git_config {
        repository_url = "https://github.com/sotnich/mltest.git"
    }
}

resource "aws_sagemaker_notebook_instance" "ni" {
    name          = "my-notebook-instance"
    role_arn      = aws_iam_role.for_notebooks.arn
    instance_type = "ml.t2.medium"
    default_code_repository = aws_sagemaker_code_repository.repo.code_repository_name
    lifecycle_config_name = aws_sagemaker_notebook_instance_lifecycle_configuration.lc.name

    tags = {
        project = var.project_name
    }
}

output "notebooks_address" {
    description = "Notebooks-URL"
    value       = "${aws_sagemaker_notebook_instance.ni.url}/tree/mltest"
}

output "vars_to_run_locally" {
    value = <<VARS
Please set these variables in your local notebook (if you want to run local notebooks)
export FEAST_S3_BUCKET="s-mltest2"
export FEAST_IAM_ROLE_ARN="arn:aws:iam::834092605248:role/s-mltest2-for-redshift"
export FEAST_REDSHIFT_CLUSTER="s-mltest2"
export FEAST_REGION="eu-west-3"
export YATAI_HOST="a64acbaff7bb1491d88bc34071c375c1-663950777.eu-west-3.elb.amazonaws.com"
VARS
}
