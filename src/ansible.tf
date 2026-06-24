resource "null_resource" "ansible" {

  depends_on = [
local_file.inventory,
    yandex_compute_instance.bastion,
    yandex_compute_instance.web_a,
    yandex_compute_instance.web_b,
    yandex_compute_instance.kibana,
    yandex_compute_instance.elasticsearch,
    yandex_compute_instance.zabbix
  ]

  triggers = {
    inventory_hash = local_file.inventory.id,
    bastion_id       = yandex_compute_instance.bastion.id
    web_a_id         = yandex_compute_instance.web_a.id
    web_b_id         = yandex_compute_instance.web_b.id
    kibana_id        = yandex_compute_instance.kibana.id
    elasticsearch_id = yandex_compute_instance.elasticsearch.id
    zabbix_id        = yandex_compute_instance.zabbix.id
  }

  provisioner "local-exec" {
    command = "sleep 60 && ansible-playbook -i hosts.ini ansible/playbook.yml"
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
      ANSIBLE_SSH_PIPELINING    = "True"

    }
  }
}