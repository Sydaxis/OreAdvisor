-- OreAdvisor v2.0
-- /oa to open
-- Ore panel: scans bags, pulls TSM prices, recommends sell/smelt/prospect/craft
-- Gem panel: scans bags and JC tradeskill, recommends raw vs best cut

----------------------------------------------------------------------
-- Saved variables
----------------------------------------------------------------------
OreAdvisorDB = OreAdvisorDB or {}
OreAdvisorDB.knownCuts = OreAdvisorDB.knownCuts or {}



----------------------------------------------------------------------
-- Ore data (all IDs verified in-game)
----------------------------------------------------------------------
local COMMON_GEM_IDS = {23077, 23079, 23107, 23112, 23117, 21929}
local RARE_GEM_IDS   = {23436, 23437, 23438, 23439, 23440, 23441}

local ORES = {
    {
        oreID = 23424, oreName = "Fel Iron Ore",
        barID = 23445, barRatio = 2,
        canProspect = true,
        commonsPerPro = 1.9, raresPerPro = 0.05,
    },
    {
        oreID = 23425, oreName = "Adamantite Ore",
        barID = 23446, barRatio = 2,
        canProspect = true,
        commonsPerPro = 2.0, raresPerPro = 0.20,
        hardenedBarID = 23573, barsPerHardened = 10,
    },
    {
        oreID = 23426, oreName = "Khorium Ore",
        barID = 23449, barRatio = 2,
        canProspect = false,
    },
    {
        oreID = 23427, oreName = "Eternium Ore",
        barID = 23447, barRatio = 2,
        canProspect = false,
    },
}

----------------------------------------------------------------------
-- Gem data
-- Cut IDs marked 0 = unverified, will be filled by tradeskill scan
-- Confirmed IDs from in-game testing noted with checkmark
----------------------------------------------------------------------
local CUT_STATS = {
    ["Bold"]      = "+STR",     ["Runed"]     = "+SP",
    ["Delicate"]  = "+AGI",     ["Teardrop"]  = "+Healing",
    ["Bright"]    = "+AP",      ["Subtle"]    = "+Dodge",
    ["Solid"]     = "+STA",     ["Sparkling"] = "+SPI",
    ["Stormy"]    = "+Spell Pen",["Lustrous"]  = "+MP5",
    ["Jagged"]    = "+AGI/STA", ["Enduring"]  = "+DEF/STA",
    ["Radiant"]   = "+Crit/STA",["Dazzling"]  = "+INT/MP5",
    ["Brilliant"] = "+INT",     ["Gleaming"]  = "+Crit",
    ["Thick"]     = "+DEF",     ["Rigid"]     = "+Hit",
    ["Glinting"]  = "+AGI/Hit", ["Potent"]    = "+SP/Crit",
    ["Luminous"]  = "+Heal/MP5",["Inscribed"] = "+STR/Crit",
    ["Glowing"]   = "+SP/STA",  ["Royal"]     = "+Heal/MP5",
    ["Shifting"]  = "+AGI/STA", ["Sovereign"] = "+STR/STA",
}

