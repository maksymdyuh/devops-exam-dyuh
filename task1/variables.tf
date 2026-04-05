variable "do_token" {
  description = "DigitalOcean Personal Access Token"
  type        = string
  sensitive   = true
}

variable "spaces_access_key" {
  description = "DigitalOcean Spaces Access Key"
  type        = string
  sensitive   = true
}

variable "spaces_secret_key" {
  description = "DigitalOcean Spaces Secret Key"
  type        = string
  sensitive   = true
}
