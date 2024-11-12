---
layout: default
title: Reverse proxy (nginx)
nav_order: 20
parent: + Setup
grand_parent: MobyBolt
---
<!-- markdownlint-disable MD014 MD022 MD025 MD033 MD040 -->

# Reverse proxy (nginx)
{: .no_toc}

{: .text-center}
![nginx logo](../../../images/mobybolt-setup-reverse-proxy_logo.png){: width="20%"}

Several components of this guide will expose a communication port, for example, the Block Explorer, or the ThunderHub web interface for your Lightning node. Even if you use these services only within your own home network, communication should always be encrypted. Otherwise, any device in the same network can listen to the exchanged data, including passwords.

We use nginx to encrypt the communication with SSL/TLS (Transport Layer Security). This setup is called a "reverse proxy": nginx provides secure communication to the outside and routes the traffic back to the internal service without encryption.

{: .note}
Even if some services, such as Fulcrum, natively support encrypted communication, for simplicity and architectural cleanliness, we will still use nginx as a single point of access to all services.

To follow this section, log in to your node as `admin` user via Secure Shell (SSH) and access the project's home:

```sh
$ cd apps/mobybolt
```


---

## Table of contents
{: .no_toc .text-delta}

1. TOC
{:toc}

---

{: .d-flex .flex-justify-between}
[<< Project setup](project-setup)
[Tor project >>](tor-project)