-- ALL_CUTS[rawGemID] = list of { name, stat, id }
-- id=0 means unverified — tradeskill scan will fill these in for known cuts
local ALL_CUTS = {
    -- Blood Garnet (red common) — IDs verified ✓
    [23077] = {
        { name="Bold Blood Garnet",     stat="+8 STR",    id=23095 },
        { name="Runed Blood Garnet",    stat="+8 SP",     id=23096 },
        { name="Delicate Blood Garnet", stat="+8 AGI",    id=23097 },
        { name="Teardrop Blood Garnet", stat="+8 Heal",   id=23094 },
        { name="Bright Blood Garnet",   stat="+16 AP",    id=0     },
        { name="Subtle Blood Garnet",   stat="+8 Dodge",  id=0     },
    },
    -- Deep Peridot (green common) — IDs verified ✓
    [23079] = {
        { name="Jagged Deep Peridot",   stat="+4AGI/+4STA",  id=23104 },
        { name="Enduring Deep Peridot", stat="+4DEF/+4STA",  id=23105 },
        { name="Radiant Deep Peridot",  stat="+4Crit/+4STA", id=23103 },
        { name="Dazzling Deep Peridot", stat="+4INT/+1MP5",  id=23106 },
    },
    -- Shadow Draenite (purple common) — IDs verified ✓
    [23107] = {
        { name="Glowing Shadow Draenite",   stat="+5SP/+4STA",   id=23108 },
        { name="Royal Shadow Draenite",     stat="+5Heal/+1MP5", id=23109 },
        { name="Shifting Shadow Draenite",  stat="+4AGI/+4STA",  id=23110 },
        { name="Sovereign Shadow Draenite", stat="+5STR/+4STA",  id=23111 },
    },
    -- Golden Draenite (yellow common) — IDs verified ✓
    [23112] = {
        { name="Brilliant Golden Draenite", stat="+8 INT",  id=23113 },
        { name="Gleaming Golden Draenite",  stat="+8 Crit", id=23114 },
        { name="Thick Golden Draenite",     stat="+8 DEF",  id=23115 },
        { name="Rigid Golden Draenite",     stat="+8 Hit",  id=23116 },
    },
    -- Azure Moonstone (blue common) — IDs verified ✓
    [23117] = {
        { name="Solid Azure Moonstone",    stat="+8 STA",      id=23118 },
        { name="Sparkling Azure Moonstone",stat="+8 SPI",      id=23119 },
        { name="Stormy Azure Moonstone",   stat="+8 SpellPen", id=23120 },
        { name="Lustrous Azure Moonstone", stat="+2 MP5",      id=23121 },
    },
    -- Flame Spessarite (orange common) — IDs verified ✓
    [21929] = {
        { name="Glinting Flame Spessarite",  stat="+4AGI/+4Hit",  id=23100 },
        { name="Potent Flame Spessarite",    stat="+5SP/+4Crit",  id=23101 },
        { name="Luminous Flame Spessarite",  stat="+5Heal/+1MP5", id=23099 },
        { name="Inscribed Flame Spessarite", stat="+5STR/+4Crit", id=23098 },
    },
    -- Living Ruby (red rare) — all IDs verified ✓
    [23436] = {
        { name="Bold Living Ruby",     stat="+12 STR",   id=24027 },
        { name="Delicate Living Ruby", stat="+12 AGI",   id=24028 },
        { name="Teardrop Living Ruby", stat="+12 Heal",  id=24029 },
        { name="Runed Living Ruby",    stat="+12 SP",    id=24030 },
        { name="Bright Living Ruby",   stat="+24 AP",    id=24031 },
        { name="Subtle Living Ruby",   stat="+12 Dodge", id=24032 },
        { name="Flashing Living Ruby", stat="+12 STA",   id=24036 },
    },
    -- Talasite (green rare) — all IDs verified ✓
    [23437] = {
        { name="Enduring Talasite", stat="+6DEF/+6STA",  id=24062 },
        { name="Dazzling Talasite", stat="+6INT/+2MP5",  id=24065 },
        { name="Radiant Talasite",  stat="+6Crit/+6STA", id=24066 },
        { name="Jagged Talasite",   stat="+6AGI/+6STA",  id=24067 },
    },
    -- Star of Elune (blue rare) — all IDs verified ✓
    [23438] = {
        { name="Solid Star of Elune",     stat="+12 STA",      id=24033 },
        { name="Sparkling Star of Elune", stat="+12 SPI",      id=24035 },
        { name="Lustrous Star of Elune",  stat="+3 MP5",       id=24037 },
        { name="Stormy Star of Elune",    stat="+12 SpellPen", id=24039 },
    },
    -- Noble Topaz (orange rare) — all IDs verified ✓
    [23439] = {
        { name="Inscribed Noble Topaz", stat="+9STR/+6Crit", id=24058 },
        { name="Potent Noble Topaz",    stat="+9SP/+6Crit",  id=24059 },
        { name="Luminous Noble Topaz",  stat="+9Heal/+2MP5", id=24060 },
        { name="Glinting Noble Topaz",  stat="+6AGI/+6Hit",  id=24061 },
    },
    -- Dawnstone (yellow rare) — all IDs verified ✓
    [23440] = {
        { name="Brilliant Dawnstone", stat="+12 INT",  id=24047 },
        { name="Smooth Dawnstone",    stat="+12 STA",  id=24048 },
        { name="Gleaming Dawnstone",  stat="+12 Crit", id=24050 },
        { name="Rigid Dawnstone",     stat="+12 Hit",  id=24051 },
        { name="Thick Dawnstone",     stat="+12 DEF",  id=24052 },
        { name="Mystic Dawnstone",    stat="+12 SPI",  id=24053 },
    },
    -- Nightseye (purple rare) — all IDs verified ✓
    [23441] = {
        { name="Sovereign Nightseye", stat="+9STR/+6STA",   id=24054 },
        { name="Shifting Nightseye",  stat="+6AGI/+6STA",   id=24055 },
        { name="Glowing Nightseye",   stat="+9SP/+6STA",    id=24056 },
        { name="Royal Nightseye",     stat="+9Heal/+2MP5",  id=24057 },
    },
}

