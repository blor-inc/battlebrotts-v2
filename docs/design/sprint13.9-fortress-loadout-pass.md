# Sprint 13.9 — S14 Fortress Loadout Pass (Opponent Loadout Templates)

**Status:** Design spec, pre-implementation
**Author:** Gizmo
**Depends on:** S13.3 (chassis balance + TCR), S13.4–13.8 (shop/shell UX — no code coupling)
**Defers from:** S13.3 "Fortress loadout tuning" deferred item

---

## 🚨 TERMINOLOGY ALERT (read first, Ett)

The task brief uses **"Fortress"** to mean **"the AI-brott opponent"** (generic enemy).
In this codebase, **Fortress is a CHASSIS TYPE** (heavy tank, `ChassisData.ChassisType.FORTRESS`).

To avoid confusion, this spec uses:
- **Opponent** — the AI-controlled enemy brott (what the brief calls "Fortress")
- **Fortress (chassis)** — the heavy tank chassis, one of three options
- **Archetype** — a loadout personality (Tank / Glass Cannon / Skirmisher / Brawler-bully / etc.)

File naming follows suit: **`opponent_loadouts.gd`**, not `fortress_loadouts.gd`.
If Ett prefers to keep the brief's naming, overrule this — but expect reader whiplash.

---

## §1 Scope

### In scope
- 4–6 named **opponent loadout templates** in `godot/data/opponent_loadouts.gd`
- Template picker: `pick_opponent_loadout(difficulty, last_archetype) -> Dictionary`
- **Variety guarantee**: no back-to-back same archetype
- **Difficulty scaling**: templates tiered by power level; picker filters by tier
- Integration into `OpponentData.build_opponent_brott()` (replaces hardcoded scrapyard entries, OR augments for future leagues — see §5)
- `test_sprint13_9.gd` with ≥12 tests
- GDD update: `docs/gdd.md §4` (opponents/progression) — document archetype taxonomy

### DO NOT EXCEED
- ❌ No new weapons / armor / modules / chassis (reuse existing enums only)
- ❌ No audio (parked, per standing rule)
- ❌ No visual distinctions beyond the `name` field in `BrottState.bot_name`
- ❌ No rarity tables / loot / cross-run progression
- ❌ No changes to `BrottBrain` logic, TCR timings, or combat core
- ❌ No new leagues (Bronze etc. stay empty; spec leaves hooks only)
- ❌ **Budget: ≤300 LoC total across `opponent_loadouts.gd` + integration diffs + tests**
- ❌ If counter-play + variety + difficulty together blow budget → **drop counter-play**

---

## §2 Current Opponent Build Path (verified)

**File:** `godot/game/opponent_data.gd` (single source of truth, ~60 LoC)

**Flow:**
1. `GameState.current_league` holds league string (currently only `"scrapyard"`; `bronze_unlocked` flag exists but bronze league is empty)
2. `OpponentData.get_league_opponents(league)` returns a **hardcoded `Array[Dictionary]`** of 3 entries for scrapyard:
   - `scrapyard_0` "Rusty" — Scout + Plasma Cutter, no armor, aggressive
   - `scrapyard_1` "Tincan" — Scout + Plasma Cutter + Plating, defensive
   - `scrapyard_2` "Crusher" — Brawler + Plasma Cutter + Shotgun, no armor, kiting
3. `OpponentData.build_opponent_brott(league, index)` reads a dict → constructs `BrottState` → assigns `BrottBrain.default_for_chassis()` if no custom brain

**Key facts:**
- There is **NO "fortress_ai.gd"**, **NO `enemy_builder.gd`**, **NO random picker**. Loadouts are fully static.
- Difficulty signal: **index within league** (0, 1, 2). No `run_depth`, no explicit difficulty tier. We'll use `(league, index)` → tier mapping (§4).
- Archetype tagging on chassis: **not present**. Chassis data (`chassis_data.gd`) has stats + TCR timings but no `archetype` field. Archetypes are implicit from stat shape. We introduce archetype as a **template-level concept**, not a chassis-level one.
- `BrottBrain` has `default_for_chassis()` — opponents inherit per-chassis AI. No custom brains wired in scrapyard data.
- Enum inventory (for templates):
  - **Chassis**: SCOUT, BRAWLER, FORTRESS
  - **Weapons**: MINIGUN, RAILGUN, SHOTGUN, MISSILE_POD, PLASMA_CUTTER, ARC_EMITTER, FLAK_CANNON
  - **Armor**: NONE, PLATING, REACTIVE_MESH, ABLATIVE_SHELL
  - **Modules**: OVERCLOCK, REPAIR_NANITES, SHIELD_PROJECTOR, SENSOR_ARRAY, AFTERBURNER, EMP_CHARGE
  - **Stance**: 0 (Aggressive) / 1 (Defensive) / 2 (Kiting)

