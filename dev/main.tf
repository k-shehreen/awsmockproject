
#creation of s3bucket
module "s3-bucket" {
  source = "../modules/bucket"
}

#uploading files to bucket
module "s3-bucket-obj1" {
  source = "../modules/objectupload"
  key = var.key[0]
  s3source = var.s3source[0]
  bucketid = module.s3-bucket.bucketid
  depends_on = [module.s3-bucket]
}

#uploading files to bucket
module "s3-bucket-obj2" {
  source = "../modules/objectupload"
  key = var.key[1]
  s3source = var.s3source[1]
  bucketid = module.s3-bucket.bucketid
  depends_on = [module.s3-bucket]
}

#uploading files to bucket
module "s3-bucket-obj3" {
  source = "../modules/objectupload"
  key = var.key[2]
  s3source = var.s3source[2]
  bucketid = module.s3-bucket.bucketid
  depends_on = [module.s3-bucket]
}


#VPC
module "vpc" {
  source   = "../modules/networking/vpc"
  vpc_cidr = var.vpc_cidr
  tag_name_vpc = var.tag_name[0]
}

#Internet gateway
module "internet_gw" {
    source   = "../modules/networking/igw"
    vpc_id = module.vpc.vpc_id
    tag_name = var.tag_name[1]
}

#Elastic IP
module "elastic_ip" {
  source  = "../modules/networking/e_ip"
  vpc = var.vpc
  dependency = [module.internet_gw]
}

#Nat gateway 
module "nat_gw" {
  source = "../modules/networking/nat"
  allocation_id = module.elastic_ip.nat_id
  subnet_id     = module.subnets.subnet[var.tag_name[3]]
  tag_name = var.tag_name[2]
}


#Subnets
module "subnets" {
  source = "../modules/networking/subnets"
  params = {
      "public_subnet" = {vpc_id = module.vpc.vpc_id, cidr_block = var.cidr_block[0], availability_zone = var.availability_zone[0], tag_name =var.tag_name[3]},
      "pvt_sub1" = {vpc_id = module.vpc.vpc_id, cidr_block = var.cidr_block[1], availability_zone = var.availability_zone[1], tag_name = var.tag_name[4]},
      "pvt_sub2" = {vpc_id = module.vpc.vpc_id, cidr_block = var.cidr_block[2], availability_zone = var.availability_zone[2],  tag_name = var.tag_name[5]}
  }
}

#Security group for public instance
module "public_ec2_sg" {
  source = "../modules/networking/security_group"
  vpc_id = module.vpc.vpc_id
  sg_name = var.sg_name[0]
  description = var.description [0]
  ingress = {
      "HTTP" = { from_port = var.from_port[0], to_port = var.to_port[0], protocol = var.protocol[0], cidr_blocks = [var.cidr_blocks[0]]},
      "HTTPS" = { from_port = var.from_port[1], to_port = var.to_port[1], protocol = var.protocol[0], cidr_blocks = [var.cidr_blocks[0]]},
      "SSH" = { from_port = var.from_port[2], to_port = var.to_port[2], protocol = var.protocol[0], cidr_blocks = [var.cidr_blocks[0]]},
  }
  egress ={
      "all" = { from_port = var.from_port[3], to_port = var.to_port[3], protocol = var.protocol[1], cidr_blocks = [var.cidr_blocks[0]]}
  }
}

#public route table 
module "public_route_table" {
  source = "../modules/networking/route_table"
  vpc_id = module.vpc.vpc_id
  cidr_block = var.cidr_blocks[0]
  gateway_id = module.internet_gw.igw_id
  tag_name = var.tag_name[6]
}

#public route table association
module "public_rt_association_table" {
  source = "../modules/networking/route_table_assoc"
  subnet_id  = module.subnets.subnet[var.tag_name[3]]
  route_table_id = module.public_route_table.rt_id
}

#Security group for private aurora instance
module "private_rds_sg" {
  source = "../modules/networking/security_group"
  vpc_id = module.vpc.vpc_id
  sg_name = var.sg_name[1]
  description = "private rds security group"
  ingress = {
      "HTTP" = { from_port = var.from_port[0], to_port = var.to_port[0], protocol =var.protocol[0], cidr_blocks = [var.cidr_blocks[1]]},
      "HTTPS" = { from_port = var.from_port[1], to_port = var.to_port[1], protocol = var.protocol[0] , cidr_blocks = [var.cidr_blocks[1]]}
  }
  egress ={
      "HTTP" = { from_port = var.from_port[0], to_port = var.to_port[0], protocol =var.protocol[0], cidr_blocks = [var.cidr_blocks[1]]},
      "HTTPS" = { from_port = var.from_port[1], to_port = var.to_port[1], protocol = var.protocol[0] , cidr_blocks = [var.cidr_blocks[1]]}
  }
}

