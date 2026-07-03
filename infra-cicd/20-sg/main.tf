############################### SECURITYGROUPS  ####################################
module "mysql_sg" {
  source       = "git::https://github.com/K-Basavaraj/terraform-aws-secuirty-group.git?ref=main"
  project_name = var.project_name
  environment  = var.environment
  sg_name      = "mysql"
  vpc_id       = local.vpc_id
  common_tags  = var.common_tags
  sg_tags      = var.mysql_sg_tags
}

module "bastion_sg" {
  source       = "git::https://github.com/K-Basavaraj/terraform-aws-secuirty-group.git?ref=main"
  project_name = var.project_name
  environment  = var.environment
  sg_name      = "bastion"
  vpc_id       = local.vpc_id
  common_tags  = var.common_tags
  sg_tags      = var.bastion_sg_tags
}

module "ingress_alb_sg" {
  source       = "git::https://github.com/K-Basavaraj/terraform-aws-secuirty-group.git?ref=main"
  project_name = var.project_name
  environment  = var.environment
  sg_name      = "ingress-alb"
  vpc_id       = local.vpc_id
  common_tags  = var.common_tags
  # sg_tags      = var.ing_alb_sg_tags
}

module "eks_control_plane_sg" {
  source       = "git::https://github.com/K-Basavaraj/terraform-aws-secuirty-group.git?ref=main"
  project_name = var.project_name
  environment  = var.environment
  sg_name      = "eks-control-plane"
  vpc_id       = local.vpc_id
  common_tags  = var.common_tags
  # sg_tags      = var.eks_cp_sg_tags
}

module "node_sg" {
  source       = "git::https://github.com/K-Basavaraj/terraform-aws-secuirty-group.git?ref=main"
  project_name = var.project_name
  environment  = var.environment
  sg_name      = "node"
  vpc_id       = local.vpc_id
  common_tags  = var.common_tags
  #sg_tags      = var.node_sg_tags
}

###############################SECUIRTYGROUPRULES###############################################
#ingressalb to allowing portnumber 443 from internet/public 
resource "aws_security_group_rule" "ingress_alb_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.ingress_alb_sg.id
}

#nodes security groups accepting the connection from ingressalb
resource "aws_security_group_rule" "node_ingress_alb" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = module.ingress_alb_sg.id
  security_group_id        = module.node_sg.id
}

#nodes are accpting the connection from controlplane 
resource "aws_security_group_rule" "node_eks_control_plane" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.eks_control_plane_sg.id
  security_group_id        = module.node_sg.id
}

#controllplane allowing connection from nodes 
resource "aws_security_group_rule" "eks_control_plane_node" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.node_sg.id
  security_group_id        = module.eks_control_plane_sg.id
}

#controll plane allowing connection from bastion
resource "aws_security_group_rule" "eks_control_plane_bastion" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.bastion_sg.id
  security_group_id        = module.eks_control_plane_sg.id
}

#nodesg accepting connection vpc (where pods can reside in different nodes for communication between them set the cidr all host communcation)
resource "aws_security_group_rule" "node_vpc" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = module.node_sg.id
}

#node accepting connection from bastion
resource "aws_security_group_rule" "node_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = module.bastion_sg.id
  security_group_id        = module.node_sg.id
}

#mysql(RDS) accepting connection from bastion on port 3306
resource "aws_security_group_rule" "mysql_bastion" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.bastion_sg.id #accept connection from this source
  security_group_id        = module.mysql_sg.id   #where your creating this rule
}

#mysql(RDS) accepting connection from nodes on port 3306
resource "aws_security_group_rule" "mysql_node" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.node_sg.id
  security_group_id        = module.mysql_sg.id
}

#bastion accepting connection from internet
resource "aws_security_group_rule" "bastion_public" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]        #Allow from ANY IP (not secure for production!) here we need to give officeips
  security_group_id = module.bastion_sg.id #where your creating this rule
}
