resource "local_file" "inventory" {
  content  = <<-XYZ
  [bastion]
  bastion-host ansible_host=${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} ansible_user=user

  [zabbix]
  zabbix-host ansible_host=${yandex_compute_instance.zabbix.network_interface.0.ip_address}

  [elasticsearch]
  elasticsearch-host ansible_host=${yandex_compute_instance.elasticsearch.network_interface.0.ip_address}

  [kibana]
  kibana-host ansible_host=${yandex_compute_instance.kibana.network_interface.0.ip_address}

  [webservers]
  web-a ansible_host=${yandex_compute_instance.web_a.network_interface.0.ip_address}
  web-b ansible_host=${yandex_compute_instance.web_b.network_interface.0.ip_address}
  
  [all:children]
  webservers
  bastion
  kibana
  elasticsearch
  zabbix

  [private_networks:children]
  webservers
  kibana
  elasticsearch
  zabbix

  [private_networks:vars]
  ansible_user=user
  ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p -q user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}"'
  
  XYZ

  filename = "./hosts.ini"
}

resource "local_file" "hosts_md" {
  content = <<-EOF

# Infrastructure

* [Load Balancer](http://${yandex_alb_load_balancer.web.listener[0].endpoint[0].address[0].external_ipv4_address[0].address})
* [Zabbix](http://${yandex_compute_instance.zabbix.network_interface.0.nat_ip_address}/zabbix)
* [Kibana](http://${yandex_compute_instance.kibana.network_interface.0.nat_ip_address}:5601)

# SSH connection

*  Bastion `ssh user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}`
*  Zabbix `ssh -J user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} user@${yandex_compute_instance.zabbix.network_interface.0.ip_address}`
*  Kibana `ssh -J user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} user@${yandex_compute_instance.kibana.network_interface.0.ip_address}`
*  Web-a `ssh -J user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} user@${yandex_compute_instance.web_a.network_interface.0.ip_address}`
*  Web-b `ssh -J user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} user@${yandex_compute_instance.web_b.network_interface.0.ip_address}`
*  Elasticsearch `ssh -J user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} user@${yandex_compute_instance.elasticsearch.network_interface.0.ip_address}`
  EOF

  filename = "./hosts.md"
}