#security group for aurora instance
module "private_rds_sg2" {
  source = "../modules/networking/security_group"
  vpc_id = module.vpc.vpc_id
  sg_name = var.sg_name[3]
  description = "private rds security group"
  ingress = {
       "MySQL" = { from_port = var.from_port[5], to_port = var.to_port[5],  protocol = var.protocol[0], cidr_blocks = [var.cidr_blocks[1]]},
  }
  egress ={
      "HTTP" = { from_port = var.from_port[0], to_port = var.to_port[0], protocol =var.protocol[0], cidr_blocks = [var.cidr_blocks[1]]},
      "HTTPS" = { from_port = var.from_port[1], to_port = var.to_port[1], protocol = var.protocol[0] , cidr_blocks = [var.cidr_blocks[1]]}
  }
}

#private rds subnet group
module "private_rds_subnet_group" {
  source = "../modules/subnet_group"
  name = var.name1
  subnet_ids = [module.subnets.subnet[var.tag_name[4]],module.subnets.subnet[var.tag_name[5]]]
  tag_name = var.tag_name[8]
}

#module for aurora mysql
#we have hardcoded the credentials here vecause we did'nt have the permission for KMS and aws secrets manager to store it
module "pvt_rds" {
  source = "../modules/rds"
  cluster_identifier      = var.cluster_identifier
  engine                  = var.engine 
  engine_mode             = var.engine_mode 
  engine_version          = var.engine_version 
  availability_zone      = var.availability_zone
  database_name           = var.database_name
  username  = var.username
  password         = var.password
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  skip_final_snapshot = var.skip_final_snapshot

}
#private route table for aurora  
module "private_route_table" {
  source = "../modules/networking/route_table"
  vpc_id = module.vpc.vpc_id
  cidr_block = var.cidr_blocks[0]
  gateway_id = module.nat_gw.nat_gw_id
  tag_name = var.tag_name[10]
}

#private route table association for aurora  
module "prvate_rt_association_table" {
  source = "../modules/networking/route_table_assoc"
  subnet_id  = module.subnets.subnet[var.tag_name[5]]
  route_table_id = module.private_route_table.rt_id
}

#_______________________________________________________________

module "pre_signup_lambda_function" {
  source = "../modules/lambda"
  function_name = var.lambda_function_name[0]
  filename = var.filename[0]
  outputfilepath = var.filepath[0]
  runtime = var.runtime_name[0]
  handler = "lambda.handler"
  depends_on = [module.private_rds_sg2, module.subnets]
  //dirname = 
}
module "post_confirmation_lambda_function" {
  source = "../modules/lambda"
  function_name = var.lambda_function_name[1]
  filename = var.filename[1]
  outputfilepath = var.filepath[1]
  runtime = var.runtime_name[1]
  handler = "lambda_function.lambda_handler"
  depends_on = [module.private_rds_sg2, module.subnets]
  
}

