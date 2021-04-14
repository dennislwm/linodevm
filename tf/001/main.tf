terraform {
  required_providers {
    linode = {
      source = "linode/linode"
    }
  }
}

provider "linode" {
  token = var.str_linode_token
}

//
//  Shared Resource
//  Create a new ssh key
resource "linode_sshkey" "obj_sshkey" {
  label   = "linode ssh key"
  ssh_key = file(format("%s%s", var.str_ssh_path, var.str_ssh_id))
}

//
// Create a new vm
resource "linode_instance" "obj_instance" {
  label           = "linodevm_tf_001"
  image           = "linode/ubuntu18.04"
  region          = "us-east"
  type            = "g6-nanode-1"
  authorized_keys = [linode_sshkey.obj_sshkey.ssh_key]
  root_pass       = var.str_root_pass
}