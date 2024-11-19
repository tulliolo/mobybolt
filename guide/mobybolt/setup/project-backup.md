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

---

## Table of contents
{: .no_toc .text-delta}

1. TOC
{:toc}

---

## Create the directory structure

Log in to your node as `admin` user via Secure Shell (SSH) and create the directory structure:

```sh
$ mkdir -p $HOME/apps/tools/backup
```

---

## Local backup

---

## Remote backup (optional)

We schedule a daily remote backup of the MobyBolt apps, using [Rclone](https://rclone.org){:target="_blank"} as backup client and setting Google Drive as the remote provider.
  
{:.note}
>Rclone supports a large number of [providers](https://rclone.org/#providers){:target="_blank"}. We chose Google Drive because it is very common, but the same procedure can be applied to a different provider.
>
>Please note that **all files will be encrypted at the source** before being transferred, so the remote provider will not be able to access them without the `Password [ E ]`

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

Install a sftp client like [FileZilla](https://filezilla-project.org/){:target="_blank"} and follow the [instructions](https://wiki.filezilla-project.org/FileZilla_Client_Tutorial_(en)){:target="_blank"} to copy the Rclone config file in the MobyBolt PC at `/home/admin/apps/tools/backup/`

##### Transfer the Rclone config file in Linux/MacOs

Open a terminal and follow the next steps:
```sh
$ cd .config/rclone
$ sftp admin@mobybolt.local
Connected to mobybolt.local.
sftp> cd apps/tools/backup/config
sftp> pwd
Remote working directory: /home/admin/apps/tools/backup
sftp> put rclone.config
Uploading rclone.config to /home/admin/apps/tools/backup/rclone.config
rclone.config
sftp> exit
```

### Create the systemd unit file

Log in to your node as `admin` user via Secure Shell (SSH) and access the backup directory:

```sh
$ cd $HOME/apps/tools/backup
```

Here, you should now have the Rclone configuration file:

```sh
$ ls
> rclone.conf
```

Create the systemd unit file with the following contents:

```sh
$ nano backup-remote.service
```

```systemd
# /etc/systemd/system/backup.service
[Unit]
Description=Backup service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
User=admin
Group=admin
ExecStart=docker run --pull always --rm \
    --volume /home/admin/apps/tools/backup/rclone.conf:/config/rclone/rclone.conf:ro \
    --volume /home/admin/apps/:/data/:ro \
    --user 1000:1000 \
    rclone/rclone \
    sync -lv --exclude **/.git/** --delete-excluded /data/ gDriveCrypt:mobybolt/home/admin/apps/
ExecStop=docker image prune -f

[Install]
WantedBy=default.target
```

### Create the systemd timer file

Create the systemd timer file with the following contents:

```sh
$ nano backup-remote.timer
```

```systemd
[Unit]
Description=Daily backup
After=docker.service
Requires=docker.service

[Timer]
OnCalendar=daily
AccuracySec=12h
Persistent=true

[Install]
WantedBy=timers.target
```

### Enable

Install the systemd files by typing:

```sh
$ sudo ln -s /home/admin/apps/tools/backup/backup-remote.service /etc/systemd/system/backup-remote.service
$ sudo ln -s /home/admin/apps/tools/backup/backup-remote.timer /etc/systemd/system/backup-remote.timer
```

Test the backup service:

```sh
$ sudo systemctl start backup-remote.service
$ sudo journalctl -u backup-remote.service -n 10
> ...
> Nov 19 18:11:29 mobybolt systemd[1]: Finished backup-remote.service - Backup service.
```

Open your Google Drive and check the Vault directory. It should contain some unreadable (encrypted) files.

Enable the backup service:

```sh
$ sudo systemctl enable --now backup-remote.timer
```

From now on, the backup will run every day around midnight. You can check the status and the result with:

```sh
$ sudo systemctl status backup-remote.timer
$ sudo journalctl -u backup-remote.service -n 10
```

---

{: .d-flex .flex-justify-between}
[<< Project setup](project-setup)
[Reverse proxy (nginx) >>](reverse-proxy)