----------------------------------------------------------------------
-- Rehydrate cut IDs from saved variables
-- ALL_CUTS is rebuilt fresh every load with rare cut IDs = 0,
-- so we restore any IDs the tradeskill scan previously saved
----------------------------------------------------------------------
local function RehydrateCutIDs()
    for rawGemID, savedCuts in pairs(OreAdvisorDB.knownCuts) do
        local cuts = ALL_CUTS[rawGemID]
        if cuts then
            for _, saved in ipairs(savedCuts) do
                for _, cut in ipairs(cuts) do
                    if cut.name == saved.name and saved.id and saved.id ~= 0 then
                        cut.id = saved.id
                    end
                end
            end
        end
    end
end

----------------------------------------------------------------------
-- TSM helpers
----------------------------------------------------------------------
local function TSMGold(itemID, source)
    if not TSM_API or not itemID or itemID == 0 then return nil end
    source = source or "DBMarket"
    local ok, v = pcall(TSM_API.GetCustomPriceValue, source, "i:"..itemID)
    if ok and type(v) == "number" and v > 0 then return v / 10000 end
    return nil
end

local function AvgTSMGold(ids)
    local sum, n = 0, 0
    for _, id in ipairs(ids) do
        local p = TSMGold(id)
        if p then sum = sum + p; n = n + 1 end
    end
    return n > 0 and (sum / n) or nil
end

