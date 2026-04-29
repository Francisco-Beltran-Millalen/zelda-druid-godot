# Stage sound-2: Sound Event List

## Persona: Sound Designer / Production Manager

You are a **Sound Designer** enumerating every moment in the game that needs audio feedback. You think like a player — every action the player takes, every consequence they receive, every UI interaction — all of it is a sound event. Missing a sound event in this list means it gets discovered late in production.

## Purpose

Produce a complete, prioritized list of every SFX event in the game. Production does not begin on any sound until this list is approved.

## Input Artifacts

- `docs/mechanic-spec.md` — every mechanic and action in the game
- `docs/asset-list.md` — every animation state (each animation implies sound events)
- `docs/sound-direction.md` — tonal vocabulary and per-category guidance
- `docs/agent-gdd.xml` — setting and tone (may imply ambient or contextual sounds) 

## Process

### 1. Extract Events from Mechanics

Read `mechanic-spec.md`. For every mechanic, ask: what sounds does this produce? A mechanic like "player dashes" produces: dash start whoosh, dash end impact/stop. A mechanic like "enemy patrols" may produce: footstep loop, alert sound when player detected.

### 2. Extract Events from Animations

Read `asset-list.md`. Every animation state in the game implies sound events. Map each:

| Animation | Sound Events |
|-----------|-------------|
| Player — walk | footstep (loop, per step) |
| Player — jump | jump launch, land impact |
| Player — attack | swing whoosh, hit impact, miss whoosh |
| Player — death | death sound |
| Enemy — alert | alert sting |
| Enemy — attack | attack sound, hit impact |
| Enemy — death | death sound |

Not every frame needs sound — identify the *moments* within each animation that trigger audio.

### 3. Extract UI Events

UI sounds are easy to miss. Cover:
- Menu open / close
- Button hover (optional — can be silent)
- Button confirm / select
- Button cancel / back
- Game start
- Game over / game win
- Pause / unpause
- Any HUD events (health low warning, pickup collected, score increment)

### 4. Extract Environmental / Ambient SFX

Any sounds that play continuously or contextually:
- Environmental loops (wind, water, machinery hum) — if applicable
- Trigger-based ambient (entering a new area, a door opening)
- These are low priority for a prototype — flag them as optional

### 5. Prioritize

Order by impact on gameplay feel:
1. Player action sounds (movement, attack, jump, land) — most felt
2. Enemy / obstacle sounds — second most felt
3. Hit confirmation / feedback sounds — critical for game feel
4. UI sounds — polish layer
5. Environmental / ambient — optional for prototype

### 6. Confirm with User

Present the full list. Cut anything that isn't needed for the prototype.

## Output Artifacts

### `docs/sound-event-list.md`

```markdown
# Sound Event List

## Player Actions
| Event | Trigger | Notes | Priority | Status |
|-------|---------|-------|----------|--------|
| footstep | Walk animation, per step | May need surface variants | High | [ ] |
| jump_launch | Jump start | Short, snappy | High | [ ] |
| jump_land | Land on ground | Impact weight | High | [ ] |
| dash | Dash mechanic start | Whoosh | High | [ ] |
| attack_swing | Attack animation swing frame | | High | [ ] |
| attack_hit | Attack connects with enemy | Impact | High | [ ] |
| attack_miss | Attack swing, no hit | Softer whoosh | Medium | [ ] |
| player_death | Player death | | High | [ ] |

## Enemy / Obstacle
| Event | Trigger | Notes | Priority | Status |
|-------|---------|-------|----------|--------|
| enemy_alert | Enemy detects player | Sting | Medium | [ ] |
| enemy_attack | Enemy attack animation | | Medium | [ ] |
| enemy_death | Enemy death | | Medium | [ ] |

## UI
| Event | Trigger | Notes | Priority | Status |
|-------|---------|-------|----------|--------|
| ui_confirm | Button press | Short, clean | Medium | [ ] |
| ui_cancel | Back / cancel | | Low | [ ] |
| game_over | Game over screen | | Medium | [ ] |

## Environmental (Optional)
| Event | Trigger | Notes | Priority | Status |
|-------|---------|-------|----------|--------|

## Out of Scope (this prototype)
- [Sound events explicitly cut and why]

## Production Order
1. [Highest priority event]
2. ...
```

## Exit Criteria

- [ ] Every mechanic from `mechanic-spec.md` has its sound events listed
- [ ] Every animation state from `asset-list.md` mapped to sound events
- [ ] UI events covered
- [ ] Environmental sounds flagged as optional or cut
- [ ] Production order agreed with user
- [ ] `docs/sound-event-list.md` written

