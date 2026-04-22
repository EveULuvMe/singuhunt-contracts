/// Singu Guardian Turret — protects SinguHunt assemblies.
///
/// Targeting rules:
///   1. If the current hunt is active AND the target's character is a registered
///      player for this epoch → skip (whitelisted).
///   2. Everyone else → attack (priority weight based on aggressor status).
///
/// Deploy one turret next to each Mini Gate, SSU, and Heavy Gate.
/// Then call `authorize_extension<SinguTurretAuth>` on each turret.
module singu_turret::singu_turret;

use sui::{bcs, clock::Clock, event};
use world::{character::Character, turret::{Self, Turret, OnlineReceipt}};
use singuhunt::singuhunt::{Self, GameState};

// ── Errors ──────────────────────────────────────────────────────────────

#[error(code = 0)]
const EInvalidOnlineReceipt: vector<u8> = b"Invalid online receipt";

// ── Witness ─────────────────────────────────────────────────────────────

public struct SinguTurretAuth has drop {}

// ── Events ──────────────────────────────────────────────────────────────

public struct GuardianTargetEvent has copy, drop {
    turret_id: ID,
    targets_evaluated: u64,
    targets_whitelisted: u64,
    targets_engaged: u64,
}

// ── Constants ───────────────────────────────────────────────────────────

const WEIGHT_BASE: u64 = 10000;
const WEIGHT_AGGRESSOR_BONUS: u64 = 5000;

// ── Core targeting function ─────────────────────────────────────────────

/// Called by the EVE Frontier game engine whenever target behaviour changes
/// near this turret.
///
/// Reads SinguHunt GameState to determine:
///   - Is a hunt currently active?
///   - Is the target's EVE character a registered player for this epoch?
///
/// Registered players during an active hunt are whitelisted (not attacked).
/// Everyone else gets added to the priority list with attack weight.
public fun get_target_priority_list(
    turret: &Turret,
    _owner_character: &Character,
    target_candidate_list: vector<u8>,
    receipt: OnlineReceipt,
    game_state: &GameState,
    clock: &Clock,
): vector<u8> {
    assert!(receipt.turret_id() == object::id(turret), EInvalidOnlineReceipt);

    let candidates = turret::unpack_candidate_list(target_candidate_list);
    let mut return_list = vector::empty<turret::ReturnTargetPriorityList>();

    // Read hunt state
    let (epoch, _start_time, end_time, hunt_active) = singuhunt::get_hunt_info(game_state);
    let now = clock.timestamp_ms();
    let hunt_live = hunt_active && now <= end_time;
    let hunt_mode = singuhunt::get_hunt_mode(game_state);

    let total = candidates.length();
    let mut whitelisted: u64 = 0;
    let mut engaged: u64 = 0;

    let mut i: u64 = 0;
    while (i < total) {
        let candidate = &candidates[i];
        let character_id = candidate.character_id();

        let is_registered = if (hunt_live) {
            singuhunt::is_character_registered(game_state, epoch, character_id)
        } else {
            false
        };

        // Mode 5 (Obstacle Run): registered players are BLACKLISTED (attacked)
        // Mode 1-4: registered players are WHITELISTED (not attacked)
        // Unregistered players: always attacked
        let should_attack = if (hunt_mode == 5 && is_registered) {
            true   // Obstacle Run: attack registered players
        } else if (is_registered) {
            false  // Other modes: whitelist registered players
        } else {
            true   // Unregistered: always attack
        };

        if (!should_attack) {
            whitelisted = whitelisted + 1;
        } else {
            let weight = if (candidate.is_aggressor()) {
                WEIGHT_BASE + WEIGHT_AGGRESSOR_BONUS
            } else {
                WEIGHT_BASE
            };
            return_list.push_back(
                turret::new_return_target_priority_list(candidate.item_id(), weight)
            );
            engaged = engaged + 1;
        };

        i = i + 1;
    };

    let result = bcs::to_bytes(&return_list);

    turret::destroy_online_receipt(receipt, SinguTurretAuth {});

    event::emit(GuardianTargetEvent {
        turret_id: object::id(turret),
        targets_evaluated: total,
        targets_whitelisted: whitelisted,
        targets_engaged: engaged,
    });

    result
}
