---
layout: default
title: Configuration
nav_order: 40
parent: System
---
<!-- markdownlint-disable MD014 MD022 MD025 MD033 MD040 -->

# Configuration
{: .no_toc }

You are now on the command line of your own Bitcoin node. Let's start with the configuration.

{: .important }
From now on, all operations will be performed by [connecting in ssh](remote-access#access-with-secure-shell) as `admin` user.

---

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Disable root access

We will disable root access for security reasons.

### Disable SSH root access

- Type the following command:

  ```sh
  $ sudo sed -i 's/^#PermitRootLogin .*$/PermitRootLogin no/' /etc/ssh/sshd_config
  ```

- Verify the configuration (the output should look like below):

  ```sh
  $ cat /etc/ssh/sshd_config | grep PermitRootLogin

  > PermitRootLogin no
  > # the setting of "PermitRootLogin prohibit-password".
  ```

- Restart the sshd service

  ```sh
  $ sudo systemctl restart sshd
  ```

### Disable root password

- Type the following command:

  ```sh
  $ sudo passwd -l root

  > passwd: password changed.
  ```

- Try to become root using the root password defined during [installation](operating-system#install-debian) (you shouldn't be able to do this):
  
  ```sh
  $ su -
  > Password: 

  > su: Authentication failure
  ```
  
  {: .note }
  From now on you will only have root access using **`sudo`** and **`Password [ A ]`**:
  
  ```
  $ sudo su -
  > [sudo] password for admin:

  $ exit
  ```

---

## System update

It is important to keep the system up-to-date with security patches and application updates. The "Advanced Packaging Tool" (apt) makes this easy. To update the operating system and all installed software packages, run the following commands:

```
$ sudo apt update
$ sudo apt full-upgrade
```

{: .note }
Do this regularly every few months to get security-related updates.

---

{: .d-flex .flex-justify-between }
[<< Remote access](remote-access)
[Docker >>](docker)
