variable "prefix" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "subnet_cidr_blocks" {
  type = list(string)
}

variable "instance_count" {
  type = number
}

variable "user_data" {
  type = string
}

variable "desired_capacity" {
  type = number
}

variable "min_size" {
  type = number
}

variable "max_size" {
  type = number
}

variable "scale_out" {
  type = object({
    scaling_adjustment = number
    cooldown           = number
    threshold          = number
  })
}

variable "scale_in" {
  type = object({
    scaling_adjustment = number
    cooldown           = number
    threshold          = number
  })
}
