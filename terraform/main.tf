variable "subscription_id" {
  default = "fe16a035-e540-4ab7-80d9-373fa9a3d6ae"
}

variable "tenant_id" {
  default = "64dc69e4-d083-49fc-9569-ebece1dd1408"
}

# test 1: miwi-private-cli
# 
# covers the following test cases related to provisioning only:
#   - cli install
#   - user defined routing
#   - byo-nsg
#   - managed identity
#   - private cluster
module "miwi_private_cli" {
  source = "./setup"

  cluster_name    = "dscott-miwi-private-cli"
  outbound_type   = "UserDefinedRouting"
  byo_nsg         = true
  miwi            = true
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  private         = true
}

# test 2: miwi-public-cli
# 
# covers the following test cases related to provisioning only:
#   - cli install
#   - load balancer routing
#   - non-byo-nsg
#   - managed identity
#   - public cluster
module "miwi_public_cli" {
  source = "./setup"

  cluster_name    = "dscott-miwi-public-cli"
  outbound_type   = "Loadbalancer"
  byo_nsg         = false
  miwi            = true
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# test 3: miwi-private-api
# 
# covers the following test cases related to provisioning only:
#   - api-based install
#   - non-udr routing
#   - byo-nsg
#   - managed identity
#   - private cluster
module "miwi_private_api" {
  source = "./setup"

  cluster_name    = "dscott-miwi-private-api"
  outbound_type   = "Loadbalancer"
  byo_nsg         = true
  miwi            = true
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  private         = true
}

# test 4: miwi-public-api
# 
# covers the following test cases related to provisioning only:
#   - api-based install
#   - udr routing
#   - non byo-nsg
#   - managed identity
#   - private cluster
module "miwi_public_api" {
  source = "./setup"

  cluster_name    = "dscott-miwi-public-api"
  outbound_type   = "UserDefinedRouting"
  byo_nsg         = false
  miwi            = true
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# test 5: sp-private-cli
# 
# covers the following test cases related to provisioning only:
#   - cli install
#   - load balancer routing
#   - non byo-nsg
#   - service principal
#   - private cluster
module "sp_private_cli" {
  source = "./setup"

  cluster_name    = "dscott-sp-private-cli"
  outbound_type   = "Loadbalancer"
  byo_nsg         = false
  miwi            = false
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  private         = true
}

# test 6: sp-public-cli
# 
# covers the following test cases related to provisioning only:
#   - cli install
#   - udr routing
#   - byo-nsg
#   - service principal
#   - public cluster
module "sp_public_cli" {
  source = "./setup"

  cluster_name    = "dscott-sp-public-cli"
  outbound_type   = "UserDefinedRouting"
  byo_nsg         = true
  miwi            = false
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# test 7: sp-private-api
# 
# covers the following test cases related to provisioning only:
#   - api-based install
#   - udr routing
#   - non byo-nsg
#   - service principal
#   - private cluster
module "sp_private_api" {
  source = "./setup"

  cluster_name    = "dscott-sp-private-api"
  outbound_type   = "UserDefinedRouting"
  byo_nsg         = false
  miwi            = false
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  private         = true
}

# test 8: sp-public-api
# 
# covers the following test cases related to provisioning only:
#   - api-based install
#   - non-udr routing
#   - byo-nsg
#   - service principal
#   - private cluster
module "sp_public_api" {
  source = "./setup"

  cluster_name    = "dscott-sp-public-api"
  outbound_type   = "Loadbalancer"
  byo_nsg         = true
  miwi            = false
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
