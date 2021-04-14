//  Terraform loads variables in the following order, with later sources taking precedence over earlier ones:
//    1. Environment variables
//    2. The terraform.tfvars file, if present.
//    3. The terraform.tfvars.json file, if present.
//    4. Any *.auto.tfvars or *.auto.tfvars.json files, processed in lexical order of their filenames.
//    5. Any -var and -var-file options on the command line, in the order they are provided. (This includes variables set by a Terraform Cloud workspace.)

//
//  Declared in terraform.tfvars (.gitignore)
variable str_linode_token {
  description = "personal access token required for API access"
}
variable str_root_pass {
  description = "root password required for instance"
}
variable str_ssh_path {
  //Windows version
  //default     = "c:\\users\\denbrige\\.ssh\\"
  default     = "/Users/dennislee/.ssh/"
  description = "Path to local SSH folder"
}
variable str_ssh_id {
  default     = "id_linodevm.pub"
  description = "Name of local SSH public_key file"
}
