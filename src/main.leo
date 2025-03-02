import credits.aleo;
import token_registry.aleo;

program sushant_zk_prediction_market.aleo {
    // Structs
    struct PredictionStake {
        account: address,
        token_id: field,
        event_id: field,      // Unique identifier for the prediction event
    }

    struct Event {
        outcome: bool,        // Final outcome (true = yes, false = no)
        resolved: bool,       // Whether the event is resolved
        total_yes_stake: u64, // Total stake on "yes"
        total_no_stake: u64,  // Total stake on "no"
    }

    // Mappings
    mapping admin: bool => address;               // Admin address
    mapping status: bool => u8;                   // Contract status (paused/unpaused)
    mapping stake_limit: bool => u64;             // Maximum stake per bet
    mapping user_stake: field => u64;             // User’s stake per event
    mapping stake_time: field => u32;             // Block height when stake was placed
    mapping events: field => Event;               // Event details by event_id
    mapping decay_factor: bool => u32;            // Decay factor for stake weight (e.g., 100 blocks)

    // Constants
    const UNPAUSED_STATUS: u8 = 1u8;
    const PAUSED_STATUS: u8 = 0u8;
    const NATIVE_TOKEN: field = 11111111111111111111field;
    const DECAY_INTERVAL: u32 = 100u32;           // Stake decays every 100 blocks

    // Initialize the contract
    async transition initialize(owner: address, limit: u64) -> Future {
        assert(limit > 0u64);
        return finalize_initialize(owner, limit);
    }

    async function finalize_initialize(owner: address, limit: u64) {
        assert(!admin.contains(true));
        admin.set(true, owner);
        stake_limit.set(true, limit);
        status.set(true, PAUSED_STATUS);
        decay_factor.set(true, DECAY_INTERVAL);
    }

    // Stake on a prediction event (public with native credits)
    async transition stake_public(event_id: field, amount: u64, prediction: bool) -> Future {
        assert(amount > 0u64);
        let transfer_output: Future = credits.aleo/transfer_public_as_signer(self.address, amount);
        return finalize_stake_public(self.caller, event_id, amount, prediction, NATIVE_TOKEN, transfer_output);
    }

    async function finalize_stake_public(user: address, event_id: field, amount: u64, prediction: bool, token_id: field, f: Future) {
        f.await();
        assert_eq(status.get(true), UNPAUSED_STATUS);
        assert(amount <= stake_limit.get(true));

        let stake_record: PredictionStake = PredictionStake {
            account: user,
            token_id: token_id,
            event_id: event_id
        };
        let stake_key: field = BHP256::hash_to_field(stake_record);
        
        // Ensure event isn’t resolved yet
        let event: Event = events.get_or_use(event_id, Event { outcome: false, resolved: false, total_yes_stake: 0u64, total_no_stake: 0u64 });
        assert(!event.resolved);

        // Update user stake and time
        let current_stake: u64 = user_stake.get_or_use(stake_key, 0u64);
        user_stake.set(stake_key, current_stake + amount);
        stake_time.set(stake_key, block.height);

        // Update event totals
        let new_yes_stake: u64 = prediction ? event.total_yes_stake + amount : event.total_yes_stake;
        let new_no_stake: u64 = prediction ? event.total_no_stake : event.total_no_stake + amount;
        events.set(event_id, Event {
            outcome: event.outcome,
            resolved: event.resolved,
            total_yes_stake: new_yes_stake,
            total_no_stake: new_no_stake
        });
    }

    // Resolve an event (admin only)
    async transition resolve_event(event_id: field, outcome: bool) -> Future {
        return finalize_resolve_event(self.caller, event_id, outcome);
    }

    async function finalize_resolve_event(from: address, event_id: field, outcome: bool) {
        let owner: address = admin.get(true);
        assert_eq(from, owner);
        assert_eq(status.get(true), UNPAUSED_STATUS);

        let event: Event = events.get_or_use(event_id, Event { outcome: false, resolved: false, total_yes_stake: 0u64, total_no_stake: 0u64 });
        assert(!event.resolved); // Ensure not already resolved
        events.set(event_id, Event {
            outcome: outcome,
            resolved: true,
            total_yes_stake: event.total_yes_stake,
            total_no_stake: event.total_no_stake
        });
    }

    // Claim winnings (public with native credits)
    async transition claim_public(event_id: field, amount: u64) -> Future {
        assert(amount > 0u64);
        let transfer_output: Future = credits.aleo/transfer_public(self.caller, amount);
        return finalize_claim_public(self.caller, event_id, amount, NATIVE_TOKEN, transfer_output);
    }

    async function finalize_claim_public(user: address, event_id: field, amount: u64, token_id: field, f: Future) {
        f.await();
        assert_eq(status.get(true), UNPAUSED_STATUS);

        let event: Event = events.get(event_id);
        assert(event.resolved);

        let stake_record: PredictionStake = PredictionStake {
            account: user,
            token_id: token_id,
            event_id: event_id
        };
        let stake_key: field = BHP256::hash_to_field(stake_record);
        let user_stake_amount: u64 = user_stake.get_or_use(stake_key, 0u64);
        assert(user_stake_amount > 0u64);

        // Calculate decayed stake weight
        let stake_block: u32 = stake_time.get_or_use(stake_key, 0u32);
        let blocks_elapsed: u32 = block.height - stake_block;
        let decay_periods: u32 = blocks_elapsed / DECAY_INTERVAL;
        let decayed_stake: u64 = user_stake_amount >> decay_periods; // Right shift to simulate decay

        // Calculate payout based on weighted stake
        let total_winning_stake: u64 = event.outcome ? event.total_yes_stake : event.total_no_stake;
        let total_losing_stake: u64 = event.outcome ? event.total_no_stake : event.total_yes_stake;
        let predicted_yes: bool = decayed_stake <= event.total_yes_stake;
        assert(predicted_yes == event.outcome); // Ensure user bet on winning outcome
        let payout: u64 = decayed_stake * (total_losing_stake + total_winning_stake) / total_winning_stake;
        assert(amount <= payout);

        // Update balance
        user_stake.set(stake_key, user_stake_amount - decayed_stake);
    }

    // Admin controls
    async transition unpause() -> Future {
        return finalize_unpause(self.caller);
    }

    async function finalize_unpause(from: address) {
        let owner: address = admin.get(true);
        assert_eq(from, owner);
        status.set(true, UNPAUSED_STATUS);
    }

    async transition pause() -> Future {
        return finalize_pause(self.caller);
    }

    async function finalize_pause(from: address) {
        let owner: address = admin.get(true);
        assert_eq(from, owner);
        status.set(true, PAUSED_STATUS);
    }

    async transition change_limit(new_limit: u64) -> Future {
        return finalize_change_limit(self.caller, new_limit);
    }

    async function finalize_change_limit(from: address, new_limit: u64) {
        let owner: address = admin.get(true);
        assert_eq(from, owner);
        assert(new_limit > 0u64);
        stake_limit.set(true, new_limit);
    }

    async transition withdraw(amount: u64) -> Future {
        let transfer_output: Future = credits.aleo/transfer_public(self.caller, amount);
        return finalize_withdraw(amount, self.caller, transfer_output);
    }

    async function finalize_withdraw(amount: u64, from: address, f: Future) {
        f.await();
        let owner: address = admin.get(true);
        assert_eq(from, owner);
    }
}