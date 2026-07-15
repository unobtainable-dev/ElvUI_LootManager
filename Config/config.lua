local E, L, V, P, G = unpack(ElvUI);
local tinsert = table.insert
local ACR = LibStub('AceConfigRegistry-3.0') 
local ELM = E:GetModule('LootManager')

-- ============================================================================
-- COLOR PALETTES FOR HEADERS
-- ============================================================================
local SilverColors = {"FFFFFF", "999999"}
local NeedColors = {"FF3333", "FF8800"}
local BoEColors = {"FFD700", "FFFFFF", "FFD700"} -- Gold White Gold
local DiscordColors = {"5865F2", "FFFFFF"} 
local MLHeaderColors = {"FFD700", "B8860B", "FFFFFF", "FFD700", "B76E79"} 
local RemoveColors = {"FF8C00", "CC5500", "FFBF00"} 
local ClearColors = {"FF0800", "DE3163", "DC143C", "FF2400"} 
local AddonColors = {"1784d1", "00CCFF", "A335EE", "F06F85"} 

local function GetItemName(id)
    local name, _, rarity = GetItemInfo(id)
    if name then
        local rarityColor = ITEM_QUALITY_COLORS[rarity or 1].hex or "|cffffffff"
        return format("%s%s|r [ID: %s]", rarityColor, name, id)
    end
    -- Return a plain ID string if not cached yet
    return format("ID: %s", id)
end

-- Use our internal gradient engine instead of GradientLib
local PluginTitle = ELM:Gradient("ElvUI Loot Manager", AddonColors)

local function GetDiscordHeader()
    local icon = "|TInterface\\FriendsFrame\\UI-Toast-ChatInviteIcon:16:16:0:0|t"
    return icon .. " " .. ELM:Gradient("Support & Community", DiscordColors)
end

-- ============================================================================
-- TITLE GENERATOR
-- ============================================================================
local PluginTitle = "|cff1784d1E|cff3399d1l|cff4daed1v|cff66c3d1U|cff80d8d1I|r |cff00CCFFLoo|cff5A8CEET|cffA335EEMana|cffD858C7ge|cffF06F85r|r"

-- Fallback to apply a solid color from the palettes above instead of gradients
local function Colorize(text, colors)
    return format("|cff%s%s|r", colors[1], text)
