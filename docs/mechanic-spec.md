# Mechanic Spec

## Mechanics

### 1. Ground Movement, Climbing & Stamina
**Description:** Basic BotW-style traversal (walk, sprint, sneak, jump, fall, land) plus climbing and mantling. Sprinting and climbing drain stamina.
**Feel Contract:** Moving feels immediate—no input lag. Stopping feels deliberate, not floaty. Landing from high jumps has weight (camera dip, audio impact).
**Owner System:** Movement (`EntityController` + `MovementBroker` + `BaseMotor` subclasses)
**Analysis Status:** [x] Done
**Implementation Status:** [ ] Not started

### 2. Camera Controller
**Description:** Third-person camera that follows the player, with states for aiming (over-the-shoulder) and lock-on (framing player and target).
**Feel Contract:** The camera feels like a physical observer. It smooths out jitter, snaps quickly when aiming, and frames combat dynamically without giving motion sickness.
**Owner System:** Camera (`CameraRig` + `CameraBroker` + `CameraMode` subclasses)
**Analysis Status:** [x] Done
**Implementation Status:** [ ] Not started

### 3. Form Shapeshifting
**Description:** Instant snap between Panther, Monkey, and Avian forms, preserving momentum.
**Feel Contract:** The shift must feel explosive and instantaneous—zero animation delay. It should feel like a fluid extension of movement, not a menu swap.
**Owner System:** Form (`FormBroker` + `FormComponent`)
**Analysis Status:** [ ] Not started
**Implementation Status:** [ ] Not started

### 4. Monkey Rhythm Parry & Counter
**Description:** Rhythmic combat counter. Player reads enemy telegraph and hits the parry window (±100ms tolerance).
**Feel Contract:** Extremely satisfying, heavy feedback. Hitting a counter triggers extreme hitpause, making the player feel like a timing master.
**Owner System:** Combat (`CombatBroker` + `ParryAction` / `CounterAction`)
**Analysis Status:** [ ] Not started
**Implementation Status:** [ ] Not started

### 5. Panther Stealth Takedown
**Description:** Silent approach into a magnetic takedown when undetected.
**Feel Contract:** Predatory and fluid. Takedowns should snap magnetically if in range, rewarding patient approach over frantic button mashing.
**Owner System:** Combat (`CombatBroker` + `TakedownAction`)
**Analysis Status:** [ ] Not started
**Implementation Status:** [ ] Not started

### 6. Avian Ranged Bow
**Description:** Drawing and releasing a projectile weapon from an over-the-shoulder aim mode.
**Feel Contract:** Drawing feels tense and heavy. Releasing has sharp recoil and satisfying contact audio on hit.
**Owner System:** Combat (`CombatBroker` + `BowAction`)
**Analysis Status:** [ ] Not started
**Implementation Status:** [ ] Not started

### 7. Climbing & Wall Jump
**Description:** Grabbing surfaces to climb or leaping off them, heavily gated by stamina.
**Feel Contract:** Effort is visible. Climbing should feel rhythmic and deliberate, not like sliding up a frictionless wall.
**Owner System:** Movement (`ClimbMotor`, `WallJumpMotor`)
**Analysis Status:** [x] Merged into Mechanic 1
**Implementation Status:** [x] Merged into Mechanic 1

### 8. Gliding
**Description:** Deployable mid-air glide state.
**Feel Contract:** Smooth, swooping, and momentum-preserving.
**Owner System:** Movement (`GlideMotor`)
**Analysis Status:** [ ] Not started
**Implementation Status:** [ ] Not started

### 9. Swimming
**Description:** Water traversal with stamina constraints.
**Feel Contract:** Buoyant but resistant. Movement is noticeably heavier than ground movement.
**Owner System:** Movement (`SwimMotor`)
**Analysis Status:** [ ] Not started
**Implementation Status:** [ ] Not started

---

## Out of Scope (TO BE IMPLEMENTED)

The following mechanics from the GDD are intentionally deferred from the MVP and will be architected in future clusters:
- Use-to-Improve Progression Backend
- Ritual Rhythm Timing & Cascade System
- Zone State Machine (Dead → Restoring → Alive)
- Wave Defense Manager
- Ecosystem Resource Management
- Enemy AI / Behavior (beyond basic target dummies for combat testing)
