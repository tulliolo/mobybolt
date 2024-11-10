---
layout: default
title: Remote access
nav_order: 30
parent: System
---
<!-- markdownlint-disable MD014 MD022 MD025 MD033 MD040 -->

# Remote access
{: .no_toc }

We connect to your MobyBolt PC by using the Secure Shell.

---

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Find your PC

Your MobyBolt PC is starting and gets a new address from your home network. Give it a few minutes to come to life.

- On your regular computer, open the Terminal (also known as "command line"). Here are a few links with additional details how to do that for [Windows](https://www.computerhope.com/issues/chusedos.htm), [MacOS](https://macpaw.com/how-to/use-terminal-on-mac) and [Linux](https://www.howtogeek.com/140679/beginner-geek-how-to-start-using-the-linux-terminal/).

- Try to ping the MobyBolt PC using the hostname `mobybolt.local` you configured [above](https://github.com/tulliolo/mobybolt/wiki/operating-system#install-avahi). Press Ctrl-C to interrupt.

  ```sh
  $ ping mobybolt.local
  
  > PING mobybolt.local (192.168.122.58) 56(84) bytes of data.
  > 64 bytes from 192.168.122.58 (192.168.122.58): icmp_seq=1 ttl=64 time=88.1 ms
  > 64 bytes from 192.168.122.58 (192.168.122.58): icmp_seq=2 ttl=64 time=61.5 ms
  > ...
  ```

- If the ping command fails or does not return anything, you need to manually look for your IP. This is a common challenge: just follow the method suggested [here](https://github.com/tulliolo/mobybolt/wiki/operating-system#install-avahi).

You should now be able to reach your PC, either with the hostname `mobybolt.local` or an IP address like `192.168.X.Y`.

---

## Access with Secure Shell

Now it's time to connect to the MobyBolt via Secure Shell (SSH) and get to work. For that, we need an SSH client.

### Connection details

| hostname | mobybolt.local (or IP address) |
| port | 22 |
| username | admin |
| password | Password [ A ] |

### Access with Secure Shell in Linux/MacOS

Open a terminal and type:

```sh
$ ssh admin@mobybolt.local

> The authenticity of host 'mobybolt.local (192.168.122.58)' can't be established.
> ED25519 key fingerprint is SHA256:RbaJtfc7Xl0OM7VIDZj8WfvT8HhzRyRWK1pbs5BJp+M.
> This key is not known by any other names.
> Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
> Warning: Permanently added 'mobybolt.local' (ED25519) to the list of known hosts.
> admin@mobybolt.local's password: 
> ...
```

Type `yes` when the security banner appears (only the first time) and then insert `Password [ A ]` when prompted. 

:bulb: if you have problems logging in, you can try using the IP address in the form `192.168.X.Y`, instead of `mobybolt.local`, for example:

```sh
$ ssh admin@192.168.122.58

> The authenticity of host '192.168.122.58 (192.168.122.58)' can't be established.
> ED25519 key fingerprint is SHA256:RbaJtfc7Xl0OM7VIDZj8WfvT8HhzRyRWK1pbs5BJp+M.
> This host key is known by the following other names/addresses:
>     ~/.ssh/known_hosts:8: mobybolt.local
> Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
> Warning: Permanently added '192.168.122.58' (ED25519) to the list of known hosts.
> admin@192.168.122.58's password: 
> ...
```

### Access with Secure Shell in Windows

Download and install [Putty](https://www.putty.org/).

Start Putty. 

To the left tree, select `Session` and type the following values in the boxes to the right:
- `Hostname (or IP Address)`: `admin@mobybolt.local` (or the IP Address in the form `admin@192.168.X.Y`)
- `Port`: 22

Press the button `OPEN`. When a `PuTTy security alert` banner appears, press the `Accept` button and finally type your `Password [ A ]`

### Exit from Secure Shell

You can exit your session at any time by:

```sh
$ exit
```

---

## The command line

We will work on the command line of the PC, which may be new to you.
Find some basic information below.
It will help you navigate and interact with your PC.

You enter commands and the PC answers by printing the results below your command.
To clarify where a command begins, every command in this guide starts with the `$` sign. The system response is marked with the `>` character.

Additional comments begin with `#` and must not be entered.

In the following example, just enter `ls -la` and press the enter/return key:

```sh
$ ls -la
> example system response
# This is a comment, don't enter this on the command line
```

- **Auto-complete commands**:
  You can use the `Tab` key for auto-completion when you enter commands, i.e., for commands, directories, or filenames.

- **Command history**:
  by pressing ⬆️ (arrow up) and ⬇️ (arrow down) on your keyboard, you can recall previously entered commands.

- **Common Linux commands**:
  For a very selective reference list of Linux commands, please refer to this [guide](https://www.geeksforgeeks.org/linux-commands-cheat-sheet/).

- **Use admin privileges**:
  Our regular user has no direct admin privileges.
  If a command needs to edit the system configuration, we must use the `sudo` ("superuser do") command as a prefix.
  Instead of editing a system file with `nano /etc/fstab`, we use `sudo nano /etc/fstab`.

- **Using the Nano text editor**:
  We use the Nano editor to create new text files or edit existing ones.
  It's not complicated, but to save and exit is not intuitive.

  - Save: hit `Ctrl-O` (for Output), confirm the filename, and hit the `Enter` key
  - Exit: hit `Ctrl-X`

- **Copy / Paste**:
  If you are using Windows and the PuTTY SSH client, you can copy text from the shell by selecting it with your mouse (no need to click anything), and paste stuff at the cursor position with a right-click anywhere in the ssh window.

  In other Terminal programs, copy/paste usually works with `Ctrl`-`Shift`-`C` and `Ctrl`-`Shift`-`V`.
  
---

{: .d-flex .flex-justify-between }
[<< Operating system](operating-system)
[Configuration >>](configuration)
