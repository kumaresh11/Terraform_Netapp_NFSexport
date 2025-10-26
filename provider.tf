provider "netapp-ontap" {
  hostname        = var.ontap_hostname
  username        = var.ontap_username
  password        = var.ontap_password
  https           = true
  insecure        = var.ontap_insecure
  timeout         = 60
}