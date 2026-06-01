variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "account_id" {
  type    = string
  default = "884916644426"
}

variable "project_name" {
  type    = string
  default = "djaret"
}

variable "domain_name" {
  type    = string
  default = "www.yaret.cloud"
}

variable "image_tag" {
  type    = string
  default = "082ac10"
}

variable "tags" {
  type    = map(string)
  default = {}
}