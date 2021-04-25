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
  label           = "dbdev"
  image           = "linode/ubuntu18.04"
  region          = "us-east"
  type            = "g6-nanode-1"
  //  Browse lists of images, regions, and sizes for Linode
  //    URL: https://www.postman.com/api-evangelist/workspace/linode/collection/35240-5118653b-32fb-44bb-85d5-2ed7977a9670?ctx=documentation
  //
  authorized_keys = [linode_sshkey.obj_sshkey.ssh_key]
  root_pass       = var.str_root_pass

  connection {
    type        = "ssh"
    host        = linode_instance.obj_instance.ip_address
    user        = "root"
    private_key = file(format("%s%s", var.str_ssh_path, var.str_ssh_id_private))
  }

  //
  // make remote folders in /root/
  provisioner "remote-exec" {
    inline     = ["sudo mkdir /root/${linode_instance.obj_instance.label}"]
    on_failure = continue
  }
  //
  // copy executable files to remote folder
  provisioner "file" {
    source      = "${var.str_root_path}/bin"
    destination = "/root"
    on_failure  = continue
    //
    // If the source is /foo (no trailing slash), and the destination is /tmp, 
    //  then the contents of /foo on the local machine will be uploaded to /tmp/foo on the remote machine. 
    //  The foo directory on the remote machine will be created by Terraform.    
  }
  //
  // copy docker files to remote folder
  provisioner "file" {
    source      = "${var.str_root_path}/docker"
    destination = "/root"
    on_failure  = continue
  }
  //
  // execute remote commands
  provisioner "remote-exec" {
    inline     = ["sudo chmod 700 /root/bin/setip.sh", "sudo /root/bin/setip.sh ${linode_instance.obj_instance.ip_address} ${linode_instance.obj_instance.label} ${var.str_user_pass}"]
    on_failure = continue
  }
  //
  // get docker and docker-compose
  provisioner "remote-exec" {
    inline     = ["sudo curl -fsSL https://get.docker.com -o bin/get-docker.sh", "sudo sh bin/get-docker.sh", "sudo curl -L https://github.com/docker/compose/releases/download/1.29.1/docker-compose-Linux-x86_64 -o /root/bin/docker-compose", "sudo chmod +x /root/bin/docker-compose"]
    on_failure = continue
  }
  //
  // docker container portainer
  provisioner "remote-exec" {
    inline     = ["sudo /root/bin/docker-compose -f /root/docker/portainer/docker-compose.yml up -d"]
    //inline     = ["cd /root/${linode_instance.obj_instance.label}", "docker volume create portainer_data", "docker run -d --restart unless-stopped -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer"]
    on_failure = continue
  }
  //
  // docker container nginxpm
  provisioner "remote-exec" {
    inline     = ["sudo /root/bin/docker-compose -f /root/docker/nginxpm/docker-compose.yml up -d"]
    on_failure = continue
  }
}