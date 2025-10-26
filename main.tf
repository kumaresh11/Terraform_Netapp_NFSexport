resource "netapp-ontap_nfs_service" "this" {
  svm_name        = var.svm_name
  is_nfsv3_enabled = var.nfs_v3_enabled
  is_nfsv4_enabled = var.nfs_v4_enabled
}

resource "netapp-ontap_nfs_export_policy" "this" {
  svm_name = var.svm_name
  name     = var.export_policy_name
  depends_on = [netapp-ontap_nfs_service.this]
}

locals {
  access_rule_count = length(var.allowed_clients)
}

resource "netapp-ontap_nfs_export_policy_rule" "rules" {
  count                = local.access_rule_count
  svm_name             = var.svm_name
  policy_name          = netapp-ontap_nfs_export_policy.this.name
  client_match         = var.allowed_clients[count.index]
  ro_rule              = var.read_only ? ["sys"] : []
  rw_rule              = var.read_only ? [] : ["sys"]
  superuser            = ["sys"]
  protocol             = ["nfs"]
  allow_suid           = true
  anonymous_user       = "65534"
  index                = count.index + 1
  depends_on = [netapp-ontap_nfs_export_policy.this]
}

resource "netapp-ontap_volume" "this" {
  name              = var.volume_name
  svm_name          = var.svm_name
  aggregate_name    = var.aggregate_name
  size              = var.size_gb * 1024 * 1024 * 1024
  type              = "rw"
  security_style    = "unix"
  junction_path     = var.junction_path
  snapshot_policy   = "default"
  export_policy     = netapp-ontap_nfs_export_policy.this.name
  is_space_guarantee_enabled = false
  autosize {
    mode      = "grow"
    maximum   = (var.size_gb + 200) * 1024 * 1024 * 1024
    minimum   = var.size_gb * 1024 * 1024 * 1024
    increment = 10 * 1024 * 1024 * 1024
  }
  depends_on = [
    netapp-ontap_nfs_service.this,
    netapp-ontap_nfs_export_policy.this,
    netapp-ontap_nfs_export_policy_rule.rules
  ]
}

resource "null_resource" "mount_nfs" {
  count = var.mount_on_client ? 1 : 0
  connection {
    type        = "ssh"
    host        = var.client_host
    user        = var.client_user
    private_key = file(var.client_private_key_path)
  }
  provisioner "remote-exec" {
    inline = [
      "set -euo pipefail",
      "if command -v apt-get >/dev/null 2>&1; then sudo apt-get update -y && sudo apt-get install -y nfs-common; fi",
      "if command -v yum >/dev/null 2>&1; then sudo yum install -y nfs-utils; fi",
      "sudo mkdir -p ${var.client_mountpoint}",
      "sudo mount -t nfs -o vers=4 ${var.data_lif_ip}:${var.junction_path} ${var.client_mountpoint} || sudo mount -t nfs -o vers=3 ${var.data_lif_ip}:${var.junction_path} ${var.client_mountpoint}",
      "mount | grep ${var.client_mountpoint} || (echo 'Mount failed' && exit 1)"
    ]
  }
  triggers = {
    vol       = netapp-ontap_volume.this.name
    lif       = var.data_lif_ip
    junction  = var.junction_path
    mountpt   = var.client_mountpoint
  }
  depends_on = [netapp-ontap_volume.this]
}

output "nfs_export" {
  value = "${var.data_lif_ip}:${var.junction_path}"
}
output "mount_command_linux" {
  value = "sudo mount -t nfs -o vers=4 ${var.data_lif_ip}:${var.junction_path} ${var.client_mountpoint}"
}