----------------------------------------------------------------------
-- Bag scanner
----------------------------------------------------------------------
-- Container API compatibility (Anniversary client uses C_Container namespace)
local GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
local GetContainerItemLink = C_Container and C_Container.GetContainerItemLink or GetContainerItemLink
local function GetContainerItemCount(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        return info and info.stackCount or 0
    else
        local _, count = GetContainerItemInfo(bag, slot)
        return count or 0
    end
end

local function BagCount(targetID)
    local total = 0
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local id = tonumber(link:match("item:(%d+)"))
                if id == targetID then
                    total = total + GetContainerItemCount(bag, slot)
                end
            end
        end
    end
    return total
end

----------------------------------------------------------------------
-- Tradeskill scanner — call with JC window open
----------------------------------------------------------------------
local function ScanJCTradeskill()
    local skillLine = GetTradeSkillLine()
    if not skillLine or not skillLine:find("Jewelcrafting") then
        print("|cFFFFD700Ore Advisor:|r Open your Jewelcrafting tradeskill window first, then hit Scan Tradeskill.")
        return 0
    end

    -- Clear old data
    OreAdvisorDB.knownCuts = {}
    local count = 0

    for i = 1, GetNumTradeSkills() do
        local _, recType = GetTradeSkillInfo(i)
        if recType ~= "header" then
            for r = 1, GetTradeSkillNumReagents(i) do
                local reagentLink = GetTradeSkillReagentItemLink(i, r)
                if reagentLink then
                    local reagentID = tonumber(reagentLink:match("item:(%d+)"))
                    if reagentID and ALL_CUTS[reagentID] then
                        local outputLink = GetTradeSkillItemLink(i)
                        if outputLink then
                            local outputID   = tonumber(outputLink:match("item:(%d+)"))
                            local outputName = GetItemInfo(outputLink) or "Unknown"
                            local prefix     = outputName:match("^(%a+)") or ""
                            local stat       = CUT_STATS[prefix] or "?"
                            if not OreAdvisorDB.knownCuts[reagentID] then
                                OreAdvisorDB.knownCuts[reagentID] = {}
                            end
                            -- Update the id in ALL_CUTS so TSM can price it
                            for _, cut in ipairs(ALL_CUTS[reagentID]) do
                                if cut.name == outputName then
                                    cut.id = outputID
                                end
                            end
                            table.insert(OreAdvisorDB.knownCuts[reagentID], {
                                name = outputName,
                                id   = outputID,
                                stat = stat,
                            })
                            count = count + 1
                        end
                    end
                end
            end
        end
    end

    print(string.format("|cFFFFD700Ore Advisor:|r Learned |cFF00FF00%d|r gem cuts.", count))
    return count
end

----------------------------------------------------------------------
-- Gem recommendation logic
----------------------------------------------------------------------
local function BestCut(rawGemID)
    local cuts = ALL_CUTS[rawGemID]
    if not cuts then return nil end

    local known = OreAdvisorDB.knownCuts[rawGemID] or {}
    local knownNames = {}
    for _, k in ipairs(known) do knownNames[k.name] = k end

    local bestCut, bestPrice, bestKnown = nil, -1, false

    for _, cut in ipairs(cuts) do
        local price = TSMGold(cut.id)
        local isKnown = (knownNames[cut.name] ~= nil)
        if price and price > bestPrice then
            bestCut   = cut
            bestPrice = price
            bestKnown = isKnown
        elseif not price and not bestCut then
            -- No pricing data but show it anyway so player knows it exists
            bestCut   = cut
            bestPrice = 0
            bestKnown = isKnown
        end
    end

    return bestCut, bestPrice, bestKnown
end

----------------------------------------------------------------------
-- Ore recommendation logic
----------------------------------------------------------------------
local function CalcOre(ore, qty, eterniumQty)
    local oreMarket = TSMGold(ore.oreID, "DBMarket")
    local oreMin    = TSMGold(ore.oreID, "DBMinBuyout")
    local barMarket = TSMGold(ore.barID, "DBMarket")

    local rawG    = oreMarket and (qty * oreMarket)                   or nil
    local smeltG  = barMarket and ((qty / ore.barRatio) * barMarket)  or nil
    local prospG  = nil
    local hardenG = nil
    local felsteelG = nil

    local prospUsedCuts = false
    if ore.canProspect then
        -- Use best cut price per gem if JC data available, else fall back to raw
        local function BestGemValue(gemID)
            local rawP = TSMGold(gemID)
            local cuts = ALL_CUTS[gemID]
            if cuts then
                local bestCutP = -1
                for _, cut in ipairs(cuts) do
                    local cp = TSMGold(cut.id)
                    if cp and cp > bestCutP then bestCutP = cp end
                end
                if bestCutP > 0 and bestCutP > (rawP or 0) then
                    prospUsedCuts = true
                    return bestCutP
                end
            end
            return rawP
        end

        local function AvgBestValue(ids)
            local sum, n = 0, 0
            for _, id in ipairs(ids) do
                local v = BestGemValue(id)
                if v then sum = sum + v; n = n + 1 end
            end
            return n > 0 and (sum / n) or nil
        end

        local cP = AvgBestValue(COMMON_GEM_IDS)
        local rP = AvgBestValue(RARE_GEM_IDS)
        if cP or rP then
            local prospects = qty / 5
            prospG = prospects * ore.commonsPerPro * (cP or 0)
                   + prospects * ore.raresPerPro   * (rP or 0)
        end
    end

    if ore.hardenedBarID and barMarket then
        local hP = TSMGold(ore.hardenedBarID)
        if hP then
            hardenG = ((qty / ore.barRatio) / ore.barsPerHardened) * hP
        end
    end

    if ore.oreID == 23424 and eterniumQty and eterniumQty > 0 then
        local fsP  = TSMGold(23448)
        local etbP = TSMGold(23447)
        if fsP and barMarket and etbP then
            local fiBars  = qty / ore.barRatio
            local etBars  = eterniumQty / 2
            local maxFS   = math.floor(math.min(fiBars / 3, etBars / 2))
            if maxFS > 0 then
                felsteelG = maxFS * fsP
                          + (fiBars - maxFS * 3) * barMarket
                          + (etBars - maxFS * 2) * etbP
            end
        end
    end

    local holdSignal = oreMarket and oreMin and (oreMin < oreMarket * 0.75)

    -- Prospect must beat smelt (or raw if no smelt) by 20% to be worth the variance
    local PROSPECT_THRESHOLD = 1.20
    local prospBaseline = smeltG or rawG
    local prospClears = prospG and prospBaseline
        and (prospG > prospBaseline * PROSPECT_THRESHOLD)
    local prospNearMiss = prospG and prospBaseline
        and (prospG > prospBaseline) and not prospClears

    local best, bestG = nil, -1
    if rawG      and rawG      > bestG then best = "SELL RAW";         bestG = rawG      end
    if smeltG    and smeltG    > bestG then best = "SMELT";            bestG = smeltG    end
    if prospClears then
        if prospG > bestG then
            best  = prospUsedCuts and "PROSPECT+CUT" or "PROSPECT"
            bestG = prospG
        end
    end
    if hardenG   and hardenG   > bestG then best = "HARDEN";           bestG = hardenG   end
    if felsteelG and felsteelG > bestG then best = "CRAFT FELSTEEL";   bestG = felsteelG end

    return {
        best=best, bestG=bestG,
        raw=rawG, smelt=smeltG, prospect=prospG,
        harden=hardenG, felsteel=felsteelG,
        prospUsedCuts=prospUsedCuts,
        prospNearMiss=prospNearMiss,
        holdSignal=holdSignal,
        hasData=(rawG~=nil or smeltG~=nil or prospG~=nil or hardenG~=nil),
    }
end

----------------------------------------------------------------------
-- Main frame
----------------------------------------------------------------------
local f = CreateFrame("Frame", "OreAdvisorFrame", UIParent, "BasicFrameTemplateWithInset")
f:SetSize(370, 460)
f:SetPoint("CENTER")
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop",  f.StopMovingOrSizing)
f:SetToplevel(true)
f:Hide()
f.TitleText:SetText("Ore Advisor")
table.insert(UISpecialFrames, "OreAdvisorFrame")

-- TSM status label
local tsmLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
tsmLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -58)

