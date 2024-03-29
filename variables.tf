
variable "prefix" {
  type = string
}

variable "project_account" {
  type = string
}

variable "project_name" {
  type = string
}

variable "project_envs" {
  type = map
}

variable "project_git" {
  type = string
}

variable "project_path" {
  type = string
  default = "/"
}

variable "project_network_name" {
  type = string
  default = ""
}

variable "project_default_tags" {
  type = string
  default = ""
}

variable "terraform_version" {
  type = string
  default = "1.3.7"
}


variable "project_type" {
  type = string
  default = "shared" 
  #shared - all envs use the same TF files
  #branched - each env uses branch named after itself
  #pathed - each env uses folder named after itself
}

variable "compute_type" {
  type = string
  default = "BUILD_GENERAL1_SMALL" 
}
