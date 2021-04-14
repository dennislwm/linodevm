# linodevm 
Terraform starter project for Linode single virtual machine ["VM"].

- [linodevm](#linodevm)
  - [About linodevm](#about-linodevm)
  - [Project Structure](#project-structure)
  - [Prerequisite](#prerequisite)
  - [Terraform](#terraform)
    - [Provider](#provider)
  - [Linode](#linode)
    - [Create an API Token](#create-an-api-token)
    - [Upload SSH Key to Linode Cloud Manager](#upload-ssh-key-to-linode-cloud-manager)
  - [References](#references)

---
## About linodevm

**linodevm** was a personal project to:
- automate creation of a single Linux VM
- automate setup and update of VM
- automate nginx-proxy-manager as Docker reverse proxy

---
## Project Structure
     linodevm/                        <-- Root of your project
       |- README.md                   <-- This README markdown file
       +- tf/                         <-- Terraform root folder
          +- 001/                     <-- Terraform SSH into VM project

---
## Prerequisite

* [Terraform](https://terraform.io)

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