#_____________________________________________________________________________________
#match list lambda
#______________________________________________________________________________________
module "getmatchlist" {
  source = "../modules/lambda"
  function_name = var.lambda_function_name[2]
  filename = var.filename[2]
  outputfilepath = var.filepath[2]
  runtime = var.runtime_name[1]
  handler = "lambda_function.lambda_handler"
  depends_on = [module.private_rds_sg2, module.subnets]
  //dirname = 
}
#_____________________________________________________________________________________
# contest list lambda
#_____________________________________________________________________________________
module "getcontestlist" {
  source = "../modules/lambda"
  function_name = var.lambda_function_name[3]
  filename = var.filename[3]
  outputfilepath = var.filepath[3]
  runtime = var.runtime_name[1]
  handler = "lambda_function.lambda_handler"
  depends_on = [module.private_rds_sg2, module.subnets]
  //dirname = 
}
#_____________________________________________________________________________________
# add cash lambda
#_____________________________________________________________________________________
module "add_cash" {
  source = "../modules/lambda"
  function_name = var.lambda_function_name[4]
  filename = var.filename[4]
  outputfilepath = var.filepath[4]
  runtime = var.runtime_name[1]
  handler = "lambda_function.lambda_handler"
  depends_on = [module.private_rds_sg2, module.subnets]
  //dirname = 
}
#_____________________________________________________________________________________
# enter contest lambda
#_____________________________________________________________________________________
module "enter_contest" {
  source = "../modules/lambda"
  function_name = var.lambda_function_name[5]
  filename = var.filename[5]
  outputfilepath = var.filepath[5]
  runtime = var.runtime_name[1]
  handler = "lambda_function.lambda_handler"
  depends_on = [module.private_rds_sg2, module.subnets]
  //dirname = 
}
#_____________________________________________________________________________________
# my team lambda
#_____________________________________________________________________________________
module "my_team" {
  source = "../modules/lambda"
  function_name = var.lambda_function_name[6]
  filename = var.filename[6]
  outputfilepath = var.filepath[6]
  runtime = var.runtime_name[1]
  handler = "lambda_function.lambda_handler"
  depends_on = [module.private_rds_sg2, module.subnets]
  //dirname = 
}
#_____________________________________________________________________________________
#player info lambda
#_____________________________________________________________________________________
module "player_info" {
  source = "../modules/lambda"
  function_name = var.lambda_function_name[7]
  filename = var.filename[7]
  outputfilepath = var.filepath[7]
  runtime = var.runtime_name[1]
  handler = "lambda_function.lambda_handler"
  depends_on = [module.private_rds_sg2, module.subnets]
  //dirname = 
}
#_____________________________________________________________________________________
#player info lambda
#_____________________________________________________________________________________
module "create_team" {
  source = "../modules/lambda"
  function_name = var.lambda_function_name[8]
  filename = var.filename[8]
  outputfilepath = var.filepath[8]
  runtime = var.runtime_name[1]
  handler = "lambda_function.lambda_handler"
  depends_on = [module.private_rds_sg2, module.subnets]
  //dirname = 
}
#_____________________________________________________________________________________
#player info lambda
#_____________________________________________________________________________________
module "leaderboard" {
  source = "../modules/lambda"
  function_name = var.lambda_function_name[9]
  filename = var.filename[9]
  outputfilepath = var.filepath[9]
  runtime = var.runtime_name[1]
  handler = "lambda_function.lambda_handler"
  depends_on = [module.private_rds_sg2, module.subnets]
  //dirname = 
}
#_____________________________________________________________________________________
#player info lambda
#_____________________________________________________________________________________
module "my_contest" {
  source = "../modules/lambda"
  function_name = var.lambda_function_name[10]
  filename = var.filename[10]
  outputfilepath = var.filepath[10]
  runtime = var.runtime_name[1]
  handler = "lambda_function.lambda_handler"
  depends_on = [module.private_rds_sg2, module.subnets]
  //dirname = 
}
#_____________________________________________________________________________________
#player info lambda
#_____________________________________________________________________________________
module "players_list" {
  source = "../modules/lambda"
  function_name = var.lambda_function_name[11]
  filename = var.filename[11]
  outputfilepath = var.filepath[11]
  runtime = var.runtime_name[1]
  handler = "lambda_function.lambda_handler"
  depends_on = [module.private_rds_sg2, module.subnets]
  //dirname = 
}
#_____________________________________________________________________________________
#player info lambda
#_____________________________________________________________________________________
module "wallet_info" {
  source = "../modules/lambda"
  function_name = var.lambda_function_name[12]
  filename = var.filename[12]
  outputfilepath = var.filepath[12]
  runtime = var.runtime_name[1]
  handler = "lambda_function.lambda_handler"
  depends_on = [module.private_rds_sg2, module.subnets]
  //dirname = 
}
#_____________________________________________________________________________________
#player info lambda
#_____________________________________________________________________________________
module "withdraw_cash" {
  source = "../modules/lambda"
  function_name = var.lambda_function_name[13]
  filename = var.filename[13]
  outputfilepath = var.filepath[13]
  runtime = var.runtime_name[1]
  handler = "lambda_function.lambda_handler"
  depends_on = [module.private_rds_sg2, module.subnets]
  //dirname = 
}

module "krackit11_cognito_pool" {

    source = "../modules/cognito_user_pool"
    userpoolname = var.userpoolname
    alias_attributes = var.alias_attributes
    auto_verified_attributes = var.auto_verified_attributes
    default_email_option = var.default_email_option
    lambdafunctionarn = module.pre_signup_lambda_function.lambda_function_arn
    lambdafunctionarn2 = module.post_confirmation_lambda_function.lambda_function_arn

