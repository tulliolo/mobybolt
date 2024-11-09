---
layout: default
title: Preparations
parent: System
nav_order: 20
---

<!-- markdownlint-disable MD014 MD022 MD025 MD040 -->

# Preparations
{: .no_toc }

Let's get all the necessary hardware parts and prepare some passwords.

---

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Hardware requirements

This guide builds on the readily available personal computer. 
Although using orchestrators such as [Docker Swarm](https://docs.docker.com/engine/swarm/) or [Kubernetes](https://kubernetes.io/it/) the same principles can be applied in a multihost environment, this scenario is considered out-of-scope.

You need the following **minimal hardware**:

- **Personal Computer** with x86_64 CPU and 4+ GB RAM
- **Internal storage**: 2+ TB, an SSD is recommended
- **Pen drive**: 4+ GB
- **Temporary monitor** screen or television
- **Temporary keyboard** USB/PS2

{: .note}
If you want to start with a single storage, and then install the secondary storage later, you can follow this [bonus guide](../bonus/system/migrate-docker-data).

You should get the following **recommended hardware**:

- **Personal Computer** with x86_64 CPU and 8+ GB RAM
- **Primary internal storage for OS**: 64+ GB, an SSD is recommended
- **Secondary internal or USB3 storage for data**: 2+ TB, an SSD is recommended
- **Pen drive**: 4+ GB
- **Temporary monitor** screen or television
- **Temporary keyboard** USB/PS2

{: .important}
It is **highly recommended** to have the **secondary storage for data** ([Docker objects](docker#overview) such as images, containers, networks and volumes with all the related data - e.g. timechain, Fulcrum database, etc...). This configuration will simplify portability and restore of all the Docker services in the event of a migration to a new PC, or operating system / primary disk issues.

You might also want to get this **optional hardware**:

- **UPS** (uninterruptible power supply)
- **Temporary mouse** USB/PS2 (for the installation phase)

{: .warning}
**UPS** is totally optional, but if you intend to implement the lightning node, please consider getting it.

---

## Write down your passwords

You will need several passwords, and it's easiest to write them all down in the beginning, instead of bumping into them throughout the guide. They should be unique and very secure, at least 12 characters in length. **Do not use uncommon special characters**, spaces, or quotes (‘ or “).

```console
- [ A ] Master user password
- [ B ] Bitcoin RPC password  # optional
- [ C ] LND wallet password
- [ D ] ThunderHub password
- [ E ] Cloud backup password # optional
```

{: refdef: style="text-align: center;"}
![xkcd: Password Strength](../../images/system-preparations_xkcd.png)
{: refdef}

If you need inspiration for creating your passwords: the [xkcd: Password Strength](https://xkcd.com/936/) comic is funny and contains a lot of truth. Store a copy of your passwords somewhere safe (preferably in an open-source password manager like [KeePassXC](https://keepassxc.org/)), or whatever password manager you're already using, and keep your original notes out of sight once your system is up and running.

---

## Secure your home network and devices

While the guide will show you how to secure your node, you will interact with it from your computer and mobile phone and use your home internet network. Before building your MobyBolt, it is recommended to secure your home network and devices. Follow Parts 1 and 2 of this ["How to Secure Your Home Network Against Threats"](https://restoreprivacy.com/secure-home-network/) tutorial by Heinrich Long, and try to implement as many points as possible (some might not apply to your router/device).

---

[<< System](./){: .float-left}
[Operating system >>](operating-system){: .float-right}
