**Game Title (Inferred):** Text Defense / Concept Purge

**Core Gameplay:**

This is a top-down, fixed-perspective hybrid tower defense and bullet-hell shooter with resource management elements.

**Objective:**  
The player must defend their base by controlling both automated turrets and a mobile unit, fending off waves of "enemies" (representing negative concepts or characters) descending from the top of the screen. Players earn points by eliminating enemies and must carefully manage their ammunition—text characters—as a finite resource.

---

**Player Controls:**

- **Movement:** Use **W/A/S/D** or arrow keys to move a green player unit (possibly a command unit or auxiliary weapon) within a limited area at the bottom of the screen.  
- **Manual Firing:** The player unit automatically targets the nearest enemy.
  - **Spacebar:** Fire a precise single-character bullet.
  - **X:** Fire a spread shot (fan-shaped bullets), consuming more ammunition.
  - **C:** Fire a piercing laser beam (high ammo cost, with a short cooldown).

**Debug / Camera Controls (Auxiliary Functions):**
- **Q/A/W/S:** Adjust the default aiming direction (idle orientation) of the player unit or all turret barrels—primarily for debugging.
- **D:** Toggle display of debug information (e.g., current angle, cooldown status).
- **R:** Reload the current "bullets" text file.
- **N:** Switch to the next "bullets" text file.

---

**Automated Defense (Core Mechanic):**

A row of automated turrets (28 in code) is positioned along the bottom of the screen. Each turret type fires differently but shares the same ammo pool with the player:

- **Standard Turret:** Fires single-character bullets.
- **Shotgun Turret:** Occasionally fires spread shots.
- **Laser Turret:** Occasionally fires laser beams.
- **Homing Turret:** Fires single-character bullets (similar logic to standard, possibly with minor tuning).

All turrets automatically detect and aim at the closest enemy, firing at varying rates and patterns (single shot, spread, laser).  

**Shared Ammo Pool:**  
All turrets and the player draw from a single, shared ammunition supply.

---

**Resource System (Unique Feature):**

Ammunition is not infinite—it is sourced from external text files stored in the `bullets` directory.

- On startup, the game reads these files and loads their characters sequentially into a "clip" (`current_clip`).
- Each shot consumes characters:
  - Single shot: **1 character**
  - Spread shot: **5 characters**
  - Laser: **10 characters**
- When one file is exhausted, the game automatically switches to the next.
- If all files are depleted, the game may halt firing or fall back to default placeholder characters.

---

**Enemies:**

- Enemies are characters representing negative "concepts" (e.g., "贪" *Greed*, "怒" *Wrath*, "愚" *Foolishness*).
- They spawn randomly at the top of the screen and move downward.
- Different enemy types may have varying speeds and HP (though base implementation uses 1 HP per enemy, with potential for expansion).
- Differentiation and variety are partially implemented, with room for deeper mechanics.

---

**Combat & Feedback:**

- Character bullets and lasers from both the player and turrets deal damage on impact.
- Defeated enemies disappear and grant score points.
- Projectiles (bullets, lasers) and enemies are removed when they exceed screen boundaries or reach their lifespan.

---

**Summary:**

The player primarily supports a network of automated turrets through movement and targeted manual fire. The core strategy and appeal of the game lie in:

- Observing and optimizing the coordinated operation of multiple turret types.
- The novel **text-based ammunition system**, transforming written content into combat resources.
- Surviving relentless, high-density waves of conceptual enemies.
- Fast-paced, high-volume combat focused on base defense and careful management of textual ammunition.

The game emphasizes **rhythm, resource scarcity, and visual spectacle**, blending procedural text usage with intense defensive gameplay.