    minimum_length    = var.minimum_length
    require_numbers   = var.require_numbers
     require_lowercase = var.require_lowercase
    require_symbols   = var.require_symbols
    require_uppercase = var.require_uppercase

    tag_name1 =var.tag_name1
    Environment = var.Environment
  }

module "krackit11_domain" {
  source = "../modules/cognito_domain"
  domain       = var.domain
  user_pool_id = module.krackit11_cognito_pool.poolid
  depends_on = [module.krackit11_cognito_pool_client]
}

#_____________________________________________________________________________________
#api
#_________________________________________________________________________
module "api_gateway" {

  source = "../modules/api_gateway"
  api_name = var.api_name
 // cognito_user_pool_name =  module.krackit11_cognito_pool.poolid
  provider_arns = module.krackit11_cognito_pool.poolarn
  depends_on = [module.krackit11_cognito_pool]
}

#______________________________________________________________________________________
#get method
module "api_getmatchlist"{
  source = "../modules/api_get_method"

  rest_api_id = module.api_gateway.api_id
  rest_api_id2 = module.api_gateway.api_id
  rest_api_id3 = module.api_gateway.api_id
  rest_api_id4 = module.api_gateway.api_id
  rest_api_id5 = module.api_gateway.api_id
  
  parent_id =  module.api_gateway.root_resource_id
  path_part = "getmatchlist"
  uri       = module.getmatchlist.invoke_arn

}

#______________________________________________________________________________________
#get method
module "api_profile"{
  source = "../modules/api_get_method"

  rest_api_id = module.api_gateway.api_id
  rest_api_id2 = module.api_gateway.api_id
  rest_api_id3 = module.api_gateway.api_id
  rest_api_id4 = module.api_gateway.api_id
  rest_api_id5 = module.api_gateway.api_id
  
  parent_id =  module.api_gateway.root_resource_id
  path_part = "profile"
  uri       = module.player_info.invoke_arn

}

#______________________________________________________________________________________
#get method
module "api_walletinfo"{
  source = "../modules/api_get_method"

  rest_api_id = module.api_gateway.api_id
  rest_api_id2 = module.api_gateway.api_id
  rest_api_id3 = module.api_gateway.api_id
  rest_api_id4 = module.api_gateway.api_id
  rest_api_id5 = module.api_gateway.api_id
  
  parent_id =  module.api_gateway.root_resource_id
  path_part = "walletinfo"
  uri       = module.wallet_info.invoke_arn

}

#______________________________________________________________________________________
#post method
module "api_getcontestlist"{
  source = "../modules/api_post_method"

  rest_api_id = module.api_gateway.api_id
  rest_api_id2 = module.api_gateway.api_id
  rest_api_id3 = module.api_gateway.api_id
  rest_api_id4 = module.api_gateway.api_id
  rest_api_id5 = module.api_gateway.api_id
  
  parent_id =  module.api_gateway.root_resource_id
  path_part = "getcontestlist"
  uri       = module.getcontestlist.invoke_arn

}

#______________________________________________________________________________________
#post method
module "api_entercontest"{
  source = "../modules/api_post_method"

  rest_api_id = module.api_gateway.api_id
  rest_api_id2 = module.api_gateway.api_id
  rest_api_id3 = module.api_gateway.api_id
  rest_api_id4 = module.api_gateway.api_id
  rest_api_id5 = module.api_gateway.api_id
  
  parent_id =  module.api_gateway.root_resource_id
  path_part = "entercontest"
  uri       = module.enter_contest.invoke_arn

}

#______________________________________________________________________________________
#post method
module "api_myteam"{
  source = "../modules/api_post_method"

  rest_api_id = module.api_gateway.api_id
  rest_api_id2 = module.api_gateway.api_id
  rest_api_id3 = module.api_gateway.api_id
  rest_api_id4 = module.api_gateway.api_id
  rest_api_id5 = module.api_gateway.api_id
  
  parent_id =  module.api_gateway.root_resource_id
  path_part = "myteam"
  uri       = module.my_team.invoke_arn

}

#______________________________________________________________________________________
#post method
module "api_createteam"{
  source = "../modules/api_post_method"

  rest_api_id = module.api_gateway.api_id
  rest_api_id2 = module.api_gateway.api_id
  rest_api_id3 = module.api_gateway.api_id
  rest_api_id4 = module.api_gateway.api_id
  rest_api_id5 = module.api_gateway.api_id
  
