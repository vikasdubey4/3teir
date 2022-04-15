provider "aws" {
  region = var.region
}

#VPC and subnets configuration

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc-cidr
  enable_dns_hostnames = true
}

resource "aws_subnet" "public-subnet-a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public-subnet-cidr-a
  availability_zone = "${var.region}a"
}

resource "aws_subnet" "public-subnet-b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public-subnet-cidr-b
  availability_zone = "${var.region}b"
}

resource "aws_subnet" "public-subnet-c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public-subnet-cidr-c
  availability_zone = "${var.region}c"
}

resource "aws_subnet" "private-subnet-a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private-subnet-cidr-a
  availability_zone = "${var.region}a"
}

resource "aws_subnet" "private-subnet-b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private-subnet-cidr-b
  availability_zone = "${var.region}b"
}

resource "aws_subnet" "private-subnet-c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private-subnet-cidr-c
  availability_zone = "${var.region}c"
}

resource "aws_route_table" "public-subnet-route-table" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "private-subnet-route-table" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_eip" "elasticip-nat" {
    vpc = true
    depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "natgateway" {
    allocation_id = aws_eip.elasticip-nat.id
    subnet_id = aws_subnet.public-subnet-a.id
}

resource "aws_route" "public-subnet-route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  route_table_id         = aws_route_table.public-subnet-route-table.id
}

resource "aws_route_table_association" "public-subnet-a-route-table-association" {
  subnet_id      = aws_subnet.public-subnet-a.id
  route_table_id = aws_route_table.public-subnet-route-table.id
}

resource "aws_route_table_association" "public-subnet-b-route-table-association" {
  subnet_id      = aws_subnet.public-subnet-b.id
  route_table_id = aws_route_table.public-subnet-route-table.id
}

resource "aws_route_table_association" "public-subnet-c-route-table-association" {
  subnet_id      = aws_subnet.public-subnet-c.id
  route_table_id = aws_route_table.public-subnet-route-table.id
}

resource "aws_route" "private-subnet-route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.natgateway.id
  route_table_id         = aws_route_table.private-subnet-route-table.id
}

resource "aws_route_table_association" "private-subnet-a-route-table-association" {
  subnet_id      = aws_subnet.private-subnet-a.id
  route_table_id = aws_route_table.private-subnet-route-table.id
}

resource "aws_route_table_association" "private-subnet-b-route-table-association" {
  subnet_id      = aws_subnet.private-subnet-b.id
  route_table_id = aws_route_table.private-subnet-route-table.id
}

resource "aws_route_table_association" "private-subnet-c-route-table-association" {
  subnet_id      = aws_subnet.private-subnet-c.id
  route_table_id = aws_route_table.private-subnet-route-table.id
}


# Application instance configuration for application teir (teir 2)

resource "aws_instance" "instance" {
  ami                         = "ami-085ed5922c6881dd6"
  instance_type               = "t2.small"
  vpc_security_group_ids      = [ aws_security_group.vikas_instance.id ]
  subnet_id                   = aws_subnet.private-subnet-a.id
  associate_public_ip_address = true

resource "aws_lb" "vikas" {
  name               = "alb-vikas-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.vikas_lb.id]
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id, aws_subnet.public-subnet-c.id]
}

resource "aws_lb_listener" "vikas" {
  load_balancer_arn = aws_lb.vikas.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vikas.arn
  }
}

resource "aws_lb_target_group" "vikas" {
   name     = "alb-vikas"
   port     = 80
   protocol = "HTTP"
   vpc_id   = aws_vpc.vpc.id
 }


#security group for instance

resource "aws_security_group" "vikas_instance" {
  name = "alb-vikas-instance"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.vikas_lb.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.vikas_lb.id]
  }

  vpc_id = aws_vpc.vpc.id
}

#security group for load balancer

resource "aws_security_group" "vikas_lb" {
  name = "alb-vikas-lb"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.vpc.id
}


#configuration for creating S3 bucket and cloud front for web teir (teir 1)

resource "aws_s3_bucket" "vikas_bucket" {
    bucket = "vikas"
    acl = "public-read"
    cors_rule {
        allowed_headers = ["*"]
        allowed_methods = ["PUT","POST"]
        allowed_origins = ["*"]
        expose_headers = ["ETag"]
        max_age_seconds = 3000
    }
	}
	
resource "aws_cloudfront_distribution" "vikas_distribution" {
    origin {
        domain_name = "${aws_s3_bucket.abc.website_endpoint}"
        origin_id = "S3-${aws_s3_bucket.abc.bucket}"
        custom_origin_config {
            http_port = 80
            https_port = 443
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
        }
    }


# configuration for teir three database teir (teir 3)

resource "aws_db_instance" "vikas" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "vikas"
  password             = "var.password"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}
	

