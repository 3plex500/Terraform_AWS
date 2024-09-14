# Настройка провайдера AWS
provider "aws" {
  region = "us-east-1"
}

# Настройка Terraform backend для хранения состояния
terraform {
  backend "s3" {
    bucket         = "my-unique-terraform-bucket-12345"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "DynamoDB"
    encrypt        = true
  }
}

# Модуль для создания VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.12.1"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway  = true
}

# Ресурс для создания ECR репозитория
resource "aws_ecr_repository" "my_app" {
  name = "my-app-repo"
}

# Модуль для создания EKS кластера
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.0"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.30"
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnets

  eks_managed_node_groups = {
    eks_nodes = {
      desired_capacity = 2
      max_capacity     = 2
      min_capacity     = 1
      instance_type    = "t2.micro"
    }
  }
}

# Output для VPC ID
output "vpc_id" {
  value = module.vpc.vpc_id
}

# Output для EKS cluster endpoint
output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

# Output для URL ECR репозитория
output "ecr_repository_url" {
  value = aws_ecr_repository.my_app.repository_url
}