----------------------------------------------------------------------
-- Tab buttons
----------------------------------------------------------------------
local activePanel = "ore"

local oreTabBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
oreTabBtn:SetSize(80, 24)
oreTabBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -32)
oreTabBtn:SetText("Ore")

local gemTabBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
gemTabBtn:SetSize(80, 24)
gemTabBtn:SetPoint("TOPLEFT", oreTabBtn, "TOPRIGHT", 4, 0)
gemTabBtn:SetText("Gems")

-- Action button (changes label based on active panel)
local actionBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
actionBtn:SetSize(120, 24)
actionBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -36, -32)

----------------------------------------------------------------------
-- Ore panel
----------------------------------------------------------------------
local orePanel = CreateFrame("Frame", nil, f)
orePanel:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -74)
orePanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 10)

local noOreText = orePanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
noOreText:SetPoint("CENTER", orePanel, "CENTER", 0, 0)
noOreText:SetText("|cFF888888No ore found in bags.\nHit Scan Bags to check.|r")
noOreText:Hide()

local oreRows = {}
local ORE_ROW_H = 94

for i = 1, 4 do
    local yOff = -6 - (i - 1) * ORE_ROW_H
    local row = {}

    if i > 1 then
        local div = orePanel:CreateTexture(nil, "ARTWORK")
        div:SetHeight(1)
        div:SetPoint("TOPLEFT",  orePanel, "TOPLEFT",  14, yOff + 8)
        div:SetPoint("TOPRIGHT", orePanel, "TOPRIGHT", -14, yOff + 8)
        div:SetColorTexture(0.3, 0.3, 0.3, 0.6)
        row.div = div
    end

    row.header = orePanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.header:SetPoint("TOPLEFT", orePanel, "TOPLEFT", 14, yOff)

    row.reco = orePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    row.reco:SetPoint("TOPLEFT", orePanel, "TOPLEFT", 14, yOff - 20)

    row.detail = orePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.detail:SetPoint("TOPLEFT", orePanel, "TOPLEFT", 14, yOff - 42)
    row.detail:SetWidth(340)

    row.hold = orePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.hold:SetPoint("TOPLEFT", orePanel, "TOPLEFT", 14, yOff - 62)

    oreRows[i] = row
end

local function HideOreRow(row)
    row.header:SetText("") row.reco:SetText("")
    row.detail:SetText("") row.hold:SetText("")
    if row.div then row.div:Hide() end
end

