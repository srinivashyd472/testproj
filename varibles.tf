ariable "rgname" {
  type    = string
  #default = "kantarproj"
}
variable "location" {
  type    = string
  #default = "eastus2"
}
variable "sg_account_name" {
  type    = string
  #default = "webstorage472"
}
variable "vnet_name" {
  type    = string
  #default = "webstorage-vnet2"
}
variable "subnet_name" {
  type    = string
  #default = "webstoragesubnet2"
}
variable "pvtend_subnet_name" {
  type    = string
  #default = "webpe-storage-subnet2"
}
variable "pvtend_name" {
  type    = string
  #default = "storagepvtendpoint2"
}
variable "pvtservice_connection_name" {
  type    = string
  #default = "storagepvtendsvcon2"
}
variable "appservice_plan_name" {
  type    = string
  #default = "webappsvplan2"
}
variable "appservice_name" {
  type    = string
  #default = "webappssv2"
}
variable "vnetaddress" {
    type = list
    #default = ["10.0.0.0/16"]
}
variable "subnetaddress" {
    type = list
    #default = ["10.0.1.0/24"]
}
variable "endpsubnetaddress" {
    type = list
    #default = ["10.0.2.0/24"]
}
