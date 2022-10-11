
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

variable "project_vpc_id" {
  type = string
  default = ""
}

variable "project_vpc_subnet_id" {
  type = list(string)
  default = []
}

variable "project_vpc_security_group_ids" {
  type = list(string)
  default = []
}


variable "terraform_version" {
  type = string
  default = "1.3.1"
}

variable "generate_ssh_key" {
  type = bool
  default = false
}

variable "project_type" {
  type = string
  default = "shared" 
  #shared - all envs use the same TF files
  #branched - each env uses branch named after itself
  #pathed - each env uses folder named after itself
}
