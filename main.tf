resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app"
  description = "Application security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP application traffic"
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app"
  }
}

resource "aws_security_group" "database" {
  name        = "${var.project_name}-database"
  description = "PostgreSQL security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from application"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-database"
  }
}

resource "aws_security_group" "load_generator" {
  name        = "${var.project_name}-load-generator"
  description = "k6 load generator security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-load-generator"
  }
}

module "app" {
  source = "./modules/ec2"

  name               = "${var.project_name}-app"
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  subnet_id          = aws_subnet.public.id
  security_group_ids = [aws_security_group.app.id]
  key_name           = var.key_name
  role               = "app"
  user_data          = file("${path.module}/scripts/app.sh")
}

module "database" {
  source = "./modules/ec2"

  name               = "${var.project_name}-database"
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  subnet_id          = aws_subnet.public.id
  security_group_ids = [aws_security_group.database.id]
  key_name           = var.key_name
  role               = "database"
  user_data          = file("${path.module}/scripts/db.sh")
}

module "load_generator" {
  source = "./modules/ec2"

  name               = "${var.project_name}-load-generator"
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  subnet_id          = aws_subnet.public.id
  security_group_ids = [aws_security_group.load_generator.id]
  key_name           = var.key_name
  role               = "load-generator"
  user_data          = file("${path.module}/scripts/k6.sh")
}
