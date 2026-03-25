<div align="center">

# Singu Hunt — Contracts

On-chain Sui Move smart contracts for [Singu Hunt](https://github.com/EveULuvMe/singuhunt-app), a location-based scavenger hunt game played inside [EVE Frontier](https://evefrontier.com)'s Utopia world.

[![Built for EVE Frontier](https://img.shields.io/badge/Built%20for-EVE%20Frontier-blueviolet?style=flat-square)](https://evefrontier.com)
[![Sui](https://img.shields.io/badge/Chain-Sui%20Testnet-blue?style=flat-square)](https://sui.io)

</div>

---

## Overview

These contracts handle:

- **Hunt session management** — start, expire, and query hunts
- **Token collection & delivery** — collect Singu tokens at gates, deliver them back
- **Achievement NFT minting** — soulbound NFTs for winners
- **On-chain anti-cheat** — Ed25519 ticket verification, replay protection, gate matching

---

## Project Structure

```
move-contracts/singuhunt/
  sources/
    singuhunt.move      # Core game logic + on-chain verification
    sig_verify.move     # Ed25519 signature verification
  Move.toml             # Package manifest
```

---

## Deploy

```bash
cd move-contracts/singuhunt
sui client publish --gas-budget 200000000
```

---

## License

MIT

---

<div align="center">

Built for the EVE Frontier community by **k66**

</div>
