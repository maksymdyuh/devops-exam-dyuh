terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34.1"
    }
  }

  backend "s3" {
    endpoint                    = "https://fra1.digitaloceanspaces.com"
    region                      = "us-east-1" # Для S3-сумісного бекенду в DO часто залишають us-east-1, а endpoint вказує на fra1
    bucket                      = "dyuh-tfstate-bucket"
    key                         = "task1/terraform.tfstate"
    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_s3_checksum            = true
  }
}

provider "digitalocean" {
  token             = var.do_token
  spaces_access_id  = var.spaces_access_key
  spaces_secret_key = var.spaces_secret_key
}

# 1. Віртуальна приватна хмара (VPC)
resource "digitalocean_vpc" "vpc" {
  name     = "dyuh-vpc-ekz"
  region   = "fra1"
  ip_range = "10.10.11.0/24" # Змінено з 10.10.10.0/24 через конфлікт зі старою мережею
}

# 2. Налаштування фаєрволу
resource "digitalocean_firewall" "firewall" {
  name = "dyuh-firewall"

  droplet_ids = [digitalocean_droplet.node.id]

  # Вхідні (inbound) підключення
  dynamic "inbound_rule" {
    for_each = ["22", "80", "443", "8000", "8001", "8002", "8003"]
    content {
      protocol         = "tcp"
      port_range       = inbound_rule.value
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  }

  # Вихідні (outbound) підключення
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# 3. Віртуальна машина (Droplet)
resource "digitalocean_droplet" "node" {
  name     = "dyuh-node"
  image    = "ubuntu-24-04-x64"
  region   = "fra1"
  size     = "s-2vcpu-4gb" # Мінімум 2 CPU та 4Gb RAM для комфортної роботи Minikube
  vpc_uuid = digitalocean_vpc.vpc.id
  
  # Додаємо ваш публічний SSH ключ (потрібно буде його прокинути)
  ssh_keys = [digitalocean_ssh_key.my_key.id]
}

# Створюємо новий SSH ключ в DO для доступу до створеної ВМ
resource "digitalocean_ssh_key" "my_key" {
  name       = "dyuh-vm-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBL+vAllzW2fZX+e2aJdT8HlxJq5jXalQyx7pEqVn5ov"
}

# 4. Сховище для об'єктів (бакет)
resource "digitalocean_spaces_bucket" "bucket" {
  name   = "dyuh-bucket"
  region = "fra1"
  # Тип за замовчуванням (у DO це стандартний Spaces)
}
