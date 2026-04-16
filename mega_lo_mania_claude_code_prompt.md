# Claude Code Prompt: Mega-Lo-Mania Spiritual Successor — Prototype Draft

## Context a cíl

Vytvoř prototyp real-time strategy hry inspirované Mega-Lo-Mania (Sensible Software, 1991).
Cílem je **funkční core loop gameplay**, ne grafický polish. Grafika = barevné čtverce
s textovými popisky. Zaměř se na **čistou architekturu a data-driven design**, protože
budeme iterovat.

**Engine**: Godot 4.3+ (GDScript)
**Genre**: Grid-based RTS / management sim
**Mode**: Single-player proti AI
**Pracovní název**: `DivineDominion` (změníme později)

---

## Core gameplay mechaniky (MVP scope)

### Svět
- Hra se hraje na **ostrovech** rozdělených na **sektory** (2-16 sektorů).
- Pro MVP stačí **jeden ostrov se 4 sektory** (2x2 grid).
- Každý sektor může obsahovat **tower** (věž) jednoho z hráčů/AI.
- Pokud tower shořel, sektor je neutrální.

### Hráči
- **2 hráči** pro MVP: Player (modrá) a AI (červená).
- Každý hráč má **globální pool mužů** (začátek: 100).
- Hráč může mít muže v **jednom nebo více sektorech**.

### Muži a tasks
V každém sektoru s towerem může hráč alokovat muže na následující úkoly:
- **Idle** (lenošení) — muži se reprodukují, čím víc idle mužů, tím rychlejší růst
- **Mining** — těží elementy (suroviny) z tohoto sektoru
- **Design** — výzkum technologií (postup tech levelu)
- **Manufacture** — vyrábí zbraně/štíty podle dostupných designs
- **Army** — tvoří armádu pro útok nebo obranu

**Důležité**: počet mužů přiřazených k tasku ovlivňuje rychlost/efektivitu úkolu.

### Tech tree (zjednodušený pro MVP)
10 tech levelů reprezentujících historické epochy. Pro MVP stačí první 3:
1. **9500 BC** — Rocks (kamení)
2. **9000 BC** — Slings (praky)
3. **8000 BC** — Spears (oštěpy)

Každý tech level odemyká nové zbraně a případně budovy. Postup v tech levelu
vyžaduje určitý počet "design points" nashromážděných designery.

### Zbraně a štíty
- **Design**: musí být nejdřív vyzkoumán (design points)
- **Manufacture**: vyžaduje elementy (suroviny) + muže v Manufacture tasku
- **Use**: automaticky vybaveny armádě v sektoru

### Combat
Když armáda útočí na sousední sektor:
- Zjednodušený combat formula: `attacker_strength vs defender_strength`
- Strength = počet mužů * tech_weapon_multiplier
- Vítěz obsadí sektor, poražený zmizí (muži jsou ztraceni)
- Pokud obránce ztratí všechny muže v sektoru, jeho tower shoří

### Victory conditions
- Hráč vyhrává, když ovládá **všechny sektory** ostrova
- Hráč prohrává, když **nemá žádný sektor ani muže**

### Real-time tick
Hra běží v reálném čase, ale interně používá **fixní tick rate** (doporučuji 10 ticks/s).
Veškerá herní logika (reprodukce, mining, design progress) probíhá per-tick.
Hráč může kdykoli **pauznout** (Space).

---

## Architektura požadavky

### 1. Data-driven design
Všechna herní data (epochs, weapons, shields, costs) musí být v **Godot Resource**
souborech (.tres) nebo JSON/TOML, ne hardcoded v kódu. Budeme to často ladit.

Navrhni Resource třídy:
- `EpochData` — tech level, dostupné zbraně, požadované design points
- `WeaponData` — damage, cost (elements), manufacture_time
- `ShieldData` — defense, cost, manufacture_time
- `IslandData` — počet sektorů, startup conditions

### 2. Separation of concerns

