# OreAdvisor

A World of Warcraft addon for the 20th Anniversary Classic servers that scans your bags and tells you exactly what to do with your ore and gems based on live TradeSkillMaster (TSM) market prices.

No more guessing whether to smelt, prospect, or just sell raw — OreAdvisor does the math for you.

---

## Requirements

- **World of Warcraft** — 20th Anniversary Classic (Interface version 20505)
- **Version** — v1.0
- **TradeSkillMaster (TSM)** with the TSM Desktop App running for up-to-date pricing data
- A character with **Mining** and/or **Jewelcrafting**

---

## Installation

1. Download `OreAdvisor.lua` and `OreAdvisor.toc` from this repo
2. Create a folder called `OreAdvisor` inside your WoW AddOns directory:
   ```
   World of Warcraft/_anniversary_/Interface/AddOns/OreAdvisor/
   ```
3. Place both files inside that folder
4. Launch WoW and enable the addon on the character select screen
5. You should see `Ore Advisor loaded — /oa to open` in your chat on login

---

## Usage

Type `/oa` to open the addon window. You can also use:

| Command | Action |
|---|---|
| `/oa` | Toggle the window open/closed |
| `/oa ore` | Open directly to the Ore tab |
| `/oa gems` | Open directly to the Gems tab |

The window can be dragged anywhere on screen and closed with **Escape**.

---

## Ore Tab

Designed for use on your **Miner**. Hit **Scan Bags** and the addon will:

1. Detect all ore in your bags (Fel Iron, Adamantite, Khorium, Eternium)
2. Pull current market prices from TSM
3. Calculate the expected gold value of each option
4. Recommend the most profitable action

### Possible recommendations

| Recommendation | Meaning |
|---|---|
| **SELL RAW** | Selling the ore as-is is the best option |
| **SMELT** | Smelting into bars and selling yields more gold |
| **PROSPECT** | Sending to your JC to prospect is best (raw gem prices used) |
| **PROSPECT+CUT** | Prospecting and cutting gems beats all other options |
| **HARDEN** | Crafting Hardened Adamantite Bars is the best use (Adamantite only) |
| **CRAFT FELSTEEL** | You have enough Fel Iron + Eternium to make profitable Felsteel Bars |

### Prospect threshold

Prospecting is only recommended if the expected gem value beats smelting by **at least 20%**. This accounts for the natural variance of prospecting — on any individual session you might get unlucky. If prospect wins by less than 20%, the addon recommends smelting and shows you how close the margin was.

If gem prices spike (e.g. Living Ruby jumps 50% before a raid reset), the recommendation will automatically flip to PROSPECT+CUT when it clears the threshold.

### Hold warning

If the current AH buyout price is more than 25% below TSM's market average, the addon will flag the ore as price-depressed and suggest holding until prices recover.

---

## Gems Tab

Designed for use on your **Jewelcrafter**. This tab shows all raw gems in your bags and recommends whether to cut or sell raw, based on which cut fetches the best TSM price.

### First time setup

The addon needs to learn which cuts your JC knows. To do this:

1. Open your **Jewelcrafting** tradeskill window in-game
2. Switch to the Gems tab in OreAdvisor
3. Hit **Scan Tradeskill**

The addon will scan every recipe you know and save the results. You only need to do this once — or again whenever you learn a new cut.

### Reading the gem recommendations

Each gem in your bags shows:

- **CUT** — cutting this gem is worth more than selling raw. Shows the recommended cut, its stat bonus, and the gold profit over raw price
- **SELL RAW** — raw price beats all available cuts
- **UNPRICED** — TSM has no data for this gem. Run an AH scan at the Auction House first

Each cut is tagged with:
- `[known]` — your JC can cut this right now
- `[pattern needed]` — you don't have this recipe yet, but it's shown so you can decide whether to buy it

### How pricing works

- Common gems (Blood Garnet, Deep Peridot, etc.) — cut IDs are fully verified
- Rare gems (Living Ruby, Nightseye, etc.) — cut IDs for patterns you have learned are populated automatically via Scan Tradeskill. Patterns you haven't learned yet will show as UNPRICED until those IDs are verified in a future update

---

## How the ore and gem tabs work together

If you run both a Miner and a Jewelcrafter:

1. Do a **Scan Tradeskill** on your JC first
2. The Ore tab on your Miner will automatically use **cut gem prices** (not raw) when calculating the prospect value — so the PROSPECT+CUT recommendation accounts for what your JC can actually do with the gems

The cut data is stored in saved variables (`OreAdvisorDB`) and shared between characters on the same account, so it only needs to be scanned once.

---

## Verified Item IDs

All item IDs have been verified in-game.

**Ore & Bars**

| Item | ID |
|---|---|
| Fel Iron Ore | 23424 |
| Fel Iron Bar | 23445 |
| Adamantite Ore | 23425 |
| Adamantite Bar | 23446 |
| Hardened Adamantite Bar | 23573 |
| Khorium Ore | 23426 |
| Khorium Bar | 23449 |
| Eternium Ore | 23427 |
| Eternium Bar | 23447 |
| Felsteel Bar | 23448 |

**Common Gems**

| Item | ID |
|---|---|
| Blood Garnet | 23077 |
| Deep Peridot | 23079 |
| Shadow Draenite | 23107 |
| Golden Draenite | 23112 |
| Azure Moonstone | 23117 |
| Flame Spessarite | 21929 |

**Rare Gems**

| Item | ID |
|---|---|
| Living Ruby | 23436 |
| Talasite | 23437 |
| Star of Elune | 23438 |
| Noble Topaz | 23439 |
| Dawnstone | 23440 |
| Nightseye | 23441 |

**Rare Gem Cuts**

| Cut | ID |
|---|---|
| Bold Living Ruby | 24027 |
| Delicate Living Ruby | 24028 |
| Teardrop Living Ruby | 24029 |
| Runed Living Ruby | 24030 |
| Bright Living Ruby | 24031 |
| Subtle Living Ruby | 24032 |
| Flashing Living Ruby | 24036 |
| Enduring Talasite | 24062 |
| Dazzling Talasite | 24065 |
| Radiant Talasite | 24066 |
| Jagged Talasite | 24067 |
| Solid Star of Elune | 24033 |
| Sparkling Star of Elune | 24035 |
| Lustrous Star of Elune | 24037 |
| Stormy Star of Elune | 24039 |
| Inscribed Noble Topaz | 24058 |
| Potent Noble Topaz | 24059 |
| Luminous Noble Topaz | 24060 |
| Glinting Noble Topaz | 24061 |
| Brilliant Dawnstone | 24047 |
| Smooth Dawnstone | 24048 |
| Gleaming Dawnstone | 24050 |
| Rigid Dawnstone | 24051 |
| Thick Dawnstone | 24052 |
| Mystic Dawnstone | 24053 |
| Sovereign Nightseye | 24054 |
| Shifting Nightseye | 24055 |
| Glowing Nightseye | 24056 |
| Royal Nightseye | 24057 |

---

## Known Limitations

- Prospect values are statistical averages based on known drop rates. Individual sessions will vary.
- DBMinBuyout (used for the hold signal) goes stale between AH scans. Run a TSM AH scan periodically to keep it accurate.

---

## Contributing

Pull requests welcome. If you find an incorrect item ID or a gem cut that isn't showing up correctly, open an issue with the item name and ID (use `/script print(GetItemInfo(ID))` in-game to verify).

---

## License

MIT
