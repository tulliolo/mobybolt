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

### Connection Details

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

{: .d-flex .flex-justify-between }
[<< Operating system](operating-system)
[Configuration >>](configutation)