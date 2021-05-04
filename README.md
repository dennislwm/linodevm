# linodevm 
Terraform ["TF"] starter project for Linode single virtual machine ["VM"].

- [linodevm](#linodevm)
  - [About linodevm](#about-linodevm)
    - [Installing Docker Engine on VM](#installing-docker-engine-on-vm)
    - [Configuration of Docker Compose](#configuration-of-docker-compose)
      - [Portainer](#portainer)
      - [Nginx Proxy Manager](#nginx-proxy-manager)
    - [Securing traffic using SSL](#securing-traffic-using-ssl)
      - [Managing DNS](#managing-dns)
      - [Adding Ingress TCP Security Rules](#adding-ingress-tcp-security-rules)
      - [Adding Proxy Host](#adding-proxy-host)
  - [Project Structure](#project-structure)
  - [Prerequisite](#prerequisite)
  - [Terraform](#terraform)
    - [Provider](#provider)
    - [Infrastructure Life Cycle](#infrastructure-life-cycle)
  - [Linode](#linode)
    - [Create an API Token](#create-an-api-token)
    - [Upload SSH Key to Linode Cloud Manager](#upload-ssh-key-to-linode-cloud-manager)
  - [References](#references)

---
## About linodevm

**linodevm** was a personal project to:
- automate creation of a single Linux VM
- automate setup and update of VM
- automate Nginx Proxy Manager ["NginxPM"] as Docker reverse proxy
- automate Portainer as Docker container manager

### Installing Docker Engine on VM

For this project, we're installing Docker Engine on an Ubuntu 18.04 image. Since you're provisioning using Terraform, you don't need to manually connect to your server via SSH.

First, Terraform copies both folders `bin/` and `docker/` from your workstation to the server's `/root/` folder. Then it runs `sudo apt update -y` command.

Terraform provisioner updates a NoIP.com dynamic host with your server's public IP address. Then, it downloads and installs Docker Engine.

```bash
sudo chmod 700 /root/bin/setip.sh
sudo /root/bin/setip.sh [SERVER_IP] [LINODE_INSTANCE_LABEL].myftp.org [USER]:[PASS]
sudo curl -fsSL https://get.docker.com -o bin/get-docker.sh
sudo sh bin/get-docker.sh
```
Terraform provisioner downloads Docker Compose and finally runs both the containers for Portainer and Nginx Proxy Manager.

```bash
sudo curl -L https://github.com/docker/compose/releases/download/1.29.1/docker-compose-Linux-x86_64 -o /root/bin/docker-compose
sudo chmod +x /root/bin/docker-compose
sudo /root/bin/docker-compose -f /root/docker/nginxpmlite/docker-compose.yml up -d
```

### Configuration of Docker Compose

Docker Compose creates the network `nginxpmlite_net_public`, which each container must join to be accessible from outside your server via NginxPM reverse proxy.

Docker Compose creates volumes under `/var/lib/docker/volumes/`for each container. Initially, it creates two volumes for NginxPM and Portainer respectively.
1. nginxpm_vol_config
2. nginxpm_vol_data_portainer

*Note: Portainer creates docker volumes in the same folder above, hence we will require a strategy to backup these volumes to an external storage.*

#### Portainer

For Portainer container, Docker Compose exposes and maps both ports `8000:8000` and `9000:9000`, where `[HOST_PORT]:[CONTAINER_PORT]`. However only port `9000` requires a proxy domain.

Portainer admin panel is accessible at `[SERVER_IP]:9000`. It will prompt you to change the admin password on first connect.

#### Nginx Proxy Manager

For NginxPM container, Docker Compose exposes and maps three ports `80:8080`, `443:4443` and `81:8181`. Both ports `80`, `443` require ingress TCP security rules, while port `81`requires a proxy domain.

The HTTP and HTTPS traffic uses ports `80` and `443` respectively. The NginxPM admin panel is accessible at port `[SERVER_IP]:81`.

The default email and password for first time login is `admin@example.com` and `changeme` respectively. You will be required to change these.

### Securing traffic using SSL

The SSL protocol requires a registered domain name, such as `example.com`. After you have purchased a domain, you need to signup for a Cloudflare.com account.

#### Managing DNS

Cloudflare allows you to manage your domain easily and provides proxied DNS, which basically masks your server IP address.

First change the nameservers of your domain to point to Cloudflare's nameservers, e.g. `lewis.ns.cloudflare.com` and `nola.ns.cloudflare.com`.  Changes will take effect after about 24 hours.

Go to Cloudflare's dashboard, click "Add a Site" and enter your [DOMAIN_NAME] that you purchased. Then click on "DNS Management" icon on the menu.

Click "+Add Record" and add the following records:
| Type | Name | Content | TTL | Proxied Status |
|------|------|---------|-----|----------------|
| A | @ | [SERVER_IP] | Auto | Proxied |
| A | nginxpm | [SERVER_IP] | Auto | Proxied |
| A | portainer | [SERVER_IP] | Auto | Proxied |

You have associated `[DOMAIN_NAME]`, `nginxpm.[DOMAIN_NAME]` and `portainer.[DOMAIN_NAME]` with your [SERVER_IP].

#### Adding Ingress TCP Security Rules

By default, some IaaS automatically allows inbound traffic at both ports `80` and `443`. However, for major cloud providers such as Azure, we need to create an ingress TCP security rule for each port.

#### Adding Proxy Host

Since all your domains are associated with your [SERVER_IP], traffic from all domains will be inbound at port `80` of your server.

We use NginxPM to force all traffic to direct to port `443` which is secured with SSL. It will also redirect traffic to each individual containers by the rules that we set.

Go to NginxPM dashboard at `http:[SERVER_IP]:81`, then click on `Hosts -> Proxy Hosts`.

Click on "Add Proxy Host". Under "Details" tab, enter the following:

* For "Domain Names", we add `nginx.[DOMAIN_NAME]` which is the Cloudflare subdomain that we created.
* For "Scheme", select `https` as we want all traffic to be secured with SSL.
* For "Forward Host Name", type `nginxpmlite_nginxpm_1`, which is the Docker [CONTAINER_NAME] for NginxPM
* For "Forward Port", type `81`, which is the Docker container [HOST_PORT].

Under "SSL" tab, enter the following:

* For "SSL Certificate", click on "Request a New SSL Certificate".
* Enable "Force SSL".

Under "Advanced" tab, copy and paste the following:

```nginx
location / {
    proxy_pass http://[CONTAINER_NAME]:[CONTAINER_PORT];
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

Click "Save". You'll need to substitute in your values for [CONTAINER_NAME] and [CONTAINER_PORT].

*Note: Most containers will have the same [HOST_PORT] and [CONTAINER_PORT]. However, sometimes they're different and this matters when you're adding a Proxy Host.*

To test your proxy host, open a web browser and navigate to `https://nginx.[DOMAIN_NAME]`. You should see the NginxPM login page secured with SSL.

> Repeat the above steps to add a Proxy Host for Portainer. You will need to change `nginxpm.[DOMAIN_NAME]` to `portainer.[DOMAIN_NAME]`, and use Portainer's values for [CONTAINER_NAME], [HOST_PORT] and [CONTAINER_PORT] instead.

---
## Project Structure
     linodevm/                        <-- Root of your project
       |- .gitignore                  <-- GitHub ignore 
       |- LICENSE
       |- README.md                   <-- GitHub README markdown 
       +- bin/                        <-- Holds any executable files
          |- setip.sh                 <-- Updates IP address of dynamic domain at NoIP.com
       +- docker/                     <-- Root of docker files
          +- nginxpm/                 <-- Docker files for NGINX Proxy Manager
          +- portainer/               <-- Docker files for Portainer
       +- tf/                         <-- Terraform root folder
          +- 001/                     <-- Terraform SSH into VM project
          +- dev/                     <-- Linode instance for development
             |- main.tf               <-- Main TF file (required)
             |- outputs.tf            <-- Outputs declaration file
             |- terraform.tfvars      <-- Secret variables declaration file for token, user and passwords (.gitignore)
             |- variables.tf          <-- Variables declaration file
             |- versions.tf           <-- Versions declaration file (required for TF >=v0.13)

---
## Prerequisite

* [Terraform v0.14.10](https://terraform.io)

Terraform is distributed as a single binary. Install Terraform (64-bit) by unzipping it and moving it to a directory included in your system's ``PATH``.

---
## Terraform

### Provider

Terraform v0.13+ requires explicit source information for any providers that are not maintained by HashiCorp, using a new syntax.

```terraform
terraform {
  required_providers {
    linode = {
      source = "linode/linode"
    }
  }
}
```

### Infrastructure Life Cycle

The infrastructure life cycle is as follows:

> `init` -> `plan` -> `apply` -> `destroy`

In the Terraform root folder, execute each command above by appending `terraform`, e.g. `terraform init`.

## Linode

### Create an API Token 

1. Log in to **Cloud Manager**.
2. Click on **My Profile**.
3. Select the **API Tokens** tab.
4. Click on **Add a Personal Access Token**.
5. Enter any name, e.g 'linodevm', in **Label**.
6. Choose **Read/Write** access for Linodes.

![Add a Personal Access Token](https://www.linode.com/docs/guides/api-create-api-token-shortguide/get-started-with-linode-api-new-token_hu5949319457c48d6edae8ef4512b27747_27192_1388x0_resize_q71_bgfafafc_catmullrom_2.jpg)

Reference: [Getting Started with the Linode API](https://www.linode.com/docs/guides/getting-started-with-the-linode-api/#get-an-access-token)

### Upload SSH Key to Linode Cloud Manager

1. Log in to **Cloud Manager**.
2. Click on **My Profile**.
3. Select the **SSH Keys** tab.
4. Click on **Add a SSH Key**.
5. Enter any name, e.g. 'linodevm', in **Label**.
6. Paste in the contents of your public SSH key (id_rsa.pub).

![Upload a SSH Key](https://www.linode.com/docs/guides/use-public-key-authentication-with-ssh/ssh-key-new-key_hu16edec8fd6fbd4321c48817119c54719_81550_1388x0_resize_q71_bgfafafc_catmullrom_2.jpg)

## References

* [Upgrading to Terraform v0.13](https://www.terraform.io/upgrade-guides/0-13.html)

* [Use SSH Public Key Authentication on Linux, macOS, and Windows](https://www.linode.com/docs/guides/use-public-key-authentication-with-ssh)

* [A Beginner's Guide to Terraform](https://www.linode.com/docs/guides/beginners-guide-to-terraform)

* [How to Install Docker CE on Ubuntu 18.04](https://www.linode.com/docs/guides/install-docker-ce-ubuntu-1804)
