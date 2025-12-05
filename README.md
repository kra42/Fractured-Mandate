Fractured Mandate - Design Document

Genre: Single-player, Turn-based Strategy, Roguelike, Team Builder

Theme: Romance of the Three Kingdoms (High Fantasy/Tactical)

Core Hook: A "Linear Trip" roguelike where Qi (Energy) is the scarcest resource. Movement is manual but expensive, forcing players to treat positioning like a puzzle rather than a skirmish.

1. Core Concepts

The Linear Trip: A roguelike run where resources (HP/Qi) are scarce. There is no turning back.

The Team: Players build a roster from 4 Factions (Shu, Wu, Wei, Warlords).

The Economy: Management of HP (Survival), Qi (Action Economy), and Provisions (Time Limit).

2. The Arena & Grid

Dimensions: Split Field.

Player Side: 4 Rows x 3 Columns (12 Squares).

Enemy Side: 4 Rows x 3 Columns (12 Squares).

Distance: Effective range is Global. If you have Line of Sight (LOS) and the targeting type permits, you can hit it.

3. Combat Mechanics

Turn Structure

Turn Order: Determined by Initiative. Highest acts first.

Round: A new Round starts only after all units have acted.

Movement (The "No Free Move" Rule)

Cost: 1 Qi per tile moved.

Tactical Trade-off: Movement competes with Ultimate abilities for the same resource pool. You typically "Stop and Pop"—secure a formation and only move when necessary.

Targeting Logic (Collision vs. Precision)

To differentiate units on a small grid, classes follow strict LOS rules:

A. Melee (Warriors/Vanguards)

Attack Type: Linear Collision.

Rule: Attacks travel down the row and hit the First Unit (Enemy) they touch.

Blocking: Blocked by ALL objects (Enemies, Friendly Units, Obstacles).

Placement: Must be in the front (Col 3) to function.

B. Ranged (Archers/Strategists)

Attack Type: Target Selection (Precision).

Rule: Players can Select any valid target in the row.

Blocking: Shoots OVER Friendly units/Obstacles. Only blocked by empty rows or Hard Cover.

Placement: Can stack behind Melee units (Col 1 or 2) and snipe high-priority targets.

4. Stats & Economy

Hero Stats

HP: If 0, Hero is removed. Death Penalty: Returns next battle with 10% HP.

Qi (Energy):

Regen: +1 Qi at start of turn.

Usage: Skills, Ultimates, and Movement.

Note: Qi is NOT shared between team members.

Attack / Defense: Flat and % based mitigation.

Initiative: Speed/Turn Order.

Provisions (The Anti-Stall System)

Consumption: The army consumes 1 Provision per Round.

Starvation: If Provisions hit 0:

Morale Collapse: Healing effects become 0% effective.

Attrition: All Heroes lose 10% Max HP at the end of every round.

5. Progression (The Run)

Start: Select Faction -> Pick 1 Starting Hero (from a selection of 3).

Combat Nodes (4-6): Normal Enemies.

Reward: Gold, Common/Rare Equips, Consumables.

Midpoint (Elite): Elite Enemies.

Reward: New Hero (if roster size < 4) OR Epic Drop/Buff.

Boss Fight: Final challenge of the floor.

Reward: Legendary Equipment or Buff.

6. Systems & Synergy (Deck Building)

Equipment

Slots: 1 Weapon, 1 Accessory.

Exclusive Weapons (Legendary): Unlocks hidden passives for specific characters.

Green Dragon Crescent Blade: Bonus effects for Guan Yu.

Twin Swords (Cixiong Shuanggu Jian): Bonus effects for Liu Bei.

Red Hare (Accessory): Bonus Speed/Evasion for Guan Yu or Lu Bu.

Passive Buffs

Faction Buffs: (e.g., Wei +Crit, Shu +Regen).

Class Buffs: (e.g., Warriors +Dmg Reduction).

Relationship Bonds (Auto-Active):

Peach Garden Oath: Liu Bei + Guan Yu + Zhang Fei.

Sleeping Dragon & Fledgling Phoenix: Zhuge Liang + Pang Tong.

Alliance Traits (The 2+2 System)

Encourages multi-faction teams. Requires 2 Heroes of each faction to trigger major buffs.

Alliance

Name (CN)

Theme

Trade-off

Shu + Wu

赤壁联盟 (Red Cliffs)

Defensive

High survivability, low burst.

Wei + Wu

审时度势 (Opportunist)

Counter-Attack

Punishes enemies for attacking.

Shu + Wei

汉贼不两立 (Mortal Enemies)

High Risk

Massive stats, HP loss per turn.

The Warlord Rule (Option C)

Heroes: Lu Bu, Diao Chan, Dong Zhuo, Yuan Shao.

Mechanic: Warlords DO NOT form Alliances.

Trade-off: They act as "Solo Carries" with significantly higher base stats and self-buffs, but break team synergy bonuses.
