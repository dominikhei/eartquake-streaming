
module "dynamodb" {
    source = "./modules/dynamodb"

    global_table_replication_region = var.global_table_replication_region
}

module "ec2" {
    source = "./modules/ec2"    

    streaming_subnet_id                   = module.networking.streaming_subnet_id
    streaming_security_group_id           = module.networking.streaming_security_group
    kafka_streaming_instance_profile_name = module.i_am.kafka_streaming_instance_profile_name
}

module "ecr" {
    source = "./modules/ecr"

    aws_region = var.aws_region
    account_id = var.account_id
}

module "i_am" {
    source = "./modules/i_am"

    aws_region = var.aws_region
    account_id = var.account_id
}

module "load_balancing" {
    source = "./modules/load_balancing"   

    aws_region = var.aws_region
    account_id = var.account_id   

    project_security_group_id    = module.networking.project_security_group_id
    seismic_subnet_id            = module.networking.seismic_subnet_id
    ecs_execution_role_arn       = module.i_am.ecs_execution_role_arn
    ecs_role_arn                 = module.i_am.ecs_role_arn
    alb_security_group_id        = module.networking.alb_security_group_id
    public_subnet_1_id           = module.networking.public_subnet_1_id
    public_subnet_2_id           = module.networking.public_subnet_2_id
    vpc_id                       = module.networking.vpc_id
}

module "networking" {
    source = "./modules/networking"   

    aws_region = var.aws_region
    my_ip      = var.my_ip
    account_id = var.account_id
    
    alb_arn = module.load_balancing.alb_arn
}

module "tls" {
    source = "./modules/tls"       
}

module "finops" {
    source = "./modules/finops"

    my_ip      = var.my_ip
    site_version = var.site_version
}