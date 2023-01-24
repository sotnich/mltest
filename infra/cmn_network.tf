data "aws_vpc" "default_vpc" {
    default = true
}

data "aws_subnets" "default_subnets" {
    filter {
        name   = "vpc-id"
        values = [data.aws_vpc.default_vpc.id]
    }
}

resource "aws_security_group" "default" {
    name   = "${var.project_name}-default"
    vpc_id = data.aws_vpc.default_vpc.id

    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        self      = true
    }


    ingress {
        from_port   = 5432
        to_port     = 5432
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]

    }

}