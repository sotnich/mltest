#resource "aws_ecs_task_definition" "feast_ui_task" {
#    family                   = "feast-ui"
#    container_definitions    = <<DEFINITION
#[
#    {
#        "name": "feast-ui-task",
#        "image": "${aws_ecr_repository.repo.repository_url}:feastui",
#        "essential": true,
#        "environment": [
#            {
#                "FEAST_S3_BUCKET": "${aws_s3_bucket.bucket.bucket}",
#                "FEAST_IAM_ROLE_ARN": "${aws_iam_role.for_redshift.arn}"
#            }
#        ],
#        "portMappings": [
#            {
#                "containerPort": 8000,
#                "hostPort": 8080
#            }
#        ],
#        "memory": 512,
#        "cpu": 512
#    }
#]
#DEFINITION
#
#    requires_compatibilities = ["EC2"]
#    memory                   = 512
#    cpu                      = 512
#    execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
#    task_role_arn            = aws_iam_role.ecs_tasks.arn
#}
#
#resource "aws_ecs_service" "feast_ui_service" {
#    name            = "feast-ui"
#    cluster         = aws_ecs_cluster.cluster.id
#    task_definition = aws_ecs_task_definition.feast_ui_task.arn # Referencing the task our service will spin up
#    launch_type     = "EC2"
#    desired_count   = 1
#}
