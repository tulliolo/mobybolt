---
layout: default
title: Project backup
nav_order: 15
parent: + Setup
grand_parent: MobyBolt
---

<!-- markdownlint-disable MD014 MD022 MD025 MD033 MD040 -->

# Project backup
{: .no_toc}

We schedule a daily backup, either local and remote, for the MobyBolt apps.

For convenience we will use [Rclone](https://rclone.org){:target="_blank"} for both local and remote bakup.
Rclone is a command-line program to manage files on cloud storage, supporting a large number of [providers](https://rclone.org/#providers){:target="_blank"}. 

We chose (encrypted) Google Drive as a remote provider for this guide because it is very common, but the same procedure can be applied to a different provider.

{:.important}
Please note that **all files will be encrypted at the source** before being transferred, so the remote provider (and yourself) will not be able to access them without the `Password [ E ]`.

---

## Table of contents
{: .no_toc .text-delta}

1. TOC
{:toc}

---

## Prepare

### Create the directory structure

Log in to your node as `satoshi` user via Secure Shell (SSH) and create the directory structure:

```sh
$ mkdir -p $HOME/apps/tools/backup
```

Enter the new directory:

```sh
$ cd $HOME/apps/tools/backup
```

### Prepare Rclone

Create an empty Rclone configuration file by typing:

```sh
$ touch rclone.conf
```

### Prepare the backup scripts

We will create the **systemd template files** for the backup service and timer.
These files will be used for both local and remote backup.

{:.more}
[Understanding Systemd Units and Unit Files](https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files){:target="_blank"}

- Create a file named `backup@.service` and populate it with the following content:

  {:.warning}
  The `@` is very important! It defines a systemd template file.

  ```sh
  $ nano backup@.service
  ```

  ```systemd
  [Unit]
  Description=%i backup service
  After=docker.service
  Requires=docker.service
  
  [Service]
  Type=oneshot
  User=satoshi
  Group=satoshi
  EnvironmentFile=/home/satoshi/apps/tools/backup/%i
  ExecStartPre=-docker exec backup-%i stop
  ExecStartPre=-docker rm backup-%i
  ExecStartPre=-docker pull rclone/rclone
  ExecStartPre=-docker image prune -f
  ExecStart=docker run --rm --name backup-%i \
      --volume /home/satoshi/apps/tools/backup/rclone.conf:/config/rclone/rclone.conf:ro \
      --volume /home/satoshi/apps/:/data/source/:ro \
      --volume /media/backup/:/data/target/ \
      --user 1000:1000 \
      rclone/rclone \
      sync -lv --exclude **/.git/** --delete-excluded /data/source $TARGET
  
  [Install]
  WantedBy=default.target
  ```

  In this [systemd service unit](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html){:target="_blank"}, we design the backup service as follow:
  - the service will run as `satoshi` user
  - the service will run under docker using the official [Rclone](https://rclone.org/){:target="_blank"} image
  - the service will sync a target local or remote dir with the local `/home/satoshi/apps/` dir

- Create a file named `backup@.timer` and populate it with the following content:

  ```sh
  $ nano backup@.timer
  ```

  ```systemd
  [Unit]
  Description=%i daily backup
  After=docker.service
  Requires=docker.service
  
  [Timer]
  OnCalendar=daily
  AccuracySec=12h
  Persistent=true
  
  [Install]
  WantedBy=timers.target
  ```

  This [systemd timer unit](https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html){:target="_blank"} will launch the backup service of the same name once a day.

- Install the backup scripts by running the following commands:

  ```sh
  $ sudo ln -s /home/satoshi/apps/tools/backup/backup@.service /etc/systemd/system/backup@.service
  $ sudo ln -s /home/satoshi/apps/tools/backup/backup@.timer /etc/systemd/system/backup@.timer
  ```

---

## Local backup

Follow this section if you want a local daily backup (recommended). If you only want a remote backup, skip to the [next section](#remote-backup).

### Storage device size

The `apps` dir backup is very small in size so even the smallest USB thumbdrive or microSD card will do the job.

### Formatting

- To ensure that the storage device does not contain malicious code, we will format it on our local computer (select a name easy to recognize like "MobyBolt backup" and choose the FAT filesystem). The following external guides explain how to format your USB thumbdrive or microSD card on [Windows](https://www.techsolutions.support.com/how-to/how-to-format-a-usb-drive-in-windows-12893){:target="_blank"}, [macOS](https://www.techsolutions.support.com/how-to/how-to-format-a-usb-drive-on-a-mac-12899){:target="_blank"}, or [Linux](https://phoenixnap.com/kb/linux-format-usb){:target="_blank"}.

- Once formatted, plug the storage device into your MobyBolt PC. If using a thumbdrive, use one of the black USB2 ports.

###  Set up a mounting point for the storage device

- Create the mounting directory and make it immutable

  ```sh
  $ sudo mkdir /media/backup
  $ sudo chattr +i /media/backup
  ```

- List active block devices and copy the `UUID` of your backup device into a text editor on your local computer (e.g. here `123456`).

  ```sh
  $ lsblk -o NAME,MOUNTPOINT,UUID,FSTYPE,SIZE,LABEL,MODEL
  > NAME   MOUNTPOINT      UUID     FSTYPE   SIZE LABEL           MODEL
  > ...
  > sdc                                      3.8G                 USB Flash Disk
  > └─sdc1 /media/backup   123456   vfat     3.8G MobyBolt Backup 
  ```

- Edit your Filesystem Table configuration file and add the following as a new line at the end, replacing `123456` with your own `UUID`.

  ```sh
  $ sudo nano /etc/fstab
  ```

  ```ini
  UUID=123456 /media/backup vfat auto,noexec,nouser,rw,sync,nosuid,nodev,noatime,nodiratime,nofail,fmask=0111,dmask=0000 0 0
  ```
  
  {:.more}
  [fstab guide](https://www.howtogeek.com/howto/38125/htg-explains-what-is-the-linux-fstab-and-how-does-it-work/){:target="_blank"}

- Mount the drive and check the file system. Is `/media/backup` listed?

  ```sh
  $ sudo mount -a
  $ df -h /media/backup
  > Filesystem      Size  Used Avail Use% Mounted on
  > /dev/sdc1       3.8G  4.0K  3.8G   1% /media/backup
  ```

### Configure the local Backup

Create the local backup env file:

```sh
$ echo "TARGET=/data/target/apps" > local
```

### Test the local backup

- Test the local backup by running the following command:

  ```sh
  $ sudo systemctl start backup@local
  ```

  {:.hint}
  You can force a local backup at any time using the command above.

### Check the local backup

To check the last run you can:

- check the last backup logs (pay attention to the date in the following example output):

  ```sh
  $ sudo journalctl -u backup@local -n 10
  > ...
  > Dec 08 08:57:43 vmobybolt systemd[1]: backup@local.service: Deactivated successfully.
  > Dec 08 08:57:43 vmobybolt systemd[1]: Finished backup@local.service - local backup service.
  ```
- check the local backup dir:

  ```sh
  $ ls -l /media/backup/apps
  > ...
  > drwxrwxrwx 3 root root 4096 Dec  8 08:57 tools
  > ...
  ```

### Schedule the local backup

- Enable the local backup timer by running the following command:

  ```sh
  $ sudo systemctl enable --now backup@local.timer
  ```

- Verify the local backup timer status:

  ```sh
  $ systemctl status backup@local.timer
  > ● backup@local.timer - local daily backup
  >      Loaded: loaded (/etc/systemd/system/backup@local.timer; enabled; preset: enabled)
  >      Active: active (waiting) since Sun 2024-12-08 09:48:07 CET; 14s ago
  >     Trigger: Mon 2024-12-09 00:00:00 CET; 14h left
  >    Triggers: ● backup@local.service
  ```

{:.hint}
A local backup will be performed every night around midnight.

---

## Remote backup

Follow this section if you want a remote daily backup.

### Configure Rclone

{:.warning}
**These steps must be performed on your regular PC**, where we will perform the configuration of the remote provider, which requires the presence of a browser.

First of all you need to install Rclone following the [installation guide](https://rclone.org/install/) for your system.

#### Create the gDrive config

In a terminal, run `rclone config` and follow the interactive setup process below to configure the [`gDrive` remote provider](https://rclone.org/drive/){:target="_blank"}:

```sh
No remotes found, make a new one?
n) New remote
r) Rename remote
c) Copy remote
s) Set configuration password
q) Quit config
n/r/c/s/q> n
name> gDrive
Type of storage to configure.
Choose a number from below, or type in your own value
[snip]
XX / Google Drive
   \ "drive"
[snip]
Storage> drive
Google Application Client Id - leave blank normally.
client_id>
Google Application Client Secret - leave blank normally.
client_secret>
Scope that rclone should use when requesting access from drive.
Choose a number from below, or type in your own value
 1 / Full access all files, excluding Application Data Folder.
   \ "drive"
 2 / Read-only access to file metadata and file contents.
   \ "drive.readonly"
   / Access to files created by rclone only.
 3 | These are visible in the drive website.
   | File authorization is revoked when the user deauthorizes the app.
   \ "drive.file"
   / Allows read and write access to the Application Data folder.
 4 | This is not visible in the drive website.
   \ "drive.appfolder"
   / Allows read-only access to file metadata but
 5 | does not allow any access to read or download file content.
   \ "drive.metadata.readonly"
scope> 1
Service Account Credentials JSON file path - needed only if you want use SA instead of interactive login.
service_account_file>
Remote config
Use web browser to automatically authenticate rclone with remote?
 * Say Y if the machine running rclone has a web browser you can use
 * Say N if running rclone on a (remote) machine without web browser access
If not sure try Y. If Y failed, try N.
y) Yes
n) No
y/n> y
If your browser doesn't open automatically go to the following link: http://127.0.0.1:53682/auth
Log in and authorize rclone for access
Waiting for code...
```

At this step, a browser should automatically open (if not open it and point to `http://127.0.0.1:53682/auth`). Login with your Google account and follow the instructions. At the end, the interactive setup should continue as reported below:

```sh
Got code
Configure this as a Shared Drive (Team Drive)?
y) Yes
n) No
y/n> n
Configuration complete.
Options:
type: drive
- client_id:
- client_secret:
- scope: drive
- root_folder_id:
- service_account_file:
- token: {"access_token":"XXX","token_type":"Bearer","refresh_token":"XXX","expiry":"2014-03-16T13:57:58.955387075Z"}
Keep this "gDrive" remote?
y) Yes this is OK
e) Edit this remote
d) Delete this remote
y/e/d> y
```

#### Create the gDriveCrypt config

Now we configure the [encryption](https://rclone.org/crypt/){:target="_blank"} for the gDrive remote.

Firts of all, open your Google Drive and create a directory named `Vault`. We will use it as the endpoint for our encrypted backups.

Then, in a terminal, run `rclone config` again and follow the interactive setup process below to create the new `gDriveCrypt` remote, encrypted with `Password [ E ]`:

```sh
Current remotes:

Name                 Type
====                 ====
gDrive               drive

e) Edit existing remote
n) New remote
d) Delete remote
r) Rename remote
c) Copy remote
s) Set configuration password
q) Quit config
n/s/q> n
name> gDriveCrypt
Type of storage to configure.
Enter a string value. Press Enter for the default ("").
Choose a number from below, or type in your own value
[snip]
XX / Encrypt/Decrypt a remote
   \ "crypt"
[snip]
Storage> crypt
** See help for crypt backend at: https://rclone.org/crypt/ **

Remote to encrypt/decrypt.
Normally should contain a ':' and a path, eg "myremote:path/to/dir",
"myremote:bucket" or maybe "myremote:" (not recommended).
Enter a string value. Press Enter for the default ("").
remote> gDrive:Vault
How to encrypt the filenames.
Enter a string value. Press Enter for the default ("standard").
Choose a number from below, or type in your own value.
   / Encrypt the filenames.
 1 | See the docs for the details.
   \ "standard"
 2 / Very simple filename obfuscation.
   \ "obfuscate"
   / Don't encrypt the file names.
 3 | Adds a ".bin" extension only.
   \ "off"
filename_encryption> 1
Option to either encrypt directory names or leave them intact.

NB If filename_encryption is "off" then this option will do nothing.
Enter a boolean value (true or false). Press Enter for the default ("true").
Choose a number from below, or type in your own value
 1 / Encrypt directory names.
   \ "true"
 2 / Don't encrypt directory names, leave them intact.
   \ "false"
directory_name_encryption> 1
Password or pass phrase for encryption.
y) Yes type in my own password
g) Generate random password
y/g> y
Enter the password:
password: Password [ E ]
Confirm the password:
password: Password [ E ]
Password or pass phrase for salt. Optional but recommended.
Should be different to the previous password.
y) Yes type in my own password
g) Generate random password
n) No leave this optional password blank (default)
y/g/n> n
Edit advanced config? (y/n)
y) Yes
n) No (default)
y/n>
Remote config
--------------------
[gDriveCrypt]
type = crypt
remote = gDrive:Vault
password = *** ENCRYPTED ***
--------------------
y) Yes this is OK (default)
e) Edit this remote
d) Delete this remote
y/e/d> y
```

#### Transfer the Rclone config file

Identify your Rclone config file by typing `rclone config file`.
The path should be:
- `C:\Users\<username>\.config\rclone\rclone.conf` in Windows;
- `$HOME/.config/rclone/rclone.conf` in Linux/MacOs

##### Transfer the Rclone config file in Windows

Install a sftp client like [FileZilla](https://filezilla-project.org/){:target="_blank"} and follow the [instructions](https://wiki.filezilla-project.org/FileZilla_Client_Tutorial_(en)){:target="_blank"} to copy the Rclone config file in the MobyBolt PC at `/home/satoshi/apps/tools/backup/`

##### Transfer the Rclone config file in Linux/MacOs

Open a terminal and follow the next steps:
```sh
$ cd .config/rclone
$ sftp satoshi@mobybolt.local
Connected to mobybolt.local.
sftp> cd apps/tools/backup/config
sftp> pwd
Remote working directory: /home/satoshi/apps/tools/backup
sftp> put rclone.config
Uploading rclone.config to /home/satoshi/apps/tools/backup/rclone.config
rclone.config
sftp> exit
```

### Configure the remote Backup

- Log in to your node as `satoshi` user via Secure Shell (SSH) and access the backup directory:

  ```sh
  $ cd $HOME/apps/tools/backup
  ```

- Check the new Rclone configuration file:

  ```sh
  $ cat rclone.conf                                                                                                                                                                     ✔ 
  > [gDrive]
  > type = drive
  > ...
  ```

- Create the remote backup env file:

  ```sh
  $ echo "TARGET=gDriveCrypt:mobybolt/apps" > remote
  ```

### Test the remote backup

- Test the remote backup by running the following command:

  ```sh
  $ sudo systemctl start backup@remote
  ```

  {:.hint}
  You can force a remote backup at any time using the command above.

### Check the remote backup

To check the last run you can:

- check the last backup logs (pay attention to the date in the following example output):

  ```sh
  $ sudo journalctl -u backup@remote -n 10
  > ...
  > Dec 08 10:39:26 vmobybolt systemd[1]: backup@remote.service: Deactivated successfully.
  > Dec 08 10:39:26 vmobybolt systemd[1]: Finished backup@remote.service - remote backup service.
  ```
- verify that the remote directory is encrypted (you should see something unreadable here):

  ```sh
  $ docker run --rm -v ./rclone.conf:/config/rclone/rclone.conf:ro rclone/rclone ls gDrive:Vault
  > ...
  > abcde/fghi
  > ...
  ```

- decrypt the content of the remote directory:

  ```sh
  $ docker run --rm -v ./rclone.conf:/config/rclone/rclone.conf:ro rclone/rclone ls gDriveCrypt:mobybolt
  >     33 apps/tools/backup/remote
  >   1307 apps/tools/backup/rclone.conf
  >     26 apps/tools/backup/local
  >    177 apps/tools/backup/backup@.timer
  >    721 apps/tools/backup/backup@.service
  ```

### Schedule the remote backup

- Enable the remote backup timer by running the following command:

  ```sh
  $ sudo systemctl enable --now backup@remote.timer
  ```

- Verify the remote backup timer status:

  ```sh
  $ systemctl status backup@remote.timer
  > ● backup@remote.timer - remote daily backup
  >      Loaded: loaded (/etc/systemd/system/backup@remote.timer; enabled; preset: enabled)
  >      Active: active (waiting) since Sun 2024-12-08 10:40:29 CET; 44s ago
  >     Trigger: Mon 2024-12-09 00:00:00 CET; 13h left
  >    Triggers: ● backup@remote.service
  ```

{:.hint}
A remote backup will be performed every night around midnight.

---

{: .d-flex .flex-justify-between}
[<< Project setup](project-setup)
[Reverse proxy (nginx) >>](reverse-proxy)