---

## §3 Loadout Template Schema + Starter Templates

### 3.1 Schema

```gdscript
# opponent_loadouts.gd
class_name OpponentLoadouts
extends RefCounted

enum Archetype { TANK, GLASS_CANNON, SKIRMISHER, BRUISER, CONTROLLER }

# Each template is a Dictionary with:
#   "id":        String (stable key)
#   "name":      String (display; stored in BrottState.bot_name)
#   "archetype": Archetype enum
#   "tier":      int  (1=weakest, 2=mid, 3=strongest)
#   "chassis":   ChassisData.ChassisType
#   "weapons":   Array[WeaponData.WeaponType]  (respect chassis weapon_slots)
#   "armor":     ArmorData.ArmorType
#   "modules":   Array[ModuleData.ModuleType]  (respect chassis module_slots)
#   "stance":    int  (0/1/2)
```

### 3.2 Starter templates (5, one per archetype)

| id | name | archetype | tier | chassis | weapons | armor | modules | stance |
|---|---|---|---|---|---|---|---|---|
| `tank_ironclad` | "Ironclad" | TANK | 2 | FORTRESS | [SHOTGUN, FLAK_CANNON] | ABLATIVE_SHELL | [REPAIR_NANITES] | 1 (Def) |
| `glass_sniper` | "Pinprick" | GLASS_CANNON | 2 | SCOUT | [RAILGUN, PLASMA_CUTTER] | NONE | [OVERCLOCK, SENSOR_ARRAY, AFTERBURNER] | 2 (Kite) |
| `skirmish_wasp` | "Wasp" | SKIRMISHER | 1 | SCOUT | [FLAK_CANNON, PLASMA_CUTTER] | PLATING | [AFTERBURNER, SENSOR_ARRAY, OVERCLOCK] | 2 (Kite) |
| `bruiser_crusher` | "Crusher-II" | BRUISER | 2 | BRAWLER | [SHOTGUN, MINIGUN] | REACTIVE_MESH | [OVERCLOCK, REPAIR_NANITES] | 0 (Agg) |
| `controller_jammer` | "Jammer" | CONTROLLER | 3 | BRAWLER | [ARC_EMITTER, MISSILE_POD] | REACTIVE_MESH | [EMP_CHARGE, SHIELD_PROJECTOR] | 1 (Def) |

**Tier-1 variant (weakest, replaces scrapyard_0/1 equivalents):**
| `tank_tincan` | "Tincan" | TANK | 1 | SCOUT | [PLASMA_CUTTER] | PLATING | [] | 1 (Def) |

→ **6 total templates**, 5 distinct archetypes, all tiers 1–3 represented.

### 3.3 Validity rules
- Every `weapons.size() ≤ chassis.weapon_slots`
- Every `modules.size() ≤ chassis.module_slots`
- All enum values must exist (enforced by test `test_templates_use_valid_enums`)

---

## §4 Picker Algorithm

```gdscript
static func pick_opponent_loadout(
    difficulty_tier: int,
    last_archetype: int = -1,
) -> Dictionary:
    # 1. Filter by tier: allow tier == difficulty_tier,
    #    plus tier == difficulty_tier - 1 (weaker fallback) if filtered pool < 2
    var pool := TEMPLATES.filter(func(t): return t.tier == difficulty_tier)
    if pool.size() < 2:
        pool += TEMPLATES.filter(func(t): return t.tier == difficulty_tier - 1)

    # 2. Variety: if last_archetype set, strip matching archetypes
    #    UNLESS pool would become empty (then keep it)
    if last_archetype != -1:
        var varied := pool.filter(func(t): return t.archetype != last_archetype)
        if not varied.is_empty():
            pool = varied

    # 3. Deterministic-ish pick (use RandomNumberGenerator; injectable seed for tests)
    return pool.pick_random()
```

