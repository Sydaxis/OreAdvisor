# OreAdvisor

A World of Warcraft addon for the 20th Anniversary Classic servers that scans your bags and tells you exactly what to do with your ore and gems based on live TradeSkillMaster (TSM) market prices.

No more guessing whether to smelt, prospect, or just sell raw — OreAdvisor does the math for you.

---

## Requirements

- **World of Warcraft** — 20th Anniversary Classic (Interface version 20505)
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

All ore and bar IDs have been verified in-game:

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

---

## Known Limitations

- Rare gem cut IDs for patterns not yet learned by the JC are not fully verified. These will show as UNPRICED until the IDs are confirmed and added in a future update. Patterns you have learned are handled automatically by Scan Tradeskill.
- Prospect values are statistical averages based on known drop rates. Individual sessions will vary.
- DBMinBuyout (used for the hold signal) goes stale between AH scans. Run a TSM AH scan periodically to keep it accurate.

---

## Contributing

Pull requests welcome. If you find an incorrect item ID or a gem cut that isn't showing up correctly, open an issue with the item name and ID (use `/script print(GetItemInfo(ID))` in-game to verify).

---

## License

MIT
