variable "region" {
  type    = string
}

variable "account_id" {
  type    = string
}

variable "project_name" {
  type    = string
}

variable "domain_name" {
  type    = string
}

variable "image_tag" {
  type    = string
}

variable "tags" {
  type    = map(string)
  default = {}
}