### 4.1 Difficulty tier mapping
- **Scrapyard indices 0,1,2** → tiers **1, 1, 2**
- **Bronze indices 0,1,2** → tiers **2, 2, 3** (hooks only; league still unpopulated)
- Mapping lives in `OpponentLoadouts.difficulty_for(league, index)`. Centralizes future adjustments.

### 4.2 Variety state
- State lives on `GameState` as `var _last_opponent_archetype: int = -1`
- Set after each `build_opponent_brott` call
- Cleared on `new_game()` (already reconstructs `GameState`, so automatic)

### 4.3 Counter-play — DEFERRED
Per LoC budget guidance in brief. Mark as **Sprint 13.10 / S14 stretch**. Hook:
```gdscript
# pick_opponent_loadout(tier, last_archetype, player_archetype_hint := -1)
# Unused param now; reserved for counter-play logic.
```
Pass `-1` from all current callers.

---

## §5 Integration Point

**File:** `godot/game/opponent_data.gd`

**Change:** `build_opponent_brott()` uses picker instead of static dict lookup.

```gdscript
static func build_opponent_brott(league: String, index: int, game_state: GameState = null) -> BrottState:
    var tier := OpponentLoadouts.difficulty_for(league, index)
    var last_arch := game_state._last_opponent_archetype if game_state else -1
    var template := OpponentLoadouts.pick_opponent_loadout(tier, last_arch)

    var b := BrottState.new()
    b.team = 1
    b.bot_name = template["name"]
    b.chassis_type = template["chassis"]
    for wt in template["weapons"]:
        b.weapon_types.append(wt)
    b.armor_type = template["armor"]
    for mt in template["modules"]:
        b.module_types.append(mt)
    b.stance = template["stance"]
    b.setup()
    b.brain = BrottBrain.default_for_chassis(template["chassis"])

    if game_state:
        game_state._last_opponent_archetype = template["archetype"]
    return b
```

**Callsite audit:** Every caller of `build_opponent_brott(league, index)` must pass `GameState`. Grep target:
```
grep -rn "build_opponent_brott" godot/
```
Expected hits: `game_flow.gd` (1–2 spots). Update signature or add overload.

**Backward compat:** Keep `get_opponent(league, index)` returning a static stub dict (just `{id, league, index}`) for UI preview if any UI reads it — verify during impl.

---

## §6 Acceptance Criteria

1. `godot/data/opponent_loadouts.gd` exists with ≥4 named templates (target: 6).
2. Every template uses only existing enum values; no magic numbers.
3. `OpponentLoadouts.pick_opponent_loadout(tier, last_archetype)` returns a valid `Dictionary` with all required keys.
4. **Variety:** 10 sequential picks, each fed the prior archetype, never repeat consecutively (unless pool size = 1 for that tier).
5. **Difficulty scaling:** tier-1 picks never return tier-3 templates; tier-3 picks prefer tier-3.
6. All templates are distinct (no duplicate `(chassis, weapons[0], archetype)` triple).
7. `OpponentData.build_opponent_brott()` uses the picker; no hardcoded league loadouts remain.
8. No regressions: S13.3/.4/.5/.6/.7/.8 test suites pass.
9. New `test_sprint13_9.gd` ≥12 tests (§7).
10. GDD `§4` (or closest opponents section) documents the 5 archetypes + tier taxonomy.

---

## §7 Tests (target 12–14)

`godot/tests/test_sprint13_9.gd`:

