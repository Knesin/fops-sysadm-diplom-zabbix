resource "yandex_storage_bucket" "zabbix_backup" {
  bucket = "zabbix-backup-${random_string.suffix.result}"

  anonymous_access_flags {
    read = true
    list = false
  }

  lifecycle_rule {
    id      = "delete-backups"
    enabled = true

    expiration {
      days = 1
    }
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "yandex_storage_object" "zabbix_dump" {
  bucket = yandex_storage_bucket.zabbix_backup.bucket
  key    = "zabbix.dump"
  source = "./vms_init/zabbix.dump"
}