local function ShowOreRow(row, ore, qty, r)
    if row.div then row.div:Show() end
    row.header:SetText(string.format("%s  |cFFAAAAAA%d ore (%.1f stacks)|r",
        ore.oreName, qty, qty / 20))
    if not r.hasData then
        row.reco:SetText("|cFFFF4444No TSM data — run an AH scan first|r")
        row.detail:SetText("") row.hold:SetText("") return
    end
    local col = {["SELL RAW"]="|cFFFF9900",["SMELT"]="|cFF88BBFF",
                 ["PROSPECT"]="|cFF00FF88",["PROSPECT+CUT"]="|cFF00FF88",
                 ["HARDEN"]="|cFFCC88FF",["CRAFT FELSTEEL"]="|cFFFFDD44"}
    row.reco:SetText(string.format("%s%s|r  |cFFFFD700%.1fg|r",
        col[r.best] or "|cFFFFFFFF", r.best or "?", r.bestG))
    local parts = {}
    if r.raw      then table.insert(parts,"Raw: "     ..string.format("%.1f",r.raw)     .."g") end
    if r.smelt    then table.insert(parts,"Smelt: "   ..string.format("%.1f",r.smelt)   .."g") end
    if r.prospect then
        local pLabel = r.prospUsedCuts and "Prospect+Cut: " or "Prospect (raw gems): "
        table.insert(parts, pLabel..string.format("%.1f",r.prospect).."g")
    end
    if r.harden   then table.insert(parts,"Harden: "  ..string.format("%.1f",r.harden)  .."g") end
    if r.felsteel then table.insert(parts,"Felsteel: "..string.format("%.1f",r.felsteel).."g") end
    row.detail:SetText("|cFF888888"..table.concat(parts,"  |  ").."|r")

    local notices = {}
    if r.holdSignal then
        table.insert(notices, "|cFFFFD700!! Spot price depressed — consider holding|r")
    end
    if r.prospNearMiss then
        local pLabel = r.prospUsedCuts and "Prospect+Cut" or "Prospect"
        local baseline = r.smelt or r.raw or 0
        local pct = baseline > 0 and ((r.prospect / baseline - 1) * 100) or 0
        table.insert(notices, string.format(
            "|cFFAAAAAA%s beats baseline by %.0f%% (need 20%% — smelt instead)|r",
            pLabel, pct))
    end
    row.hold:SetText(table.concat(notices, "  "))
end

----------------------------------------------------------------------
-- Gem panel (with scroll)
----------------------------------------------------------------------
local gemPanel = CreateFrame("Frame", nil, f)
gemPanel:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -74)
gemPanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 10)
gemPanel:Hide()

local noGemText = gemPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
noGemText:SetPoint("CENTER", gemPanel, "CENTER", 0, 20)
noGemText:SetText("|cFF888888No raw gems found in bags.\nHit Scan Bags to check.|r")
noGemText:Hide()

-- ScrollFrame sits above the bottom button bar
local gemScroll = CreateFrame("ScrollFrame", "OreAdvisorGemScroll", gemPanel, "UIPanelScrollFrameTemplate")
gemScroll:SetPoint("TOPLEFT",     gemPanel, "TOPLEFT",      4,   -4)
gemScroll:SetPoint("BOTTOMRIGHT", gemPanel, "BOTTOMRIGHT", -26,  58)

local gemContent = CreateFrame("Frame", nil, gemScroll)
gemContent:SetWidth(gemScroll:GetWidth() - 8)
gemScroll:SetScrollChild(gemContent)

local gemRows = {}
local GEM_ROW_H = 64
local ALL_RAW_GEM_IDS = {23077,23079,23107,23112,23117,21929,23436,23437,23438,23439,23440,23441}

for i = 1, 12 do
    local yOff = -6 - (i - 1) * GEM_ROW_H
    local row = {}

    if i > 1 then
        local div = gemContent:CreateTexture(nil, "ARTWORK")
        div:SetHeight(1)
        div:SetPoint("TOPLEFT",  gemContent, "TOPLEFT",  10, yOff + 6)
        div:SetPoint("TOPRIGHT", gemContent, "TOPRIGHT", -4, yOff + 6)
        div:SetColorTexture(0.3, 0.3, 0.3, 0.6)
        row.div = div
    end

    row.header = gemContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.header:SetPoint("TOPLEFT", gemContent, "TOPLEFT", 10, yOff)

    row.reco = gemContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.reco:SetPoint("TOPLEFT", gemContent, "TOPLEFT", 10, yOff - 18)
    row.reco:SetWidth(320)

    row.detail = gemContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.detail:SetPoint("TOPLEFT", gemContent, "TOPLEFT", 10, yOff - 36)
    row.detail:SetWidth(320)

    gemRows[i] = row
