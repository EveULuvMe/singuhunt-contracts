/// Bulletin Board Extension for Smart Storage Unit
/// Integrates the SinguHunt game with an EVE Frontier SSU
/// The SSU serves as the physical in-game location where players
/// check hunt status and claim achievements.
module singuhunt::bulletin_board {
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::table::{Self, Table};
    // Game state reference (for future SSU integration)
    // use singuhunt::singuhunt::{GameState, HuntToken};

    // ============ Error Codes ============
    const E_NOT_ADMIN: u64 = 100;
    #[allow(unused_const)]
    const E_BOARD_NOT_CONFIGURED: u64 = 101;

    // ============ Extension Witness ============

    /// Witness type for SSU extension authorization
    public struct SinguHuntAuth has drop {}

    /// Bulletin board configuration - attached to an SSU via dynamic field
    public struct BulletinConfig has key {
        id: UID,
        /// The SSU object ID this bulletin is attached to
        ssu_object_id: address,
        /// Admin address
        admin: address,
        /// Message of the day
        motd: vector<u8>,
        /// Total visitors count
        total_visitors: u64,
        /// Visitor log (address -> last visit timestamp)
        visitors: Table<address, u64>,
    }

    // ============ Events ============

    public struct BulletinCreated has copy, drop {
        ssu_object_id: address,
        admin: address,
    }

    public struct BulletinUpdated has copy, drop {
        ssu_object_id: address,
        message: vector<u8>,
    }

    public struct PlayerVisited has copy, drop {
        player: address,
        ssu_object_id: address,
        timestamp: u64,
    }

    // ============ Functions ============

    /// Create a new bulletin board config
    public entry fun create_bulletin(
        ssu_object_id: address,
        ctx: &mut TxContext,
    ) {
        let config = BulletinConfig {
            id: object::new(ctx),
            ssu_object_id,
            admin: ctx.sender(),
            motd: b"Welcome to SinguHunt! Check back for the next hunt announcement.",
            total_visitors: 0,
            visitors: table::new(ctx),
        };

        event::emit(BulletinCreated {
            ssu_object_id,
            admin: ctx.sender(),
        });

        transfer::share_object(config);
    }

    /// Update the message of the day (admin only)
    public entry fun update_motd(
        config: &mut BulletinConfig,
        message: vector<u8>,
        ctx: &TxContext,
    ) {
        assert!(ctx.sender() == config.admin, E_NOT_ADMIN);
        config.motd = message;

        event::emit(BulletinUpdated {
            ssu_object_id: config.ssu_object_id,
            message,
        });
    }

    /// Register a player visit to the bulletin board
    public entry fun visit_bulletin(
        config: &mut BulletinConfig,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        let player = ctx.sender();
        let now = clock::timestamp_ms(clock);

        if (config.visitors.contains(player)) {
            let last_visit = config.visitors.borrow_mut(player);
            *last_visit = now;
        } else {
            config.visitors.add(player, now);
            config.total_visitors = config.total_visitors + 1;
        };

        event::emit(PlayerVisited {
            player,
            ssu_object_id: config.ssu_object_id,
            timestamp: now,
        });
    }

    // ============ View Functions ============

    public fun get_motd(config: &BulletinConfig): &vector<u8> {
        &config.motd
    }

    public fun get_total_visitors(config: &BulletinConfig): u64 {
        config.total_visitors
    }

    public fun get_ssu_id(config: &BulletinConfig): address {
        config.ssu_object_id
    }
}
