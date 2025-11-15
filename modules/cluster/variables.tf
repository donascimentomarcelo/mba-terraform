variable "prefix" {
  type = string
}

variable "subnet_id" {
  type = list(string)
}

variable "security_group_id" {
  type = list(string)
}

variable "instance_count" {
  type = number
}

variable "vpc_id" {
  type = string
}
