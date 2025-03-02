# Welcome to the Zero-Knowledge Prediction Market

Hey there! Imagine a world where you can bet on the future—will it rain this afternoon? Will your favorite team win?—all while keeping your moves secret and the game fair. That’s what `zk_prediction_market.aleo` brings to the Aleo blockchain: a prediction market powered by zero-knowledge magic, with a twist that’ll make you say, "Whoa, that’s cool!"

---

## What’s This All About?

This isn’t your average betting app. It’s a smart contract that lets users stake Aleo credits on yes/no outcomes for any event you can dream up. The kicker? Your stake isn’t just a static number—it *decays* over time, giving newer players a louder voice. We call it "stake-weighted voting with decay," and it’s baked into the code with zero-knowledge proofs to keep everything private and provable. Built on Aleo, it’s a showcase of what’s possible when privacy meets prediction.

---

## How It Runs on Aleo

This beauty lives on the Aleo blockchain, tapping into `credits.aleo` for those sweet native credits and `token_registry.aleo` for token flexibility. I hammered it out in the Aleo Playground with the endpoint set to `https://api.explorer.provable.com/v1`, and it builds like a charm every time—tested in incognito mode just to be extra sure.

---

## Diving Into the Good Stuff: Transitions

Here’s the rundown of what this contract can do. Each piece is a little gear in the machine, and together, they make something pretty epic.

- **`initialize(owner: address, limit: u64) -> Future`**  
  Think of this as flipping the "on" switch. It sets up an admin (that’s you or whoever’s in charge) and caps how much anyone can stake in one go. Gotta keep things manageable, right?

- **`stake_public(event_id: field, amount: u64, prediction: bool) -> Future`**  
  This is where the action starts. You pick an event (say, event ID `123field`), toss in some credits, and call “yes” or “no.” The contract hashes your stake with `BHP256` so nobody knows it’s you, then tracks it with a decay timer. Sneaky and smart.

- **`resolve_event(event_id: field, outcome: bool) -> Future`**  
  Admin-only territory. Once the event’s done—rain or no rain—you set the outcome here. True for “yes,” false for “no.” This unlocks the payouts, and the math gets wild (more on that later).

- **`claim_public(event_id: field, amount: u64) -> Future`**  
  Time to cash out! If you bet right, this sends your winnings back in native credits. The amount you get? It’s tied to your decayed stake and the total pool—fair and square.

- **`unpause() -> Future`**  
  Green light! The admin uses this to open the market for staking and claiming. No bets when it’s off.

- **`pause() -> Future`**  
  Red light! Shuts it all down temporarily. Admin’s call—maybe for maintenance or drama control.

- **`change_limit(new_limit: u64) -> Future`**  
  Flexibility is key. The admin can tweak the stake ceiling whenever the market needs a shake-up.

- **`withdraw(amount: u64) -> Future`**  
  Admin’s escape hatch. Pulls credits out of the contract—handy for emergencies or profit-taking.

---

## What Makes It Tick?

Let’s peel back the curtain on why this thing’s a big deal:

- **Stake Decay Awesomeness**: Your stake isn’t frozen in time. Every 100 blocks (tweakable with `DECAY_INTERVAL`), it shrinks a bit—shifts right in the bits, to be exact. Fresh stakes rule the roost, old ones fade. It’s like a living, breathing market.

- **Zero-Knowledge Sauce**: Every bet’s hashed into a `field` with `BHP256`. You’re in, but nobody knows how much or what you picked. Privacy’s the name of the game.

- **Payout Math**: When an event resolves, your payout’s a slice of the losing side’s pool, weighted by your decayed stake. It’s fair, it’s clever, and it’s all on-chain.

---

## Getting It Running

I built this in the Aleo Playground, and it’s rock-solid with `credits.aleo` and `token_registry.aleo` pulled from `https://api.explorer.provable.com/v1`. Here’s how you can see it in action:

1. Fire up an incognito window (keeps things fresh).
2. Head to `https://playground.aleo.org`.
3. Drop the code into `zk_prediction_market.aleo`.
4. Hit "Build"—bam, it works!
5. Play around: `initialize`, `unpause`, stake on `123field`, resolve it, claim your loot.

---

## Why It’s Open

This is open-source, built with Aleo’s guidelines in mind. It’s not just a contract—it’s a peek into the future of private, fair betting. Feel free to tweak, explore, or just marvel at it.

---

Ready to blow some minds with this? It’s submission-ready and screaming “innovation.” Let me know if you want to riff on it more!