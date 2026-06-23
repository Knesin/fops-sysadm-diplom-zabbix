#создаем облачную сеть
resource "yandex_vpc_network" "develop" {
  name = "develop-fops-${var.flow}"
}

#создаем подсеть zone A
resource "yandex_vpc_subnet" "private_a" {
  name           = "private-fops-${var.flow}-ru-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["10.0.1.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}

#создаем подсеть zone B
resource "yandex_vpc_subnet" "private_b" {
  name           = "private-fops-${var.flow}-ru-central1-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["10.0.2.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}

#создаем публичную подсеть
resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["10.0.10.0/24"]
}

#создаем NAT для выхода в интернет
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "fops-gateway-${var.flow}"
  shared_egress_gateway {}
}

#создаем сетевой маршрут для выхода в интернет через NAT
resource "yandex_vpc_route_table" "rt" {
  name       = "fops-route-table-${var.flow}"
  network_id = yandex_vpc_network.develop.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

#создаем группу безопасности (firewall)
resource "yandex_vpc_security_group" "bastion" {
  name       = "bastion-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  # разрешаем входящий SSH
  ingress {
    description    = "Allow 0.0.0.0/0"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
  # разрешаем любой исходящий трафик
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Группа безопасности WEB серверов
resource "yandex_vpc_security_group" "web_sg" {
  name       = "web-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  # разрешаем входящий HTTP от балансировщика
  ingress {
    description       = "Allow HTTP"
    protocol          = "TCP"
    port              = 80
    security_group_id = yandex_vpc_security_group.alb_sg.id
  }
  # разрешаем входящий HTTP для проверки доступности
  ingress {
    description       = "ALB health checks"
    protocol          = "TCP"
    port              = 80
    predefined_target = "loadbalancer_healthchecks"
  }
  # разрешаем входящий SSH от серверов группы бастион
  ingress {
    description       = "SSH from Bastion"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }
  # разрешаем входящий трафик от Zabbix сервера
  ingress {
    description       = "Zabbix Agent"
    protocol          = "TCP"
    port              = 10050
    security_group_id = yandex_vpc_security_group.zabbix_sg.id
  }
  # Разрешаем весь исходящий трафик
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "zabbix_sg" {
  name       = "zabbix-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  # разрешаем входящий HTTP 
  ingress {
    description    = "Allow HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  # разрешаем входящий SSH от серверов группы бастион
  ingress {
    description       = "SSH from Bastion"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }
  # разрешаем входящий трафик от Zabbix агентов
  ingress {
    protocol       = "TCP"
    port           = 10051
    v4_cidr_blocks = ["10.0.0.0/8"]
  }
  # Разрешаем весь исходящий трафик
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "elasticsearch_sg" {
  name       = "elasticsearch-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  # разрешаем входящий SSH от серверов группы бастион
  ingress {
    description       = "SSH from Bastion"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }
  # разрешаем входящий трафик от Zabbix сервера
  ingress {
    description       = "Zabbix Agent"
    protocol          = "TCP"
    port              = 10050
    security_group_id = yandex_vpc_security_group.zabbix_sg.id
  }
  # разрешаем входящий для Elasticsearch
  ingress {
    description    = "Elasticsearch"
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["10.0.0.0/8"]
  }
  # Разрешаем весь исходящий трафик
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "kibana_sg" {
  name       = "kibana-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  # разрешаем входящий SSH от серверов группы бастион
  ingress {
    description       = "SSH from Bastion"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }
  # разрешаем входящий трафик от Zabbix сервера
  ingress {
    description       = "Zabbix Agent"
    protocol          = "TCP"
    port              = 10050
    security_group_id = yandex_vpc_security_group.zabbix_sg.id
  }
  # разрешаем входящий трафик Elasticsearch
  ingress {
    description    = "Elasticsearch"
    protocol       = "TCP"
    port           = 9200
    security_group_id = yandex_vpc_security_group.elasticsearch_sg.id
  }
  # разрешаем входящий трафик для WEB сервера Kibana
  ingress {
    description    = "Kibana WEB"
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  # Разрешаем весь исходящий трафик
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "alb_sg" {
  name       = "alb-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  # разрешаем входящий HTTP
  ingress {
    description       = "HTTP from Internet"
    protocol          = "TCP"
    port              = 80
    v4_cidr_blocks    = ["0.0.0.0/0"]
  }
  # Разрешаем весь исходящий трафик
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}