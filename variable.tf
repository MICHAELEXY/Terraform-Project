variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "db_instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  description = "SSH key pair"
  type        = string
  default     = "cloud"
}

variable "my_ip" {
  type        = string
  description = "Your IP address"
  /* validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.my_ip))
    error_message = "Must be a valid IPv4 address."
  }*/
}
