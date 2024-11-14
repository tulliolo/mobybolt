---
title: Home
layout: home
nav_order: 1
---

{: .logo }
![MobyBolt Logo](images/mobybolt-logo.png)

Build your own "do-everything-yourself" Bitcoin full node that will make you a sovereign peer in the Bitcoin and Lightning network.
{: .fs-6 }

No need to trust anyone else.
{: .fs-6 }

---

## What is MobyBolt?

With this guide, you can set up a Dockerized Bitcoin and Lightning node on a personal computer from scratch, doing everything yourself.
You will learn about Linux, Docker, Bitcoin, and Lightning.
As a result, you'll have your very own MobyBolt node, built by you and no one else.

There are many reasons why you should run your own Bitcoin node.

- **Keep Bitcoin decentralized.** Use your node to help enforce your Bitcoin consensus rules.
- **Take back your sovereignty.** Let your node validate your own Bitcoin transactions. No need to ask someone else to tell you what's happening in the Bitcoin network.
- **Improve your privacy.** Connect your wallets to your node so that you no longer need to reveal their whole financial history to external servers.
- **Be part of Lightning.** Run your own Lightning node for everyday payments and help building a robust, decentralized Bitcoin Lightning network.

Did we mention that it's fun, as well?

---

## Why Docker?

A Bitcoin and Lightning node is a complex ecosystem of applications, mainly interconnected with each other, each with its own requirements and dependencies.
Managing and updating all these applications is certainly a delicate process.

[Docker](https://docs.docker.com/get-started/overview/){: target="_blank"} (or containerization in general) comes in handy because it allows you to isolate each of these applications (along with its dependencies and everything else you need to run it), making troubleshooting, upgrading and rollback much easier.

Applications will run in **containers** isolated from each other, as if they were on different hosts, which is also good in terms of security. 

In addition, Docker makes it much easier to migrate applications from one machine to another.

---

## MobyBolt overview

This guide explains how to set up your own Bitcoin node on personal computer. However, it works on most hardware platforms because it only uses standard Debian Linux commands.

### Features

Your Bitcoin node will offer the following functionality:

- **Bitcoin**: direct and trustless participation in the Bitcoin peer-to-peer network, full validation of blocks and transactions
- **Electrum server**: connect your compatible wallets (including hardware wallets) to your own node
- **Blockchain Explorer**: web-based Explorer to privately look up transactions, blocks, and more
- **Lightning**: full client with stable long-term channels and web-based and mobile-based management interfaces
- **Always on**: services are constantly synced and available 24/7
- **Reachable from anywhere**: connect to all your services through the Tor network

### Target audience

We strive to give foolproof instructions.
But the goal is also to do everything ourselves.
Shortcuts that involve trusting someone else are not allowed.
This makes this guide quite technical, but we try to make it as straightforward as possible.
You'll gain a basic understanding of the how and why.

If you like to learn about Linux, Docker, Bitcoin, and Lightning, then this guide is for you.

### Structure

We aim to keep the core of this guide well maintained and up-to-date:

1. [System](guide/system): prepare the hardware and set up the operating system with docker
1. [Mobybolt](guide/mobybolt): an overwiew of the MobyBolt stack
   1. [Setup](guide/mobybolt/setup): prepare the stack and install the base services
   1. [Bitcoin](guide/mobybolt/bitcoin): sync your own Bitcoin full node, Electrum server, and Blockchain Explorer
   1. [Lightning](guide/mobybolt/lightning): run your own Lightning client with web-based node management

The bonus section contains more specific guides that build on top of the main section.
More fun, lots of knowledge, but with lesser maintenance guarantees.
Everything is optional.

- [Bonus guides](guide/bonus)

---

## Community

- [Issues / Knowledge Base](https://github.com/tulliolo/mobybolt/issues/){: target="_blank"}
- [Contribute / Source Code](https://github.com/tulliolo/mobybolt/){: target="_blank"}

---

{: .d-flex .flex-justify-end }
[Get Started >>](guide/system/preparations)