```
GameState (autoload singleton)
├── WorldModel — sektory, ownership, tower states
├── PlayerModel[] — muži, resources, tech level, designs
└── TickEngine — spouští per-tick update všech systémů

UI (kompletně oddělené od logiky)
├── SectorView — vizualizace sektoru (čtverec + label)
├── AllocationPanel — sliders pro alokaci mužů na tasks
├── ResourcePanel — zobrazení resources, tech level
└── ActionPanel — tlačítka: Attack, Build Tower, Ally
```

### 3. Event-driven komunikace
Použij Godot **signals** pro komunikaci mezi modely a UI:
- `sector_captured(sector_id, new_owner)`
- `tech_level_advanced(player_id, new_level)`
- `weapon_designed(player_id, weapon_id)`
- `combat_resolved(attacker, defender, result)`
- `men_allocation_changed(sector_id, task, count)`

### 4. AI opponent (MVP verze)
Jednoduchý **state machine** pro AI, ne složité behavior trees:
- `EXPAND` — pokud má idle muže, postav tower v prázdném sektoru
- `RESEARCH` — pokud je tech level nízký, alokuj muže na design
- `DEFEND` — pokud je pod útokem, stáhni muže do army
- `ATTACK` — pokud má dost armády, útoč na nejslabšího souseda

AI rozhoduje každé 2-5 sekund, ne per-tick (jinak je to computationally drahé).

### 5. Save/Load
Jednoduchá serializace celého GameState do JSON (Godot má nativní `JSON.stringify`).
Není to priorita pro první prototyp, ale architektura by to měla umožnit
(tj. všechny modely musí být serializable).

---

## UI požadavky (draft grafika)

### Vizuální styl
- **Žádný art**. Čistě Godot Control nodes.
- Sektory = **ColorRect** (128x128 px) s border a Label uprostřed
- Barva sektoru = barva vlastníka (modrá/červená/šedá pro neutral)
- Label = "Sector X" + "♂ N" (počet mužů) + "▲ T" (tech level)

### Layout
```
┌─────────────────────────────────────────┐
│ [Top bar: Player resources, tech level] │
├──────────────┬──────────────────────────┤
│              │                          │
│   SECTOR     │    SECTOR                │
│   (0,0)      │    (1,0)                 │
│              │                          │
├──────────────┼──────────────────────────┤
│              │                          │
│   SECTOR     │    SECTOR                │
│   (0,1)      │    (1,1)                 │
│              │                          │
├──────────────┴──────────────────────────┤
│ [Bottom panel: Allocation sliders for   │
│  selected sector]                       │
└─────────────────────────────────────────┘
```

### Interakce
- **Klik na sektor** = otevře allocation panel (spodní panel)
- **Allocation panel**: 5 sliderů (Idle, Mining, Design, Manufacture, Army).
  Suma = muži v tom sektoru. Přesun mezi tasky.
- **Pravé tlačítko na sektor** = akce: Attack from (vybraný sektor), Build Tower (pokud neutral)
- **Space** = pauza
- **Speed buttons**: 1x, 2x, 4x (nahoře vpravo)

### Theme
- Použij **default Godot Theme** pro MVP (nic vlastního)
- Font: Godot default
- Můžeš ale použít `Kenney UI Pack` z kenney.nl pokud chceš rychle lepší vzhled
  (není povinné pro draft)

---

## Technické požadavky

### Project setup
- Godot 4.3+ projekt
- `project.godot` s nastavením: 1280x720, 2D renderer, pixel_snap off
- Struktura složek:
  ```
  /scripts
    /models       — GameState, WorldModel, PlayerModel
    /systems      — TickEngine, CombatSystem, AISystem
    /data         — Epoch, Weapon, Shield resources
  /scenes
    /ui           — Control scenes
    /main         — Main.tscn (root scene)
  /resources
    /epochs       — .tres files
    /weapons      — .tres files
  /tests          — GUT tests pokud to čas dovolí
  ```

