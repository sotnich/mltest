resource "aws_iam_role" "for_redshift" {
    name               = "${var.project_name}-for-redshift"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "redshift.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_read" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
    role       = aws_iam_role.for_redshift.name
}

resource "aws_iam_role_policy_attachment" "glue_full" {
    policy_arn = "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess"
    role       = aws_iam_role.for_redshift.name
}

resource "aws_iam_role_policy_attachment" "dynamo_full" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
    role       = aws_iam_role.for_redshift.name
}

resource "aws_iam_role_policy_attachment" "redshift_full" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess"
    role       = aws_iam_role.for_redshift.name
}

resource "aws_iam_role_policy_attachment" "redshift_data_full" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftDataFullAccess"
    role       = aws_iam_role.for_redshift.name
}

resource "aws_iam_role_policy_attachment" "s3-policy-attachment" {
    role       = aws_iam_role.for_redshift.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

#resource "aws_iam_role_policy_attachment" "for_redshift_service_r_attach" {
#    role       = aws_iam_role.for_redshift.name
#    policy_arn = "arn:aws:iam::aws:policy/aws-service-role/AmazonRedshiftServiceLinkedRolePolicy"
#}

#data "aws_iam_role" "AWSServiceRoleForRedshift" {
#    name = "AWSServiceRoleForRedshift"
#}

resource "aws_redshift_cluster" "feast_redshift_cluster" {
    cluster_identifier = var.project_name
    iam_roles          = [
        #        data.aws_iam_role.AWSServiceRoleForRedshift.arn,
        aws_iam_role.for_redshift.arn
    ]
    database_name   = var.redshift_database_name
    master_username = var.redshift_admin_user
    master_password = var.redshift_admin_password
    node_type       = "dc2.large"
    cluster_type    = "single-node"
    number_of_nodes = 1

    skip_final_snapshot = true

    provisioner "local-exec" {
        command = <<EOF
            aws --profile gdc redshift-data execute-statement \
                --region ${var.aws_region} \
                --cluster-identifier ${var.project_name} \
                --db-user ${var.redshift_admin_user} \
                --database ${var.redshift_database_name} \
                --sql "create external schema spectrum \
                    from data catalog database '${aws_glue_catalog_database.feature_database.name}' \
                    iam_role '${aws_iam_role.for_redshift.arn}' create external database if not exists;"
        EOF
    }
}

