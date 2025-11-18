terraform {
  required_version = ">= 1.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "api_token" {
  type        = string
  description = "DigitalOcean API token"
  sensitive   = true
}

variable "private_key" {
  type        = string
  description = "Path to SSH private key file"
  sensitive   = true
}

variable "private_key_name" {
  type        = string
  description = "Name of the SSH key in DigitalOcean"
}

variable "droplet_name" {
  type        = string
  description = "Name for the droplet"
}

variable "droplet_size" {
  type        = string
  description = "Size slug for the droplet"
}

variable "db_password" {
  type        = string
  description = "Database password"
  sensitive   = true
}

variable "server_domain" {
  type        = string
  description = "Domain for the server"
}

variable "server_root" {
  type        = string
  description = "Root directory for the server"
}

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
  graceful_shutdown  = false
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