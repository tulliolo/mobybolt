---
layout: default
title: Configuration
nav_order: 40
parent: System
---
<!-- markdownlint-disable MD014 MD022 MD025 MD033 MD040 -->

# Configuration
{: .no_toc}

You are now on the command line of your own Bitcoin node. Let's start with the configuration.

---

## Table of contents
{: .no_toc .text-delta}

1. TOC
{:toc}

---

## Create a new connection

We will use the primary user `admin` which we already configured in the MobyBolt PC (see [Configure the admin user](operating-system#configure-the-admin-user) section).

- Log in again using SSH (see [Access with Secure Shell](remote-access#access-with-secure-shell) section), with user `admin` and your `password [A]`

  ```sh
  $ ssh admin@mobybolt.local
  ```

- You can exit your session any time with

  ```sh
  $ exit
  ```

<br/>

{: .note}
To change the system configuration and files that don't belong to user `admin`, you have to prefix commands with `sudo`.
You will be prompted to enter your `Password [ A ]` from time to time for increased security.

---

## System update

It is important to keep the system up-to-date with security patches and application updates. The "Advanced Packaging Tool" (apt) makes this easy. To update the operating system and all installed software packages, run the following commands:

```sh
$ sudo apt update
$ sudo apt full-upgrade
```

{: .important}
Do this regularly every few months to get security-related updates.

---

## Check drive performance

Performant drives are essential for your node. Let's check if your drives work well as-is.

- Install the software to measure the performance of your drives:

  ```sh
  $ sudo apt install -y hdparm
  ```

- List the names of connected block devices:

  ```sh
  $ lsblk -o NAME,MOUNTPOINT,UUID,FSTYPE,SIZE,LABEL,MODEL

  > NAME   MOUNTPOINT      UUID                                 FSTYPE    SIZE LABEL MODEL
  > sda                                                                 476.9G       CYX-SSD-S1000
  > ├─sda1 /boot/efi       ED3D-37B3                            vfat      512M       
  > ├─sda2 /               b6649e30-d00b-4fd8-8ce0-b85be4c3075b ext4    475.5G       
  > └─sda3 [SWAP]          b39d91f1-065d-41fd-be35-cbd96ac1ff3a swap      976M       
  > sdb                                                                   1.8T       SPCC Solid State Disk
  > └─sda1 /var/lib/docker 774987cd-7827-47b2-813e-6fdb2692a182 ext4      1.8T
  ```
  
  Here we will see all the disks detected by the system and what unit name have been assigned to them. Pay attention to the `NAME`, `SIZE` and `MODEL` columns to identify each one, e.g: "sdb, 1.9T, SPCC Solid State Disk".<br/><br/>
  For each disk present, also pay attention to the `MOUNT POINT` column.

### Check your primary drive

- Identify your primary/system drive:
  - it should have the **NAME** `sda` or `nvme0n1`, but it may have a different name in your case;
  - it shall have a **MOUNT POINT** in `/`.

  In the example below it is `sda`.

- Measure the speed of your primary/system drive (where `<YOUR_DRIVE>` is your device name, e.g. `sda`):

  ```sh
  $ sudo hdparm -t --direct /dev/<YOUR_DRIVE>
  > Timing O_DIRECT disk reads: 932 MB in  3.00 seconds = 310.23 MB/sec
  ```

### Check your secondary drive

{: .warning}
Follow this section only if you have a separate disk for data and you configured it in step 7.d of the [operating system installation](operating-system#install-debian). 

- Identify your secondary/data drive:
  - it should have the **NAME** like `sdX` or `nvmeXnY` (where X and Y may vary);
  - it shall have a **MOUNT POINT** in `/var/lib/docker`.

  In the example below it is `sdb`.

- Measure the speed of your secondary/data drive (where `<YOUR_DRIVE>` is your device name, e.g. `sdb`):

  ```sh
  $ sudo hdparm -t --direct /dev/<YOUR_DRIVE>
  > Timing O_DIRECT disk reads: 932 MB in  3.00 seconds = 310.23 MB/sec
  ```

<br/>

{: .note}
If the measured speeds are more than 150 MB/s, you're good but it is recommended more for a better experience.

---

## Login with SSH keys

One of the best options to secure the sensitive SSH login is to disable passwords altogether and require an SSH key certificate. Only someone with physical possession of the private certificate key can log in.

### Generate SSH Keys on Windows

From your regular Windows PC, follow this guide [Configure "No Password SSH Keys Authentication with PuTTY" on Linux Servers](https://www.tecmint.com/ssh-passwordless-login-with-putty/){:target="_blank"}

You have now generated three new files. Keep them safe!

- `MobyBolt-Private-Key.ppk`
- `MobyBolt-Public-Key`
- `authorized-Keys.txt`

You also copied the content of `authorized-Keys.txt` into the file `~/.ssh/authorized_keys` on your MobyBolt PC and changed the directory’s permissions to `700`.

After specifying your private key file in the PuTTY configuration, you’re all set.

### Generate SSH Keys on MacOS or Linux

- In the terminal on your regular MacOS/Linux PC, check if keys already exist:
  
  ```sh
  $ ls -la ~/.ssh/*.pub
  ```

- If files are listed, your public key should be named something like `id_dsa.pub`, `id_ecdsa.pub`, `id_ed25519.pub` or `id_rsa.pub`. If one of these files already exists, skip the next step.

- If none of those files exist, or you get a `No such file or directory error`, create a new public / private key pair:
  
  ```sh
  $ ssh-keygen -t rsa -b 4096
  ```

  When you’re prompted to `Enter a file in which to save the key`, press `Enter` to use the default file location. Optionally, for maximum security, use `password [A]` to protect your key.

- The public key now needs to be copied to the MobyBolt PC. Use the command `ssh-copy-id`, which stores your public key on the remote machine (and creates files and directories, if needed). You will be prompted for your SSH login password once.

  ```sh
  $ ssh-copy-id admin@mobybolt.local
  ```

  {: .hint}
  >If you are on MacOS and encounter an error, you might need install `ssh-copy-id` first by running the following command on your Mac’s command line:
  >
  >```sh
  >$ brew install ssh-copy-id
  >```

### Disable password login

- Log in to the MobyBolt PC as `admin` using SSH with your SSH key. You shouldn't be prompted for the admin's password anymore.

- Edit the ssh configuration file `/etc/ssh/sshd_config` to harden our security:

  ```sh 
  $ sudo nano /etc/ssh/sshd_config
  ```

- Uncomment the following option to disable password authentication:

  ```config
  PasswordAuthentication no
  ```

- Below the commented out `ChallengeResponseAuthentication` option, add the following line to disable s/key, a one-time password authentification. Save and exit.

  ```config
  #ChallengeResponseAuthentication no
  KbdInteractiveAuthentication no
  ```

- Restart the SSH daemon, then exit your session:

  ```sh
  $ sudo systemctl restart sshd
  $ exit
  ```

- Log in again with user `admin`

You can no longer log in with a password. User `admin` is the only user that has the necessary SSH keys, no other user can log in remotely.

{: .important}
Backup your SSH keys! You will need to attach a screen and keyboard to your MobyBolt PC if you lose them.

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
  
- Try to become root using `sudo` and `Password [ A ]` :

  ```sh
  $ sudo su -
  > [sudo] password for admin:
  ```

- Type `exit`, to return to the admin shell:

  ```sh
  $ exit
  ```

<br/>

{: .note}
From now on you will only have root access using `sudo` and `Password [ A ]`:

---

## Enabling the Uncomplicated Firewall

A firewall controls what kind of outside traffic your machine accepts and which applications can send data out.
By default, many network ports are open and listening for incoming connections.
Closing unnecessary ports can mitigate many potential system vulnerabilities.

For now, only SSH and Avahi should be reachable from the outside.

{: .note}
>We won't need to enable any other services in UFW, as Docker will directly configure its own firewall rules, bypassing those configured at the host level with UFW. In summary:
>- UFW will take care of blocking or enabling the services installed on the host;
>- Docker will take care of blocking or enabling the services installed via Docker.
>
>For more information, see: [Docker and UFW](https://docs.docker.com/engine/network/packet-filtering-firewalls/#docker-and-ufw){:target="_blank"}

- With user `admin`, configure and enable the firewall rules:

  {: .hint}
  If you are seeing: `ERROR: Couldn't determine iptables version` you may need to reboot after installing `UFW`.

  ```sh
  $ sudo apt install -y ufw
  $ sudo ufw default deny incoming
  $ sudo ufw default allow outgoing
  $ sudo ufw allow 22/tcp comment 'allow SSH'
  $ sudo ufw allow 5353/udp comment 'allow Avahi'
  $ sudo ufw logging off
  $ sudo ufw enable
  ```

- Check if the UFW is properly configured and active

  ```sh
  $ sudo ufw status
  > Status: active
  > 
  > To                         Action      From
  > --                         ------      ----
  > 22/tcp                     ALLOW       Anywhere                   # allow SSH
  > 5353/udp                   ALLOW       Anywhere                   # allow Avahi
  > 22/tcp (v6)                ALLOW       Anywhere (v6)              # allow SSH
  > 5353/udp (v6)              ALLOW       Anywhere (v6)              # allow Avahi
  ```

- Make sure that the UFW is started automatically on boot

  ```sh
  $ sudo systemctl enable ufw
  ```

For more information, see: [UFW Essentials](https://www.digitalocean.com/community/tutorials/ufw-essentials-common-firewall-rules-and-commands){:target="_blank"}

{: .hint}
If you find yourself locked out by mistake, you can connect a keyboard and screen to your Pi to log in locally and fix these settings (especially for the SSH port 22).

---

## fail2ban

The SSH login to the MobyBolt PC must be specially protected.
An additional measure is to install "fail2ban", which prevents an attacker from gaining access via brute force.
It simply cuts off any remote system with five failed login attempts for ten minutes.

- Install "fail2ban", which activates automatically

  ```sh
  $ sudo apt install -y fail2ban
  ```

The initial configuration is fine, as it protects SSH by default.

{: .more}
For more information, see: [customize fail2ban configuration](https://linode.com/docs/security/using-fail2ban-for-security/){:target="_blank"}

---

{: .d-flex .flex-justify-between}
[<< Remote access](remote-access)
[Docker >>](docker)
