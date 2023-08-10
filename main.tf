terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.12.0"
    }
  }
}

# Expects credentials for providers to be set in environment variables
provider "digitalocean" {}

provider "cloudflare" {}

# Data sources for DigitalOcean and Cloudflare
data "digitalocean_ssh_key" "ed25519" {
  name = "ed25519"
}

data "cloudflare_zones" "domain" {
  filter {
    name = "pezlab.dev"
  }
}

# Pull in our config file
locals {
  config = yamldecode(file("${path.module}/config.yml"))
}

# Create the DigitalOcean droplet
resource "digitalocean_droplet" "wg" {
  image    = local.config.wg_server.image
  name     = "wg-server"
  region   = local.config.wg_server.region
  size     = local.config.wg_server.size
  ssh_keys = [data.digitalocean_ssh_key.ed25519.id]
}

# Create the Cloudflare DNS record
resource "cloudflare_record" "wg" {
  type    = "A"
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = local.config.wg_server.dns
  value   = digitalocean_droplet.wg.ipv4_address
  ttl     = 1
  proxied = false
}

# Sanity output for the public IPv4 address
output "wg_ip" {
  value = digitalocean_droplet.wg.ipv4_address
}