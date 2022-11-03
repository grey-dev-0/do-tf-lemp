terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }
}

variable "api_token" {}
variable "private_key" {}
variable "private_key_name" {}
variable "droplet_name" {}
variable "droplet_size" {}
variable "db_password" {
  type = string
  sensitive = true
}
variable "server_domain" {}
variable "server_root" {}

provider "digitalocean" {
  token = var.api_token
}

data "digitalocean_ssh_key" "terraform" {
  name = var.private_key_name
}

resource "digitalocean_droplet" "lemp" {
  image = "rockylinux-9-x64"
  name = var.droplet_name
  region = "fra1"
  size = var.droplet_size
  monitoring = true
  ssh_keys = [
    data.digitalocean_ssh_key.terraform.id
  ]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.private_key)
    timeout = "2m"
  }

  provisioner "file" {
    source = "resources"
    destination = "/root"
  }

  provisioner "file" {
    source = "provision"
    destination = "/root/provision"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /root/provision",
      "/root/provision --db_password ${var.db_password} --server_domain ${var.server_domain} --server_root ${var.server_root} > /root/provision.log 2>&1",
      "rm -rf /root/provision /root/resources"
    ]
  }
}