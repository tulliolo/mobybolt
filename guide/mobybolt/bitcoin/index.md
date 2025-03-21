---
layout: default
title: + Bitcoin
nav_order: 20
parent: MobyBolt
---

<!-- markdownlint-disable MD014 MD022 MD025 MD040 -->

# Bitcoin

The base of a sovereign Bitcoin node is a fully validating Bitcoin client.
It will download the whole blockchain and validate every single transaction that ever happened.
After this verification, the client can check the validity of all future transactions.

Your Bitcoin client also acts as a data source for other applications, like the Electrum server (to use with your software and hardware wallets), blockchain explorer or lightning client.

---

We first install Bitcoin Knots and Fulcrum on the node.
We then set up the powerful Sparrow desktop wallet on your computer and connect it to your Fulcrum server 
for secure and private base layer operations, such as sending and receiving payments from and to your hardware wallet.
Finally, we install BTC RPC Explorer on the node, a lite blockchain explorer with a clean web UI for privately checking your transactions and the mempool.
