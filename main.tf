############### Variables ###############

variable "hcloud_token" {
  default = "0QtyGLqWyuWkrPn49Pb5aO7aM80bqqJLusgEAErFpvWDMXcRHQgJEkfgWn3Un77r"
}

# Define provider
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

# Define Hetzner provider token
provider "hcloud" {
  token = var.hcloud_token
}

# Obtain ssh key data
data "hcloud_ssh_key" "ssh_key" {
  fingerprint = "c5:e7:80:f0:ed:07:3d:e3:97:19:fa:30:b0:7f:d5:e6"
}

# Create Debian 11 server
resource "hcloud_server" "app" {
  count       = var.instances_app
  name        = "app-server-${count.index}"
  image       = var.os_type
  server_type = var.server_type
  location    = var.location
  ssh_keys  = ["${data.hcloud_ssh_key.ssh_key.id}"]
  labels = {
    type = "app"
  }
  user_data = file("user_data.yml")
}


resource "hcloud_server_network" "app_network" {
  count     = var.instances_app
  server_id = hcloud_server.app[count.index].id
  subnet_id = hcloud_network_subnet.hc_private_subnet_app.id
}

resource "hcloud_network_subnet" "hc_private_subnet_app" {
  network_id   = hcloud_network.hc_private_app.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = var.ip_range_app
}

resource "hcloud_network" "hc_private_app" {
  name     = "hc_private_app"
  ip_range = var.ip_range_app
}

output "app_servers_status" {
  value = {
    for server in hcloud_server.app :
    server.name => server.status
  }
}

output "app_servers_ips" {
  value = {
    for server in hcloud_server.app :
    server.name => server.ipv4_address
  }
}
