variable "flow" {
  type    = string
  default = "44"
}

variable "cloud_id" {
  type    = string
  default = "b1gemrh200gvr8mopqio"
}
variable "folder_id" {
  type    = string
  default = "b1g2jsur6qadlbfsbtca"
}

variable "vm_res" {
  type = map(number)
  default = {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }
}