  parent_id =  module.api_gateway.root_resource_id
  path_part = "createteam"
  uri       = module.create_team.invoke_arn

}

#______________________________________________________________________________________
#post method
module "api_mycontest"{
  source = "../modules/api_post_method"

  rest_api_id = module.api_gateway.api_id
  rest_api_id2 = module.api_gateway.api_id
  rest_api_id3 = module.api_gateway.api_id
  rest_api_id4 = module.api_gateway.api_id
  rest_api_id5 = module.api_gateway.api_id
  
  parent_id =  module.api_gateway.root_resource_id
  path_part = "mycontest"
  uri       = module.my_contest.invoke_arn

}

#______________________________________________________________________________________
#post method
module "api_playerinfo"{
  source = "../modules/api_post_method"

  rest_api_id = module.api_gateway.api_id
  rest_api_id2 = module.api_gateway.api_id
  rest_api_id3 = module.api_gateway.api_id
  rest_api_id4 = module.api_gateway.api_id
  rest_api_id5 = module.api_gateway.api_id
  
  parent_id =  module.api_gateway.root_resource_id
  path_part = "playerinfo"
  uri       = module.players_list.invoke_arn

}

#______________________________________________________________________________________
#post method
module "api_addcash"{
  source = "../modules/api_post_method"

  rest_api_id = module.api_gateway.api_id
  rest_api_id2 = module.api_gateway.api_id
  rest_api_id3 = module.api_gateway.api_id
  rest_api_id4 = module.api_gateway.api_id
  rest_api_id5 = module.api_gateway.api_id
  
  parent_id =  module.api_gateway.root_resource_id
  path_part = "addcash"
  uri       = module.add_cash.invoke_arn

}

#______________________________________________________________________________________
#post method
module "api_withdrawcash"{
  source = "../modules/api_post_method"

  rest_api_id = module.api_gateway.api_id
  rest_api_id2 = module.api_gateway.api_id
  rest_api_id3 = module.api_gateway.api_id
  rest_api_id4 = module.api_gateway.api_id
  rest_api_id5 = module.api_gateway.api_id
  
  parent_id =  module.api_gateway.root_resource_id
  path_part = "withdrawcash"
  uri       = module.withdraw_cash.invoke_arn

}

#______________________________________________________________________________________
#post method
module "api_leaderboard"{
  source = "../modules/api_post_method"

  rest_api_id = module.api_gateway.api_id
  rest_api_id2 = module.api_gateway.api_id
  rest_api_id3 = module.api_gateway.api_id
  rest_api_id4 = module.api_gateway.api_id
  rest_api_id5 = module.api_gateway.api_id
  
  parent_id =  module.api_gateway.root_resource_id
  path_part = "leaderboard"
  uri       = module.leaderboard.invoke_arn

}

#______________________________________________________________________________________
module "api_deployment" {
  source = "../modules/api_deployment"

  api_id = module.api_gateway.api_id
  depends_on = [module.api_getmatchlist,module.api_profile,module.api_walletinfo,module.api_getcontestlist,module.api_entercontest,module.api_myteam,module.api_createteam,module.api_mycontest,module.api_playerinfo,module.api_addcash,module.api_withdrawcash,module.api_leaderboard]

}
module "krackit11_cognito_pool_client" {
   source = "../modules/cognito_app_client"
  appclientname = var.appclientname
  user_pool_id = module.krackit11_cognito_pool.poolid
  supported_identity_providers = var.supported_identity_providers
  required = var.required
  generate_secret = var.generate_secret
  allowed_oauth_flows           = var.allowed_oauth_flows
  allowed_oauth_scopes          = var.allowed_oauth_scopes
  explicit_auth_flows           = var.explicit_auth_flows
  prevent_user_existence_errors = var.prevent_user_existence_errors
  read_attributes               = var.read_attributes
  refresh_token_validity        = var.refresh_token_validity
  write_attributes              = var.write_attributes
  callback_urls                 = ["https://9asde9idyb.execute-api.us-east-1.amazonaws.com/v1"]
  depends_on = [module.krackit11_cognito_pool]

}

#_____________________________________________________________________________________
resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowMyDemoAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name[2]
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = module.api_gateway.execution_arn
  depends_on = [module.api_gateway , module.api_getmatchlist,module.api_profile,module.api_walletinfo,module.api_getcontestlist,module.api_entercontest,module.api_myteam,module.api_createteam,module.api_mycontest,module.api_playerinfo,module.api_addcash,module.api_withdrawcash,module.api_leaderboard]


}
