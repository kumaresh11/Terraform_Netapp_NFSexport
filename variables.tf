variable "ontap_hostname" { type = string }
variable "ontap_username" { type = string }
variable "ontap_password" { type = string  sensitive = true }
variable "ontap_insecure" { type = bool    default  = true }
variable "svm_name"       { type = string }
variable "volume_name"    { type = string  default = "nfs_vol01" }
variable "aggregate_name" { type = string  description = "Aggregate for FlexVol" }
variable "size_gb"        { type = number  default = 100 }
variable "junction_path"  { type = string  default = "/nfs_vol01" }
variable "export_policy_name" { type = string default = "tf_nfs_policy" }
variable "allowed_clients"    { type = list(string) default = ["0.0.0.0/0"] }
variable "read_only"          { type = bool default = false }
variable "nfs_v4_enabled"     { type = bool default = true }
variable "nfs_v3_enabled"     { type = bool default = true }
variable "mount_on_client"   { type = bool   default = false }
variable "client_host"       { type = string default = "" }
variable "client_user"       { type = string default = "ec2-user" }
variable "client_private_key_path" { type = string default = "" }
variable "client_mountpoint" { type = string default = "/mnt/netapp" }
variable "data_lif_ip"       { type = string default = "" }