end
local function Options(ELM)
    E.Options.args.lootmanager = { 
        order = 8000,
        type = 'group',
        name = PluginTitle,
        get = function(info) return E.LootManager.Global[info[#info]] end,
        set = function(info, value) E.LootManager.Global[info[#info]] = value end,
        
        args = {
            header = { order = 1, type = 'header', name = PluginTitle },
			logo = {
				order = 2,
				type = "description",
				name = "",
				width = 0.8,
				image = function() 
					return "Interface\\AddOns\\ElvUI_LootManager\\Media\\UI-Logo-Big1", 161, 161 
				end,
			},
			credits = { 
				order = 3, 
				type = 'description', 
				fontSize = 'large',
				width = 2.4,
				name = "\n" .. 
					"    Automated Group Loot & Master Looter tool" ..
					"\n" ..
					"    by |cfff58cbaUn|cffff9566ob|cffff9f4dta|cffffa933in|cffffb31aab|cffffd700le|r",
			}, 
            general = {
                order = 3, type = 'group', 
                name = " ", 
                guiInline = true,
                args = {
                    header = { order = 0, type = 'header', name = ELM:Gradient('Group Loot Settings', SilverColors) },
                    enabled = { order = 1, type = 'toggle', width = 1.5, name = 'Enable Module' },
                    disablePopups = { 
                        order = 2, type = 'toggle', width = 1.5, name = 'Auto Confirm Popups',
                        disabled = function() return not E.LootManager.Global.enabled end
                    },
                    enableNeedList = { 
                        order = 3, type = 'toggle', width = 1.5, name = 'Enable Need List',
                        desc = 'Toggle the Need List functionality on/off.',
                        get = function() return E.LootManager.Global.enableNeedList end,
                        set = function(_, val) E.LootManager.Global.enableNeedList = val end,
                        disabled = function() return not E.LootManager.Global.enabled end
                    },
                    rollEpicBoE = { 
                        order = 4, type = 'toggle', width = 1.5, name = 'Auto Need Epic BoE',
                        disabled = function() return not E.LootManager.Global.enabled end
                    },
                    autoGreed = { 
                        order = 5, type = 'toggle', width = 1.5, name = 'Auto Greed - Green-Blue',
                        disabled = function() return not E.LootManager.Global.enabled end
                    },
                    autoDe = { 
                        order = 6, type = 'toggle', width = 1.5, name = 'Auto DE (Priority over Greed)', 
                        disabled = function() return not E.LootManager.Global.enabled or not E.LootManager.Global.autoGreed end 
                    },
                },
            },
            needListGroup = {
                order = 4, type = 'group', 
                name = " ", 
                guiInline = true,
                args = {
                    header = { order = 0, type = 'header', name = ELM:Gradient('NEED LIST (Account Wide)', NeedColors) },
                    
                    desc = { order = 1, type = 'description', fontSize = 'medium', name = 'Items added here will always be NEED rolled.', width = 'full' },
                    
                    spacer_desc = { order = 1.5, type = 'description', name = ' ', width = 'full' },

                    inputID = {
                        order = 2, type = 'input', name = 'Add Item ID',
                        dialogControl = "ELM_Input", 
                        width = 0.8,  
                        get = function() return "" end,
						set = function(_, val)
							local id = tonumber(val)
							if id and id >= 17 and id <= 56806 then
								local itemName = GetItemName(id)
								if itemName then
									E.LootManager.Global.needList[id] = itemName
									ELM:PrintAction("Need List", "Added", itemName)
								else
									local ghost = "|cff808080[Unknown Item]|r [ID: "..id.."]"
									E.LootManager.Global.needList[id] = ghost
									ELM:Console("|cffffff00Warning:|r Item "..id.." added to database (Pending Cache).")
								end
								ACR:NotifyChange("ElvUI")
							else
								ELM:Console("|cffff0000Invalid ID:|r Please enter a correct ItemID.")
							end
						end
                    },                  
					removeSelect = {
						order = 3, type = 'select', name = 'Select to Remove',
						dialogControl = "ELM_ScrollSelect", 
						width = 2.2, 
values = function()
    local t = {} 
    -- Change 'needList' to 'boeList' for the other dropdown
    for id, storedName in pairs(E.LootManager.Global.needList) do 
        local currentName = GetItemName(id)
        
        -- If the name is now in cache and isn't just the ID placeholder
        if currentName and not currentName:find("^ID: ") then
            -- Update the database permanently
            E.LootManager.Global.needList[id] = currentName
            t[id] = currentName
        else
            t[id] = storedName 
        end
    end 
    
    if next(t) == nil then t["empty"] = "List Empty" end
    return t 
end,
						get = function()
							if not next(E.LootManager.Global.needList) then 
								return "empty" 
							end
							return selectedNeedItem 
						end,
						set = function(_, val) 
							if val ~= "empty" then 
								selectedNeedItem = val 
							end 
						end,
					},
                    removeButton = {
                        order = 4, type = 'execute', 
                        name = ELM:Gradient("Remove", RemoveColors), 
                        width = 0.6,
                        dialogControl = "ELM_Button",
                        func = function()
                            if selectedNeedItem and selectedNeedItem ~= 0 then
                                local name = E.LootManager.Global.needList[selectedNeedItem]
                                if name then
                                    E.LootManager.Global.needList[selectedNeedItem] = nil
                                    ELM:PrintAction("Need List", "Removed", name)
                                    selectedNeedItem = nil
                                    ACR:NotifyChange("ElvUI")
                                end
                            end
                        end
                    },
                },
            },
            
            mlGroup = {
                order = 5,
                type = 'group',
                name = " ", 
                guiInline = true,
                args = {
                    header = { order = 0, type = 'header', name = ELM:Gradient('Master Looter Options', MLHeaderColors), width = 'full' },
                    hideBlizzardLootMessages = {
                        order = 0.5, type = 'toggle', width = 'full', 
                        name = "Hide Blizzard Master Loot Messages",
                        desc = "Suppress default 'Player receives loot' chat messages while you are Master Looter.",
                        get = function() return E.LootManager.Global.hideBlizzardLootMessages end,
                        set = function(_, val) E.LootManager.Global.hideBlizzardLootMessages = val end,
                    },
                    
                    -- GREEN / BLUE
                    desc_greenblue = {
                        order = 0.6, type = 'description', width = 'full', fontSize = 'large',
                        name = "|cff1eff00G|rreen - |cff0070ddB|rlue"
                    },
                    ml_greenblue = {
                        order = 1, type = 'input', width = 'full',
                        dialogControl = "ELM_Input_Clean", -- 30px
                        name = " ",
                        get = function() return E.LootManager.Global.ml_greenblue end,
                        set = function(info, value) E.LootManager.Global.ml_greenblue = strtrim(value) end
                    },
                    -- EPIC BOP
					desc_epicbop = {
                        order = 1.6, type = 'description', width = 'full', fontSize = 'large',
                        name = "|cffa335eeE|rpic BoP"
                    },
                    ml_epic_bop = {
                        order = 2, type = 'input', width = 'full',
                        dialogControl = "ELM_Input_Clean", -- 30px
                        name = " ",
                        get = function() return E.LootManager.Global.ml_epic_bop end,
                        set = function(info, value) E.LootManager.Global.ml_epic_bop = strtrim(value) end
                    },
                    -- LEGENDARY
					desc_legendary = {
                        order = 2.6, type = 'description', width = 'full', fontSize = 'large',
                        name = "|cffff8000L|regendary"
                    },
                    ml_legendary = {
                        order = 3, type = 'input', width = 'full',
                        dialogControl = "ELM_Input_Clean", -- 30px
                        name = " ",
                        get = function() return E.LootManager.Global.ml_legendary end,
                        set = function(info, value) E.LootManager.Global.ml_legendary = strtrim(value) end
                    },
                    -- RAID BOE
                    desc_customboe = {
                        order = 3.6, type = 'description', width = 'full', fontSize = 'large',
                        name = ELM:Gradient("Raid BoE", BoEColors)
                    },
                    ml_epic_boe = {
                        order = 4, type = 'input', width = 'full',
                        dialogControl = "ELM_Input_Clean", -- 30px
                        name = " ",
                        get = function() return E.LootManager.Global.ml_epic_boe end,
                        set = function(info, value) E.LootManager.Global.ml_epic_boe = strtrim(value) end
                    },
                    printList = {
                        order = 6, type = 'execute', 
                        name = ELM:Gradient("Print List", AddonColors),
                        width = 'full', 
                        dialogControl = "ELM_Button_Clean", -- 30px
                        func = function() ELM:PrintMasterLooterList() end
                    },
                },
            },
            boeListGroup = {
                order = 7, type = 'group',
                name = " ",
                guiInline = true,
                args = {
                    header = { order = 0, type = 'header', name = ELM:Gradient('RAID BOE LIST (Account Wide)', BoEColors) },
                    desc = { order = 1, type = 'description', fontSize = 'medium', name = 'Items added here will be given to the Raid BoE Receiver.', width = 'full' },
                    spacer_desc = { order = 1.5, type = 'description', name = ' ', width = 'full' },
                    boeInput = {
                        order = 2, type = 'input', name = 'Add BoE ID', 
                        dialogControl = "ELM_Input",
                        width = 0.8, 
                        get = function() return "" end,
						set = function(_, val)
							local id = tonumber(val)
							if id and id >= 17 and id <= 56806 then
								local itemName = GetItemName(id)
								if itemName then
									E.LootManager.Global.boeList[id] = itemName
									ELM:PrintAction("Raid BoE List", "Added", itemName)
								end
								ACR:NotifyChange("ElvUI")
							else
								ELM:Console("|cffff0000Invalid ID:|r Please enter a correct ItemID.")
							end
						end
                    },
					boeSelect = {
						order = 3, type = 'select', name = 'Select to Remove',
						dialogControl = "ELM_ScrollSelect", 
						width = 2.2, 
values = function()
    local t = {} 
    -- Change 'needList' to 'boeList' for the other dropdown
    for id, storedName in pairs(E.LootManager.Global.boeList) do 
        local currentName = GetItemName(id)
        
        -- If the name is now in cache and isn't just the ID placeholder
        if currentName and not currentName:find("^ID: ") then
            -- Update the database permanently
            E.LootManager.Global.boeList[id] = currentName
            t[id] = currentName
        else
            t[id] = storedName 
        end
    end 
    
    if next(t) == nil then t["empty"] = "List Empty" end
    return t 
end,
						get = function()
							if not next(E.LootManager.Global.boeList) then 
								return "empty" 
							end
							return selectedBoEItem 
						end,
						set = function(_, val) 
							if val ~= "empty" then 
								selectedBoEItem = val 
							end 
						end,
					},
                    boeButton = {
                        order = 4, type = 'execute', 
                        name = ELM:Gradient("Remove", RemoveColors),
                        width = 0.6 ,
                        dialogControl = "ELM_Button",
                        func = function()
                            if selectedBoEItem and selectedBoEItem ~= 0 then
                                local name = E.LootManager.Global.boeList[selectedBoEItem]
                                if name then
                                    E.LootManager.Global.boeList[selectedBoEItem] = nil
                                    ELM:PrintAction("Raid BoE List", "Removed", name)
                                    selectedBoEItem = nil
                                    ACR:NotifyChange("ElvUI")
                                end
                            end
                        end
                    },
                },
            },

            supportGroup = {
                order = 99, type = 'group', 
                name = Colorize(' ', DiscordColors), 
                guiInline = true,
                args = {
                    header = { order = 1, type = 'header', name = GetDiscordHeader() },
                    discordLink = {
                        order = 3, type = 'input', name = 'Discord Link (Copy)', width = 'full',
                        get = function() return "https://discord.gg/a9BCdEjhS" end,
                        set = function() end, 
                    },
                }
            }
        },
    }
end

tinsert(ELM.Config, Options)