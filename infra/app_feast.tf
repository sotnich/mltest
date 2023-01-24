resource "aws_iam_role" "feast_for_ec2" {
    name               = "${var.project_name}_feast_ec2"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            }
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "feast_for_ec2_s3full_attachment" {
    role       = aws_iam_role.feast_for_ec2.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "feast_for_ec2_redshiftfull_attachment" {
    role       = aws_iam_role.feast_for_ec2.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess"
}

resource "aws_iam_role_policy_attachment" "feast_for_ec2_dynamo_attachment" {
    role       = aws_iam_role.feast_for_ec2.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_instance_profile" "feast_for_ec2_profile" {
    name = "feast_for_ec2_profile"
    role = aws_iam_role.feast_for_ec2.name
}

resource "aws_instance" "feast-ui-instance" {
    ami                    = "ami-0cc814d99c59f3789"
    instance_type          = "t2.micro"
    vpc_security_group_ids = [aws_security_group.default.id]
    iam_instance_profile   = aws_iam_instance_profile.feast_for_ec2_profile.name
    depends_on             = [aws_s3_bucket.bucket]
    tags                   = {
        Name = "feast-ui"
    }
    user_data = <<EOF
#!/bin/bash
set -e
export FEAST_S3_BUCKET="${aws_s3_bucket.bucket.bucket}"
export FEAST_IAM_ROLE_ARN="${aws_iam_role.for_redshift.arn}"
export FEAST_REDSHIFT_CLUSTER="${aws_redshift_cluster.feast_redshift_cluster.cluster_identifier}"
export FEAST_REGION="${var.aws_region}"
echo FEAST_S3_BUCKET="$FEAST_S3_BUCKET" >> /root/feast-environment
echo FEAST_IAM_ROLE_ARN="$FEAST_IAM_ROLE_ARN" >> /root/feast-environment
echo FEAST_REDSHIFT_CLUSTER="$FEAST_REDSHIFT_CLUSTER" >> /root/feast-environment
echo FEAST_REGION="$FEAST_REGION" >> /root/feast-environment
aws s3 cp s3://${aws_s3_bucket.bucket.bucket}/config/feast/feature_store.yaml /root/feature_store.yaml
aws s3 cp s3://${aws_s3_bucket.bucket.bucket}/config/feast/features.py /root/features.py
aws s3 cp s3://${aws_s3_bucket.bucket.bucket}/config/feast/feastui.service /etc/systemd/system/feastui.service
pip3 install --upgrade pip
pip3 install --default-timeout=100 feast[aws]
cd /root/
/usr/local/bin/feast apply
systemctl start feastui
systemctl enable feastui
EOF
}

resource "null_resource" "clear_dynamo_caches" {
    triggers = {
        aws_region = var.aws_region
    }

    provisioner "local-exec" {
        when    = destroy
        command = <<EOF
aws dynamodb delete-table --region ${self.triggers.aws_region} --table-name mltest.zipcode_features
aws dynamodb delete-table --region ${self.triggers.aws_region} --table-name mltest.credit_history
EOF
    }
}

output "feast_ui_address" {
    description = "Feast-UI"
    value       = "http://${aws_instance.feast-ui-instance.public_dns}:8080"
}