
#считываем данные об образе ОС
data "yandex_compute_image" "ubuntu_2404_lts" {
  family = "ubuntu-2404-lts"
}

resource "yandex_compute_instance" "web_a" {
  name        = "web-a" #Имя ВМ в облачной консоли
  hostname    = "web-a" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!!


  resources {
    cores         = var.vm_res.cores
    memory        = var.vm_res.memory
    core_fraction = var.vm_res.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init_web.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_a.id
    nat                = false
    security_group_ids = [ yandex_vpc_security_group.web_sg.id]
  }
}

resource "yandex_compute_instance" "web_b" {
  name        = "web-b" #Имя ВМ в облачной консоли
  hostname    = "web-b" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-b" #зона ВМ должна совпадать с зоной subnet!!!

  resources {
    cores         = var.vm_res.cores
    memory        = var.vm_res.memory
    core_fraction = var.vm_res.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init_web.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_b.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web_sg.id]

  }
}

resource "yandex_compute_instance" "bastion" {
  name        = "bastion" #Имя ВМ в облачной консоли
  hostname    = "bastion" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!!

  resources {
    cores         = var.vm_res.cores
    memory        = var.vm_res.memory
    core_fraction = var.vm_res.core_fraction
  }

  boot_disk { 
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init_bastion.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id #зона ВМ должна совпадать с зоной subnet!!!
    nat                = true
    security_group_ids = [ yandex_vpc_security_group.bastion.id]
  }
}


resource "yandex_compute_instance" "zabbix" {
  name        = "zabbix" #Имя ВМ в облачной консоли
  hostname    = "zabbix" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!!

  resources {
    cores         = var.vm_res.cores
    memory        = var.vm_res.memory
    core_fraction = var.vm_res.core_fraction
  }

  boot_disk { 
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data = templatefile("./cloud-init_zabbix.yml", {
      ZABBIX_CONFIG_CONTENT = indent(6, file("./zabbix.conf.php"))
    })
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_a.id #зона ВМ должна совпадать с зоной subnet!!!
    nat                = false
    security_group_ids = [ yandex_vpc_security_group.zabbix_sg.id]
  }
}

resource "yandex_compute_instance" "elasticsearch" {
  name        = "elasticsearch" #Имя ВМ в облачной консоли
  hostname    = "elasticsearch" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!!


  resources {
    cores         = var.vm_res.cores
    memory        = 2
    core_fraction = var.vm_res.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init_elasticsearch.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_a.id
    nat                = false
    security_group_ids = [ yandex_vpc_security_group.elasticsearch_sg.id]
  }
}

resource "yandex_compute_instance" "kibana" {
  name        = "kibana" #Имя ВМ в облачной консоли
  hostname    = "kibana" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!!
  depends_on = [
    yandex_compute_instance.elasticsearch
  ]


  resources {
    cores         = var.vm_res.cores
    memory        = var.vm_res.memory
    core_fraction = var.vm_res.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init_kibana.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_a.id
    nat                = false
    security_group_ids = [ yandex_vpc_security_group.kibana_sg.id]
  }

}

# [loadbalancer]
#   # ${yandex_alb_load_balancer.web.listener[0].endpoint[0].address[0].external_ipv4_address[0].address}

resource "local_file" "inventory" {
  content  = <<-XYZ
  
  [bastion]
  ${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}

  [zabbix]
  # ${yandex_compute_instance.zabbix.network_interface.0.nat_ip_address}
  ${yandex_compute_instance.zabbix.network_interface.0.ip_address}

  [elasticsearch]
  ${yandex_compute_instance.elasticsearch.network_interface.0.ip_address}

  [kibana]
  # ${yandex_compute_instance.kibana.network_interface.0.nat_ip_address}
  ${yandex_compute_instance.kibana.network_interface.0.ip_address}

  [webservers]
  ${yandex_compute_instance.web_a.network_interface.0.ip_address}
  ${yandex_compute_instance.web_b.network_interface.0.ip_address}
  [webservers:vars]
  ansible_ssh_common_args='-o ProxyCommand="ssh -p 22 -W %h:%p -q user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}"'
  XYZ
  filename = "./hosts.ini"
}



