# Singu Hunt Contracts

Sui Move contracts for the Singu Hunt game loop.

This repository now covers more than a simple shard hunt. The current package includes:

- daily hunt configuration and execution
- registration windows and paid registration passes
- EVE-denominated registration flow
- solo race, team race, deep decrypt, large arena, and obstacle run modes
- achievement NFT minting
- shard-token minting and burn flow
- signed ticket verification for protected claim actions
- bulletin-board state for the in-world SSU entry point

## Package Layout

`move-contracts/singuhunt/sources/singuhunt.move`
Core game state, registration, hunt lifecycle, shard collection, delivery, and achievement claim logic.

`move-contracts/singuhunt/sources/achievement_token.move`
Achievement treasury and token primitives used for the permanent reward NFT.

`move-contracts/singuhunt/sources/singu_shard_token.move`
Shard treasury and token primitives used during a hunt.

`move-contracts/singuhunt/sources/sig_verify.move`
Signature verification helpers used by claim-ticket flows.

`move-contracts/singuhunt/sources/bulletin_board.move`
Bulletin-board module for the SSU / in-world announcement surface.

## Core Game Model

`GameState`
Shared game object storing epoch, active hunt timing, configured gates, registration state, fee pool, ticket signer, and cumulative counters.

`RegistrationPass`
Transferable object minted during registration purchase, later consumed by `activate_registration`.

`SinguShardRecord`
Per-player shard progress object.

`AchievementNFT`
Permanent achievement object minted to successful players.

`AdminCap`
Admin capability used for gate configuration, signer configuration, registration windows, and hunt start/expiry.

## Supported Modes

The contract defines five hunt modes:

- `1` solo race
- `2` team race
- `3` deep decrypt
- `4` large arena
- `5` obstacle run

All current registration fees are set to `1 EVE` in smallest units (`1_000_000_000`).

## Main Entry Functions

Admin flow:

- `set_start_gate`
- `set_end_gate`
- `set_pool_gate`
- `set_shard_gate`
- `set_ticket_signer`
- `set_required_singu_count`
- `open_registration`
- `withdraw_registration_fees`
- `finalize_team_registration`
- `start_hunt_with_selection`
- `start_hunt`
- `expire_hunt`

Player flow:

- `buy_registration_pass`
- `buy_registration_pass_eve<T>`
- `activate_registration`
- `collect_singu_shard`
- `deliver_singu_shard`
- `claim_achievement`
- `claim_team_achievement`
- `claim_decrypt_achievement`

Bulletin-board flow:

- `create_bulletin`
- `update_motd`
- `visit_bulletin`

## Current Registration And Hunt Flow

```text
admin opens registration
  -> player buys RegistrationPass
  -> player activates registration
  -> admin finalizes team registration if needed
  -> admin starts hunt
  -> players collect and deliver shards
  -> players claim mode-specific achievement
```

## Current Economic Notes

- `buy_registration_pass_eve<T>` enforces the configured EVE coin type and forwards the fee directly to `REGISTRATION_FEE_RECEIVER`.
- The older `buy_registration_pass` path still exists in Move and consumes `Coin<LUX>`.
- `total_lux_collected` and related legacy field names are still present in code as identifiers, even though the current product registration flow is EVE-facing.

## Integration Notes

- This package depends on the local `singuvault` package.
- `singuhunt.move` imports `singuvault::lux::LUX`, so package renaming on the vault side must stay coordinated with this repository.
- The achievement image URL is currently hardcoded to `https://dapp-seven-henna.vercel.app/NFT.png`.
- Claim protection relies on signed tickets plus replay protection tables.

## Build And Publish

```bash
cd move-contracts/singuhunt
sui move build
sui client publish --gas-budget 200000000
```

`Move.toml` currently points to:

- Sui framework `testnet-v1.66.2`
- local dependency `../../../singuvault-contracts/move-contracts/singuvault`

## License

MIT