### Coding style
- **Strict typing**: všechny funkce a proměnné typované (`var x: int = 0`)
- **Docstrings** nad každou třídou a public metodou
- **Krátké metody** (max 20 řádků)
- **Žádné magic numbers** — konstanty nahoře v souboru nebo v Resource
- **Preferuj composition over inheritance**
- **GDScript**, ne C# (pro tento scope GDScript stačí a rychleji iteruji)

### Dependencies
- **Žádné third-party knihovny** pro MVP
- Vše nativně Godot 4.3

### Testing
Pokud čas dovolí, napiš základní unit testy pro:
- `CombatSystem.resolve_combat()` — matematika combat formule
- `WorldModel.reproduce_men()` — reprodukční logika
- `TechTree.advance_level()` — podmínky postupu

Použij **GUT** (Godot Unit Test) framework pokud ho chceš přidat,
nebo jednoduché smoke testy v samostatné scéně.

---

## Deliverables (co od tebe očekávám)

1. **Kompletní Godot 4.3 projekt** s běžícím prototypem
2. **README.md** s:
   - Popisem architektury
   - Instrukcemi jak spustit
   - Známými omezeními MVP
3. **CHANGELOG.md** kde budu trackovat změny
4. **Sample playthrough** popis: "Jak vypadá typická hra (2-3 minuty)"

---

## Co NEDĚLAT (explicitně mimo scope MVP)

- ❌ Grafické assety, sprity, animace
- ❌ Zvuky a hudba
- ❌ Multiplayer / network
- ❌ Všech 28 ostrovů — stačí 1 ostrov pro demo
- ❌ Všech 10 epoch — stačí první 3
- ❌ Alliance systém (odložíme na další iteraci)
- ❌ Shields (odložíme — zatím jen weapons)
- ❌ Sophisticated AI — stačí jednoduchý state machine
- ❌ Cinematics, menu, save/load UI (stačí New Game + běžící hra)
- ❌ Localization
- ❌ Settings menu (hlasitost, fullscreen, keybindings)

Tohle všechno přidáme postupně v dalších iteracích, **nepředbíhej**.

---

## Kritéria úspěchu MVP

Prototyp je hotový, když:

1. ✅ Hru lze spustit, objeví se ostrov se 4 sektory
2. ✅ Hráč začíná s 1 sektorem (levý horní), AI s 1 sektorem (pravý dolní)
3. ✅ Hráč může alokovat muže mezi 5 tasků ve svých sektorech
4. ✅ Elementy se těží, design points rostou, tech level se zvyšuje po splnění podmínek
5. ✅ Hráč může zaútočit na sousední sektor, combat se resolvne
6. ✅ AI se chová podle state machine (nedělá random akce)
7. ✅ Existuje win/lose condition a hra se koncí správně
8. ✅ Hra běží na 60 FPS bez stutter
9. ✅ Kód je čistý, komentovaný, testovatelný

---

## Workflow

Prosím **pracuj iterativně**:

1. Nejdřív vytvoř **strukturu projektu** a `project.godot`
2. Potom **datové modely a resources** (žádná grafika)
3. Potom **TickEngine a základní game loop** (log do konzole, bez UI)
4. Potom **UI vrstvu** (čtverce a panely)
5. Potom **AI opponenta**
6. Na konec **win/lose condition a polish**

Po každé fázi mi ukaž, co jsi udělal, a počkej na feedback než budeš pokračovat.
Pokud narazíš na nejasnost nebo design decision, **ptej se místo hádání**.

---

## Reference materiály

- Wikipedia: Mega-Lo-Mania (pro pochopení originálu)
- Godot docs: https://docs.godotengine.org/en/stable/
- GDScript best practices: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html
- Pokud chceš inspiraci na UI: Kenney.nl UI Pack (CC0)

---

**Start here**: Zobraz mi plán projektu (seznam souborů a co budou obsahovat)
**před tím, než začneš psát kód**. Chci schválit architekturu než se pustíš do implementace.