end

-- Set content height to fit all rows
gemContent:SetHeight(GEM_ROW_H * 12 + 12)

local function HideGemRow(row)
    row.header:SetText("") row.reco:SetText("") row.detail:SetText("")
    if row.div then row.div:Hide() end
end

local function ShowGemRow(row, gemID, qty)
    if row.div then row.div:Show() end

    local gemInfo = {
        [23077]="Blood Garnet",[23079]="Deep Peridot",[23107]="Shadow Draenite",
        [23112]="Golden Draenite",[23117]="Azure Moonstone",[21929]="Flame Spessarite",
        [23436]="Living Ruby",[23437]="Talasite",[23438]="Star of Elune",
        [23439]="Noble Topaz",[23440]="Dawnstone",[23441]="Nightseye",
    }
    local isRare = gemID >= 23436
    local rarity = isRare and "|cFFFF8000" or "|cFFFFFFFF"
    row.header:SetText(string.format("%s%s|r  |cFFAAAAAA x%d|r", rarity, gemInfo[gemID] or "Unknown Gem", qty))

    local rawPrice = TSMGold(gemID)
    local bestCut, bestPrice, isKnown = BestCut(gemID)

    local recoStr, detailStr = "", ""

    if bestCut and bestPrice > 0 then
        local knownTag = isKnown
            and "|cFF00FF00[known]|r"
            or  "|cFFFF4444[pattern needed]|r"
        local rawStr = rawPrice and string.format("%.1fg", rawPrice) or "?"
        local profit = rawPrice and (bestPrice - rawPrice) or 0

        if bestPrice > (rawPrice or 0) then
            recoStr = string.format("|cFF00FF88CUT|r  %s %s  %s  |cFFFFD700+%.1fg vs raw|r",
                bestCut.name, bestCut.stat, knownTag, profit)
        else
            recoStr = string.format("|cFFFF9900SELL RAW|r  %.1fg  (best cut: %s %s %s  %.1fg)",
                rawPrice or 0, bestCut.name, bestCut.stat, knownTag, bestPrice)
        end
        detailStr = string.format("|cFF888888Raw: %s  |  Best cut: %.1fg|r", rawStr, bestPrice)

    elseif bestCut and bestPrice == 0 then
        -- We know the cuts exist but can't price them
        local knownTag = isKnown and "|cFF00FF00[known]|r" or "|cFFFF4444[pattern needed]|r"
        recoStr = string.format("|cFFFFDD44UNPRICED|r  %s %s  %s",
            bestCut.name, bestCut.stat, knownTag)
        detailStr = "|cFF888888No TSM data for cuts — run an AH scan|r"

    elseif rawPrice then
        recoStr  = string.format("|cFFFF9900SELL RAW|r  %.1fg  (no cut data)", rawPrice)
        detailStr = "|cFF888888Open JC window and hit Scan Tradeskill to load cuts|r"
    else
        recoStr  = "|cFFFF4444No TSM data|r"
        detailStr = "|cFF888888Run an AH scan first|r"
    end

    row.reco:SetText(recoStr)
    row.detail:SetText(detailStr)
end

----------------------------------------------------------------------
-- Scan functions
----------------------------------------------------------------------
local function DoScanOre()
    tsmLabel:SetText(TSM_API and "|cFF00FF00TSM connected|r" or "|cFFFF4444TSM not found|r")
    noOreText:Hide()
    for i=1,4 do HideOreRow(oreRows[i]) end
    local eterniumQty = BagCount(23427)
    local found = {}
    for _, ore in ipairs(ORES) do
        local qty = BagCount(ore.oreID)
        if qty > 0 then table.insert(found, {ore=ore, qty=qty}) end
    end
    if #found == 0 then noOreText:Show(); return end
    for i, entry in ipairs(found) do
        if oreRows[i] then
            ShowOreRow(oreRows[i], entry.ore, entry.qty, CalcOre(entry.ore, entry.qty, eterniumQty))
        end
    end
end