1. `test_templates_list_nonempty` — ≥4 templates defined
2. `test_templates_use_valid_enums` — every chassis/weapon/armor/module/stance is a valid enum value
3. `test_templates_respect_slot_limits` — weapons.size() ≤ chassis.weapon_slots; modules ≤ module_slots
4. `test_templates_archetypes_cover_min_four` — ≥4 distinct archetypes present
5. `test_templates_tiers_span_range` — tiers 1, 2, 3 each have ≥1 template
6. `test_picker_returns_valid_template_tier1`
7. `test_picker_returns_valid_template_tier3`
8. `test_picker_variety_10_picks` — run picker 10× with last_archetype feedback; no back-to-back repeats
9. `test_picker_variety_fallback_when_pool_size_1` — if only 1 template matches tier, picker returns it even if matches last_archetype
10. `test_difficulty_for_scrapyard` — returns (1,1,2) for indices 0,1,2
11. `test_build_opponent_brott_uses_picker` — brott has valid chassis/weapons/armor/modules from a template
12. `test_build_opponent_brott_updates_last_archetype` — GameState `_last_opponent_archetype` set after build
13. `test_build_opponent_brott_has_brain` — brain is non-null (default_for_chassis fired)
14. `test_counter_play_hook_accepts_player_hint` — picker signature accepts hint param without crashing (stretch; deletable if counter-play dropped)

---

## §8 Risks / Flags for Ett

1. **🚨 Terminology collision** (§2 alert). "Fortress" = chassis in code. Spec renames artifacts to "opponent_loadouts". If Ett wants to keep brief's naming, grep-replace is trivial but tests/docs will read weird.
2. **No `fortress_ai.gd` / `enemy_builder.gd` exists.** All opponent construction is in `opponent_data.gd`. Brief's assumption was wrong; spec adjusted.
3. **No difficulty / run-depth field.** Using `(league, index) → tier` mapping instead. If Ett wants a real depth signal, that's scope creep → separate ticket.
4. **No archetype tagging on chassis.** Archetypes live on templates, not chassis. Fine for S13.9 but flag if future work wants chassis-level archetype queries.
5. **`GameState` plumbing.** `build_opponent_brott` needs `GameState` for variety tracking. Small signature change; ripple to 1–2 callsites. Acceptable.
6. **Counter-play deferred** per budget. Hook left in picker signature (unused param). Reclaim in S13.10 or fold into S14 stretch.
7. **Bronze league still empty.** S13.9 adds hooks (`difficulty_for("bronze", i)`) but doesn't populate. Bronze content is future work.
8. **LoC budget risk:** estimated — loadouts file ~90 LoC, integration diff ~30 LoC, tests ~160 LoC = ~280 LoC. Tight but fits. If GDD section writing spills, land it as a separate doc commit.
9. **`pick_random()` uses Godot's default RNG.** Tests should inject a seeded RNG or accept non-deterministic ordering (variety test is deterministic regardless — it's an invariant, not a specific sequence).

---

## §9 Split-Spawn Recommendation

**Recommend: 2-way split (A + B). Low coupling after schema is frozen.**

### Subagent A — Templates + Picker + Picker Tests
- Write `godot/data/opponent_loadouts.gd` (schema, 6 templates, `difficulty_for`, `pick_opponent_loadout`)
- Write tests 1–10 in `test_sprint13_9.gd`
- **Est:** ~140 LoC. No dependency on B.
- **Deliverable:** picker green in isolation.

### Subagent B — Integration + GDD + Integration Tests
- Modify `opponent_data.gd::build_opponent_brott` to use picker
- Update callsites in `game_flow.gd` (signature change to pass `GameState`)
- Add `_last_opponent_archetype` to `GameState`
- Write tests 11–14 in `test_sprint13_9.gd` (append after A lands)
- Update `docs/gdd.md` §4 with archetype taxonomy
- **Est:** ~140 LoC (mostly tests + GDD prose). Depends on A's schema + function signatures being frozen.
- **Deliverable:** full green, S13.3–13.8 regressions clean, GDD updated.

**Coordination:** A lands first (schema freeze). B starts once A's `pick_opponent_loadout` signature is merged. Ett can serialize A→B or let B stub the picker locally if parallelism matters.

---

## Appendix: Template Design Notes (for playtest feel)

- **Tank** = punish players with no sustain; Repair Nanites force long engagements
- **Glass Cannon** = punish players with no mobility; Railgun + Afterburner forces chase
- **Skirmisher** = generalist harasser; tests player's positional discipline
- **Bruiser** = midrange pressure; rewards players who commit TCR windows well
- **Controller** = disruption; EMP + Arc Emitter punish module-reliant player builds

All archetypes beatable by any player loadout with correct play. No hard counters. Variety guarantee keeps matchups fresh within a run.
