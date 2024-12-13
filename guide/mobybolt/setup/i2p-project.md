---
layout: default
title: I2P project
nav_order: 40
parent: + Setup
grand_parent: MobyBolt
---
<!-- markdownlint-disable MD014 MD022 MD025 MD033 MD040 -->

# I2P project
{:.no_toc}

{:.text-center}
![i2p logo](../../../images/mobybolt-setup-i2p-project_logo.png){:width="25%"}

[I2P](https://geti2p.net/en/){:target="_blank"} is a universal anonymous network layer. All communications over I2P are anonymous and end-to-end encrypted, participants don't reveal their real IP addresses. I2P allows people from all around the world to communicate and share information without restrictions.

I2P client is software used for building and using anonymous I2P networks. Such networks are commonly used for anonymous peer-to-peer applications (filesharing, cryptocurrencies) and anonymous client-server applications (websites, instant messengers, chat-servers).

We are to use [i2pd](https://i2pd.readthedocs.io/en/latest/){:target="_blank"} (I2P Daemon), a full-featured C++ implementation of the I2P client, as a Tor network complement. We'll use the [official docker image](https://hub.docker.com/r/purplei2p/i2pd){:target="_blank"} for the installation.

---

To follow this section, log in to your node as `satoshi` user via Secure Shell (SSH) and access the project's home:

```sh
$ cd $HOME/apps/mobybolt
```

---

## Table of contents
{:.no_toc .text-delta}

1. TOC
{:toc}

---