local function ScanOre()
    C_Timer.After(0, DoScanOre)
end

local function DoScanGems()
    tsmLabel:SetText(TSM_API and "|cFF00FF00TSM connected|r" or "|cFFFF4444TSM not found|r")
    noGemText:Hide()
    for i=1,12 do HideGemRow(gemRows[i]) end
    local found = {}
    for _, id in ipairs(ALL_RAW_GEM_IDS) do
        local qty = BagCount(id)
        if qty > 0 then table.insert(found, {id=id, qty=qty}) end
    end
    if #found == 0 then noGemText:Show(); return end
    for i, entry in ipairs(found) do
        if gemRows[i] then ShowGemRow(gemRows[i], entry.id, entry.qty) end
    end
end

local function ScanGems()
    C_Timer.After(0, DoScanGems)
end

----------------------------------------------------------------------
-- Tab switching
----------------------------------------------------------------------
local function ShowOrePanel()
    activePanel = "ore"
    orePanel:Show(); gemPanel:Hide()
    actionBtn:SetText("Scan Bags")
    oreTabBtn:LockHighlight(); gemTabBtn:UnlockHighlight()
end

local function ShowGemPanel()
    activePanel = "gems"
    orePanel:Hide(); gemPanel:Show()
    actionBtn:SetText("Scan Bags")
    gemTabBtn:LockHighlight(); oreTabBtn:UnlockHighlight()
end

oreTabBtn:SetScript("OnClick", function() ShowOrePanel(); ScanOre() end)
gemTabBtn:SetScript("OnClick", function() ShowGemPanel(); ScanGems() end)

actionBtn:SetScript("OnClick", function()
    if activePanel == "ore" then ScanOre()
    else ScanGems() end
end)

f:SetScript("OnShow", function()
    tsmLabel:SetText(TSM_API and "|cFF00FF00TSM connected|r" or "|cFFFF4444TSM not found|r")
    -- Auto-detect professions to pick starting panel
    local hasJC, hasMining = false, false
    for i = 1, GetNumSkillLines() do
        local name = GetSkillLineInfo(i)
        if name then
            if name:find("Jewelcrafting") then hasJC = true end
            if name:find("Mining")        then hasMining = true end
        end
    end
    if hasJC and not hasMining then
        ShowGemPanel(); ScanGems()
    else
        ShowOrePanel(); ScanOre()
    end
end)

----------------------------------------------------------------------
-- Gem panel footer buttons
----------------------------------------------------------------------
-- Scan Tradeskill button — left of bottom bar
local scanTSBtn = CreateFrame("Button", nil, gemPanel, "UIPanelButtonTemplate")
scanTSBtn:SetSize(140, 24)
scanTSBtn:SetPoint("BOTTOMLEFT", gemPanel, "BOTTOMLEFT", 14, 10)
scanTSBtn:SetText("Scan Tradeskill")
scanTSBtn:SetScript("OnClick", function()
    local n = ScanJCTradeskill()
    if n > 0 then ScanGems() end
end)

-- Hint text — right of button
local scanHintText = gemPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
scanHintText:SetPoint("LEFT",  scanTSBtn, "RIGHT", 8, 0)
scanHintText:SetPoint("RIGHT", gemPanel,  "RIGHT", -14, 0)
scanHintText:SetText("|cFFAAAAAA Open JC window first|r")

----------------------------------------------------------------------
-- Slash commands
----------------------------------------------------------------------
SLASH_OREADVISOR1 = "/oa"
SLASH_OREADVISOR2 = "/oreadvisor"
SlashCmdList["OREADVISOR"] = function(msg)
    if msg == "gems" then
        f:Show(); ShowGemPanel(); ScanGems()
    elseif msg == "ore" then
        f:Show(); ShowOrePanel(); ScanOre()
    else
        if f:IsShown() then f:Hide() else f:Show() end
    end
end

ShowOrePanel()
-- Wait for saved variables to be loaded from disk before rehydrating
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "OreAdvisor" then
        OreAdvisorDB = OreAdvisorDB or {}
        OreAdvisorDB.knownCuts = OreAdvisorDB.knownCuts or {}
        RehydrateCutIDs()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

print("|cFFFFD700Ore Advisor|r loaded — |cFF00FFFF/oa|r to open  |  |cFF00FFFF/oa ore|r  |cFF00FFFF/oa gems|r")
