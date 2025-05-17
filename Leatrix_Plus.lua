----------------------------------------------------------------------
-- 	Leatrix Plus 3.0.131 (10th May 2023)
----------------------------------------------------------------------

--	01:Functns, 02:Locks, 03:Restart, 20:Live, 30:Isolated, 40:Player
--	50:RunOnce, 60:Evnts, 62:Profile, 70:Lgot, 80:Commands, 90:Panel
--
----------------------------------------------------------------------
-- 	Leatrix Plus
----------------------------------------------------------------------

LibCompat = LibStub:GetLibrary("LibCompat-1.0")
-- Create global table
_G.LeaPlusDB = _G.LeaPlusDB or {}

-- Create locals
local LeaPlusLC, LeaPlusCB, LeaDropList, LeaConfigList, LeaLockList = {}, {}, {}, {}, {}
local ClientVersion = GetBuildInfo()
local GameLocale = GetLocale()
local void


--===== Check for if 3.3.5 or 2.4.3 game client. =====--
local isTBC = select(4, GetBuildInfo()) == 20400 -- true if TBC 2.4.3
local isWOTLK = select(4, GetBuildInfo()) == 30300 -- true if WOTLK 3.3.5
local isPastWOTLK = select(4, GetBuildInfo()) > 30300 -- true if more than 3.3.5 ala 4.3.4

-- Version
LeaPlusLC["AddonVer"] = "3.3.5"

-- Get locale table
local void, Leatrix_Plus = ...
local L = Leatrix_Plus.L

-- Check Wow version is valid
do
    local gameversion, gamebuild, gamedate, gametocversion = GetBuildInfo()
    if gametocversion and gametocversion < 30000 or gametocversion > 39999 then
        -- Game client is not Wow Classic
        LibCompat.After(2, function()
            print(L["LEATRIX PLUS: WRONG VERSION INSTALLED!"])
        end)
        return
    end
end

-- Check for addons
if IsAddOnLoaded("ElvUI") then
    LeaPlusLC.ElvUI = unpack(ElvUI)
end
if IsAddOnLoaded("Glass") then
    LeaPlusLC.Glass = true
end

----------------------------------------------------------------------
--	L00: Leatrix Plus
----------------------------------------------------------------------




-- Initialise variables
LeaPlusLC["ShowErrorsFlag"] = 1
LeaPlusLC["NumberOfPages"] = 9
LeaPlusLC["RaidColors"] = RAID_CLASS_COLORS

-- for class, color in pairs(RAID_CLASS_COLORS) do
-- 	print(class, color.r, color.g, color.b)
-- end


-- Create event frame
local LpEvt = CreateFrame("FRAME")
LpEvt:RegisterEvent("ADDON_LOADED")
LpEvt:RegisterEvent("PLAYER_LOGIN")
LpEvt:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Set bindings translations
_G.BINDING_HEADER_LEATRIX_PLUS = "Leatrix Plus"
_G.BINDING_NAME_LEATRIX_PLUS_GLOBAL_TOGGLE = L["Toggle panel"]
_G.BINDING_NAME_LEATRIX_PLUS_GLOBAL_WEBLINK = L["Show web link"]
_G.BINDING_NAME_LEATRIX_PLUS_GLOBAL_RARE = L["Announce rare"]

-- Slash command taint
-- Enter combat, enter any addon slash command, open quest log with L, toggle tracking on a quest 4 times,
-- click the tracked quest in the objective tracker, taint and objective tracker no longer functions

----------------------------------------------------------------------
--	L01: Functions
----------------------------------------------------------------------

-- Print text
function LeaPlusLC:Print(text)
    DEFAULT_CHAT_FRAME:AddMessage(L[text], 1.0, 0.85, 0.0)
end

-- Lock and unlock an item
function LeaPlusLC:LockItem(item, lock)
    if lock then
        item:Disable()
        item:SetAlpha(0.3)
    else
        item:Enable()
        item:SetAlpha(1.0)
    end
end

-- Hide configuration panels
function LeaPlusLC:HideConfigPanels()
    for k, v in pairs(LeaConfigList) do
        v:Hide()
    end
end

-- Decline a shared quest if needed
function LeaPlusLC:CheckIfQuestIsSharedAndShouldBeDeclined()
    if LeaPlusLC["NoSharedQuests"] == "On" then
        local npcName = UnitName("questnpc")
        if npcName then
            if UnitInParty(npcName) or UnitInRaid(npcName) then
                if not LeaPlusLC:FriendCheck(npcName) then
                    DeclineQuest()
                    return
                end
            end
        end
    end
end

-- Show a single line prefilled editbox with copy functionality
function LeaPlusLC:ShowSystemEditBox(word, focuschat)
    if not LeaPlusLC.FactoryEditBox then
        -- Create frame for first time
        local eFrame = CreateFrame("FRAME", nil, UIParent)
        LeaPlusLC.FactoryEditBox = eFrame
        eFrame:SetSize(700, 110)
        eFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
        eFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        -- eFrame:SetFrameLevel(5000)
        eFrame:EnableMouse(true)
        eFrame:EnableKeyboard()
        eFrame:SetScript("OnMouseDown", function(self, btn)
            if btn == "RightButton" then
                eFrame:Hide()
            end
        end)
        -- Add background color
        eFrame.t = eFrame:CreateTexture(nil, "BACKGROUND")
        eFrame.t:SetAllPoints()
        eFrame.t:SetTexture(0.05, 0.05, 0.05, 0.9)
        -- Add copy title
        eFrame.f = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
        eFrame.f:SetPoint("TOPLEFT", x, y)
        eFrame.f:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -52)
        eFrame.f:SetWidth(676)
        eFrame.f:SetJustifyH("LEFT")
        eFrame.f:SetWordWrap(false)
        -- Add copy label
        eFrame.c = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
        eFrame.c:SetPoint("TOPLEFT", x, y)
        eFrame.c:SetText(L["Press CTRL/C to copy"])
        eFrame.c:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -82)
        -- Add feedback label
        eFrame.x = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
        eFrame.x:SetPoint("TOPRIGHT", x, y)
        eFrame.x:SetText("|cff00ff00Feedback Discord:|r |cffadd8e6sattva108|r")

        eFrame.x:SetPoint("TOPRIGHT", eFrame, "TOPRIGHT", -12, -52)
        hooksecurefunc(eFrame.f, "SetText", function()
            eFrame.f:SetWidth(676 - eFrame.x:GetStringWidth() - 26)
        end)
        -- Add cancel label
        eFrame.x = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
        eFrame.x:SetPoint("TOPRIGHT", x, y)
        eFrame.x:SetText(L["Right-click to close"])
        eFrame.x:SetPoint("TOPRIGHT", eFrame, "TOPRIGHT", -12, -82)
        -- Create editbox
        eFrame.b = CreateFrame("EditBox", nil, eFrame, "InputBoxTemplate")
        eFrame.b:ClearAllPoints()
        eFrame.b:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 16, -12)
        eFrame.b:SetSize(672, 24)
        eFrame.b:SetFontObject("GameFontNormalLarge")
        eFrame.b:SetTextColor(1.0, 1.0, 1.0, 1)
        eFrame.b:DisableDrawLayer("BACKGROUND")
        -- eFrame.b:SetBlinkSpeed(0)
        eFrame.b:SetHitRectInsets(99, 99, 99, 99)
        eFrame.b:SetAutoFocus(true)
        eFrame.b:SetAltArrowKeyMode(true)
        eFrame.b:EnableMouse(true)
        eFrame.b:EnableKeyboard(true)
        -- Editbox texture
        eFrame.t = CreateFrame("FRAME", nil, eFrame.b)
        eFrame.t:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 } })
        eFrame.t:SetPoint("LEFT", -6, 0)
        eFrame.t:SetWidth(eFrame.b:GetWidth() + 6)
        eFrame.t:SetHeight(eFrame.b:GetHeight())
        eFrame.t:SetBackdropColor(1.0, 1.0, 1.0, 0.3)
        -- Handler
        -- it doesnt work in 3.3.5
        --eFrame.b:SetScript("OnKeyDown", function(void, key)
        --	if key == "c" and IsControlKeyDown() then
        --		LibCompat.After(0.1, function()
        --			eFrame:Hide()
        --			ActionStatus_DisplayMessage(L["Copied to clipboard."], true)
        --			if LeaPlusLC.FactoryEditBoxFocusChat then
        --				local eBox = ChatEdit_ChooseBoxForSend()
        --				ChatEdit_ActivateChat(eBox)
        --			end
        --		end)
        --	end
        --end)
        -- Prevent changes
        -- eFrame.b:SetScript("OnEscapePressed", function() eFrame:Hide() end)
        -- eFrame.b:SetScript("OnEnterPressed", eFrame.b.HighlightText)
        -- eFrame.b:SetScript("OnMouseDown", eFrame.b.ClearFocus)
        -- eFrame.b:SetScript("OnMouseUp", eFrame.b.HighlightText)
        eFrame.b:SetScript("OnChar", function()
            eFrame.b:SetText(word);
            eFrame.b:HighlightText();
        end);
        eFrame.b:SetScript("OnMouseUp", function()
            eFrame.b:HighlightText();
        end);
        eFrame.b:SetScript("OnEscapePressed", function()
            eFrame:Hide()
        end)
        eFrame.b:SetFocus(true)
        eFrame.b:HighlightText()
        eFrame:Show()
    end
    if focuschat then
        LeaPlusLC.FactoryEditBoxFocusChat = true
    else
        LeaPlusLC.FactoryEditBoxFocusChat = nil
    end
    LeaPlusLC.FactoryEditBox:Show()
    LeaPlusLC.FactoryEditBox.b:SetText(word)
    LeaPlusLC.FactoryEditBox.b:HighlightText()
    LeaPlusLC.FactoryEditBox.b:SetScript("OnChar", function(_, char)
        if char == 'w' or char == 'a' or char == 's' or char == 'd' then
            LeaPlusLC.FactoryEditBox:Hide()
            --LeaPlusLC.FactoryEditBox:SetFocus(false)
        end
        LeaPlusLC.FactoryEditBox.b:SetFocus(true)
        LeaPlusLC.FactoryEditBox.b:SetText(word)
        LeaPlusLC.FactoryEditBox.b:HighlightText()
    end)
    LeaPlusLC.FactoryEditBox.b:SetScript("OnKeyUp", function()
        LeaPlusLC.FactoryEditBox.b:SetFocus(true)
        LeaPlusLC.FactoryEditBox.b:SetText(word)
        LeaPlusLC.FactoryEditBox.b:HighlightText()
    end)
end

-- Load a string variable or set it to default if it's not set to "On" or "Off"
function LeaPlusLC:LoadVarChk(var, def)
    if LeaPlusDB[var] and type(LeaPlusDB[var]) == "string" and LeaPlusDB[var] == "On" or LeaPlusDB[var] == "Off" then
        LeaPlusLC[var] = LeaPlusDB[var]
    else
        LeaPlusLC[var] = def
        LeaPlusDB[var] = def
    end
end

-- Load a numeric variable and set it to default if it's not within a given range
function LeaPlusLC:LoadVarNum(var, def, valmin, valmax)
    if LeaPlusDB[var] and type(LeaPlusDB[var]) == "number" and LeaPlusDB[var] >= valmin and LeaPlusDB[var] <= valmax then
        LeaPlusLC[var] = LeaPlusDB[var]
    else
        LeaPlusLC[var] = def
        LeaPlusDB[var] = def
    end
end

-- Load an anchor point variable and set it to default if the anchor point is invalid
function LeaPlusLC:LoadVarAnc(var, def)
    if LeaPlusDB[var] and type(LeaPlusDB[var]) == "string" and LeaPlusDB[var] == "CENTER" or LeaPlusDB[var] == "TOP" or LeaPlusDB[var] == "BOTTOM" or LeaPlusDB[var] == "LEFT" or LeaPlusDB[var] == "RIGHT" or LeaPlusDB[var] == "TOPLEFT" or LeaPlusDB[var] == "TOPRIGHT" or LeaPlusDB[var] == "BOTTOMLEFT" or LeaPlusDB[var] == "BOTTOMRIGHT" then
        LeaPlusLC[var] = LeaPlusDB[var]
    else
        LeaPlusLC[var] = def
        LeaPlusDB[var] = def
    end
end

-- Load a string variable and set it to default if it is not a string (used with minimap exclude list)
function LeaPlusLC:LoadVarStr(var, def)
    if LeaPlusDB[var] and type(LeaPlusDB[var]) == "string" then
        LeaPlusLC[var] = LeaPlusDB[var]
    else
        LeaPlusLC[var] = def
        LeaPlusDB[var] = def
    end
end

-- Show tooltips for checkboxes
function LeaPlusLC:TipSee()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    local parent = self:GetParent()
    local pscale = parent:GetEffectiveScale()
    local gscale = UIParent:GetEffectiveScale()
    local tscale = GameTooltip:GetEffectiveScale()
    local gap = ((UIParent:GetRight() * gscale) - (parent:GetRight() * pscale))
    if gap < (250 * tscale) then
        GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
    else
        GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
    end
    GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
end

-- Show tooltips for dropdown menu tooltips
function LeaPlusLC:ShowDropTip()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    local parent = self:GetParent():GetParent():GetParent()
    local pscale = parent:GetEffectiveScale()
    local gscale = UIParent:GetEffectiveScale()
    local tscale = GameTooltip:GetEffectiveScale()
    local gap = ((UIParent:GetRight() * gscale) - (parent:GetRight() * pscale))
    if gap < (250 * tscale) then
        GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
    else
        GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
    end
    GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
end

-- Show tooltips for configuration buttons and dropdown menus
function LeaPlusLC:ShowTooltip()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    local parent = LeaPlusLC["PageF"]
    local pscale = parent:GetEffectiveScale()
    local gscale = UIParent:GetEffectiveScale()
    local tscale = GameTooltip:GetEffectiveScale()
    local gap = ((UIParent:GetRight() * gscale) - (LeaPlusLC["PageF"]:GetRight() * pscale))
    if gap < (250 * tscale) then
        GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
    else
        GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
    end
    GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
end

-- Create configuration button
function LeaPlusLC:CfgBtn(name, parent)
    local CfgBtn = CreateFrame("BUTTON", nil, parent)
    LeaPlusCB[name] = CfgBtn
    CfgBtn:SetWidth(20)
    CfgBtn:SetHeight(20)
    CfgBtn:SetPoint("LEFT", parent.f, "RIGHT", 0, 0)

    CfgBtn.t = CfgBtn:CreateTexture(nil, "BORDER")
    CfgBtn.t:SetAllPoints()
    CfgBtn.t:SetTexture("Interface\\WorldMap\\Gear_64.png")
    CfgBtn.t:SetTexCoord(0, 0.50, 0, 0.50);
    CfgBtn.t:SetVertexColor(1.0, 0.82, 0, 1.0)

    CfgBtn:SetHighlightTexture("Interface\\WorldMap\\Gear_64.png")
    CfgBtn:GetHighlightTexture():SetTexCoord(0, 0.50, 0, 0.50);

    CfgBtn.tiptext = L["Click to configure the settings for this option."]
    CfgBtn:SetScript("OnEnter", LeaPlusLC.ShowTooltip)
    CfgBtn:SetScript("OnLeave", GameTooltip_Hide)
end

-- Create a help button to the right of a fontstring
function LeaPlusLC:CreateHelpButton(frame, panel, parent, tip)
    LeaPlusLC:CfgBtn(frame, panel)
    LeaPlusCB[frame]:ClearAllPoints()
    LeaPlusCB[frame]:SetPoint("LEFT", parent, "RIGHT", -parent:GetWidth() + parent:GetStringWidth(), 0)
    LeaPlusCB[frame]:SetSize(25, 25)
    LeaPlusCB[frame].t:SetTexture("Interface\\COMMON\\help-i.blp")
    LeaPlusCB[frame].t:SetTexCoord(0, 1, 0, 1)
    LeaPlusCB[frame].t:SetVertexColor(0.9, 0.8, 0.0)
    LeaPlusCB[frame]:SetHighlightTexture("Interface\\COMMON\\help-i.blp")
    LeaPlusCB[frame]:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
    LeaPlusCB[frame].tiptext = L[tip]
    LeaPlusCB[frame]:SetScript("OnEnter", LeaPlusLC.TipSee)
end

-- Frame Stack Function Toggle
local function toggleFrameStack(msg)
    UIParentLoadAddOn("Blizzard_DebugTools")
    if msg == tostring(true) then
        FrameStackTooltip_Toggle(true)
    else
        FrameStackTooltip_Toggle()
    end
end

SLASH_FRAMESTACK1 = "/fs"
SlashCmdList["FRAMESTACK"] = toggleFrameStack

-- Create a FrameStack button
function LeaPlusLC:CreateFrameStackButton(frame, panel, parent, tip)
    LeaPlusLC:CfgBtn(frame, panel)
    LeaPlusCB[frame]:ClearAllPoints()
    LeaPlusCB[frame]:SetPoint("LEFT", parent, "RIGHT", -parent:GetWidth() + parent:GetStringWidth(), 0)
    LeaPlusCB[frame]:SetSize(25, 25)
    LeaPlusCB[frame].t:SetTexture("Interface\\COMMON\\help-i.blp")
    LeaPlusCB[frame].t:SetTexCoord(0, 1, 0, 1)
    LeaPlusCB[frame].t:SetVertexColor(0.9, 0.8, 0.0)
    LeaPlusCB[frame]:SetHighlightTexture("Interface\\COMMON\\help-i.blp")
    LeaPlusCB[frame]:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
    LeaPlusCB[frame].tiptext = L[tip]
    LeaPlusCB[frame]:SetScript("OnEnter", LeaPlusLC.TipSee)
    LeaPlusCB[frame]:SetScript("OnClick", function()
        toggleFrameStack(true)
    end)
end


-- Show a footer
function LeaPlusLC:MakeFT(frame, text, left, width)
    local footer = LeaPlusLC:MakeTx(frame, text, left, 96)
    footer:SetWidth(width);
    footer:SetJustifyH("LEFT");
    footer:SetWordWrap(true);
    footer:ClearAllPoints()
    footer:SetPoint("BOTTOMLEFT", left, 96)
end

-- Capitalise first character in a string
function LeaPlusLC:CapFirst(str)
    return gsub(string.lower(str), "^%l", strupper)
end

-- Toggle Zygor addon
function LeaPlusLC:ZygorToggle()
    if select(2, GetAddOnInfo("ZygorGuidesViewerClassic")) then
        if not IsAddOnLoaded("ZygorGuidesViewerClassic") then
            if LeaPlusLC:PlayerInCombat() then
                return
            else
                EnableAddOn("ZygorGuidesViewerClassic")
                ReloadUI();
            end
        else
            DisableAddOn("ZygorGuidesViewerClassic")
            ReloadUI();
        end
    else
        -- Zygor cannot be found
        LeaPlusLC:Print("Zygor addon not found.");
    end
    return
end

-- Show memory usage stat
function LeaPlusLC:ShowMemoryUsage(frame, anchor, x, y)

    -- Create frame
    local memframe = CreateFrame("FRAME", nil, frame)
    memframe:ClearAllPoints()
    memframe:SetPoint(anchor, x, y)
    memframe:SetWidth(100)
    memframe:SetHeight(20)

    -- Create labels
    local pretext = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    pretext:SetPoint("TOPLEFT", 0, 0)
    pretext:SetText(L["Memory Usage"])

    local memtext = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    memtext:SetPoint("TOPLEFT", 0, 0 - 30)

    -- Create stat
    local memstat = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    memstat:SetPoint("BOTTOMLEFT", memtext, "BOTTOMRIGHT")
    memstat:SetText("(calculating...)")

    -- Create update script
    local memtime = -1
    memframe:SetScript("OnUpdate", function(self, elapsed)
        if memtime > 2 or memtime == -1 then
            UpdateAddOnMemoryUsage();
            memtext = GetAddOnMemoryUsage("Leatrix_Plus")
            memtext = math.floor(memtext + .5) .. " KB"
            memstat:SetText(memtext);
            memtime = 0;
        end
        memtime = memtime + elapsed;
    end)

    -- Release memory
    LeaPlusLC.ShowMemoryUsage = nil

end

-- Check if player is in LFG queue
function LeaPlusLC:IsInLFGQueue()
    if LeaPlusLC["GameVer"] == "5" then
        if GetLFGQueueStats(LE_LFG_CATEGORY_LFD) or GetLFGQueueStats(LE_LFG_CATEGORY_LFR) or GetLFGQueueStats(LE_LFG_CATEGORY_RF) then
            return true
        end
    else
        if MiniMapLFGFrame:IsShown() then
            return true
        end
    end
end

-- Check if player is in combat
function LeaPlusLC:PlayerInCombat()
    if (UnitAffectingCombat("player")) then
        LeaPlusLC:Print("You cannot do that in combat.")
        return true
    end
end

--  Hide panel and pages
function LeaPlusLC:HideFrames()

    -- Hide option pages
    for i = 0, LeaPlusLC["NumberOfPages"] do
        if LeaPlusLC["Page" .. i] then
            LeaPlusLC["Page" .. i]:Hide();
        end ;
    end

    -- Hide options panel
    LeaPlusLC["PageF"]:Hide();

end

-- Find out if Leatrix Plus is showing (main panel or config panel)
function LeaPlusLC:IsPlusShowing()
    if LeaPlusLC["PageF"]:IsShown() then
        return true
    end
    for k, v in pairs(LeaConfigList) do
        if v:IsShown() then
            return true
        end
    end
end

-- Check if a name is in your friends list or guild (does not check realm as realm is unknown for some checks)
function LeaPlusLC:FriendCheck(name)

    -- Do nothing if name is empty (such as whispering from the Battle.net app)
    if not name then
        return
    end

    -- Update friends list
    ShowFriends()

    -- Remove realm if it exists
    if name ~= nil then
        name = strsplit("-", name, 2)
    end

    -- Check character friends
    for i = 1, GetNumFriends() do
        local friendName, _, _, _, friendConnected = GetFriendInfo(i)
        if friendName ~= nil then
            -- Check if name is not nil
            friendName = strsplit("-", friendName, 2)
        end

        if (name == friendName) and friendConnected then
            -- Check if name matches and friend is connected
            return true
        end
    end

    -- -- Check Battle.net friends -- obviously disable as there is no bnet friends in 3.3.5 and 2.4.3
    -- local numfriends = BNGetNumFriends()
    -- for i = 1, numfriends do
    -- 	local numtoons = C_BattleNet.GetFriendNumGameAccounts(i)
    -- 	for j = 1, numtoons do
    -- 		local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, j)
    -- 		local characterName = gameAccountInfo.characterName
    -- 		local client = gameAccountInfo.clientProgram
    -- 		if client == "WoW" and characterName == name then
    -- 			return true
    -- 		end
    -- 	end
    -- end

    -- Check guild members if guild is enabled (new members may need to press J to refresh roster)
    if LeaPlusLC["FriendlyGuild"] == "On" then
        local gCount = GetNumGuildMembers()
        for i = 1, gCount do
            local gName, void, void, void, void, void, void, void, gOnline = GetGuildRosterInfo(i)
            if gOnline then
                gName = strsplit("-", gName, 2)
                -- Return true if character name matches
                if (name == gName) then
                    return true
                end
            end
        end
    end

end

----------------------------------------------------------------------
--	L02: Locks
----------------------------------------------------------------------

-- Function to set lock state for configuration buttons
function LeaPlusLC:LockOption(option, item, reloadreq)
    if reloadreq then
        -- Option change requires UI reload
        if LeaPlusLC[option] ~= LeaPlusDB[option] or LeaPlusLC[option] == "Off" then
            LeaPlusLC:LockItem(LeaPlusCB[item], true)
        else
            LeaPlusLC:LockItem(LeaPlusCB[item], false)
        end
    else
        -- Option change does not require UI reload
        if LeaPlusLC[option] == "Off" then
            LeaPlusLC:LockItem(LeaPlusCB[item], true)
        else
            LeaPlusLC:LockItem(LeaPlusCB[item], false)
        end
    end
end

--	Set lock state for configuration buttons
function LeaPlusLC:SetDim()
    LeaPlusLC:LockOption("AutomateQuests", "AutomateQuestsBtn", false)            -- Automate quests
    LeaPlusLC:LockOption("AutoAcceptRes", "AutoAcceptResBtn", false)            -- Accept resurrection
    LeaPlusLC:LockOption("AutoReleasePvP", "AutoReleasePvPBtn", false)            -- Release in PvP
    LeaPlusLC:LockOption("AutoSellJunk", "AutoSellJunkBtn", false)                -- Sell junk automatically
    LeaPlusLC:LockOption("AutoRepairGear", "AutoRepairBtn", false)                -- Repair automatically
    LeaPlusLC:LockOption("InviteFromWhisper", "InvWhisperBtn", false)            -- Invite from whispers
    LeaPlusLC:LockOption("FilterChatMessages", "FilterChatMessagesBtn", true)    -- Filter chat messages
    LeaPlusLC:LockOption("MailFontChange", "MailTextBtn", true)                    -- Resize mail text
    LeaPlusLC:LockOption("QuestFontChange", "QuestTextBtn", true)                -- Resize quest text
    LeaPlusLC:LockOption("BookFontChange", "BookTextBtn", true)                    -- Resize book text
    LeaPlusLC:LockOption("MinimapModder", "ModMinimapBtn", true)                -- Enhance minimap
    LeaPlusLC:LockOption("TipModEnable", "MoveTooltipButton", true)                -- Enhance tooltip
    -- LeaPlusLC:LockOption("EnhanceDressup", "EnhanceDressupBtn", true)			-- Enhance dressup
    LeaPlusLC:LockOption("EnhanceQuestLog", "EnhanceQuestLogBtn", true)            -- Enhance quest log
    LeaPlusLC:LockOption("EnhanceTrainers", "EnhanceTrainersBtn", true)            -- Enhance trainers
    -- LeaPlusLC:LockOption("ShowCooldowns", "CooldownsButton", true)				-- Show cooldowns
    LeaPlusLC:LockOption("ShowPlayerChain", "ModPlayerChain", true)                -- Show player chain
    LeaPlusLC:LockOption("ShowWowheadLinks", "ShowWowheadLinksBtn", true)        -- Show Wowhead links
    LeaPlusLC:LockOption("ShowFlightTimes", "ShowFlightTimesBtn", true)            -- Show flight times
    LeaPlusLC:LockOption("FrmEnabled", "MoveFramesButton", true)                -- Manage frames
    LeaPlusLC:LockOption("ManageBuffs", "ManageBuffsButton", true)                -- Manage buffs
    LeaPlusLC:LockOption("ManageDeBuffs", "ManageDeBuffsButton", true)                -- Manage buffs
    LeaPlusLC:LockOption("ManageWidget", "ManageWidgetButton", true)            -- Manage widget
    LeaPlusLC:LockOption("ManageFocus", "ManageFocusButton", true)                -- Manage focus
    LeaPlusLC:LockOption("ManageTimer", "ManageTimerButton", true)                -- Manage timer
    LeaPlusLC:LockOption("ManageDurability", "ManageDurabilityButton", true)    -- Manage durability
    LeaPlusLC:LockOption("ManageTracker", "ManageTrackerButton", true)    -- Manage Tracker

    LeaPlusLC:LockOption("ManageVehicle", "ManageVehicleButton", true)            -- Manage vehicle
    LeaPlusLC:LockOption("ClassColFrames", "ClassColFramesBtn", true)            -- Class colored frames
    LeaPlusLC:LockOption("SetWeatherDensity", "SetWeatherDensityBtn", false)    -- Set weather density
    LeaPlusLC:LockOption("ViewPortEnable", "ModViewportBtn", true)                -- Enable viewport
    LeaPlusLC:LockOption("FasterLooting", "ModFasterLootingBtn", true)                -- Enable fasterlooting
    --LeaPlusLC:LockOption("MuteGameSounds", "MuteGameSoundsBtn", false)			-- Mute game sounds
    --LeaPlusLC:LockOption("MuteCustomSounds", "MuteCustomSoundsBtn", false)		-- Mute custom sounds
    --LeaPlusLC:LockOption("StandAndDismount", "DismountBtn", true)				-- Dismount me
end

----------------------------------------------------------------------
--	L03: Restarts
----------------------------------------------------------------------

-- Set the reload button state
function LeaPlusLC:ReloadCheck()

    -- Chat
    if (LeaPlusLC["UseEasyChatResizing"] ~= LeaPlusDB["UseEasyChatResizing"])    -- Use easy resizing
            or (LeaPlusLC["NoCombatLogTab"] ~= LeaPlusDB["NoCombatLogTab"])            -- Hide the combat log
            or (LeaPlusLC["NoChatButtons"] ~= LeaPlusDB["NoChatButtons"])            -- Hide chat buttons
            or (LeaPlusLC["UnclampChat"] ~= LeaPlusDB["UnclampChat"])            -- Unclamp chat frame
            or (LeaPlusLC["MoveChatEditBoxToTop"] ~= LeaPlusDB["MoveChatEditBoxToTop"])    -- Move editbox to top
            or (LeaPlusLC["MoreFontSizes"] ~= LeaPlusDB["MoreFontSizes"])            -- More font sizes
            or (LeaPlusLC["AltClickInv"] ~= LeaPlusDB["AltClickInv"])            -- Alt click invite
            or (LeaPlusLC["NoStickyChat"] ~= LeaPlusDB["NoStickyChat"])            -- Disable sticky chat
            or (LeaPlusLC["UseArrowKeysInChat"] ~= LeaPlusDB["UseArrowKeysInChat"])        -- Use arrow keys in chat
            or (LeaPlusLC["NoChatFade"] ~= LeaPlusDB["NoChatFade"])                -- Disable chat fade
            or (LeaPlusLC["ClassColorsInChat"] ~= LeaPlusDB["ClassColorsInChat"])        -- Use class colors in chat
            or (LeaPlusLC["RecentChatWindow"] ~= LeaPlusDB["RecentChatWindow"])        -- Recent chat window
            or (LeaPlusLC["MaxChatHstory"] ~= LeaPlusDB["MaxChatHstory"])            -- Increase chat history
            or (LeaPlusLC["FilterChatMessages"] ~= LeaPlusDB["FilterChatMessages"])        -- Filter chat messages
            or (LeaPlusLC["RestoreChatMessages"] ~= LeaPlusDB["RestoreChatMessages"])    -- Restore chat messages

            -- Text
            or (LeaPlusLC["NoHitIndicators"] ~= LeaPlusDB["NoHitIndicators"])        -- Hide portrait text
            or (LeaPlusLC["HideZoneText"] ~= LeaPlusDB["HideZoneText"])            -- Hide zone text
            or (LeaPlusLC["HideKeybindText"] ~= LeaPlusDB["HideKeybindText"])        -- Hide keybind text
            or (LeaPlusLC["HideMacroText"] ~= LeaPlusDB["HideMacroText"])            -- Hide macro text

            or (LeaPlusLC["MailFontChange"] ~= LeaPlusDB["MailFontChange"])            -- Resize mail text
            or (LeaPlusLC["QuestFontChange"] ~= LeaPlusDB["QuestFontChange"])        -- Resize quest text
            or (LeaPlusLC["BookFontChange"] ~= LeaPlusDB["BookFontChange"])            -- Resize book text

            -- Interface
            or (LeaPlusLC["MinimapModder"] ~= LeaPlusDB["MinimapModder"])            -- Enhance minimap
            or (LeaPlusLC["HideMiniAddonButtons"] ~= LeaPlusDB["HideMiniAddonButtons"])    -- Enhance minimap
            or (LeaPlusLC["SquareMinimap"] ~= LeaPlusDB["SquareMinimap"])            -- Square minimap
            or (LeaPlusLC["CombineAddonButtons"] ~= LeaPlusDB["CombineAddonButtons"])    -- Combine addon buttons
            or (LeaPlusLC["HideMiniTracking"] ~= LeaPlusDB["HideMiniTracking"])        -- Hide tracking button
            or (LeaPlusLC["HideMiniCalendar"] ~= LeaPlusDB["HideMiniCalendar"])        -- Hide tracking button
            or (LeaPlusLC["MiniExcludeList"] ~= LeaPlusDB["MiniExcludeList"])        -- Minimap exclude list
            or (LeaPlusLC["TipModEnable"] ~= LeaPlusDB["TipModEnable"])            -- Enhance tooltip
            or (LeaPlusLC["TipNoHealthBar"] ~= LeaPlusDB["TipNoHealthBar"])            -- Tooltip hide health bar
            or (LeaPlusLC["EnhanceDressup"] ~= LeaPlusDB["EnhanceDressup"])            -- Enhance dressup
            or (LeaPlusLC["EnhanceQuestLog"] ~= LeaPlusDB["EnhanceQuestLog"])        -- Enhance quest log
            or (LeaPlusLC["EnhanceProfessions"] ~= LeaPlusDB["EnhanceProfessions"])        -- Enhance professions
            or (LeaPlusLC["EnhanceTrainers"] ~= LeaPlusDB["EnhanceTrainers"])        -- Enhance trainers
            or (LeaPlusLC["ShowVolume"] ~= LeaPlusDB["ShowVolume"])                -- Show volume slider
            or (LeaPlusLC["AhExtras"] ~= LeaPlusDB["AhExtras"])                -- Show auction controls
            -- or	(LeaPlusLC["ShowCooldowns"]			~= LeaPlusDB["ShowCooldowns"])			-- Show cooldowns
            or (LeaPlusLC["DurabilityStatus"] ~= LeaPlusDB["DurabilityStatus"])        -- Show durability status
            or (LeaPlusLC["ShowVanityControls"] ~= LeaPlusDB["ShowVanityControls"])        -- Show vanity controls
            or (LeaPlusLC["ShowBagSearchBox"] ~= LeaPlusDB["ShowBagSearchBox"])        -- Show bag search box
            -- or	(LeaPlusLC["ShowRaidToggle"]		~= LeaPlusDB["ShowRaidToggle"])			-- Show raid button
            or (LeaPlusLC["ShowPlayerChain"] ~= LeaPlusDB["ShowPlayerChain"])        -- Show player chain
            or (LeaPlusLC["ShowReadyTimer"] ~= LeaPlusDB["ShowReadyTimer"])            -- Show ready timer
            or (LeaPlusLC["ShowWowheadLinks"] ~= LeaPlusDB["ShowWowheadLinks"])        -- Show Wowhead links
            or (LeaPlusLC["ShowFlightTimes"] ~= LeaPlusDB["ShowFlightTimes"])        -- Show flight times

            -- Frames
            or (LeaPlusLC["FrmEnabled"] ~= LeaPlusDB["FrmEnabled"])                -- Manage frames
            or (LeaPlusLC["ManageBuffs"] ~= LeaPlusDB["ManageBuffs"])            -- Manage buffs
            or (LeaPlusLC["ManageDeBuffs"] ~= LeaPlusDB["ManageDeBuffs"])            -- Manage buffs
            or (LeaPlusLC["ManageWidget"] ~= LeaPlusDB["ManageWidget"])            -- Manage widget
            or (LeaPlusLC["ManageFocus"] ~= LeaPlusDB["ManageFocus"])            -- Manage focus
            or (LeaPlusLC["ManageTimer"] ~= LeaPlusDB["ManageTimer"])            -- Manage timer
            or (LeaPlusLC["ManageDurability"] ~= LeaPlusDB["ManageDurability"])        -- Manage durability
            or (LeaPlusLC["ManageTracker"] ~= LeaPlusDB["ManageTracker"])            -- Manage Tracker
            or (LeaPlusLC["ManageVehicle"] ~= LeaPlusDB["ManageVehicle"])            -- Manage vehicle
            or (LeaPlusLC["ClassColFrames"] ~= LeaPlusDB["ClassColFrames"])            -- Class colored frames
            or (LeaPlusLC["NoAlerts"] ~= LeaPlusDB["NoAlerts"])                -- Hide alerts
            or (LeaPlusLC["NoGryphons"] ~= LeaPlusDB["NoGryphons"])                -- Hide gryphons
            or (LeaPlusLC["NoClassBar"] ~= LeaPlusDB["NoClassBar"])                -- Hide stance bar

            -- System
            or (LeaPlusLC["ViewPortEnable"] ~= LeaPlusDB["ViewPortEnable"])            -- Enable viewport
            or (LeaPlusLC["NoRestedEmotes"] ~= LeaPlusDB["NoRestedEmotes"])            -- Silence rested emotes
            or (LeaPlusLC["NoBagAutomation"] ~= LeaPlusDB["NoBagAutomation"])        -- Disable bag automation
            --or	(LeaPlusLC["CharAddonList"]			~= LeaPlusDB["CharAddonList"])			-- Show character addons
            or (LeaPlusLC["FasterLooting"] ~= LeaPlusDB["FasterLooting"])            -- Faster auto loot
            or (LeaPlusLC["FasterMovieSkip"] ~= LeaPlusDB["FasterMovieSkip"])        -- Faster movie skip
            --or	(LeaPlusLC["StandAndDismount"]		~= LeaPlusDB["StandAndDismount"])		-- Dismount me
            --or	(LeaPlusLC["ShowVendorPrice"]		~= LeaPlusDB["ShowVendorPrice"])		-- Show vendor price
            or (LeaPlusLC["CombatPlates"] ~= LeaPlusDB["CombatPlates"])            -- Combat plates
            or (LeaPlusLC["EasyItemDestroy"] ~= LeaPlusDB["EasyItemDestroy"])        -- Easy item destroy

    then
        -- Enable the reload button
        LeaPlusLC:LockItem(LeaPlusCB["ReloadUIButton"], false)
        LeaPlusCB["ReloadUIButton"].f:Show()
    else
        -- Disable the reload button
        LeaPlusLC:LockItem(LeaPlusCB["ReloadUIButton"], true)
        LeaPlusCB["ReloadUIButton"].f:Hide()
    end

end

----------------------------------------------------------------------
--	L20: Live
----------------------------------------------------------------------

function LeaPlusLC:Live()

    ----------------------------------------------------------------------
    --	Auto Spirit Res
    ----------------------------------------------------------------------

    if LeaPlusLC["AutoSpiritRes"] == "On" then
        LpEvt:RegisterEvent("PLAYER_DEAD")
        LpEvt:RegisterEvent("CONFIRM_XP_LOSS")
    else
        LpEvt:UnregisterEvent("PLAYER_DEAD");
        LpEvt:UnregisterEvent("CONFIRM_XP_LOSS");
    end

    ----------------------------------------------------------------------
    --	Invite from whispers
    ----------------------------------------------------------------------

    if LeaPlusLC["InviteFromWhisper"] == "On" then
        LpEvt:RegisterEvent("CHAT_MSG_WHISPER");
        LpEvt:RegisterEvent("CHAT_MSG_BN_WHISPER");
    else
        LpEvt:UnregisterEvent("CHAT_MSG_WHISPER");
        LpEvt:UnregisterEvent("CHAT_MSG_BN_WHISPER");
    end

    ----------------------------------------------------------------------
    --	Block duels
    ----------------------------------------------------------------------

    if LeaPlusLC["NoDuelRequests"] == "On" then
        LpEvt:RegisterEvent("DUEL_REQUESTED");
    else
        LpEvt:UnregisterEvent("DUEL_REQUESTED");
    end

    ----------------------------------------------------------------------
    --	Block party invites and Party from friends
    ----------------------------------------------------------------------

    if LeaPlusLC["NoPartyInvites"] == "On" or LeaPlusLC["AcceptPartyFriends"] == "On" then
        LpEvt:RegisterEvent("PARTY_INVITE_REQUEST");
    else
        LpEvt:UnregisterEvent("PARTY_INVITE_REQUEST");
    end

    ----------------------------------------------------------------------
    --	Block guild invites
    ----------------------------------------------------------------------

    if LeaPlusLC["NoGuildInvites"] == "On" then
        LpEvt:RegisterEvent("GUILD_INVITE_REQUEST");
    else
        LpEvt:UnregisterEvent("GUILD_INVITE_REQUEST");
    end

    ----------------------------------------------------------------------
    --	Automatic summon
    ----------------------------------------------------------------------

    if LeaPlusLC["AutoAcceptSummon"] == "On" then
        LpEvt:RegisterEvent("CONFIRM_SUMMON");
    else
        LpEvt:UnregisterEvent("CONFIRM_SUMMON");
    end

    ----------------------------------------------------------------------
    --	Disable loot warnings
    ----------------------------------------------------------------------

    if LeaPlusLC["NoConfirmLoot"] == "On" then
        LpEvt:RegisterEvent("CONFIRM_LOOT_ROLL")
        LpEvt:RegisterEvent("LOOT_BIND_CONFIRM")
        LpEvt:RegisterEvent("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL")
        LpEvt:RegisterEvent("MAIL_LOCK_SEND_ITEMS")
    else
        LpEvt:UnregisterEvent("CONFIRM_LOOT_ROLL")
        LpEvt:UnregisterEvent("LOOT_BIND_CONFIRM")
        LpEvt:UnregisterEvent("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL")
        LpEvt:UnregisterEvent("MAIL_LOCK_SEND_ITEMS")
    end

end

----------------------------------------------------------------------
--	L30: Isolated
----------------------------------------------------------------------

function LeaPlusLC:Isolated()

    ----------------------------------------------------------------------
    -- Easy item destroy
    ----------------------------------------------------------------------

    if LeaPlusLC["EasyItemDestroy"] == "On" then

        -- Get the type "DELETE" into the field to confirm text
        local TypeDeleteLine = gsub(DELETE_GOOD_ITEM, "[\r\n]", "@")
        local void, TypeDeleteLine = strsplit("@", TypeDeleteLine, 2)

        -- Add hyperlinks to regular item destroy
        RunScript('StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkEnter = function(self, link, text, region, boundsLeft, boundsBottom, boundsWidth, boundsHeight) GameTooltip:SetOwner(self, "ANCHOR_PRESERVE") GameTooltip:ClearAllPoints() local cursorClearance = 30 GameTooltip:SetPoint("TOPLEFT", region, "BOTTOMLEFT", boundsLeft, boundsBottom - cursorClearance) GameTooltip:SetHyperlink(link) end')
        RunScript('StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkLeave = function(self) GameTooltip:Hide() end')
        RunScript('StaticPopupDialogs["DELETE_ITEM"].OnHyperlinkEnter = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkEnter')
        RunScript('StaticPopupDialogs["DELETE_ITEM"].OnHyperlinkLeave = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkLeave')
        --RunScript('StaticPopupDialogs["DELETE_QUEST_ITEM"].OnHyperlinkEnter = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkEnter')
        --RunScript('StaticPopupDialogs["DELETE_QUEST_ITEM"].OnHyperlinkLeave = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkLeave')
        --RunScript('StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"].OnHyperlinkEnter = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkEnter')
        --RunScript('StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"].OnHyperlinkLeave = StaticPopupDialogs["DELETE_GOOD_ITEM"].OnHyperlinkLeave')

        -- Hide editbox and set item link
        local easyDelFrame = CreateFrame("FRAME")
        easyDelFrame:RegisterEvent("DELETE_ITEM_CONFIRM")
        easyDelFrame:SetScript("OnEvent", function()
            if StaticPopup1EditBox:IsShown() then
                -- Item requires player to type delete so hide editbox and show link
                StaticPopup1:SetHeight(StaticPopup1:GetHeight() - 10)
                StaticPopup1EditBox:Hide()
                StaticPopup1Button1:Enable()
                local link = select(3, GetCursorInfo())
                if link then
                    StaticPopup1Text:SetText(gsub(StaticPopup1Text:GetText(), gsub(TypeDeleteLine, "@", ""), "") .. "|n" .. link)
                end
            else
                -- Item does not require player to type delete so just show item link
                StaticPopup1:SetHeight(StaticPopup1:GetHeight() + 40)
                StaticPopup1EditBox:Hide()
                StaticPopup1Button1:Enable()
                local link = select(3, GetCursorInfo())
                if link then
                    StaticPopup1Text:SetText(gsub(StaticPopup1Text:GetText(), gsub(TypeDeleteLine, "@", ""), "") .. "|n|n" .. link)
                end
            end
        end)

    end

    ----------------------------------------------------------------------
    -- Mute game sounds (no reload required) (MuteGameSounds)
    ----------------------------------------------------------------------

    --do
    --
    --	-- Create soundtable
    --	local muteTable = {
    --
    --		["MuteFizzle"] = {			"sound/spells/fizzle/fizzlefirea.ogg#569773", "sound/spells/fizzle/FizzleFrostA.ogg#569775", "sound/spells/fizzle/FizzleHolyA.ogg#569772", "sound/spells/fizzle/FizzleNatureA.ogg#569774", "sound/spells/fizzle/FizzleShadowA.ogg#569776",},
    --		["MuteInterface"] = {		"sound/interface/iUiInterfaceButtonA.ogg#567481", "sound/interface/uChatScrollButton.ogg#567407", "sound/interface/uEscapeScreenClose.ogg#567464", "sound/interface/uEscapeScreenOpen.ogg#567490",},
    --
    --		-- Trains
    --		["MuteTrains"] = {
    --
    --			--[[Blood Elf]]	"sound#539219", "sound#539203",
    --			--[[Draenei]]	"sound#539516", "sound#539730",
    --			--[[Dwarf]]		"sound#539802", "sound#539881",
    --			--[[Gnome]]		"sound#540271", "sound#540275",
    --			--[[Human]]		"sound#540535", "sound#540734",
    --			--[[Night Elf]]	"sound#540870", "sound#540947",
    --			--[[Orc]]		"sound#541157", "sound#541239",
    --			--[[Tauren]]	"sound#542818", "sound#542896",
    --			--[[Troll]] 	"sound#543085", "sound#543093",
    --			--[[Undead]]	"sound#542526", "sound#542600",
    --
    --		},
    --
    --		-- Chimes (sound/doodad/)
    --		["MuteChimes"] = {
    --			"belltollalliance.ogg#566564",
    --			"belltollhorde.ogg#565853",
    --			"belltollnightelf.ogg#566558",
    --			"belltolltribal.ogg#566027",
    --			"kharazahnbelltoll.ogg#566254",
    --			"dwarfhorn.ogg#566064",
    --		},
    --
    --		-- Vaults
    --		["MuteVaults"] = {
    --
    --			-- Mechanical guild vault idle sound (such as those found in Booty Bay and Winterspring)
    --			"sound/doodad/guildvault_goblin_01stand.ogg#566289",
    --
    --		},
    --
    --		-- Ready check (sound/interface/)
    --		["MuteReady"] = {
    --			"levelup2.ogg#567478",
    --		},
    --
    --		-- Login (sound/interface/)
    --		["MuteLogin"] = {
    --
    --			-- This is handled with the PLAYER_LOGOUT event
    --
    --		},
    --
    --		-- Bikes
    --		["MuteBikes"] = {
    --
    --			-- Mekgineer's Chopper/Mechano Hog/Chauffeured (sound/vehicles/motorcyclevehicle, sound/vehicles)
    --			"motorcyclevehicleattackthrown.ogg#569858", "motorcyclevehiclejumpend1.ogg#569863", "motorcyclevehiclejumpend2.ogg#569857", "motorcyclevehiclejumpend3.ogg#569855", "motorcyclevehiclejumpstart1.ogg#569856", "motorcyclevehiclejumpstart2.ogg#569862", "motorcyclevehiclejumpstart3.ogg#569860", "motorcyclevehicleloadthrown.ogg#569861", "motorcyclevehiclestand.ogg#569859", "motorcyclevehiclewalkrun.ogg#569854", "vehicle_ground_gearshift_1.ogg#598748", "vehicle_ground_gearshift_2.ogg#598736", "vehicle_ground_gearshift_3.ogg#569852", "vehicle_ground_gearshift_4.ogg#598745", "vehicle_ground_gearshift_5.ogg#569845",
    --
    --		},
    --
    --		-- Events
    --		["MuteEvents"] = {
    --
    --			-- Headless Horseman (sound/creature/headlesshorseman/)
    --			"horseman_beckon_01.ogg#551670",
    --			"horseman_bodydefeat_01.ogg#551706",
    --			"horseman_bomb_01.ogg#551705",
    --			"horseman_conflag_01.ogg#551686",
    --			"horseman_death_01.ogg#551695",
    --			"horseman_failing_01.ogg#551684",
    --			"horseman_failing_02.ogg#551700",
    --			"horseman_fire_01.ogg#551673",
    --			"horseman_laugh_01.ogg#551703",
    --			"horseman_laugh_02.ogg#551682",
    --			"horseman_out_01.ogg#551680",
    --			"horseman_request_01.ogg#551687",
    --			"horseman_return_01.ogg#551698",
    --			"horseman_slay_01.ogg#551676",
    --			"horseman_special_01.ogg#551696",
    --
    --		},
    --
    --		-- Gyrocopters
    --		["MuteGyrocopters"] = {
    --
    --			-- Mimiron's Head (sound/creature/mimironheadmount/)
    --			"mimironheadmount_jumpend.ogg#595097",
    --			"mimironheadmount_jumpstart.ogg#595103",
    --			"mimironheadmount_run.ogg#555364",
    --			"mimironheadmount_walk.ogg#595100",
    --
    --			-- sound/creature/gyrocopter/
    --			"gyrocopterfly.ogg#551390",
    --			"gyrocopterflyidle.ogg#551398",
    --			"gyrocopterflyup.ogg#551389",
    --			"gyrocoptergearshift1.ogg#551384",
    --			"gyrocoptergearshift2.ogg#551391",
    --			"gyrocoptergearshift3.ogg#551387",
    --			"gyrocopterjumpend.ogg#551396",
    --			"gyrocopterjumpstart.ogg#551399",
    --			"gyrocopterrun.ogg#551386",
    --			"gyrocoptershuffleleftorright1.ogg#551385",
    --			"gyrocoptershuffleleftorright2.ogg#551382",
    --			"gyrocoptershuffleleftorright3.ogg#551392",
    --			"gyrocopterstallinair.ogg#551395",
    --			"gyrocopterstallinairlong.ogg#551394",
    --			"gyrocopterstallongroundlong.ogg#551393",
    --			"gyrocopterstand.ogg#551383",
    --			"gyrocopterstandvar1_a.ogg#551388",
    --			"gyrocopterstandvar1_b.ogg#551397",
    --			"gyrocopterstandvar1_bnew.ogg#551400",
    --			"gyrocopterwalk.ogg#551401",
    --
    --			-- Gear shift sounds (sound/vehicles/)
    --			"vehicle_airplane_gearshift_1.ogg#569846",
    --			"vehicle_airplane_gearshift_2.ogg#598739",
    --			"vehicle_airplane_gearshift_3.ogg#569851",
    --			"vehicle_airplane_gearshift_4.ogg#598742",
    --			"vehicle_airplane_gearshift_5.ogg#598733",
    --			"vehicle_airplane_gearshift_6.ogg#569850",
    --
    --			-- sound/spells/
    --			"summongyrocopter.ogg#568252",
    --
    --		},
    --
    --		-- Yawns (sound/creature/tiger/)
    --		["MuteYawns"] = {
    --
    --			"mtigerstand2a.ogg#562388",
    --
    --		},
    --
    --		-- Screech (sound/spells/)
    --		["MuteScreech"] = {
    --
    --			"screech.ogg#569429",
    --
    --		},
    --
    --		-- A'dal
    --		["MuteAdal"] = {
    --
    --			-- sound/creature/naaru/
    --			"naruuloopgood.ogg#601649",
    --
    --			-- sound/doodad/
    --			"ancient_d_lights.ogg#567134",
    --
    --		},
    --
    --		-- Ripper (Arcanite ripper guitar sound)
    --		["MuteRipper"] = {
    --
    --			-- sound/events/
    --			"archaniteripper.ogg#567384",
    --
    --		},
    --
    --		-- Rhonin
    --		["MuteRhonin"] = {
    --
    --			-- sound/creature/rhonin/ur_rhonin_event
    --			"01.ogg#559130", "02.ogg#559131", "03.ogg#559126", "04.ogg#559128", "05.ogg#559133", "06.ogg#559129", "07.ogg#559132", "08.ogg#559127",
    --
    --		},
    --
    --		-- Travelers (gnimo sounds are handled in SetupMute() as they are shared with striders)
    --		["MuteTravelers"] = {
    --
    --			-- Traveler's Tundra Mammoth (sound/creature/npcdraeneimalestandard, sound/creature/goblinmalezanynpc, sound/creature/trollfemalelaidbacknpc, sound/creature/trollfemalelaidbacknpc)
    --			"npcdraeneimalestandardvendor01.ogg#557341", "npcdraeneimalestandardvendor02.ogg#557335", "npcdraeneimalestandardvendor03.ogg#557328", "npcdraeneimalestandardvendor04.ogg#557331", "npcdraeneimalestandardvendor05.ogg#557325", "npcdraeneimalestandardvendor06.ogg#557324",
    --			"npcdraeneimalestandardfarewell01.ogg#557342", "npcdraeneimalestandardfarewell02.ogg#557326", "npcdraeneimalestandardfarewell03.ogg#557322", "npcdraeneimalestandardfarewell05.ogg#557332", "npcdraeneimalestandardfarewell06.ogg#557338", "npcdraeneimalestandardfarewell08.ogg#557334",
    --			"goblinmalezanynpcvendor01.ogg#550818", "goblinmalezanynpcvendor02.ogg#550817", "goblinmalezanynpcgreeting01.ogg#550805", "goblinmalezanynpcgreeting02.ogg#550813", "goblinmalezanynpcgreeting03.ogg#550819", "goblinmalezanynpcgreeting04.ogg#550806", "goblinmalezanynpcgreeting05.ogg#550820", "goblinmalezanynpcgreeting06.ogg#550809",
    --			"goblinmalezanynpcfarewell01.ogg#550807", "goblinmalezanynpcfarewell03.ogg#550808", "goblinmalezanynpcfarewell04.ogg#550812",
    --			"trollfemalelaidbacknpcvendor01.ogg#562812","trollfemalelaidbacknpcvendor02.ogg#562802", "trollfemalelaidbacknpcgreeting01.ogg#562815","trollfemalelaidbacknpcgreeting02.ogg#562814", "trollfemalelaidbacknpcgreeting03.ogg#562816", "trollfemalelaidbacknpcgreeting04.ogg#562807", "trollfemalelaidbacknpcgreeting05.ogg#562804", "trollfemalelaidbacknpcgreeting06.ogg#562803",
    --			"trollfemalelaidbacknpcfarewell01.ogg#562809", "trollfemalelaidbacknpcfarewell02.ogg#562808", "trollfemalelaidbacknpcfarewell03.ogg#562813", "trollfemalelaidbacknpcfarewell04.ogg#562817", "trollfemalelaidbacknpcfarewell05.ogg#562806",
    --
    --		},
    --
    --		-- Striders (footsteps are in another setting) (wound sounds are handled in SetupMute() as they are shared with travelers)
    --		["MuteStriders"] = {
    --
    --			-- sound/creature/mechastrider/
    --			"mechastrideraggro.ogg#555127",
    --			"mechastriderattacka.ogg#555125",
    --			"smechastriderattackb.ogg#555123",
    --			"mechastriderattackc.ogg#555132",
    --			"mechastriderloop.ogg#555124",
    --			"mechastriderwoundcrit.ogg#555131",
    --
    --		},
    --
    --		-- Mechanical mount footsteps
    --		["MuteMechSteps"] = {
    --
    --			-- sound/creature/gnomespidertank/
    --			"gnomespidertankfootstepa.ogg#550507",
    --			"gnomespidertankfootstepb.ogg#550514",
    --			"gnomespidertankfootstepc.ogg#550501",
    --			"gnomespidertankfootstepd.ogg#550500",
    --			"gnomespidertankwoundd.ogg#550511",
    --			"gnomespidertankwounde.ogg#550504",
    --			"gnomespidertankwoundf.ogg#550498",
    --
    --		},
    --
    --		-- Netherdrakes
    --		["MuteNetherdrakes"] = {
    --
    --			-- sound/creature/netherdrake/
    --			"hugewingflap1.ogg#556477",
    --			"hugewingflap2.ogg#556479",
    --			"hugewingflap3.ogg#556476",
    --			"netherdrakea.ogg#556475",
    --			"netherdrakeb.ogg#556478",
    --
    --		},
    --
    --		-- Brooms
    --		["MuteBrooms"] = {
    --
    --			-- sound/creature/broomstickmount/
    --			"broomstickmountland.ogg#545651",
    --			"broomstickmounttakeoff.ogg#545652",
    --
    --			-- sound/spells/
    --			"summonbroomstick1.ogg#567986",
    --			"summonbroomstick3.ogg#569547",
    --			"summonbroomstick2.ogg#568335",
    --
    --		},
    --
    --	}
    --
    --	-- Give table file level scope (its used during logout and for wipe and admin commands)
    --	LeaPlusLC["muteTable"] = muteTable
    --
    --	-- Load saved settings or set default values
    --	for k, v in pairs(muteTable) do
    --		if LeaPlusDB[k] and type(LeaPlusDB[k]) == "string" and LeaPlusDB[k] == "On" or LeaPlusDB[k] == "Off" then
    --			LeaPlusLC[k] = LeaPlusDB[k]
    --		else
    --			LeaPlusLC[k] = "Off"
    --			LeaPlusDB[k] = "Off"
    --		end
    --	end
    --
    --	-- Create configuration panel
    --	local SoundPanel = LeaPlusLC:CreatePanel("Mute game sounds", "SoundPanel")
    --
    --	-- Add checkboxes
    --	LeaPlusLC:MakeTx(SoundPanel, "General", 16, -72)
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteChimes", "Chimes", 16, -92, false, "If checked, clock hourly chimes will be muted.")
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteEvents", "Events", 16, -112, false, "If checked, holiday event sounds will be muted.|n|nThis applies to Headless Horseman.")
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteFizzle", "Fizzle", 16, -132, false, "If checked, the spell fizzle sounds will be muted.")
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteInterface", "Interface", 16, -152, false, "If checked, the interface button sound, the chat frame tab click sound and the game menu toggle sound will be muted.")
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteLogin", "Login", 16, -172, false, "If checked, login screen sounds will be muted when you logout of the game.|n|nNote that login screen sounds will not be muted when you initially launch the game.|n|nThey will only be muted when you logout of the game.  This includes manually logging out as well as being forcefully logged out by the game server for reasons such as being away for an extended period of time.|n|nNo more dragons roaring when you fall asleep while the game is running!")
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteReady", "Ready", 16, -192, false, "If checked, the ready check sound will be muted.")
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteTrains", "Trains", 16, -212, false, "If checked, train sounds will be muted.")
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteVaults", "Vaults", 16, -232, false, "If checked, the mechanical guild vault idle sound will be muted.")
    --
    --	LeaPlusLC:MakeTx(SoundPanel, "Mounts", 150, -72)
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteBikes", "Bikes", 150, -92, false, "If checked, bike mount sounds will be muted.|n|nThis applies to Mekgineer's Chopper and Mechano-hog.")
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteBrooms", "Brooms", 150, -112, false, "If checked, broom mounts will be muted.")
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteGyrocopters", "Gyrocopters", 150, -132, false, "If checked, gyrocopters will be muted.|n|nThis applies to the engineering flying machine mounts.")
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteMechSteps", "Mechsteps", 150, -152, false, "If checked, footsteps for mechanical mounts will be muted.")
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteStriders", "Mechstriders", 150, -172, false, "If checked, mechanostriders will be quieter.")
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteNetherdrakes", "Netherdrakes", 150, -192, false, "If checked, netherdrakes will be quieter.")
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteTravelers", "Travelers", 150, -212, false, "If checked, traveling merchant greetings and farewells will be muted.|n|nThis applies to Traveler's Tundra Mammoth.")
    --
    --	LeaPlusLC:MakeTx(SoundPanel, "Pets", 284, -72)
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteScreech", "Screech", 284, -92, false, "If checked, Screech will be muted.|n|nThis is a spell used by some flying pets.")
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteYawns", "Yawns", 284, -112, false, "If checked, yawns from hunter pet cats will be muted.")
    --
    --	LeaPlusLC:MakeTx(SoundPanel, "Misc", 418, -72)
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteAdal", "A'dal", 418, -92, false, "If checked, A'dal in Shattrath City will be muted.")
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteRipper", "Ripper", 418, -112, false, "If checked, the Arcanite Ripper guitar sound will be muted.")
    --	LeaPlusLC:MakeCB(SoundPanel, "MuteRhonin", "Rhonin", 418, -132, false, "If checked, Rhonin will be muted.")
    --
    --	-- Set click width for sounds checkboxes
    --	for k, v in pairs(muteTable) do
    --		LeaPlusCB[k].f:SetWidth(90)
    --		if LeaPlusCB[k].f:GetStringWidth() > 90 then
    --			LeaPlusCB[k]:SetHitRectInsets(0, -80, 0, 0)
    --		else
    --			LeaPlusCB[k]:SetHitRectInsets(0, -LeaPlusCB[k].f:GetStringWidth() + 4, 0, 0)
    --		end
    --	end
    --
    --	-- Function to mute and unmute sounds
    --	local function SetupMute()
    --		for k, v in pairs(muteTable) do
    --			if LeaPlusLC["MuteGameSounds"] == "On" and LeaPlusLC[k] == "On" then
    --				for i, e in pairs(v) do
    --					local file, soundID = e:match("([^,]+)%#([^,]+)")
    --					MuteSoundFile(soundID)
    --				end
    --			else
    --				for i, e in pairs(v) do
    --					local file, soundID = e:match("([^,]+)%#([^,]+)")
    --					UnmuteSoundFile(soundID)
    --				end
    --			end
    --		end
    --		-- Handle special cases where sounds overlap
    --		if LeaPlusLC["MuteGameSounds"] == "On" and (LeaPlusLC["MuteTravelers"] == "On" or LeaPlusLC["MuteStriders"] == "On") then
    --			-- Mute travelers and mute striders share same sounds
    --			MuteSoundFile(555128) -- mechastriderwounda
    --			MuteSoundFile(555129) -- mechastriderwoundb
    --			MuteSoundFile(555130) -- mechastriderwoundc
    --		else
    --			-- Mute travelers and mute striders share same sounds
    --			UnmuteSoundFile(555128) -- mechastriderwounda
    --			UnmuteSoundFile(555129) -- mechastriderwoundb
    --			UnmuteSoundFile(555130) -- mechastriderwoundc
    --		end
    --	end
    --
    --	-- Setup mute on startup if option is enabled
    --	if LeaPlusLC["MuteGameSounds"] == "On" then SetupMute() end
    --
    --	-- Setup mute when options are clicked
    --	for k, v in pairs(muteTable) do
    --		LeaPlusCB[k]:HookScript("OnClick", SetupMute)
    --	end
    --	LeaPlusCB["MuteGameSounds"]:HookScript("OnClick", SetupMute)
    --
    --	-- Help button hidden
    --	SoundPanel.h:Hide()
    --
    --	-- Back button handler
    --	SoundPanel.b:SetScript("OnClick", function()
    --		SoundPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
    --		return
    --	end)
    --
    --	-- Reset button handler
    --	SoundPanel.r:SetScript("OnClick", function()
    --
    --		-- Reset checkboxes
    --		for k, v in pairs(muteTable) do
    --			LeaPlusLC[k] = "Off"
    --		end
    --		SetupMute()
    --
    --		-- Refresh panel
    --		SoundPanel:Hide(); SoundPanel:Show()
    --
    --	end)
    --
    --	-- Show panal when options panel button is clicked
    --	LeaPlusCB["MuteGameSoundsBtn"]:SetScript("OnClick", function()
    --		if IsShiftKeyDown() and IsControlKeyDown() then
    --			-- Preset profile
    --			for k, v in pairs(muteTable) do
    --				LeaPlusLC[k] = "On"
    --			end
    --			LeaPlusLC["MuteReady"] = "Off"
    --			SetupMute()
    --		else
    --			SoundPanel:Show()
    --			LeaPlusLC:HideFrames()
    --		end
    --	end)
    --
    --	----------------------------------------------------------------------
    --	-- Login setting
    --	----------------------------------------------------------------------
    --
    --	-- Create soundtable for PLAYER_LOGOUT (these sounds are only muted or unmuted when logging out
    --	local muteLogoutTable = {
    --
    --		-- Ambiance (sound/ambience/gluescreen/gluescreenlogin.ogg)
    --		"538968",
    --
    --		-- Dragon roaring sounds (sound/ambience/gluescreen/wrath_login_)
    --		"538970", "538969", "538971", "538972",
    --
    --		-- Game music (sound/music/gluescreenmusic/wotlk_main_title.mp3)
    --		"53222",
    --
    --	}
    --
    --	-- Handle sounds that get muted or unmuted when logging out
    --	local logoutEvent = CreateFrame("FRAME")
    --	logoutEvent:RegisterEvent("PLAYER_LOGOUT")
    --
    --	-- Mute or unmute sounds when logging out
    --	logoutEvent:SetScript("OnEvent", function()
    --		if LeaPlusLC["MuteGameSounds"] == "On" and LeaPlusLC["MuteLogin"] == "On" then
    --			-- Mute logout table sounds on logout
    --			for void, soundID in pairs(muteLogoutTable) do
    --				--FIX ME
    --				-- MuteSoundFile(soundID)
    --			end
    --		else
    --			-- Unmute logout table sounds on logout
    --			for void, soundID in pairs(muteLogoutTable) do
    --				--FIX ME
    --				-- UnmuteSoundFile(soundID)
    --			end
    --		end
    --	end)
    --
    --	-- Unmute sounds when logging in
    --	-- for void, soundID in pairs(muteLogoutTable) do
    --	-- 	UnmuteSoundFile(soundID)
    --	-- end
    --
    --end

    ----------------------------------------------------------------------
    -- Faster movie skip
    ----------------------------------------------------------------------

    if LeaPlusLC["FasterMovieSkip"] == "On" then

        CinematicFrame:HookScript("OnShow", function(self, ...)
            if not isPastWOTLK then
                HideUIPanel(self);
                GameMovieFinished()
                LibCompat.After(0.01, function()
                    StopCinematic();
                end)
            end
        end)

    end

    ----------------------------------------------------------------------
    -- Unclamp chat frame
    ----------------------------------------------------------------------

    if LeaPlusLC["UnclampChat"] == "On" and not LeaLockList["UnclampChat"] then

        -- Process normal and existing chat frames on startup
        for i = 1, 50 do
            if _G["ChatFrame" .. i] then
                _G["ChatFrame" .. i]:SetClampRectInsets(0, 0, 0, 0);
            end
        end

        -- -- Process new chat frames and combat log
        -- hooksecurefunc("FloatingChatFrame_UpdateBackgroundAnchors", function(self)
        -- 	self:SetClampRectInsets(0, 0, 0, 0);
        -- end)

        -- Process temporary chat frames
        hooksecurefunc("FCF_OpenTemporaryWindow", function()
            local cf = FCF_GetCurrentChatFrame():GetName() or nil
            if cf then
                _G[cf]:SetClampRectInsets(0, 0, 0, 0);
            end
        end)

    end

    ----------------------------------------------------------------------
    -- Wowhead Links
    ----------------------------------------------------------------------

    if LeaPlusLC["ShowWowheadLinks"] == "On" then

        -- Create configuration panel
        local WowheadPanel = LeaPlusLC:CreatePanel("Show Wowhead links", "WowheadPanel")

        LeaPlusLC:MakeTx(WowheadPanel, "Settings", 16, -72)
        LeaPlusLC:MakeCB(WowheadPanel, "WowheadLinkComments", "Links go directly to the comments section", 16, -92, false, "If checked, Wowhead links will go directly to the comments section.")

        -- Help button hidden
        WowheadPanel.h:Hide()

        -- Back button handler
        WowheadPanel.b:SetScript("OnClick", function()
            WowheadPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page5"]:Show()
            return
        end)

        -- Reset button handler
        WowheadPanel.r:SetScript("OnClick", function()

            -- Reset controls
            LeaPlusLC["WowheadLinkComments"] = "Off"

            -- Refresh configuration panel
            WowheadPanel:Hide();
            WowheadPanel:Show()

        end)

        -- Show configuration panal when options panel button is clicked
        LeaPlusCB["ShowWowheadLinksBtn"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["WowheadLinkComments"] = "Off"
            else
                WowheadPanel:Show()
                LeaPlusLC:HideFrames()
            end
        end)

        -- Get localised Wowhead URL
        local wowheadLoc
        if GameLocale == "deDE" then
            wowheadLoc = "wowhead.com/wotlk/de"
        elseif GameLocale == "esMX" then
            wowheadLoc = "wowhead.com/wotlk/es"
        elseif GameLocale == "esES" then
            wowheadLoc = "wowhead.com/wotlk/es"
        elseif GameLocale == "frFR" then
            wowheadLoc = "wowhead.com/wotlk/fr"
        elseif GameLocale == "itIT" then
            wowheadLoc = "wowhead.com/wotlk/it"
        elseif GameLocale == "ptBR" then
            wowheadLoc = "wowhead.com/wotlk/pt"
        elseif GameLocale == "ruRU" then
            wowheadLoc = "wowhead.com/wotlk/ru"
        elseif GameLocale == "koKR" then
            wowheadLoc = "wowhead.com/wotlk/ko"
        elseif GameLocale == "zhCN" then
            wowheadLoc = "wowhead.com/wotlk/cn"
        elseif GameLocale == "zhTW" then
            wowheadLoc = "wowhead.com/wotlk/cn"
        else
            wowheadLoc = "wowhead.com/wotlk"
        end

        ----------------------------------------------------------------------
        -- Achievements frame
        ----------------------------------------------------------------------

        -- Achievement link function
        local function DoWowheadAchievementFunc()

            -- Create editbox
            local aEB = CreateFrame("EditBox", nil, AchievementFrame)
            aEB:ClearAllPoints()
            aEB:SetPoint("BOTTOMRIGHT", -50, 1)
            aEB:SetHeight(16)
            aEB:SetFontObject("GameFontNormalSmall")
            aEB:SetBlinkSpeed(0)
            aEB:SetJustifyH("RIGHT")
            aEB:SetAutoFocus(false)
            aEB:EnableKeyboard(true)
            aEB:SetHitRectInsets(90, 0, 0, 0)
            aEB:SetScript("OnKeyDown", function()
            end)
            aEB:SetScript("OnMouseUp", function()
                if aEB:IsMouseOver() then
                    aEB:HighlightText()
                else
                    aEB:HighlightText(0, 0)
                end
            end)

            -- Create hidden font string (used for setting width of editbox)
            aEB.z = aEB:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
            aEB.z:Hide()

            -- Store last link in case editbox is cleared
            local lastAchievementLink

            -- Function to set editbox value
            hooksecurefunc("AchievementFrameAchievements_SelectButton", function(self)
                local achievementID = self.id or nil
                if achievementID then
                    -- Set editbox text
                    if LeaPlusLC["WowheadLinkComments"] == "On" then
                        aEB:SetText("https://" .. wowheadLoc .. "/achievement=" .. achievementID .. "#comments")
                    else
                        aEB:SetText("https://" .. wowheadLoc .. "/achievement=" .. achievementID)
                    end
                    lastAchievementLink = aEB:GetText()
                    -- Set hidden fontstring then resize editbox to match
                    aEB.z:SetText(aEB:GetText())
                    aEB:SetWidth(aEB.z:GetStringWidth() + 90)
                    -- Get achievement title for tooltip
                    local achievementLink = GetAchievementLink(self.id)
                    if achievementLink then
                        aEB.tiptext = achievementLink:match("%[(.-)%]") .. "|n" .. L["Press CTRL/C to copy."]
                    end
                    -- Show the editbox
                    aEB:Show()
                end
            end)

            -- Create tooltip
            aEB:HookScript("OnEnter", function()
                aEB:HighlightText()
                aEB:SetFocus()
                GameTooltip:SetOwner(aEB, "ANCHOR_TOP", 0, 10)
                GameTooltip:SetText(aEB.tiptext, nil, nil, nil, nil, true)
                GameTooltip:Show()
            end)

            aEB:HookScript("OnLeave", function()
                -- Set link text again if it's changed since it was set
                if aEB:GetText() ~= lastAchievementLink then
                    aEB:SetText(lastAchievementLink)
                end
                aEB:HighlightText(0, 0)
                aEB:ClearFocus()
                GameTooltip:Hide()
            end)

            -- Hide editbox when achievement is deselected
            hooksecurefunc("AchievementFrameAchievements_ClearSelection", function(self)
                aEB:Hide()
            end)
            hooksecurefunc("AchievementCategoryButton_OnClick", function(self)
                aEB:Hide()
            end)

        end

        -- Run function when achievement UI is loaded
        if IsAddOnLoaded("Blizzard_AchievementUI") then
            DoWowheadAchievementFunc()
        else
            local waitAchievementsFrame = CreateFrame("FRAME")
            waitAchievementsFrame:RegisterEvent("ADDON_LOADED")
            waitAchievementsFrame:SetScript("OnEvent", function(self, event, arg1)
                if arg1 == "Blizzard_AchievementUI" then
                    DoWowheadAchievementFunc()
                    waitAchievementsFrame:UnregisterAllEvents()
                end
            end)
        end

        ----------------------------------------------------------------------
        -- World map frame
        ----------------------------------------------------------------------

        -- Create editbox
        local mEB = CreateFrame("EditBox", nil, QuestLogFrame)
        mEB:ClearAllPoints()
        mEB:SetPoint("TOPLEFT", 70, 4)
        mEB:SetHeight(16)
        mEB:SetFontObject("GameFontNormal")
        mEB:SetBlinkSpeed(0)
        mEB:SetAutoFocus(false)
        mEB:EnableKeyboard(true)
        mEB:SetHitRectInsets(0, 90, 0, 0)
        mEB:SetScript("OnKeyDown", function()
        end)
        mEB:SetScript("OnMouseUp", function()
            if mEB:IsMouseOver() then
                mEB:HighlightText()
            else
                mEB:HighlightText(0, 0)
            end
        end)

        -- Set the background color
        mEB.t = mEB:CreateTexture(nil, "BACKGROUND")
        mEB.t:SetPoint(mEB:GetPoint())
        mEB.t:SetSize(mEB:GetSize())
        mEB.t:SetVertexColor(0.05, 0.05, 0.05, 1.0)

        -- Create hidden font string (used for setting width of editbox)
        mEB.z = mEB:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
        mEB.z:Hide()

        -- Function to set editbox value
        local function SetQuestInBox(questListID)

            local questTitle, void, void, void, isHeader, void, void, void, questID = GetQuestLogTitle(questListID)
            if questID and not isHeader then

                -- Hide editbox if quest ID is invalid
                if questID == 0 then
                    mEB:Hide()
                else
                    mEB:Show()
                end

                -- Set editbox text
                if LeaPlusLC["WowheadLinkComments"] == "On" then
                    mEB:SetText("https://" .. wowheadLoc .. "/quest=" .. questID .. "#comments")
                else
                    mEB:SetText("https://" .. wowheadLoc .. "/quest=" .. questID)
                end

                -- Set hidden fontstring then resize editbox to match
                mEB.z:SetText(mEB:GetText())
                mEB:SetWidth(mEB.z:GetStringWidth() + 90)
                mEB.t:SetWidth(mEB.z:GetStringWidth())

                -- Get quest title for tooltip
                if questTitle then
                    mEB.tiptext = questTitle .. "|n" .. L["Press CTRL/C to copy."]
                else
                    mEB.tiptext = ""
                    if mEB:IsMouseOver() and GameTooltip:IsShown() then
                        GameTooltip:Hide()
                    end
                end

            end
        end

        -- Set URL when quest is selected (this works with Questie, old method used QuestLog_SetSelection)
        hooksecurefunc("SelectQuestLogEntry", function(questListID)
            SetQuestInBox(questListID)
        end)

        -- Create tooltip
        mEB:HookScript("OnEnter", function()
            mEB:HighlightText()
            mEB:SetFocus()
            GameTooltip:SetOwner(mEB, "ANCHOR_BOTTOM", 0, -10)
            GameTooltip:SetText(mEB.tiptext, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)

        mEB:HookScript("OnLeave", function()
            mEB:HighlightText(0, 0)
            mEB:ClearFocus()
            GameTooltip:Hide()
        end)

        -- ElvUI fix to move Wowhead link inside the quest log frame
        if LeaPlusLC.ElvUI then
            LibCompat.After(0.1, function()
                QuestLogTitleText:ClearAllPoints()
                QuestLogTitleText:SetPoint("TOPLEFT", QuestLogFrame, "TOPLEFT", 32, -18)
                if QuestLogTitleText:GetStringWidth() > 200 then
                    QuestLogTitleText:SetWidth(200)
                else
                    QuestLogTitleText:SetWidth(QuestLogTitleText:GetStringWidth())
                end
                mEB:ClearAllPoints()
                mEB:SetPoint("LEFT", QuestLogTitleText, "RIGHT", 10, 0)
                mEB.t:Hide()
            end)
        end

    end

    ----------------------------------------------------------------------
    -- Automate gossip (no reload required)								--
    ----------------------------------------------------------------------

    do

        local isMessagePrinted = false

        -- Function to skip gossip
        local function SkipGossip(skipAltKeyRequirement)
            if not skipAltKeyRequirement and not IsAltKeyDown() then
                return
            end
            local gossipInfoTable = GetGossipOptions()
            local getnumGossips = GetNumGossipOptions()
            if getnumGossips ~= 0 and GetNumGossipAvailableQuests() == 0 and GetNumGossipActiveQuests() == 0 then
                SelectGossipOption(1)
                if not isMessagePrinted then
                    print("|cFF00ff99Leatrix Plus:|r option chosen. Hold a shift key to override.")
                    isMessagePrinted = true
                end
            end
        end

        -- Reset Message flag when gossip window is closed
        local function ResetMessageFlag()
            isMessagePrinted = false
        end

        -- Create gossip event frame
        local gossipFrame = CreateFrame("FRAME")

        -- Function to setup events
        local function SetupEvents()
            if LeaPlusLC["AutomateGossip"] == "On" then
                gossipFrame:RegisterEvent("GOSSIP_SHOW")
                gossipFrame:RegisterEvent("GOSSIP_CLOSED") -- Added line to register GOSSIP_CLOSED event
            else
                gossipFrame:UnregisterEvent("GOSSIP_SHOW")
                gossipFrame:UnregisterEvent("GOSSIP_CLOSED") -- Added line to unregister GOSSIP_CLOSED event
            end
        end

        -- Setup events when option is clicked and on startup (if option is enabled)
        LeaPlusCB["AutomateGossip"]:HookScript("OnClick", SetupEvents)
        if LeaPlusLC["AutomateGossip"] == "On" then
            SetupEvents()
        end

        -- Create tables for specific NPC IDs (these are automatically selected with no alt key requirement)
        local npcTable = {

            -- Stable masters (https://www.wowhead.com/wotlk/npcs?filter=27;1;0)
            9988, 21518, 15131, 10055, 21517, 11069, 9985, 22469, 19476, 21336, 10060, 16586, 16094, 18250, 16824, 23392, 15722, 9977, 19018, 9987, 19368, 6749, 10058, 22468, 11104, 9986, 13617, 10046, 10048, 10051, 10053, 10054, 17485, 18244, 10045, 24974, 16665, 25037, 16656, 10057, 18984, 9984, 11105, 10056, 16185, 10059, 16764, 11119, 14741, 10085, 10061, 19019, 10052, 10047, 10063, 9979, 17666, 11117, 10049, 17896, 9983, 24905, 9989, 9982, 10050, 9980, 9981, 10062, 9976, 9978, 13616,

            -- Dalaran: Brassbolt Mechawrench (Alliance) and Reginald Arcfire (Horde) (engineer auctioneers)
            35594, 35607,

            -- Banker
            2625, 2455, 2458, 31420, 19318, 3309, 21733, 21732, 29282, 30606, 28676, 30607, 38919, 2461, 18350, 30608, 5060, 2460, 19246, 29530, 17631, 8356, 16617, 17632, 36284, 3496, 4209, 17633, 2457, 16710, 3318, 31421, 4208, 28343, 19034, 2459, 16615, 4550, 17773, 29283, 16616, 8124, 8123, 5099, 31422, 3320, 28680, 28679, 30605, 28678, 28677, 28675, 2996, 36352, 4549, 8119, 38920, 38921, 8357, 7799, 4155, 13917, 19338, 2456, 36351, 30604, 21734,

            -- Flightmaster
            23859, 32571, 28574, 28674, 24795, 28615, 3310, 931, 29480, 1387, 25288, 26851, 18789, 10583, 26878, 11901, 12578, 11900, 20234, 26852, 26881, 27046, 2859, 26602, 10897, 6726, 4312, 26880, 18930, 6706, 16587, 16227, 6026, 4267, 2432, 8610, 28624, 18940, 26847, 1571, 27344, 7823, 28618, 1573, 18938, 8020, 22455, 22935, 4407, 1572, 13177, 8609, 18931, 4321, 2299, 16822, 20762, 12577, 26845, 12617, 17554, 26560, 23736, 4319, 21766, 18937, 19558, 12596, 18939, 7824, 3841, 2835, 28196, 15177, 19317, 18791, 2409, 22216, 8019, 22931, 19583, 2858, 3305, 28623, 18808, 22485, 20515, 18942, 18807, 18785, 2941, 19581, 11138, 4551, 26566, 4317, 10378, 21107, 11899, 26879, 18953, 2851, 3615, 352, 23612, 12740, 12636, 2861, 8018, 2226, 24851, 18788, 24366, 15178, 16189, 16192, 17555, 2995, 3838, 12616, 11139, 2389, 18809, 4314, 28197, 523,
            37888, -- Added manually

            -- Trainer
            31238, 28701, 31247, 28697, 28699, 29631, 28746, 28705, 18988, 26989, 28703, 26953, 8126, 19186, 18987, 35093, 35135, 35133, 26992, 18911, 5482, 28693, 29156, 25277, 25099, 26986, 33676, 26905, 35100, 29233, 26972, 29513, 3494, 18773, 16583, 18753, 19778, 24868, 4752, 26990, 26991, 4732, 26982, 28742, 26975, 28698, 18774, 28694, 33682, 28706, 26956, 27001, 3399, 18993, 26976, 18990, 28700, 33680, 18751, 26964, 19775, 26974, 26997, 3026, 26955, 5159, 4552, 23734, 26999, 26969, 26994, 26980, 4586, 16253, 16588, 26912, 31084, 26907, 18991, 16280, 26960, 26915, 26987, 1430, 26962, 26954, 26910, 19252, 26914, 3028, 7406, 32474, 26963, 18802, 19052, 20914, 18775, 12042, 26988, 30721, 28702, 27000, 7954, 3690, 26998, 26981, 33614, 18779, 26993, 17637, 17634, 26906, 28958, 4772, 5493, 20500, 33613, 4773, 26951, 5518, 16823, 26958, 20511, 5938, 4210, 11869, 11868, 18749, 11865, 18777, 26903, 5174, 8736, 11557, 33638, 18747, 3067, 33610, 29505, 26977, 18772, 28696, 33617, 30722, 6251, 18752, 29194, 30713, 17110, 11867, 5491, 18771, 20791, 26952, 4218, 4753, 17246, 6297, 7944, 1651, 7953, 11870, 15501, 6707, 3332, 17204, 29514, 19185, 23128, 33679, 11017, 27703, 30706, 26995, 18755, 5885, 33611, 7866, 16676, 6286, 4568, 19540, 3064, 29195, 19187, 18776, 18748, 3355, 7867, 3032, 5161, 3412, 3352, 4217, 18018, 4606, 23127, 33615, 5513, 19180, 5511, 8306, 908, 11866, 4573, 925, 5127, 3324, 28472, 18754, 837, 2704, 19184, 28474, 3373, 26959, 28704, 30717, 928, 8146, 10993, 28956, 16681, 20407, 19063, 1218, 3036, 543, 375, 16646, 4156, 3136, 16773, 11074, 16621, 9584, 19539, 3347, 223, 11097, 3345, 6288, 987, 3401, 912, 5958, 7311, 8738, 26564, 1681, 7869, 7870, 461, 915, 985, 8128, 916, 3033, 16771, 16663, 957, 1346, 19341, 3365, 16499, 911, 13283, 29509, 2327, 3030, 5566, 17222, 3001, 5172, 33683, 33621, 3327, 895, 15400, 4258, 17215, 4211, 2367, 4165, 13417, 7871, 5564, 22477, 914, 2836, 16266, 2399, 7312, 1231, 14740, 1382, 11025, 11401, 5502, 2818, 5392, 3326, 3606, 5173, 13084, 17101, 30715, 4219, 4254, 11098, 17513, 11406, 376, 16653, 17509, 11072, 29196, 19340, 16633, 5880, 3967, 33608, 16662, 4215, 3047, 6291, 7946, 5515, 3181, 17520, 7231, 5113, 20124, 8144, 16755, 5506, 2798, 16277, 17481, 4212, 11073, 4588, 16669, 5144, 5149, 1701, 19251, 11031, 17482, 5165, 4576, 1473, 1317, 3137, 2329, 16721, 17219, 1458, 16684, 3607, 5957, 5690, 1355, 3963, 16667, 1229, 986, 3039, 5497, 27034, 3344, 3013, 3063, 28471, 2492, 27705, 913, 3357, 16719, 5166, 16679, 3034, 3354, 3706, 3041, 3007, 19576, 16728, 16658, 3009, 5114, 7232, 4598, 927, 20406, 5115, 5164, 6306, 16680, 2837, 3555, 3175, 8153, 30709, 5943, 514, 16647, 5505, 3171, 2857, 11052, 11029, 17483, 5495, 17844, 3406, 16651, 1632, 2390, 5148, 10090, 16367, 4593, 2129, 4609, 17488, 5498, 16774, 4214, 1470, 11037, 5492, 1404, 5499, 1292, 4591, 4583, 2834, 11397, 11096, 5137, 1386, 5496, 33618, 3173, 4163, 5171, 7088, 17212, 3040, 6295, 20125, 4160, 16660, 17484, 19369, 4611, 1676, 3353, 1234, 27704, 1411, 4138, 3170, 3038, 16640, 12961, 5941, 12032, 3045, 1226, 2489, 7089, 17442, 16752, 16726, 11177, 29506, 918, 5882, 15513, 10276, 5504, 4089, 5177, 3169, 6018, 5479, 4090, 23534, 1385, 5484, 2128, 4582, 23103, 4205, 16749, 17487, 5167, 16269, 5157, 17441, 16655, 11146, 11028, 3154, 3602, 2998, 17121, 3707, 3964, 3600, 16659, 16688, 3363, 1228, 12030, 12025, 16725, 16686, 16275, 16731, 1700, 377, 6287, 16366, 15283, 5939, 7949, 3065, 4900, 812, 16161, 4087, 1232, 17514, 11068, 17245, 16644, 16756, 8141, 16736, 3545, 2119, 7315, 3290, 16738, 3172, 16780, 3174, 16685, 5883, 17089, 5612, 9465, 4584, 4193, 3179, 10086, 5480, 4596, 3404, 5153, 4578, 5145, 4563, 4566, 16272, 17504, 16503, 7948, 3061, 331, 16160, 3604, 29507, 3597, 15284, 3044, 3605, 16654, 3066, 5150, 5146, 3328, 15285, 4567, 16729, 3155, 5567, 2391, 3407, 1383, 11026, 3004, 5516, 16500, 1246, 10088, 328, 16502, 30710, 5994, 1215, 8308, 17214, 2856, 16501, 2131, 4595, 17120, 3698, 11178, 1702, 5489, 4320, 16642, 3069, 3603, 10930, 11044, 6387, 459, 17005, 11081, 17511, 2114, 3046, 4204, 3594, 3153, 16712, 3060, 2627, 1699, 1466, 3622, 10277, 3557, 16675, 3059, 17983, 17519, 2124, 17510, 11066, 15279, 5501, 1901, 3043, 198, 17505, 7087, 33681, 11047, 3598, 11070, 4092, 2485, 4616, 1300, 16723, 5884, 3008, 11067, 2130, 4614, 2126, 3062, 3184, 11041, 3325, 17434, 11071, 3156, 5759, 5116, 2878, 18804, 16652, 3688, 16763, 17480, 2127, 7868, 3042, 16278, 3549, 3157, 10089, 2855, 4213, 16279, 11084, 5500, 5141, 10278, 3049, 5143, 16692, 10266, 1703, 5147, 11051, 11048, 1683, 11046, 16674, 3624, 3593, 17424, 4594, 3596, 16761, 4605, 3523, 4898, 6094, 2132, 3087, 3965, 11083, 2123, 2122, 3601, 6292, 1103, 4607, 4608, 3620, 4091, 15280, 4146, 5811, 2879, 988, 3306, 3484, 3703, 4564, 3704, 16273, 1680, 4159, 16724, 3185, 16276, 6289, 5117, 11049, 4565, 3595, 7230, 3403, 11042, 16672, 3011, 16271, 2326, 11065, 5517, 3031, 1241, 3478, 11050, 3048, 5695, 17122, 5784, 6014, 6290, 16648, 3408, 5142, 926, 8140, 6299, 19478, 21087, 16270, 3599, 8142, 917, 944, 16673, 460, 906,

            -- Vendor
            30431, 32538, 32287, 32540, 32533, 31238, 29529, 28997, 32172, 31580, 27730, 28995, 28701, 32763, 32565, 28992, 29636, 8137, 31579, 29523, 32514, 31582, 18960, 32216, 28721, 35507, 32564, 28718, 7947, 18484, 29537, 12781, 20096, 18988, 32515, 340, 19186, 18987, 31863, 19296, 29535, 31581, 31031, 18911, 4561, 2664, 8139, 28722, 16585, 35508, 20097, 25206, 8145, 19663, 35498, 31910, 32773, 19373, 32380, 20028, 12022, 2810, 18011, 28715, 12793, 2821, 29547, 21655, 4229, 18015, 31032, 32385, 18773, 2803, 2806, 16583, 18753, 19004, 31916, 5494, 8125, 32509, 29493, 19213, 28742, 66, 29744, 32774, 18756, 18774, 16786, 12919, 15174, 33026, 18993, 29532, 20916, 1448, 18990, 30472, 16826, 29527, 3556, 19383, 18751, 34252, 28951, 28714, 29587, 25977, 5940, 19038, 31911, 1465, 29478, 18382, 3027, 14846, 2685, 31865, 31864, 21113, 28776, 12944, 16253, 19662, 3482, 16588, 16657, 3323, 14753, 5594, 19837, 24539, 30885, 12783, 18005, 18991, 4877, 19074, 12246, 10618, 7564, 12245, 26484, 12788, 28040, 1275, 18957, 32834, 12778, 19575, 14754, 20980, 21432, 17904, 18525, 13219, 35496, 23489, 32594, 19042, 12796, 18802, 8678, 16782, 29528, 16624, 3489, 4574, 5162, 32832, 18775, 5817, 6548, 11189, 29628, 26941, 17512, 28687, 2393, 1286, 20080, 14847, 32383, 35497, 9499, 19227, 20240, 3954, 8666, 12043, 1148, 19661, 11185, 28692, 27037, 25046, 19617, 29715, 29491, 11187, 16823, 28589, 3348, 13217, 3313, 30006, 18749, 6367, 3497, 21643, 22212, 5483, 16860, 28038, 30825, 7775, 15419, 4305, 11557, 33638, 29049, 3546, 22208, 4879, 3333, 32631, 27012, 4897, 1257, 19331, 15127, 26977, 25314, 18772, 2663, 6779, 13218, 23732, 28990, 14860, 26110, 14624, 1285, 1263, 14322, 33027, 15126, 18897, 35099, 3335, 2381, 23007, 14921, 18752, 16262, 5519, 1684, 3029, 21019, 32356, 35500, 29495, 18771, 29497, 32337, 17657, 12033, 27011, 32381, 3881, 26938, 27668, 2480, 734, 13216, 5188, 17585, 23381, 17246, 233, 4307, 32382, 20377, 21474, 20241, 8665, 19772, 4453, 3346, 35132, 13476, 9179, 20242, 27722, 22213, 8401, 28685, 19196, 24780, 1301, 5193, 33679, 12795, 6746, 27039, 16635, 277, 4731, 5942, 24291, 29716, 19694, 15179, 26995, 3960, 19521, 20981, 16602, 19232, 3550, 23802, 25032, 1303, 35101, 30723, 29548, 19540, 27721, 3362, 989, 24341, 1460, 28991, 12943, 28993, 1347, 31781, 2848, 23367, 29496, 13433, 1318, 8679, 4200, 4217, 18672, 18018, 23604, 11056, 21485, 16631, 26352, 5101, 5151, 2832, 16528, 4553, 19182, 5611, 483, 29688, 18427, 7854, 21906, 5049, 24357, 167, 3614, 12794, 25976, 12384, 29499, 2805, 32641, 32334, 16015, 1307, 10667, 19538, 35131, 3495, 32639, 8161, 12942, 27142, 8681, 3413, 30730, 27063, 29203, 11057, 19197, 3133, 32413, 4226, 20278, 3400, 14637, 15351, 18754, 5514, 152, 29702, 15006, 5160, 31776, 5175, 15350, 789, 5815, 28723, 11278, 3334, 3366, 1261, 3081, 2670, 1302, 12957, 26600, 19053, 843, 1325, 5565, 25195, 21183, 27267, 28691, 8361, 3342, 27134, 829, 19539, 384, 1299, 222, 945, 29703, 12096, 3562, 4981, 836, 981, 3490, 22491, 9636, 2383, 227, 5753, 19857, 226, 2626, 12785, 3023, 6777, 26596, 2118, 20510, 17553, 16376, 16638, 24396, 29291, 980, 3685, 15165, 1311, 19015, 10118, 13420, 19321, 16264, 23521, 844, 8158, 2838, 1304, 28726, 956, 25178, 8176, 11555, 6740, 258, 793, 1237, 74, 23748, 4730, 791, 3351, 4577, 28725, 24188, 5178, 984, 982, 31557, 16442, 28994, 15293, 17222, 11038, 2672, 15197, 958, 20092, 28727, 1328, 16268, 19678, 3358, 4575, 29538, 9501, 372, 19342, 32354, 15471, 12784, 1313, 7955, 959, 27144, 4265, 4225, 19773, 4221, 17584, 26898, 896, 8404, 15400, 25196, 2481, 3364, 4165, 2687, 1213, 29905, 18907, 5111, 6929, 15291, 29510, 3135, 28716, 29908, 16224, 30438, 21905, 18266, 2482, 26945, 1321, 27138, 32355, 27030, 19536, 1298, 14437, 23437, 14740, 30735, 12792, 5848, 32412, 2380, 31804, 12799, 27195, 3488, 1146, 12956, 5173, 9087, 4602, 5128, 21112, 32477, 1669, 17101, 1250, 1314, 27935, 14337, 10216, 29962, 6741, 8150, 1305, 4590, 1287, 33019, 4878, 17930, 13018, 23159, 1308, 3955, 23208, 27711, 14522, 27146, 15011, 26599, 27031, 3481, 1291, 20986, 16708, 28728, 11188, 3369, 3493, 960, 1289, 23484, 19879, 11116, 1471, 12941, 4083, 1454, 3536, 3015, 4173, 8157, 16829, 12024, 32642, 27052, 18954, 16191, 20808, 16649, 1149, 4228, 25278, 16611, 3537, 28989, 29512, 1294, 24054, 27071, 5163, 27148, 16709, 16722, 3168, 4184, 3018, 23731, 17630, 6807, 8403, 23428, 6574, 3359, 8178, 4085, 24468, 7852, 11536, 23145, 7945, 10367, 27019, 2622, 1690, 5158, 29907, 7952, 2135, 4604, 7683, 4610, 14480, 19932, 1312, 25274, 11183, 24033, 23263, 26936, 2697, 3578, 20494, 12019, 29288, 26934, 18898, 4585, 3367, 12097, 3085, 29014, 4885, 16444, 2265, 16766, 3410, 19574, 16641, 19011, 26868, 1645, 27489, 22225, 20807, 1407, 3935, 2819, 16636, 3409, 23896, 1316, 16705, 3350, 20616, 228, 21488, 5110, 21084, 27817, 16553, 18906, 4894, 6374, 12021, 3577, 2668, 3180, 29277, 30434, 6300, 4170, 5100, 4556, 8508, 3962, 6731, 1247, 33018, 4892, 12023, 28046, 3134, 3958, 4558, 5758, 27140, 3658, 12959, 27186, 3551, 19718, 16678, 29122, 18017, 27055, 32478, 32416, 3178, 18019, 15864, 16612, 6568, 18542, 26569, 28707, 27667, 28796, 24333, 18267, 20081, 16367, 1351, 16739, 29922, 54, 29205, 4220, 19371, 2397, 26968, 15292, 23862, 21110, 2682, 32638, 3316, 28760, 3956, 2264, 7733, 6747, 19495, 2388, 7736, 6730, 5512, 3322, 19474, 3937, 1691, 27185, 27053, 28812, 27478, 19330, 19047, 26707, 1694, 11874, 19836, 2134, 8878, 12026, 4241, 12029, 2364, 1323, 3539, 19450, 16677, 19473, 8177, 14581, 14371, 30439, 1326, 5189, 4259, 27938, 19013, 19245, 3534, 2679, 8117, 16443, 18664, 26474, 27137, 27149, 8131, 6576, 31024, 12777, 12782, 20378, 20249, 7940, 24148, 19533, 19534, 27950, 24510, 4891, 23064, 4555, 19518, 4223, 6567, 12958, 4256, 23511, 24408, 5112, 16748, 26908, 18564, 2352, 5688, 6790, 6791, 3610, 19195, 13435, 30241, 17489, 19560, 13434, 24975, 32421, 19020, 30724, 3533, 3076, 4183, 2814, 16767, 8160, 30572, 19479, 16632, 18810, 16263, 16718, 18009, 3528, 3532, 27181, 491, 31115, 7879, 2699, 2684, 2688, 27057, 28871, 15199, 14737, 5520, 23606, 7976, 4562, 24342, 5169, 4899, 15176, 2842, 22099, 20082, 26568, 16664, 25248, 3952, 23244, 8359, 18581, 28807, 2816, 20463, 18255, 2113, 10856, 23522, 16713, 4893, 5620, 3097, 7978, 5570, 3096, 28827, 4182, 4266, 16683, 26398, 2137, 4587, 16670, 2845, 3091, 3298, 4600, 2698, 5820, 4232, 1692, 16716, 19561, 2839, 2844, 30731, 18905, 1464, 6930, 28682, 3491, 25245, 2483, 15012, 2401, 1697, 3589, 3588, 4231, 5748, 8305, 5411, 5870, 8362, 29511, 19520, 27147, 27143, 1297, 5129, 19239, 18010, 2394, 4888, 28791, 16620, 2357,

            -- Battlemaster and Arenamaster
            12197, 29318, 15006, 26007, 857, 907, 35007, 19859, 3890, 7029, 35023, 15008, 34999, 15972, 34955, 7885, 34991, 19905, 14981, 14982, 19907, 347, 7427, 7410, 20271, 19855, 29568, 19858, 2302, 14942, 17506, 15007, 34983, 5238, 29234, 32332, 1037, 10360, 2804, 30578, 20388, 30171, 5118, 18439, 32333, 20120, 19908, 30581, 20118, 14879, 16711, 20381, 35024, 22516, 25991, 20200, 7314, 20269, 34895, 35027, 30583, 18895, 20272, 30584, 35017, 19811, 20386, 34971, 20273, 34972, 19915, 20274, 30587, 20390, 19923, 20497, 34976, 12198, 19925, 16695, 20362, 35022, 20499, 14623, 16696, 20374, 21235, 19909, 40413, 20382, 32330, 20119, 30579, 35000, 34985, 30580, 35001, 35025, 35002, 17507, 20383, 34437, 35026, 20384, 19910, 35008, 20385, 19912, 29533, 30586, 35019, 34993, 35020, 16694, 30231, 19906, 34986, 34987, 19911, 34989, 30590, 35021, 30610, 30582, 34988, 20276, 34978, 34973, 34997, 34998,

            -- Quests
            10668

        }

        -- --===== create ignore NPC table to not mess with npcTable and for future user options =====--
        -- local npcIgnore = {

        -- 	-- Innkeepers
        -- 	5111, 6740

        -- }


        -- Event handler
        gossipFrame:SetScript("OnEvent", function(self, event, ...)
            if event == "GOSSIP_SHOW" then
                -- Special treatment for specific NPCs
                local npcGuid = UnitGUID("target") or nil

                local void, gossipType = GetGossipOptions()
                if gossipType == "binder"
                        or gossipType == "trainer"
                then
                    return
                end

                if npcGuid and not IsShiftKeyDown() then
                    local npcID = LibCompat.GetUnitCreatureId("target")
                    -- print(npcID)
                    if npcID then
                        -- Open rogue doors in Dalaran (Broken Isles) automatically
                        if npcID == "96782"        -- Lucian Trias
                                or npcID == "93188"        -- Mongar
                                or npcID == "97004"        -- "Red" Jack Findle
                        then
                            SkipGossip()
                            return
                        end
                        -- Skip gossip with no alt key requirement
                        if npcID == "132969"    -- Katy Stampwhistle (toy)
                                or npcID == "104201"    -- Katy Stampwhistle (npc)
                                or tContains(npcTable, tonumber(npcID))
                        -- and not tContains(npcIgnore, tonumber(npcID))
                        then
                            SkipGossip(true)    -- true means skip alt key requirement
                            return
                        end
                    end
                end
                -- Process gossip
                SkipGossip()

            elseif event == "GOSSIP_CLOSED" then
                -- Reset Message flag when gossip window is closed
                ResetMessageFlag()
            end
        end)

    end

    ----------------------------------------------------------------------
    --	Faster looting
    ----------------------------------------------------------------------

    if LeaPlusLC["FasterLooting"] == "On" then

        --===== WA Custom Options - Sound database  =====--
        local soundFiles = {
            [1] = "Sound/Interface/Pickup/putDownRocks_Ore01.wav",
            [2] = "sound/character/gnome/gnomemaleerrormessages/gnomemale_err_inventoryfull01.wav",
            [3] = "sound/character/dwarf/dwarfmaleerrormessages/dwarfmale_err_inventoryfull02.wav",
            -- Add more sound file paths if needed
        }

        -- Create configuration panel
        --local weatherSliderTable = {L["Very Low"], L["Low"], L["Medium"], L["High"]}
        --LeaPlusCB["WeatherLevel"].f:SetText(LeaPlusLC["WeatherLevel"] .. "  (" .. weatherSliderTable[LeaPlusLC["WeatherLevel"] + 1] .. ")")
        local FasterLootPanel = LeaPlusLC:CreatePanel("Faster Looting", "FasterLootPanel")

        LeaPlusLC:MakeTx(FasterLootPanel, "Settings", 16, -72)
        LeaPlusLC:MakeCB(FasterLootPanel, "SmallerErrorFrame", "Smaller Error Frame", 16, -92, false, "If checked, your red error text frame, will be only one line long.")
        LeaPlusLC:MakeCB(FasterLootPanel, "FasterErrorFrame", "Faster Error Frame", 16, -112, false, "If checked, your red error text frame, will be faster to fade|n(1 second instead of 5).")

        LeaPlusLC:MakeTx(FasterLootPanel, "Full Inventory Sound", 356, -72)
        LeaPlusLC:MakeSL(FasterLootPanel, "FullInvSound", "Drag to set the desired sound played when your inventory is Full. Set 0 to disable sound.", 0, 3, 1, 356, -92, "%.0f")

        local FullInvSoundSliderTable = { "Disabled", "Default", "Gnome", "Dwarf" }
        local function SetFullInvSliderText()
            -- set text next to the number of sound from FullInvSoundSliderTable
            LeaPlusCB["FullInvSound"].f:SetText(LeaPlusLC["FullInvSound"] .. "  (" .. FullInvSoundSliderTable[LeaPlusLC["FullInvSound"] + 1] .. ")")
            local soundPath = soundFiles[LeaPlusLC["FullInvSound"]]
            if soundPath then
                PlaySoundFile(soundPath, "Sound")
            end
        end

        --===== Function to make error frame contain only 1 line =====--
        --===== It also checks if frame is not already 1 line, to make sure error frame doesnt get hidden fully. =====--
        local function SetErrorFrameHeight()
            local errorFrameHeight = 20
            if LeaPlusLC["SmallerErrorFrame"] == "On" then

                if UIErrorsFrame:GetHeight() ~= errorFrameHeight then

                    UIErrorsFrame:SetHeight(errorFrameHeight)

                end
            else
                UIErrorsFrame:SetHeight(60)
            end
        end
        SetErrorFrameHeight()

        local function SetErroFrameFadeTime()
            if LeaPlusLC["FasterErrorFrame"] == "On" then
                UIErrorsFrame:SetTimeVisible(1)
            else
                UIErrorsFrame:SetTimeVisible(5)
            end
        end
        SetErroFrameFadeTime()

        LeaPlusCB["FullInvSound"]:HookScript("OnValueChanged", SetFullInvSliderText)
        LeaPlusCB["SmallerErrorFrame"]:HookScript("OnClick", SetErrorFrameHeight)
        LeaPlusCB["FasterErrorFrame"]:HookScript("OnClick", SetErroFrameFadeTime)



        -- Help button hidden
        FasterLootPanel.h:Hide()

        -- Back button handler
        FasterLootPanel.b:SetScript("OnClick", function()
            FasterLootPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page7"]:Show();
            return
        end)

        -- Reset button handler
        FasterLootPanel.r:SetScript("OnClick", function()

            -- Reset checkboxes
            LeaPlusLC["SmallerErrorFrame"] = "Off"
            LeaPlusLC["FasterErrorFrame"] = "Off"
            LeaPlusLC["FullInvSound"] = 1
            UIErrorsFrame:SetHeight(60)
            UIErrorsFrame:SetTimeVisible(5)
            -- Refresh panel
            FasterLootPanel:Hide();
            FasterLootPanel:Show()

        end)

        -- Show panal when options panel button is clicked
        LeaPlusCB["ModFasterLootingBtn"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["SmallerErrorFrame"] = "On"
                LeaPlusLC["FasterErrorFrame"] = "On"
                LeaPlusLC["FullInvSound"] = 1
                UIErrorsFrame:SetHeight(20)
                UIErrorsFrame:SetTimeVisible(1)
            else
                FasterLootPanel:Show()
                LeaPlusLC:HideFrames()
            end
        end)

        --------------------------------------------------------------------------------
        -- Code taken, and modified by Sattva.
        -- Source code is from SpeedyAutoLoot addon.
        -- Increase speed of looting singnificantly. Makes the feel of it better.
        -- The main approach is to not load the looting window, when is not needed.
        -- It was initially made for my WeakAura https://wago.io/uGLs2fARD
        --------------------------------------------------------------------------------


        local AutoLoot = CreateFrame("Frame")
        -- local aura_env = aura_env or {}

        local SetCVar = SetCVar
        local BACKPACK_CONTAINER, LOOT_SLOT_ITEM, NUM_BAG_SLOTS = BACKPACK_CONTAINER, LOOT_SLOT_ITEM, NUM_BAG_SLOTS
        local GetContainerNumFreeSlots = GetContainerNumFreeSlots
        local GetCursorPosition = GetCursorPosition
        local GetItemCount = GetItemCount
        local GetItemInfo = GetItemInfo
        local GetLootSlotInfo = GetLootSlotInfo
        local GetLootSlotLink = GetLootSlotLink
        local GetNumLootItems = GetNumLootItems
        local IsModifiedClick = IsModifiedClick
        local LootSlot = LootSlot
        local band = bit.band
        local select = select
        local tContains = tContains
        _G.ElvLootFrame = ElvLootFrame
        _G.ElvLootFrameHolder = ElvLootFrameHolder
        local slotType = slotType
        local invFullSoundPlayed = false

        --===== Check for if 3.3.5 or 2.4.3 game client. =====--
        local isTBC = select(4, GetBuildInfo()) == 20400 -- true if TBC 2.4.3
        local isWOTLK = select(4, GetBuildInfo()) == 30300 -- true if WOTLK 3.3.5


        -----------------------------------------------------------------
        -- Function checks for if player has free bag slots,
        -- If not then checks if looted item can fit in existing stacks.
        -----------------------------------------------------------------

        function AutoLoot:ProcessLoot(item, q)

            local total, free, bagFamily = 0
            local itemFamily = GetItemFamily(item)

            for i = BACKPACK_CONTAINER, NUM_BAG_SLOTS do

                free, bagFamily = GetContainerNumFreeSlots(i)

                if (not bagFamily or bagFamily == 0) or (itemFamily and band(itemFamily, bagFamily) > 0) then

                    total = total + free

                end

            end

            if total > 0 then

                return true

            end

            local have = (GetItemCount(item) or 0)
            if have > 0 then

                local itemStackCount = (select(8, GetItemInfo(item)) or 0)
                if itemStackCount > 1 then

                    while have > itemStackCount do

                        have = have - itemStackCount

                    end

                    local remain = itemStackCount - have
                    if remain >= q then

                        return true

                    end

                end

            end

            return false

        end

        --------------------------------------------------------------------------------
        -- Function checks and helps to handle (show, hide) ElvUI looting frame.
        -- It also helps to handle default looting frame.
        --------------------------------------------------------------------------------


        function AutoLoot:ShowLootFrame(show)
            -- print("ShowLootFrame: Show: " .. tostring(show))

            if IsAddOnLoaded("ElvUI") then
                -- print("ShowLootFrame: ElvUI loaded")
                if show then
                    -- print("ShowLootFrame: Show ElvLootFrame")
                    ElvLootFrame:SetParent(ElvLootFrameHolder)
                    ElvLootFrame:SetFrameStrata("HIGH")
                    self:LootUnderMouse(ElvLootFrame, ElvLootFrameHolder, 20)
                    self.isHidden = false
                else
                    -- print("ShowLootFrame: Hide ElvLootFrame")
                    ElvLootFrame:SetParent(self)
                    self.isHidden = true
                end
            elseif LootFrame:IsEventRegistered("LOOT_SLOT_CLEARED") then
                -- print("ShowLootFrame: Default UI loot frame")
                LootFrame.page = 1;
                if show then
                    if isWOTLK then
                        LootFrame_Show(LootFrame)
                    elseif isTBC then
                        ShowUIPanel(LootFrame)
                    end
                    self.isHidden = false
                else
                    -- HideUIPanel(LootFrame)
                    self.isHidden = true
                end
            else
                -- print("ShowLootFrame: No valid loot frames")
                self.isHidden = true
            end
            -- print("ShowLootFrame: Done")
        end




        ----------------------------------------------------------------------------------------------------
        -- Function to automate looting items, before looting it checks for if item is being master looted.
        ----------------------------------------------------------------------------------------------------



        function AutoLoot:LootItems(numItems)

            local lootThreshold = (self.isClassic and select(2, GetLootMethod()) == 0) and GetLootThreshold() or 10
            for i = numItems, 1, -1 do

                local itemLink = GetLootSlotLink(i)
                local _, _, lootQuantity, rarity, locked = GetLootSlotInfo(i)
                -- print("itemLink: ", itemLink, "quantity: ", lootQuantity, "quality: ", rarity, "locked: ", locked)

                if locked or (rarity and rarity >= lootThreshold) then

                    -- print("item is locked")
                    self.isItemLocked = true

                else

                    --===== FIX ME =====--
                    --===== not sure why there is slotType ~= LOOT_SLOT_ITEM, its not defined =====--
                    if slotType ~= LOOT_SLOT_ITEM or self:ProcessLoot(itemLink, lootQuantity) then
                        -- print("It's working!")

                        numItems = numItems - 1
                        LootSlot(i)

                    end
                end
            end

            if numItems > 0 then

                self:ShowLootFrame(true)

            end

        end


        --------------------------------------------------------------------------------
        -- Function to filter error messages
        --------------------------------------------------------------------------------


        -- if aura_env.config["error_filter"] then

        --local AutoLootErrScript = UIErrorsFrame:GetScript('OnEvent')
        --
        ---- Error message events
        --UIErrorsFrame:SetScript('OnEvent', function (self, event, AutoLootError, ...)
        --
        --	-- Handle error messages
        --	if event == "UI_ERROR_MESSAGE" then
        --
        --		-- if aura_env.config["error_filter"] then
        --
        --		if  AutoLootError == ERR_LOOT_GONE or
        --				AutoLootError == ERR_LOOT_DIDNT_KILL or
        --				AutoLootError == ERR_NO_LOOT then
        --
        --			return -- hide the error message
        --
        --		end
        --
        --		-- else
        --
        --		--     return -- hide the error message
        --
        --		-- end
        --	end
        --
        --	return AutoLootErrScript(self, event, AutoLootError, ...)
        --
        --end)

        -- end


        -------------------------------------------------------------------------------------
        -- Function to handle all events related to looting.
        -- Such as opening/closing loot windows and checking for inventory space.
        --------------------------------------------------------------------------------



        function AutoLoot:OnEvent(e, ...)

            --===== Loot functions are called here =====--
            if (e == "LOOT_READY" or e == "LOOT_OPENED") and not self.isLooting then

                local numItems = GetNumLootItems()


                --===== if nothing to loot, stop script =====--
                if numItems == 0 then

                    return

                end

                self.isLooting = true
                self.isHidden = true


                --===== Checks for if modifier is held and stops looting if given errors are fired, to avoid looping when it's not needed  =====--
                if not IsModifiedClick("AUTOLOOTTOGGLE") and not tContains(({ ERR_INV_FULL, ERR_ITEM_MAX_COUNT, ERR_LOOT_ROLL_PENDING }), select(1, ...)) then

                    self:LootItems(numItems)
                    -- print("loot")

                else

                    self:ShowLootFrame(true)
                    -- print("show")

                end

            elseif e == "LOOT_CLOSED" then

                self.isLooting = false
                self.isHidden = false
                self.isItemLocked = false
                self:ShowLootFrame(false)
                invFullSoundPlayed = false


                --===== If inventory is full or you have too many of items, show loot frame and play sound. =====--
            elseif tContains(({ ERR_INV_FULL, ERR_ITEM_MAX_COUNT }), select(1, ...)) then
                if not invFullSoundPlayed and self.isLooting then

                    AutoLoot:OnInvFull()
                    invFullSoundPlayed = true

                end

                --===== If item being rolled for (Group Loot), show loot frame. =====--
            elseif tContains(({ ERR_LOOT_ROLL_PENDING }), select(1, ...)) then

                if self.isLooting then

                    self:ShowLootFrame(true)
                    -- print("pickup")

                end


            elseif e == "LOOT_BIND_CONFIRM" then

                if self.isLooting and self.isHidden then

                    AutoLoot:OnBindConfirm()

                end

            elseif e == "OPEN_MASTER_LOOT_LIST" then

                if self.isLooting and self.isHidden then

                    self:ShowLootFrame(true);
                    -- print("master loot")

                end

                -- elseif e == "PLAYER_LOGIN" or e == "ADDON_LOADED" and aura_env.config["autoLootGlobalEnabled"] then
            elseif e == "PLAYER_LOGIN" or e == "ADDON_LOADED" then

                if isTBC then

                    SetCVar("autoLootCorpse", 1)

                elseif isWOTLK then

                    SetCVar("autoLootDefault", 1)

                end


                --===== Disable Auto Loot button in Interface menu and add tooltip to it. =====--
                -- if aura_env.config["autoLootGlobalEnabled"] then

                InterfaceOptionsControlsPanelAutoLootCorpse:Disable()

                local autoLootText = InterfaceOptionsControlsPanelAutoLootCorpseText
                autoLootText:SetText("Auto Loot option is controlled by Leatrix Plus.")
                autoLootText:SetAlpha(0.6)

                -- print("Auto Loot Set")

                -- else

                --     InterfaceOptionsControlsPanelAutoLootCorpse:Enable()

                -- end


            end

        end


        --------------------------------------------------------------------------------
        -- Inventory Full Function
        --------------------------------------------------------------------------------


        function AutoLoot:OnInvFull()

            local soundIndex = LeaPlusLC["FullInvSound"]

            local soundPath = soundFiles[soundIndex]
            if soundPath then
                PlaySoundFile(soundPath, "Sound")
            end

            self:ShowLootFrame(true)
            -- print("inv full")

        end


        --------------------------------------------------------------------------------
        -- Bind confirm Function
        --------------------------------------------------------------------------------

        function AutoLoot:OnBindConfirm(slot)

            if self.isLooting then

                self:ShowLootFrame(true);
                -- print("bind confirm")

            end

        end


        --------------------------------------------------------------------------------
        -- Function to make sure the Looting Window is positioned well, when shown.
        --------------------------------------------------------------------------------



        function AutoLoot:LootUnderMouse(frame, parent, yoffset)
            if (GetCVar("lootUnderMouse") == "1") then
                local x, y = GetCursorPosition()
                x = x / frame:GetEffectiveScale()
                y = y / frame:GetEffectiveScale()

                frame:ClearAllPoints()
                frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x - 40, y + (yoffset or 20))
                frame:GetCenter()
                frame:Raise()

                -- print("Loot under mouse enabled. Positioning frame under cursor.")

            else
                frame:ClearAllPoints()
                frame:SetPoint("TOPLEFT", parent, "TOPLEFT")

                -- print("Loot under mouse disabled. Positioning frame at top-left of parent.")
            end
        end



        --------------------------------------------------------------------------------
        -- Function to setup events.
        --------------------------------------------------------------------------------


        function AutoLoot:OnLoad()

            -- if (aura_env.config["errorFaster"] or aura_env.config["error_tiny"])  then

            --===== Function to make error frame fade out animation faster. =====--
            -- if aura_env.config["errorFaster"] then

            --UIErrorsFrame:SetTimeVisible(1)

            -- end




            self:SetToplevel(true)
            self:Hide()

            --===== Function sets the OnEvent script for the AutoLoot frame to call the self:OnEvent(...) function. =====--
            --===== Whenever an event is detected by the addon. =====--
            self:SetScript("OnEvent", function(_, ...)

                self:OnEvent(...)

            end)

            for _, e in next, ({ "ADDON_LOADED", "PLAYER_LOGIN", "LOOT_READY", "LOOT_OPENED", "LOOT_CLOSED", "UI_ERROR_MESSAGE", "CVAR_UPDATE", "LOOT_BIND_CONFIRM", "OPEN_MASTER_LOOT_LIST" }) do

                self:RegisterEvent(e)

            end


            -- I did not change this for 2.4.3 and 3.3.5, it's working, so i let it be "Classic" :D
            self.isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)

            if self.isClassic then

                -- print("classic")
                self:RegisterEvent("LOOT_BIND_CONFIRM")
                self:RegisterEvent("OPEN_MASTER_LOOT_LIST")

            end

            LootFrame:UnregisterEvent('LOOT_OPENED')

        end

        AutoLoot:OnLoad()

    end

    ----------------------------------------------------------------------
    --	Disable bag automation
    ----------------------------------------------------------------------

    if LeaPlusLC["NoBagAutomation"] == "On" and not LeaLockList["NoBagAutomation"] then
        local function ManageBackpack(event)
            if event == "MERCHANT_SHOW" then
                BACKPACK_WAS_OPEN = IsBagOpen(0)
                if OpenBackpack ~= nil then
                    CloseBackpack()
                end
            elseif event == "MERCHANT_CLOSED" and not BACKPACK_WAS_OPEN then
                CloseBackpack()
            end
        end

        local frame = CreateFrame("Frame")
        frame:RegisterEvent("MERCHANT_SHOW")
        frame:RegisterEvent("MERCHANT_CLOSED")
        frame:SetScript("OnEvent", function(self, event)
            ManageBackpack(event)
        end)

        local function CustomCloseBackpack(closeFunction)
            return function()
                if not MERCHANT_FRAME_ACTIVE then
                    closeFunction()
                end
            end
        end

        hooksecurefunc("CloseBackpack", CustomCloseBackpack(CloseBackpack))

        local function MerchantFrame_Active_OnShow()
            MERCHANT_FRAME_ACTIVE = true
        end

        local function MerchantFrame_Active_OnHide()
            MERCHANT_FRAME_ACTIVE = false
        end

        hooksecurefunc("MerchantFrame_OnShow", MerchantFrame_Active_OnShow)
        hooksecurefunc("MerchantFrame_OnHide", MerchantFrame_Active_OnHide)


    end

    ----------------------------------------------------------------------
    --	Automate quests (no reload required)
    ----------------------------------------------------------------------

    do

        local addon = CreateFrame('Frame')

        addon.completedQuests = {}
        addon.uncompletedQuests = {}

        function addon:OnEvent(event, ...)
            if self[event] then
                self[event](self, ...)
            end
        end

        addon:SetScript('OnEvent', addon.OnEvent)

        -- Function to setup events
        local function SetupEvents()
            if LeaPlusLC["AutomateQuests"] == "On" then
                addon:RegisterEvent('GOSSIP_SHOW')
                addon:RegisterEvent('QUEST_COMPLETE')
                addon:RegisterEvent('QUEST_DETAIL')
                addon:RegisterEvent('QUEST_FINISHED')
                addon:RegisterEvent('QUEST_GREETING')
                addon:RegisterEvent('QUEST_LOG_UPDATE')
                addon:RegisterEvent('QUEST_PROGRESS')
            else
                addon:UnregisterAllEvents()
            end
        end

        -- Create configuration panel
        local QuestPanel = LeaPlusLC:CreatePanel("Automate quests", "QuestPanel")

        LeaPlusLC:MakeTx(QuestPanel, "Settings", 16, -72)
        LeaPlusLC:MakeCB(QuestPanel, "AutoQuestAvailable", "Accept available quests automatically", 16, -92, false, "If checked, available quests will be accepted automatically.")
        LeaPlusLC:MakeCB(QuestPanel, "AutoQuestCompleted", "Turn-in completed quests automatically", 16, -112, false, "If checked, completed quests will be turned-in automatically.")
        LeaPlusLC:MakeCB(QuestPanel, "AutoQuestShift", "Require override key for quest automation", 16, -132, false, "If checked, you will need to hold the override key down for quests to be automated.|n|nIf unchecked, holding the override key will prevent quests from being automated.")

        LeaPlusLC:CreateDropDown("AutoQuestKeyMenu", "Override key", QuestPanel, 146, "TOPLEFT", 356, -115, { L["SHIFT"], L["ALT"], L["CONTROL"] }, "")

        -- Setup events when option is clicked and on startup (if option is enabled)
        LeaPlusCB["AutomateQuests"]:HookScript("OnClick", SetupEvents)
        if LeaPlusLC["AutomateQuests"] == "On" then
            SetupEvents()
        end

        -- Help button hidden
        QuestPanel.h:Hide()

        -- Back button handler
        QuestPanel.b:SetScript("OnClick", function()
            QuestPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page1"]:Show();
            SetupEvents()
            return
        end)

        -- Reset button handler
        QuestPanel.r:SetScript("OnClick", function()

            -- Reset checkboxes
            LeaPlusLC["AutoQuestShift"] = "Off"
            LeaPlusLC["AutoQuestAvailable"] = "On"
            LeaPlusLC["AutoQuestCompleted"] = "On"
            LeaPlusLC["AutoQuestKeyMenu"] = 1

            -- Refresh panel
            QuestPanel:Hide();
            QuestPanel:Show()
            SetupEvents()
        end)

        -- Show panal when options panel button is clicked
        LeaPlusCB["AutomateQuestsBtn"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["AutoQuestShift"] = "Off"
                LeaPlusLC["AutoQuestAvailable"] = "On"
                LeaPlusLC["AutoQuestCompleted"] = "On"
                LeaPlusLC["AutoQuestKeyMenu"] = 1
            else
                QuestPanel:Show()
                LeaPlusLC:HideFrames()
            end
            SetupEvents()
        end)

        --===== Config Panel Setup END =====--

        -- Function to determine if override key is being held (from 2nd code)
        local function IsOverrideKeyDown()
            if LeaPlusLC["AutoQuestKeyMenu"] == 1 and IsShiftKeyDown()
                    or LeaPlusLC["AutoQuestKeyMenu"] == 2 and IsAltKeyDown()
                    or LeaPlusLC["AutoQuestKeyMenu"] == 3 and IsControlKeyDown()
            then
                return true
            end
        end

        function addon:canAutomate()
            if LeaPlusLC["AutoQuestCompleted"] == "Off" or (LeaPlusLC["AutoQuestShift"] == "On" and not IsOverrideKeyDown()) or (LeaPlusLC["AutoQuestShift"] == "Off" and IsOverrideKeyDown()) then
                return false
            else
                return true
            end
        end

        function addon:strip_text(text)
            if not text then
                return
            end
            text = text:gsub('|c%x%x%x%x%x%x%x%x(.-)|r', '%1')
            text = text:gsub('%[.*%]%s*', '')
            text = text:gsub('(.+) %(.+%)', '%1')
            text = text:trim()
            return text
        end

        function addon:QUEST_PROGRESS()
            if not self:canAutomate() then
                return
            end
            if IsQuestCompletable() then
                CompleteQuest()
            end
        end

        function addon:QUEST_LOG_UPDATE()
            if not self:canAutomate() then
                return
            end
            local start_entry = GetQuestLogSelection()
            local num_entries = GetNumQuestLogEntries()
            local title, is_complete, no_objectives

            self.completedQuests = {}
            self.uncompletedQuests = {}

            if num_entries > 0 then
                for i = 1, num_entries do
                    SelectQuestLogEntry(i)
                    title, _, _, _, _, _, is_complete = GetQuestLogTitle(i)
                    no_objectives = GetNumQuestLeaderBoards(i) == 0
                    if title and (is_complete or no_objectives) then
                        self.completedQuests[title] = true
                    else
                        self.uncompletedQuests[title] = true
                    end
                end
            end
            SelectQuestLogEntry(start_entry)
        end

        function addon:GOSSIP_SHOW()
            if not self:canAutomate() then
                return
            end

            local button, text
            for i = 1, 32 do
                button = _G['GossipTitleButton' .. i]
                if button:IsVisible() then
                    text = self:strip_text(button:GetText())
                    if button.type == 'Available' and LeaPlusLC["AutoQuestAvailable"] == "On" then
                        button:Click()
                    elseif button.type == 'Active' and LeaPlusLC["AutoQuestCompleted"] == "On" and self.completedQuests[text] then
                        button:Click()
                    end
                end
            end
        end

        function addon:QUEST_GREETING(...)
            if not self:canAutomate() then
                return
            end

            local button, text
            for i = 1, 32 do
                button = _G['QuestTitleButton' .. i]
                if button:IsVisible() then
                    text = self:strip_text(button:GetText())
                    if LeaPlusLC["AutoQuestCompleted"] == "On" and self.completedQuests[text] then
                        button:Click()
                    elseif LeaPlusLC["AutoQuestAvailable"] == "On" and not self.uncompletedQuests[text] then
                        button:Click()
                    end
                end
            end
        end

        function addon:QUEST_DETAIL()
            if not self:canAutomate() then
                return
            end
            if LeaPlusLC["AutoQuestAvailable"] == "On" then
                AcceptQuest()
            end
        end

        function addon:QUEST_COMPLETE(event)
            if not self:canAutomate() then
                return
            end
            if LeaPlusLC["AutoQuestCompleted"] == "On" and GetNumQuestChoices() <= 1 then
                GetQuestReward(QuestFrameRewardPanel.itemChoice)
            end
        end

        _G.Leatrix_Plus = addon


    end

    ----------------------------------------------------------------------
    --	Sort game options addon list - not present in 3.3.5
    ----------------------------------------------------------------------

    --if LeaPlusLC["CharAddonList"] == "On" then
    --	-- Set the addon list to character by default
    --	if AddonCharacterDropDown and AddonCharacterDropDown.selectedValue then
    --		AddonCharacterDropDown.selectedValue = UnitName("player");
    --		AddonCharacterDropDownText:SetText(UnitName("player"))
    --	end
    --end

    ----------------------------------------------------------------------
    --	Sell junk automatically (no reload required)
    -- 	Not 2.4.3 compatible - kek
    ----------------------------------------------------------------------

    do

        -- Create sell junk banner
        local StartMsg = CreateFrame("FRAME", nil, MerchantFrame)
        StartMsg:ClearAllPoints()
        StartMsg:SetPoint("BOTTOMLEFT", 4, 4)
        StartMsg:SetSize(160, 22)
        StartMsg:SetToplevel(true)
        StartMsg:Hide()

        StartMsg.s = StartMsg:CreateTexture(nil, "BACKGROUND")
        StartMsg.s:SetAllPoints()
        StartMsg.s:SetVertexColor(0.1, 0.1, 0.1, 1.0)

        StartMsg.f = StartMsg:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        StartMsg.f:SetAllPoints();
        StartMsg.f:SetText(L["SELLING JUNK"])

        -- Declarations
        local IterationCount, totalPrice = 500, 0
        local SellJunkTicker

        -- Create custom NewTicker function (from Wrath)
        local function LeaPlusNewTicker(duration, callback, iterations)
            local ticker = setmetatable({}, TickerMetatable)
            ticker._remainingIterations = iterations
            ticker._callback = function()
                if (not ticker._cancelled) then
                    callback(ticker)
                    --Make sure we weren't cancelled during the callback
                    if (not ticker._cancelled) then
                        if (ticker._remainingIterations) then
                            ticker._remainingIterations = ticker._remainingIterations - 1
                        end
                        if (not ticker._remainingIterations or ticker._remainingIterations > 0) then
                            LibCompat.After(duration, ticker._callback)
                        end
                    end
                end
            end
            LibCompat.After(duration, ticker._callback)
            return ticker
        end



        -- Create configuration panel
        local SellJunkFrame = LeaPlusLC:CreatePanel("Sell junk automatically", "SellJunkFrame")
        LeaPlusLC:MakeTx(SellJunkFrame, "Settings", 16, -72)
        LeaPlusLC:MakeCB(SellJunkFrame, "AutoSellShowSummary", "Show vendor summary in chat", 16, -92, false, "If checked, a vendor summary will be shown in chat when junk is automatically sold.")

        -- Help button hidden
        SellJunkFrame.h:Hide()

        -- Back button handler
        SellJunkFrame.b:SetScript("OnClick", function()
            SellJunkFrame:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page1"]:Show();
            return
        end)

        -- Reset button handler
        SellJunkFrame.r.tiptext = SellJunkFrame.r.tiptext .. "|n|n" .. L["Note that this will not reset your exclusions list."]
        SellJunkFrame.r:SetScript("OnClick", function()

            -- Reset checkboxes
            LeaPlusLC["AutoSellShowSummary"] = "On"

            -- Refresh panel
            SellJunkFrame:Hide();
            SellJunkFrame:Show()

        end)

        -- Show panal when options panel button is clicked
        LeaPlusCB["AutoSellJunkBtn"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["AutoSellShowSummary"] = "On"
            else
                SellJunkFrame:Show()
                LeaPlusLC:HideFrames()
            end
        end)

        -- Function to stop selling
        local function StopSelling()
            if SellJunkTicker then
                SellJunkTicker._cancelled = true;
            end
            StartMsg:Hide()
            SellJunkFrame:UnregisterEvent("ITEM_LOCKED")
            SellJunkFrame:UnregisterEvent("UI_ERROR_MESSAGE")
        end

        -- Create excluded box
        local titleTX = LeaPlusLC:MakeTx(SellJunkFrame, "Exclusions", 356, -72)
        titleTX:SetWidth(200)
        titleTX:SetWordWrap(false)
        titleTX:SetJustifyH("LEFT")

        -- Show help button for exclusions
        LeaPlusLC:CreateHelpButton("SellJunkExcludeHelpButton", SellJunkFrame, titleTX, "Enter item IDs separated by commas.  Item IDs can be found in item tooltips while this panel is showing.|n|nJunk items entered here will not be sold automatically.|n|nWhite items entered here will be sold automatically.|n|nThe editbox tooltip will show you more information about the items you have entered.")

        local eb = CreateFrame("Frame", nil, SellJunkFrame)
        eb:SetSize(200, 180)
        eb:SetPoint("TOPLEFT", 350, -92)
        eb:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
            edgeSize = 16,
            insets = { left = 8, right = 6, top = 8, bottom = 8 },
        })
        eb:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.5)

        eb.scroll = CreateFrame("ScrollFrame", nil, eb)
        eb.scroll:SetPoint("TOPLEFT", eb, 12, -10)
        eb.scroll:SetPoint("BOTTOMRIGHT", eb, -30, 10)

        eb.Text = CreateFrame("EditBox", nil, eb)
        eb.Text:SetMultiLine(true)
        eb.Text:SetWidth(150)
        eb.Text:SetPoint("TOPLEFT", eb.scroll)
        eb.Text:SetPoint("BOTTOMRIGHT", eb.scroll)
        eb.Text:SetMaxLetters(600)
        eb.Text:SetFontObject(GameFontNormalLarge)
        eb.Text:SetAutoFocus(false)
        eb.Text:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)
        eb.scroll:SetScrollChild(eb.Text)

        -- Set focus on the editbox text when clicking the editbox
        eb:SetScript("OnMouseDown", function()
            eb.Text:SetFocus()
            eb.Text:SetCursorPosition(eb.Text:GetMaxLetters())
        end)

        -- Function to create whitelist
        local whiteList = {}
        local function UpdateWhiteList()
            wipe(whiteList)

            local whiteString = eb.Text:GetText()
            if whiteString and whiteString ~= "" then
                whiteString = whiteString:gsub("[^,%d]", "")
                local tList = { strsplit(",", whiteString) }
                for i = 1, #tList do
                    if tList[i] then
                        tList[i] = tonumber(tList[i])
                        if tList[i] then
                            whiteList[tList[i]] = true
                        end
                    end
                end
            end

            LeaPlusLC["AutoSellExcludeList"] = whiteString
            eb.Text:SetText(LeaPlusLC["AutoSellExcludeList"])

        end

        -- Save the excluded list when it changes and at startup
        eb.Text:SetScript("OnTextChanged", UpdateWhiteList)
        eb.Text:SetText(LeaPlusLC["AutoSellExcludeList"])
        UpdateWhiteList()

        -- Create whitelist on startup and option or preset is clicked
        UpdateWhiteList()
        LeaPlusCB["AutoSellJunkBtn"]:HookScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                UpdateWhiteList()
            end
        end)

        -- Function to make tooltip string
        local function MakeTooltipString()

            local keepMsg = ""
            local sellMsg = ""
            local dupMsg = ""
            local novalueMsg = ""
            local incompatMsg = ""

            local tipString = eb.Text:GetText()
            if tipString and tipString ~= "" then
                tipString = tipString:gsub("[^,%d]", "")
                local tipList = { strsplit(",", tipString) }
                for i = 1, #tipList do
                    if tipList[i] then
                        tipList[i] = tonumber(tipList[i])
                        if tipList[i] and tipList[i] > 0 and tipList[i] < 999999999 then
                            local void, tLink, Rarity, void, void, void, void, void, void, void, ItemPrice = GetItemInfo(tipList[i])
                            if tLink and tLink ~= "" then
                                local linkCol = string.sub(tLink, 1, 10)
                                if linkCol then
                                    local linkName = tLink:match("%[(.-)%]")
                                    if linkName and ItemPrice then
                                        if ItemPrice > 0 then
                                            if Rarity == 0 then
                                                -- Junk item
                                                if string.find(keepMsg, "%(" .. tipList[i] .. "%)") then
                                                    -- Duplicate (ID appears more than once in list)
                                                    dupMsg = dupMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
                                                else
                                                    -- Add junk item to keep list
                                                    keepMsg = keepMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
                                                end
                                            elseif Rarity == 1 then
                                                -- White item
                                                if string.find(sellMsg, "%(" .. tipList[i] .. "%)") then
                                                    -- Duplicate (ID appears more than once in list)
                                                    dupMsg = dupMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
                                                else
                                                    -- Add non-junk item to sell list
                                                    sellMsg = sellMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
                                                end
                                            else
                                                -- Incompatible item (not junk or white)
                                                if string.find(incompatMsg, "%(" .. tipList[i] .. "%)") then
                                                    -- Duplicate (ID appears more than once in list)
                                                    dupMsg = dupMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
                                                else
                                                    -- Add item to incompatible list
                                                    incompatMsg = incompatMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
                                                end
                                            end
                                        else
                                            -- Item has no sell price so cannot be sold
                                            if string.find(novalueMsg, "%(" .. tipList[i] .. "%)") then
                                                -- Duplicate (ID appears more than once in list)
                                                dupMsg = dupMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
                                            else
                                                -- Add item to cannot be sold list
                                                novalueMsg = novalueMsg .. linkCol .. linkName .. " (" .. tipList[i] .. ")" .. "|r|n"
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if keepMsg ~= "" then
                keepMsg = "|n" .. L["Keep"] .. "|n" .. keepMsg
            end
            if sellMsg ~= "" then
                sellMsg = "|n" .. L["Sell"] .. "|n" .. sellMsg
            end
            if dupMsg ~= "" then
                dupMsg = "|n" .. L["Duplicates"] .. "|n" .. dupMsg
            end
            if novalueMsg ~= "" then
                novalueMsg = "|n" .. L["Cannot be sold"] .. "|n" .. novalueMsg
            end
            if incompatMsg ~= "" then
                incompatMsg = "|n" .. L["Incompatible"] .. "|n" .. incompatMsg
            end

            eb.tiptext = L["Exclusions"] .. "|n" .. keepMsg .. sellMsg .. dupMsg .. novalueMsg .. incompatMsg
            eb.Text.tiptext = L["Exclusions"] .. "|n" .. keepMsg .. sellMsg .. dupMsg .. novalueMsg .. incompatMsg
            if eb.tiptext == L["Exclusions"] .. "|n" then
                eb.tiptext = eb.tiptext .. "|n" .. L["Nothing to see here."]
            end
            if eb.Text.tiptext == L["Exclusions"] .. "|n" then
                eb.Text.tiptext = "-"
            end

            if GameTooltip:IsShown() then
                if MouseIsOver(eb) or MouseIsOver(eb.Text) then
                    GameTooltip:SetText(eb.tiptext, nil, nil, nil, nil, false)
                end
            end

        end

        eb.Text:HookScript("OnTextChanged", MakeTooltipString)
        eb.Text:HookScript("OnTextChanged", function()
            LibCompat.After(0.1, function()
                MakeTooltipString()
            end)
        end)

        -- Show the button tooltip for the editbox
        eb:SetScript("OnEnter", MakeTooltipString)
        eb:HookScript("OnEnter", LeaPlusLC.TipSee)
        eb:HookScript("OnEnter", function()
            GameTooltip:SetText(eb.tiptext, nil, nil, nil, nil, false)
        end)
        eb:SetScript("OnLeave", GameTooltip_Hide)
        eb.Text:SetScript("OnEnter", MakeTooltipString)
        eb.Text:HookScript("OnEnter", LeaPlusLC.ShowDropTip)
        eb.Text:HookScript("OnEnter", function()
            GameTooltip:SetText(eb.tiptext, nil, nil, nil, nil, false)
        end)
        eb.Text:SetScript("OnLeave", GameTooltip_Hide)

        -- Show item ID in item tooltips while configuration panel is showing
        GameTooltip:HookScript("OnTooltipSetItem", function(self)
            if SellJunkFrame:IsShown() then
                local void, itemLink = self:GetItem()
                if itemLink then
                    local itemID = itemLink:match("item:(%d+):")
                    if itemID then
                        self:AddLine(L["Item ID"] .. ": " .. itemID)
                    end
                end
            end
        end)


        -- Vendor function
        local function SellJunkFunc()

            -- Variables
            local SoldCount, Rarity, ItemPrice = 0, 0, 0
            local CurrentItemLink, void

            -- Traverse bags and sell grey items
            for BagID = 0, 4 do
                for BagSlot = 1, GetContainerNumSlots(BagID) do
                    local itemId = GetContainerItemID(BagID, BagSlot)
                    if itemId then
                        local CurrentItemLink = select(2, GetItemInfo(itemId))
                        if CurrentItemLink then
                            local itemName, _, Rarity, _, _, _, _, _, _, _, ItemPrice = GetItemInfo(CurrentItemLink)
                            -- Don't sell whitelisted items
                            if whiteList[itemId] then
                                if Rarity == 0 then
                                    -- Junk item to keep
                                    Rarity = 3
                                    ItemPrice = 0
                                elseif Rarity == 1 then
                                    -- White item to sell
                                    Rarity = 0
                                end
                            end

                            local texture, itemCount, locked, quality, readable = GetContainerItemInfo(BagID, BagSlot)
                            if itemCount then
                                -- The item has a valid itemCount, so we can proceed
                                if Rarity == 0 and ItemPrice ~= 0 then
                                    SoldCount = SoldCount + 1
                                    if MerchantFrame:IsShown() then
                                        -- If merchant frame is open, vendor the item
                                        UseContainerItem(BagID, BagSlot)
                                        -- Perform actions on first iteration
                                        if SellJunkTicker._remainingIterations == IterationCount then
                                            -- Calculate total price
                                            totalPrice = totalPrice + (ItemPrice * itemCount)
                                        end
                                    else
                                        -- If merchant frame is not open, stop selling
                                        StopSelling()
                                        return
                                    end
                                end
                            else
                                -- The item count is nil, so we cannot proceed
                                print("Item count is nil!")
                            end

                        end
                    end
                end


            end

            -- Stop selling if no items were sold for this iteration or iteration limit was reached
            if SoldCount == 0 or SellJunkTicker and SellJunkTicker._remainingIterations == 1 then
                StopSelling()
                if totalPrice > 0 and LeaPlusLC["AutoSellShowSummary"] == "On" then
                    LeaPlusLC:Print(L["Sold junk for"] .. " " .. GetCoinText(totalPrice) .. ".")
                end
            end

        end

        -- Function to setup events
        local function SetupEvents()
            if LeaPlusLC["AutoSellJunk"] == "On" then
                SellJunkFrame:RegisterEvent("MERCHANT_SHOW");
                SellJunkFrame:RegisterEvent("MERCHANT_CLOSED");
            else
                SellJunkFrame:UnregisterEvent("MERCHANT_SHOW")
                SellJunkFrame:UnregisterEvent("MERCHANT_CLOSED")
            end
        end

        -- Setup events when option is clicked and on startup (if option is enabled)
        LeaPlusCB["AutoSellJunk"]:HookScript("OnClick", SetupEvents)
        if LeaPlusLC["AutoSellJunk"] == "On" then
            SetupEvents()
        end

        -- Event handler
        SellJunkFrame:SetScript("OnEvent", function(self, event)
            if event == "MERCHANT_SHOW" then
                -- Check for vendors that refuse to buy items
                SellJunkFrame:RegisterEvent("UI_ERROR_MESSAGE")
                -- Reset variable
                totalPrice = 0
                -- Do nothing if shift key is held down
                if IsShiftKeyDown() then
                    return
                end
                -- Cancel existing ticker if present
                if SellJunkTicker then
                    SellJunkTicker._cancelled = true;
                end
                -- Sell grey items using ticker (ends when all grey items are sold or iteration count reached)
                SellJunkTicker = LeaPlusNewTicker(0.2, SellJunkFunc, IterationCount)
                SellJunkFrame:RegisterEvent("ITEM_LOCKED")
            elseif event == "ITEM_LOCKED" then
                StartMsg:Show()
                SellJunkFrame:UnregisterEvent("ITEM_LOCKED")
            elseif event == "MERCHANT_CLOSED" then
                -- If merchant frame is closed, stop selling
                StopSelling()
            elseif event == "UI_ERROR_MESSAGE" then
                if arg1 == 46 then
                    StopSelling() -- Vendor refuses to buy items
                end
            end
        end)

    end

    ----------------------------------------------------------------------
    --	Repair automatically (no reload required)
    ----------------------------------------------------------------------

    do

        -- Repair when suitable merchant frame is shown
        local function RepairFunc()
            if IsShiftKeyDown() then
                return
            end
            if CanMerchantRepair() then
                -- If merchant is capable of repair
                -- Process repair
                local RepairCost, CanRepair = GetRepairAllCost()
                if CanRepair then
                    -- If merchant is offering repair
                    if LeaPlusLC["AutoRepairGuildFunds"] == "On" and IsInGuild() then
                        -- Guilded character and guild repair option is enabled
                        if CanGuildBankRepair() then
                            -- Character has permission to repair so try guild funds but fallback on character funds (if daily gold limit is reached)
                            RepairAllItems(1) --test 2.4.3
                            RepairAllItems()
                        else
                            -- Character does not have permission to repair so use character funds
                            RepairAllItems()
                        end
                    else
                        -- Unguilded character or guild repair option is disabled
                        RepairAllItems()
                    end
                    -- Show cost summary
                    if LeaPlusLC["AutoRepairShowSummary"] == "On" then
                        LeaPlusLC:Print(L["Repaired for"] .. " " .. GetCoinText(RepairCost) .. ".")
                    end
                end
            end
        end

        -- Create event frame
        local RepairFrame = CreateFrame("FRAME")

        -- Function to setup event
        local function SetupEvent()
            if LeaPlusLC["AutoRepairGear"] == "On" then
                RepairFrame:RegisterEvent("MERCHANT_SHOW")
            else
                RepairFrame:UnregisterEvent("MERCHANT_SHOW")
            end
        end

        -- Setup event when option is clicked and on startup (if option is enabled)
        LeaPlusCB["AutoRepairGear"]:HookScript("OnClick", SetupEvent)
        if LeaPlusLC["AutoRepairGear"] == "On" then
            SetupEvent()
        end

        -- Event handler
        RepairFrame:SetScript("OnEvent", RepairFunc)

        -- Create configuration panel
        local RepairPanel = LeaPlusLC:CreatePanel("Repair automatically", "RepairPanel")

        LeaPlusLC:MakeTx(RepairPanel, "Settings", 16, -72)
        LeaPlusLC:MakeCB(RepairPanel, "AutoRepairGuildFunds", "Repair using guild funds if available", 16, -92, false, "If checked, repair costs will be taken from guild funds for characters that are guilded and have permission to repair.")
        LeaPlusLC:MakeCB(RepairPanel, "AutoRepairShowSummary", "Show repair summary in chat", 16, -112, false, "If checked, a repair summary will be shown in chat when your gear is automatically repaired.")

        -- Help button hidden
        RepairPanel.h:Hide()

        -- Back button handler
        RepairPanel.b:SetScript("OnClick", function()
            RepairPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page1"]:Show();
            return
        end)

        -- Reset button handler
        RepairPanel.r:SetScript("OnClick", function()

            -- Reset checkboxes
            LeaPlusLC["AutoRepairGuildFunds"] = "On"
            LeaPlusLC["AutoRepairShowSummary"] = "On"

            -- Refresh panel
            RepairPanel:Hide();
            RepairPanel:Show()

        end)

        -- Show panal when options panel button is clicked
        LeaPlusCB["AutoRepairBtn"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["AutoRepairGuildFunds"] = "On"
                LeaPlusLC["AutoRepairShowSummary"] = "On"
            else
                RepairPanel:Show()
                LeaPlusLC:HideFrames()
            end
        end)

    end

    ----------------------------------------------------------------------
    -- Hide the combat log
    ----------------------------------------------------------------------

    if LeaPlusLC["NoCombatLogTab"] == "On" and not LeaLockList["NoCombatLogTab"] then

        -- Ensure combat log is docked
        if ChatFrame2.isDocked then
            -- Set combat log attributes when chat windows are updated
            LpEvt:RegisterEvent("UPDATE_CHAT_WINDOWS")
            -- Set combat log tab placement when tabs are assigned by the client
            hooksecurefunc("FCF_SetTabPosition", function()
                ChatFrame2Tab:SetPoint("BOTTOMLEFT", ChatFrame1Tab, "BOTTOMRIGHT", 0, 0)
            end)
        else
            -- If combat log is undocked, do nothing but show warning
            LibCompat.After(1, function()
                LeaPlusLC:Print("Combat log cannot be hidden while undocked.")
            end)
        end

    end

    ----------------------------------------------------------------------
    --	Show player chain
    ----------------------------------------------------------------------

    if LeaPlusLC["ShowPlayerChain"] == "On" and not LeaLockList["ShowPlayerChain"] then

        -- Ensure chain doesnt clip through pet portrait
        PetPortrait:GetParent():SetFrameLevel(4)

        -- Create configuration panel
        local ChainPanel = LeaPlusLC:CreatePanel("Show player chain", "ChainPanel")

        -- Add dropdown menu
        LeaPlusLC:CreateDropDown("PlayerChainMenu", "Chain style", ChainPanel, 146, "TOPLEFT", 16, -112, { L["RARE"], L["ELITE"], L["RARE ELITE"] }, "")

        -- Set chain style
        local function SetChainStyle()
            -- Get dropdown menu value
            local chain = LeaPlusLC["PlayerChainMenu"] -- Numeric value
            -- Set chain style according to value
            if chain == 1 then
                -- Rare
                PlayerFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare.blp")
                PlayerFrameTexture:SetTexCoord(1, .09375, 0, .78125)
            elseif chain == 2 then
                -- Elite
                PlayerFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite.blp")
                PlayerFrameTexture:SetTexCoord(1, .09375, 0, .78125)
            elseif chain == 3 then
                -- Rare Elite
                PlayerFrameTexture:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus.blp")
                PlayerFrameTexture:SetTexCoord(0.25, 0.0234375, 0, 0.1953125)
            end
        end

        -- Set style on startup
        SetChainStyle()

        -- Set style when a drop menu is selected (procs when the list is hidden)
        LeaPlusCB["ListFramePlayerChainMenu"]:HookScript("OnHide", SetChainStyle)

        -- Help button hidden
        ChainPanel.h:Hide()

        -- Back button handler
        ChainPanel.b:SetScript("OnClick", function()
            LeaPlusCB["ListFramePlayerChainMenu"]:Hide(); -- Hide the dropdown list
            ChainPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page5"]:Show();
            return
        end)

        -- Reset button handler
        ChainPanel.r:SetScript("OnClick", function()
            LeaPlusCB["ListFramePlayerChainMenu"]:Hide(); -- Hide the dropdown list
            LeaPlusLC["PlayerChainMenu"] = 2
            ChainPanel:Hide();
            ChainPanel:Show();
            SetChainStyle()
        end)

        -- Show the panel when the configuration button is clicked
        LeaPlusCB["ModPlayerChain"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                LeaPlusLC["PlayerChainMenu"] = 3;
                SetChainStyle();
            else
                LeaPlusLC:HideFrames();
                ChainPanel:Show();
            end
        end)

    end

    ----------------------------------------------------------------------
    -- Show raid frame toggle button
    ----------------------------------------------------------------------

    -- if LeaPlusLC["ShowRaidToggle"] == "On" and not LeaLockList["ShowRaidToggle"] then

    -- 	-- Check to make sure raid toggle button exists
    -- 	if CompactRaidFrameManagerDisplayFrameHiddenModeToggle then

    -- 		-- Create a border for the button
    -- 		local cBackdrop = CreateFrame("Frame", nil, CompactRaidFrameManagerDisplayFrameHiddenModeToggle)
    -- 		cBackdrop:SetAllPoints()
    -- 		cBackdrop.backdropInfo = {edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, insets = {left = 0, right = 0, top = 0, bottom = 0}}
    -- 		cBackdrop:ApplyBackdrop()

    -- 		-- Move the button (function runs after PLAYER_ENTERING_WORLD and PARTY_LEADER_CHANGED)
    -- 		hooksecurefunc("CompactRaidFrameManager_UpdateOptionsFlowContainer", function()
    -- 			if CompactRaidFrameManager and CompactRaidFrameManagerDisplayFrameHiddenModeToggle then
    -- 				local void, void, void, void, y = CompactRaidFrameManager:GetPoint()
    -- 				CompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetWidth(40)
    -- 				CompactRaidFrameManagerDisplayFrameHiddenModeToggle:ClearAllPoints()
    -- 				CompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, y + 22)
    -- 				CompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetParent(UIParent)
    -- 			end
    -- 		end)

    -- 	end

    -- end

    ----------------------------------------------------------------------
    -- Hide hit indicators (portrait text)
    ----------------------------------------------------------------------

    if LeaPlusLC["NoHitIndicators"] == "On" and not LeaLockList["NoHitIndicators"] then
        hooksecurefunc(PlayerHitIndicator, "Show", PlayerHitIndicator.Hide)
        hooksecurefunc(PetHitIndicator, "Show", PetHitIndicator.Hide)
    end

    ----------------------------------------------------------------------
    -- Class colored frames
    ----------------------------------------------------------------------

    if LeaPlusLC["ClassColFrames"] == "On" and not LeaLockList["ClassColFrames"] then

        -- Create background frame for player frame
        local PlayFN = CreateFrame("FRAME", nil, PlayerFrame)
        PlayFN:Hide()

        PlayFN:SetWidth(TargetFrameNameBackground:GetWidth())
        PlayFN:SetHeight(TargetFrameNameBackground:GetHeight())

        local void, void, void, x, y = TargetFrameNameBackground:GetPoint()
        PlayFN:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", -x, y)

        PlayFN.t = PlayFN:CreateTexture(nil, "BORDER")
        PlayFN.t:SetAllPoints()
        PlayFN.t:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground")

        local c = LeaPlusLC["RaidColors"][select(2, UnitClass("player"))]
        if c then
            PlayFN.t:SetVertexColor(c.r, c.g, c.b)
        end

        -- Create color function for target and focus frames
        local function TargetFrameCol()
            if UnitIsPlayer("target") then
                local c = LeaPlusLC["RaidColors"][select(2, UnitClass("target"))]
                if c then
                    TargetFrameNameBackground:SetVertexColor(c.r, c.g, c.b)
                end
            end
            if UnitIsPlayer("focus") then
                local c = LeaPlusLC["RaidColors"][select(2, UnitClass("focus"))]
                if c then
                    FocusFrameNameBackground:SetVertexColor(c.r, c.g, c.b)
                end
            end
        end

        local ColTar = CreateFrame("FRAME")
        ColTar:SetScript("OnEvent", TargetFrameCol) -- Events are registered if target option is enabled

        -- Refresh color if focus frame size changes
        hooksecurefunc("FocusFrame_SetSmallSize", function()
            if LeaPlusLC["ClassColTarget"] == "On" then
                TargetFrameCol()
            end
        end)

        -- Create configuration panel
        local ClassFrame = LeaPlusLC:CreatePanel("Class colored frames", "ClassFrame")

        LeaPlusLC:MakeTx(ClassFrame, "Settings", 16, -72)
        LeaPlusLC:MakeCB(ClassFrame, "ClassColPlayer", "Show player frame in class color", 16, -92, false, "If checked, the player frame background will be shown in class color.")
        LeaPlusLC:MakeCB(ClassFrame, "ClassColTarget", "Show target frame and focus frame in class color", 16, -112, false, "If checked, the target frame background and focus frame background will be shown in class color.")

        -- Help button hidden
        ClassFrame.h:Hide()

        -- Back button handler
        ClassFrame.b:SetScript("OnClick", function()
            ClassFrame:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page6"]:Show()
            return
        end)

        -- Function to set class colored frames
        local function SetClassColFrames()
            -- Player frame
            if LeaPlusLC["ClassColPlayer"] == "On" then
                PlayFN:Show()
            else
                PlayFN:Hide()
            end
            -- Target and focus frames
            if LeaPlusLC["ClassColTarget"] == "On" then
                ColTar:RegisterEvent("GROUP_ROSTER_UPDATE")
                ColTar:RegisterEvent("PLAYER_TARGET_CHANGED")
                ColTar:RegisterEvent("PLAYER_FOCUS_CHANGED")
                ColTar:RegisterEvent("UNIT_FACTION")
                TargetFrameCol()
            else
                ColTar:UnregisterAllEvents()
                TargetFrame_CheckFaction(TargetFrame) -- Reset target frame colors
                TargetFrame_CheckFaction(FocusFrame) -- Reset focus frame colors
            end
        end

        -- Run function when options are clicked and on startup
        LeaPlusCB["ClassColPlayer"]:HookScript("OnClick", SetClassColFrames)
        LeaPlusCB["ClassColTarget"]:HookScript("OnClick", SetClassColFrames)
        SetClassColFrames()

        -- Reset button handler
        ClassFrame.r:SetScript("OnClick", function()

            -- Reset checkboxes
            LeaPlusLC["ClassColPlayer"] = "On"
            LeaPlusLC["ClassColTarget"] = "On"

            -- Update colors and refresh configuration panel
            SetClassColFrames()
            ClassFrame:Hide();
            ClassFrame:Show()

        end)

        -- Show configuration panal when options panel button is clicked
        LeaPlusCB["ClassColFramesBtn"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["ClassColPlayer"] = "On"
                LeaPlusLC["ClassColTarget"] = "On"
                SetClassColFrames()
            else
                ClassFrame:Show()
                LeaPlusLC:HideFrames()
            end
        end)

    end

    ----------------------------------------------------------------------
    --	Quest text size
    ----------------------------------------------------------------------

    if LeaPlusLC["QuestFontChange"] == "On" and not LeaLockList["QuestFontChange"] then

        -- -- Set gossip frame scroll box layout (fix for game patch 3.4.1)
        -- GossipFrame.GreetingPanel.ScrollBox:SetHeight(320)
        -- GossipFrame.GreetingPanel.ScrollBar:ClearAllPoints()
        -- GossipFrame.GreetingPanel.ScrollBar:SetPoint("TOPLEFT", GossipFrame.GreetingPanel.ScrollBox, "TOPRIGHT", 4, 9)
        -- GossipFrame.GreetingPanel.ScrollBar:SetPoint("BOTTOMLEFT", GossipFrame.GreetingPanel.ScrollBox, "BOTTOMRIGHT", 4, -14)

        -- Create configuration panel
        local QuestTextPanel = LeaPlusLC:CreatePanel("Resize quest text", "QuestTextPanel")

        LeaPlusLC:MakeTx(QuestTextPanel, "Text size", 16, -72)
        LeaPlusLC:MakeSL(QuestTextPanel, "LeaPlusQuestFontSize", "Drag to set the font size of quest text.", 10, 36, 1, 16, -92, "%.0f")

        -- Function to update the font size
        local function QuestSizeUpdate()
            local a, b, c = QuestFont:GetFont()
            QuestTitleFont:SetFont(a, LeaPlusLC["LeaPlusQuestFontSize"] + 3, c)
            QuestFont:SetFont(a, LeaPlusLC["LeaPlusQuestFontSize"] + 1, c)
            local d, e, f = QuestFontNormalSmall:GetFont()
            QuestFontNormalSmall:SetFont(d, LeaPlusLC["LeaPlusQuestFontSize"], f)
        end

        -- Set text size when slider changes and on startup
        LeaPlusCB["LeaPlusQuestFontSize"]:HookScript("OnValueChanged", QuestSizeUpdate)
        QuestSizeUpdate()

        -- Help button hidden
        QuestTextPanel.h:Hide()

        -- Back button handler
        QuestTextPanel.b:SetScript("OnClick", function()
            QuestTextPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page4"]:Show()
            return
        end)

        -- Reset button handler
        QuestTextPanel.r:SetScript("OnClick", function()

            -- Reset slider
            LeaPlusLC["LeaPlusQuestFontSize"] = 12
            QuestSizeUpdate()

            -- Refresh side panel
            QuestTextPanel:Hide();
            QuestTextPanel:Show()

        end)

        -- Show configuration panal when options panel button is clicked
        LeaPlusCB["QuestTextBtn"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["LeaPlusQuestFontSize"] = 18
                QuestSizeUpdate()
            else
                QuestTextPanel:Show()
                LeaPlusLC:HideFrames()
            end
        end)

    end

    ----------------------------------------------------------------------
    --	Resize mail text
    ----------------------------------------------------------------------

    if LeaPlusLC["MailFontChange"] == "On" then

        -- Create configuration panel
        local MailTextPanel = LeaPlusLC:CreatePanel("Resize mail text", "MailTextPanel")

        LeaPlusLC:MakeTx(MailTextPanel, "Text size", 16, -72)
        LeaPlusLC:MakeSL(MailTextPanel, "LeaPlusMailFontSize", "Drag to set the font size of mail text.", 10, 36, 1, 16, -92, "%.0f")

        -- Function to set the text size
        local function MailSizeUpdate()
            local MailFont, void, flags = QuestFont:GetFont()
            OpenMailBodyText:SetFont(MailFont, LeaPlusLC["LeaPlusMailFontSize"], flags)
            OpenMailBodyText:SetFont(MailFont, LeaPlusLC["LeaPlusMailFontSize"], flags)
            OpenMailBodyText:SetFont(MailFont, LeaPlusLC["LeaPlusMailFontSize"], flags)
            OpenMailBodyText:SetFont(MailFont, LeaPlusLC["LeaPlusMailFontSize"], flags)
            SendMailBodyEditBox:SetFont(MailFont, LeaPlusLC["LeaPlusMailFontSize"], flags)
        end

        -- Set text size after changing slider and on startup
        LeaPlusCB["LeaPlusMailFontSize"]:HookScript("OnValueChanged", MailSizeUpdate)
        MailSizeUpdate()

        -- Help button hidden
        MailTextPanel.h:Hide()

        -- Back button handler
        MailTextPanel.b:SetScript("OnClick", function()
            MailTextPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page4"]:Show()
            return
        end)

        -- Reset button handler
        MailTextPanel.r:SetScript("OnClick", function()

            -- Reset slider
            LeaPlusLC["LeaPlusMailFontSize"] = 15

            -- Refresh side panel
            MailTextPanel:Hide();
            MailTextPanel:Show()

        end)

        -- Show configuration panal when options panel button is clicked
        LeaPlusCB["MailTextBtn"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["LeaPlusMailFontSize"] = 22
                MailSizeUpdate()
            else
                MailTextPanel:Show()
                LeaPlusLC:HideFrames()
            end
        end)

    end

    ----------------------------------------------------------------------
    --	Resize book text
    ----------------------------------------------------------------------

    if LeaPlusLC["BookFontChange"] == "On" then

        -- Create configuration panel
        local BookTextPanel = LeaPlusLC:CreatePanel("Resize book text", "BookTextPanel")

        LeaPlusLC:MakeTx(BookTextPanel, "Text size", 16, -72)
        LeaPlusLC:MakeSL(BookTextPanel, "LeaPlusBookFontSize", "Drag to set the font size of book text.\n\nReading books, not spellbook", 10, 36, 1, 16, -92, "%.0f")

        -- Function to set the text size
        local function BookSizeUpdate()
            local BookFont, void, flags = QuestFont:GetFont()
            ItemTextFontNormal:SetFont(BookFont, LeaPlusLC["LeaPlusBookFontSize"], flags)
        end

        -- Set text size after changing slider and on startup
        LeaPlusCB["LeaPlusBookFontSize"]:HookScript("OnValueChanged", BookSizeUpdate)
        BookSizeUpdate()

        -- Help button hidden
        BookTextPanel.h:Hide()

        -- Back button handler
        BookTextPanel.b:SetScript("OnClick", function()
            BookTextPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page4"]:Show()
            return
        end)

        -- Reset button handler
        BookTextPanel.r:SetScript("OnClick", function()

            -- Reset slider
            LeaPlusLC["LeaPlusBookFontSize"] = 15

            -- Refresh side panel
            BookTextPanel:Hide();
            BookTextPanel:Show()

        end)

        -- Show configuration panel when options panel button is clicked
        LeaPlusCB["BookTextBtn"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["LeaPlusBookFontSize"] = 22
                BookSizeUpdate()
            else
                BookTextPanel:Show()
                LeaPlusLC:HideFrames()
            end
        end)

    end

    ----------------------------------------------------------------------
    --	Show durability status
    ----------------------------------------------------------------------

    if LeaPlusLC["DurabilityStatus"] == "On" then

        -- Create durability button
        local cButton = CreateFrame("BUTTON", nil, PaperDollFrame)
        cButton:ClearAllPoints()
        cButton:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -40, 80)
        cButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
        cButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        cButton:SetSize(32, 32)

        -- Create durability tables
        local Slots = { "HeadSlot", "ShoulderSlot", "ChestSlot", "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot" }
        local SlotsFriendly = { INVTYPE_HEAD, INVTYPE_SHOULDER, INVTYPE_CHEST, INVTYPE_WRIST, INVTYPE_HAND, INVTYPE_WAIST, INVTYPE_LEGS, INVTYPE_FEET, INVTYPE_WEAPONMAINHAND, INVTYPE_WEAPONOFFHAND, INVTYPE_RANGED }

        -- Show durability status in tooltip or status line (tip or status)
        local function ShowDuraStats(where)

            local duravaltotal, duramaxtotal, durapercent = 0, 0, 0
            local valcol, id, duraval, duramax

            if where == "tip" then
                -- Creare layout
                GameTooltip:AddLine("|cffffffff")
                GameTooltip:AddLine("|cffffffff")
                GameTooltip:AddLine("|cffffffff")
                _G["GameTooltipTextLeft1"]:SetText("|cffffffff");
                _G["GameTooltipTextRight1"]:SetText("|cffffffff")
                _G["GameTooltipTextLeft2"]:SetText("|cffffffff");
                _G["GameTooltipTextRight2"]:SetText("|cffffffff")
                _G["GameTooltipTextLeft3"]:SetText("|cffffffff");
                _G["GameTooltipTextRight3"]:SetText("|cffffffff")
            end

            local validItems = false

            -- Traverse equipment slots
            for k, slotName in ipairs(Slots) do
                if GetInventorySlotInfo(slotName) then
                    id = GetInventorySlotInfo(slotName)
                    duraval, duramax = GetInventoryItemDurability(id)
                    if duraval ~= nil then

                        -- At least one item has durability stat
                        validItems = true

                        -- Add to tooltip
                        if where == "tip" then
                            durapercent = tonumber(format("%.0f", duraval / duramax * 100))
                            valcol = (durapercent >= 80 and "|cff00FF00") or (durapercent >= 60 and "|cff99FF00") or (durapercent >= 40 and "|cffFFFF00") or (durapercent >= 20 and "|cffFF9900") or (durapercent >= 0 and "|cffFF2000") or ("|cffFFFFFF")
                            _G["GameTooltipTextLeft1"]:SetText(L["Durability"])
                            _G["GameTooltipTextLeft2"]:SetText(_G["GameTooltipTextLeft2"]:GetText() .. SlotsFriendly[k] .. "|n")
                            _G["GameTooltipTextRight2"]:SetText(_G["GameTooltipTextRight2"]:GetText() .. valcol .. durapercent .. "%" .. "|n")
                        end

                        duravaltotal = duravaltotal + duraval
                        duramaxtotal = duramaxtotal + duramax
                    end
                end
            end
            if duravaltotal > 0 and duramaxtotal > 0 then
                durapercent = duravaltotal / duramaxtotal * 100
            else
                durapercent = 0
            end

            if where == "tip" then

                if validItems == true then
                    -- Show overall durability in the tooltip
                    if durapercent >= 80 then
                        valcol = "|cff00FF00"
                    elseif durapercent >= 60 then
                        valcol = "|cff99FF00"
                    elseif durapercent >= 40 then
                        valcol = "|cffFFFF00"
                    elseif durapercent >= 20 then
                        valcol = "|cffFF9900"
                    elseif durapercent >= 0 then
                        valcol = "|cffFF2000"
                    else
                        return
                    end
                    _G["GameTooltipTextLeft3"]:SetText(L["Overall"] .. " " .. valcol)
                    _G["GameTooltipTextRight3"]:SetText(valcol .. string.format("%.0f", durapercent) .. "%")

                    -- Show lines of the tooltip
                    GameTooltipTextLeft1:Show();
                    GameTooltipTextRight1:Show()
                    GameTooltipTextLeft2:Show();
                    GameTooltipTextRight2:Show()
                    GameTooltipTextLeft3:Show();
                    GameTooltipTextRight3:Show()
                    GameTooltipTextRight2:SetJustifyH "RIGHT";
                    GameTooltipTextRight3:SetJustifyH "RIGHT";
                    GameTooltip:Show()
                else
                    -- No items have durability stat
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine("" .. L["Durability"], 1.0, 0.85, 0.0)
                    GameTooltip:AddLine("" .. L["No items with durability equipped."], 1, 1, 1)
                    GameTooltip:Show()
                end

            elseif where == "status" then
                if validItems == true then
                    -- Show simple status line instead
                    if tonumber(durapercent) >= 0 then
                        -- Ensure character has some durability items equipped
                        LeaPlusLC:Print(L["You have"] .. " " .. string.format("%.0f", durapercent) .. "%" .. " " .. L["durability"] .. ".")
                    end
                end

            end
        end

        -- Hover over the durability button to show the durability tooltip
        cButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(cButton, "ANCHOR_RIGHT");
            ShowDuraStats("tip");
        end)
        cButton:SetScript("OnLeave", GameTooltip_Hide)

        -- Create frame to watch events
        local DeathDura = CreateFrame("FRAME")
        DeathDura:RegisterEvent("PLAYER_DEAD")
        DeathDura:SetScript("OnEvent", function(self, event)
            ShowDuraStats("status")
            DeathDura:UnregisterEvent("PLAYER_DEAD")
            LibCompat.After(2, function()
                DeathDura:RegisterEvent("PLAYER_DEAD")
            end)
        end)

        hooksecurefunc("AcceptResurrect", function()
            -- Player has ressed without releasing
            ShowDuraStats("status")
        end)

    end

    ----------------------------------------------------------------------
    --	Hide zone text
    ----------------------------------------------------------------------

    if LeaPlusLC["HideZoneText"] == "On" then
        ZoneTextFrame:SetScript("OnShow", ZoneTextFrame.Hide);
        SubZoneTextFrame:SetScript("OnShow", SubZoneTextFrame.Hide);
    end

    ----------------------------------------------------------------------
    --	Disable sticky chat
    ----------------------------------------------------------------------

    if LeaPlusLC["NoStickyChat"] == "On" and not LeaLockList["NoStickyChat"] then
        -- These taint if set to anything other than nil
        ChatTypeInfo.WHISPER.sticky = nil
        ChatTypeInfo.BN_WHISPER.sticky = nil
        ChatTypeInfo.CHANNEL.sticky = nil
    end

    ----------------------------------------------------------------------
    --	Hide stance bar
    ----------------------------------------------------------------------

    if LeaPlusLC["NoClassBar"] == "On" and not LeaLockList["NoClassBar"] then
        local stancebar = CreateFrame("FRAME", nil, UIParent)
        stancebar:Hide()
        ShapeshiftBarFrame:UnregisterAllEvents()
        ShapeshiftBarFrame:SetParent(stancebar)
    end

    ----------------------------------------------------------------------
    --	Hide gryphons
    ----------------------------------------------------------------------

    if LeaPlusLC["NoGryphons"] == "On" and not LeaLockList["NoGryphons"] then
        MainMenuBarLeftEndCap:Hide();
        MainMenuBarRightEndCap:Hide();
    end

    ----------------------------------------------------------------------
    --	Disable chat fade
    ----------------------------------------------------------------------

    if LeaPlusLC["NoChatFade"] == "On" and not LeaLockList["NoChatFade"] then
        -- Process normal and existing chat frames
        for i = 1, 50 do
            if _G["ChatFrame" .. i] then
                _G["ChatFrame" .. i]:SetFading(false)
            end
        end
        -- Process temporary frames
        hooksecurefunc("FCF_OpenTemporaryWindow", function()
            local cf = FCF_GetCurrentChatFrame():GetName() or nil
            if cf then
                _G[cf]:SetFading(false)
            end
        end)
    end

    ----------------------------------------------------------------------
    --	Use easy chat frame resizing
    ----------------------------------------------------------------------

    if LeaPlusLC["UseEasyChatResizing"] == "On" and not LeaLockList["UseEasyChatResizing"] then
        ChatFrame1Tab:HookScript("OnMouseDown", function(self, arg1)
            if arg1 == "LeftButton" then
                if select(8, GetChatWindowInfo(1)) then
                    ChatFrame1:StartSizing("TOP")
                end
            end
        end)
        ChatFrame1Tab:SetScript("OnMouseUp", function(self, arg1)
            if arg1 == "LeftButton" then
                ChatFrame1:StopMovingOrSizing()
                FCF_SavePositionAndDimensions(ChatFrame1)
            end
        end)
    end

    ----------------------------------------------------------------------
    --	Increase chat history
    ----------------------------------------------------------------------

    if LeaPlusLC["MaxChatHstory"] == "On" and not LeaLockList["MaxChatHstory"] then
        -- Process normal and existing chat frames
        for i = 1, 50 do
            if _G["ChatFrame" .. i] and _G["ChatFrame" .. i]:GetMaxLines() ~= 4096 then
                _G["ChatFrame" .. i]:SetMaxLines(4096);
            end
        end
        -- Process temporary chat frames
        hooksecurefunc("FCF_OpenTemporaryWindow", function()
            local cf = FCF_GetCurrentChatFrame():GetName() or nil
            if cf then
                if (_G[cf]:GetMaxLines() ~= 4096) then
                    _G[cf]:SetMaxLines(4096);
                end
            end
        end)
    end

    ----------------------------------------------------------------------
    --	Hide error messages
    ----------------------------------------------------------------------


    -- Error message events
    local OrigErrHandler = UIErrorsFrame:GetScript('OnEvent')
    function LeaPlusLC:UpdateErrorMessageVisibility()
        if LeaPlusLC["HideErrorMessages"] == "On" then
            UIErrorsFrame:SetScript('OnEvent', function(self, event, err, ...)
                if event == "UI_ERROR_MESSAGE" then
                    -- Hide error messages for specific conditions
                    if err == ERR_INV_FULL or
                            err == ERR_QUEST_LOG_FULL or
                            err == ERR_RAID_GROUP_ONLY or
                            err == ERR_PET_SPELL_DEAD or
                            err == ERR_PLAYER_DEAD or
                            err == ERR_FEIGN_DEATH_RESISTED or
                            err == SPELL_FAILED_TARGET_NO_POCKETS or
                            err == ERR_ALREADY_PICKPOCKETED or
                            string.match(err, "Requires") or
                            string.match(err, "mount") or
                            string.match(err, "gold") or
                            string.match(err, "money") or
                            string.match(err, "afford") or
                            string.match(err, "shapeshift") or
                            string.match(err, "disarm")
                    then
                        return OrigErrHandler(self, event, err, ...)
                    end
                elseif event == 'UI_INFO_MESSAGE' then
                    -- Show information messages
                    return OrigErrHandler(self, event, err, ...)
                end
            end)
        else
            UIErrorsFrame:SetScript('OnEvent', OrigErrHandler)
        end
    end

    -- Hook the checkbox click to toggle visibility
    LeaPlusCB["HideErrorMessages"]:HookScript("OnClick", function(self)
        LeaPlusLC:UpdateErrorMessageVisibility()  -- Update the error message visibility state
    end)

    -- Initial check to set the correct visibility on load
    LeaPlusLC:UpdateErrorMessageVisibility()


    -- Release memory
    LeaPlusLC.Isolated = nil
end

----------------------------------------------------------------------
--	L40: Player
----------------------------------------------------------------------

function LeaPlusLC:Player()

    ----------------------------------------------------------------------
    -- Mute custom sounds (no reload required)
    ----------------------------------------------------------------------

    --do
    --
    --	-- Create configuration panel
    --	local MuteCustomPanel = LeaPlusLC:CreatePanel("Mute custom sounds", "MuteCustomPanel")
    --
    --	local titleTX = LeaPlusLC:MakeTx(MuteCustomPanel, "Editor", 16, -72)
    --	titleTX:SetWidth(534)
    --	titleTX:SetWordWrap(false)
    --	titleTX:SetJustifyH("LEFT")
    --
    --	-- Show help button for title
    --	LeaPlusLC:CreateHelpButton("MuteGameSoundsCustomHelpButton", MuteCustomPanel, titleTX, "Enter sound file IDs separated by comma then click the Mute button.|n|nIf you wish, you can enter a brief note for each file ID but do not include numbers in your notes.|n|nFor example, you can enter 'DevAura 569679, RetAura 568744' to mute the Devotion Aura and Retribution Aura spells.|n|nUse Leatrix Sounds to find, test and play sound file IDs.")
    --
    --	-- Add large editbox
    --	local eb = CreateFrame("Frame", nil, MuteCustomPanel)
    --	eb:SetSize(548, 180)
    --	eb:SetPoint("TOPLEFT", 10, -92)
    --	eb:SetBackdrop({
    --		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    --		edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
    --		edgeSize = 16,
    --		insets = { left = 8, right = 6, top = 8, bottom = 8 },
    --	})
    --	eb:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.5)
    --
    --	eb.scroll = CreateFrame("ScrollFrame", nil, eb)
    --	eb.scroll:SetPoint("TOPLEFT", eb, 12, -10)
    --	eb.scroll:SetPoint("BOTTOMRIGHT", eb, -30, 10)
    --
    --	eb.Text = CreateFrame("EditBox", nil, eb)
    --	eb.Text:SetMultiLine(true)
    --	eb.Text:SetWidth(494)
    --	eb.Text:SetHeight(230)
    --	eb.Text:SetPoint("TOPLEFT", eb.scroll)
    --	eb.Text:SetPoint("BOTTOMRIGHT", eb.scroll)
    --	eb.Text:SetMaxLetters(2000)
    --	eb.Text:SetFontObject(GameFontNormalLarge)
    --	eb.Text:SetAutoFocus(false)
    --	eb.Text:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    --	eb.scroll:SetScrollChild(eb.Text)
    --
    --	-- Set focus on the editbox text when clicking the editbox
    --	eb:SetScript("OnMouseDown", function()
    --		eb.Text:SetFocus()
    --		eb.Text:SetCursorPosition(eb.Text:GetMaxLetters())
    --	end)
    --
    --	-- Function to save the custom sound list
    --	local function SaveString(self, userInput)
    --		local keytext = eb.Text:GetText()
    --		if keytext and keytext ~= "" then
    --			LeaPlusLC["MuteCustomList"] = strtrim(eb.Text:GetText())
    --		else
    --			LeaPlusLC["MuteCustomList"] = ""
    --		end
    --	end
    --
    --	-- Save the custom sound list when it changes and at startup
    --	eb.Text:SetScript("OnTextChanged", SaveString)
    --	eb.Text:SetText(LeaPlusLC["MuteCustomList"])
    --	SaveString()
    --
    --	-- Help button hidden
    --	MuteCustomPanel.h:Hide()
    --
    --	-- Back button handler
    --	MuteCustomPanel.b:SetScript("OnClick", function()
    --		MuteCustomPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
    --		return
    --	end)
    --
    --	-- Reset button hidden
    --	MuteCustomPanel.r:Hide()
    --
    --	-- Show configuration panal when options panel button is clicked
    --	LeaPlusCB["MuteCustomSoundsBtn"]:SetScript("OnClick", function()
    --		if IsShiftKeyDown() and IsControlKeyDown() then
    --			-- Preset profile
    --			LeaPlusLC["MuteCustomList"] = "Devotion Aura 569679, Retribution Aura 568744"
    --			eb.Text:SetText(LeaPlusLC["MuteCustomList"])
    --		else
    --			MuteCustomPanel:Show()
    --			LeaPlusLC:HideFrames()
    --		end
    --	end)
    --
    --	-- Function to mute custom sound list
    --	local function MuteCustomListFunc(unmute, userInput)
    --		-- local mutedebug = true -- Debug
    --		local counter = 0
    --		local muteString = LeaPlusLC["MuteCustomList"]
    --		if muteString and muteString ~= "" then
    --			muteString = muteString:gsub("%s", ",")
    --			muteString = muteString:gsub("[\n]", ",")
    --			muteString = muteString:gsub("[^,%d]", "")
    --			if mutedebug then print(muteString) end
    --			local tList = {strsplit(",", muteString)}
    --			if mutedebug then ChatFrame1:Clear() end
    --			for i = 1, #tList do
    --				if tList[i] then
    --					tList[i] = tonumber(tList[i])
    --					if tList[i] and tList[i] < 20000000 then
    --						if mutedebug then print(tList[i]) end
    --						if unmute then
    --							UnmuteSoundFile(tList[i])
    --						else
    --							MuteSoundFile(tList[i])
    --						end
    --						counter = counter + 1
    --					end
    --				end
    --			end
    --			if userInput then
    --				if unmute then
    --					if counter == 1 then
    --						LeaPlusLC:Print(L["Unmuted"] .. " " .. counter .. " " .. L["sound"] .. ".")
    --					else
    --						LeaPlusLC:Print(L["Unmuted"] .. " " .. counter .. " " .. L["sounds"] .. ".")
    --					end
    --				else
    --					if counter == 1 then
    --						LeaPlusLC:Print(L["Muted"] .. " " .. counter .. " " .. L["sound"] .. ".")
    --					else
    --						LeaPlusLC:Print(L["Muted"] .. " " .. counter .. " " .. L["sounds"] .. ".")
    --					end
    --				end
    --			end
    --		end
    --	end
    --
    --	-- Mute custom list on startup if option is enabled
    --	if LeaPlusLC["MuteCustomSounds"] == "On" then
    --		MuteCustomListFunc()
    --	end
    --
    --	-- Mute or unmute when option is clicked
    --	LeaPlusCB["MuteCustomSounds"]:HookScript("OnClick", function()
    --		if LeaPlusLC["MuteCustomSounds"] == "On" then
    --			MuteCustomListFunc(false, false)
    --		else
    --			MuteCustomListFunc(true, false)
    --		end
    --	end)
    --
    --	-- Add mute button
    --	local MuteCustomNowButton = LeaPlusLC:CreateButton("MuteCustomNowButton", MuteCustomPanel, "Mute", "TOPLEFT", 16, -292, 0, 25, true, "Click to mute sounds in the list.")
    --	LeaPlusCB["MuteCustomNowButton"]:SetScript("OnClick", function() MuteCustomListFunc(false, true) end)
    --
    --	-- Add unmute button
    --	local UnmuteCustomNowButton = LeaPlusLC:CreateButton("UnmuteCustomNowButton", MuteCustomPanel, "Unmute", "TOPLEFT", 16, -72, 0, 25, true, "Click to unmute sounds in the list.")
    --	LeaPlusCB["UnmuteCustomNowButton"]:ClearAllPoints()
    --	LeaPlusCB["UnmuteCustomNowButton"]:SetPoint("LEFT", MuteCustomNowButton, "RIGHT", 10, 0)
    --	LeaPlusCB["UnmuteCustomNowButton"]:SetScript("OnClick", function() MuteCustomListFunc(true, true) end)
    --
    --	-- Add play sound file editbox
    --	local willPlay, musicHandle
    --	local MuteCustomSoundsStopButton = LeaPlusLC:CreateButton("MuteCustomSoundsStopButton", MuteCustomPanel, "Stop", "TOPRIGHT", -18, -66, 0, 25, true, "")
    --	MuteCustomSoundsStopButton:SetScript("OnClick", function()
    --		if musicHandle then StopSound(musicHandle) end
    --	end)
    --
    --	local MuteCustomSoundsPlayButton = LeaPlusLC:CreateButton("MuteCustomSoundsPlayButton", MuteCustomPanel, "Play", "TOPRIGHT", -18, -66, 0, 25, true, "")
    --	MuteCustomSoundsPlayButton:ClearAllPoints()
    --	MuteCustomSoundsPlayButton:SetPoint("RIGHT", MuteCustomSoundsStopButton, "LEFT", -10, 0)
    --
    --	local MuteCustomSoundsSoundBox = LeaPlusLC:CreateEditBox("MuteCustomSoundsSoundBox", eb, 80, 8, "TOPRIGHT", -10, 20, "PlaySoundBox", "PlaySoundBox")
    --	MuteCustomSoundsSoundBox:SetNumeric(true)
    --	MuteCustomSoundsSoundBox:ClearAllPoints()
    --	MuteCustomSoundsSoundBox:SetPoint("RIGHT", MuteCustomSoundsPlayButton, "LEFT", -10, 0)
    --	MuteCustomSoundsPlayButton:SetScript("OnClick", function()
    --		MuteCustomSoundsSoundBox:GetText()
    --		if musicHandle then StopSound(musicHandle) end
    --		willPlay, musicHandle = PlaySoundFile(MuteCustomSoundsSoundBox:GetText(), "Master")
    --	end)
    --
    --	-- Add mousewheel support to the editbox
    --	MuteCustomSoundsSoundBox:SetScript("OnMouseWheel", function(self, delta)
    --		local endSound = tonumber(MuteCustomSoundsSoundBox:GetText())
    --		if endSound then
    --			if delta == 1 then endSound = endSound + 1 else endSound = endSound - 1 end
    --			if endSound < 1 then endSound = 1 elseif endSound >= 10000000 then endSound = 10000000 end
    --			MuteCustomSoundsSoundBox:SetText(endSound)
    --			MuteCustomSoundsPlayButton:Click()
    --		end
    --	end)
    --
    --	local titlePlayer = LeaPlusLC:MakeTx(MuteCustomPanel, "Player", 16, -72)
    --	titlePlayer:ClearAllPoints()
    --	titlePlayer:SetPoint("TOPLEFT", MuteCustomSoundsSoundBox, "TOPLEFT", -4, 16)
    --	LeaPlusLC:CreateHelpButton("MuteGameSoundsCustomPlayHelpButton", MuteCustomPanel, titlePlayer, "If you want to listen to a sound file, enter the sound file ID into the editbox and click the play button.|n|nYou can scroll the mousewheel over the editbox to play neighbouring sound files.")
    --end

    ----------------------------------------------------------------------
    -- Manage vehicle
    ----------------------------------------------------------------------

    if LeaPlusLC["ManageVehicle"] == "On" and not LeaLockList["ManageVehicle"] then

        -- Create and manage container for VehicleSeatIndicator
        local vehicleHolder = CreateFrame("Frame", nil, UIParent)
        vehicleHolder:SetPoint("TOP", UIParent, "TOP", 0, -15)
        vehicleHolder:SetSize(128, 128)

        local vehicleContainer = _G.VehicleSeatIndicator
        vehicleContainer:ClearAllPoints()
        vehicleContainer:SetPoint('CENTER', vehicleHolder)
        --vehicleContainer:SetIgnoreParentScale(true) -- Needed to keep drag frame position when scaled

        hooksecurefunc(vehicleContainer, 'SetPoint', function(self, void, b)
            if b and (b ~= vehicleHolder) then
                -- Reset parent if it changes from vehicleHolder
                self:ClearAllPoints()
                self:SetPoint('TOPRIGHT', vehicleHolder) -- Has to be TOPRIGHT (drag frame while moving between subzones)
                self:SetParent(vehicleHolder)
            end
        end)

        -- Allow vehicle frame to be moved
        vehicleHolder:SetMovable(true)
        vehicleHolder:SetUserPlaced(true)
        vehicleHolder:SetDontSavePosition(true)
        vehicleHolder:SetClampedToScreen(false)

        -- Set vehicle frame position at startup
        vehicleHolder:ClearAllPoints()
        vehicleHolder:SetPoint(LeaPlusLC["VehicleA"], UIParent, LeaPlusLC["VehicleR"], LeaPlusLC["VehicleX"], LeaPlusLC["VehicleY"])
        vehicleHolder:SetScale(LeaPlusLC["VehicleScale"])
        VehicleSeatIndicator:SetScale(LeaPlusLC["VehicleScale"])

        -- Create drag frame
        local dragframe = CreateFrame("FRAME", nil, nil)
        dragframe:SetPoint("CENTER", vehicleHolder, "CENTER", 0, 1)
        dragframe:SetBackdropColor(0.0, 0.5, 1.0)
        dragframe:SetBackdrop({ edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
        dragframe:SetToplevel(true)
        dragframe:EnableMouse(true)
        dragframe:Hide()
        dragframe:SetScale(LeaPlusLC["VehicleScale"])

        dragframe.t = dragframe:CreateTexture()
        dragframe.t:SetAllPoints()
        dragframe.t:SetTexture(0.0, 1.0, 0.0, 0.5)
        dragframe.t:SetAlpha(0.5)

        dragframe.f = dragframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
        dragframe.f:SetPoint('CENTER', 0, 0)
        dragframe.f:SetText(L["Vehicle"])

        -- Click handler
        dragframe:SetScript("OnMouseDown", function(self, btn)
            -- Start dragging if left clicked
            if btn == "LeftButton" then
                vehicleHolder:StartMoving()
            end
        end)

        dragframe:SetScript("OnMouseUp", function()
            -- Save frame position
            vehicleHolder:StopMovingOrSizing()
            LeaPlusLC["VehicleA"], void, LeaPlusLC["VehicleR"], LeaPlusLC["VehicleX"], LeaPlusLC["VehicleY"] = vehicleHolder:GetPoint()
            vehicleHolder:SetMovable(true)
            vehicleHolder:ClearAllPoints()
            vehicleHolder:SetPoint(LeaPlusLC["VehicleA"], UIParent, LeaPlusLC["VehicleR"], LeaPlusLC["VehicleX"], LeaPlusLC["VehicleY"])
        end)

        -- Snap-to-grid
        do
            local frame, grid = dragframe, 10
            local w, h = 120, 128
            local xpos, ypos, scale, uiscale
            frame:RegisterForDrag("RightButton")
            frame:HookScript("OnDragStart", function()
                frame:SetScript("OnUpdate", function()
                    scale, uiscale = frame:GetScale(), UIParent:GetScale()
                    xpos, ypos = GetCursorPosition()
                    xpos = floor((xpos / scale / uiscale) / grid) * grid - w / 2
                    ypos = ceil((ypos / scale / uiscale) / grid) * grid + h / 2
                    vehicleHolder:ClearAllPoints()
                    vehicleHolder:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", xpos, ypos)
                end)
            end)
            frame:HookScript("OnDragStop", function()
                frame:SetScript("OnUpdate", nil)
                frame:GetScript("OnMouseUp")()
            end)
        end

        -- Create configuration panel
        local VehiclePanel = LeaPlusLC:CreatePanel("Manage vehicle", "VehiclePanel")

        LeaPlusLC:MakeTx(VehiclePanel, "Scale", 16, -72)
        LeaPlusLC:MakeSL(VehiclePanel, "VehicleScale", "Drag to set the vehicle seat indicator frame scale.", 0.5, 2, 0.05, 16, -92, "%.2f")

        -- Set scale when slider is changed
        LeaPlusCB["VehicleScale"]:HookScript("OnValueChanged", function()
            vehicleHolder:SetScale(LeaPlusLC["VehicleScale"])
            VehicleSeatIndicator:SetScale(LeaPlusLC["VehicleScale"])
            dragframe:SetScale(LeaPlusLC["VehicleScale"])
            -- Show formatted slider value
            LeaPlusCB["VehicleScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["VehicleScale"] * 100)
        end)

        -- Hide frame alignment grid with panel
        VehiclePanel:HookScript("OnHide", function()
            LeaPlusLC.grid:Hide()
        end)

        -- Toggle grid button
        local VehicleToggleGridButton = LeaPlusLC:CreateButton("VehicleToggleGridButton", VehiclePanel, "Toggle Grid", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the frame alignment grid.")
        LeaPlusCB["VehicleToggleGridButton"]:ClearAllPoints()
        LeaPlusCB["VehicleToggleGridButton"]:SetPoint("LEFT", VehiclePanel.h, "RIGHT", 10, 0)
        LeaPlusCB["VehicleToggleGridButton"]:SetScript("OnClick", function()
            if LeaPlusLC.grid:IsShown() then
                LeaPlusLC.grid:Hide()
            else
                LeaPlusLC.grid:Show()
            end
        end)
        VehiclePanel:HookScript("OnHide", function()
            if LeaPlusLC.grid then
                LeaPlusLC.grid:Hide()
            end
        end)

        -- Help button tooltip
        VehiclePanel.h.tiptext = L["Drag the frame overlay with the left button to position it freely or with the right button to position it using snap-to-grid."]

        -- Back button handler
        VehiclePanel.b:SetScript("OnClick", function()
            VehiclePanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page6"]:Show()
            return
        end)

        -- Reset button handler
        VehiclePanel.r:SetScript("OnClick", function()

            -- Reset position and scale
            LeaPlusLC["VehicleA"] = "TOPRIGHT"
            LeaPlusLC["VehicleR"] = "TOPRIGHT"
            LeaPlusLC["VehicleX"] = -100
            LeaPlusLC["VehicleY"] = -192
            LeaPlusLC["VehicleScale"] = 1
            vehicleHolder:ClearAllPoints()
            vehicleHolder:SetPoint(LeaPlusLC["VehicleA"], UIParent, LeaPlusLC["VehicleR"], LeaPlusLC["VehicleX"], LeaPlusLC["VehicleY"])

            -- Refresh configuration panel
            VehiclePanel:Hide();
            VehiclePanel:Show()
            dragframe:Show()

            -- Show frame alignment grid
            LeaPlusLC.grid:Show()

        end)

        -- Show configuration panel when options panel button is clicked
        LeaPlusCB["ManageVehicleButton"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["VehicleA"] = "TOPRIGHT"
                LeaPlusLC["VehicleR"] = "TOPRIGHT"
                LeaPlusLC["VehicleX"] = -100
                LeaPlusLC["VehicleY"] = -192
                LeaPlusLC["VehicleScale"] = 1
                vehicleHolder:ClearAllPoints()
                vehicleHolder:SetPoint(LeaPlusLC["VehicleA"], UIParent, LeaPlusLC["VehicleR"], LeaPlusLC["VehicleX"], LeaPlusLC["VehicleY"])
                vehicleHolder:SetScale(LeaPlusLC["VehicleScale"])
                VehicleSeatIndicator:SetScale(LeaPlusLC["VehicleScale"])
            else
                -- Find out if the UI has a non-standard scale
                if GetCVar("useuiscale") == "1" then
                    LeaPlusLC["gscale"] = GetCVar("uiscale")
                else
                    LeaPlusLC["gscale"] = 1
                end

                -- Set drag frame size according to UI scale
                dragframe:SetWidth(128 * LeaPlusLC["gscale"])
                dragframe:SetHeight(128 * LeaPlusLC["gscale"])

                -- Show configuration panel
                VehiclePanel:Show()
                LeaPlusLC:HideFrames()
                dragframe:Show()

                -- Show frame alignment grid
                LeaPlusLC.grid:Show()
            end
        end)

        -- Hide drag frame when configuration panel is closed
        VehiclePanel:HookScript("OnHide", function()
            dragframe:Hide()
        end)

    end

    ----------------------------------------------------------------------
    -- Block shared quests (no reload needed)
    ----------------------------------------------------------------------

    do

        local eFrame = CreateFrame("FRAME")
        eFrame:SetScript("OnEvent", LeaPlusLC.CheckIfQuestIsSharedAndShouldBeDeclined)

        -- Function to set event
        local function SetSharedQuestsFunc()
            if LeaPlusLC["NoSharedQuests"] == "On" then
                eFrame:RegisterEvent("QUEST_DETAIL")
            else
                eFrame:UnregisterEvent("QUEST_DETAIL")
            end
        end

        -- Set event when option is clicked and on startup
        LeaPlusCB["NoSharedQuests"]:HookScript("OnClick", SetSharedQuestsFunc)
        SetSharedQuestsFunc()

    end

    ----------------------------------------------------------------------
    -- Restore chat messages
    ----------------------------------------------------------------------

    if LeaPlusLC["RestoreChatMessages"] == "On" and not LeaLockList["RestoreChatMessages"] then

        -- ===== helpers ==================================================
        local chatTypeIndexToName = {}
        for t in pairs(ChatTypeInfo) do
            chatTypeIndexToName[ GetChatTypeIndex(t) ] = t
        end

        local function CleanAndColour(msg, lineID)
            msg = gsub(msg, "|T.-|t", "")         -- strip textures
            msg = gsub(msg, "|A.-|a", "")         -- strip atlases
            local inf = ChatTypeInfo[ chatTypeIndexToName[lineID] ]
            local r, g, b = (inf and inf.r) or 1, (inf and inf.g) or 1, (inf and inf.b) or 1
            local hex     = format("|cff%02x%02x%02x", r*255, g*255, b*255)
            return hex .. msg:gsub("|r", "|r"..hex) .. "|r"
        end

        local function WindowActive(idx)
            local shown = select(7, FCF_GetChatWindowInfo(idx))
            if shown then return true end
            local f = _G["ChatFrame"..idx]
            return (f and f.isDocked)
        end

        -- ===== SAVE on logout ===========================================
        local saver = CreateFrame("Frame")
        saver:RegisterEvent("PLAYER_LOGOUT")
        saver:SetScript("OnEvent", function()
            local name, realm = LibCompat.UnitFullName("player")
            realm = realm or GetRealmName() ; if not name then return end

            LeaPlusDB["ChatHistoryName"] = name .. "-" .. realm
            LeaPlusDB["ChatHistoryTime"] = time()

            for i = 1, 50 do
                if i ~= 2 and _G["ChatFrame"..i] and WindowActive(i) then
                    local cf, num  = _G["ChatFrame"..i], _G["ChatFrame"..i]:GetNumMessages()
                    local first    = (num > 128) and (num - 128 + 1) or 1
                    LeaPlusDB["ChatHistory"..i] = {}

                    for n = first, num do
                        local txt, _, lineID = cf:GetMessageInfo(n)
                        if txt and not txt:find(L["Restored"], 1, true) then
                            tinsert(LeaPlusDB["ChatHistory"..i], CleanAndColour(txt, lineID))
                        end
                    end
                end
            end
        end)

        -- ===== RESTORE once UI is up ====================================
        local function Restore()
            if not (LeaPlusDB["ChatHistoryTime"] and LeaPlusDB["ChatHistoryName"]) then return end
            if time() - LeaPlusDB["ChatHistoryTime"] > 10 then return end

            for i = 1, 50 do
                if i ~= 2 and _G["ChatFrame"..i] and WindowActive(i) then
                    local cf = _G["ChatFrame"..i]
                    cf:Clear()
                    local restored = 0

                    for _, line in ipairs(LeaPlusDB["ChatHistory"..i] or {}) do
                        cf:AddMessage(line)
                        restored = restored + 1
                    end

                    if restored > 0 then
                        cf:AddMessage(format("|cffffd800%s %d %s|r",
                                L["Restored"], restored, L["message from previous session"]))
                    end
                end
            end
        end
        LibCompat.After(1, Restore)

        -- ===== OPTION OFF – wipe stored history =============================
    else
        LeaPlusDB["ChatHistoryName"] = nil
        LeaPlusDB["ChatHistoryTime"] = nil
        for i = 1, 50 do
            LeaPlusDB["ChatHistory"..i]       = nil
            LeaPlusDB["ChatTemp"..i]          = nil
            LeaPlusDB["ChatHistory"..i.."Count"] = nil
        end
    end

    ----------------------------------------------------------------------
    -- Enhance minimap
    ----------------------------------------------------------------------

    if LeaPlusLC["MinimapModder"] == "On" and not LeaLockList["MinimapModder"] then

        local miniFrame = CreateFrame("FRAME")
        local LibDBIconStub = LibStub("LibDBIcon-1.0")

        -- Function to set button radius
        local function SetButtonRad()
            if LeaPlusLC["SquareMinimap"] == "On" then
                -- LibDBIconStub:SetButtonRadius(26 + ((LeaPlusLC["MinimapSize"] - 140) * 0.165))
            else
                -- LibDBIconStub:SetButtonRadius(1)
            end
        end

        -- Disable mouse on invisible minimap cluster
        MinimapCluster:EnableMouse(false)

        ----------------------------------------------------------------------
        -- Configuration panel
        ----------------------------------------------------------------------

        -- Create configuration panel
        local SideMinimap = LeaPlusLC:CreatePanel("Enhance minimap", "SideMinimap")

        -- Hide panel during combat
        SideMinimap:SetScript("OnUpdate", function()
            if UnitAffectingCombat("player") then
                SideMinimap:Hide()
            end
        end)

        -- Add checkboxes
        LeaPlusLC:MakeTx(SideMinimap, "Settings", 16, -72)
        LeaPlusLC:MakeCB(SideMinimap, "HideMiniZoomBtns", "Hide the zoom buttons", 16, -92, false, "If checked, the zoom buttons will be hidden.  You can use the mousewheel to zoom regardless of this setting.")
        LeaPlusLC:MakeCB(SideMinimap, "HideMiniZoneText", "Hide the zone text bar", 16, -112, false, "If checked, the zone text bar will be hidden.")
        LeaPlusLC:MakeCB(SideMinimap, "HideMiniMapButton", "Hide the world map button", 16, -132, false, "If checked, the world map button will be hidden.")
        LeaPlusLC:MakeCB(SideMinimap, "HideMiniTracking", "Hide the tracking button", 16, -152, true, "If checked, the tracking button will be hidden. Right-click on the minimap to show tracking menu.")
        LeaPlusLC:MakeCB(SideMinimap, "HideMiniCalendar", "Hide calendar button.", 226, -92, true, "If checked, the calendar button will be hidden. Shift+Middle-click on the minimap to show calendar frame.")
        LeaPlusLC:MakeCB(SideMinimap, "HideMiniPOIArrows", "Hide POI arrows.", 226, -112, false, "If checked, the POI arrows (those on the edges of minimap) will be hidden.")
        LeaPlusLC:MakeCB(SideMinimap, "ClockMouseover", "Show Clock on Mouseover", 226, -132, false, "If checked, clock will be shown on mouseover.")
        LeaPlusLC:MakeCB(SideMinimap, "HideMiniAddonButtons", "Hide addon buttons", 16, -172, true, "If checked, addon buttons will be hidden while the pointer is not over the minimap.")

        LeaPlusLC:MakeCB(SideMinimap, "SquareMinimap", "Square minimap", 16, -212, true, "If checked, the minimap shape will be square.")
        LeaPlusLC:MakeCB(SideMinimap, "ShowWhoPinged", "Show who pinged", 16, -232, false, "If checked, when someone pings the minimap, their name will be shown.  This does not apply to your pings.")

        LeaPlusLC:CfgBtn("ModSquareMapBtn", LeaPlusCB["SquareMinimap"])

        -- Set dim on square minimap configuration button
        local function SetDimSquareMinimapButton()
            if LeaPlusLC["SquareMinimap"] == "On" then
                LeaPlusLC:LockItem(LeaPlusCB["ModSquareMapBtn"], false)
            else
                LeaPlusLC:LockItem(LeaPlusCB["ModSquareMapBtn"], true)
            end
        end
        SetDimSquareMinimapButton()

        -- Add excluded button
        local MiniExcludedButton = LeaPlusLC:CreateButton("MiniExcludedButton", SideMinimap, "Buttons", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the addon buttons editor.")
        LeaPlusCB["MiniExcludedButton"]:ClearAllPoints()
        LeaPlusCB["MiniExcludedButton"]:SetPoint("LEFT", SideMinimap.h, "RIGHT", 10, 0)

        -- Set exclude button visibility
        local function SetExcludeButtonsFunc()
            if LeaPlusLC["HideMiniAddonButtons"] == "On" or LeaPlusLC["CombineAddonButtons"] == "On" then
                LeaPlusLC:LockItem(LeaPlusCB["MiniExcludedButton"], false)
            else
                LeaPlusLC:LockItem(LeaPlusCB["MiniExcludedButton"], true)
            end
        end
        LeaPlusCB["HideMiniAddonButtons"]:HookScript("OnClick", SetExcludeButtonsFunc)
        SetExcludeButtonsFunc()

        -- Add slider controls
        LeaPlusLC:MakeTx(SideMinimap, "Scale", 406, -72)
        LeaPlusLC:MakeSL(SideMinimap, "MinimapScale", "Drag to set the minimap scale.|n|nAdjusting this slider makes the minimap and all the elements bigger.", 1, 4, 0.01, 406, -92, "%.2f")

        -- set x position for now to 10000, FIXME
        LeaPlusLC:MakeTx(SideMinimap, "Square size", 10000, -132)
        LeaPlusLC:MakeSL(SideMinimap, "MinimapSize", "Drag to set the square minimap size.|n|nAdjusting this slider makes the minimap bigger but keeps the elements the same size.", 140, 560, 1, 10000, -152, "%.0f")

        LeaPlusLC:MakeTx(SideMinimap, "Cluster scale", 406, -132)
        LeaPlusLC:MakeSL(SideMinimap, "MiniClusterScale", "Drag to set the cluster scale.|n|nNote: Adjusting the cluster scale affects the entire cluster including frames attached to it such as the quest watch frame.|n|nIt will also cause the default UI right-side action bars to scale when you login.  If you use the default UI right-side action bars, you may want to leave this at 100%.", 1, 2, 0.1, 406, -152, "%.2f")

        LeaPlusLC:MakeCB(SideMinimap, "CombineAddonButtons", "Combine addon buttons", 16, -192, true, "If checked, addon buttons will be combined into a single button frame which you can toggle by right-clicking the minimap.|n|nNote that enabling this option will lock out the 'Hide addon buttons' setting.", "Use slider to increase size of the frame and `Move Combined Frame` button to move it around. ")

        if LeaPlusLC["CombineAddonButtons"] == "On" then
            LeaPlusLC:MakeTx(SideMinimap, "Minimap buttons scale", 406, -212)
            LeaPlusLC:MakeSL(SideMinimap, "MiniAddonPanelScale", "Drag to adjust scale of the Minimap Combined Addons button frame.", 0, 2, 0.01, 406, -232, "%.2f")
        end


        -- set x position for now to 10000, FIXME
        LeaPlusLC:MakeCB(SideMinimap, "MinimapNoScale", "Not minimap", 10000, -242, false, "If checked, adjusting the cluster scale will not affect the minimap scale.")

        ----------------------------------------------------------------------
        -- Addon buttons editor
        ----------------------------------------------------------------------

        do

            -- Create configuration panel
            local ExcludedButtonsPanel = LeaPlusLC:CreatePanel("Enhance minimap", "ExcludedButtonsPanel")

            local titleTX = LeaPlusLC:MakeTx(ExcludedButtonsPanel, "Buttons for the addons listed below will remain visible.", 16, -72)
            titleTX:SetWidth(534)
            titleTX:SetWordWrap(false)
            titleTX:SetJustifyH("LEFT")

            -- -- Show framestack button to help user make an exclusion for certain addon button / blizzard button from hiding.
            -- LeaPlusLC:CreateFrameStackButton("ExcludedButtonsFrameStackButton", ExcludedButtonsPanel, titleTX, "Enter item IDs separated by commas.  Item IDs can be found in item tooltips while this panel is showing.|n|nJunk items entered here will not be sold automatically.|n|nWhite items entered here will be sold automatically.|n|nThe editbox tooltip will show you more information about the items you have entered.")


            -- Add second excluded button
            local MiniExcludedButton2 = LeaPlusLC:CreateButton("MiniExcludedButton2", ExcludedButtonsPanel, "Buttons", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the addon buttons editor.")
            LeaPlusCB["MiniExcludedButton2"]:ClearAllPoints()
            LeaPlusCB["MiniExcludedButton2"]:SetPoint("LEFT", ExcludedButtonsPanel.h, "RIGHT", 10, 0)
            LeaPlusCB["MiniExcludedButton2"]:SetScript("OnClick", function()
                ExcludedButtonsPanel:Hide();
                SideMinimap:Show()
                return
            end)


            -- Add second Framestack button
            local MiniExcludedButton2 = LeaPlusLC:CreateButton("FramestackButton2", ExcludedButtonsPanel, "Framestack", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle framestack, to view names of minimap buttons, and then be able to exclude them by entering their name.")
            LeaPlusCB["FramestackButton2"]:ClearAllPoints()
            LeaPlusCB["FramestackButton2"]:SetPoint("LEFT", ExcludedButtonsPanel.h, "RIGHT", 90, 0)
            -- LeaPlusCB["FramestackButton2"]:SetScript("OnClick", function()
            -- 	ExcludedButtonsPanel:Hide(); SideMinimap:Show()
            -- 	return
            -- end)
            LeaPlusCB["FramestackButton2"]:SetScript("OnClick", function()
                toggleFrameStack(true)
            end)

            -- Add large editbox
            local eb = CreateFrame("Frame", nil, ExcludedButtonsPanel)
            eb:SetSize(548, 180)
            eb:SetPoint("TOPLEFT", 10, -92)
            eb:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
                edgeSize = 16,
                insets = { left = 8, right = 6, top = 8, bottom = 8 },
            })
            eb:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.5)

            eb.scroll = CreateFrame("ScrollFrame", nil, eb)
            eb.scroll:SetPoint("TOPLEFT", eb, 12, -10)
            eb.scroll:SetPoint("BOTTOMRIGHT", eb, -30, 10)

            eb.Text = CreateFrame("EditBox", nil, eb)
            eb.Text:SetMultiLine(true)
            eb.Text:SetWidth(494)
            eb.Text:SetHeight(230)
            eb.Text:SetPoint("TOPLEFT", eb.scroll)
            eb.Text:SetPoint("BOTTOMRIGHT", eb.scroll)
            eb.Text:SetMaxLetters(1200)
            eb.Text:SetFontObject(GameFontNormalLarge)
            eb.Text:SetAutoFocus(false)
            eb.Text:SetScript("OnEscapePressed", function(self)
                self:ClearFocus()
            end)
            eb.scroll:SetScrollChild(eb.Text)

            -- Set focus on the editbox text when clicking the editbox
            eb:SetScript("OnMouseDown", function()
                eb.Text:SetFocus()
                eb.Text:SetCursorPosition(eb.Text:GetMaxLetters())
            end)

            -- Debug
            -- eb.Text:SetText("Leatrix_Plus\nLeatrix_Maps\nBugSack\nLeatrix_Plus\nLeatrix_Maps\nBugSack\nLeatrix_Plus\nLeatrix_Maps\nBugSack\nLeatrix_Plus\nLeatrix_Maps\nBugSack\nLeatrix_Plus\nLeatrix_Maps\nBugSack")

            -- Function to save the excluded list
            local function SaveString(self, userInput)
                local keytext = eb.Text:GetText()
                if keytext and keytext ~= "" then
                    LeaPlusLC["MiniExcludeList"] = strtrim(eb.Text:GetText())
                else
                    LeaPlusLC["MiniExcludeList"] = ""
                end
                if userInput then
                    LeaPlusLC:ReloadCheck()
                end
            end

            -- Save the excluded list when it changes and at startup
            eb.Text:SetScript("OnTextChanged", SaveString)
            eb.Text:SetText(LeaPlusLC["MiniExcludeList"])
            SaveString()

            -- Help button tooltip
            ExcludedButtonsPanel.h.tiptext = L["If you use the 'Hide addon buttons' or 'Combine addon buttons' settings but you want some addon buttons to remain visible around the minimap, enter the addon names into the editbox separated by a comma.|n|nThe editbox tooltip shows the addon names that you can enter.  The names must match exactly with the names shown in the editbox tooltip though case does not matter.|n|nChanges to the list will require a UI reload to take effect."]

            -- Back button handler
            ExcludedButtonsPanel.b:SetScript("OnClick", function()
                ExcludedButtonsPanel:Hide();
                LeaPlusLC["PageF"]:Show();
                LeaPlusLC["Page5"]:Show()
                return
            end)

            -- Reset button handler
            ExcludedButtonsPanel.r:SetScript("OnClick", function()

                -- Reset controls
                LeaPlusLC["MiniExcludeList"] = ""
                eb.Text:SetText(LeaPlusLC["MiniExcludeList"])

                -- Refresh configuration panel
                ExcludedButtonsPanel:Hide();
                ExcludedButtonsPanel:Show()
                LeaPlusLC:ReloadCheck()

            end)

            -- Show configuration panel when options panel button is clicked
            LeaPlusCB["MiniExcludedButton"]:SetScript("OnClick", function()
                if IsShiftKeyDown() and IsControlKeyDown() then
                    -- Preset profile
                    LeaPlusLC["MiniExcludeList"] = "BugSack, Leatrix_Plus"
                    LeaPlusLC:ReloadCheck()
                else
                    ExcludedButtonsPanel:Show()
                    LeaPlusGlobalPanel_SideMinimap:Hide()
                end
            end)

            -- Function to make tooltip string with list of addons
            local function MakeAddonString()
                local msg = ""
                local numAddons = GetNumAddOns()
                for i = 1, numAddons do
                    if IsAddOnLoaded(i) then
                        local name = GetAddOnInfo(i)
                        if name and _G["LibDBIcon10_" .. name] then
                            -- Only list LibDBIcon buttons
                            msg = msg .. name .. ", "
                        end
                    end
                end
                if msg ~= "" then
                    msg = "Example Input" .. "|n|n" .. msg:sub(1, (strlen(msg) - 2)) .. "."
                else
                    msg = L["No supported addons."]
                end
                eb.tiptext = msg
                eb.Text.tiptext = msg
            end

            -- Show the help button tooltip for the editbox too
            eb:SetScript("OnEnter", MakeAddonString)
            eb:HookScript("OnEnter", LeaPlusLC.TipSee)
            eb:SetScript("OnLeave", GameTooltip_Hide)
            eb.Text:SetScript("OnEnter", MakeAddonString)
            eb.Text:HookScript("OnEnter", LeaPlusLC.ShowDropTip)
            eb.Text:SetScript("OnLeave", GameTooltip_Hide)

        end

        ----------------------------------------------------------------------
        -- Show who pinged
        ----------------------------------------------------------------------

        do

            -- Create frame
            local pFrame = CreateFrame("FRAME", nil, Minimap)
            pFrame:SetSize(100, 20)

            -- Set position
            if LeaPlusLC["SquareMinimap"] == "On" then
                pFrame:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, -3) -- Move to the left
            else
                pFrame:SetPoint("BOTTOM", Minimap, "BOTTOM", -50, 2) -- Slightly offset to the left
            end

            -- Set backdrop
            pFrame.bg = {
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                insets = { left = 4, top = 4, right = 4, bottom = 4 },
                edgeSize = 16,
                tile = true,
            }

            pFrame:SetBackdrop(pFrame.bg)
            pFrame:SetBackdropColor(0, 0, 0, 0.7)
            pFrame:SetBackdropBorderColor(0, 0, 0, 0)

            -- Create fontstring
            pFrame.f = pFrame:CreateFontString(nil, nil, "GameFontNormalSmall")
            pFrame.f:SetAllPoints()
            pFrame:Hide()

            -- Set variables
            local pingTime
            local lastUnit, lastX, lastY = "player", 0, 0

            -- Show who pinged
            pFrame:SetScript("OnEvent", function(_, _, unit, x, y)
                -- Ignore if the ping is from the player or the same unit at the same location
                if UnitIsUnit(unit, "player") or (UnitIsUnit(unit, lastUnit) and x == lastX and y == lastY) then
                    return
                end
                lastUnit, lastX, lastY = unit, x, y

                -- Show name in class color
                local _, class = UnitClass(unit)
                if class then
                    local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
                    if color then
                        -- Set frame details
                        pFrame.f:SetFormattedText("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, UnitName(unit))
                        pFrame:SetSize(pFrame.f:GetStringWidth() + 12, 20)

                        -- Show frame
                        pFrame:Show()

                        -- Hide frame after 3 second
                        LibCompat.After(3, function()
                            -- Only hide if the last ping matches the current state
                            if UnitIsUnit(unit, lastUnit) and x == lastX and y == lastY then
                                pFrame:Hide()
                            end
                        end)
                    end
                end
            end)

            -- Set event when option is clicked and on startup
            local function SetPingFunc()
                if LeaPlusLC["ShowWhoPinged"] == "On" then
                    pFrame:RegisterEvent("MINIMAP_PING")
                else
                    pFrame:UnregisterEvent("MINIMAP_PING")
                    if pFrame:IsShown() then
                        pFrame:Hide()
                    end
                end
            end

            LeaPlusCB["ShowWhoPinged"]:HookScript("OnClick", SetPingFunc)
            SetPingFunc()

        end

        ----------------------------------------------------------------------
        -- Minimap scale
        ----------------------------------------------------------------------

        -- Function to set the minimap cluster scale
        local function SetClusterScale()
            MinimapCluster:SetScale(LeaPlusLC["MiniClusterScale"])
            -- Set slider formatted text
            LeaPlusCB["MiniClusterScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["MiniClusterScale"] * 100)
        end

        -- Set minimap scale when slider is changed and on startup
        LeaPlusCB["MiniClusterScale"]:HookScript("OnValueChanged", SetClusterScale)
        SetClusterScale()

        ----------------------------------------------------------------------
        -- Minimap size
        ----------------------------------------------------------------------

        if LeaPlusLC["SquareMinimap"] == "On" then

            -- Function to set minimap size
            local function SetMinimapSize()
                -- Set minimap size
                Minimap:SetSize(LeaPlusLC["MinimapSize"], LeaPlusLC["MinimapSize"])
                -- Refresh minimap
                if Minimap:GetZoom() ~= 5 then
                    Minimap:SetZoom(Minimap:GetZoom() + 1)
                    Minimap:SetZoom(Minimap:GetZoom() - 1)
                else
                    Minimap:SetZoom(Minimap:GetZoom() - 1)
                    Minimap:SetZoom(Minimap:GetZoom() + 1)
                end
                -- Refresh addon button radius
                SetButtonRad()
                -- Update slider text
                LeaPlusCB["MinimapSize"].f:SetFormattedText("%.0f%%", (LeaPlusLC["MinimapSize"] / 140) * 100)
            end

            -- Set minimap size when slider is changed and on startup
            LeaPlusCB["MinimapSize"]:HookScript("OnValueChanged", SetMinimapSize)
            SetMinimapSize()

            -- Assign file level scope (for reset and preset)
            LeaPlusLC.SetMinimapSize = SetMinimapSize

        else

            -- Square minimap is disabled so lock the size slider
            LeaPlusLC:LockItem(LeaPlusCB["MinimapSize"], true)
            LeaPlusCB["MinimapSize"].tiptext = LeaPlusCB["MinimapSize"].tiptext .. "|cff00AAFF|n|n" .. L["This slider requires 'Square minimap' to be enabled."] .. "|r"

        end

        ----------------------------------------------------------------------
        -- Combine addon buttons
        ----------------------------------------------------------------------

        if LeaPlusLC["CombineAddonButtons"] == "On" then

            -- Lock out hide minimap buttons
            LeaPlusLC:LockItem(LeaPlusCB["HideMiniAddonButtons"], true)
            LeaPlusCB["HideMiniAddonButtons"].tiptext = LeaPlusCB["HideMiniAddonButtons"].tiptext .. "|n|n|cff00AAFF" .. L["Cannot be used with Combine addon buttons."]

            -- First, we create a new frame to hold all the minimap buttons.
            local minimapFrame = CreateFrame("Frame", "Leatrix_ButtonGrabber", UIParent)
            LeaPlusLC['minimapFrameGlobal'] = minimapFrame
            minimapFrame:SetSize(1, 1)
            minimapFrame:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMLEFT", -2, -1.2)
            minimapFrame:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
                tile = true,
                tileSize = 16,
                edgeSize = 3,
                -- insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            minimapFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
            minimapFrame:SetBackdropBorderColor(1, 1, 1, 0.5)


            -- --===== Some code for testing - adds buttons to minimap =====--

            -- -- Load the libraries required for button creation.
            -- local LibDataBroker = LibStub:GetLibrary("LibDataBroker-1.1")
            -- local LibDBIcon = LibStub:GetLibrary("LibDBIcon-1.0")

            -- --===== Button 1 =====--

            -- -- Create the data broker objects for the custom buttons.
            -- local button1 = LibDataBroker:NewDataObject("Button1", {
            --     type = "launcher",
            --     icon = "Interface\\Icons\\inv_enchant_dustillusion",
            -- })

            -- -- Register the data broker objects with LibDBIcon to create minimap buttons.
            -- LibDBIcon:Register("Button1", button1, {
            --     icon = "Interface\\Icons\\inv_enchant_dustillusion",
            -- })


            -- --===== Button 2 =====--

            -- local button2 = LibDataBroker:NewDataObject("Button2", {
            --     type = "launcher",
            --     icon = "Interface\\Icons\\spell_holy_prayerofhealing02",
            -- })

            -- LibDBIcon:Register("Button2", button2, {
            --     icon = "Interface\\Icons\\spell_holy_prayerofhealing02",
            -- })


            -- --===== Button 3 =====--

            -- local button3 = LibDataBroker:NewDataObject("Button3", {
            --     type = "launcher",
            --     icon = "Interface\\Icons\\spell_nature_earthquake",
            -- })


            -- LibDBIcon:Register("Button3", button3, {
            --     icon = "Interface\\Icons\\spell_nature_earthquake",
            -- })



            -- --===== Button 4 =====--

            -- local button4 = LibDataBroker:NewDataObject("Button4", {
            --     type = "launcher",
            --     icon = "Interface\\Icons\\inv_misc_summerfest_braziergreen",
            -- })


            -- LibDBIcon:Register("Button4", button4, {
            --     icon = "Interface\\Icons\\inv_misc_summerfest_braziergreen",
            -- })



            -- --===== Button 5 =====--

            -- local button5 = LibDataBroker:NewDataObject("Button5", {
            --     type = "launcher",
            --     icon = "Interface\\Icons\\inv_misc_toy_02",
            -- })


            -- LibDBIcon:Register("Button5", button5, {
            --     icon = "Interface\\Icons\\inv_misc_toy_02",
            -- })



            -- --===== Button 6 =====--

            -- local button6 = LibDataBroker:NewDataObject("Button6", {
            --     type = "launcher",
            --     icon = "Interface\\Icons\\inv_misc_toy_02",
            -- })


            -- LibDBIcon:Register("Button6", button6, {
            --     icon = "Interface\\Icons\\inv_misc_toy_02",
            -- })



            --===== Define a table of minimap buttons to ignore =====--

            local WHITE_LIST = {
                'MiniMapBattlefieldFrame',
                'MiniMapTrackingButton',
                'MiniMapMailFrame',
                'HelpOpenTicketButton',
                'GatherMatePin',
                'HandyNotesPin',
                'TimeManagerClockButton',
                'Archy',
                'GatherNote',
                'MinimMap',
                'Spy_MapNoteList_mini',
                'ZGV',
                'poiWorldMapPOIFrame',
                'WorldMapPOIFrame',
                'QuestMapPOI',
                'GameTimeFrame',
                'ZygorGuidesViewerMapIcon',
                "Node",
                "Note",
                "Pin",
                "GuildInstance",
                -- GuildMap3
                "GuildMap3Mini",
                -- LibRockConfig
                "LibRockConfig-1.0_MinimapButton",
                -- Nauticus
                "NauticusMiniIcon",
                "WestPointer",
                -- QuestPointer
                "poiMinimap",
                "pfMiniMapPin"
            }

            local numColumns = 1 -- initialize the number of Columns as a global variable
            local numButtons = 0 -- initialize the number of buttons

            local function MoveMinimapChildren()
                local buttonWidth = 34 -- adjust this value to match the width of your minimap buttons
                local buttonSpacing = -6 -- adjust this value to match the spacing between your minimap buttons
                local maxButtonsPerColumn = 5 -- maximum number of buttons per column
                local maxColumns = 3 -- maximum number of columns

                -- not sure why i added it.
                --if InCombatLockdown() then
                --    return -- Stop execution if player is in combat.
                --end

                local excludedPatterns = {}
                for pattern in string.gmatch(LeaPlusDB["MiniExcludeList"], "[^,]+") do
                    table.insert(excludedPatterns, pattern)
                end

                local children = { Minimap:GetChildren() }
                local x = 0 -- initial x position
                local y = 0 -- initial y position

                for i, child in ipairs(children) do
                    if child and child:IsObjectType("Button") and child:GetName() then
                        local isWhitelisted = false
                        for _, name in ipairs(WHITE_LIST) do
                            if string.find(child:GetName(), name) then
                                isWhitelisted = true
                                -- print(child:GetName() .. " is whitelisted")
                                break
                            end
                        end
                        if not isWhitelisted then
                            local isExcluded = false
                            for _, pattern in ipairs(excludedPatterns) do
                                if string.find(child:GetName(), pattern) then
                                    isExcluded = true
                                    -- print(child:GetName() .. " is excluded")
                                    break
                                end
                            end
                            if not isExcluded then
                                local point, parent, relativePoint, xOfs, yOfs = child:GetPoint()
                                if parent == Minimap and point == "CENTER" then
                                    -- If the child is a minimap button and is positioned in the center of the Minimap frame, we move it to the minimapFrame and set its position.
                                    child:SetParent(minimapFrame)
                                    child:ClearAllPoints()
                                    child:SetPushedTexture(nil)
                                    child:SetHighlightTexture(nil)
                                    child:SetDisabledTexture(nil)
                                    child:SetScript("OnDragStart", nil)
                                    child:SetScript("OnDragStop", nil)

                                    if numButtons >= maxButtonsPerColumn * numColumns then
                                        -- We've reached the maximum number of buttons per column, so we move to the next column.
                                        if numColumns >= maxColumns then
                                            -- We've reached the maximum number of columns, so we stop adding buttons.
                                            break
                                        end
                                        numColumns = numColumns + 1
                                        numButtons = (numColumns - 1) * maxButtonsPerColumn -- calculate the number of buttons on the previous columns
                                        x = x - buttonWidth - buttonSpacing -- increment x position by a negative value to move to the left
                                        y = 0
                                    end

                                    local newY = y + (numButtons % maxButtonsPerColumn) * (buttonWidth + buttonSpacing) -- calculate y position for new button at the bottom right

                                    child:SetPoint("BOTTOMRIGHT", minimapFrame, "BOTTOMRIGHT", x - 3, newY + 2) -- set point to BOTTOMRIGHT to move button to the bottom right corner



                                    -- Loop through the regions of the minimap button and remove any unwanted textures.
                                    for j = 1, child:GetNumRegions() do
                                        local region = select(j, child:GetRegions())
                                        if region:GetObjectType() == "Texture" then
                                            local texture = region:GetTexture()
                                            --===== Make Buttons Square =====--
                                            region:SetTexCoord(0.2, 0.8, 0.2, 0.8)
                                            child:HookScript("OnLeave", function()
                                                region:SetTexCoord(0.2, 0.8, 0.2, 0.8)
                                            end)
                                            --===== Remove round texture around buttons =====--
                                            if texture and (string.find(texture, "Border") or string.find(texture, "Background") or string.find(texture, "AlphaMask")) then
                                                region:SetTexture(nil)
                                            end
                                        end
                                    end

                                    numButtons = numButtons + 1
                                end
                            end
                        end
                    end
                end
                -- print("Number of buttons in first column: " .. (numButtons % maxButtonsPerColumn))

                -- Resize the minimapFrame based on the number of columns and buttons.
                local frameHeight = buttonWidth * maxButtonsPerColumn + buttonSpacing * (maxButtonsPerColumn - 1)
                minimapFrame:SetWidth(numColumns * (buttonWidth + buttonSpacing) + 6)
                if numButtons <= maxButtonsPerColumn then
                    minimapFrame:SetHeight(buttonWidth * numButtons + buttonSpacing * (numButtons - 1))
                else
                    minimapFrame:SetHeight(frameHeight)
                end

                -- print("Number of buttons: " .. numButtons)
            end

            -- Match scale with minimap
            if LeaPlusLC["SquareMinimap"] == "On" then
                minimapFrame:SetScale(LeaPlusLC["MinimapScale"] * 0.85)
            else
                minimapFrame:SetScale(LeaPlusLC["MinimapScale"] * 0.90)
                minimapFrame:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMLEFT", -5, -1)
            end
            --LeaPlusCB["MinimapScale"]:HookScript("OnValueChanged", function()
            --	if LeaPlusLC["SquareMinimap"] == "On" then
            --		minimapFrame:SetScale(LeaPlusLC["MinimapScale"] * 0.85)
            --	else
            --		minimapFrame:SetScale(LeaPlusLC["MinimapScale"] * 0.90)
            --	minimapFrame:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMLEFT", -5, -1)
            --	end
            --end)




            local ticks = 0 -- keep track of how many times the function has been called
            local ticker = nil -- keep track of the timer object

            local function OnLoginHideCombine(eventName, ...)
                ticker = LibCompat.NewTicker(0.3, function()
                    ticks = ticks + 1 -- increment the tick counter
                    -- print("tick #".. ticks)
                    MoveMinimapChildren()
                    if ticks >= 5 then
                        -- stop after 6 seconds have passed (20 ticks * 0.3 seconds per tick)
                        LibCompat.CancelTimer(ticker) -- stop the timer
                    end
                end)
            end


            -- Register the OnLoginHideCombine function to fire when the "PLAYER_ENTERING_WORLD" event occurs.
            local eventFrame = CreateFrame("FRAME")
            eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

            -- eventFrame:RegisterEvent("PLAYER_LOGIN")
            eventFrame:SetScript("OnEvent", OnLoginHideCombine)

            -- Modify the Minimap's OnMouseUp event handler to use MiddleButton
            LibCompat.After(1, function()
                Minimap:HookScript("OnMouseUp", function(self, button)
                    if button == "MiddleButton" and not IsShiftKeyDown() then
                        if LeaPlusLC['minimapFrameGlobal']:IsShown() then
                            LeaPlusLC['minimapFrameGlobal']:Hide()
                            LeaPlusDB["HiddenCombineFrame"] = "On" -- Set the DB value to "On" if hidden
                        else
                            LeaPlusLC['minimapFrameGlobal']:Show()
                            LeaPlusDB["HiddenCombineFrame"] = "Off" -- Set the DB value to "Off" if shown
                        end
                    end
                end)
            end)

            -- Function to handle the PLAYER_ENTERING_WORLD event
            local function OnLoginCombineVisibilityState(eventName, ...)
                if LeaPlusDB["HiddenCombineFrame"] == "On" then
                    LeaPlusLC['minimapFrameGlobal']:Hide() -- Hide the frame if the DB value is "On"
                else
                    LeaPlusLC['minimapFrameGlobal']:Show() -- Show the frame if the DB value is not "On"
                end
            end

            -- eventFrame:RegisterEvent("PLAYER_LOGIN")
            eventFrame:HookScript("OnEvent", OnLoginCombineVisibilityState)



            --------------------------------------------------------------------------------
            ---- Combine addon buttons frame scale and move button
            --------------------------------------------------------------------------------


            -- Function to set the combined addons frame scale
            function LeaPlusLC:SetMinimapAddonButtonsFrameScale()
                LeaPlusLC['minimapFrameGlobal']:SetScale(LeaPlusLC["MiniAddonPanelScale"])
                -- Set slider formatted text
                LeaPlusCB["MiniAddonPanelScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["MiniAddonPanelScale"] * 100)
            end

            if LeaPlusLC["CombineAddonButtons"] == "On" then

                -- Create drag frame
                local dragframe = CreateFrame("FRAME", nil, nil)

                -- Set combined addons frame scale when slider is changed and on startup
                LeaPlusCB["MiniAddonPanelScale"]:HookScript("OnValueChanged", function()
                    LeaPlusLC:SetMinimapAddonButtonsFrameScale()
                    dragframe:SetScale(LeaPlusLC['minimapFrameGlobal']:GetScale() - 0.10)
                end)
                LeaPlusLC:SetMinimapAddonButtonsFrameScale()

                --------------------------------------------------------------------------------
                ---- Allow CombineAddonsFrame frame to be moved
                --------------------------------------------------------------------------------

                LeaPlusLC['minimapFrameGlobal']:SetMovable(true)
                LeaPlusLC['minimapFrameGlobal']:SetUserPlaced(true)
                LeaPlusLC['minimapFrameGlobal']:SetDontSavePosition(true)
                LeaPlusLC['minimapFrameGlobal']:SetClampedToScreen(false)

                -- Set CombineAddonsFrame frame position at startup
                LeaPlusLC['minimapFrameGlobal']:ClearAllPoints()


                -- reanchor to UIParent if user moved the frame, because if relative to Minimap we getting bugs.
                if LeaPlusLC["CombineAddonsFrameX"] == -2 and LeaPlusLC["CombineAddonsFrameY"] == -1.2 then
                    LeaPlusLC['minimapFrameGlobal']:SetPoint(LeaPlusLC["CombineAddonsFrameA"], Minimap, LeaPlusLC["CombineAddonsFrameR"], LeaPlusLC["CombineAddonsFrameX"], LeaPlusLC["CombineAddonsFrameY"])
                else
                    LeaPlusLC['minimapFrameGlobal']:SetPoint(LeaPlusLC["CombineAddonsFrameA"], UIParent, LeaPlusLC["CombineAddonsFrameR"], LeaPlusLC["CombineAddonsFrameX"], LeaPlusLC["CombineAddonsFrameY"])
                end
                --LeaPlusLC['minimapFrameGlobal']:SetScale(LeaPlusLC["CombineAddonsFrameScale"])
                --LeaPlusLC['minimapFrameGlobal']:SetScale(LeaPlusLC["CombineAddonsFrameScale"])


                dragframe:SetPoint("CENTER", LeaPlusLC['minimapFrameGlobal'], "CENTER", 0, 1)

                local function getDragFrameSize()
                    local width = LeaPlusLC['minimapFrameGlobal']:GetWidth()
                    local height = LeaPlusLC['minimapFrameGlobal']:GetHeight()
                    return width, height
                end

                local function setDragFrameSize()
                    local width, height = getDragFrameSize()
                    dragframe:SetSize(width, height)
                end

                LibCompat.After(3, function()
                    setDragFrameSize()
                    local width, height = getDragFrameSize()
                    if width <= 1 or height <= 1 then
                        --print("go agane")
                        LibCompat.After(3, function()
                            setDragFrameSize()
                        end)
                    end
                end)
                dragframe:SetBackdropColor(0.0, 0.5, 1.0)
                --dragframe:SetBackdrop({edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, insets = { left = 0, right = 0, top = 0, bottom = 0}})
                dragframe:SetToplevel(true)
                dragframe:EnableMouse(true)
                dragframe:SetFrameStrata("TOOLTIP")
                dragframe:Hide()
                dragframe:SetScale(LeaPlusLC['minimapFrameGlobal']:GetScale() - 0.10)

                dragframe.t = dragframe:CreateTexture()
                dragframe.t:SetAllPoints(LeaPlusLC['minimapFrameGlobal'])
                dragframe.t:SetTexture(0.0, 1.0, 0.0, 0.5)
                dragframe.t:SetAlpha(0.5)

                dragframe.f = dragframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
                dragframe.f:SetPoint('CENTER', 0, 0)
                dragframe.f:SetText("Move")

                -- Click handler
                dragframe:SetScript("OnMouseDown", function(self, btn)
                    -- Start dragging if left clicked
                    if btn == "LeftButton" then
                        LeaPlusLC['minimapFrameGlobal']:StartMoving()
                        -- Hide frame if right button is clicked
                    else
                        LeaPlusLC['minimapFrameGlobal']:StopMovingOrSizing()
                        dragframe:Hide()
                    end
                end)

                dragframe:SetScript("OnMouseUp", function()
                    -- Save frame position
                    LeaPlusLC['minimapFrameGlobal']:StopMovingOrSizing()
                    LeaPlusLC["CombineAddonsFrameA"], void, LeaPlusLC["CombineAddonsFrameR"], LeaPlusLC["CombineAddonsFrameX"], LeaPlusLC["CombineAddonsFrameY"] = LeaPlusLC['minimapFrameGlobal']:GetPoint()
                    LeaPlusLC['minimapFrameGlobal']:SetMovable(true)
                    LeaPlusLC['minimapFrameGlobal']:ClearAllPoints()
                    LeaPlusLC['minimapFrameGlobal']:SetPoint(LeaPlusLC["CombineAddonsFrameA"], UIParent, LeaPlusLC["CombineAddonsFrameR"], LeaPlusLC["CombineAddonsFrameX"], LeaPlusLC["CombineAddonsFrameY"])
                end)



                -- Add Button to Move Combined Minimap Buttons frame
                local MoveCombinedFrame = LeaPlusLC:CreateButton("MoveCombinedFrame", SideMinimap, "Move Combined Frame", "TOPLEFT", 16, -262, 0, 25, true, "Click to move:|n|nCombined addon buttons frame.")
                --LeaPlusCB["MoveCombinedFrame"]:ClearAllPoints()
                --LeaPlusCB["MoveCombinedFrame"]:SetPoint("LEFT", SideMinimap.h, "LEFT", 90, 0)
                LeaPlusCB["MoveCombinedFrame"]:SetScript("OnClick", function()
                    if dragframe:GetWidth() == 1 then
                        setDragFrameSize()
                    end
                    if dragframe:IsShown() then
                        dragframe:Hide()
                    else
                        dragframe:Show()
                    end
                end)


            else
                if LeaPlusCB["MiniAddonPanelScale"] then
                    LeaPlusCB["MiniAddonPanelScale"]:Hide()
                end
            end


            --------------------------------------------------------------------------------
            -- Some code for testing - adds buttons to minimap
            --------------------------------------------------------------------------------

            -- -- Load the libraries required for button creation.
            -- local LibDataBroker = LibStub:GetLibrary("LibDataBroker-1.1")
            -- local LibDBIcon = LibStub:GetLibrary("LibDBIcon-1.0")

            -- --===== Button 1 =====--

            -- -- Create the data broker objects for the custom buttons.
            -- local button1 = LibDataBroker:NewDataObject("Button1", {
            --     type = "launcher",
            --     icon = "Interface\\Icons\\inv_enchant_dustillusion",
            -- })

            -- -- Register the data broker objects with LibDBIcon to create minimap buttons.
            -- LibDBIcon:Register("Button1", button1, {
            --     icon = "Interface\\Icons\\inv_enchant_dustillusion",
            -- })


            -- --===== Button 2 =====--

            -- local button2 = LibDataBroker:NewDataObject("Button2", {
            --     type = "launcher",
            --     icon = "Interface\\Icons\\spell_holy_prayerofhealing02",
            -- })

            -- LibDBIcon:Register("Button2", button2, {
            --     icon = "Interface\\Icons\\spell_holy_prayerofhealing02",
            -- })


            -- --===== Button 3 =====--

            -- local button3 = LibDataBroker:NewDataObject("Button3", {
            --     type = "launcher",
            --     icon = "Interface\\Icons\\spell_nature_earthquake",
            -- })


            -- LibDBIcon:Register("Button3", button3, {
            --     icon = "Interface\\Icons\\spell_nature_earthquake",
            -- })



            -- --===== Button 4 =====--

            -- local button4 = LibDataBroker:NewDataObject("Button4", {
            --     type = "launcher",
            --     icon = "Interface\\Icons\\inv_misc_summerfest_braziergreen",
            -- })


            -- LibDBIcon:Register("Button4", button4, {
            --     icon = "Interface\\Icons\\inv_misc_summerfest_braziergreen",
            -- })



            -- --===== Button 5 =====--

            -- local button5 = LibDataBroker:NewDataObject("Button5", {
            --     type = "launcher",
            --     icon = "Interface\\Icons\\inv_misc_toy_02",
            -- })


            -- LibDBIcon:Register("Button5", button5, {
            --     icon = "Interface\\Icons\\inv_misc_toy_02",
            -- })



            -- --===== Button 6 =====--

            -- local button6 = LibDataBroker:NewDataObject("Button6", {
            --     type = "launcher",
            --     icon = "Interface\\Icons\\inv_misc_toy_02",
            -- })


            -- LibDBIcon:Register("Button6", button6, {
            --     icon = "Interface\\Icons\\inv_misc_toy_02",
            -- })

            --------------------------------------------------------------------------------
            -- End of Testing Buttons
            --------------------------------------------------------------------------------



            -- -- Create button frame (parenting to cluster ensures bFrame scales correctly)
            -- local bFrame = CreateFrame("FRAME", nil, MinimapCluster)
            -- bFrame:ClearAllPoints()
            -- bFrame:SetPoint("TOPLEFT", Minimap, "TOPRIGHT", 4, 4)
            -- bFrame:Hide()
            -- bFrame:SetFrameLevel(8)

            -- LeaPlusLC.bFrame = bFrame -- Used in LibDBIcon callback
            -- _G["LeaPlusGlobalMinimapCombinedButtonFrame"] = bFrame -- For third party addons

            -- -- Hide button frame automatically
            -- local ButtonFrameTicker
            -- bFrame:HookScript("OnShow", function()
            -- 	if ButtonFrameTicker then ButtonFrameTicker:Cancel() end
            -- 	ButtonFrameTicker = LibCompat.NewTicker(2, function()
            -- 		if ItemRackMenuFrame and ItemRackMenuFrame:IsShown() and ItemRackMenuFrame:IsMouseOver() then return end
            -- 		if not bFrame:IsMouseOver() and not Minimap:IsMouseOver() then
            -- 			bFrame:Hide()
            -- 			if ButtonFrameTicker then ButtonFrameTicker:Cancel() end
            -- 		end
            -- 	end, 15)
            -- end)

            -- -- Match scale with minimap
            -- if LeaPlusLC["SquareMinimap"] == "On" then
            -- 	bFrame:SetScale(LeaPlusLC["MinimapScale"] * 0.75)
            -- else
            -- 	bFrame:SetScale(LeaPlusLC["MinimapScale"])
            -- end
            -- LeaPlusCB["MinimapScale"]:HookScript("OnValueChanged", function()
            -- 	if LeaPlusLC["SquareMinimap"] == "On" then
            -- 		bFrame:SetScale(LeaPlusLC["MinimapScale"] * 0.75)
            -- 	else
            -- 		bFrame:SetScale(LeaPlusLC["MinimapScale"])
            -- 	end
            -- end)

            -- -- Position LibDBIcon tooltips when shown
            -- LibDBIconTooltip:HookScript("OnShow", function()
            -- 	GameTooltip:Hide()
            -- 	LibDBIconTooltip:ClearAllPoints()
            -- 	if bFrame:GetPoint() == "BOTTOMLEFT" then
            -- 		LibDBIconTooltip:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -6)
            -- 	else
            -- 		LibDBIconTooltip:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -6)
            -- 	end
            -- end)

            -- -- Function to position GameTooltip below the minimap
            -- local function SetButtonTooltip()
            -- 	GameTooltip:ClearAllPoints()
            -- 	if bFrame:GetPoint() == "BOTTOMLEFT" then
            -- 		GameTooltip:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -6)
            -- 	else
            -- 		GameTooltip:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -6)
            -- 	end
            -- end

            -- LeaPlusLC.SetButtonTooltip = SetButtonTooltip -- Used in LibDBIcon callback



            -- -- Hide existing LibDBIcon icons
            -- local buttons = LibDBIconStub:GetButtonList()
            -- for i = 1, #buttons do
            -- 	local button = LibDBIconStub:GetMinimapButton(buttons[i])
            -- 	local buttonName = strlower(buttons[i])
            -- 	if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
            -- 		button:Hide()
            -- 		button:SetScript("OnShow", function() if not bFrame:IsShown() then button:Hide() end end)
            -- 		-- Create background texture
            -- 		local bFrameBg = button:CreateTexture(nil, "BACKGROUND")
            -- 		bFrameBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
            -- 		bFrameBg:SetPoint("CENTER")
            -- 		bFrameBg:SetSize(30, 30)
            -- 		bFrameBg:SetVertexColor(0, 0, 0, 0.5)
            -- 	elseif strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) and LeaPlusLC["SquareMinimap"] == "On" then
            -- 		button:SetScale(0.75)
            -- 	end
            -- 	-- Move GameTooltip to below the minimap in case the button uses it
            -- 	button:HookScript("OnEnter", SetButtonTooltip)
            -- end

            -- Hide new LibDBIcon icons
            -- LibDBIcon_IconCreated: Done in LibDBIcon callback function

            -- -- Toggle button frame
            -- Minimap:SetScript("OnMouseUp", function(frame, button)
            -- 	if button == "RightButton" then
            -- 		if bFrame:IsShown() then
            -- 			bFrame:Hide()
            -- 		else bFrame:Show()
            -- 			-- Position button frame
            -- 			local side
            -- 			local m = Minimap:GetCenter()
            -- 			local b = Minimap:GetEffectiveScale()
            -- 			local w = GetScreenWidth()
            -- 			local s = UIParent:GetEffectiveScale()
            -- 			bFrame:ClearAllPoints()
            -- 			if m * b > (w * s / 2) then
            -- 				side = "Right"
            -- 				bFrame:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMLEFT", -10, -0)
            -- 			else
            -- 				side = "Left"
            -- 				bFrame:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMRIGHT", 10, 0)
            -- 			end
            -- 			-- Show button frame
            -- 			local x, y, row, col = 0, 0, 0, 0
            -- 			local buttons = LibDBIconStub:GetButtonList()
            -- 			-- Calculate buttons per row
            -- 			local buttonsPerRow
            -- 			local totalButtons = #buttons
            -- 				if totalButtons > 36 then buttonsPerRow = 10
            -- 			elseif totalButtons > 32 then buttonsPerRow = 9
            -- 			elseif totalButtons > 28 then buttonsPerRow = 8
            -- 			elseif totalButtons > 24 then buttonsPerRow = 7
            -- 			elseif totalButtons > 20 then buttonsPerRow = 6
            -- 			elseif totalButtons > 16 then buttonsPerRow = 5
            -- 			elseif totalButtons > 12 then buttonsPerRow = 4
            -- 			elseif totalButtons > 8 then buttonsPerRow = 3
            -- 			elseif totalButtons > 4 then buttonsPerRow = 2
            -- 			else
            -- 				buttonsPerRow = 1
            -- 			end
            -- 			-- Build button grid
            -- 			for i = 1, totalButtons do
            -- 				local buttonName = strlower(buttons[i])
            -- 				if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
            -- 					local button = LibDBIconStub:GetMinimapButton(buttons[i])
            -- 					if button.db then
            -- 						if buttonName == "armory" then button.db.hide = false end -- Armory addon sets hidden to true
            -- 						if not button.db.hide then
            -- 							button:SetParent(bFrame)
            -- 							button:ClearAllPoints()
            -- 							if side == "Left" then
            -- 								-- Minimap is on left side of screen
            -- 								button:SetPoint("TOPLEFT", bFrame, "TOPLEFT", x, y)
            -- 								col = col + 1; if col >= buttonsPerRow then col = 0; row = row + 1; x = 0; y = y - 30 else x = x + 30 end
            -- 							else
            -- 								-- Minimap is on right side of screen
            -- 								button:SetPoint("TOPRIGHT", bFrame, "TOPRIGHT", x, y)
            -- 								col = col + 1; if col >= buttonsPerRow then col = 0; row = row + 1; x = 0; y = y - 30 else x = x - 30 end
            -- 							end
            -- 							if totalButtons <= buttonsPerRow then
            -- 								bFrame:SetWidth(totalButtons * 30)
            -- 							else
            -- 								bFrame:SetWidth(buttonsPerRow * 30)
            -- 							end
            -- 							local void, void, void, void, e = button:GetPoint()
            -- 							bFrame:SetHeight(0 - e + 30)
            -- 							LibDBIconStub:Show(buttons[i])
            -- 						end
            -- 					end
            -- 				end
            -- 			end
            -- 		end
            -- 	else
            -- 		Minimap_OnClick(frame, button)
            -- 	end
            -- end)

        end




        ----------------------------------------------------------------------
        -- Square minimap
        ----------------------------------------------------------------------

        if LeaPlusLC["SquareMinimap"] == "On" then

            -- Set minimap shape
            _G.GetMinimapShape = function()
                return "SQUARE"
            end

            -- Create black border around map
            local miniBorder = CreateFrame("Frame", nil, Minimap)
            miniBorder:SetPoint("TOPLEFT", -1, 1)
            miniBorder:SetPoint("BOTTOMRIGHT", 1, -1)
            miniBorder:SetAlpha(0.8)
            miniBorder:SetBackdrop({
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
                edgeSize = 3,
            })

            -- Hide the default border
            MinimapBorder:Hide()

            -- Mask texture
            Minimap:SetMaskTexture('Interface\\ChatFrame\\ChatFrameBackground')

            -- Hide the North tag
            hooksecurefunc(MinimapNorthTag, "Show", function()
                MinimapNorthTag:Hide()
            end)

            -- Tracking button
            MiniMapTracking:SetScale(0.75)
            miniFrame.ClearAllPoints(MiniMapTracking)
            MiniMapTracking:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -20, -40)

            -- -- Mail button
            -- MiniMapMailFrame:SetScale(0.75)
            -- miniFrame.ClearAllPoints(MiniMapMailFrame)
            -- MiniMapMailFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -19, -75)

            -- Battleground queue button
            MiniMapBattlefieldFrame:SetScale(0.75)
            miniFrame.ClearAllPoints(MiniMapBattlefieldFrame)
            MiniMapBattlefieldFrame:SetPoint("TOP", MiniMapMailFrame, "BOTTOM", 0, 0)

            -- Looking For Group button
            MiniMapLFGFrame:SetScale(0.75)
            MiniMapLFGFrame:ClearAllPoints()
            MiniMapLFGFrame:SetPoint("TOP", MiniMapBattlefieldFrame, "BOTTOM", 0, 0)

            -- World map button
            MiniMapWorldMapButton:SetScale(0.75)
            MiniMapWorldMapButton:ClearAllPoints()
            MiniMapWorldMapButton:SetPoint("BOTTOM", MinimapZoomIn, "TOP", 0, 0)

            -- Zoom in button
            MinimapZoomIn:SetScale(0.75)
            miniFrame.ClearAllPoints(MinimapZoomIn)
            MinimapZoomIn:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 19, -120)

            -- Zoom out button
            MinimapZoomOut:SetScale(0.75)
            miniFrame.ClearAllPoints(MinimapZoomOut)
            MinimapZoomOut:SetPoint("TOP", MinimapZoomIn, "BOTTOM", 0, 0)


            --------------------------------------------------------------------------------
            -- Style the Minimap Mail Button
            --------------------------------------------------------------------------------


            miniFrame.ClearAllPoints(MiniMapMailFrame)
            -- Hide Circle around mail button
            MiniMapMailFrame:DisableDrawLayer("OVERLAY")
            -- Get the texture of MiniMapMailFrame
            local mailIcon = MiniMapMailFrame:GetRegions()
            mailIcon:SetTexture("Interface\\Minimap\\TRACKING\\Mailbox")
            -- Set the scale of the icon
            MiniMapMailFrame:SetScale(1.2)
            -- MiniMapMailFrame:SetFrameLevel(2)
            -- Move the icon to the top right of the minimap
            MiniMapMailFrame:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", 19, 14)
            MiniMapMailFrame:SetHitRectInsets(10, 10, 5, 8)
            -- Flag to track if mail icon is hidden
            local isHidden = false

            -- Function to toggle mail icon visibility
            local function toggleMailIcon()
                if isHidden then
                    mailIcon:Show()
                    isHidden = false
                else
                    mailIcon:Hide()
                    GameTooltip:Hide() -- re-show the tooltip to update its size
                    isHidden = true
                    -- UIErrorsFrame:AddMessage("Mail button is hidden. Right click again to show.", 0.1, 1.0, 0.1, 1.0, 3)
                end
            end

            -- Make the mail icon hide/show on right-click
            MiniMapMailFrame:SetScript("OnMouseUp", function(self, button)
                if button == "RightButton" then
                    toggleMailIcon()
                end
            end)


            -- Add new tooltip to the mail button
            local originalMailFrame_OnEnter = MiniMapMailFrame:GetScript("OnEnter")

            local function modifiedMailFrame_OnEnter(self)
                originalMailFrame_OnEnter(self)

                GameTooltip:AddLine("  ", 1, 1, 1, true)
                GameTooltip:AddLine("|cffeda55fRight-Click|r |cff99ff00to toggle minimap button.|r")

                GameTooltip:SetMinimumWidth(200) -- set the minimum width of the tooltip
                GameTooltip:Show() -- re-show the tooltip to update its size
            end

            MiniMapMailFrame:SetScript("OnEnter", modifiedMailFrame_OnEnter)

            --------------------------------------------------------------------------------
            -- Style the Calendar Mail Button
            --------------------------------------------------------------------------------


            miniFrame.ClearAllPoints(GameTimeFrame)
            -- Set the scale of the icon
            GameTimeFrame:SetScale(0.8)
            -- Move the icon to the top right of the minimap
            GameTimeFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 19, 14)

            --------------------------------------------------------------------------------
            --------------------------------------------------------------------------------


            -- Calendar button
            -- miniFrame.ClearAllPoints(GameTimeFrame)
            -- GameTimeFrame:SetPoint("BOTTOM", Minimap, "TOP", 0, 2)
            -- GameTimeFrame:SetParent(MinimapBackdrop)
            -- GameTimeFrame:SetScale(0.75)
            -- GameTimeFrame:SetSize(32, 32)

            -- Debug buttons
            local LeaPlusMiniMapDebug = nil
            if LeaPlusMiniMapDebug then
                LibCompat.After(2, function()
                    MiniMapMailFrame:Show()
                    MiniMapBattlefieldFrame:Show()
                    MiniMapWorldMapButton:Show()
                    -- GameTimeFrame:Show()
                    MiniMapLFGFrame:Show()
                end)
            end

            -- Rescale addon buttons if combine addon buttons is disabled
            if LeaPlusLC["CombineAddonButtons"] == "Off" then
                -- -- Scale existing buttons
                -- local buttons = LibDBIconStub:GetButtonList()
                -- for i = 1, #buttons do
                -- 	local button = LibDBIconStub:GetMinimapButton(buttons[i])
                -- 	button:SetScale(0.75)
                -- end
                -- -- Scale new buttons
                -- -- LibDBIcon_IconCreated: Done in LiBDBIcon callback function
            end

            -- Refresh buttons
            LibCompat.After(0.1, SetButtonRad)

            --------------------------------------------------------------------------------
            ---- Create the configuration panel for Square Minimap
            --------------------------------------------------------------------------------

            local SquareMapPanel = LeaPlusLC:CreatePanel("Square Minimap", "SquareMapPanel")

            -- Add a dropdown menu for mail icon position
            LeaPlusLC:CreateDropDown("MiniMapMailIconPos", "Mail Icon Position", SquareMapPanel, 146, "TOPLEFT", 16, -112, {L["Top Left"], L["Top Right"], L["Bottom Left"], L["Bottom Right"]}, "Set the position of the minimap mail icon.")

            -- Function to update mail icon position based on the dropdown selection
            local function UpdateMailIconPosition()
                local mailIcon = MiniMapMailFrame
                if mailIcon then
                    mailIcon:ClearAllPoints()
                    if LeaPlusLC["MiniMapMailIconPos"] == 1 then -- Top Left
                        mailIcon:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -19, 14)
                    elseif LeaPlusLC["MiniMapMailIconPos"] == 2 then -- Top Right
                        mailIcon:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 19, 14)
                    elseif LeaPlusLC["MiniMapMailIconPos"] == 3 then -- Bottom Left
                        mailIcon:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -19, -14)
                    elseif LeaPlusLC["MiniMapMailIconPos"] == 4 then -- Bottom Right
                        mailIcon:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 19, -14)
                    end
                end
            end

            -- Call UpdateMailIconPosition when the dropdown value changes
            LeaPlusCB["ListFrameMiniMapMailIconPos"]:HookScript("OnHide", function()
                UpdateMailIconPosition()
            end)

            -- Call UpdateMailIconPosition on startup to set the initial position
            UpdateMailIconPosition()

            -- Add a dropdown menu for LFG button position with no "Default" position, only custom ones
            LeaPlusLC:CreateDropDown("MiniMapLFGIconPos", "LFG Icon Position", SquareMapPanel, 146, "TOPLEFT", 16, -172,
                    {L["Top Left"], L["Top Right"], L["Bottom Left"], L["Bottom Right"]}, "Set the position of the minimap LFG icon.")

            -- Function to update LFG button position based on the dropdown selection
            local function UpdateLFGIconPosition()
                local lfgIcon = MiniMapLFGFrame
                if lfgIcon then
                    lfgIcon:ClearAllPoints()

                    -- Apply custom positions inside the minimap with a slight outset from the edges
                    if LeaPlusLC["MiniMapLFGIconPos"] == 1 then -- Top Left
                        lfgIcon:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 5, -5)  -- Slightly inset
                    elseif LeaPlusLC["MiniMapLFGIconPos"] == 2 then -- Top Right
                        lfgIcon:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -5, -5)  -- Slightly inset
                    elseif LeaPlusLC["MiniMapLFGIconPos"] == 3 then -- Bottom Left
                        lfgIcon:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 5, 5)  -- Slightly inset
                    elseif LeaPlusLC["MiniMapLFGIconPos"] == 4 then -- Bottom Right
                        lfgIcon:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -5, 25)  -- Slightly inset
                    end
                end
            end

            -- Call UpdateLFGIconPosition when the dropdown value changes
            LeaPlusCB["ListFrameMiniMapLFGIconPos"]:HookScript("OnHide", function()
                UpdateLFGIconPosition()
            end)

            -- Call UpdateLFGIconPosition on startup to set the initial position
            UpdateLFGIconPosition()


            -- Add a dropdown menu for Battlefield icon position
            LeaPlusLC:CreateDropDown("MiniMapBattlefieldIconPos", "Battlefield Icon Position", SquareMapPanel, 146, "TOPLEFT", 16, -232, {L["Top Left"], L["Top Right"], L["Bottom Left"], L["Bottom Right"]}, "Set the position of the minimap battlefield icon.")

            -- Function to update Battlefield icon position based on the dropdown selection
            local function UpdateBattlefieldIconPosition()
                local battlefieldIcon = MiniMapBattlefieldFrame
                if battlefieldIcon then
                    battlefieldIcon:ClearAllPoints()

                    -- Apply custom positions inside the minimap with a slight outset from the edges
                    if LeaPlusLC["MiniMapBattlefieldIconPos"] == 1 then -- Top Left
                        battlefieldIcon:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 5, -5)  -- Slightly inset
                    elseif LeaPlusLC["MiniMapBattlefieldIconPos"] == 2 then -- Top Right
                        battlefieldIcon:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -5, -5)  -- Slightly inset
                    elseif LeaPlusLC["MiniMapBattlefieldIconPos"] == 3 then -- Bottom Left
                        battlefieldIcon:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 5, 5)  -- Slightly inset
                    elseif LeaPlusLC["MiniMapBattlefieldIconPos"] == 4 then -- Bottom Right
                        battlefieldIcon:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -5, 25)  -- Slightly inset
                    end
                end
            end

            -- Call UpdateBattlefieldIconPosition when the dropdown value changes
            LeaPlusCB["ListFrameMiniMapBattlefieldIconPos"]:HookScript("OnHide", function()
                UpdateBattlefieldIconPosition()
            end)

            -- Call UpdateBattlefieldIconPosition on startup to set the initial position
            UpdateBattlefieldIconPosition()


            -- Help button hidden (or you can add specific help for this panel)
            SquareMapPanel.h:Hide()

            -- Back button handler
            SquareMapPanel.b:SetScript("OnClick", function()
                SquareMapPanel:Hide()
                LeaPlusGlobalPanel_SideMinimap:Show()
                return
            end)

            -- Reset button handler
            SquareMapPanel.r:SetScript("OnClick", function()
                -- Reset your Square Minimap settings to default values here
                LeaPlusLC["MiniMapMailIconPos"] = 1
                LeaPlusLC["MiniMapLFGIconPos"] = 3
                LeaPlusLC["MiniMapBattlefieldIconPos"] = 1

                -- Refresh dropdowns
                LeaPlusCB["ListFrameMiniMapMailIconPos"]:Hide()
                UpdateMailIconPosition()
                LeaPlusCB["ListFrameMiniMapLFGIconPos"]:Hide()
                UpdateLFGIconPosition()
                LeaPlusCB["ListFrameMiniMapBattlefieldIconPos"]:Hide()
                UpdateBattlefieldIconPosition()

                -- Refresh the configuration panel
                SquareMapPanel:Hide()
                SquareMapPanel:Show()
            end)

            -- Set the OnClick script for the configuration button
            LeaPlusCB["ModSquareMapBtn"]:SetScript("OnClick", function()
                if IsShiftKeyDown() and IsControlKeyDown() then
                    -- Preset profile (if you have any presets for this panel)
                    LeaPlusLC["MiniMapMailIconPos"] = 1
                else
                    SquareMapPanel:Show()
                    LeaPlusGlobalPanel_SideMinimap:Hide()
                end
            end)

        else

            -- Square minimap is disabled so use round shape
            _G.GetMinimapShape = function()
                return "ROUND"
            end
            Minimap:SetMaskTexture([[Interface\CharacterFrame\TempPortraitAlphaMask]])

            -- -- Calendar button
            -- miniFrame.ClearAllPoints(GameTimeFrame)
            -- GameTimeFrame:SetPoint("TOPRIGHT", MinimapBackdrop, "TOPRIGHT", -11, 4)
            -- GameTimeFrame:SetParent(MinimapBackdrop)

            -- -- World map button
            -- miniFrame.ClearAllPoints(MiniMapWorldMapButton)
            -- -- LibDBIconStub:SetButtonToPosition(MiniMapWorldMapButton, 20)
            -- MiniMapWorldMapButton:SetPoint("TOPRIGHT", MinimapBackdrop, "TOPRIGHT", -21, -1)

        end

        ----------------------------------------------------------------------
        -- Replace non-standard buttons
        ----------------------------------------------------------------------

        -- Replace non-standard buttons for addons that don't use the standard LibDBIcon library
        -- do

        -- 	-- Make custom LibDBIcon buttons for addons that don't use LibDBIcon
        -- 	local CustomAddonTable = {}
        -- 	LeaPlusDB["CustomAddonButtons"] = LeaPlusDB["CustomAddonButtons"] or {}

        -- 	-- Function to create a LibDBIcon button
        -- 	local function CreateBadButton(name)

        -- 		-- Get non-standard button texture
        -- 		local finalTex = "Interface\\HELPFRAME\\HelpIcon-KnowledgeBase"

        -- 		if _G[name .. "Icon"] then
        -- 			if _G[name .. "Icon"]:GetObjectType() == "Texture" then
        -- 				local gTex = _G[name .. "Icon"]:GetTexture()
        -- 				if gTex then
        -- 					finalTex = gTex
        -- 				end
        -- 			end
        -- 		else
        -- 			for i = 1, select('#', _G[name]:GetRegions()) do
        -- 				local region = select(i, _G[name]:GetRegions())
        -- 				if region.GetTexture then
        -- 					local x, y = region:GetSize()
        -- 					if x and x < 30 then
        -- 						finalTex = region:GetTexture()
        -- 					end
        -- 				end
        -- 			end
        -- 		end

        -- 		if not finalTex then finalTex = "Interface\\HELPFRAME\\HelpIcon-KnowledgeBase" end

        -- 		local zeroButton = LibStub("LibDataBroker-1.1"):NewDataObject("LeaPlusCustomIcon_" .. name, {
        -- 			type = "data source",
        -- 			text = name,
        -- 			icon = finalTex,
        -- 			OnClick = function(self, btn)
        -- 				if _G[name] then
        -- 					if string.find(name, "LibDBIcon") then
        -- 						-- It's a fake LibDBIcon
        -- 						local mouseUp = _G[name]:GetScript("OnMouseUp")
        -- 						if mouseUp then
        -- 							mouseUp(self, btn)
        -- 						end
        -- 					else
        -- 						-- It's a genuine LibDBIcon
        -- 						local clickUp = _G[name]:GetScript("OnClick")
        -- 						if clickUp then
        -- 							_G[name]:Click(btn)
        -- 						end
        -- 					end
        -- 				end
        -- 			end,
        -- 			OnTooltipShow = function(tooltip)
        -- 				if not tooltip or not tooltip.AddLine then return end
        -- 				tooltip:AddLine(name)
        -- 				tooltip:AddLine(L["This is a custom button."], 1, 1, 1)
        -- 				tooltip:AddLine(L["Please ask the addon author to use LibDBIcon."], 1, 1, 1)
        -- 				tooltip:AddLine(L["There is a helpful guide on leatrix.com."], 1, 1, 1)
        -- 			end,
        -- 		})
        -- 		LeaPlusDB["CustomAddonButtons"][name] = LeaPlusDB["CustomAddonButtons"][name] or {}
        -- 		LeaPlusDB["CustomAddonButtons"][name].hide = false
        -- 		CustomAddonTable[name] = name
        -- 		local icon = LibStub("LibDBIcon-1.0", true)
        -- 		icon:Register("LeaPlusCustomIcon_" .. name, zeroButton, LeaPlusDB["CustomAddonButtons"][name])

        -- 	end

        -- 	-- Function to loop through minimap children to find custom addon buttons
        -- 	local function MakeButtons()
        -- 		local temp = {Minimap:GetChildren()}
        -- 		for i = 1, #temp do
        -- 			if temp[i] then
        -- 				local btn = temp[i]
        -- 				local name = btn:GetName()
        -- 				local btype = btn:GetObjectType()
        -- 				if name and btype == "Button" and not CustomAddonTable[name] and btn:GetNumRegions() >= 3 and not issecurevariable(name) and btn:IsShown() then
        -- 					if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), strlower("##" .. name)) then
        -- 						if not string.find(name, "LibDBIcon") or name == "LibDBIcon10_MethodRaidTools" then
        -- 							CreateBadButton(name)
        -- 							btn:Hide()
        -- 							btn:SetScript("OnShow", function() btn:Hide() end)
        -- 						end
        -- 					end
        -- 				end
        -- 			end
        -- 		end
        -- 	end

        -- 	-- Run the function a few times on startup
        -- 	LibCompat.NewTicker(2, MakeButtons, 3)
        -- 	LibCompat.After(0.1, MakeButtons)

        -- end

        ----------------------------------------------------------------------
        -- Hide addon buttons
        ----------------------------------------------------------------------

        if LeaPlusLC["CombineAddonButtons"] == "Off" then

            -- Function to set button state
            local function SetHideButtons()
                if LeaPlusLC["HideMiniAddonButtons"] == "On" then


                    -- First, we create an empty table to hold all of our minimap buttons.
                    local minimapButtons = {}

                    -- This function will capture all children attached to the minimap, and add them to our table.
                    local function GetMinimapChildren()
                        -- First, we clear our table to ensure there are no duplicates.
                        wipe(minimapButtons)

                        -- Next, we get the total number of children attached to the minimap frame.
                        local numChildren = Minimap:GetNumChildren()

                        -- Now, we loop through each child and check if it's a minimap button.
                        for i = 1, numChildren do
                            local child = select(i, Minimap:GetChildren())
                            if child and child:IsObjectType("Button") and child:GetName() then
                                -- If the child is a minimap button, we add it to our table.
                                minimapButtons[child:GetName()] = child
                            end
                        end
                    end
                    -- Set hover scripts for all buttons
                    local function SetupButtonHoverScripts()
                        for _, button in pairs(minimapButtons) do
                            if button then
                                button:HookScript("OnEnter", function()
                                    -- Show all buttons when hovering over one
                                    for _, btn in pairs(minimapButtons) do
                                        btn:SetAlpha(1)
                                    end
                                end)
                                button:HookScript("OnLeave", function()
                                    -- Hide buttons if mouse is not over minimap or any button
                                    if not Minimap:IsMouseOver() then
                                        local mouseOverAny = false
                                        for _, btn in pairs(minimapButtons) do
                                            if btn:IsMouseOver() then
                                                mouseOverAny = true
                                                break
                                            end
                                        end
                                        if not mouseOverAny then
                                            for _, btn in pairs(minimapButtons) do
                                                btn:SetAlpha(0)
                                            end
                                        end
                                    end
                                end)
                            end
                        end
                    end



                    local function HideMinimapButtons()
                        local searchStr = LeaPlusDB["MiniExcludeList"]
                        -- Thanks to https://github.com/s0h2x/pretty_minimap for good list of buttons to ignore!
                        local keepVisible = {
                            "ZGV",
                            "Spy",
                            "MiniMapBattlefieldFrame",
                            "GatherMatePin",
                            "HandyNotesPin",
                            "Archy",
                            "GatherNote",
                            "poiWorldMapPOIFrame",
                            "WorldMapPOIFrame",
                            "QuestMapPOI",
                            "pfMiniMapPin",
                            -- Add TimeManagerClockButton based on ClockMouseover option
                            LeaPlusLC["ClockMouseover"] == "Off" and "TimeManagerClockButton" or nil
                        }

                        -- Remove nil values from the keepVisible table
                        for i = #keepVisible, 1, -1 do
                            if not keepVisible[i] then
                                table.remove(keepVisible, i)
                            end
                        end

                        if searchStr == "" then
                            -- Set alpha of all buttons to 0 if MiniExcludeList is empty
                            for _, button in pairs(minimapButtons) do
                                local match = false
                                for _, visible in ipairs(keepVisible) do
                                    if string.find(button:GetName(), visible) then
                                        match = true
                                        break
                                    end
                                end
                                if not match then
                                    button:SetAlpha(0)
                                end
                            end
                        else
                            -- Set alpha of buttons that match MiniExcludeList to 0
                            local excludedNames = { strsplit(",", searchStr) } -- Split MiniExcludeList by comma
                            for name, button in pairs(minimapButtons) do
                                local match = false
                                for _, visible in ipairs(keepVisible) do
                                    if string.find(button:GetName(), visible) then
                                        match = true
                                        break
                                    end
                                end
                                if not match then
                                    -- Check if button name doesn't contain any substring in 'keepVisible'
                                    for _, excludedName in ipairs(excludedNames) do
                                        if string.find(name, strtrim(excludedName)) ~= nil then
                                            match = true
                                            break
                                        end
                                    end
                                    if not match then
                                        button:SetAlpha(0)
                                    end
                                end
                            end
                        end
                    end


                    -- This function shows the minimap buttons by setting their alpha to 1.
                    local function ShowMinimapButtons()
                        for name, button in pairs(minimapButtons) do
                            button:SetAlpha(1)
                        end
                    end




                    -- This function is called when the mouse enters the minimap area.
                    local function Minimap_OnEnter()
                        -- If the mouse is over a child, we show all minimap buttons.
                        Minimap:HookScript("OnUpdate", function(self, elapsed)
                            local numChildren = Minimap:GetNumChildren()
                            local mouseOverChild = false
                            local mouseOverMinimap = Minimap:IsMouseOver() -- Check if the mouse is over the minimap
                            for i = 1, numChildren do
                                local child = select(i, Minimap:GetChildren())
                                if child and child:IsObjectType("Button") then
                                    local x, y = child:GetCenter()
                                    if x and y then
                                        -- Check if x and y are not nil
                                        x, y = x * child:GetEffectiveScale(), y * child:GetEffectiveScale()
                                        local cx, cy = GetCursorPosition()
                                        local dist = sqrt((x - cx) ^ 2 + (y - cy) ^ 2) / 3 -- Triple the distance of buttons OnEnter alpha trigger

                                        if dist < child:GetWidth() / 2 then
                                            mouseOverChild = true
                                            break
                                        end
                                    end
                                end
                            end

                            -- If the mouse is over either the minimap or a child, show the buttons
                            if mouseOverMinimap or mouseOverChild then
                                ShowMinimapButtons()
                            else
                                HideMinimapButtons()
                            end
                        end)
                    end



                    -- This function is called when the mouse leaves the minimap area.
                    local function Minimap_OnLeave()
                        HideMinimapButtons()
                    end

                    -- Finally, we create a timer that will capture new minimap children every 0.5 seconds.
                    LibCompat.NewTicker(1, function()
                        GetMinimapChildren()
                        SetupButtonHoverScripts() -- Apply hover scripts to each button
                    end)

                    -- We set up the minimap to respond to mouse events.
                    Minimap:SetScript("OnEnter", Minimap_OnEnter)
                    Minimap:SetScript("OnLeave", Minimap_OnLeave)

                    local ticks = 0 -- keep track of how many times the function has been called
                    local ticker = nil -- keep track of the timer object

                    local function OnLoginHide(eventName, ...)
                        ticker = LibCompat.NewTicker(0.3, function()
                            ticks = ticks + 1 -- increment the tick counter
                            -- print("tick #".. ticks)
                            HideMinimapButtons()
                            if ticks >= 4 then
                                -- stop after 6 seconds have passed (20 ticks * 0.3 seconds per tick)
                                LibCompat.CancelTimer(ticker) -- stop the timer
                            end
                        end)
                    end


                    -- Register the OnLoginHide function to fire when the "PLAYER_ENTERING_WORLD" event occurs.
                    local eventFrame = CreateFrame("FRAME")
                    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

                    -- eventFrame:RegisterEvent("PLAYER_LOGIN")
                    eventFrame:SetScript("OnEvent", OnLoginHide)


                end

            end

            -- Assign file level scope (it's used in reset and preset)
            LeaPlusLC.SetHideButtons = SetHideButtons

            -- Set buttons when option is clicked and on startup
            LeaPlusCB["HideMiniAddonButtons"]:HookScript("OnClick", SetHideButtons)
            SetHideButtons()

        end

        ----------------------------------------------------------------------
        -- Hide the world map button
        ----------------------------------------------------------------------

        -- Function to set world map button
        local function SetWorldMapButton()
            if LeaPlusLC["HideMiniMapButton"] == "On" then
                MiniMapWorldMapButton:Hide()
            else
                MiniMapWorldMapButton:Show()
            end
        end

        -- Set map button when option is clicked and on startup
        LeaPlusCB["HideMiniMapButton"]:HookScript("OnClick", SetWorldMapButton)
        SetWorldMapButton()

        -- Hide world map button when it's shown
        hooksecurefunc(MiniMapWorldMapButton, "Show", function()
            if LeaPlusLC["HideMiniMapButton"] == "On" then
                MiniMapWorldMapButton:Hide()
            end
        end)

        ----------------------------------------------------------------------
        -- Unlock the minimap
        ----------------------------------------------------------------------

        -- Raise the frame in case it's hidden
        Minimap:Raise()

        -- Enable minimap movement
        Minimap:SetMovable(true)
        Minimap:SetUserPlaced(true)
        Minimap:SetDontSavePosition(true)
        Minimap:SetClampedToScreen(true)
        if LeaPlusLC["SquareMinimap"] == "On" then
            Minimap:SetClampRectInsets(-3, 3, 3, -3)
        else
            Minimap:SetClampRectInsets(-2, 0, 2, -2)
        end
        MinimapBackdrop:ClearAllPoints()
        MinimapBackdrop:SetPoint("TOP", Minimap, "TOP", -9, 2)
        Minimap:RegisterForDrag("LeftButton")

        -- Set minimap position on startup
        Minimap:ClearAllPoints()
        Minimap:SetPoint(LeaPlusLC["MinimapA"], UIParent, LeaPlusLC["MinimapR"], LeaPlusLC["MinimapX"], LeaPlusLC["MinimapY"])

        -- Drag functions
        Minimap:SetScript("OnDragStart", function(self, btn)
            -- Start dragging if left clicked
            if IsAltKeyDown() and btn == "LeftButton" then
                Minimap:StartMoving()
            end
        end)

        Minimap:SetScript("OnDragStop", function(self, btn)
            -- Save minimap position
            Minimap:StopMovingOrSizing()
            LeaPlusLC["MinimapA"], void, LeaPlusLC["MinimapR"], LeaPlusLC["MinimapX"], LeaPlusLC["MinimapY"] = Minimap:GetPoint()
            Minimap:SetMovable(true)
            Minimap:ClearAllPoints()
            Minimap:SetPoint(LeaPlusLC["MinimapA"], UIParent, LeaPlusLC["MinimapR"], LeaPlusLC["MinimapX"], LeaPlusLC["MinimapY"])
        end)

        ----------------------------------------------------------------------
        -- Hide the zone text bar, time of day button and toggle button
        ----------------------------------------------------------------------

        -- Reparent MinimapCluster elements
        MinimapBorderTop:SetParent(Minimap)
        MinimapZoneTextButton:SetParent(MinimapBackdrop)

        -- Instance difficulty
        miniFrame.SetParent(MiniMapInstanceDifficulty, Minimap)
        miniFrame.ClearAllPoints(MiniMapInstanceDifficulty)
        if LeaPlusLC["SquareMinimap"] == "On" then
            MiniMapInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -21, 10)
            MiniMapInstanceDifficulty:SetScale(0.75)
        else
            MiniMapInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -13, 5)
        end
        MiniMapInstanceDifficulty:SetFrameLevel(4)

        -- Anchor border top to MinimapBackdrop
        MinimapBorderTop:ClearAllPoints()
        MinimapBorderTop:SetPoint("TOP", MinimapBackdrop, "TOP", 0, 20)

        -- Refresh buttons
        LibCompat.After(0.1, SetButtonRad)

        -- Function to set zone text bar
        local function SetZoneTextBar()
            if LeaPlusLC["HideMiniZoneText"] == "On" then
                MinimapBorderTop:Hide()
                MinimapZoneTextButton:Hide()
            else
                MinimapZoneTextButton:ClearAllPoints()
                MinimapZoneTextButton:SetPoint("CENTER", MinimapBorderTop, "CENTER", -1, 3)
                MinimapBorderTop:Show()
                MinimapZoneTextButton:Show()
                if LeaPlusDB["SquareMinimap"] == "On" then
                    MinimapBorderTop:Hide()
                    MinimapZoneTextButton:ClearAllPoints()
                    MinimapZoneTextButton:SetPoint("TOP", Minimap, "TOP", 0, 0)
                    MinimapZoneTextButton:SetFrameLevel(100)
                end
                -- Reduce the click area by 30 pixels from left and right side
                MinimapZoneTextButton:SetHitRectInsets(30, 30, 0, 0)
            end
        end

        -- Set the zone text bar when option is clicked and on startup
        LeaPlusCB["HideMiniZoneText"]:HookScript("OnClick", SetZoneTextBar)
        SetZoneTextBar()

        ----------------------------------------------------------------------
        -- Hide the zoom buttons
        ----------------------------------------------------------------------

        -- Function to toggle the zoom buttons
        local function ToggleZoomButtons()
            if LeaPlusLC["HideMiniZoomBtns"] == "On" then
                MinimapZoomIn:Hide()
                MinimapZoomOut:Hide()
            else
                MinimapZoomIn:Show()
                MinimapZoomOut:Show()
            end
        end

        -- Set the zoom buttons when the option is clicked and on startup
        LeaPlusCB["HideMiniZoomBtns"]:HookScript("OnClick", ToggleZoomButtons)
        ToggleZoomButtons()

        ----------------------------------------------------------------------
        -- Style and position the clock
        ----------------------------------------------------------------------

        local function initialClockSetup()
            -- Set initial visibility based on ClockMouseover
            if LeaPlusLC["ClockMouseover"] == "On" then
                TimeManagerClockButton:SetAlpha(0) -- Hidden by default for mouseover
            else
                TimeManagerClockButton:SetAlpha(1) -- Visible by default
            end
        end

        -- Function to style and position the clock
        local function SetMiniClock(firstRun)
            if IsAddOnLoaded("Blizzard_TimeManager") then
                if LeaPlusLC["SquareMinimap"] == "On" and firstRun == true then
                    local regions = { TimeManagerClockButton:GetRegions() }
                    regions[1]:Hide()
                    TimeManagerClockButton:ClearAllPoints()
                    TimeManagerClockButton:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 10, -6)
                    TimeManagerClockButton:SetHitRectInsets(10, 10, 5, 8)
                    TimeManagerClockButton:SetFrameLevel(100)
                    local timeBG = TimeManagerClockButton:CreateTexture(nil, "BACKGROUND")
                    timeBG:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
                    timeBG:SetPoint("TOPLEFT", 8, -5)
                    timeBG:SetPoint("BOTTOMRIGHT", -10, 8)
                    timeBG:SetVertexColor(0, 0, 0, 0.6)
                    TimeManagerFrame:ClearAllPoints()
                    TimeManagerFrame:SetPoint("TOP", Minimap, "BOTTOM", 0, 0)
                else
                    TimeManagerFrame:ClearAllPoints()
                    TimeManagerFrame:SetPoint("TOP", Minimap, "BOTTOM", 0, 0)
                end

                initialClockSetup()
            end
        end

        -- Run function when Blizzard addon is loaded
        if IsAddOnLoaded("Blizzard_TimeManager") then
            SetMiniClock(true)
        else
            local waitFrame = CreateFrame("FRAME")
            waitFrame:RegisterEvent("ADDON_LOADED")
            waitFrame:SetScript("OnEvent", function(self, event, arg1)
                if arg1 == "Blizzard_TimeManager" then
                    SetMiniClock(true)
                    -- Ensure the clock remains visible when the mouse is over it
                    TimeManagerClockButton:HookScript("OnEnter", function()
                        if IsAddOnLoaded("Blizzard_TimeManager") then
                            if LeaPlusLC["ClockMouseover"] == "On" then
                                TimeManagerClockButton:SetAlpha(1)
                            end
                        end
                    end)

                    TimeManagerClockButton:HookScript("OnLeave", function()
                        if IsAddOnLoaded("Blizzard_TimeManager") then
                            if LeaPlusLC["ClockMouseover"] == "On" then
                                TimeManagerClockButton:SetAlpha(0)
                            end
                        end
                    end)
                    waitFrame:UnregisterAllEvents()
                end
            end)
        end

        -- Show clock on mouseover if ClockMouseover is enabled
        Minimap:HookScript("OnEnter", function()
            if IsAddOnLoaded("Blizzard_TimeManager") then
                if LeaPlusLC["ClockMouseover"] == "On" then
                    TimeManagerClockButton:SetAlpha(1)
                end
            end
        end)

        -- Hide clock on mouse leave if ClockMouseover is enabled
        Minimap:HookScript("OnLeave", function()
            if IsAddOnLoaded("Blizzard_TimeManager") then
                if LeaPlusLC["ClockMouseover"] == "On" then
                    TimeManagerClockButton:SetAlpha(0)
                end
            end
        end)

        LeaPlusCB["ClockMouseover"]:HookScript("OnClick", initialClockSetup)

        ----------------------------------------------------------------------
        -- Enable mousewheel zoom
        ----------------------------------------------------------------------

        -- Function to control mousewheel zoom
        local function MiniZoom(self, arg1)
            if arg1 > 0 and self:GetZoom() < 5 then
                -- Zoom in
                MinimapZoomOut:Enable()
                self:SetZoom(self:GetZoom() + 1)
                if (Minimap:GetZoom() == (Minimap:GetZoomLevels() - 1)) then
                    MinimapZoomIn:Disable()
                end
            elseif arg1 < 0 and self:GetZoom() > 0 then
                -- Zoom out
                MinimapZoomIn:Enable()
                self:SetZoom(self:GetZoom() - 1)
                if (Minimap:GetZoom() == 0) then
                    MinimapZoomOut:Disable()
                end
            end
        end

        -- Enable mousewheel zoom
        Minimap:EnableMouseWheel(true)
        Minimap:SetScript("OnMouseWheel", MiniZoom)

        ----------------------------------------------------------------------
        -- Minimap scale
        ----------------------------------------------------------------------

        -- Function to set the minimap scale and not minimap checkbox
        local function SetMiniScale()
            Minimap:SetScale(LeaPlusLC["MinimapScale"])
            -- Set slider formatted text
            LeaPlusCB["MinimapScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["MinimapScale"] * 100)
            -- Set Not minimap
            if LeaPlusLC["MinimapNoScale"] == "On" then
                --Minimap:SetIgnoreParentScale(true)
            else
                -- Minimap:SetIgnoreParentScale(false)
            end
        end

        -- Set minimap scale when slider is changed and on startup
        LeaPlusCB["MinimapScale"]:HookScript("OnValueChanged", SetMiniScale)
        LeaPlusCB["MinimapNoScale"]:HookScript("OnClick", SetMiniScale)
        SetMiniScale()

        ----------------------------------------------------------------------
        -- Buttons
        ----------------------------------------------------------------------

        -- Help button tooltip
        SideMinimap.h.tiptext = L["To move the minimap, hold down the alt key and drag it.|n|nIf you toggle an addon minimap button, you may need to reload your UI for the change to take effect.  This only affects a few addons that use custom buttons.|n|nThis panel will close automatically if you enter combat."]

        -- Back button handler
        SideMinimap.b:SetScript("OnClick", function()
            SideMinimap:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page5"]:Show()
            return
        end)

        -- Reset button handler
        SideMinimap.r.tiptext = SideMinimap.r.tiptext .. "|n|n" .. L["Note that this will not reset settings that require a UI reload."]
        SideMinimap.r:HookScript("OnClick", function()
            LeaPlusLC["HideMiniZoomBtns"] = "Off";
            ToggleZoomButtons()
            LeaPlusLC["HideMiniZoneText"] = "Off";
            SetZoneTextBar()
            LeaPlusLC["HideMiniAddonButtons"] = "On";
            if LeaPlusLC.SetHideButtons then
                LeaPlusLC.SetHideButtons()
            end
            LeaPlusLC["MinimapScale"] = 1
            LeaPlusLC["MinimapSize"] = 140;
            if LeaPlusLC.SetMinimapSize then
                LeaPlusLC:SetMinimapSize()
            end
            LeaPlusLC["MiniClusterScale"] = 1;
            LeaPlusLC["MinimapNoScale"] = "Off";
            SetClusterScale()
            Minimap:SetScale(1)
            SetMiniScale()

            LeaPlusLC["CombineAddonsFrameA"] = "BOTTOMRIGHT"
            LeaPlusLC["CombineAddonsFrameR"] = "BOTTOMLEFT"
            LeaPlusLC["CombineAddonsFrameX"] = -2
            LeaPlusLC["CombineAddonsFrameY"] = -1.2
            --LeaPlusLC["CombineAddonsFrameScale"] = 1

            LeaPlusLC["MiniAddonPanelScale"] = 1;
            if LeaPlusLC["CombineAddonButtons"] == "On" and LeaPlusLC['minimapFrameGlobal'] then
                LeaPlusLC:SetMinimapAddonButtonsFrameScale()

                LeaPlusLC['minimapFrameGlobal']:ClearAllPoints()
                LeaPlusLC['minimapFrameGlobal']:SetPoint(LeaPlusLC["CombineAddonsFrameA"], Minimap, LeaPlusLC["CombineAddonsFrameR"], LeaPlusLC["CombineAddonsFrameX"], LeaPlusLC["CombineAddonsFrameY"])
            end

            -- Reset map position
            LeaPlusLC["MinimapA"], LeaPlusLC["MinimapR"], LeaPlusLC["MinimapX"], LeaPlusLC["MinimapY"] = "TOPRIGHT", "TOPRIGHT", -17, -45
            Minimap:ClearAllPoints()
            Minimap:SetPoint(LeaPlusLC["MinimapA"], UIParent, LeaPlusLC["MinimapR"], LeaPlusLC["MinimapX"], LeaPlusLC["MinimapY"])
            -- Hide world map button
            LeaPlusLC["HideMiniMapButton"] = "On";
            SetWorldMapButton()
            -- Refresh panel
            SideMinimap:Hide();
            SideMinimap:Show()
        end)

        -- Configuration button handler
        LeaPlusCB["ModMinimapBtn"]:HookScript("OnClick", function()
            if LeaPlusLC:PlayerInCombat() then
                return
            else
                if IsShiftKeyDown() and IsControlKeyDown() then
                    -- Preset profile
                    LeaPlusLC["HideMiniZoomBtns"] = "Off";
                    ToggleZoomButtons()
                    LeaPlusLC["HideMiniZoneText"] = "On";
                    SetZoneTextBar()
                    LeaPlusLC["HideMiniAddonButtons"] = "On";
                    if LeaPlusLC.SetHideButtons then
                        LeaPlusLC.SetHideButtons()
                    end
                    LeaPlusLC["MinimapScale"] = 1.40
                    LeaPlusLC["MinimapSize"] = 180;
                    if LeaPlusLC.SetMinimapSize then
                        LeaPlusLC:SetMinimapSize()
                    end
                    LeaPlusLC["MiniClusterScale"] = 1;
                    LeaPlusLC["MinimapNoScale"] = "Off";
                    SetClusterScale()
                    Minimap:SetScale(1)
                    SetMiniScale()

                    LeaPlusLC["MiniAddonPanelScale"] = 1;
                    if LeaPlusLC["CombineAddonButtons"] == "On" and LeaPlusLC['minimapFrameGlobal'] then
                        LeaPlusLC:SetMinimapAddonButtonsFrameScale()
                    end

                    -- Hide world map button
                    LeaPlusLC["HideMiniMapButton"] = "On";
                    SetWorldMapButton()
                    -- Map position
                    LeaPlusLC["MinimapA"], LeaPlusLC["MinimapR"], LeaPlusLC["MinimapX"], LeaPlusLC["MinimapY"] = "TOPRIGHT", "TOPRIGHT", 0, 0
                    Minimap:SetMovable(true)
                    Minimap:ClearAllPoints()
                    Minimap:SetPoint(LeaPlusLC["MinimapA"], UIParent, LeaPlusLC["MinimapR"], LeaPlusLC["MinimapX"], LeaPlusLC["MinimapY"])
                    LeaPlusLC:ReloadCheck() -- Special reload check
                else
                    -- Show configuration panel
                    SideMinimap:Show()
                    LeaPlusLC:HideFrames()
                end
            end
        end)

        -- Hide tracking button
        if LeaPlusLC["HideMiniTracking"] == "On" then

            MiniMapTracking:Hide()

            Minimap:SetScript("OnMouseUp", function(self, button)

                if button == "RightButton" then
                    MiniMapTrackingDropDown:SetScript("OnShow", function(self)
                        local x, y = GetCursorPosition()
                        self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
                    end)
                    ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, "cursor", -3, -3)
                elseif button == "LeftButton" then
                    Minimap_OnClick(self)
                end

            end)


        end

        -- Hide calendar button
        if LeaPlusLC["HideMiniCalendar"] == "On" then
            GameTimeFrame:Hide()

            Minimap:HookScript("OnMouseUp", function(self, button)
                if IsShiftKeyDown() then -- Check if the Shift key is pressed
                    if button == "MiddleButton" then
                        GameTimeFrame_OnClick(self) -- Trigger the GameTimeFrame function
                    end
                end
            end)
        end


        -- Hide POI arrows
        local function SetupPOI()
            if LeaPlusLC["HideMiniPOIArrows"] == "On" then
                Minimap:SetStaticPOIArrowTexture("Interface\\addons\\Leatrix_Plus\\assets\\ROTATING-MINIMAPARROW")
            else
                Minimap:SetStaticPOIArrowTexture("Interface\\Minimap\\Rotating-MinimapArrow")
            end
        end

        if LeaPlusLC["HideMiniPOIArrows"] == "On" then
            local frame=CreateFrame("Frame");
            frame:RegisterEvent("PLAYER_ENTERING_WORLD");
            frame:SetScript("OnEvent",function(self,event,...)
                -- Put code here
                Minimap:SetStaticPOIArrowTexture("Interface\\addons\\Leatrix_Plus\\assets\\ROTATING-MINIMAPARROW")
            end);
        end

        -- Setup events when option is clicked and on startup (if option is enabled)
        LeaPlusCB["HideMiniPOIArrows"]:HookScript("OnClick", SetupPOI)



        -- -- LibDBIcon callback (search LibDBIcon_IconCreated to find calls to this)
        -- LibDBIconStub.RegisterCallback(miniFrame, "LibDBIcon_IconCreated", function(self, button, name)

        -- 	-- Combine addon buttons: Hide new LibDBIcon icons
        -- 	if LeaPlusLC["CombineAddonButtons"] == "On" then
        -- 		--LibCompat.After(0.1, function() -- Removed for now
        -- 			local buttonName = strlower(name)
        -- 			if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
        -- 				if button.db and not button.db.hide then
        -- 					button:Hide()
        -- 					button:SetScript("OnShow", function() if not LeaPlusLC.bFrame:IsShown() then button:Hide() end end)
        -- 				end
        -- 				-- Create background texture
        -- 				local bFrameBg = button:CreateTexture(nil, "BACKGROUND")
        -- 				bFrameBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        -- 				bFrameBg:SetPoint("CENTER")
        -- 				bFrameBg:SetSize(30, 30)
        -- 				bFrameBg:SetVertexColor(0, 0, 0, 0.5)
        -- 			elseif strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) and LeaPlusLC["SquareMinimap"] == "On" then
        -- 				button:SetScale(0.75)
        -- 			end
        -- 			-- Move GameTooltip to below the minimap in case the button uses it
        -- 			button:HookScript("OnEnter", LeaPlusLC.SetButtonTooltip)
        -- 		--end)
        -- 	end

        -- 	-- Square minimap: Set scale of new LibDBIcon icons
        -- 	if LeaPlusLC["SquareMinimap"] == "On" and LeaPlusLC["CombineAddonButtons"] == "Off" then
        -- 		button:SetScale(0.75)
        -- 	end

        -- 	-- Hide addon buttons: Hide new LibDBIcon icons
        -- 	if LeaPlusLC["CombineAddonButtons"] == "Off" then
        -- 		local buttonName = strlower(name)
        -- 		if LeaPlusLC["HideMiniAddonButtons"] == "On" then
        -- 			-- Hide addon buttons is enabled
        -- 			if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
        -- 				LibDBIconStub:ShowOnEnter(name, true)
        -- 			end
        -- 		else
        -- 			-- Hide addon buttons is disabled
        -- 			if not strfind(strlower(LeaPlusDB["MiniExcludeList"]), buttonName) then
        -- 				LibDBIconStub:ShowOnEnter(name, false)
        -- 			end
        -- 		end
        -- 	end

        -- 	-- Hide tracking button
        -- 	if LeaPlusLC["HideMiniTracking"] == "On" then
        -- 		button:HookScript("OnEnter", function()
        -- 			-- Show tracking button when entering LibDBIcon button
        -- 			MiniMapTracking.fadeOut:Stop()
        -- 			MiniMapTracking:SetAlpha(1)
        -- 		end)
        -- 		button:HookScript("OnLeave", function()
        -- 			-- Hide tracking button when leaving LibDBIcon button
        -- 			MiniMapTracking.fadeOut:Play()
        -- 		end)
        -- 	end

        -- end)

    end

    ----------------------------------------------------------------------
    -- Manage durability
    ----------------------------------------------------------------------

    if LeaPlusLC["ManageDurability"] == "On" and not LeaLockList["ManageDurability"] then

        -- Create and manage container for DurabilityFrame
        local durabilityHolder = CreateFrame("Frame", nil, UIParent)
        durabilityHolder:SetPoint("TOP", UIParent, "TOP", 0, -15)
        durabilityHolder:SetSize(92, 75)

        local durabilityContainer = _G.DurabilityFrame
        durabilityContainer:ClearAllPoints()
        durabilityContainer:SetPoint('CENTER', durabilityHolder)
        --durabilityContainer:SetIgnoreParentScale(true) -- Needed to keep drag frame position when scaled

        local isDurabilityFrameMoving = false
        local durabilityFrameSetPoint = durabilityContainer.SetPoint

        durabilityContainer.SetPoint = function(self, _, relativeTo)
            if not InCombatLockdown() and not isDurabilityFrameMoving and relativeTo ~= durabilityHolder then
                --durabilityFrameSetPoint(self, 'TOPRIGHT', durabilityHolder) -- Has to be TOPRIGHT (drag frame while moving between subzones)
                --self:SetParent(durabilityHolder)
            end
        end

        -- Allow durability frame to be moved
        durabilityHolder:SetMovable(true)
        durabilityHolder:SetUserPlaced(true)
        durabilityHolder:SetDontSavePosition(true)
        durabilityHolder:SetClampedToScreen(false)

        -- Set durability frame position at startup
        durabilityHolder:ClearAllPoints()
        durabilityHolder:SetPoint(LeaPlusLC["DurabilityA"], UIParent, LeaPlusLC["DurabilityR"], LeaPlusLC["DurabilityX"], LeaPlusLC["DurabilityY"])
        durabilityHolder:SetScale(LeaPlusLC["DurabilityScale"])
        DurabilityFrame:SetScale(LeaPlusLC["DurabilityScale"])

        -- Create drag frame
        local dragframe = CreateFrame("FRAME", nil, nil)
        dragframe:SetPoint("CENTER", durabilityHolder, "CENTER", 0, 1)
        dragframe:SetBackdropColor(0.0, 0.5, 1.0)
        dragframe:SetBackdrop({ edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
        dragframe:SetToplevel(true)
        dragframe:EnableMouse(true)
        dragframe:Hide()
        dragframe:SetScale(LeaPlusLC["DurabilityScale"])

        dragframe.t = dragframe:CreateTexture()
        dragframe.t:SetAllPoints()
        dragframe.t:SetTexture(0.0, 1.0, 0.0, 0.5)
        dragframe.t:SetAlpha(0.5)

        dragframe.f = dragframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
        dragframe.f:SetPoint('CENTER', 0, 0)
        dragframe.f:SetText(L["Durability"])

        -- Click handler
        dragframe:SetScript("OnMouseDown", function(self, btn)
            -- Start dragging if left clicked
            if btn == "LeftButton" then
                durabilityHolder:StartMoving()
            end
        end)

        dragframe:SetScript("OnMouseUp", function()
            -- Save frame position
            durabilityHolder:StopMovingOrSizing()
            LeaPlusLC["DurabilityA"], void, LeaPlusLC["DurabilityR"], LeaPlusLC["DurabilityX"], LeaPlusLC["DurabilityY"] = durabilityHolder:GetPoint()
            durabilityHolder:SetMovable(true)
            durabilityHolder:ClearAllPoints()
            durabilityHolder:SetPoint(LeaPlusLC["DurabilityA"], UIParent, LeaPlusLC["DurabilityR"], LeaPlusLC["DurabilityX"], LeaPlusLC["DurabilityY"])
        end)

        -- Snap-to-grid
        do
            local frame, grid = dragframe, 10
            local w, h = 65, 75
            local xpos, ypos, scale, uiscale
            frame:RegisterForDrag("RightButton")
            frame:HookScript("OnDragStart", function()
                frame:SetScript("OnUpdate", function()
                    scale, uiscale = frame:GetScale(), UIParent:GetScale()
                    xpos, ypos = GetCursorPosition()
                    xpos = floor((xpos / scale / uiscale) / grid) * grid - w / 2
                    ypos = ceil((ypos / scale / uiscale) / grid) * grid + h / 2
                    durabilityHolder:ClearAllPoints()
                    durabilityHolder:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", xpos, ypos)
                end)
            end)
            frame:HookScript("OnDragStop", function()
                frame:SetScript("OnUpdate", nil)
                frame:GetScript("OnMouseUp")()
            end)
        end

        -- Create configuration panel
        local DurabilityPanel = LeaPlusLC:CreatePanel("Manage durability", "DurabilityPanel")

        LeaPlusLC:MakeTx(DurabilityPanel, "Scale", 16, -72)
        LeaPlusLC:MakeSL(DurabilityPanel, "DurabilityScale", "Drag to set the durability frame scale.", 0.5, 2, 0.05, 16, -92, "%.2f")

        -- Set scale when slider is changed
        LeaPlusCB["DurabilityScale"]:HookScript("OnValueChanged", function()
            durabilityHolder:SetScale(LeaPlusLC["DurabilityScale"])
            DurabilityFrame:SetScale(LeaPlusLC["DurabilityScale"])
            dragframe:SetScale(LeaPlusLC["DurabilityScale"])
            -- Show formatted slider value
            LeaPlusCB["DurabilityScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["DurabilityScale"] * 100)
        end)

        -- Hide frame alignment grid with panel
        DurabilityPanel:HookScript("OnHide", function()
            LeaPlusLC.grid:Hide()
        end)

        -- Toggle grid button
        local DurabilityToggleGridButton = LeaPlusLC:CreateButton("DurabilityToggleGridButton", DurabilityPanel, "Toggle Grid", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the frame alignment grid.")
        LeaPlusCB["DurabilityToggleGridButton"]:ClearAllPoints()
        LeaPlusCB["DurabilityToggleGridButton"]:SetPoint("LEFT", DurabilityPanel.h, "RIGHT", 10, 0)
        LeaPlusCB["DurabilityToggleGridButton"]:SetScript("OnClick", function()
            if LeaPlusLC.grid:IsShown() then
                LeaPlusLC.grid:Hide()
            else
                LeaPlusLC.grid:Show()
            end
        end)
        DurabilityPanel:HookScript("OnHide", function()
            if LeaPlusLC.grid then
                LeaPlusLC.grid:Hide()
            end
        end)

        -- Help button tooltip
        DurabilityPanel.h.tiptext = L["Drag the frame overlay with the left button to position it freely or with the right button to position it using snap-to-grid."]

        -- Back button handler
        DurabilityPanel.b:SetScript("OnClick", function()
            DurabilityPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page6"]:Show()
            return
        end)

        -- Reset button handler
        DurabilityPanel.r:SetScript("OnClick", function()

            -- Reset position and scale
            LeaPlusLC["DurabilityA"] = "TOPRIGHT"
            LeaPlusLC["DurabilityR"] = "TOPRIGHT"
            LeaPlusLC["DurabilityX"] = 0
            LeaPlusLC["DurabilityY"] = -170
            LeaPlusLC["DurabilityScale"] = 1
            durabilityHolder:ClearAllPoints()
            durabilityHolder:SetPoint(LeaPlusLC["DurabilityA"], UIParent, LeaPlusLC["DurabilityR"], LeaPlusLC["DurabilityX"], LeaPlusLC["DurabilityY"])

            -- Refresh configuration panel
            DurabilityPanel:Hide();
            DurabilityPanel:Show()
            dragframe:Show()

            -- Show frame alignment grid
            LeaPlusLC.grid:Show()

        end)

        -- Show configuration panel when options panel button is clicked
        LeaPlusCB["ManageDurabilityButton"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["DurabilityA"] = "TOPRIGHT"
                LeaPlusLC["DurabilityR"] = "TOPRIGHT"
                LeaPlusLC["DurabilityX"] = 0
                LeaPlusLC["DurabilityY"] = -170
                LeaPlusLC["DurabilityScale"] = 1
                durabilityHolder:ClearAllPoints()
                durabilityHolder:SetPoint(LeaPlusLC["DurabilityA"], UIParent, LeaPlusLC["DurabilityR"], LeaPlusLC["DurabilityX"], LeaPlusLC["DurabilityY"])
                durabilityHolder:SetScale(LeaPlusLC["DurabilityScale"])
                DurabilityFrame:SetScale(LeaPlusLC["DurabilityScale"])
            else
                -- Find out if the UI has a non-standard scale
                if GetCVar("useuiscale") == "1" then
                    LeaPlusLC["gscale"] = GetCVar("uiscale")
                else
                    LeaPlusLC["gscale"] = 1
                end

                -- Set drag frame size according to UI scale
                dragframe:SetWidth(92 * LeaPlusLC["gscale"])
                dragframe:SetHeight(75 * LeaPlusLC["gscale"])

                -- Show configuration panel
                DurabilityPanel:Show()
                LeaPlusLC:HideFrames()
                dragframe:Show()

                -- Show frame alignment grid
                LeaPlusLC.grid:Show()
            end
        end)

        -- Hide drag frame when configuration panel is closed
        DurabilityPanel:HookScript("OnHide", function()
            dragframe:Hide()
        end)

    end


    ----------------------------------------------------------------------
    -- Manage Tracker
    ----------------------------------------------------------------------

    if LeaPlusLC["ManageTracker"] == "On" and not LeaLockList["ManageTracker"] then

        -- Create and manage container for WatchFrame
        local trackerHolder = CreateFrame("Frame", nil, UIParent)
        trackerHolder:SetPoint("TOP", UIParent, "TOP", 0, -15)
        trackerHolder:SetSize(92, 75)

        local trackerContainer = _G.WatchFrame
        trackerContainer:ClearAllPoints()
        trackerContainer:SetPoint('CENTER', trackerHolder)
        trackerContainer:SetClampedToScreen(false)


        local function SetWatchFrameHeight()
            local top = WatchFrame:GetTop() or 0
            local screenHeight = GetScreenHeight()
            local gapFromTop = screenHeight - top
            local maxHeight = screenHeight - gapFromTop
            local watchFrameHeight = min(maxHeight, 800)

            WatchFrame:SetHeight(watchFrameHeight)
        end

        SetWatchFrameHeight()

        --trackerContainer:SetIgnoreParentScale(true) -- Needed to keep drag frame position when scaled

        local isWatchFrameMoving = false
        local WatchFrameSetPoint = trackerContainer.SetPoint

        trackerContainer.SetPoint = function(self, _, relativeTo)
            if not InCombatLockdown() and not isWatchFrameMoving and relativeTo ~= trackerHolder then
                WatchFrameSetPoint(self, 'TOPRIGHT', trackerHolder) -- Has to be TOPRIGHT (drag frame while moving between subzones)
                self:SetParent(trackerHolder)
            end
        end

        -- Allow tracker frame to be moved
        trackerHolder:SetMovable(true)
        trackerHolder:SetUserPlaced(true)
        trackerHolder:SetDontSavePosition(true)
        trackerHolder:SetClampedToScreen(false)

        -- Set tracker frame position at startup
        trackerHolder:ClearAllPoints()
        trackerHolder:SetPoint(LeaPlusLC["TrackerA"], UIParent, LeaPlusLC["TrackerR"], LeaPlusLC["TrackerX"], LeaPlusLC["TrackerY"])
        trackerHolder:SetScale(LeaPlusLC["TrackerScale"])
        WatchFrame:SetScale(LeaPlusLC["TrackerScale"])

        -- Create drag frame
        local dragframe = CreateFrame("FRAME", nil, nil)
        dragframe:SetPoint("CENTER", trackerHolder, "CENTER", 0, 1)
        dragframe:SetBackdropColor(0.0, 0.5, 1.0)
        dragframe:SetBackdrop({ edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
        dragframe:SetToplevel(true)
        dragframe:EnableMouse(true)
        dragframe:Hide()
        dragframe:SetScale(LeaPlusLC["TrackerScale"])

        dragframe.t = dragframe:CreateTexture()
        dragframe.t:SetAllPoints()
        dragframe.t:SetTexture(0.0, 1.0, 0.0, 0.5)
        dragframe.t:SetAlpha(0.5)

        dragframe.f = dragframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
        dragframe.f:SetPoint('CENTER', 0, 0)
        dragframe.f:SetText(L["Tracker"])

        -- Click handler
        dragframe:SetScript("OnMouseDown", function(self, btn)
            -- Start dragging if left clicked
            if btn == "LeftButton" then
                trackerHolder:StartMoving()
            end
        end)

        dragframe:SetScript("OnMouseUp", function()
            -- Save frame position
            trackerHolder:StopMovingOrSizing()
            LeaPlusLC["TrackerA"], void, LeaPlusLC["TrackerR"], LeaPlusLC["TrackerX"], LeaPlusLC["TrackerY"] = trackerHolder:GetPoint()
            trackerHolder:SetMovable(true)
            trackerHolder:ClearAllPoints()
            trackerHolder:SetPoint(LeaPlusLC["TrackerA"], UIParent, LeaPlusLC["TrackerR"], LeaPlusLC["TrackerX"], LeaPlusLC["TrackerY"])
        end)

        -- Snap-to-grid
        do
            local frame, grid = dragframe, 10
            local w, h = 65, 75
            local xpos, ypos, scale, uiscale
            frame:RegisterForDrag("RightButton")
            frame:HookScript("OnDragStart", function()
                frame:SetScript("OnUpdate", function()
                    scale, uiscale = frame:GetScale(), UIParent:GetScale()
                    xpos, ypos = GetCursorPosition()
                    xpos = floor((xpos / scale / uiscale) / grid) * grid - w / 2
                    ypos = ceil((ypos / scale / uiscale) / grid) * grid + h / 2
                    trackerHolder:ClearAllPoints()
                    trackerHolder:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", xpos, ypos)
                end)
            end)
            frame:HookScript("OnDragStop", function()
                frame:SetScript("OnUpdate", nil)
                frame:GetScript("OnMouseUp")()
            end)
        end

        -- Create configuration panel
        local TrackerPanel = LeaPlusLC:CreatePanel("Manage tracker", "TrackerPanel")

        LeaPlusLC:MakeTx(TrackerPanel, "Scale", 16, -72)
        LeaPlusLC:MakeSL(TrackerPanel, "TrackerScale", "Drag to set the tracker frame scale.", 0.5, 2, 0.05, 16, -92, "%.2f")

        -- Set scale when slider is changed
        LeaPlusCB["TrackerScale"]:HookScript("OnValueChanged", function()
            trackerHolder:SetScale(LeaPlusLC["TrackerScale"])
            WatchFrame:SetScale(LeaPlusLC["TrackerScale"])
            dragframe:SetScale(LeaPlusLC["TrackerScale"])
            -- Show formatted slider value
            LeaPlusCB["TrackerScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["TrackerScale"] * 100)
        end)

        -- Hide frame alignment grid with panel
        TrackerPanel:HookScript("OnHide", function()
            LeaPlusLC.grid:Hide()
        end)

        -- Toggle grid button
        local TrackerToggleGridButton = LeaPlusLC:CreateButton("TrackerToggleGridButton", TrackerPanel, "Toggle Grid", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the frame alignment grid.")
        LeaPlusCB["TrackerToggleGridButton"]:ClearAllPoints()
        LeaPlusCB["TrackerToggleGridButton"]:SetPoint("LEFT", TrackerPanel.h, "RIGHT", 10, 0)
        LeaPlusCB["TrackerToggleGridButton"]:SetScript("OnClick", function()
            if LeaPlusLC.grid:IsShown() then
                LeaPlusLC.grid:Hide()
            else
                LeaPlusLC.grid:Show()
            end
        end)
        TrackerPanel:HookScript("OnHide", function()
            if LeaPlusLC.grid then
                LeaPlusLC.grid:Hide()
            end
        end)

        -- Help button tooltip
        TrackerPanel.h.tiptext = L["Drag the frame overlay with the left button to position it freely or with the right button to position it using snap-to-grid."]

        -- Back button handler
        TrackerPanel.b:SetScript("OnClick", function()
            TrackerPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page6"]:Show()
            return
        end)

        -- Reset button handler
        TrackerPanel.r:SetScript("OnClick", function()

            -- Reset position and scale
            LeaPlusLC["TrackerA"] = "TOPRIGHT"
            LeaPlusLC["TrackerR"] = "TOPRIGHT"
            LeaPlusLC["TrackerX"] = 0
            LeaPlusLC["TrackerY"] = -170
            LeaPlusLC["TrackerScale"] = 1
            trackerHolder:ClearAllPoints()
            trackerHolder:SetPoint(LeaPlusLC["TrackerA"], UIParent, LeaPlusLC["TrackerR"], LeaPlusLC["TrackerX"], LeaPlusLC["TrackerY"])

            -- Refresh configuration panel
            TrackerPanel:Hide();
            TrackerPanel:Show()
            dragframe:Show()

            -- Show frame alignment grid
            LeaPlusLC.grid:Show()

        end)

        -- Show configuration panel when options panel button is clicked
        LeaPlusCB["ManageTrackerButton"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["TrackerA"] = "TOPRIGHT"
                LeaPlusLC["TrackerR"] = "TOPRIGHT"
                LeaPlusLC["TrackerX"] = 0
                LeaPlusLC["TrackerY"] = -170
                LeaPlusLC["TrackerScale"] = 1
                trackerHolder:ClearAllPoints()
                trackerHolder:SetPoint(LeaPlusLC["TrackerA"], UIParent, LeaPlusLC["TrackerR"], LeaPlusLC["TrackerX"], LeaPlusLC["TrackerY"])
                trackerHolder:SetScale(LeaPlusLC["TrackerScale"])
                WatchFrame:SetScale(LeaPlusLC["TrackerScale"])
            else
                -- Find out if the UI has a non-standard scale
                if GetCVar("useuiscale") == "1" then
                    LeaPlusLC["gscale"] = GetCVar("uiscale")
                else
                    LeaPlusLC["gscale"] = 1
                end

                -- Set drag frame size according to UI scale
                dragframe:SetWidth(92 * LeaPlusLC["gscale"])
                dragframe:SetHeight(75 * LeaPlusLC["gscale"])

                -- Show configuration panel
                TrackerPanel:Show()
                LeaPlusLC:HideFrames()
                dragframe:Show()

                -- Show frame alignment grid
                LeaPlusLC.grid:Show()
            end
        end)

        -- Hide drag frame when configuration panel is closed
        TrackerPanel:HookScript("OnHide", function()
            dragframe:Hide()
        end)

    end



    ----------------------------------------------------------------------
    -- Manage timer
    ----------------------------------------------------------------------

    if LeaPlusLC["ManageTimer"] == "On" and not LeaLockList["ManageTimer"] then

        -- Allow timer frame to be moved
        MirrorTimer1:SetMovable(true)
        MirrorTimer1:SetUserPlaced(true)
        MirrorTimer1:SetDontSavePosition(true)
        MirrorTimer1:SetClampedToScreen(true)

        -- Set timer frame position at startup
        MirrorTimer1:ClearAllPoints()
        MirrorTimer1:SetPoint(LeaPlusLC["TimerA"], UIParent, LeaPlusLC["TimerR"], LeaPlusLC["TimerX"], LeaPlusLC["TimerY"])
        MirrorTimer1:SetScale(LeaPlusLC["TimerScale"])

        -- Create drag frame
        local dragframe = CreateFrame("FRAME", nil, nil)
        dragframe:SetPoint("TOPRIGHT", MirrorTimer1, "TOPRIGHT", 0, 2.5)
        dragframe:SetBackdropColor(0.0, 0.5, 1.0)
        dragframe:SetBackdrop({ edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
        dragframe:SetToplevel(true)
        dragframe:EnableMouse(true)
        dragframe:Hide()
        dragframe:SetScale(LeaPlusLC["TimerScale"])

        dragframe.t = dragframe:CreateTexture()
        dragframe.t:SetAllPoints()
        dragframe.t:SetTexture(0.0, 1.0, 0.0, 0.5)
        dragframe.t:SetAlpha(0.5)

        dragframe.f = dragframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
        dragframe.f:SetPoint('CENTER', 0, 0)
        dragframe.f:SetText(L["Timer"])

        -- Click handler
        dragframe:SetScript("OnMouseDown", function(self, btn)
            -- Start dragging if left clicked
            if btn == "LeftButton" then
                MirrorTimer1:StartMoving()
            end
        end)

        dragframe:SetScript("OnMouseUp", function()
            -- Save frame positions
            MirrorTimer1:StopMovingOrSizing()
            LeaPlusLC["TimerA"], void, LeaPlusLC["TimerR"], LeaPlusLC["TimerX"], LeaPlusLC["TimerY"] = MirrorTimer1:GetPoint()
            MirrorTimer1:SetMovable(true)
            MirrorTimer1:ClearAllPoints()
            MirrorTimer1:SetPoint(LeaPlusLC["TimerA"], UIParent, LeaPlusLC["TimerR"], LeaPlusLC["TimerX"], LeaPlusLC["TimerY"])
        end)

        -- Snap-to-grid
        do
            local frame, grid = dragframe, 10
            local w, h = 180, 20
            local xpos, ypos, scale, uiscale
            frame:RegisterForDrag("RightButton")
            frame:HookScript("OnDragStart", function()
                frame:SetScript("OnUpdate", function()
                    scale, uiscale = frame:GetScale(), UIParent:GetScale()
                    xpos, ypos = GetCursorPosition()
                    xpos = floor((xpos / scale / uiscale) / grid) * grid - w / 2
                    ypos = ceil((ypos / scale / uiscale) / grid) * grid + h / 2
                    MirrorTimer1:ClearAllPoints()
                    MirrorTimer1:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", xpos, ypos)
                end)
            end)
            frame:HookScript("OnDragStop", function()
                frame:SetScript("OnUpdate", nil)
                frame:GetScript("OnMouseUp")()
            end)
        end

        -- Create configuration panel
        local TimerPanel = LeaPlusLC:CreatePanel("Manage timer", "TimerPanel")

        LeaPlusLC:MakeTx(TimerPanel, "Scale", 16, -72)
        LeaPlusLC:MakeSL(TimerPanel, "TimerScale", "Drag to set the timer bar scale.", 0.5, 2, 0.05, 16, -92, "%.2f")

        -- Set scale when slider is changed
        LeaPlusCB["TimerScale"]:HookScript("OnValueChanged", function()
            MirrorTimer1:SetScale(LeaPlusLC["TimerScale"])
            dragframe:SetScale(LeaPlusLC["TimerScale"])
            -- Show formatted slider value
            LeaPlusCB["TimerScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["TimerScale"] * 100)
        end)

        -- Hide frame alignment grid with panel
        TimerPanel:HookScript("OnHide", function()
            LeaPlusLC.grid:Hide()
        end)

        -- Toggle grid button
        local TimerToggleGridButton = LeaPlusLC:CreateButton("TimerToggleGridButton", TimerPanel, "Toggle Grid", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the frame alignment grid.")
        LeaPlusCB["TimerToggleGridButton"]:ClearAllPoints()
        LeaPlusCB["TimerToggleGridButton"]:SetPoint("LEFT", TimerPanel.h, "RIGHT", 10, 0)
        LeaPlusCB["TimerToggleGridButton"]:SetScript("OnClick", function()
            if LeaPlusLC.grid:IsShown() then
                LeaPlusLC.grid:Hide()
            else
                LeaPlusLC.grid:Show()
            end
        end)
        TimerPanel:HookScript("OnHide", function()
            if LeaPlusLC.grid then
                LeaPlusLC.grid:Hide()
            end
        end)

        -- Help button tooltip
        TimerPanel.h.tiptext = L["Drag the frame overlay with the left button to position it freely or with the right button to position it using snap-to-grid."]

        -- Back button handler
        TimerPanel.b:SetScript("OnClick", function()
            TimerPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page6"]:Show()
            return
        end)

        -- Reset button handler
        TimerPanel.r:SetScript("OnClick", function()

            -- Reset position and scale
            LeaPlusLC["TimerA"] = "TOP"
            LeaPlusLC["TimerR"] = "TOP"
            LeaPlusLC["TimerX"] = -5
            LeaPlusLC["TimerY"] = -96
            LeaPlusLC["TimerScale"] = 1
            MirrorTimer1:ClearAllPoints()
            MirrorTimer1:SetPoint(LeaPlusLC["TimerA"], UIParent, LeaPlusLC["TimerR"], LeaPlusLC["TimerX"], LeaPlusLC["TimerY"])

            -- Refresh configuration panel
            TimerPanel:Hide();
            TimerPanel:Show()
            dragframe:Show()

            -- Show frame alignment grid
            LeaPlusLC.grid:Show()

        end)

        -- Show configuration panel when options panel button is clicked
        LeaPlusCB["ManageTimerButton"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["TimerA"] = "TOP"
                LeaPlusLC["TimerR"] = "TOP"
                LeaPlusLC["TimerX"] = 0
                LeaPlusLC["TimerY"] = -120
                LeaPlusLC["TimerScale"] = 1
                MirrorTimer1:ClearAllPoints()
                MirrorTimer1:SetPoint(LeaPlusLC["TimerA"], UIParent, LeaPlusLC["TimerR"], LeaPlusLC["TimerX"], LeaPlusLC["TimerY"])
                MirrorTimer1:SetScale(LeaPlusLC["TimerScale"])
            else
                -- Find out if the UI has a non-standard scale
                if GetCVar("useuiscale") == "1" then
                    LeaPlusLC["gscale"] = GetCVar("uiscale")
                else
                    LeaPlusLC["gscale"] = 1
                end

                -- Set drag frame size according to UI scale
                dragframe:SetWidth(206 * LeaPlusLC["gscale"])
                dragframe:SetHeight(20 * LeaPlusLC["gscale"])
                dragframe:SetFrameStrata("HIGH") -- MirrorTimer is medium

                -- Show configuration panel
                TimerPanel:Show()
                LeaPlusLC:HideFrames()
                dragframe:Show()

                -- Show frame alignment grid
                LeaPlusLC.grid:Show()
            end
        end)

        -- Hide drag frame when configuration panel is closed
        TimerPanel:HookScript("OnHide", function()
            dragframe:Hide()
        end)

    end

    ----------------------------------------------------------------------
    -- Hide alerts
    ----------------------------------------------------------------------

    if LeaPlusLC["NoAlerts"] == "On" then

        -- Unregister alert events
        hooksecurefunc(AlertFrame, "RegisterEvent", function(_, event)
            AlertFrame:UnregisterEvent(event)
        end)
        AlertFrame:UnregisterAllEvents()

        -- Show chat message and play sound for achievement alerts
        local frame = CreateFrame("FRAME")
        frame:RegisterEvent("ACHIEVEMENT_EARNED")
        frame:SetScript("OnEvent", function(self, event, arg1)
            if arg1 then
                local alink = GetAchievementLink(arg1)
                if alink then
                    LeaPlusLC:Print(string.format(NEW_ACHIEVEMENT_EARNED:gsub("'", ""), alink))
                    PlaySound(12891)
                end
            end
        end)

    end

    ----------------------------------------------------------------------
    -- Show ready timer
    ----------------------------------------------------------------------

    if LeaPlusLC["ShowReadyTimer"] == "On" then

        -- Player vs Player
        do

            --===== Status Bar creation =====--

            local bar = CreateFrame("StatusBar")
            local anchorFrame
            local shouldShowBar = false
            local started = false
            bar:SetHeight(5)
            bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
            bar:SetStatusBarColor(1.0, 1, 0.0)

            --===== Spark creation =====--

            local spark = bar:CreateTexture(nil, "OVERLAY")
            spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
            spark:SetSize(18, 18)
            spark:SetVertexColor(1, 1, 1)
            spark:SetBlendMode("ADD")
            spark:Hide()

            --------------------------------------------------------------------------------
            -- Function to setup status bar scripts and positions
            --------------------------------------------------------------------------------


            local function SetupBar()
                LibCompat.After(0.1, function()
                    if not StaticPopup1:IsShown() and not MiniMapBattlefieldFrame:IsShown() then
                        -- print("resetting")
                        started = false
                    end
                end)
                for i = 1, MAX_BATTLEFIELD_QUEUES do
                    status = GetBattlefieldStatus(i);
                    if (status == "confirm") then
                        shouldShowBar = true
                        break
                    else
                        shouldShowBar = false
                    end
                end
                if shouldShowBar then
                    bar:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 8, 0)
                    bar:SetPoint("TOPRIGHT", anchorFrame, "BOTTOMRIGHT", 0, 0)
                    bar:SetParent(anchorFrame)
                    bar:SetScript("OnEvent", OnEvent)
                    bar:SetScript("OnUpdate", Update)
                    bar:SetFrameStrata("FULLSCREEN")
                else
                    bar:SetScript("OnEvent", nil)
                    bar:SetScript("OnUpdate", nil)
                    bar:Hide()
                    spark:Hide()
                end
            end

            --===== Hook to the blizzard frames scripts, to avoid bar creation on frames that are not BG queue pop-up =====--

            StaticPopup1:HookScript("OnShow", SetupBar)
            StaticPopup2:HookScript("OnShow", SetupBar)
            StaticPopup3:HookScript("OnShow", SetupBar)
            StaticPopup4:HookScript("OnShow", SetupBar)

            StaticPopup1:HookScript("OnHide", SetupBar)
            StaticPopup2:HookScript("OnHide", SetupBar)
            StaticPopup3:HookScript("OnHide", SetupBar)
            StaticPopup4:HookScript("OnHide", SetupBar)


            --===== Status Bar Text Creation =====--

            local text = bar:CreateFontString(nil, "ARTWORK")
            text:SetFontObject("GameFontNormalLarge")
            text:SetTextColor(0, 0.85, 0.0)
            text:SetPoint("TOPLEFT", 0, -10)


            --------------------------------------------------------------------------------
            -- Hooks to the Blizzard functions.
            --------------------------------------------------------------------------------

            --===== OnShow =====--

            local BGQueue_OnShow = StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"].OnShow

            function hookConfirmBattlefieldEntry()
                hooksecurefunc(StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"], "OnShow", function(self, data)
                    bar:Show()
                    anchorFrame = self
                    SetupBar()
                    BGQueue_OnShow(self, data)
                end)
            end

            hookConfirmBattlefieldEntry()

            --===== BG Popup: Button Functions - OnAccept & OnCancel =====--

            local BGQueue_OnAccept = StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"].OnAccept
            local BGQueue_OnCancel = StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"].OnCancel

            function hookConfirmBattlefieldEntry()
                hooksecurefunc(StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"], "OnAccept", function(self, data)
                    -- print("accept")
                    SetupBar()
                    LibCompat.After(1, function()
                        if not self:IsShown() and not MiniMapBattlefieldFrame:IsShown() then
                            -- print("resetting")
                            started = false
                        end
                    end)
                    return BGQueue_OnAccept(self, data)
                end)

                hooksecurefunc(StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"], "OnCancel", function(self, data)
                    -- print("cancel")
                    SetupBar()
                    LibCompat.After(1, function()
                        if not self:IsShown() and not MiniMapBattlefieldFrame:IsShown() then
                            -- print("resetting")
                            started = false
                        end
                    end)

                    -- Call the original function
                    return BGQueue_OnCancel(self, data)
                end)
            end

            hookConfirmBattlefieldEntry()


            --------------------------------------------------------------------------------
            -- My own Functions
            --------------------------------------------------------------------------------


            local function OnEvent(self, event)
                for i = 1, MAX_BATTLEFIELD_QUEUES do
                    if not started then
                        bar.expiration = GetBattlefieldPortExpiration(i)
                        bar.startTime = GetTime()
                        started = true
                    end
                    bar:SetMinMaxValues(0, bar.expiration)
                end
            end

            local function Update(self, elapsed)
                for i = 1, MAX_BATTLEFIELD_QUEUES do
                    local progress = bar.expiration - (GetTime() - bar.startTime)
                    bar:SetValue(progress)
                    text:SetFormattedText(SecondsToTime(progress + 0.5))
                end
            end

            --===== Hook to Blizz Function OnUpdate =====--

            hooksecurefunc("BattlefieldTimerFrame_OnUpdate", function()
                for i = 1, MAX_BATTLEFIELD_QUEUES do
                    -- 		status = GetBattlefieldStatus(i);
                    -- if status == "confirm" then
                    if not started then
                        bar.expiration = GetBattlefieldPortExpiration(i)
                        bar.startTime = GetTime()
                        started = true
                    end
                    bar:SetMinMaxValues(0, bar.expiration)
                    local progress = bar.expiration - (GetTime() - bar.startTime)
                    bar:SetValue(progress)
                    text:SetFormattedText(SecondsToTime(progress + 0.5))

                    spark:Show()
                    local pos = bar:GetWidth() / bar.expiration * progress
                    spark:SetPoint("CENTER", bar, "LEFT", pos, 0)
                    if progress <= 15 then
                        text:SetTextColor(1, 1, 0)
                        bar:SetStatusBarColor(1, 0, 0)
                    else
                        text:SetTextColor(0, 1, 0)
                        bar:SetStatusBarColor(1, 1, 0.0)

                    end
                end
                -- end
            end)

            --------------------------------------------------------------------------------
            -- Play Sound, code from ReadyCheckBgSound addon.
            --------------------------------------------------------------------------------


            local frame = CreateFrame("Frame")
            lasttime = GetTime()

            local function ReadyCheckBgSoundOnEvent(self, event, ...)
                if (event == "LFG_PROPOSAL_SHOW" or event == "READY_CHECK") then
                    ReadyCheckPlaySound()

                elseif (event == "UPDATE_BATTLEFIELD_STATUS") then

                    for i = 1, MAX_BATTLEFIELD_QUEUES do
                        status, mapName, instanceID, lowestlevel, highestlevel, teamSize, registeredMatch = GetBattlefieldStatus(i);

                        if (status == "confirm") then
                            ReadyCheckPlaySound()
                            break
                        end
                        i = i + 1
                    end
                end
            end

            function ReadyCheckBgSoundOnLoad()

            end

            function ReadyCheckPlaySound()
                if (GetTime() >= lasttime + 10) then
                    lasttime = GetTime()
                    PlaySoundFile("Sound\\Interface\\ReadyCheck.wav", "Master")
                end
            end

            frame:RegisterEvent("LFG_PROPOSAL_SHOW");
            frame:RegisterEvent("READY_CHECK");
            frame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS");
            frame:SetScript("OnEvent", ReadyCheckBgSoundOnEvent)


            --------------------------------------------------------------------------------
            -- Test and Old codes
            --------------------------------------------------------------------------------




            -- local shouldShowBar1 = false
            -- local shouldShowBar2 = false


            -- StaticPopup1:HookScript("OnShow", function()
            -- anchorFrame = StaticPopup1
            -- SetupBar()

            -- for i = 1, MAX_BATTLEFIELD_QUEUES do
            --   status = GetBattlefieldStatus(i);
            --   if ( status == "confirm" ) then
            --     shouldShowBar1 = true
            --     break
            --   end
            -- end

            -- if shouldShowBar1 then
            --   bar:Show()
            -- else
            --   bar:Hide()
            -- end
            -- end)

            -- StaticPopup2:HookScript("OnShow", function()
            -- anchorFrame = StaticPopup2
            -- SetupBar()

            -- for i = 1, MAX_BATTLEFIELD_QUEUES do
            --   status = GetBattlefieldStatus(i);
            --   if ( status == "confirm" ) then
            --     shouldShowBar2 = true
            --     break
            --   end
            -- end

            -- if shouldShowBar2 then
            --   bar:Show()
            -- else
            --   bar:Hide()
            -- end
            -- end)

            -- StaticPopup1:HookScript("OnHide", function()
            -- 	if shouldShowBar1 or shouldShowBar2 then return end
            -- 	bar:Hide()
            -- 	LibCompat.After(1, function()
            -- 		if not StaticPopup1:IsShown() and not MiniMapBattlefieldFrame:IsShown() then
            -- 			print("resetting")
            -- 			started = false
            -- 		end
            -- 	end)

            -- end)

            -- StaticPopup2:HookScript("OnHide", function()
            -- 	if shouldShowBar1 or shouldShowBar2 then return end
            -- 	bar:Hide()
            -- 	LibCompat.After(1, function()
            -- 		if not StaticPopup2:IsShown() and not MiniMapBattlefieldFrame:IsShown() then
            -- 			print("resetting")
            -- 			started = false
            -- 		end
            -- 	end)

            -- end)













            -- -- Declare variables
            -- local t, barTime = -1, -1

            -- -- Create status bar below dungeon ready popup
            -- local bar = CreateFrame("StatusBar", nil, PVPReadyDialog)
            -- bar:SetPoint("TOPLEFT", PVPReadyDialog, "BOTTOMLEFT", 0, -5)
            -- bar:SetPoint("TOPRIGHT", PVPReadyDialog, "BOTTOMRIGHT", 0, -5)
            -- bar:SetHeight(5)
            -- bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
            -- bar:SetStatusBarColor(1.0, 0.85, 0.0)

            -- -- Create status bar text
            -- local text = bar:CreateFontString(nil, "ARTWORK")
            -- text:SetFontObject("GameFontNormalLarge")
            -- text:SetTextColor(1.0, 0.85, 0.0)
            -- text:SetPoint("TOP", 0, -10)

            -- -- Update bar as timer counts down
            -- bar:SetScript("OnUpdate", function(self, elapsed)
            -- 	t = t - elapsed
            -- 	if barTime >= 1 or barTime == -1 then
            -- 		self:SetValue(t)
            -- 		text:SetText(SecondsToTime(floor(t + 0.5)))
            -- 		barTime = 0
            -- 	end
            -- 	barTime = barTime + elapsed
            -- end)

            -- -- Show frame when PvP ready frame shows
            -- hooksecurefunc("PVPReadyDialog_Display", function(self, id)
            -- 	t = GetBattlefieldPortExpiration(id) + 1
            -- 	-- t = 89; -- debug
            -- 	if t and t > 1 then
            -- 		bar:SetMinMaxValues(0, t)
            -- 		barTime = -1
            -- 		bar:Show()
            -- 	else
            -- 		bar:Hide()
            -- 	end
            -- end)

            -- PVPReadyDialog:HookScript("OnHide", function()
            -- 	bar:Hide()
            -- end)

            -- Debug
            -- LibCompat.After(2, function() PVPReadyDialog_Display(self, 1, "Warsong Gulch", 0, "BATTLEGROUND", "", "DAMAGER"); bar:Show() end)

        end

    end

    ----------------------------------------------------------------------
    -- Show flight times
    ----------------------------------------------------------------------

    if LeaPlusLC["ShowFlightTimes"] == "On" then

        -- Load flight data
        Leatrix_Plus["FlightData"] = {}
        Leatrix_Plus:LoadFlightDataAlliance()
        Leatrix_Plus:LoadFlightDataHorde()

        -- Minimum time difference (in seconds) to flight data entry before flight report window is shown
        local timeBuffer = 15

        -- Create editbox
        local editFrame = CreateFrame("ScrollFrame", nil, UIParent, "Leatrix_InputScrollFrameTemplate")

        -- Set frame parameters
        editFrame:ClearAllPoints()
        editFrame:SetPoint("BOTTOM", 0, 130)
        editFrame:SetSize(600, 300)
        editFrame:SetFrameStrata("HIGH")
        editFrame:SetToplevel(true)
        editFrame:Hide()
        editFrame.CharCount:Hide()
        editFrame:SetHitRectInsets(10, 10, 10, 10)

        -- Set solid white color for background instead of using 8x8 texture
        editFrame:SetBackdrop({
            bgFile = "Interface\\BUTTONS\\WHITE8X8", -- use 8x8 texture
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileEdge = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        editFrame:SetBackdropColor(0.00, 0.00, 0.0, 0.6) -- set transparency

        --===== Create Scroll Frame =====--
        local scroll = CreateFrame("ScrollFrame", "LeatrixChatScroll", editFrame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", editFrame, 26, -36)
        scroll:SetPoint("BOTTOMRIGHT", editFrame, "BOTTOMRIGHT", -34, 8)

        -- Set textures
        -- editFrame.LeftTex:SetTexture(editFrame.RightTex:GetTexture()); editFrame.LeftTex:SetTexCoord(1, 0, 0, 1)
        -- editFrame.BottomTex:SetTexture(editFrame.TopTex:GetTexture()); editFrame.BottomTex:SetTexCoord(0, 1, 1, 0)
        -- editFrame.BottomRightTex:SetTexture(editFrame.TopRightTex:GetTexture()); editFrame.BottomRightTex:SetTexCoord(0, 1, 1, 0)
        -- editFrame.BottomLeftTex:SetTexture(editFrame.TopRightTex:GetTexture()); editFrame.BottomLeftTex:SetTexCoord(1, 0, 1, 0)
        -- editFrame.TopLeftTex:SetTexture(editFrame.TopRightTex:GetTexture()); editFrame.TopLeftTex:SetTexCoord(1, 0, 0, 1)

        -- Create title bar
        local titleFrame = CreateFrame("ScrollFrame", nil, editFrame, "Leatrix_InputScrollFrameTemplate")
        titleFrame:ClearAllPoints()
        titleFrame:SetPoint("TOP", 0, 40)
        titleFrame:SetSize(600, 36)
        titleFrame:SetFrameStrata("MEDIUM")
        titleFrame:SetToplevel(true)
        titleFrame:SetHitRectInsets(-6, -6, -6, -6)

        -- titleFrame.LeftTex:SetTexture(titleFrame.RightTex:GetTexture()); titleFrame.LeftTex:SetTexCoord(1, 0, 0, 1)
        -- titleFrame.BottomTex:SetTexture(titleFrame.TopTex:GetTexture()); titleFrame.BottomTex:SetTexCoord(0, 1, 1, 0)
        -- titleFrame.BottomRightTex:SetTexture(titleFrame.TopRightTex:GetTexture()); titleFrame.BottomRightTex:SetTexCoord(0, 1, 1, 0)
        -- titleFrame.BottomLeftTex:SetTexture(titleFrame.TopRightTex:GetTexture()); titleFrame.BottomLeftTex:SetTexCoord(1, 0, 1, 0)
        -- titleFrame.TopLeftTex:SetTexture(titleFrame.TopRightTex:GetTexture()); titleFrame.TopLeftTex:SetTexCoord(1, 0, 0, 1)

        -- Set background texture for titleFrame
        titleFrame:SetBackdrop({
            bgFile = "Interface\\BUTTONS\\WHITE8X8", -- use 8x8 texture
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileEdge = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        titleFrame:SetBackdropColor(0.00, 0.00, 0.0, 0.6) -- set transparency

        -- Add message count
        titleFrame.m = titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        titleFrame.m:SetPoint("LEFT", 9, 0)
        titleFrame.m:SetText("Flight Timer Bug Report")
        titleFrame.m:SetFont(titleFrame.m:GetFont(), 16, nil)

        -- Add right-click to close message
        titleFrame.x = titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        titleFrame.x:SetPoint("RIGHT", -9, 0)
        titleFrame.x:SetText(L["Drag to size"] .. " | " .. L["Right-click to close"])
        titleFrame.x:SetFont(titleFrame.x:GetFont(), 16, nil)
        titleFrame.x:SetWidth(600 - titleFrame.m:GetStringWidth() - 30)
        titleFrame.x:SetWordWrap(false)
        titleFrame.x:SetJustifyH("RIGHT")

        -- local titleBox = titleFrame.EditBox
        -- titleBox:Hide()
        -- titleBox:SetEnabled(false)
        -- titleBox:SetMaxLetters(0)

        -- Drag to resize
        editFrame:SetResizable(true)
        editFrame:SetMinResize(600, 50)
        editFrame:SetMaxResize(600, 680)

        titleFrame:HookScript("OnMouseDown", function(self, btn)
            if btn == "LeftButton" then
                editFrame:StartSizing("TOP")
            end
        end)
        titleFrame:HookScript("OnMouseUp", function(self, btn)
            if btn == "LeftButton" then
                editFrame:StopMovingOrSizing()
                LeaPlusLC["RecentChatSize"] = editFrame:GetHeight()
            elseif btn == "MiddleButton" then
                -- Reset frame size
                LeaPlusLC["RecentChatSize"] = 170
                editFrame:SetSize(600, LeaPlusLC["RecentChatSize"])
                editFrame:ClearAllPoints()
                editFrame:SetPoint("BOTTOM", 0, 130)
            end
        end)

        -- Create editbox
        local editBox = editFrame.EditBox
        editBox:SetAltArrowKeyMode(false)
        editBox:SetTextInsets(10, 10, 10, 10)
        editBox:SetWidth(editFrame:GetWidth() - 50)
        -- editBox:SetSecurityDisablePaste()
        editBox:SetMaxLetters(0)

        -- Manage focus
        editBox:HookScript("OnEditFocusLost", function()
            if MouseIsOver(titleFrame) and IsMouseButtonDown("LeftButton") then
                editBox:SetFocus()
            end
        end)

        local introMsg = L["Leatrix Plus needs to be updated with the flight details.  Press CTRL/C to copy the flight details below then paste them into an email to flight@leatrix.com.  When your report is received, Leatrix Plus will be updated and you will never see this window again for this flight."] .. "|n|n"
        local startHighlight = string.len(introMsg)

        -- Define a boolean variable to keep track of the editFrame visibility
        local isNormWindowShown = false;
        local isTempWindowShown = false;



        -- Close frame with right-click of editframe or editbox
        local function CloseRecentChatWindow()
            editBox:SetText("")
            editBox:ClearFocus()
            editFrame:Hide()
        end

        editFrame:SetScript("OnMouseDown", function(self, btn)
            if btn == "RightButton" then
                CloseRecentChatWindow()
                isNormWindowShown = false;
                isTempWindowShown = false;
            end
        end)

        editBox:SetScript("OnMouseDown", function(self, btn)
            if btn == "RightButton" then
                CloseRecentChatWindow()
                isNormWindowShown = false;
                isTempWindowShown = false;
            end
        end)

        titleFrame:HookScript("OnMouseDown", function(self, btn)
            if btn == "RightButton" then
                CloseRecentChatWindow()
                isNormWindowShown = false;
                isTempWindowShown = false;
            end
        end)

        -- Disable text changes while still allowing editing controls to work
        editBox:EnableKeyboard(true)
        editBox:SetScript("OnKeyDown", function()
        end)

        --- Clear highlighted text if escape key is pressed
        editBox:HookScript("OnEscapePressed", function()
            CloseRecentChatWindow()
            isNormWindowShown = false;
            isTempWindowShown = false;
        end)

        -- Clear highlighted text and clear focus if enter key is pressed
        editBox:SetScript("OnEnterPressed", function()
            editBox:HighlightText(0, 0)
            editBox:ClearFocus()
        end)

        --===== Hide ScrollBar if window too small. =====--
        local function HideScrollBar()
            if editFrame:GetHeight() < 80 then
                scroll:Hide()
            else
                scroll:Show()
            end
        end

        editFrame:HookScript("OnSizeChanged", HideScrollBar)

        HideScrollBar()

        editFrame:SetScript("OnUpdate", function(self, elapsed)
            HideScrollBar()
        end)

        -- Load LibCandyBar
        Leatrix_Plus:LeaPlusCandyBar()

        -- Variables
        local data = Leatrix_Plus["FlightData"]
        local faction = UnitFactionGroup("player")
        local candy = LibStub("LibCandyBar-3.0")
        local texture = "Interface\\TargetingFrame\\UI-StatusBar"
        local flightFrame = CreateFrame("FRAME")
        LeaPlusLC.flightFrame = flightFrame


        -- Function to get node name
        local function GetNodeName(i)
            return strmatch(TaxiNodeName(i), "[^,]+")
        end

        --------------------------------------------------------------------------------
        -- Hook to the Flight Map Node OnClick function
        --------------------------------------------------------------------------------


        -- Show progress bar when flight is taken
        hooksecurefunc("TakeTaxiNode", function(node)

            -- FIXME: why check for no combat?
            if UnitAffectingCombat("player") then
                return
            end
            if editFrame:IsShown() then
                editFrame:Hide()
            end

            --local PLAYER_ON_TAXI = false
            LibCompat.After(0.1, function()
                local ticker
                ticker = LibCompat.NewTicker(0.1, function()

                    if UnitOnTaxi("player") then
                        -- print("ticking")
                        --PLAYER_ON_TAXI = true
                        --if PLAYER_ON_TAXI == true then print("register event") end
                    elseif not UnitOnTaxi("player") then
                        LibCompat.CancelTimer(ticker) -- stop the timer
                        --PLAYER_ON_TAXI = false
                        Leatrix_HandleFlightLanding()
                        --print("unregister event")
                        --if PLAYER_ON_TAXI == false then print("unregister event") else print("event still registered") end
                        if LeaPlusLC.FlightProgressBar then
                            LeaPlusLC.FlightProgressBar:Stop()
                            LeaPlusLC.FlightProgressBar = nil
                        end
                    end
                end)
            end)


            -- if UnitAffectingCombat("player") then return end
            -- if editFrame:IsShown() then editFrame:Hide() end
            for i = 1, NumTaxiNodes() do
                local nodeType = TaxiNodeGetType(i)
                local nodeName = GetNodeName(i)
                if nodeType == "CURRENT" then


                    -- Get current node
                    local continent = GetCurrentMapContinent()
                    local startX, startY = TaxiNodePosition(i)
                    local currentNode = string.format("%0.2f", startX) .. ":" .. string.format("%0.2f", startY)
                    -- print(currentNode)

                    -- Get destination
                    local endX, endY = TaxiNodePosition(node)
                    local destination = string.format("%0.2f", endX) .. ":" .. string.format("%0.2f", endY)

                    -- Build route string
                    local routeString = currentNode .. ":" .. destination
                    -- print("new" .. routeString)

                    -- Get destination
                    local endX, endY = TaxiNodePosition(node)
                    local destination = string.format("%0.2f", endX) .. ":" .. string.format("%0.2f", endY)
                    local barName = GetNodeName(node)

                    -- Build route string and debug string
                    local numEnterHops = GetNumRoutes(node)
                    local debugString = '["' .. currentNode
                    local routeString = currentNode

                    for i = 1, numEnterHops do
                        local nextHopX = TaxiGetDestX(node, i)
                        local nextHopY = TaxiGetDestY(node, i)
                        local hopPos = string.format("%0.2f", nextHopX) .. ":" .. string.format("%0.2f", nextHopY)

                        local fpName = TaxiNodeName(i)

                        debugString = debugString .. ":" .. hopPos
                        routeString = routeString .. ":" .. hopPos
                    end
                    -- print(routeString .. destination)
                    -- If route string does not contain destination, add it to the end (such as Altar of Sha'tar)
                    if not string.find(routeString, destination) then
                        -- print(routeString .. "and" .. destination)
                        debugString = debugString .. ":" .. destination
                        routeString = routeString .. ":" .. destination
                    end
                    debugString = debugString .. '"] = '

                    local debugOnenumEnterHops = (GetNumRoutes(node) - 1)

                    -- Add node names to debug string
                    debugString = debugString .. " -- " .. nodeName

                    -- If debug string does not contain destination, add it to the end
                    if not string.find(debugString, barName) then
                        debugString = debugString .. ", " .. barName .. " with " .. debugOnenumEnterHops .. " hops"
                    end

                    -- Print debug string (used for showing full routes for nodes)
                    --print(debugString)


                    -- Handle flight time not correct or flight does not exist in database
                    local timeStart = GetTime()
                    LibCompat.After(0.2, function()
                        if UnitOnTaxi("player") then
                            -- Player is on a taxi so register when taxi lands
                            -- flightFrame:RegisterEvent("PLAYER_CONTROL_GAINED")
                            --if PLAYER_ON_TAXI == true then print("unit is on taxi") else PLAYER_ON_TAXI = false end

                        else
                            -- Player is not on a taxi so delete the flight progress bar
                            -- flightFrame:UnregisterEvent("PLAYER_CONTROL_GAINED")
                            if LeaPlusLC.FlightProgressBar then
                                LeaPlusLC.FlightProgressBar:Stop()
                                LeaPlusLC.FlightProgressBar = nil
                                --PLAYER_ON_TAXI = false
                            end

                        end
                    end)

                    function Leatrix_HandleFlightLanding()
                        --print("debug report script fire")
                        local timeEnd = GetTime()
                        local timeTaken = timeEnd - timeStart
                        debugString = gsub(debugString, "TimeTakenPlaceHolder", string.format("%0.0f", timeTaken))
                        local flightMsg = L["Flight details"] .. " (" .. L["WRATH"] .. "): " .. nodeName .. " (" .. currentNode .. ") " .. L["to"] .. " " .. barName .. " (" .. destination .. ") (" .. faction .. ") " .. L["took"] .. " " .. string.format("%0.0f", timeTaken) .. " " .. L["seconds"] .. " (" .. debugOnenumEnterHops .. " " .. L["hop"] .. ").|n|n" .. debugString .. "|n|n"
                        if destination and data[faction] and data[faction][continent] and data[faction][continent][routeString] then
                            local savedDuration = data[faction][continent][routeString]
                            if savedDuration then
                                if timeTaken > (savedDuration + timeBuffer) or timeTaken < (savedDuration - timeBuffer) then
                                    local editMsg = introMsg .. flightMsg .. L["This flight's actual time of"] .. " " .. string.format("%0.0f", timeTaken) .. " " .. L["seconds does not match the saved flight time of"] .. " " .. savedDuration .. " " .. L["seconds"] .. "."
                                    editBox:SetText(editMsg);
                                    if LeaPlusLC["FlightBarContribute"] == "On" then
                                        editFrame:Show()
                                    end
                                end
                            else
                                local editMsg = introMsg .. flightMsg .. L["This flight does not have a saved duration in the database."]
                                editBox:SetText(editMsg);
                                if LeaPlusLC["FlightBarContribute"] == "On" then
                                    editFrame:Show()
                                end
                            end
                        else
                            local editMsg = introMsg .. flightMsg .. L["This flight does not exist in the database."]
                            editBox:SetText(editMsg);
                            if LeaPlusLC["FlightBarContribute"] == "On" then
                                editFrame:Show()
                            end
                        end
                        -- flightFrame:UnregisterEvent("PLAYER_MONEY")

                        -- Delete the progress bar since we have landed
                        if LeaPlusLC.FlightProgressBar then
                            LeaPlusLC.FlightProgressBar:Stop()
                            LeaPlusLC.FlightProgressBar = nil
                        end
                    end

                    -- Show flight progress bar if flight exists in database
                    if data[faction] and data[faction][continent] and data[faction][continent][routeString] then

                        local duration = data[faction][continent][routeString]
                        if duration then

                            -- Delete an existing progress bar if one exists
                            if LeaPlusLC.FlightProgressBar then
                                LeaPlusLC.FlightProgressBar:Stop()
                                LeaPlusLC.FlightProgressBar = nil
                            end

                            -- Create progress bar
                            local mybar = candy:New(texture, 230, 16)
                            mybar:SetPoint(LeaPlusLC["FlightBarA"], UIParent, LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"])
                            mybar:SetScale(LeaPlusLC["FlightBarScale"])
                            mybar:SetWidth(LeaPlusLC["FlightBarWidth"])

                            if faction == "Alliance" then
                                mybar:SetColor(0, 0.5, 1, 0.5)
                            else
                                mybar:SetColor(1, 0.0, 0, 0.5)
                            end
                            mybar:SetShadowColor(0, 0, 0, 0.5)

                            mybar:SetScript("OnMouseDown", function(self, btn)
                                if btn == "RightButton" then
                                    mybar:Stop()
                                    LeaPlusLC.FlightProgressBar = nil
                                end
                            end)

                            -- Set bar label width
                            -- barName = "SupercalifragilisticexpialidociousDociousaliexpisticfragicalirupus" -- Debug
                            mybar.candyBarLabel:ClearAllPoints()
                            mybar.candyBarLabel:SetPoint("TOPLEFT", mybar.candyBarBackground, "TOPLEFT", 2, 0)
                            mybar.candyBarLabel:SetPoint("BOTTOMRIGHT", mybar.candyBarBackground, "BOTTOMRIGHT", -40, 0)

                            -- Set flight bar background
                            if LeaPlusLC["FlightBarBackground"] == "On" then
                                if LeaPlusLC.ElvUI then
                                    _G.LeaPlusGlobalFlightBar = mybar.candyBarBar
                                    if faction == "Alliance" then
                                        LeaPlusLC.ElvUI:GetModule("Skins"):HandleStatusBar(_G.LeaPlusGlobalFlightBar, { 0, 0.5, 1, 0.5 })
                                    else
                                        LeaPlusLC.ElvUI:GetModule("Skins"):HandleStatusBar(_G.LeaPlusGlobalFlightBar, { 1, 0.0, 0, 0.5 })
                                    end
                                else
                                    mybar:SetTexture(texture)
                                end
                            else
                                mybar:SetTexture("")
                            end

                            -- Set flight bar destination
                            if LeaPlusLC["FlightBarDestination"] == "On" then
                                mybar:SetLabel(barName)
                            end

                            -- Set flight bar fill mode
                            if LeaPlusLC["FlightBarFillBar"] == "On" then
                                mybar:SetFill(true)
                            else
                                mybar:SetFill(false)
                            end

                            mybar:EnableMouse(false)
                            mybar:SetDuration(duration)
                            mybar:Start()

                            -- Unlock close bar button
                            if LeaPlusCB["CloseFlightBarButton"] then
                                LeaPlusLC:LockItem(LeaPlusCB["CloseFlightBarButton"], false)
                            end

                            -- Assign file level scope to the bar so it can be cancelled later
                            LeaPlusLC.FlightProgressBar = mybar

                        end

                    end

                end
            end
        end)

        -- Function to stop the progress bar
        local function CeaseProgress()
            if LeaPlusLC.FlightProgressBar then
                LeaPlusLC.FlightProgressBar:Stop()
                LeaPlusLC.FlightProgressBar = nil
            end
        end

        -- Stop the progress bar under various circumstances
        -- hooksecurefunc("TaxiRequestEarlyLanding", CeaseProgress)
        hooksecurefunc("AcceptBattlefieldPort", CeaseProgress)
        hooksecurefunc("ConfirmSummon", CeaseProgress)

        -- Function to get node name
        local function GetNodeName(i)
            return strmatch(TaxiNodeName(i), "[^,]+")
        end

        -- hooksecurefunc("TakeTaxiNode", function(node)
        --   for i = 1, NumTaxiNodes() do
        --     local nodeType = TaxiNodeGetType(i)
        --     local nodeName = GetNodeName(i)
        --     if nodeType == "CURRENT" then


        --       -- Get current node
        --       local continent = GetCurrentMapContinent()
        --       local startX, startY = TaxiNodePosition(i)
        --       local currentNode = string.format("%0.2f", startX) .. ":" .. string.format("%0.2f", startY)
        --       -- print(currentNode)

        --       -- Get destination
        --       local endX, endY = TaxiNodePosition(node)
        --       local destination = string.format("%0.2f", endX) .. ":" .. string.format("%0.2f", endY)

        --       -- Build route string
        --       local routeString = currentNode .. ":" .. destination
        --       -- print("new" .. routeString)


        -- 		-- Show flight time in tooltip if it exists
        -- 		if data[faction] and data[faction][continent] and data[faction][continent][routeString] then
        -- 			local duration = data[faction][continent][routeString]
        -- 			if duration and type(duration) == "number" then
        -- 				duration = date("%M:%S", duration):gsub("^0","")
        -- 				print(duration)
        -- 			end
        -- 		elseif currentNode ~= destination then
        -- 			print("no destination")
        -- 		end
        --       end
        --     end

        -- end)

        --------------------------------------------------------------------------------
        -- Hook to the Node OnEnter blizzard func.
        --------------------------------------------------------------------------------



        -- Show flight time in node tooltips
        hooksecurefunc("TaxiNodeOnButtonEnter", function(button)
            local index = button:GetID()
            for i = 1, NumTaxiNodes() do
                local nodeType = TaxiNodeGetType(i)
                local nodeName = GetNodeName(i)
                if nodeType == "CURRENT" then

                    -- Get current node
                    local continent = GetCurrentMapContinent()
                    local startX, startY = TaxiNodePosition(i)
                    local currentNode = string.format("%0.2f", startX) .. ":" .. string.format("%0.2f", startY)

                    -- Get destination
                    local endX, endY = TaxiNodePosition(index)
                    local destination = string.format("%0.2f", endX) .. ":" .. string.format("%0.2f", endY)
                    local barName = GetNodeName(index)

                    -- Build route string and debug string
                    local numEnterHops = GetNumRoutes(index)
                    --local debugString = '["' .. currentNode
                    local debugString = '"' .. currentNode
                    local debugChatString = '["' .. currentNode
                    local routeString = currentNode
                    for i = 1, numEnterHops do
                        local nextHopX = TaxiGetDestX(index, i)
                        local nextHopY = TaxiGetDestY(index, i)
                        local hopPos = string.format("%0.2f", nextHopX) .. ":" .. string.format("%0.2f", nextHopY)

                        local fpName = TaxiNodeName(i)

                        -- Find comma index
                        -- local commaIndex = fpName:find(", ")

                        -- -- Get first word
                        -- local firstWord = fpName:sub(1, commaIndex - 1)
                        -- fpName = firstWord

                        -- print(fpName)


                        debugString = debugString .. ":" .. hopPos
                        debugChatString = debugChatString .. ":" .. hopPos
                        routeString = routeString .. ":" .. hopPos
                    end
                    -- print(routeString .. destination)
                    -- If route string does not contain destination, add it to the end (such as Altar of Sha'tar)
                    if not string.find(routeString, destination) then
                        -- print(routeString .. "and" .. destination)
                        debugString = debugString .. ":" .. destination
                        debugChatString = debugString .. ":" .. destination
                        routeString = routeString .. ":" .. destination
                    end
                    --debugString = debugString .. '"] = '
                    --debugString = debugString .. '"]'
                    debugString = debugString .. '"'

                    debugChatString = debugChatString .. '"] = '



                    -- Show flight time in tooltip if it exists
                    if data[faction] and data[faction][continent] and data[faction][continent][routeString] then
                        local duration = data[faction][continent][routeString]
                        if duration and type(duration) == "number" then
                            duration = date("%M:%S", duration):gsub("^0", "")
                            GameTooltip:AddLine(L["Duration"] .. ": " .. duration, 0.9, 0.9, 0.9, true)
                            GameTooltip:Show()
                        end
                    elseif currentNode ~= destination then
                        GameTooltip:AddLine(L["Duration"] .. ": -:--", 0.9, 0.9, 0.9, true)
                        GameTooltip:Show()
                    end

                    local debugTwonumEnterHops = (GetNumRoutes(index) - 1)

                    -- Add node names to debug string
                    --debugString = debugString .. " -- " .. nodeName
                    debugString = debugString
                    debugChatString = debugChatString .. " -- " .. nodeName

                    -- for i = 20, numEnterHops do
                    -- 	local fpName = TaxiNodeName(i)

                    --     -- Find comma index
                    --     local commaIndex = fpName:find(", ")

                    --     -- Get first word
                    --     local firstWord = fpName:sub(1, commaIndex - 1)
                    --     fpName = firstWord
                    -- 	debugString = debugString .. ", " .. fpName
                    -- end

                    -- If debug string does not contain destination, add it to the end
                    if not string.find(debugString, barName) then
                        --debugString = debugString .. ", " .. barName .. " with " .. debugTwonumEnterHops .. " hops"
                        debugString = debugString
                        debugChatString = debugChatString .. ", " .. barName .. " with " .. debugTwonumEnterHops .. " hops"

                    end

                    -- Print debug string (used for showing full routes for nodes)
                    -- Clear chat for easier working with data. FIXME REMOVEME before release IMPORTANT
                    --for i = 1, NUM_CHAT_WINDOWS do _G["ChatFrame"..i]:Clear() end
                    ----print(debugChatString)
                    --
                    ---- Open the chat edit box, pre-fill with debugString, and highlight the text for easy copying
                    --local defaultChatFrame = DEFAULT_CHAT_FRAME
                    --if defaultChatFrame then
                    --	ChatFrame_OpenChat(debugString, defaultChatFrame)
                    --	local editBox = ChatFrame1EditBox
                    --	if editBox then
                    --		LibCompat.After(0.1, function() editBox:HighlightText()  end)
                    --	end
                    --end

                end
            end
        end)

        -- FIXME 3.3.5
        -- Unregister landing event for various reasons that stop taxi early
        local function StopLandingEvent()
            if editFrame:IsShown() then
                editFrame:Hide()
            end
            if LeaPlusLC.FlightProgressBar then
                LeaPlusLC.FlightProgressBar:Stop()
                LeaPlusLC.FlightProgressBar = nil
            end
        end

        hooksecurefunc("TaxiNodeOnButtonEnter", StopLandingEvent)
        -- hooksecurefunc("TaxiRequestEarlyLanding", StopLandingEvent)
        hooksecurefunc("AcceptBattlefieldPort", StopLandingEvent)
        hooksecurefunc("ConfirmSummon", StopLandingEvent)

        ----------------------------------------------------------------------
        -- Drag frame
        ----------------------------------------------------------------------

        -- Create drag frame
        local tempFrame = CreateFrame("FRAME", nil, UIParent)
        tempFrame:SetWidth(230)
        tempFrame:SetHeight(16)
        tempFrame:SetScale(2)
        tempFrame:ClearAllPoints()
        tempFrame:SetPoint(LeaPlusLC["FlightBarA"], UIParent, LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"])
        tempFrame:Hide()
        tempFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        tempFrame:SetFrameLevel(5000)
        tempFrame:SetClampedToScreen(false)

        -- Create texture
        tempFrame.t = tempFrame:CreateTexture(nil, "BORDER")
        tempFrame.t:SetAllPoints()
        tempFrame.t:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        tempFrame.t:SetVertexColor(0.0, 1.0, 0.0, 0.5)

        -- Enable movement
        tempFrame:EnableMouse(true)
        tempFrame:SetMovable(true)
        tempFrame:SetScript("OnMouseDown", function()
            tempFrame:StartMoving()
        end)
        tempFrame:SetScript("OnMouseUp", function()
            tempFrame:StopMovingOrSizing()
            LeaPlusLC["FlightBarA"], void, LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"] = tempFrame:GetPoint()
            -- Position actual flight progress bar if one exists
            if LeaPlusLC.FlightProgressBar then
                LeaPlusLC.FlightProgressBar:ClearAllPoints()
                LeaPlusLC.FlightProgressBar:SetPoint(LeaPlusLC["FlightBarA"], UIParent, LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"])
            end
        end)

        ----------------------------------------------------------------------
        -- Configuration panel
        ----------------------------------------------------------------------

        -- Create configuration panel
        local FlightPanel = LeaPlusLC:CreatePanel("Show flight times", "FlightPanel")

        LeaPlusLC:MakeTx(FlightPanel, "Settings", 16, -72)
        LeaPlusLC:MakeCB(FlightPanel, "FlightBarBackground", "Show background", 16, -92, false, "If checked, the flight progress bar background texture will be shown.")
        LeaPlusLC:MakeCB(FlightPanel, "FlightBarDestination", "Show destination", 16, -112, false, "If checked, the flight progress bar destination will be shown.")
        LeaPlusLC:MakeCB(FlightPanel, "FlightBarFillBar", "Fill instead of drain", 16, -132, false, "If checked, the flight progress bar background will fill instead of drain.")
        --LeaPlusLC:MakeCB(FlightPanel, "FlightBarSpeech", "Speak the remaining time", 16, -152, false, "If checked, the remaining flight time will be spoken using text to speech.|n|nChanges to this setting will take effect on the next flight you take.")

        LeaPlusLC:MakeTx(FlightPanel, "Contribute", 16, -192)
        LeaPlusLC:MakeCB(FlightPanel, "FlightBarContribute", "Help contribute flight times", 16, -212, false, "If checked, you will be prompted to submit missing flight times.")

        LeaPlusLC:MakeTx(FlightPanel, "Scale", 356, -72)
        LeaPlusLC:MakeSL(FlightPanel, "FlightBarScale", "Drag to set the flight progress bar scale.", 1, 5, 0.1, 356, -92, "%.2f")

        LeaPlusLC:MakeTx(FlightPanel, "Width", 356, -132)
        LeaPlusLC:MakeSL(FlightPanel, "FlightBarWidth", "Drag to set the flight progress bar width.", 40, 460, 10, 356, -152, "%.0f")

        -- Add close bar button
        local CloseFlightBarButton = LeaPlusLC:CreateButton("CloseFlightBarButton", FlightPanel, "Close Bar", "TOPLEFT", 16, -72, 0, 25, true, "Click to close the currently active flight progress bar.")
        LeaPlusCB["CloseFlightBarButton"]:ClearAllPoints()
        LeaPlusCB["CloseFlightBarButton"]:SetPoint("LEFT", FlightPanel.h, "RIGHT", 10, 0)
        LeaPlusCB["CloseFlightBarButton"]:SetScript("OnClick", function()
            if LeaPlusLC.FlightProgressBar then
                LeaPlusLC.FlightProgressBar:Stop()
                LeaPlusLC.FlightProgressBar = nil
            end
        end)

        -- Lock close bar button at startup and when flight progress bar stops
        LeaPlusLC:LockItem(LeaPlusCB["CloseFlightBarButton"], true)
        candy.RegisterCallback(LeaPlusLC, "LibCandyBar_Stop", function()
            if LeaPlusCB["CloseFlightBarButton"] then
                LeaPlusLC:LockItem(LeaPlusCB["CloseFlightBarButton"], true)
            end
        end)

        -- Set progress bar background
        if LeaPlusLC.ElvUI then

            -- Progress bar background is always enabled and cannot be disabled with ElvUI
            LeaPlusLC:LockItem(LeaPlusCB["FlightBarBackground"], true)
            LeaPlusLC["FlightBarBackground"] = "On"
            LeaPlusCB["FlightBarBackground"].tiptext = LeaPlusCB["FlightBarBackground"].tiptext .. "|n|n|cff00AAFF" .. L["The background is always shown with ElvUI."]

        else

            -- Set progress bar background
            local function SetProgressBarBackground()
                if LeaPlusLC.FlightProgressBar then
                    if LeaPlusLC["FlightBarBackground"] == "On" then
                        LeaPlusLC.FlightProgressBar:SetTexture(texture)
                    else
                        LeaPlusLC.FlightProgressBar:SetTexture("")
                    end
                end
            end

            -- Set progress bar background when option is clicked and on startup
            LeaPlusCB["FlightBarBackground"]:HookScript("OnClick", SetProgressBarBackground)
            SetProgressBarBackground()

        end

        -- Set progress bar fill mode
        local function SetProgressBarFillMode()
            if LeaPlusLC.FlightProgressBar then
                if LeaPlusLC["FlightBarFillBar"] == "On" then
                    LeaPlusLC.FlightProgressBar:SetFill(true)
                else
                    LeaPlusLC.FlightProgressBar:SetFill(false)
                end
            end
        end

        -- Set progress bar fill mode when option is clicked and on startup
        LeaPlusCB["FlightBarFillBar"]:HookScript("OnClick", SetProgressBarFillMode)
        SetProgressBarFillMode()

        -- Set progress bar destination
        local function SetProgressBarDestination()
            if LeaPlusLC.FlightProgressBar then
                if LeaPlusLC["FlightBarDestination"] == "On" then
                    if LeaPlusLC.FlightDestination then
                        LeaPlusLC.FlightProgressBar:SetLabel(LeaPlusLC.FlightDestination)
                    end
                else
                    LeaPlusLC.FlightProgressBar:SetLabel("")
                end
            end
        end

        -- Set flight bar destination when option is clicked and on startup
        LeaPlusCB["FlightBarDestination"]:HookScript("OnClick", SetProgressBarDestination)
        SetProgressBarDestination()

        -- Flight progress bar scale
        local function SetFlightBarScale()
            tempFrame:SetScale(LeaPlusLC["FlightBarScale"])
            if LeaPlusLC.FlightProgressBar then
                LeaPlusLC.FlightProgressBar:SetScale(LeaPlusLC["FlightBarScale"])
            end
            -- Set slider formatted text
            LeaPlusCB["FlightBarScale"].f:SetFormattedText("%.0f%%", (LeaPlusLC["FlightBarScale"] / 2) * 100)
        end

        -- Set flight bar scale when slider is changed and on startup
        LeaPlusCB["FlightBarScale"]:HookScript("OnValueChanged", SetFlightBarScale)
        SetFlightBarScale()

        -- Flight progress bar width
        local function SetFlightBarWidth()
            tempFrame:SetWidth(LeaPlusLC["FlightBarWidth"])
            if LeaPlusLC.FlightProgressBar then
                LeaPlusLC.FlightProgressBar:SetWidth(LeaPlusLC["FlightBarWidth"])
            end
            -- Set slider formatted text
            LeaPlusCB["FlightBarWidth"].f:SetFormattedText("%.0f%%", (LeaPlusLC["FlightBarWidth"] / 230) * 100)
        end

        -- Set flight bar width when slider is changed and on startup
        LeaPlusCB["FlightBarWidth"]:HookScript("OnValueChanged", SetFlightBarWidth)
        SetFlightBarWidth()

        -- Help button tooltip
        FlightPanel.h.tiptext = L["Drag the frame overlay to position the frame."]

        -- Back button handler
        FlightPanel.b:SetScript("OnClick", function()
            FlightPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page5"]:Show()
            return
        end)

        -- Reset button handler
        FlightPanel.r:SetScript("OnClick", function()

            -- Reset controls
            LeaPlusLC["FlightBarA"], LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"] = "TOP", "TOP", 0, -66
            tempFrame:ClearAllPoints()
            tempFrame:SetPoint(LeaPlusLC["FlightBarA"], UIParent, LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"])
            -- Reset scale
            LeaPlusLC["FlightBarScale"] = 2
            tempFrame:SetScale(LeaPlusLC["FlightBarScale"])
            -- Reset width
            LeaPlusLC["FlightBarWidth"] = 230
            tempFrame:SetWidth(LeaPlusLC["FlightBarWidth"])
            -- Reset checkboxes
            LeaPlusLC["FlightBarBackground"] = "On"
            LeaPlusLC["FlightBarDestination"] = "On"
            LeaPlusLC["FlightBarFillBar"] = "Off";
            SetProgressBarFillMode()
            LeaPlusLC["FlightBarSpeech"] = "Off"
            LeaPlusLC["FlightBarContribute"] = "Off"
            -- Reset live progress bar
            if LeaPlusLC.FlightProgressBar then
                -- Reset position
                LeaPlusLC.FlightProgressBar:ClearAllPoints()
                LeaPlusLC.FlightProgressBar:SetPoint(LeaPlusLC["FlightBarA"], UIParent, LeaPlusLC["FlightBarR"], LeaPlusLC["FlightBarX"], LeaPlusLC["FlightBarY"])
                LeaPlusLC.FlightProgressBar:SetScale(LeaPlusLC["FlightBarScale"])
                -- Reset width
                LeaPlusLC.FlightProgressBar:SetWidth(LeaPlusLC["FlightBarWidth"])
                -- Reset background
                LeaPlusLC.FlightProgressBar:SetTexture(texture)
                -- Reset destination
                if LeaPlusLC.FlightDestination then
                    LeaPlusLC.FlightProgressBar:SetLabel(LeaPlusLC.FlightDestination)
                end
            end

            -- Refresh configuration panel
            FlightPanel:Hide();
            FlightPanel:Show()

        end)

        -- Show configuration panal when options panel button is clicked
        LeaPlusCB["ShowFlightTimesBtn"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["FlightBarContribute"] = "Off"
            else
                FlightPanel:Show()
                LeaPlusLC:HideFrames()
            end
        end)

        -- Toggle drag frame with configuration panel
        FlightPanel:HookScript("OnShow", function()
            tempFrame:Show()
        end)

        FlightPanel:HookScript("OnHide", function()
            tempFrame:Hide()
        end)

    end

    ----------------------------------------------------------------------
    -- Filter chat messages
    ----------------------------------------------------------------------

    if LeaPlusLC["FilterChatMessages"] == "On" then

        -- -- Load LibChatAnims
        -- Leatrix_Plus:LeaPlusLCA()

        -- Create configuration panel
        local ChatFilterPanel = LeaPlusLC:CreatePanel("Filter chat messages", "ChatFilterPanel")

        LeaPlusLC:MakeTx(ChatFilterPanel, "Settings", 16, -72)
        LeaPlusLC:MakeCB(ChatFilterPanel, "BlockSpellLinks", "Block spell links during combat", 16, -92, false, "If checked, messages containing spell links will be blocked while you are in combat.|n|nThis is useful for blocking spell interrupt spam.|n|nThis applies to the say, party, raid, emote and yell channels.")
        LeaPlusLC:MakeCB(ChatFilterPanel, "BlockDrunkenSpam", "Block drunken spam", 16, -112, false, "If checked, drunken messages will be blocked unless they apply to your character.|n|nThis applies to the system channel.")
        LeaPlusLC:MakeCB(ChatFilterPanel, "BlockDuelSpam", "Block duel spam", 16, -132, false, "If checked, duel victory and retreat messages will be blocked unless your character took part in the duel.|n|nThis applies to the system channel.")

        -- Lock block drunken spam option for zhTW
        if GameLocale == "zhTW" then
            LeaPlusLC:LockItem(LeaPlusCB["BlockDrunkenSpam"], true)
            LeaPlusLC["BlockDrunkenSpam"] = "Off"
            LeaPlusDB["BlockDrunkenSpam"] = "Off"
            LeaPlusCB["BlockDrunkenSpam"].tiptext = LeaPlusCB["BlockDrunkenSpam"].tiptext .. "|n|n|cff00AAFF" .. L["Cannot use this with your locale."]
        end

        -- Help button hidden
        ChatFilterPanel.h:Hide()

        -- Back button handler
        ChatFilterPanel.b:SetScript("OnClick", function()
            ChatFilterPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page3"]:Show()
            return
        end)

        local charName = GetUnitName("player")
        local charRealm = GetRealmName()
        local nameRealm = charName .. "%%-" .. charRealm

        -- Chat filter
        local function ChatFilterFunc(self, event, msg)
            -- Block duel spam
            if LeaPlusLC["BlockDuelSpam"] == "On" then
                -- Block duel messages unless you are part of the duel
                if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", "%.+"):gsub("%%2$s", "%.+")) or msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", "%.+"):gsub("%%2$s", "%.+")) then
                    -- Player has defeated player in a duel.
                    if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", charName):gsub("%%2$s", "%.+")) then
                        return false
                    end
                    if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", nameRealm):gsub("%%2$s", "%.+")) then
                        return false
                    end
                    if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", "%.+"):gsub("%%2$s", charName)) then
                        return false
                    end
                    if msg:match(DUEL_WINNER_KNOCKOUT:gsub("%%1$s", "%.+"):gsub("%%2$s", nameRealm)) then
                        return false
                    end
                    -- Player has fled from player in a duel.
                    if msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", charName):gsub("%%2$s", "%.+")) then
                        return false
                    end
                    if msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", nameRealm):gsub("%%2$s", "%.+")) then
                        return false
                    end
                    if msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", "%.+"):gsub("%%2$s", charName)) then
                        return false
                    end
                    if msg:match(DUEL_WINNER_RETREAT:gsub("%%1$s", "%.+"):gsub("%%2$s", nameRealm)) then
                        return false
                    end
                    -- Block all duel messages not involving player
                    return true
                end
            end
            -- Block spell links
            if LeaPlusLC["BlockSpellLinks"] == "On" and UnitAffectingCombat("player") then
                if msg:find("|Hspell") then
                    return true
                end
            end
            -- Block drunken spam
            if LeaPlusLC["BlockDrunkenSpam"] == "On" then
                for i = 1, 4 do
                    local drunk1 = _G["DRUNK_MESSAGE_ITEM_OTHER" .. i]:gsub("%%s", "%s-")
                    local drunk2 = _G["DRUNK_MESSAGE_OTHER" .. i]:gsub("%%s", "%s-")
                    if msg:match(drunk1) or msg:match(drunk2) then
                        return true
                    end
                end
            end
        end

        -- Enable or disable chat filter settings
        local function SetChatFilter()
            if LeaPlusLC["BlockSpellLinks"] == "On" then
                ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", ChatFilterFunc)
                ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", ChatFilterFunc)
                ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", ChatFilterFunc)
                ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", ChatFilterFunc)
                ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", ChatFilterFunc)
                ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", ChatFilterFunc)
                ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", ChatFilterFunc)
            else
                ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SAY", ChatFilterFunc)
                ChatFrame_RemoveMessageEventFilter("CHAT_MSG_PARTY", ChatFilterFunc)
                ChatFrame_RemoveMessageEventFilter("CHAT_MSG_PARTY_LEADER", ChatFilterFunc)
                ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID", ChatFilterFunc)
                ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID_LEADER", ChatFilterFunc)
                ChatFrame_RemoveMessageEventFilter("CHAT_MSG_EMOTE", ChatFilterFunc)
                ChatFrame_RemoveMessageEventFilter("CHAT_MSG_YELL", ChatFilterFunc)
            end
            if LeaPlusLC["BlockDrunkenSpam"] == "On" or LeaPlusLC["BlockDuelSpam"] == "On" then
                ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilterFunc)
            else
                ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilterFunc)
            end
        end

        -- Set chat filter when settings are clicked and on startup
        LeaPlusCB["BlockSpellLinks"]:HookScript("OnClick", SetChatFilter)
        LeaPlusCB["BlockDrunkenSpam"]:HookScript("OnClick", SetChatFilter)
        LeaPlusCB["BlockDuelSpam"]:HookScript("OnClick", SetChatFilter)
        SetChatFilter()

        -- Reset button handler
        ChatFilterPanel.r:SetScript("OnClick", function()

            -- Reset controls
            LeaPlusLC["BlockSpellLinks"] = "Off"
            LeaPlusLC["BlockDrunkenSpam"] = "Off"
            LeaPlusLC["BlockDuelSpam"] = "Off"
            SetChatFilter()

            -- Refresh configuration panel
            ChatFilterPanel:Hide();
            ChatFilterPanel:Show()

        end)

        -- Show configuration panal when options panel button is clicked
        LeaPlusCB["FilterChatMessagesBtn"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["BlockSpellLinks"] = "On"
                LeaPlusLC["BlockDrunkenSpam"] = "On"
                LeaPlusLC["BlockDuelSpam"] = "On"
                SetChatFilter()
            else
                ChatFilterPanel:Show()
                LeaPlusLC:HideFrames()
            end
        end)

    end

    ----------------------------------------------------------------------
    -- Automatically accept resurrection requests (no reload required)
    ----------------------------------------------------------------------

    do

        -- Create configuration panel
        local AcceptResPanel = LeaPlusLC:CreatePanel("Accept resurrection", "AcceptResPanel")

        LeaPlusLC:MakeTx(AcceptResPanel, "Settings", 16, -72)
        LeaPlusLC:MakeCB(AcceptResPanel, "AutoResNoCombat", "Exclude combat resurrection", 16, -92, false, "If checked, resurrection requests will not be automatically accepted if the player resurrecting you is in combat.")

        -- Help button hidden
        AcceptResPanel.h:Hide()

        -- Back button handler
        AcceptResPanel.b:SetScript("OnClick", function()
            AcceptResPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page1"]:Show();
            return
        end)

        -- Reset button handler
        AcceptResPanel.r:SetScript("OnClick", function()

            -- Reset checkboxes
            LeaPlusLC["AutoResNoCombat"] = "On"

            -- Refresh panel
            AcceptResPanel:Hide();
            AcceptResPanel:Show()

        end)

        -- Show panal when options panel button is clicked
        LeaPlusCB["AutoAcceptResBtn"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["AutoResNoCombat"] = "On"
            else
                AcceptResPanel:Show()
                LeaPlusLC:HideFrames()
            end
        end)

        -- Function to set resurrect event
        local function SetResEvent()
            -- print("Setting resurrect event")
            if LeaPlusLC["AutoAcceptRes"] == "On" then
                AcceptResPanel:RegisterEvent("RESURRECT_REQUEST")
            else
                AcceptResPanel:UnregisterEvent("RESURRECT_REQUEST")
            end
        end

        -- Run function when option is clicked and on startup if option is enabled
        LeaPlusCB["AutoAcceptRes"]:HookScript("OnClick", function()
            -- print("AutoAcceptRes clicked")
            SetResEvent()
        end)

        if LeaPlusLC["AutoAcceptRes"] == "On" then
            SetResEvent()
        end

        -- -- Function to not accept resurrection based on certain conditions
        -- local function DoNotAcceptResurrect()
        --     print("Checking conditions to accept resurrect")
        --     local mapID = C_Map.GetBestMapForUnit("player") or nil

        --     if mapID and mapID == 162 then -- Naxxramas Construct Quarter
        --         print("In Naxxramas Construct Quarter")

        --         -- Check party or raid for debuffs
        --         local group = IsInRaid() and "raid" or "party"
        --         for i = 1, GetNumGroupMembers() do
        --             local unit = group .. i
        --             if unit and UnitExists(unit) then
        --                 for j = 1, 40 do
        --                     local void, void, void, void, void, void, void, void, void, spellID = UnitDebuff(unit, j)
        --                     if spellID then
        --                         if spellID == 28059 or spellID == 28084 then
        --                             -- Thaddius positive and negative charge debuffs
        --                             print("Resurrection not accepted. Someone in your group has a charge debuff.")
        --                             return true
        --                         end
        --                     end
        --                 end
        --             end
        --         end
        --     end
        -- end

        -- Handle event
        AcceptResPanel:SetScript("OnEvent", function(self, event, ...)
            if event == "RESURRECT_REQUEST" then
                -- print("Received resurrect request")

                -- -- Exclude Chained Spirit (Zul'Gurub)
                -- local chainLoc

                -- -- Exclude Chained Spirit (Zul'Gurub)
                -- chainLoc = "Chained Spirit"
                -- if     GameLocale == "zhCN" then chainLoc = "被禁锢的灵魂"
                -- elseif GameLocale == "zhTW" then chainLoc = "禁錮之魂"
                -- elseif GameLocale == "ruRU" then chainLoc = "Скованный дух"
                -- elseif GameLocale == "koKR" then chainLoc = "구속된 영혼"
                -- elseif GameLocale == "esMX" then chainLoc = "Espíritu encadenado"
                -- elseif GameLocale == "ptBR" then chainLoc = "Espírito Acorrentado"
                -- elseif GameLocale == "deDE" then chainLoc = "Angeketteter Geist"
                -- elseif GameLocale == "esES" then chainLoc = "Espíritu encadenado"
                -- elseif GameLocale == "frFR" then chainLoc = "Esprit enchaîné"
                -- elseif GameLocale == "itIT" then chainLoc = "Spirito Incatenato"
                -- end
                -- if arg1 == chainLoc then return    end

                -- Resurrect
                -- local resTimer = GetCorpseRecoveryDelay()
                -- if resTimer and resTimer > 0 then
                if LeaPlusLC["AutoAcceptRes"] == "On" then
                    -- Resurrect has a delay so wait before resurrecting
                    -- print("Waiting to resurrect...")
                    -- LibCompat.After(resTimer + 1, function()
                    if not LibCompat.IsGroupInCombat() or LeaPlusLC["AutoResNoCombat"] == "Off" then
                        if LeaPlusLC["AutoAcceptRes"] == "On" then
                            -- if not DoNotAcceptResurrect() then
                            -- print("Accepting resurrect...")
                            AcceptResurrect()
                            StaticPopup_Hide("RESURRECT_NO_TIMER")
                            -- end
                        end
                    end
                    -- end)
                else
                    -- Resurrect has no delay so resurrect now
                    if not LibCompat.IsGroupInCombat() or LeaPlusLC["AutoResNoCombat"] == "On" then
                        -- if not DoNotAcceptResurrect() then
                        -- print("Accepting resurrect...")
                        AcceptResurrect()
                        StaticPopup_Hide("RESURRECT_NO_TIMER")
                        -- end
                    end
                end

                return
            end
        end)


    end

    ----------------------------------------------------------------------
    -- Hide keybind text
    ----------------------------------------------------------------------

    if LeaPlusLC["HideKeybindText"] == "On" and not LeaLockList["HideKeybindText"] then

        -- Hide keybind text
        for i = 1, 12 do
            _G["ActionButton" .. i .. "HotKey"]:SetAlpha(0) -- Main bar
            _G["MultiBarBottomRightButton" .. i .. "HotKey"]:SetAlpha(0) -- Bottom right bar
            _G["MultiBarBottomLeftButton" .. i .. "HotKey"]:SetAlpha(0) -- Bottom left bar
            _G["MultiBarRightButton" .. i .. "HotKey"]:SetAlpha(0) -- Right bar
            _G["MultiBarLeftButton" .. i .. "HotKey"]:SetAlpha(0) -- Left bar
        end

    end

    ----------------------------------------------------------------------
    -- Hide macro text
    ----------------------------------------------------------------------

    if LeaPlusLC["HideMacroText"] == "On" and not LeaLockList["HideMacroText"] then

        -- Hide marco text
        for i = 1, 12 do
            _G["ActionButton" .. i .. "Name"]:SetAlpha(0) -- Main bar
            _G["MultiBarBottomRightButton" .. i .. "Name"]:SetAlpha(0) -- Bottom right bar
            _G["MultiBarBottomLeftButton" .. i .. "Name"]:SetAlpha(0) -- Bottom left bar
            _G["MultiBarRightButton" .. i .. "Name"]:SetAlpha(0) -- Right bar
            _G["MultiBarLeftButton" .. i .. "Name"]:SetAlpha(0) -- Left bar
        end

    end

    ----------------------------------------------------------------------
    -- More font sizes
    ----------------------------------------------------------------------

    if LeaPlusLC["MoreFontSizes"] == "On" and not LeaLockList["MoreFontSizes"] then
        RunScript('CHAT_FONT_HEIGHTS = {[1] = 10, [2] = 12, [3] = 14, [4] = 16, [5] = 18, [6] = 20, [7] = 22, [8] = 24, [9] = 26, [10] = 28}')
    end

    ----------------------------------------------------------------------
    -- Alt click invite
    ----------------------------------------------------------------------

    if LeaPlusLC["AltClickInv"] == "On" then
        local originSetItemRef = SetItemRef
        SetItemRef = function(link, text, button, chatFrame)
            local linkType, playerName = strsplit(":", link)
            if linkType == "player" and IsAltKeyDown() then
                InviteUnit(playerName)
                return  -- Prevent Blizzard from opening whisper
            end
            -- Otherwise do original Blizzard behavior
            originSetItemRef(link, text, button, chatFrame)
        end
    end

    ----------------------------------------------------------------------
    --	Show vanity controls (must be before Enhance dressup)
    ----------------------------------------------------------------------

    if LeaPlusLC["ShowVanityControls"] == "On" then

        -- Create checkboxes
        LeaPlusLC:MakeCB(PaperDollFrame, "ShowHelm", L["Helm"], 2, -192, false, "")
        LeaPlusLC:MakeCB(PaperDollFrame, "ShowCloak", L["Cloak"], 281, -192, false, "")
        LeaPlusCB["ShowHelm"]:SetFrameStrata("HIGH")
        LeaPlusCB["ShowCloak"]:SetFrameStrata("HIGH")

        -- Function to set vanity controls layout
        local function SetVanityControlsLayout()

            -- ElvUI_WrathArmory: Position helm and cloak checkboxes
            if LeaPlusLC.ElvUI then
                local E = LeaPlusLC.ElvUI:GetModule("ElvUI_WrathArmory", true)
                if E then
                    LeaPlusCB["ShowHelm"].f:SetText(L["H"])
                    LeaPlusCB["ShowHelm"].f:ClearAllPoints()
                    LeaPlusCB["ShowHelm"].f:SetPoint("RIGHT", LeaPlusCB["ShowHelm"], "LEFT", 4, 0)
                    LeaPlusCB["ShowHelm"]:ClearAllPoints()
                    LeaPlusCB["ShowHelm"]:SetPoint("BOTTOMLEFT", CharacterFrame, "BOTTOMLEFT", 80, 110)
                    LeaPlusCB["ShowHelm"]:SetHitRectInsets(-LeaPlusCB["ShowHelm"].f:GetStringWidth() + 4, 3, 0, 0)
                    LeaPlusCB["ShowCloak"].f:SetText(L["C"])
                    LeaPlusCB["ShowCloak"].f:ClearAllPoints()
                    LeaPlusCB["ShowCloak"].f:SetPoint("RIGHT", LeaPlusCB["ShowCloak"], "LEFT", 4, 0)
                    LeaPlusCB["ShowCloak"]:ClearAllPoints()
                    LeaPlusCB["ShowCloak"]:SetPoint("LEFT", LeaPlusCB["ShowHelm"], "RIGHT", 4, 0)
                    LeaPlusCB["ShowCloak"]:SetHitRectInsets(-LeaPlusCB["ShowCloak"].f:GetStringWidth() + 4, 3, 0, 0)
                    return
                end
            end

            -- Position helm and cloak checkboxes
            if LeaPlusLC["VanityAltLayout"] == "On" then
                -- Alternative layout
                LeaPlusCB["ShowHelm"].f:SetText(L["H"])
                LeaPlusCB["ShowHelm"]:ClearAllPoints()
                LeaPlusCB["ShowHelm"]:SetPoint("TOPLEFT", 275, -224)
                LeaPlusCB["ShowHelm"]:SetHitRectInsets(-LeaPlusCB["ShowHelm"].f:GetStringWidth() + 4, 3, 0, 0)
                LeaPlusCB["ShowHelm"].f:ClearAllPoints()
                LeaPlusCB["ShowHelm"].f:SetPoint("RIGHT", LeaPlusCB["ShowHelm"], "LEFT", 4, 0)

                LeaPlusCB["ShowCloak"].f:SetText(L["C"])
                LeaPlusCB["ShowCloak"]:ClearAllPoints()
                LeaPlusCB["ShowCloak"]:SetPoint("TOP", LeaPlusCB["ShowHelm"], "BOTTOM", 0, 6)
                LeaPlusCB["ShowCloak"].f:ClearAllPoints()
                LeaPlusCB["ShowCloak"].f:SetPoint("RIGHT", LeaPlusCB["ShowCloak"], "LEFT", 4, 0)
                LeaPlusCB["ShowCloak"]:SetHitRectInsets(-LeaPlusCB["ShowCloak"].f:GetStringWidth() + 4, 3, 0, 0)
            else
                -- Default layout
                LeaPlusCB["ShowHelm"].f:SetText(L["Helm"])
                LeaPlusCB["ShowHelm"]:ClearAllPoints()
                LeaPlusCB["ShowHelm"]:SetPoint("TOPLEFT", 65, -246)
                LeaPlusCB["ShowHelm"]:SetHitRectInsets(3, -LeaPlusCB["ShowHelm"].f:GetStringWidth(), 0, 0)
                LeaPlusCB["ShowHelm"].f:ClearAllPoints()
                LeaPlusCB["ShowHelm"].f:SetPoint("LEFT", LeaPlusCB["ShowHelm"], "RIGHT", 0, 0)

                LeaPlusCB["ShowCloak"].f:SetText(L["Cloak"])
                LeaPlusCB["ShowCloak"]:ClearAllPoints()
                LeaPlusCB["ShowCloak"]:SetPoint("TOPLEFT", 275, -246)
                LeaPlusCB["ShowCloak"]:SetHitRectInsets(-LeaPlusCB["ShowCloak"].f:GetStringWidth(), 3, 0, 0)
                LeaPlusCB["ShowCloak"].f:ClearAllPoints()
                LeaPlusCB["ShowCloak"].f:SetPoint("RIGHT", LeaPlusCB["ShowCloak"], "LEFT", 0, 0)
            end
        end

        -- Set position when controls are shift/right-clicked
        LeaPlusCB["ShowHelm"]:SetScript('OnMouseDown', function(self, btn)
            if btn == "RightButton" and IsShiftKeyDown() then
                if LeaPlusLC["VanityAltLayout"] == "On" then
                    LeaPlusLC["VanityAltLayout"] = "Off"
                else
                    LeaPlusLC["VanityAltLayout"] = "On"
                end
                SetVanityControlsLayout()
            end
        end)

        LeaPlusCB["ShowCloak"]:SetScript('OnMouseDown', function(self, btn)
            if btn == "RightButton" and IsShiftKeyDown() then
                if LeaPlusLC["VanityAltLayout"] == "On" then
                    LeaPlusLC["VanityAltLayout"] = "Off"
                else
                    LeaPlusLC["VanityAltLayout"] = "On"
                end
                SetVanityControlsLayout()
            end
        end)

        -- Set controls on startup
        SetVanityControlsLayout()

        -- Manage alpha
        LeaPlusCB["ShowHelm"]:SetAlpha(0.3)
        LeaPlusCB["ShowCloak"]:SetAlpha(0.3)
        LeaPlusCB["ShowHelm"]:HookScript("OnEnter", function()
            LeaPlusCB["ShowHelm"]:SetAlpha(1.0)
        end)
        LeaPlusCB["ShowHelm"]:HookScript("OnLeave", function()
            LeaPlusCB["ShowHelm"]:SetAlpha(0.3)
        end)
        LeaPlusCB["ShowCloak"]:HookScript("OnEnter", function()
            LeaPlusCB["ShowCloak"]:SetAlpha(1.0)
        end)
        LeaPlusCB["ShowCloak"]:HookScript("OnLeave", function()
            LeaPlusCB["ShowCloak"]:SetAlpha(0.3)
        end)

        -- Toggle helm with click
        LeaPlusCB["ShowHelm"]:HookScript("OnClick", function()
            LeaPlusCB["ShowHelm"]:Disable()
            LeaPlusCB["ShowHelm"]:SetAlpha(1.0)
            LibCompat.After(0.5, function()
                if ShowingHelm() then
                    ShowHelm(false)
                else
                    ShowHelm(true)
                end
                LeaPlusCB["ShowHelm"]:Enable()
                if not LeaPlusCB["ShowHelm"]:IsMouseOver() then
                    LeaPlusCB["ShowHelm"]:SetAlpha(0.3)
                end
            end)
        end)

        -- Toggle cloak with click
        LeaPlusCB["ShowCloak"]:HookScript("OnClick", function()
            LeaPlusCB["ShowCloak"]:Disable()
            LeaPlusCB["ShowCloak"]:SetAlpha(1.0)
            LibCompat.After(0.5, function()
                if ShowingCloak() then
                    ShowCloak(false)
                else
                    ShowCloak(true)
                end
                LeaPlusCB["ShowCloak"]:Enable()
                if not LeaPlusCB["ShowCloak"]:IsMouseOver() then
                    LeaPlusCB["ShowCloak"]:SetAlpha(0.3)
                end
            end)
        end)

        -- Set checkbox state when checkboxes are shown
        LeaPlusCB["ShowCloak"]:HookScript("OnShow", function()
            if ShowingHelm() then
                LeaPlusCB["ShowHelm"]:SetChecked(true)
            else
                LeaPlusCB["ShowHelm"]:SetChecked(false)
            end
            if ShowingCloak() then
                LeaPlusCB["ShowCloak"]:SetChecked(true)
            else
                LeaPlusCB["ShowCloak"]:SetChecked(false)
            end
        end)

    end

    ----------------------------------------------------------------------
    -- Enhance dressup
    ----------------------------------------------------------------------

    if LeaPlusLC["EnhanceDressup"] == "On" then

        -- -- Create configuration panel
        -- local DressupPanel = LeaPlusLC:CreatePanel("Enhance dressup", "DressupPanel")

        -- LeaPlusLC:MakeTx(DressupPanel, "Settings", 16, -72)
        -- LeaPlusLC:MakeCB(DressupPanel, "DressupItemButtons", "Show item buttons", 16, -92, false, "If checked, item buttons will be shown in the dressing room.  You can click the item buttons to remove individual items from the model.")
        -- LeaPlusLC:MakeCB(DressupPanel, "DressupAnimControl", "Show animation slider", 16, -112, false, "If checked, an animation slider will be shown in the dressing room.")

        -- -- Help button hidden
        -- DressupPanel.h:Hide()

        -- -- Back button handler
        -- DressupPanel.b:SetScript("OnClick", function()
        -- 	DressupPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
        -- 	return
        -- end)

        -- -- Reset button handler
        -- DressupPanel.r:SetScript("OnClick", function()

        -- 	-- Refresh configuration panel
        -- 	DressupPanel:Hide(); DressupPanel:Show()

        -- end)

        -- -- Show configuration panal when options panel button is clicked
        -- LeaPlusCB["EnhanceDressupBtn"]:SetScript("OnClick", function()
        -- 	if IsShiftKeyDown() and IsControlKeyDown() then
        -- 		-- Preset profile
        -- 	else
        -- 		DressupPanel:Show()
        -- 		LeaPlusLC:HideFrames()
        -- 	end
        -- end)

        ----------------------------------------------------------------------
        -- Item buttons
        ----------------------------------------------------------------------

        -- do

        -- 	local buttons = {}
        -- 	local slotTable = {"HeadSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "MainHandSlot", "SecondaryHandSlot"}
        -- 	local texTable = {"INV_Misc_Desecrated_ClothHelm", "INV_Misc_Desecrated_ClothShoulder", "INV_Misc_Cape_01", "INV_Misc_Desecrated_ClothChest", "INV_Shirt_01", "INV_Shirt_GuildTabard_01", "INV_Misc_Desecrated_ClothBracer", "INV_Misc_Desecrated_ClothGlove", "INV_Misc_Desecrated_ClothBelt", "INV_Misc_Desecrated_ClothPants", "INV_Misc_Desecrated_ClothBoots", "INV_Sword_01", "INV_Shield_01"}

        -- 	local function MakeSlotButton(number, slot, anchor, x, y)

        -- 		-- Create slot button
        -- 		local slotBtn = CreateFrame("Button", nil, DressUpFrame)
        -- 		slotBtn:SetFrameStrata("HIGH")
        -- 		slotBtn:SetSize(30, 30)
        -- 		slotBtn.slot = slot
        -- 		slotBtn:ClearAllPoints()
        -- 		slotBtn:SetPoint(anchor, x, y)
        -- 		slotBtn:RegisterForClicks("LeftButtonUp")
        -- 		slotBtn:SetMotionScriptsWhileDisabled(true)

        -- 		-- Slot button click
        -- 		slotBtn:SetScript("OnClick", function(self, btn)
        -- 			if btn == "LeftButton" then
        -- 				local slotID = GetInventorySlotInfo(self.slot)
        -- 				DressUpModel:UndressSlot(slotID)
        -- 			end
        -- 		end)

        -- 		-- Slot button tooltip
        -- 		slotBtn:SetScript("OnEnter", function(self)
        -- 			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        -- 			if self.item then
        -- 				GameTooltip:SetHyperlink(self.item)
        -- 			else
        -- 				if self.slot then
        -- 					GameTooltip:SetText(_G[string.upper(self.slot)])
        -- 				end
        -- 			end
        -- 		end)
        -- 		slotBtn:SetScript("OnLeave", GameTooltip_Hide)

        -- 		-- Slot button textures
        -- 		slotBtn.t = slotBtn:CreateTexture(nil, "BACKGROUND")
        -- 		slotBtn.t:SetSize(30, 30)
        -- 		slotBtn.t:SetPoint("CENTER")
        -- 		slotBtn.t:SetDesaturated(true)
        -- 		slotBtn.t:SetTexture("interface\\icons\\" .. texTable[number])

        -- 		slotBtn.h = slotBtn:CreateTexture()
        -- 		slotBtn.h:SetSize(30, 30)
        -- 		slotBtn.h:SetPoint("CENTER")
        -- 		slotBtn.h:SetTexture("bags-glow-white")
        -- 		slotBtn.h:SetBlendMode("ADD")
        -- 		slotBtn:SetHighlightTexture(slotBtn.h)

        -- 		-- Add slot button to table
        -- 		tinsert(buttons, slotBtn)

        -- 	end

        -- 	-- Show left column slot buttons
        -- 	for i = 1, 7 do
        -- 		MakeSlotButton(i, slotTable[i], "TOPLEFT", 22, -80 + -35 * (i - 1))
        -- 	end

        -- 	-- Show right column slot buttons
        -- 	for i = 8, 13 do
        -- 		MakeSlotButton(i, slotTable[i], "TOPRIGHT", -46, -80 + -35 * (i - 8))
        -- 	end

        -- 	-- Function to set item buttons
        -- 	local function ToggleItemButtons()
        -- 		if LeaPlusLC["DressupItemButtons"] == "On" then
        -- 			for i = 1, #buttons do buttons[i]:Show() end
        -- 		else
        -- 			for i = 1, #buttons do buttons[i]:Hide() end
        -- 		end
        -- 	end
        -- 	LeaPlusLC.ToggleItemButtons = ToggleItemButtons

        -- 	-- Set item buttons for option click, startup, reset click and preset click
        -- 	LeaPlusCB["DressupItemButtons"]:HookScript("OnClick", ToggleItemButtons)
        -- 	ToggleItemButtons()
        -- 	DressupPanel.r:HookScript("OnClick", function()
        -- 		LeaPlusLC["DressupItemButtons"] = "On"
        -- 		ToggleItemButtons()
        -- 		DressupPanel:Hide(); DressupPanel:Show()
        -- 	end)
        -- 	LeaPlusCB["EnhanceDressupBtn"]:HookScript("OnClick", function()
        -- 		if IsShiftKeyDown() and IsControlKeyDown() then
        -- 			LeaPlusLC["DressupItemButtons"] = "On"
        -- 			ToggleItemButtons()
        -- 		end
        -- 	end)

        -- end

        ----------------------------------------------------------------------
        -- Animation slider (must be before bottom row buttons)
        ----------------------------------------------------------------------

        -- local animTable = {0, 4, 5, 143, 119, 26, 25, 27, 28, 108, 120, 51, 124, 52, 125, 126, 62, 63, 41, 42, 43, 44, 132, 38, 14, 115, 193, 48, 110, 109, 134, 197, 0}
        -- local lastSetting

        -- LeaPlusLC["DressupAnim"] = 0 -- Defined here since the setting is not saved
        -- LeaPlusLC:MakeSL(DressUpFrame, "DressupAnim", "", 1, #animTable - 1, 1, 356, -92, "%.0f")
        -- LeaPlusCB["DressupAnim"]:ClearAllPoints()
        -- LeaPlusCB["DressupAnim"]:SetPoint("BOTTOM", -12, 112)
        -- LeaPlusCB["DressupAnim"]:SetWidth(226)
        -- LeaPlusCB["DressupAnim"]:SetFrameLevel(5)
        -- LeaPlusCB["DressupAnim"]:HookScript("OnValueChanged", function(self, setting)
        -- 	local playerActor = DressUpModel
        -- 	setting = math.floor(setting + 0.5)
        -- 	if playerActor and setting ~= lastSetting then
        -- 		lastSetting = setting
        -- 		-- DressUpModel:SetAnimation(animTable[setting], 0, 1, 1)
        -- 		-- print(animTable[setting]) -- Debug
        -- 	end
        -- end)

        -- -- Function to show animation control
        -- local function SetAnimationSlider()
        -- 	if LeaPlusLC["DressupAnimControl"] == "On" then
        -- 		LeaPlusCB["DressupAnim"]:Show()
        -- 	else
        -- 		LeaPlusCB["DressupAnim"]:Hide()
        -- 	end
        -- 	LeaPlusCB["DressupAnim"]:SetValue(1)
        -- end

        -- -- Set animation control with option, startup, preset and reset
        -- LeaPlusCB["DressupAnimControl"]:HookScript("OnClick", SetAnimationSlider)
        -- SetAnimationSlider()
        -- LeaPlusCB["EnhanceDressupBtn"]:HookScript("OnClick", function()
        -- 	if IsShiftKeyDown() and IsControlKeyDown() then
        -- 		LeaPlusLC["DressupAnimControl"] = "On"
        -- 		SetAnimationSlider()
        -- 	end
        -- end)
        -- DressupPanel.r:HookScript("OnClick", function()
        -- 	LeaPlusLC["DressupAnimControl"] = "On"
        -- 	SetAnimationSlider()
        -- 	DressupPanel:Hide(); DressupPanel:Show()
        -- end)

        -- -- Reset animation when dressup frame is shown and model is reset
        -- hooksecurefunc(DressUpFrame, "Show", SetAnimationSlider)
        -- DressUpFrameResetButton:HookScript("OnClick", SetAnimationSlider)

        -- -- Skin slider for ElvUI
        -- if LeaPlusLC.ElvUI then
        -- 	_G.LeaPlusGlobalDressupAnim = LeaPlusCB["DressupAnim"]
        -- 	LeaPlusLC.ElvUI:GetModule("Skins"):HandleSliderFrame(_G.LeaPlusGlobalDressupAnim, false)
        -- end

        ----------------------------------------------------------------------
        -- Buttons
        ----------------------------------------------------------------------

        -- Function to modify a button
        local function SetButton(where, text, tip)
            if text ~= "" then
                where:SetText(L[text])
                where:SetWidth(where:GetFontString():GetStringWidth() + 20)
            end
            where:HookScript("OnEnter", function()
                GameTooltip:SetOwner(where, "ANCHOR_NONE")
                GameTooltip:SetPoint("BOTTOM", where, "TOP", 0, 10)
                GameTooltip:SetText(L[tip], nil, nil, nil, nil, true)
            end)
            where:HookScript("OnLeave", GameTooltip_Hide)
        end

        -- Close
        SetButton(DressUpFrameCancelButton, "", "Close")
        DressUpFrameCancelButton:ClearAllPoints()
        DressUpFrameCancelButton:SetPoint("BOTTOMRIGHT", DressUpFrame, "BOTTOMRIGHT", -40, 80)

        -- Reset
        SetButton(DressUpFrameResetButton, "R", "Reset")

        -- Nude
        LeaPlusLC:CreateButton("DressUpNudeBtn", DressUpFrameResetButton, "N", "BOTTOMLEFT", 106, 79, 80, 22, false, "")
        LeaPlusCB["DressUpNudeBtn"]:SetFrameLevel(3)
        LeaPlusCB["DressUpNudeBtn"]:ClearAllPoints()
        LeaPlusCB["DressUpNudeBtn"]:SetPoint("RIGHT", DressUpFrameResetButton, "LEFT", 0, 0)
        SetButton(LeaPlusCB["DressUpNudeBtn"], "N", "Remove all items")
        LeaPlusCB["DressUpNudeBtn"]:SetScript("OnClick", function()
            DressUpModel:Undress()
        end)

        -- Show me
        LeaPlusLC:CreateButton("DressUpShowMeBtn", DressUpFrameResetButton, "M", "BOTTOMLEFT", 26, 79, 80, 22, false, "")
        LeaPlusCB["DressUpShowMeBtn"]:ClearAllPoints()
        LeaPlusCB["DressUpShowMeBtn"]:SetPoint("RIGHT", LeaPlusCB["DressUpNudeBtn"], "LEFT", 0, 0)
        SetButton(LeaPlusCB["DressUpShowMeBtn"], "M", "Show me")
        LeaPlusCB["DressUpShowMeBtn"]:SetScript("OnClick", function()
            local playerActor = DressUpModel
            playerActor:SetUnit("player")
            -- Set animation
            -- playerActor:SetAnimation(0)
            -- LibCompat.After(0.1,function()
            -- 	playerActor:SetAnimation(animTable[math.floor(LeaPlusCB["DressupAnim"]:GetValue() + 0.5)], 0, 1, 1)
            -- end)
        end)

        -- Show my outfit on target
        --[[LeaPlusLC:CreateButton("DressUpOutfitOnTargetBtn", DressUpFrameResetButton, "O", "BOTTOMLEFT", 26, 79, 80, 22, false, "")
                LeaPlusCB["DressUpOutfitOnTargetBtn"]:ClearAllPoints()
                LeaPlusCB["DressUpOutfitOnTargetBtn"]:SetPoint("RIGHT", LeaPlusCB["DressUpNudeBtn"], "LEFT", 0, 0)
                SetButton(LeaPlusCB["DressUpOutfitOnTargetBtn"], "O", "Show my outfit on target")
                LeaPlusCB["DressUpOutfitOnTargetBtn"]:SetScript("OnClick", function()
                    if UnitIsPlayer("target") then
                        DressUpModel:SetUnit("target")
                        DressUpModel:Undress()
                        LibCompat.After(0.01, function()
                            for i = 1, 19 do
                                local itemName = GetInventoryItemID("player", i)
                                if itemName then
                                    DressUpModel:TryOn("item:" .. itemName)
                                end
                            end
                        end)
                    end
                end)]]

        -- Target
        LeaPlusLC:CreateButton("DressUpTargetBtn", DressUpFrameResetButton, "T", "BOTTOMLEFT", 26, 79, 80, 22, false, "")
        LeaPlusCB["DressUpTargetBtn"]:ClearAllPoints()
        LeaPlusCB["DressUpTargetBtn"]:SetPoint("RIGHT", LeaPlusCB["DressUpShowMeBtn"], "LEFT", 0, 0)
        SetButton(LeaPlusCB["DressUpTargetBtn"], "T", "Show target model")
        LeaPlusCB["DressUpTargetBtn"]:SetScript("OnClick", function()
            if UnitIsPlayer("target") then
                local playerActor = DressUpModel
                if playerActor then
                    playerActor:SetUnit("target")
                    -- Set animation
                    -- playerActor:SetAnimation(0)
                    -- LibCompat.After(0.1,function()
                    -- 	playerActor:SetAnimation(animTable[math.floor(LeaPlusCB["DressupAnim"]:GetValue() + 0.5)], 0, 1, 1)
                    -- end)
                end
            end
        end)

        -- -- Toggle buttons
        -- LeaPlusLC:CreateButton("DressUpButonsBtn", DressUpFrameResetButton, "B", "BOTTOMLEFT", 26, 79, 80, 22, false, "")
        -- LeaPlusCB["DressUpButonsBtn"]:ClearAllPoints()
        -- LeaPlusCB["DressUpButonsBtn"]:SetPoint("RIGHT", LeaPlusCB["DressUpTargetBtn"], "LEFT", 0, 0)
        -- SetButton(LeaPlusCB["DressUpButonsBtn"], "B", "Toggle buttons")
        -- LeaPlusCB["DressUpButonsBtn"]:SetScript("OnClick", function()
        -- 	if LeaPlusLC["DressupItemButtons"] == "On" then LeaPlusLC["DressupItemButtons"] = "Off" else LeaPlusLC["DressupItemButtons"] = "On" end
        -- 	LeaPlusLC:ToggleItemButtons()
        -- 	if DressupPanel:IsShown() then DressupPanel:Hide(); DressupPanel:Show() end
        -- end)

        -- Show nearby target outfit on me button
        --[[LeaPlusLC:CreateButton("DressUpTargetSelfBtn", DressUpFrameResetButton, "S", "BOTTOMLEFT", 26, 79, 80, 22, false, "")
                LeaPlusCB["DressUpTargetSelfBtn"]:ClearAllPoints()
                LeaPlusCB["DressUpTargetSelfBtn"]:SetPoint("RIGHT", LeaPlusCB["DressUpTargetBtn"], "LEFT", 0, 0)
                SetButton(LeaPlusCB["DressUpTargetSelfBtn"], "S", "Show nearby target outfit on me")
                LeaPlusCB["DressUpTargetSelfBtn"]:SetScript("OnClick", function()
                    if UnitIsPlayer("target") then
                        if not CanInspect("target") then
                            ActionStatus_DisplayMessage(L["Target out of range."], true)
                            return
                        end
                        NotifyInspect("target")
                        LeaPlusCB["DressUpTargetSelfBtn"]:RegisterEvent("INSPECT_READY")
                        LeaPlusCB["DressUpTargetSelfBtn"]:SetScript("OnEvent", function()
                            DressUpModel:SetUnit("player")
                            DressUpModel:Undress()
                            LibCompat.After(0.01, function()
                                for i = 1, 19 do
                                    local itemName = GetInventoryItemID("target", i)
                                    LibCompat.After(0.01, function()
                                        if itemName then
                                            DressUpModel:TryOn("item:" .. itemName)
                                        end
                                    end)
                                end
                            end)
                            LeaPlusCB["DressUpTargetSelfBtn"]:UnregisterEvent("INSPECT_READY")
                        end)
                    end
                end)]]

        -- Change player actor to player when reset button is clicked (needed because target button changes it)
        DressUpFrameResetButton:HookScript("OnClick", function()
            DressUpModel:SetUnit("player")
        end)

        -- Auction house
        local BtnStrata, BtnLevel = UIParent:GetFrameStrata(), UIParent:GetFrameLevel()

        -- Add buttons to auction house dressup frame
        LeaPlusLC:CreateButton("DressUpSideBtn", SideDressUpModelResetButton, "Tabard", "BOTTOMLEFT", -36, -31, 60, 22, false, "")
        LeaPlusCB["DressUpSideBtn"]:SetFrameStrata(BtnStrata)
        LeaPlusCB["DressUpSideBtn"]:SetFrameLevel(BtnLevel)
        LeaPlusCB["DressUpSideBtn"]:SetScript("OnClick", function()
            SideDressUpModel:UndressSlot(19)
        end)

        LeaPlusLC:CreateButton("DressUpSideNudeBtn", SideDressUpModelResetButton, "Nude", "BOTTOMRIGHT", 39, -31, 60, 22, false, "")
        LeaPlusCB["DressUpSideNudeBtn"]:SetFrameStrata(BtnStrata)
        LeaPlusCB["DressUpSideNudeBtn"]:SetFrameLevel(BtnLevel)
        LeaPlusCB["DressUpSideNudeBtn"]:SetScript("OnClick", function()
            SideDressUpModel:Undress()
        end)

        -- Skin buttons for ElvUI
        if LeaPlusLC.ElvUI then
            -- _G.LeaPlusGlobalDressUpButtonsButton = LeaPlusCB["DressUpButonsBtn"]
            -- LeaPlusLC.ElvUI:GetModule("Skins"):HandleButton(_G.LeaPlusGlobalDressUpButtonsButton)

            _G.LeaPlusGlobalDressUpShowMeButton = LeaPlusCB["DressUpShowMeBtn"]
            LeaPlusLC.ElvUI:GetModule("Skins"):HandleButton(_G.LeaPlusGlobalDressUpShowMeButton)

            _G.LeaPlusGlobalDressUpTargetButton = LeaPlusCB["DressUpTargetBtn"]
            LeaPlusLC.ElvUI:GetModule("Skins"):HandleButton(_G.LeaPlusGlobalDressUpTargetButton)

            _G.LeaPlusGlobalDressUpNudeButton = LeaPlusCB["DressUpNudeBtn"]
            LeaPlusLC.ElvUI:GetModule("Skins"):HandleButton(_G.LeaPlusGlobalDressUpNudeButton)
        end

        ----------------------------------------------------------------------
        -- Controls
        ----------------------------------------------------------------------

        -- Hide model rotation controls
        -- CharacterModelFrameRotateLeftButton:HookScript("OnShow", CharacterModelFrameRotateLeftButton.Hide)
        -- CharacterModelFrameRotateRightButton:HookScript("OnShow", CharacterModelFrameRotateRightButton.Hide)
        -- DressUpModelFrameRotateLeftButton:HookScript("OnShow", DressUpModelFrameRotateLeftButton.Hide)
        -- DressUpModelFrameRotateRightButton:HookScript("OnShow", DressUpModelFrameRotateRightButton.Hide)
        -- SideDressUpModelControlFrame:HookScript("OnShow", SideDressUpModelControlFrame.Hide)

        ----------------------------------------------------------------------
        -- Hide dressup stats button
        ----------------------------------------------------------------------

        local function ToggleStats(startup)

            -- ElvUI_WrathArmory: Make character model full size
            if LeaPlusLC.ElvUI then
                local E = LeaPlusLC.ElvUI:GetModule("ElvUI_WrathArmory", true)
                if E then
                    CharacterModelFrame:ClearAllPoints()
                    CharacterModelFrame:SetPoint("TOPLEFT", PaperDollFrame, 66, -76)
                    CharacterModelFrame:SetPoint("BOTTOMRIGHT", PaperDollFrame, -86, 134)
                    return
                end
            end

            -- Toggle dressup stats
            if LeaPlusLC["HideDressupStats"] == "On" then
                CharacterResistanceFrame:Hide()
                if CSC_HideStatsPanel then
                    -- CharacterStatsTBC is installed
                    RunScript('CSC_HideStatsPanel()')
                    if startup then
                        LibCompat.After(0.1, function()
                            CharacterModelFrame:ClearAllPoints()
                            CharacterModelFrame:SetPoint("TOPLEFT", PaperDollFrame, 66, -76)
                            CharacterModelFrame:SetPoint("BOTTOMRIGHT", PaperDollFrame, -86, 134)
                        end)
                    end
                else
                    -- CharacterStatsTBC is not installed
                    CharacterAttributesFrame:Hide()
                end
                CharacterModelFrame:ClearAllPoints()
                CharacterModelFrame:SetPoint("TOPLEFT", PaperDollFrame, 66, -76)
                CharacterModelFrame:SetPoint("BOTTOMRIGHT", PaperDollFrame, -86, 134)
                if LeaPlusLC["ShowVanityControls"] == "On" then
                    LeaPlusCB["ShowHelm"]:Hide()
                    LeaPlusCB["ShowCloak"]:Hide()
                end

            else

                CharacterResistanceFrame:Show()
                if CSC_ShowStatsPanel then
                    -- CharacterStatsTBC is installed
                    RunScript('CSC_ShowStatsPanel()')
                    if startup then
                        LibCompat.After(0.1, function()
                            CharacterModelFrame:ClearAllPoints()
                            CharacterModelFrame:SetPoint("TOPLEFT", PaperDollFrame, 66, -76)
                            CharacterModelFrame:SetPoint("BOTTOMRIGHT", PaperDollFrame, -86, 243)
                        end)
                    end
                else
                    -- CharacterStatsTBC is not installed
                    CharacterAttributesFrame:Show()
                end
                CharacterModelFrame:ClearAllPoints()
                CharacterModelFrame:SetPoint("TOPLEFT", PaperDollFrame, 66, -76)
                CharacterModelFrame:SetPoint("BOTTOMRIGHT", PaperDollFrame, -86, 243)
                if LeaPlusLC["ShowVanityControls"] == "On" then
                    LeaPlusCB["ShowHelm"]:Show()
                    LeaPlusCB["ShowCloak"]:Show()
                end
            end

        end

        -- Toggle stats with middle mouse button
        CharacterModelFrame:HookScript("OnMouseDown", function(self, btn)
            if btn == "MiddleButton" then
                if LeaPlusLC["HideDressupStats"] == "On" then
                    LeaPlusLC["HideDressupStats"] = "Off"
                else
                    LeaPlusLC["HideDressupStats"] = "On"
                end
                ToggleStats()
            end
        end)
        ToggleStats(true)

        -- Create toggle stats button
        local toggleButton = CreateFrame("Button", nil, PaperDollFrame)
        toggleButton:SetSize(36, 36)
        toggleButton:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", 64, -45)
        toggleButton:SetNormalTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-RotationRight-Big-Up")
        toggleButton:SetHighlightTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-RotationRight-Big-Up")
        toggleButton:SetPushedTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-RotationRight-Big-Up")
        toggleButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(toggleButton, "ANCHOR_NONE")
            GameTooltip:SetPoint("BOTTOMLEFT", toggleButton, "BOTTOMRIGHT", 0, 0)
            GameTooltip:SetText(L["Toggle character stats"], nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        toggleButton:SetScript("OnLeave", GameTooltip_Hide)
        toggleButton:SetScript("OnClick", function()
            if LeaPlusLC["HideDressupStats"] == "On" then
                LeaPlusLC["HideDressupStats"] = "Off"
            else
                LeaPlusLC["HideDressupStats"] = "On"
            end
            ToggleStats()
        end)

        -- Delay setting stats if CharacterStatsTBC is installed but hasn't loaded yet
        if not CSC_HideStatsPanel and select(2, GetAddOnInfo("CharacterStatsTBC")) then
            local waitFrame = CreateFrame("FRAME")
            waitFrame:RegisterEvent("ADDON_LOADED")
            waitFrame:SetScript("OnEvent", function(self, event, arg1)
                if arg1 == "CharacterStatsTBC" then
                    ToggleStats(true)
                    waitFrame:UnregisterAllEvents()
                end
            end)
        end

        ----------------------------------------------------------------------
        -- Enable zooming and panning
        ----------------------------------------------------------------------

        -- Enable zooming for character frame and dressup frame
        -- CharacterModelFrame:HookScript("OnMouseWheel", Model_OnMouseWheel)
        -- DressUpModelFrame:HookScript("OnMouseWheel", Model_OnMouseWheel)

        -- Slightly shorter character model frame for CharacterStatsTBC
        if IsAddOnLoaded("CharacterStatsTBC") then
            CharacterModelFrame:ClearAllPoints()
            CharacterModelFrame:SetPoint("TOPLEFT", PaperDollFrame, 66, -76)
            CharacterModelFrame:SetPoint("BOTTOMRIGHT", PaperDollFrame, -86, 220)
        end

        -- -- Enable panning for character frame
        -- CharacterModelFrame:HookScript("OnMouseDown", function(self, btn)
        -- 	if btn == "RightButton" then
        -- 		Model_StartPanning(self)
        -- 	end
        -- end)

        -- CharacterModelFrame:HookScript("OnMouseUp", function(self, btn)
        -- 	Model_StopPanning(self)
        -- end)

        -- -- Enable panning for dressup frame
        -- DressUpModelFrame:HookScript("OnMouseDown", function(self, btn)
        -- 	if btn == "RightButton" then
        -- 		Model_StartPanning(self)
        -- 	end
        -- end)

        -- DressUpModelFrame:HookScript("OnMouseUp", function(self, btn)
        -- 	Model_StopPanning(self)
        -- end)

        -- DressUpModelFrame:ClearAllPoints()
        -- DressUpModelFrame:SetPoint("TOPLEFT", DressUpFrame, 22, -76)
        -- DressUpModelFrame:SetPoint("BOTTOMRIGHT", DressUpFrame, -46, 106)

        -- -- Reset dressup frame when reset button clicked
        -- DressUpFrameResetButton:HookScript("OnClick", function()
        -- 	DressUpModelFrame.rotation = 0
        -- 	DressUpModelFrame:SetRotation(0)
        -- 	DressUpModelFrame:SetPosition(0, 0, 0)
        -- 	DressUpModelFrame.zoomLevel = 0
        -- 	DressUpModelFrame:SetPortraitZoom(0)
        -- 	DressUpModelFrame:RefreshCamera()
        -- end)

        -- -- Reset side dressup when reset button clicked
        -- SideDressUpModelResetButton:HookScript("OnClick", function()
        -- 	SideDressUpModel.rotation = 0
        -- 	SideDressUpModel:SetRotation(0)
        -- 	SideDressUpModel:SetPosition(0, 0, -0.1)
        -- 	SideDressUpModel.zoomLevel = 0
        -- 	SideDressUpModel:SetPortraitZoom(0)
        -- 	SideDressUpModel:RefreshCamera()
        -- end)

        -- ----------------------------------------------------------------------
        -- -- Inspect system
        -- ----------------------------------------------------------------------

        -- -- Inspect System
        -- local function DoInspectSystemFunc()

        -- 	-- -- Hide model rotation controls
        -- 	-- InspectModelFrameRotateLeftButton:Hide()
        -- 	-- InspectModelFrameRotateRightButton:Hide()

        -- 	-- Enable zooming
        -- 	InspectModelFrame:HookScript("OnMouseWheel", Model_OnMouseWheel)

        -- 	-- Enable panning
        -- 	InspectModelFrame:HookScript("OnMouseDown", function(self, btn)
        -- 		if btn == "RightButton" then
        -- 			Model_StartPanning(self)
        -- 		end
        -- 	end)

        -- 	InspectModelFrame:HookScript("OnMouseUp", function(self, btn)
        -- 		Model_StopPanning(self)
        -- 	end)

        -- end

        -- if IsAddOnLoaded("Blizzard_InspectUI") then
        -- 	DoInspectSystemFunc()
        -- else
        -- 	local waitFrame = CreateFrame("FRAME")
        -- 	waitFrame:RegisterEvent("ADDON_LOADED")
        -- 	waitFrame:SetScript("OnEvent", function(self, event, arg1)
        -- 		if arg1 == "Blizzard_InspectUI" then
        -- 			DoInspectSystemFunc()
        -- 			waitFrame:UnregisterAllEvents()
        -- 		end
        -- 	end)
        -- end

    end

    ----------------------------------------------------------------------
    -- Automatically release in battlegrounds
    ----------------------------------------------------------------------

    do

        -- Create configuration panel
        local ReleasePanel = LeaPlusLC:CreatePanel("Release in PvP", "ReleasePanel")

        LeaPlusLC:MakeTx(ReleasePanel, "Settings", 16, -72)
        LeaPlusLC:MakeCB(ReleasePanel, "AutoReleaseNoAlterac", "Exclude Alterac Valley", 16, -92, false, "If checked, you will not release automatically in Alterac Valley.")

        LeaPlusLC:MakeTx(ReleasePanel, "Delay", 356, -72)
        LeaPlusLC:MakeSL(ReleasePanel, "AutoReleaseDelay", "Drag to set the number of milliseconds before you are automatically released.|n|nYou can hold down shift as the timer is ending to cancel the automatic release.", 200, 3000, 100, 356, -92, "%.0f")

        -- Help button hidden
        ReleasePanel.h:Hide()

        -- Back button handler
        ReleasePanel.b:SetScript("OnClick", function()
            ReleasePanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page1"]:Show();
            return
        end)

        -- Reset button handler
        ReleasePanel.r:SetScript("OnClick", function()

            -- Reset checkboxes
            LeaPlusLC["AutoReleaseNoAlterac"] = "Off"
            LeaPlusLC["AutoReleaseDelay"] = 200

            -- Refresh panel
            ReleasePanel:Hide();
            ReleasePanel:Show()

        end)

        -- Show panal when options panel button is clicked
        LeaPlusCB["AutoReleasePvPBtn"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["AutoReleaseNoAlterac"] = "Off"
                LeaPlusLC["AutoReleaseDelay"] = 200
            else
                ReleasePanel:Show()
                LeaPlusLC:HideFrames()
            end
        end)

        -- Release in battlegrounds
        hooksecurefunc("StaticPopup_Show", function(sType)
            if sType and sType == "DEATH" and LeaPlusLC["AutoReleasePvP"] == "On" then
                if HasSoulstone() then
                    return
                end
                local InstStat, InstType = IsInInstance()
                if InstStat and InstType == "pvp" then
                    -- Exclude specific maps
                    local mapID = GetCurrentMapAreaID() or nil -- 2.4.3 need test
                    if mapID then
                        if mapID == 1459 and LeaPlusLC["AutoReleaseNoAlterac"] == "On" then
                            return
                        end -- Alterac Valley
                    end
                    -- Release automatically
                    local delay = LeaPlusLC["AutoReleaseDelay"] / 1000
                    LibCompat.After(delay, function()
                        local dialog = StaticPopup_Visible("DEATH")
                        if dialog then
                            if IsShiftKeyDown() then
                                ActionStatus_DisplayMessage(L["Automatic Release Cancelled"], true)
                            else
                                StaticPopup_OnClick(_G[dialog], 1)
                            end
                        end
                    end)
                end
            end
        end)

    end

    ----------------------------------------------------------------------
    --	Enhance trainers
    ----------------------------------------------------------------------

    if LeaPlusLC["EnhanceTrainers"] == "On" then

        -- Create configuration panel
        local TrainerPanel = LeaPlusLC:CreatePanel("Enhance trainers", "TrainerPanel")

        LeaPlusLC:MakeTx(TrainerPanel, "Settings", 16, -72)
        LeaPlusLC:MakeCB(TrainerPanel, "ShowTrainAllBtn", "Show train all skills button", 16, -92, false, "If checked, a train all skills button will be shown in the skill trainer frame allowing you to train all available skills instantly.")

        -- Help button hidden
        TrainerPanel.h:Hide()

        -- Back button handler
        TrainerPanel.b:SetScript("OnClick", function()
            TrainerPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page5"]:Show()
            return
        end)

        -- Reset button handler
        TrainerPanel.r:SetScript("OnClick", function()

            -- Reset controls
            LeaPlusLC["ShowTrainAllBtn"] = "On"

            -- Refresh configuration panel
            TrainerPanel:Hide();
            TrainerPanel:Show()

        end)

        -- Show configuration panal when options panel button is clicked
        LeaPlusCB["EnhanceTrainersBtn"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["ShowTrainAllBtn"] = "On"
            else
                TrainerPanel:Show()
                LeaPlusLC:HideFrames()
            end
        end)

        -- Set increased height of skill trainer frame and maximum number of skills listed
        local tall, numTallTrainers = 73, 17

        ----------------------------------------------------------------------
        --	Trainers Frame
        ----------------------------------------------------------------------

        local function TrainerFunc(frame)

            -- Make the frame double-wide
            UIPanelWindows["ClassTrainerFrame"] = { area = "override", pushable = 0, xoffset = 0, yoffset = 12, bottomClampOverride = 140 + 12, width = 714, height = 487, whileDead = 1 }

            -- Size the frame
            _G["ClassTrainerFrame"]:SetSize(714, 487 + tall)

            -- Lower title text slightly
            _G["ClassTrainerNameText"]:ClearAllPoints()
            _G["ClassTrainerNameText"]:SetPoint("TOP", _G["ClassTrainerFrame"], "TOP", 0, -18)

            -- Expand the skill list to full height
            _G["ClassTrainerListScrollFrame"]:ClearAllPoints()
            _G["ClassTrainerListScrollFrame"]:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 25, -75)
            _G["ClassTrainerListScrollFrame"]:SetSize(295, 336 + tall)

            -- Create additional list rows
            do

                local oldSkillsDisplayed = CLASS_TRAINER_SKILLS_DISPLAYED

                -- Position existing buttons
                for i = 1 + 1, CLASS_TRAINER_SKILLS_DISPLAYED do
                    _G["ClassTrainerSkill" .. i]:ClearAllPoints()
                    _G["ClassTrainerSkill" .. i]:SetPoint("TOPLEFT", _G["ClassTrainerSkill" .. (i - 1)], "BOTTOMLEFT", 0, 1)
                end

                -- Create and position new buttons
                _G.CLASS_TRAINER_SKILLS_DISPLAYED = _G.CLASS_TRAINER_SKILLS_DISPLAYED + numTallTrainers
                for i = oldSkillsDisplayed + 1, CLASS_TRAINER_SKILLS_DISPLAYED do
                    local button = CreateFrame("Button", "ClassTrainerSkill" .. i, ClassTrainerFrame, "ClassTrainerSkillButtonTemplate")
                    button:SetID(i)
                    button:Hide()
                    button:ClearAllPoints()
                    button:SetPoint("TOPLEFT", _G["ClassTrainerSkill" .. (i - 1)], "BOTTOMLEFT", 0, 1)
                end

                hooksecurefunc("ClassTrainer_SetToTradeSkillTrainer", function()
                    _G.CLASS_TRAINER_SKILLS_DISPLAYED = _G.CLASS_TRAINER_SKILLS_DISPLAYED + numTallTrainers
                    ClassTrainerListScrollFrame:SetHeight(336 + tall)
                    ClassTrainerDetailScrollFrame:SetHeight(336 + tall)
                end)

                hooksecurefunc("ClassTrainer_SetToClassTrainer", function()
                    _G.CLASS_TRAINER_SKILLS_DISPLAYED = _G.CLASS_TRAINER_SKILLS_DISPLAYED + numTallTrainers - 1
                    ClassTrainerListScrollFrame:SetHeight(336 + tall)
                    ClassTrainerDetailScrollFrame:SetHeight(336 + tall)
                end)

                --===== 3.3.5 - Hooking blizzard func to not change the Skills width if no scrollbar (was overlapping before) =====--

                local function modified_ClassTrainerFrame_Update()
                    -- Your modifications to the function here
                    -- Set button width to 293 if scrollbar is hidden
                    for i = 1, CLASS_TRAINER_SKILLS_DISPLAYED do
                        local skillButton = _G["ClassTrainerSkill" .. i];
                        if (skillButton) then
                            if (not ClassTrainerListScrollFrame:IsShown()) then
                                skillButton:SetWidth(293);
                            else
                                skillButton:SetWidth(293);
                            end
                        end
                    end
                end

                -- Hook the modified function to the ClassTrainerFrame_Update event
                hooksecurefunc("ClassTrainerFrame_Update", modified_ClassTrainerFrame_Update)


            end

            -- Set highlight bar width when shown
            hooksecurefunc(_G["ClassTrainerSkillHighlightFrame"], "Show", function()
                ClassTrainerSkillHighlightFrame:SetWidth(290)
            end)

            -- Move the detail frame to the right and stretch it to full height
            _G["ClassTrainerDetailScrollFrame"]:ClearAllPoints()
            _G["ClassTrainerDetailScrollFrame"]:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 352, -74)
            _G["ClassTrainerDetailScrollFrame"]:SetSize(296, 336 + tall)
            -- _G["ClassTrainerSkillIcon"]:SetHeight(500) -- Debug

            -- Hide detail scroll frame textures
            _G["ClassTrainerDetailScrollFrameTop"]:SetAlpha(0)
            _G["ClassTrainerDetailScrollFrameBottom"]:SetAlpha(0)

            -- Hide expand tab (left of All button)
            _G["ClassTrainerExpandTabLeft"]:Hide()

            -- Get frame textures
            local regions = { _G["ClassTrainerFrame"]:GetRegions() }

            -- Set top left texture
            regions[2]:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus")
            regions[2]:SetTexCoord(0.25, 0.75, 0, 1)
            regions[2]:SetSize(512, 512)

            -- Set top right texture
            regions[3]:ClearAllPoints()
            regions[3]:SetPoint("TOPLEFT", regions[2], "TOPRIGHT", 0, 0)
            regions[3]:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus")
            regions[3]:SetTexCoord(0.75, 1, 0, 1)
            regions[3]:SetSize(256, 512)

            -- Hide bottom left and bottom right textures
            regions[4]:Hide()
            regions[5]:Hide()

            -- Hide skills list dividing bar
            regions[9]:Hide()
            ClassTrainerHorizontalBarLeft:Hide()

            -- Set skills list backdrop
            local RecipeInset = _G["ClassTrainerFrame"]:CreateTexture(nil, "ARTWORK")
            RecipeInset:SetSize(304, 361 + tall)
            RecipeInset:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 16, -72)
            RecipeInset:SetTexture("Interface\\RAIDFRAME\\UI-RaidFrame-GroupBg")

            -- Set detail frame backdrop
            local DetailsInset = _G["ClassTrainerFrame"]:CreateTexture(nil, "ARTWORK")
            DetailsInset:SetSize(302, 339 + tall)
            DetailsInset:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 348, -72)
            DetailsInset:SetTexture("Interface\\addons\\Leatrix_Plus\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")

            -- Move bottom button row
            _G["ClassTrainerTrainButton"]:ClearAllPoints()
            _G["ClassTrainerTrainButton"]:SetPoint("RIGHT", _G["ClassTrainerCancelButton"], "LEFT", -1, 0)

            -- Position and size close button
            _G["ClassTrainerCancelButton"]:SetSize(80, 22)
            _G["ClassTrainerCancelButton"]:SetText(CLOSE)
            _G["ClassTrainerCancelButton"]:ClearAllPoints()
            _G["ClassTrainerCancelButton"]:SetPoint("BOTTOMRIGHT", _G["ClassTrainerFrame"], "BOTTOMRIGHT", -42, 54)

            -- Position close box
            _G["ClassTrainerFrameCloseButton"]:ClearAllPoints()
            _G["ClassTrainerFrameCloseButton"]:SetPoint("TOPRIGHT", _G["ClassTrainerFrame"], "TOPRIGHT", -30, -8)

            -- Position dropdown menus
            ClassTrainerFrameFilterDropDown:ClearAllPoints()
            ClassTrainerFrameFilterDropDown:SetPoint("TOPLEFT", ClassTrainerFrame, "TOPLEFT", 501, -40)

            -- Position money frame
            ClassTrainerMoneyFrame:ClearAllPoints()
            ClassTrainerMoneyFrame:SetPoint("TOPLEFT", _G["ClassTrainerFrame"], "TOPLEFT", 143, -49)
            ClassTrainerGreetingText:Hide()

            ----------------------------------------------------------------------
            --	Train All button
            ----------------------------------------------------------------------

            -- Create train all button
            LeaPlusLC:CreateButton("TrainAllButton", ClassTrainerFrame, "Train All", "BOTTOMLEFT", 344, 54, 0, 22, false, "")

            -- Give button global scope (useful for compatibility with other addons and essential for ElvUI)
            _G.LeaPlusGlobalTrainAllButton = LeaPlusCB["TrainAllButton"]

            -- Button tooltip
            LeaPlusCB["TrainAllButton"]:SetScript("OnEnter", function(self)
                -- Get number of available skills and total cost
                local count, cost = 0, 0
                for i = 1, GetNumTrainerServices() do
                    local void, void, isAvail = GetTrainerServiceInfo(i)
                    if isAvail and isAvail == "available" then
                        count = count + 1
                        cost = cost + GetTrainerServiceCost(i)
                    end
                end
                -- Show tooltip
                if count > 0 then
                    GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 4)
                    GameTooltip:ClearLines()
                    if count > 1 then
                        GameTooltip:AddLine(L["Train"] .. " " .. count .. " " .. L["skills for"] .. " " .. GetCoinTextureString(cost))
                    else
                        GameTooltip:AddLine(L["Train"] .. " " .. count .. " " .. L["skill for"] .. " " .. GetCoinTextureString(cost))
                    end
                    GameTooltip:Show()
                end
            end)

            -- Button click handler
            LeaPlusCB["TrainAllButton"]:SetScript("OnClick", function(self)
                for i = 1, GetNumTrainerServices() do
                    local void, void, isAvail = GetTrainerServiceInfo(i)
                    if isAvail and isAvail == "available" then
                        BuyTrainerService(i)
                    end
                end
            end)

            -- Enable button only when skills are available
            local skillsAvailable
            hooksecurefunc("ClassTrainerFrame_Update", function()
                skillsAvailable = false
                for i = 1, GetNumTrainerServices() do
                    local void, void, isAvail = GetTrainerServiceInfo(i)
                    if isAvail and isAvail == "available" then
                        skillsAvailable = true
                    end
                end
                if skillsAvailable then
                    LeaPlusCB["TrainAllButton"]:Enable()
                else
                    LeaPlusCB["TrainAllButton"]:Disable()
                end
                -- Refresh tooltip
                if LeaPlusCB["TrainAllButton"]:IsMouseOver() and skillsAvailable then
                    LeaPlusCB["TrainAllButton"]:GetScript("OnEnter")(LeaPlusCB["TrainAllButton"])
                end
            end)

            -- Function to set train all button
            local function SetTrainAllFunc()
                if LeaPlusLC["ShowTrainAllBtn"] == "On" then
                    LeaPlusCB["TrainAllButton"]:Show()
                else
                    LeaPlusCB["TrainAllButton"]:Hide()
                end
            end

            -- Run function when option is clicked, reset or preset button is clicked and on startup
            LeaPlusCB["ShowTrainAllBtn"]:HookScript("OnClick", SetTrainAllFunc)
            TrainerPanel.r:HookScript("OnClick", SetTrainAllFunc)
            LeaPlusCB["EnhanceTrainersBtn"]:HookScript("OnClick", function()
                if IsShiftKeyDown() and IsControlKeyDown() then
                    -- Preset profile
                    LeaPlusLC["ShowTrainAllBtn"] = "On"
                    SetTrainAllFunc()
                end
            end)
            SetTrainAllFunc()

            ----------------------------------------------------------------------
            --	ElvUI fixes
            ----------------------------------------------------------------------

            -- ElvUI fixes
            if LeaPlusLC.ElvUI then
                local E = LeaPlusLC.ElvUI
                if E.private.skins.blizzard.enable and E.private.skins.blizzard.trainer then
                    regions[2]:Hide()
                    regions[3]:Hide()
                    RecipeInset:Hide()
                    DetailsInset:Hide()
                    _G["ClassTrainerFrame"]:SetHeight(512 + tall)
                    _G["ClassTrainerTrainButton"]:ClearAllPoints()
                    _G["ClassTrainerTrainButton"]:SetPoint("BOTTOMRIGHT", _G["ClassTrainerFrame"], "BOTTOMRIGHT", -42, 78)
                    LeaPlusCB["TrainAllButton"]:ClearAllPoints()
                    LeaPlusCB["TrainAllButton"]:SetPoint("BOTTOMLEFT", _G["ClassTrainerFrame"], "BOTTOMLEFT", 344, 78)
                    E:GetModule("Skins"):HandleButton(_G.LeaPlusGlobalTrainAllButton)
                end
            end

        end

        -- Run function when Trainer UI has loaded
        if IsAddOnLoaded("Blizzard_TrainerUI") then
            TrainerFunc()
        else
            local waitFrame = CreateFrame("FRAME")
            waitFrame:RegisterEvent("ADDON_LOADED")
            waitFrame:SetScript("OnEvent", function(self, event, arg1)
                if arg1 == "Blizzard_TrainerUI" then
                    TrainerFunc()
                    waitFrame:UnregisterAllEvents()
                end
            end)
        end

    end

    ----------------------------------------------------------------------
    --	Set weather density (no reload required)
    ----------------------------------------------------------------------

    do

        -- Create configuration panel
        local weatherPanel = LeaPlusLC:CreatePanel("Set weather density", "weatherPanel")
        LeaPlusLC:MakeTx(weatherPanel, "Settings", 16, -72)
        LeaPlusLC:MakeSL(weatherPanel, "WeatherLevel", "Drag to set the density of weather effects.", 0, 3, 1, 16, -92, "%.0f")

        local weatherSliderTable = { L["Very Low"], L["Low"], L["Medium"], L["High"] }

        -- Function to set the weather density
        local function SetWeatherFunc()
            LeaPlusCB["WeatherLevel"].f:SetText(LeaPlusLC["WeatherLevel"] .. "  (" .. weatherSliderTable[LeaPlusLC["WeatherLevel"] + 1] .. ")")
            if LeaPlusLC["SetWeatherDensity"] == "On" then
                SetCVar("weatherDensity", LeaPlusLC["WeatherLevel"])
                --SetCVar("RAIDweatherDensity", LeaPlusLC["WeatherLevel"])
            else
                SetCVar("weatherDensity", "3")
                --SetCVar("RAIDweatherDensity", "3")
            end
        end

        -- Set weather density when options are clicked and on startup if option is enabled
        LeaPlusCB["SetWeatherDensity"]:HookScript("OnClick", SetWeatherFunc)
        LeaPlusCB["WeatherLevel"]:HookScript("OnValueChanged", SetWeatherFunc)
        if LeaPlusLC["SetWeatherDensity"] == "On" then
            SetWeatherFunc()
        end

        -- Prevent weather density from being changed when particle density is changed
        hooksecurefunc("SetCVar", function(setting, value)
            if setting and LeaPlusLC["SetWeatherDensity"] == "On" then
                if setting == "graphicsParticleDensity" then
                    if GetCVar("WeatherDensity") ~= LeaPlusLC["WeatherLevel"] then
                        LibCompat.After(0.1, function()
                            SetCVar("weatherDensity", LeaPlusLC["WeatherLevel"])
                        end)
                    end
                    --elseif setting == "raidGraphicsParticleDensity" then
                    --	if GetCVar("RAIDweatherDensity") ~= LeaPlusLC["WeatherLevel"] then
                    --		LibCompat.After(0.1, function()
                    --			SetCVar("RAIDweatherDensity", LeaPlusLC["WeatherLevel"])
                    --		end)
                    --	end
                end
            end
        end)

        -- Help button hidden
        weatherPanel.h:Hide()

        -- Back button handler
        weatherPanel.b:SetScript("OnClick", function()
            weatherPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page7"]:Show()
            return
        end)

        -- Reset button handler
        weatherPanel.r:SetScript("OnClick", function()

            -- Reset slider
            LeaPlusLC["WeatherLevel"] = 3

            -- Refresh side panel
            weatherPanel:Hide();
            weatherPanel:Show()

        end)

        -- Show configuration panal when options panel button is clicked
        LeaPlusCB["SetWeatherDensityBtn"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["WeatherLevel"] = 0
                SetWeatherFunc()
            else
                weatherPanel:Show()
                LeaPlusLC:HideFrames()
            end
        end)

    end

    ----------------------------------------------------------------------
    --	Enhance professions
    ----------------------------------------------------------------------

    if LeaPlusLC["EnhanceProfessions"] == "On" and not LeaLockList["EnhanceProfessions"] then

        -- Set increased height of professions frame and maximum number of recipes listed
        local tall, numTallProfs = 73, 19

        ----------------------------------------------------------------------
        --	TradeSkill Frame
        ----------------------------------------------------------------------

        local function TradeSkillFunc(frame)

            -- Make the tradeskill frame double-wide
            UIPanelWindows["TradeSkillFrame"] = { area = "override", pushable = 3, xoffset = 0, yoffset = 12, bottomClampOverride = 140 + 12, width = 714, height = 487, whileDead = 1 }

            -- Size the tradeskill frame
            _G["TradeSkillFrame"]:SetWidth(714)
            _G["TradeSkillFrame"]:SetHeight(487 + tall)

            -- Adjust title text
            _G["TradeSkillFrameTitleText"]:ClearAllPoints()
            _G["TradeSkillFrameTitleText"]:SetPoint("TOP", _G["TradeSkillFrame"], "TOP", 0, -18)

            -- Expand the tradeskill list to full height
            _G["TradeSkillListScrollFrame"]:ClearAllPoints()
            _G["TradeSkillListScrollFrame"]:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 25, -75)
            _G["TradeSkillListScrollFrame"]:SetSize(295, 336 + tall)

            -- Create additional list rows
            local oldTradeSkillsDisplayed = TRADE_SKILLS_DISPLAYED

            -- Position existing buttons
            for i = 1 + 1, TRADE_SKILLS_DISPLAYED do
                _G["TradeSkillSkill" .. i]:ClearAllPoints()
                _G["TradeSkillSkill" .. i]:SetPoint("TOPLEFT", _G["TradeSkillSkill" .. (i - 1)], "BOTTOMLEFT", 0, 1)
            end

            -- Create and position new buttons
            _G.TRADE_SKILLS_DISPLAYED = _G.TRADE_SKILLS_DISPLAYED + numTallProfs
            for i = oldTradeSkillsDisplayed + 1, TRADE_SKILLS_DISPLAYED do
                local button = CreateFrame("Button", "TradeSkillSkill" .. i, TradeSkillFrame, "TradeSkillSkillButtonTemplate")
                button:SetID(i)
                button:Hide()
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", _G["TradeSkillSkill" .. (i - 1)], "BOTTOMLEFT", 0, 1)
            end

            -- Set highlight bar width when shown
            hooksecurefunc(_G["TradeSkillHighlightFrame"], "Show", function()
                _G["TradeSkillHighlightFrame"]:SetWidth(290)
            end)

            -- Move the tradeskill detail frame to the right and stretch it to full height
            _G["TradeSkillDetailScrollFrame"]:ClearAllPoints()
            _G["TradeSkillDetailScrollFrame"]:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 352, -74)
            _G["TradeSkillDetailScrollFrame"]:SetSize(298, 336 + tall)
            -- _G["TradeSkillReagent1"]:SetHeight(500) -- Debug

            -- Hide detail scroll frame textures
            _G["TradeSkillDetailScrollFrameTop"]:SetAlpha(0)
            _G["TradeSkillDetailScrollFrameBottom"]:SetAlpha(0)

            -- Create texture for skills list
            local RecipeInset = _G["TradeSkillFrame"]:CreateTexture(nil, "ARTWORK")
            RecipeInset:SetSize(304, 361 + tall)
            RecipeInset:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 16, -72)
            RecipeInset:SetTexture("Interface\\RAIDFRAME\\UI-RaidFrame-GroupBg")

            -- Set detail frame backdrop
            local DetailsInset = _G["TradeSkillFrame"]:CreateTexture(nil, "ARTWORK")
            DetailsInset:SetSize(302, 339 + tall)
            DetailsInset:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 348, -72)
            DetailsInset:SetTexture("Interface\\addons\\Leatrix_Plus\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")
            -- DetailsInset:SetTexture(0.2, 0.2, 0.2, 1)


            -- Hide expand tab (left of All button)
            _G["TradeSkillExpandTabLeft"]:Hide()

            -- Hide skills list horizontal dividing bar (this hides it behind RecipeInset)
            TradeSkillHorizontalBarLeft:SetSize(1, 1)
            TradeSkillHorizontalBarLeft:Hide()

            -- Get tradeskill frame textures
            local regions = { _G["TradeSkillFrame"]:GetRegions() }

            -- Set top left texture
            regions[3]:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus")
            regions[3]:SetTexCoord(0.25, 0.75, 0, 1)
            regions[3]:SetSize(512, 512)

            -- Set top right texture
            regions[4]:ClearAllPoints()
            regions[4]:SetPoint("TOPLEFT", regions[3], "TOPRIGHT", 0, 0)
            regions[4]:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus")
            regions[4]:SetTexCoord(0.75, 1, 0, 1)
            regions[4]:SetSize(256, 512)

            -- Hide bottom left and bottom right textures
            TradeSkillFrameBottomLeftTexture:Hide()
            TradeSkillFrameBottomRightTexture:Hide()

            -- Hide horizonal bar in recipe list
            regions[8]:Hide()
            regions[9]:Hide() -- The shorter pesky horizontal bar that only shows sometimes (texture is 130968)

            -- Move skill rank text
            TradeSkillRankFrameSkillRank:ClearAllPoints()
            TradeSkillRankFrameSkillRank:SetPoint("TOP", TradeSkillRankFrame, "TOP", 0, -1)

            -- Move create button row
            _G["TradeSkillCreateButton"]:ClearAllPoints()
            _G["TradeSkillCreateButton"]:SetPoint("RIGHT", _G["TradeSkillCancelButton"], "LEFT", -1, 0)

            -- Position and size close button
            _G["TradeSkillCancelButton"]:SetSize(80, 22)
            _G["TradeSkillCancelButton"]:SetText(CLOSE)
            _G["TradeSkillCancelButton"]:ClearAllPoints()
            _G["TradeSkillCancelButton"]:SetPoint("BOTTOMRIGHT", _G["TradeSkillFrame"], "BOTTOMRIGHT", -42, 54)

            -- Position close box
            _G["TradeSkillFrameCloseButton"]:ClearAllPoints()
            _G["TradeSkillFrameCloseButton"]:SetPoint("TOPRIGHT", _G["TradeSkillFrame"], "TOPRIGHT", -30, -8)

            -- Position dropdown menus
            TradeSkillInvSlotDropDown:ClearAllPoints()
            TradeSkillInvSlotDropDown:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 510, -40)
            TradeSkillSubClassDropDown:ClearAllPoints()
            TradeSkillSubClassDropDown:SetPoint("RIGHT", TradeSkillInvSlotDropDown, "LEFT", 0, 0)

            -- Move search box below rank frame
            TradeSkillFrameEditBox:ClearAllPoints()
            TradeSkillFrameEditBox:SetPoint("TOPRIGHT", TradeSkillRankFrame, "BOTTOMRIGHT", 0, 1)
            TradeSkillFrameEditBox:SetFrameLevel(3)

            -- Move have materials checkbox down slightly
            TradeSkillFrameAvailableFilterCheckButton:ClearAllPoints()
            TradeSkillFrameAvailableFilterCheckButton:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 70, -53)

            -- Ensure have materials checkbox doesn't overlap search box
            TradeSkillFrameAvailableFilterCheckButtonText:SetWidth(110)
            TradeSkillFrameAvailableFilterCheckButtonText:SetWordWrap(false)
            TradeSkillFrameAvailableFilterCheckButtonText:SetJustifyH("LEFT")

            -- ElvUI fixes, in 3.3.5 this code doesnt matter, we dont tweak tradeskill if elvui is loaded
            if LeaPlusLC.ElvUI then
                local E = LeaPlusLC.ElvUI
                if E.private.skins.blizzard.enable and E.private.skins.blizzard.tradeskill then
                    regions[3]:Hide()
                    regions[4]:Hide()
                    RecipeInset:Hide()
                    DetailsInset:Hide()
                    _G["TradeSkillFrame"]:SetHeight(512 + tall)
                    _G["TradeSkillCancelButton"]:ClearAllPoints()
                    _G["TradeSkillCancelButton"]:SetPoint("BOTTOMRIGHT", _G["TradeSkillFrame"], "BOTTOMRIGHT", -42, 78)
                    _G["TradeSkillRankFrame"]:ClearAllPoints()
                    _G["TradeSkillRankFrame"]:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 24, -44)
                    _G["TradeSkillFrameEditBox"]:ClearAllPoints()
                    _G["TradeSkillFrameEditBox"]:SetPoint("TOPRIGHT", TradeSkillFrame, "TOPRIGHT", -392, -60)
                    _G["TradeSkillFrameAvailableFilterCheckButton"]:ClearAllPoints()
                    _G["TradeSkillFrameAvailableFilterCheckButton"]:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 20, -58)
                end
            end

            -- Classic Profession Filter addon fixes
            if IsAddOnLoaded("ClassicProfessionFilter") and TradeSkillFrame.SearchBox and TradeSkillFrame.HaveMats and TradeSkillFrame.HaveMats.text and TradeSkillFrame.SearchMats and TradeSkillFrame.SearchMats.text then
                TradeSkillFrame.SearchBox:ClearAllPoints()
                TradeSkillFrame.SearchBox:SetPoint("LEFT", TradeSkillRankFrame, "RIGHT", 20, -10)

                TradeSkillFrame.HaveMats:ClearAllPoints()
                TradeSkillFrame.HaveMats:SetPoint("LEFT", TradeSkillFrame.SearchBox, "RIGHT", 10, 8)
                TradeSkillFrame.HaveMats.text:SetText(L["Have mats?"])
                TradeSkillFrame.HaveMats:SetHitRectInsets(0, -TradeSkillFrame.HaveMats.text:GetStringWidth() + 4, 0, 0)
                TradeSkillFrame.HaveMats.text:SetJustifyH("LEFT")
                TradeSkillFrame.HaveMats.text:SetWordWrap(false)
                if TradeSkillFrame.HaveMats.text:GetWidth() > 80 then
                    TradeSkillFrame.HaveMats.text:SetWidth(80)
                    TradeSkillFrame.HaveMats:SetHitRectInsets(0, -80 + 4, 0, 0)
                end

                TradeSkillFrame.SearchMats:ClearAllPoints()
                TradeSkillFrame.SearchMats:SetPoint("BOTTOMLEFT", TradeSkillFrame.HaveMats, "BOTTOMLEFT", 0, -16)
                TradeSkillFrame.SearchMats.text:SetText(L["Search mats?"])
                TradeSkillFrame.SearchMats:SetHitRectInsets(0, -TradeSkillFrame.SearchMats.text:GetStringWidth() + 2, 0, 0)
                TradeSkillFrame.SearchMats.text:SetJustifyH("LEFT")
                TradeSkillFrame.SearchMats.text:SetWordWrap(false)
                if TradeSkillFrame.SearchMats.text:GetWidth() > 80 then
                    TradeSkillFrame.SearchMats.text:SetWidth(80)
                    TradeSkillFrame.SearchMats:SetHitRectInsets(0, -80 + 4, 0, 0)
                end
            end

        end

        -- Run function when TradeSkill UI has loaded
        if IsAddOnLoaded("Blizzard_TradeSkillUI") then
            TradeSkillFunc("TradeSkill")
        else
            local waitFrame = CreateFrame("FRAME")
            waitFrame:RegisterEvent("ADDON_LOADED")
            waitFrame:SetScript("OnEvent", function(self, event, arg1)
                if arg1 == "Blizzard_TradeSkillUI" then
                    TradeSkillFunc("TradeSkill")
                    waitFrame:UnregisterAllEvents()
                end
            end)
        end

    end

    ----------------------------------------------------------------------
    --	Enhance quest log
    ----------------------------------------------------------------------

    if LeaPlusLC["EnhanceQuestLog"] == "On" then

        -- Button to toggle quest headers
        LeaPlusLC:CreateButton("ToggleQuestHeaders", QuestLogFrame, "Collapse", "BOTTOMLEFT", 344, 54, 0, 22, true, "", false)
        LeaPlusCB["ToggleQuestHeaders"]:ClearAllPoints()
        LeaPlusCB["ToggleQuestHeaders"]:SetPoint("TOPRIGHT", QuestLogFrame, "TOPRIGHT", -360, -44)
        LeaPlusCB["ToggleQuestHeaders"]:GetFontString():SetWordWrap(false)

        local function SetHeadersButton()
            if LeaPlusCB["ToggleQuestHeaders"].collapsed then
                LeaPlusCB["ToggleQuestHeaders"]:SetText(L["Expand"])
            else
                LeaPlusCB["ToggleQuestHeaders"]:SetText(L["Collapse"])
            end
            local headerButtonWidth = LeaPlusCB["ToggleQuestHeaders"]:GetFontString():GetStringWidth() + 13.6
            if headerButtonWidth > 120 then
                headerButtonWidth = 120
            end
            LeaPlusCB["ToggleQuestHeaders"]:GetFontString():SetWidth(headerButtonWidth)
            LeaPlusCB["ToggleQuestHeaders"]:SetWidth(headerButtonWidth)
        end

        LeaPlusCB["ToggleQuestHeaders"]:HookScript("OnMouseDown", function(self, btn)
            if btn == "LeftButton" then
                if self.collapsed then
                    self.collapsed = nil
                    ExpandQuestHeader(0)
                    SetHeadersButton()
                else
                    self.collapsed = 1
                    -- QuestLogListScrollFrameScrollBar:SetValue(0)
                    CollapseQuestHeader(0)
                    SetHeadersButton()
                end
            end
        end)

        -- Show quest level in quest log detail frame (but not when turning in quest)
        hooksecurefunc("QuestLog_UpdateQuestDetails", function()
            if LeaPlusLC["EnhanceQuestLevels"] == "On" then
                local quest = GetQuestLogSelection()
                if quest then
                    local title, level, suggestedGroup = GetQuestLogTitle(quest)
                    if title and level then
                        if suggestedGroup then
                            if suggestedGroup == LFG_TYPE_DUNGEON then
                                level = level .. "D"
                            elseif suggestedGroup == RAID then
                                level = level .. "R"
                            elseif suggestedGroup == ELITE then
                                level = level .. "+"
                            elseif suggestedGroup == GROUP then
                                level = level .. "+"
                            elseif suggestedGroup == PVP then
                                level = level .. "P"
                            end
                        end
                        QuestInfoTitleHeader:SetText("[" .. level .. "] " .. title)
                    end
                end
            end
        end)

        -- Show quest levels in quest log
        hooksecurefunc("QuestLogTitleButton_Resize", function(questLogTitle)
            if LeaPlusLC["EnhanceQuestLevels"] == "On" and not questLogTitle.isHeader then
                local questIndex = questLogTitle:GetID()
                local title, level, suggestedGroup = GetQuestLogTitle(questIndex)
                local questTitleTag = questLogTitle.tag
                local questNormalText = questLogTitle.normalText
                local questCheck = questLogTitle.check

                if level and level > 0 and level < 10 then
                    level = "0" .. level
                end

                if suggestedGroup and LeaPlusLC["EnhanceQuestDifficulty"] == "On" then
                    if suggestedGroup == LFG_TYPE_DUNGEON then
                        level = level .. "D"
                    elseif suggestedGroup == RAID then
                        level = level .. "R"
                    elseif suggestedGroup == ELITE then
                        level = level .. "+"
                    elseif suggestedGroup == GROUP then
                        level = level .. "+"
                    elseif suggestedGroup == PVP then
                        level = level .. "P"
                    end
                end

                questNormalText:SetWidth(0)
                if title then
                    questNormalText:SetText("  [" .. level .. "] " .. title)
                end

                -- Debug
                -- questLogTitle.normalText:SetText("  [80] Learning to Leave and Return The")

                -- From QuestLogTitleButton_Resize
                local rightEdge
                if questTitleTag:IsShown() then
                    if questCheck:IsShown() then
                        rightEdge = questLogTitle:GetLeft() + questLogTitle:GetWidth() - questTitleTag:GetWidth() - 4 - questCheck:GetWidth() - 2
                    else
                        rightEdge = questLogTitle:GetLeft() + questLogTitle:GetWidth() - questTitleTag:GetWidth() - 4
                    end
                else
                    if questCheck:IsShown() then
                        rightEdge = questLogTitle:GetLeft() + questLogTitle:GetWidth() - questCheck:GetWidth() - 2
                    else
                        rightEdge = questLogTitle:GetLeft() + questLogTitle:GetWidth()
                    end
                end
                -- subtract from the text width the number of pixels that overrun the right edge
                local questNormalTextWidth = questNormalText:GetWidth() - max(questNormalText:GetRight() - rightEdge, 0)
                questNormalText:SetWidth(questNormalTextWidth)
            end
        end)

        -- Create configuration panel
        local EnhanceQuestPanel = LeaPlusLC:CreatePanel("Enhance quest log", "EnhanceQuestPanel")

        LeaPlusLC:MakeTx(EnhanceQuestPanel, "Settings", 16, -72)
        LeaPlusLC:MakeCB(EnhanceQuestPanel, "EnhanceQuestHeaders", "Show toggle headers button", 16, -92, false, "If checked, the toggle headers button will be shown.")

        LeaPlusLC:MakeTx(EnhanceQuestPanel, "Levels", 16, -132)
        LeaPlusLC:MakeCB(EnhanceQuestPanel, "EnhanceQuestLevels", "Show quest levels", 16, -152, false, "If checked, quest levels will be shown.")
        LeaPlusLC:MakeCB(EnhanceQuestPanel, "EnhanceQuestDifficulty", "Show quest difficulty in quest log list", 16, -172, false, "If checked, the quest difficulty will be shown next to the quest level in the quest log list.|n|nThis will indicate whether the quest requires a group (+), dungeon (D), raid (R) or PvP (P).|n|nThe quest difficulty will always be shown in the quest log detail pane regardless of this setting.")

        -- Disable Show quest difficulty option if Show quest levels is disabled
        LeaPlusCB["EnhanceQuestLevels"]:HookScript("OnClick", function()
            LeaPlusLC:LockOption("EnhanceQuestLevels", "EnhanceQuestDifficulty", false)
        end)
        LeaPlusLC:LockOption("EnhanceQuestLevels", "EnhanceQuestDifficulty", false)

        -- Help button hidden
        EnhanceQuestPanel.h:Hide()

        -- Back button handler
        EnhanceQuestPanel.b:SetScript("OnClick", function()
            EnhanceQuestPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page5"]:Show();
            return
        end)

        -- Function to set toggle headers button
        local function SetQuestHeaderFunc()
            if LeaPlusLC["EnhanceQuestHeaders"] == "On" then
                LeaPlusCB["ToggleQuestHeaders"]:Show()
            else
                LeaPlusCB["ToggleQuestHeaders"]:Hide()
            end
        end

        -- Set toggle headers button when setting is clicked and on startup
        LeaPlusCB["EnhanceQuestHeaders"]:HookScript("OnClick", SetQuestHeaderFunc)
        SetQuestHeaderFunc()

        -- Reset button handler
        EnhanceQuestPanel.r.tiptext = EnhanceQuestPanel.r.tiptext .. "|n|n" .. L["Note that this will not reset settings that require a UI reload."]
        EnhanceQuestPanel.r:SetScript("OnClick", function()

            -- Reset checkboxes
            LeaPlusLC["EnhanceQuestHeaders"] = "On";
            SetQuestHeaderFunc()
            LeaPlusLC["EnhanceQuestLevels"] = "On"
            LeaPlusLC["EnhanceQuestDifficulty"] = "On"

            -- Refresh panel
            EnhanceQuestPanel:Hide();
            EnhanceQuestPanel:Show()

        end)

        -- Show panal when options panel button is clicked
        LeaPlusCB["EnhanceQuestLogBtn"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["EnhanceQuestHeaders"] = "On";
                SetQuestHeaderFunc()
                LeaPlusLC["EnhanceQuestLevels"] = "On"
                LeaPlusLC["EnhanceQuestDifficulty"] = "On"
            else
                EnhanceQuestPanel:Show()
                LeaPlusLC:HideFrames()
            end
        end)

    end

    ----------------------------------------------------------------------
    --	Show bag search box
    ----------------------------------------------------------------------

    if LeaPlusLC["ShowBagSearchBox"] == "On" and not LeaLockList["ShowBagSearchBox"] then

        -- -- Function to unregister search event for guild bank since it isn't used
        -- local function SetGuildBankFunc()
        -- 	for i = 1, 6 do
        -- 		_G["GuildBankTab" .. i].Button:UnregisterEvent("INVENTORY_SEARCH_UPDATE")
        -- 	end
        -- end

        -- -- Run search event function when Blizzard addon is loaded
        -- if IsAddOnLoaded("Blizzard_GuildBankUI") then
        -- 	-- SetGuildBankFunc()
        -- else
        -- 	local waitFrame = CreateFrame("FRAME")
        -- 	waitFrame:RegisterEvent("ADDON_LOADED")
        -- 	waitFrame:SetScript("OnEvent", function(self, event, arg1)
        -- 		if arg1 == "Blizzard_GuildBankUI" then
        -- 			-- SetGuildBankFunc()
        -- 			waitFrame:UnregisterAllEvents()
        -- 		end
        -- 	end)
        -- end



        local function SearchEditBox_OnTextChanged(editBox)
            local text = editBox:GetText()
            if not text or text:trim() == "" then
                editBox.clearButton:Hide()
            else
                editBox.clearButton:Show()
                SearchEditBox_UpdateButton()
            end
        end

        local function SearchEditBox_OnEnterPressed(editBox)
            editBox:ClearFocus()
            SearchEditBox_UpdateButton()
            Leatrix_EnableAllBagLayers()
            return SearchEditBox_OnTextChanged(editBox)
        end

        local function SearchEditBox_OnEscapePressed(editBox)
            editBox:ClearFocus()
            editBox:SetText('')
            SearchEditBox_UpdateButton()
            Leatrix_EnableAllBagLayers()
            return SearchEditBox_OnTextChanged(editBox)
        end

        --===== Setup Edit Box for Searching =====--
        local searchEditBox = CreateFrame("EditBox", "Leatrix_SearchFrame", ContainerFrame1MoneyFrame, "InputBoxTemplate")
        searchEditBox:SetSize(120, 15)
        searchEditBox:SetPoint("TOPRIGHT", ContainerFrame1MoneyFrame, "TOPRIGHT", -9, 185)

        searchEditBox:SetAutoFocus(false)
        searchEditBox:SetTextInsets(14, 20, 0, 0)
        searchEditBox:SetScript("OnEnterPressed", SearchEditBox_OnEnterPressed)
        searchEditBox:SetScript("OnEscapePressed", SearchEditBox_OnEscapePressed)
        searchEditBox:SetScript("OnTextChanged", SearchEditBox_OnTextChanged)
        LTP_searchEditBox = searchEditBox

        --===== Search Icon =====--
        local searchIcon = searchEditBox:CreateTexture(nil, "OVERLAY")
        searchIcon:SetPoint("LEFT", 0, -2)
        searchIcon:SetSize(14, 14)
        searchIcon:SetTexture([[Interface\Common\UI-Searchbox-Icon]])
        searchIcon:SetVertexColor(0.6, 0.6, 0.6)

        --===== Setup Tooltip =====--
        local function onEnterSearchBox()
            GameTooltip:SetOwner(searchEditBox, "ANCHOR_RIGHT")
            GameTooltip:SetText("Item Search")
            GameTooltip:AddLine("Enter your search query.")
            GameTooltip:Show()
        end

        local function onLeaveSearchBox()
            GameTooltip:Hide()
        end

        searchEditBox:SetScript("OnEnter", onEnterSearchBox)
        searchEditBox:SetScript("OnLeave", onLeaveSearchBox)

        --===== Close Button =====--
        local searchClearButton = CreateFrame("Button", nil, searchEditBox, "UIPanelButtonTemplate")
        searchClearButton:SetPoint("RIGHT")
        searchClearButton:SetSize(20, 20)
        searchClearButton:SetText("X")
        searchClearButton:Hide()
        searchClearButton:SetScript('OnClick', function()
            SearchEditBox_OnEscapePressed(searchEditBox)
        end)

        searchEditBox.clearButton = searchClearButton


        --===== Table That Contains Matching Items =====--
        function LeatrixBagContains(table, val)
            for _, v in pairs(table) do
                if v == val then
                    return true
                end
            end
            return false
        end

        --===== Function with loops to iterate through bag slots =====--
        function SearchEditBox_UpdateButton(event, button)
            local links, found = {}, false

            for bag = 0, NUM_BAG_SLOTS do
                for i = 1, _G["ContainerFrame" .. (bag + 1)].size do
                    local itemButton = _G["ContainerFrame" .. (bag + 1) .. "Item" .. i]
                    if itemButton then
                        local link = GetContainerItemLink(bag, itemButton:GetID())
                        if link and link:lower():find(LTP_searchEditBox:GetText():lower(), 1, true) then
                            table.insert(links, link)
                            itemButton:EnableDrawLayer("BORDER")
                            itemButton:EnableDrawLayer("OVERLAY")
                            found = true
                        else
                            itemButton:DisableDrawLayer("BORDER")
                            itemButton:DisableDrawLayer("OVERLAY")
                        end
                    end
                end

            end

            if not found then
                for bag = 0, NUM_BAG_SLOTS do
                    for i = 1, _G["ContainerFrame" .. (bag + 1)].size do
                        _G["ContainerFrame" .. (bag + 1) .. "Item" .. i]:EnableDrawLayer("BORDER")
                        _G["ContainerFrame" .. (bag + 1) .. "Item" .. i]:EnableDrawLayer("OVERLAY")
                    end
                end

            end
        end


        --===== Function to re-enable button layers =====--
        function Leatrix_EnableAllBagLayers()
            for bag = 0, NUM_BAG_SLOTS do
                -- made it "or 0" because seems that if interact with vendor without first opening bag "_G["ContainerFrame"..(bag+1)].size" is nil.
                for i = 1, (_G["ContainerFrame" .. (bag + 1)].size or 0) do
                    local itemButton = _G["ContainerFrame" .. (bag + 1) .. "Item" .. i]
                    if itemButton then
                        itemButton:EnableDrawLayer("BORDER")
                        itemButton:EnableDrawLayer("OVERLAY")
                    end
                end
            end
        end

        --===== Function to trigger re-enabling layers for buttons =====--
        --===== 0.1 delay is made for initial bag opening LUA error avoiding =====--
        local function Leatrix_ToggleBags()
            LibCompat.After(0.1, Leatrix_EnableAllBagLayers)
        end

        --===== We are using Blizzard functions as triggers to trigger our layer-enabling function =====--
        hooksecurefunc("ToggleBackpack", Leatrix_ToggleBags)
        hooksecurefunc("ToggleBag", Leatrix_ToggleBags)





        -- -- Create bag item search box
        -- local BagItemSearchBox = CreateFrame("EditBox", "BagItemSearchBox", ContainerFrame1, "BagSearchBoxTemplate")
        -- BagItemSearchBox:SetSize(110, 18)
        -- BagItemSearchBox:SetMaxLetters(15)

        -- -- Create bank item search box
        -- local BankItemSearchBox = CreateFrame("EditBox", "BankItemSearchBox", BankFrame, "BagSearchBoxTemplate")
        -- BankItemSearchBox:SetSize(120, 14)
        -- BankItemSearchBox:SetMaxLetters(15)
        -- BankItemSearchBox:SetPoint("TOPRIGHT", -60, -40)

        -- -- Attach bag search box first bag only
        -- hooksecurefunc("ContainerFrame_Update", function(self)
        -- 	if self:GetID() == 0 then
        -- 		BagItemSearchBox:SetParent(self)
        -- 		BagItemSearchBox:SetPoint("TOPLEFT", self, "TOPLEFT", 54, -29)
        -- 		BagItemSearchBox.anchorBag = self
        -- 		BagItemSearchBox:Show()
        -- 	elseif BagItemSearchBox.anchorBag == self then
        -- 		BagItemSearchBox:ClearAllPoints()
        -- 		BagItemSearchBox:Hide()
        -- 		BagItemSearchBox.anchorBag = nil
        -- 	end
        -- end)

    end

    ----------------------------------------------------------------------
    --	Show vendor price
    ----------------------------------------------------------------------

    --if LeaPlusLC["ShowVendorPrice"] == "On" then
    --
    --	-- Function to show vendor price
    --	local function ShowSellPrice(tooltip, tooltipObject)
    --		if tooltip.shownMoneyFrames then return end
    --		tooltipObject = tooltipObject or GameTooltip
    --		-- Get container
    --		local container = GetMouseFocus()
    --		if not container then return end
    --		-- Get item
    --		local itemName, itemlink = tooltipObject:GetItem()
    --		if not itemlink then return end
    --		local void, void, void, void, void, void, void, void, void, void, sellPrice, classID = GetItemInfo(itemlink)
    --		if sellPrice and sellPrice > 0 then
    --			local count = container and type(container.count) == "number" and container.count or 1
    --			if sellPrice and count > 0 then
    --				if classID and classID == 11 then count = 1 end -- Fix for quiver/ammo pouch so ammo is not included
    --				SetTooltipMoney(tooltip, sellPrice * count, "STATIC", SELL_PRICE .. ":")
    --			end
    --		end
    --		-- Refresh chat tooltips
    --		if tooltipObject == ItemRefTooltip then ItemRefTooltip:Show() end
    --	end
    --
    --	-- Show vendor price when tooltips are shown
    --	GameTooltip:HookScript("OnTooltipSetItem", ShowSellPrice)
    --	hooksecurefunc(GameTooltip, "SetHyperlink", function(tip) ShowSellPrice(tip, GameTooltip) end)
    --	hooksecurefunc(ItemRefTooltip, "SetHyperlink", function(tip) ShowSellPrice(tip, ItemRefTooltip) end)
    --
    --end

    ----------------------------------------------------------------------
    --	Dismount me
    ----------------------------------------------------------------------

    --if LeaPlusLC["StandAndDismount"] == "On" then
    --
    --	local eFrame = CreateFrame("FRAME")
    --	eFrame:RegisterEvent("UI_ERROR_MESSAGE")
    --	eFrame:SetScript("OnEvent", function(self, event, messageType, msg)
    --		-- Auto dismount
    --		if msg == ERR_OUT_OF_RAGE and LeaPlusLC["DismountNoResource"] == "On"
    --		or msg == ERR_OUT_OF_MANA and LeaPlusLC["DismountNoResource"] == "On"
    --		or msg == ERR_OUT_OF_ENERGY and LeaPlusLC["DismountNoResource"] == "On"
    --		or msg == SPELL_FAILED_MOVING and LeaPlusLC["DismountNoMoving"] == "On"
    --		or msg == ERR_TAXIPLAYERSHAPESHIFTED
    --		then
    --			local void, class = UnitClass("player")
    --			if class == "SHAMAN" and GetShapeshiftFormID() then
    --				-- Cancel Ghost Wolf
    --				RunScript('CancelShapeshiftForm()')
    --			end
    --			if IsMounted() then
    --				Dismount()
    --				UIErrorsFrame:Clear()
    --			end
    --		end
    --	end)
    --
    --	-- Dismount when flight point map is opened
    --	local taxiFrame = CreateFrame("FRAME")
    --	taxiFrame:RegisterEvent("TAXIMAP_OPENED")
    --	taxiFrame:SetScript("OnEvent", function()
    --		local void, class = UnitClass("player")
    --		if class == "SHAMAN" and GetShapeshiftFormID() then
    --			-- Cancel Ghost Wolf
    --			RunScript('CancelShapeshiftForm()')
    --		end
    --		if IsMounted() then Dismount() end
    --	end)
    --
    --	-- Create configuration panel
    --	local DismountFrame = LeaPlusLC:CreatePanel("Dismount me", "DismountFrame")
    --
    --	LeaPlusLC:MakeTx(DismountFrame, "Settings", 16, -72)
    --	LeaPlusLC:MakeCB(DismountFrame, "DismountNoResource", "Dismount when not enough rage, mana or energy", 16, -92, false, "If checked, you will be dismounted when you attempt to cast a spell but don't have the rage, mana or energy to cast it.")
    --	LeaPlusLC:MakeCB(DismountFrame, "DismountNoMoving", "Dismount when casting a spell while moving", 16, -112, false, "If checked, you will be dismounted when you attempt to cast a non-instant cast spell while moving.")
    --	LeaPlusLC:MakeCB(DismountFrame, "DismountNoTaxi", "Dismount when the flight map opens", 16, -132, false, "If checked, you will be dismounted when you instruct a flight master to open the flight map.")
    --	LeaPlusLC:MakeCB(DismountFrame, "DismountShowFormBtn", "Show cancel form button on flight map", 16, -152, false, "If checked, a cancel form button will be shown on the flight map while you are playing as a shapeshifted druid or shaman.")
    --
    --	-- Help button hidden
    --	DismountFrame.h.tiptext = L["The game will dismount you if you successfully cast a spell without addons.  These settings let you set some additional dismount rules."]
    --
    --	-- Back button handler
    --	DismountFrame.b:SetScript("OnClick", function()
    --		DismountFrame:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
    --		return
    --	end)
    --
    --	-- Function to set dismount options
    --	local function SetDismount()
    --		if LeaPlusLC["DismountNoTaxi"] == "On" then
    --			taxiFrame:RegisterEvent("TAXIMAP_OPENED")
    --		else
    --			taxiFrame:UnregisterEvent("TAXIMAP_OPENED")
    --		end
    --	end
    --
    --	-- Run function when certain options are clicked and on startup
    --	LeaPlusCB["DismountNoTaxi"]:HookScript("OnClick", SetDismount)
    --	SetDismount()
    --
    --	-- Reset button handler
    --	DismountFrame.r:SetScript("OnClick", function()
    --
    --		-- Reset checkboxes
    --		LeaPlusLC["DismountNoResource"] = "On"
    --		LeaPlusLC["DismountNoMoving"] = "On"
    --		LeaPlusLC["DismountNoTaxi"] = "On"
    --		LeaPlusLC["DismountShowFormBtn"] = "On"
    --
    --		-- Update settings and configuration panel
    --		SetDismount()
    --		DismountFrame:Hide(); DismountFrame:Show()
    --
    --	end)
    --
    --	-- Show configuration panal when options panel button is clicked
    --	LeaPlusCB["DismountBtn"]:SetScript("OnClick", function()
    --		if IsShiftKeyDown() and IsControlKeyDown() then
    --			-- Preset profile
    --			LeaPlusLC["DismountNoResource"] = "On"
    --			LeaPlusLC["DismountNoMoving"] = "On"
    --			LeaPlusLC["DismountNoTaxi"] = "On"
    --			LeaPlusLC["DismountShowFormBtn"] = "On"
    --			SetDismount()
    --		else
    --			DismountFrame:Show()
    --			LeaPlusLC:HideFrames()
    --		end
    --	end)
    --
    --	-- Druid cancel form button
    --	local void, class = UnitClass("player")
    --	if class == "DRUID" or class == "SHAMAN" then
    --
    --		-- Create button
    --		local cancelFormBtn = CreateFrame("Button", nil, TaxiFrame, "InsecureActionButtonTemplate")
    --		cancelFormBtn:SetAttribute("type", "macro")
    --		cancelFormBtn:SetAttribute("macrotext", "/cancelform")
    --		cancelFormBtn:ClearAllPoints()
    --		cancelFormBtn:SetSize(24, 24)
    --		cancelFormBtn:SetPoint("TOPRIGHT", TaxiFrame, "TOPRIGHT", -46, -46)
    --		cancelFormBtn:SetNormalTexture("Interface\\ICONS\\Achievement_Character_Nightelf_Female")
    --		cancelFormBtn:SetPushedTexture("Interface\\ICONS\\Achievement_Character_Nightelf_Female")
    --		cancelFormBtn:SetHighlightTexture("Interface\\ICONS\\Achievement_Character_Nightelf_Female")
    --
    --		-- Button message
    --		cancelFormBtn.f = cancelFormBtn:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    --		cancelFormBtn.f:SetHeight(32)
    --		cancelFormBtn.f:SetPoint('RIGHT', cancelFormBtn, 'LEFT', -10, 0)
    --		cancelFormBtn.f:SetText(L["Click to unshift"])
    --
    --		-- Toggle button when form changes
    --		cancelFormBtn:SetScript("OnEvent", function()
    --			local form = GetShapeshiftForm() or 0
    --			if form ~= 0 then
    --				if not cancelFormBtn:IsShown() then	cancelFormBtn:Show() end
    --			else
    --				cancelFormBtn:Hide()
    --			end
    --		end)
    --
    --		-- Function to set event and button status
    --		local function SetShiftEvent()
    --			if LeaPlusLC["DismountShowFormBtn"] == "On" then
    --				cancelFormBtn:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    --				local form = GetShapeshiftForm() or 0
    --				if form ~= 0 then cancelFormBtn:Show() else cancelFormBtn:Hide() end
    --			else
    --				cancelFormBtn:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
    --				cancelFormBtn:Hide()
    --			end
    --		end
    --
    --		-- Set button when option is clicked, when reset button is clicked, preset profile and on startup
    --		LeaPlusCB["DismountShowFormBtn"]:HookScript("OnClick", SetShiftEvent)
    --		DismountFrame.r:HookScript("OnClick", SetShiftEvent)
    --		LeaPlusCB["DismountBtn"]:HookScript("OnClick", function()
    --			if IsShiftKeyDown() and IsControlKeyDown() then	SetShiftEvent() end
    --		end)
    --		SetShiftEvent()
    --
    --	end
    --
    --end

    ----------------------------------------------------------------------
    --	Use class colors in chat
    ----------------------------------------------------------------------

    if LeaPlusLC["ClassColorsInChat"] == "On" and not LeaLockList["ClassColorsInChat"] then

        -- SetCVar("chatClassColorOverride", "0")

        LibCompat.After(0.1, function()

            -- Set local channel colors and lock checkboxes
            for i = 1, 18 do
                if _G["ChatConfigChatSettingsLeftCheckBox" .. i .. "Check"] then
                    ToggleChatColorNamesByClassGroup(true, _G["ChatConfigChatSettingsLeftCheckBox" .. i .. "Check"]:GetParent().type)
                    if _G["ChatConfigChatSettingsLeftCheckBox" .. i .. "ColorClasses"] then
                        LeaPlusLC:LockItem(_G["ChatConfigChatSettingsLeftCheckBox" .. i .. "ColorClasses"], true)
                    end
                end
            end

            -- Set global channel colors
            for i = 1, 50 do
                ToggleChatColorNamesByClassGroup(true, "CHANNEL" .. i)
            end

            -- Lock global channel checkboxes on startup
            hooksecurefunc("ChatConfig_CreateCheckboxes", function(self, checkBoxTable, checkBoxTemplate, title)
                if ChatConfigChannelSettingsLeft.checkBoxTable then
                    for i = 1, 50 do
                        if _G["ChatConfigChannelSettingsLeftCheckBox" .. i .. "ColorClasses"] then
                            LeaPlusLC:LockItem(_G["ChatConfigChannelSettingsLeftCheckBox" .. i .. "ColorClasses"], true)
                        end
                    end
                end
            end)

        end)

    end

    ----------------------------------------------------------------------
    -- Disable screen glow (no reload required)
    ----------------------------------------------------------------------

    do

        -- Function to set screen glow
        local function SetGlow()
            if LeaPlusLC["NoScreenGlow"] == "On" then
                SetCVar("ffxGlow", "0")
            else
                SetCVar("ffxGlow", "1")
            end
        end

        -- Set screen glow on startup and when option is clicked (if enabled)
        LeaPlusCB["NoScreenGlow"]:HookScript("OnClick", SetGlow)
        if LeaPlusLC["NoScreenGlow"] == "On" then
            SetGlow()
        end

    end

    ----------------------------------------------------------------------
    -- Disable screen effects (no reload required)
    ----------------------------------------------------------------------

    do

        -- Function to set screen effects
        local function SetEffects()
            if LeaPlusLC["NoScreenEffects"] == "On" then
                SetCVar("ffxDeath", "0")
                SetCVar("ffxNetherWorld", "0")
            else
                SetCVar("ffxDeath", "1")
                SetCVar("ffxNetherWorld", "1")
            end
        end

        -- Set screen effects when option is clicked and on startup (if enabled)
        LeaPlusCB["NoScreenEffects"]:HookScript("OnClick", SetEffects)
        if LeaPlusLC["NoScreenEffects"] == "On" then
            SetEffects()
        end

    end

    ----------------------------------------------------------------------
    -- Universal group chat color (no reload required)
    ----------------------------------------------------------------------

    do

        -- Function to set chat colors
        local function SetCol()
            if LeaPlusLC["UnivGroupColor"] == "On" then
                ChangeChatColor("RAID", 0.67, 0.67, 1)
                ChangeChatColor("RAID_LEADER", 0.46, 0.78, 1)
            else
                ChangeChatColor("RAID", 1, 0.50, 0)
                ChangeChatColor("RAID_LEADER", 1, 0.28, 0.04)
            end
        end

        -- Set chat colors when option is clicked and on startup (if enabled)
        LeaPlusCB["UnivGroupColor"]:HookScript("OnClick", SetCol)
        if LeaPlusLC["UnivGroupColor"] == "On" then
            SetCol()
        end

    end

    ----------------------------------------------------------------------
    -- Minimap button (no reload required)
    ----------------------------------------------------------------------

    do

        -- Minimap button click function
        local function MiniBtnClickFunc(arg1)

            if LeaPlusLC["LeaPlusFrameMove"] and LeaPlusLC["LeaPlusFrameMove"]:IsShown() then
                return
            end
            if LeaPlusCB["TooltipDragFrame"] and LeaPlusCB["TooltipDragFrame"]:IsShown() then
                return
            end
            if InterfaceOptionsFrame:IsShown() or VideoOptionsFrame:IsShown() then
                return
            end

            if arg1 == "LeftButton" and not IsAltKeyDown() then
                -- No modifier key toggles the options panel
                if LeaPlusLC:IsPlusShowing() then
                    LeaPlusLC:HideFrames()
                    LeaPlusLC:HideConfigPanels()
                else
                    LeaPlusLC:HideFrames()
                    LeaPlusLC["PageF"]:Show()
                end
                LeaPlusLC["Page" .. LeaPlusLC["LeaStartPage"]]:Show()
            end
            if arg1 == "RightButton" and not IsAltKeyDown() then
                ReloadUI();
            end

            -- Add ALT-click functionality here
            if (arg1 == "LeftButton" or arg1 == "RightButton") and IsAltKeyDown() then
                if LeaPlusLC["HideErrorMessages"] == "On" then
                    LeaPlusLC["HideErrorMessages"] = "Off"
                    ActionStatus_DisplayMessage(L["Error messages will be shown"], true)
                else
                    LeaPlusLC["HideErrorMessages"] = "On"
                    ActionStatus_DisplayMessage(L["Error messages will be hidden"], true)
                end
                -- Update the visibility based on the new setting
                LeaPlusLC:UpdateErrorMessageVisibility()

                -- Update the checkbox state in the options panel
                LeaPlusCB["HideErrorMessages"]:SetChecked(LeaPlusLC["HideErrorMessages"] == "On")
            end


        end

        -- Create minimap button using LibDBIcon
        local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("Leatrix_Plus", {
            type = "data source",
            text = "Leatrix Plus",
            icon = "Interface\\addons\\Leatrix_Plus\\assets\\minimapicon.tga",
            OnClick = function(self, btn)
                MiniBtnClickFunc(btn)
            end,
            OnTooltipShow = function(tooltip)
                if not tooltip or not tooltip.AddLine then
                    return
                end
                tooltip:AddLine("Leatrix Plus")
                tooltip:AddLine("|cffeda55fClick|r |cff99ff00to open Leatrix Plus options.|r")
                tooltip:AddLine("|cffeda55fRight-Click|r |cff99ff00to reload the user interface.|r")

                -- Toggle error message line color based on HideErrorMessages state
                if LeaPlusLC["HideErrorMessages"] == "On" then
                    tooltip:AddLine("|cffcc3333Alt-Click|r |cff99ff00to toggle error messages.|r")  -- Red color if On
                else
                    tooltip:AddLine("|cffeda55fAlt-Click|r |cff99ff00to toggle error messages.|r")  -- Default color if Off
                end
            end,
        })

        local icon = LibStub("LibDBIcon-1.0", true)
        icon:Register("Leatrix_Plus", miniButton, LeaPlusDB)

        -- Function to toggle LibDBIcon
        local function SetLibDBIconFunc()
            if LeaPlusLC["ShowMinimapIcon"] == "On" then
                LeaPlusDB["hide"] = false
                icon:Show("Leatrix_Plus")
            else
                LeaPlusDB["hide"] = true
                icon:Hide("Leatrix_Plus")
            end
        end

        -- Set LibDBIcon when option is clicked and on startup
        LeaPlusCB["ShowMinimapIcon"]:HookScript("OnClick", SetLibDBIconFunc)
        SetLibDBIconFunc()
    end

    ----------------------------------------------------------------------
    -- Auction House Extras
    ----------------------------------------------------------------------

    if LeaPlusLC["AhExtras"] == "On" then

        local function AuctionFunc()

            -- Update duration radio button

            -- if AuctionFrameAuctions.duration == 1 then
            -- 	AuctionsShortAuctionButton:SetChecked(true)
            -- elseif AuctionFrameAuctions.duration == 2 then
            -- 	AuctionsMediumAuctionButton:SetChecked(true)
            -- elseif AuctionFrameAuctions.duration == 3 then
            -- 	AuctionsLongAuctionButton:SetChecked(true)
            -- end

            --===== 3.3.5 Took And Modified code from Panda Leatrix :) =====--
            hooksecurefunc("DurationDropDown_Initialize", function(self)
                if not LeaPlusDB["AHDuration"] or type(LeaPlusDB["AHDuration"]) ~= "number" or LeaPlusDB["AHDuration"] < 1 or LeaPlusDB["AHDuration"] > 3 then
                    LeaPlusDB["AHDuration"] = AuctionFrameAuctions.duration;
                else
                    AuctionFrameAuctions.duration = LeaPlusDB["AHDuration"];
                end
            end)

            hooksecurefunc("DurationDropDown_OnClick", function(self)
                LeaPlusDB["AHDuration"] = AuctionFrameAuctions.duration;
            end)



            -- Functions
            local function CreateAuctionCB(name, anchor, x, y, text)
                LeaPlusCB[name] = CreateFrame("CheckButton", nil, AuctionFrameAuctions, "OptionsCheckButtonTemplate")
                LeaPlusCB[name]:SetFrameStrata("HIGH")
                LeaPlusCB[name]:SetSize(20, 20)
                LeaPlusCB[name]:SetPoint(anchor, x, y)
                LeaPlusCB[name].f = LeaPlusCB[name]:CreateFontString(nil, 'OVERLAY', "GameFontNormal")
                LeaPlusCB[name].f:SetPoint("LEFT", 20, 0)
                LeaPlusCB[name].f:SetText(L[text])
                LeaPlusCB[name].f:Show();
                LeaPlusCB[name]:SetScript('OnClick', function()
                    if LeaPlusCB[name]:GetChecked() then
                        LeaPlusLC[name] = "On"
                    else
                        LeaPlusLC[name] = "Off"
                    end
                end)
                LeaPlusCB[name]:SetScript('OnShow', function(self)
                    if LeaPlusLC[name] == "On" then
                        self:SetChecked(true)
                    else
                        self:SetChecked(false)
                    end
                end)
            end

            -- Show the correct fields in the AH frame and match prices
            local function SetupAh()

                if LeaPlusLC["AhGoldOnly"] == "On" and LeaPlusLC["AhBuyoutOnly"] == "On" then
                    LeaPlusCB["AhTabConfirm"]:Show()
                else
                    LeaPlusCB["AhTabConfirm"]:Hide()
                end

                if LeaPlusLC["AhBuyoutOnly"] == "On" then
                    -- Hide the start price
                    StartPrice:SetAlpha(0);
                    -- Set start price to buyout price
                    StartPriceGold:SetText(BuyoutPriceGold:GetText());
                    StartPriceSilver:SetText(BuyoutPriceSilver:GetText());
                    StartPriceCopper:SetText(BuyoutPriceCopper:GetText());
                else
                    -- Show the start price
                    StartPrice:SetAlpha(1);
                end
                -- If gold only is on, set copper and silver to 99
                if LeaPlusLC["AhGoldOnly"] == "On" then
                    StartPriceCopper:SetText("00");
                    StartPriceCopper:Hide();
                    StartPriceSilver:SetText("00");
                    StartPriceSilver:Hide();
                    BuyoutPriceCopper:SetText("00");
                    BuyoutPriceCopper:Hide();
                    BuyoutPriceSilver:SetText("00");
                    BuyoutPriceSilver:Hide();
                else
                    StartPriceCopper:Show();
                    StartPriceSilver:Show();
                    BuyoutPriceCopper:Show();
                    BuyoutPriceSilver:Show();
                end
                -- Validate the auction (mainly for the create auction button status)
                AuctionsFrameAuctions_ValidateAuction()
            end

            if not LeaPlusLC.ElvUI then
                -- Create checkboxes
                CreateAuctionCB("AhBuyoutOnly", "BOTTOMLEFT", 200, 16, "Buyout Only")
                CreateAuctionCB("AhGoldOnly", "BOTTOMLEFT", 320, 16, "Gold Only")
                CreateAuctionCB("AhTabConfirm", "BOTTOMLEFT", 440, 16, "Tab To Confirm")
            end

            if LeaPlusLC.ElvUI then
                -- Create checkboxes
                CreateAuctionCB("AhBuyoutOnly", "BOTTOMLEFT", 215, 30, "Buyout Only")
                CreateAuctionCB("AhGoldOnly", "BOTTOMLEFT", 335, 30, "Gold Only")
                CreateAuctionCB("AhTabConfirm", "BOTTOMLEFT", 555, 16, "Tab Creates Auction")
            end

            -- Reposition Gold Only checkbox so it does not overlap Buyout Only checkbox label
            LeaPlusCB["AhGoldOnly"]:ClearAllPoints()
            LeaPlusCB["AhGoldOnly"]:SetPoint("LEFT", LeaPlusCB["AhBuyoutOnly"].f, "RIGHT", 20, 0)

            -- Reposition Gold Only checkbox so it does not overlap Buyout Only checkbox label
            LeaPlusCB["AhTabConfirm"]:ClearAllPoints()
            LeaPlusCB["AhTabConfirm"]:SetPoint("LEFT", LeaPlusCB["AhGoldOnly"].f, "RIGHT", 20, 0)
            LeaPlusCB["AhTabConfirm"]:Hide()

            -- Set click boundaries
            LeaPlusCB["AhBuyoutOnly"]:SetHitRectInsets(0, -LeaPlusCB["AhBuyoutOnly"].f:GetStringWidth() + 6, 0, 0);
            LeaPlusCB["AhGoldOnly"]:SetHitRectInsets(0, -LeaPlusCB["AhGoldOnly"].f:GetStringWidth() + 6, 0, 0);
            LeaPlusCB["AhTabConfirm"]:SetHitRectInsets(0, -LeaPlusCB["AhTabConfirm"].f:GetStringWidth() + 6, 0, 0);

            LeaPlusCB["AhBuyoutOnly"]:HookScript('OnClick', SetupAh);
            LeaPlusCB["AhBuyoutOnly"]:HookScript('OnShow', SetupAh);
            LeaPlusCB["AhTabConfirm"]:HookScript('OnShow', SetupAh);

            AuctionFrameAuctions:HookScript("OnShow", SetupAh)
            BuyoutPriceGold:HookScript("OnTextChanged", SetupAh)
            BuyoutPriceSilver:HookScript("OnTextChanged", SetupAh)
            BuyoutPriceCopper:HookScript("OnTextChanged", SetupAh)
            StartPriceGold:HookScript("OnTextChanged", SetupAh)
            StartPriceSilver:HookScript("OnTextChanged", SetupAh)
            StartPriceCopper:HookScript("OnTextChanged", SetupAh)

            -- Lock the create auction button if buyout gold box is empty (when using buyout only and gold only)
            AuctionsCreateAuctionButton:HookScript("OnEnable", function()
                -- Do nothing if wow token frame is showing
                -- if AuctionsWowTokenAuctionFrame:IsShown() then return end
                -- Lock the create auction button if both checkboxes are enabled and buyout gold price is empty
                if LeaPlusLC["AhGoldOnly"] == "On" and LeaPlusLC["AhBuyoutOnly"] == "On" then
                    if BuyoutPriceGold:GetText() == "" then
                        AuctionsCreateAuctionButton:Disable()
                    end
                end
            end)

            -- Clear copper and silver prices if gold only box is unchecked
            LeaPlusCB["AhGoldOnly"]:HookScript('OnClick', function()
                if LeaPlusCB["AhGoldOnly"]:GetChecked() == false then
                    BuyoutPriceCopper:SetText("")
                    BuyoutPriceSilver:SetText("")
                    StartPriceCopper:SetText("")
                    StartPriceSilver:SetText("")
                end
                SetupAh();
            end)

            -- Create find button
            AuctionsItemText:Hide()

            if not LeaPlusLC.ElvUI then
                LeaPlusLC:CreateButton("FindAuctionButton", AuctionsStackSizeMaxButton, "Find Item", "CENTER", -5, 73, 0, 21, false, "")
                LeaPlusCB["FindAuctionButton"]:SetParent(AuctionFrameAuctions)
            end

            if LeaPlusLC.ElvUI then
                LeaPlusLC:CreateButton("FindAuctionButton", AuctionsStackSizeMaxButton, "Find Item", "CENTER", 37, 75, 0, 21, false, "")
                LeaPlusCB["FindAuctionButton"]:SetParent(AuctionFrameAuctions)
                _G.LeaPlusGlobalFindItemButton = LeaPlusCB["FindAuctionButton"]
                LeaPlusLC.ElvUI:GetModule("Skins"):HandleButton(_G.LeaPlusGlobalFindItemButton)
            end

            -- Show find button when the auctions tab is shown
            AuctionFrameAuctions:HookScript("OnShow", function()
                LeaPlusCB["FindAuctionButton"]:SetAlpha(GetAuctionSellItemInfo() and 1 or 0)
            end)

            -- Show find button when a new item is added
            AuctionsItemButton:HookScript("OnEvent", function(self, event)
                if event == "NEW_AUCTION_UPDATE" then
                    LeaPlusCB["FindAuctionButton"]:SetAlpha(GetAuctionSellItemInfo() and 1 or 0)
                end
            end)

            LeaPlusCB["FindAuctionButton"]:SetScript("OnClick", function()
                if GetAuctionSellItemInfo() then
                    -- if BrowseWowTokenResults:IsShown() then
                    -- 	-- Stop if Game Time filter is currently shown
                    -- 	AuctionFrameTab1:Click()
                    -- 	LeaPlusLC:Print("To use the Find Item button, you need to deselect the WoW Token category.")
                    -- else
                    -- Otherwise, search for the required item
                    local name = GetAuctionSellItemInfo()
                    BrowseName:SetText('' .. name .. '')
                    AuctionFrameBrowse_Search() -- Workaround for quoted search from QueryAuctionItems(name, 0, 0, 0, false, 0, false, true)
                    AuctionFrameTab1:Click()

                end
            end)

            -- Clear the cursor and reset editboxes when a new item replaces an existing one
            hooksecurefunc("AuctionsFrameAuctions_ValidateAuction", function()
                if GetAuctionSellItemInfo() then
                    -- Return anything you might be holding
                    ClearCursor();
                    -- Set copper and silver prices to 99 if gold mode is on
                    if LeaPlusLC["AhGoldOnly"] == "On" then
                        StartPriceCopper:SetText("00")
                        StartPriceSilver:SetText("00")
                        BuyoutPriceCopper:SetText("00")
                        BuyoutPriceSilver:SetText("00")
                    end
                end
            end)

            -- Clear gold editbox after an auction has been created (to force user to enter something)
            AuctionsCreateAuctionButton:HookScript("OnClick", function()
                StartPriceGold:SetText("")
                BuyoutPriceGold:SetText("")
            end)

            -- Set tab key actions (if different from defaults)
            StartPriceGold:HookScript("OnTabPressed", function()
                if not IsShiftKeyDown() then
                    if LeaPlusLC["AhBuyoutOnly"] == "Off" and LeaPlusLC["AhGoldOnly"] == "On" then
                        BuyoutPriceGold:SetFocus(true)
                    end
                end
            end)

            BuyoutPriceGold:HookScript("OnTabPressed", function()
                if IsShiftKeyDown() then
                    if LeaPlusLC["AhBuyoutOnly"] == "Off" and LeaPlusLC["AhGoldOnly"] == "On" then
                        StartPriceGold:SetFocus(true)
                    end
                else
                    if LeaPlusLC["AhTabConfirm"] == "On" and LeaPlusLC["AhBuyoutOnly"] == "On" and LeaPlusLC["AhGoldOnly"] == "On" then
                        AuctionsCreateAuctionButton:Click()
                        BuyoutPriceGold:ClearFocus()
                    end

                end
            end)

            local function AddItemToAuction(button, bag, slot)
                if IsAltKeyDown() then
                    local name = GetItemInfo(bag, slot)
                    ClearCursor()
                    PickupContainerItem(bag, slot)
                    ClickAuctionSellItemButton()
                    if GetAuctionSellItemInfo() == name then
                        PickupContainerItem(bag, slot)
                    end
                    if LeaPlusLC["AhBuyoutOnly"] == "Off" then
                        StartPriceGold:SetFocus(true)
                    else
                        BuyoutPriceGold:SetFocus(true)
                    end
                else
                    button:SetAttribute("type", "macro")
                    button:SetAttribute("macrotext", "/click AuctionsItemButton")
                    button:Click()
                end
            end

            local function GetActiveAuctionTabID()
                local activeTab = PanelTemplates_GetSelectedTab(AuctionFrame)
                if activeTab == AuctionFrameTab1:GetID() then
                    return 1
                elseif activeTab == AuctionFrameTab2:GetID() then
                    return 2
                elseif activeTab == AuctionFrameTab3:GetID() then
                    return 3
                end
            end

            hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self, button)
                local bag, slot = self:GetParent():GetID(), self:GetID()
                if button == "LeftButton" and not CursorHasItem() then
                    if not AuctionFrame:IsShown() then
                        return
                    end
                    local activeTabID = GetActiveAuctionTabID()
                    if activeTabID == 1 or activeTabID == 2 or activeTabID == 3 then
                        AddItemToAuction(self, bag, slot)
                        AuctionFrameTab3:Click()
                    end
                end
            end)


        end

        -- Run function when Blizzard addon is loaded
        if IsAddOnLoaded("Blizzard_AuctionUI") then
            AuctionFunc()
        else
            local waitFrame = CreateFrame("FRAME")
            waitFrame:RegisterEvent("ADDON_LOADED")
            waitFrame:SetScript("OnEvent", function(self, event, arg1)
                if arg1 == "Blizzard_AuctionUI" then
                    AuctionFunc()
                    waitFrame:UnregisterAllEvents()
                end
            end)
        end

    end

    ----------------------------------------------------------------------
    -- Show volume control on character frame
    ----------------------------------------------------------------------

    if LeaPlusLC["ShowVolume"] == "On" then

        -- Function to update master volume
        local function MasterVolUpdate()
            if LeaPlusLC["ShowVolume"] == "On" then
                -- Set the volume
                SetCVar("Sound_MasterVolume", LeaPlusLC["LeaPlusMaxVol"]);
                -- Format the slider text
                LeaPlusCB["LeaPlusMaxVol"].f:SetFormattedText("%.0f", LeaPlusLC["LeaPlusMaxVol"] * 100)
            end
        end

        -- Create slider control
        LeaPlusLC["LeaPlusMaxVol"] = tonumber(GetCVar("Sound_MasterVolume"));
        LeaPlusLC:MakeSL(CharacterModelFrame, "LeaPlusMaxVol", "", 0, 1, 0.05, -42, -328, "%.2f")
        LeaPlusCB["LeaPlusMaxVol"]:SetWidth(64)
        LeaPlusCB["LeaPlusMaxVol"].f:ClearAllPoints()
        LeaPlusCB["LeaPlusMaxVol"].f:SetPoint("LEFT", LeaPlusCB["LeaPlusMaxVol"], "RIGHT", 6, 0)

        -- Set slider control value when shown
        LeaPlusCB["LeaPlusMaxVol"]:SetScript("OnShow", function()
            LeaPlusCB["LeaPlusMaxVol"]:SetValue(GetCVar("Sound_MasterVolume"))
        end)

        -- Update volume when slider control is changed
        LeaPlusCB["LeaPlusMaxVol"]:HookScript("OnValueChanged", function()
            if IsMouseButtonDown("RightButton") and IsShiftKeyDown() then
                -- Dual layout is active so don't adjust slider
                LeaPlusCB["LeaPlusMaxVol"].f:SetFormattedText("%.0f", LeaPlusLC["LeaPlusMaxVol"] * 20)
                LeaPlusCB["LeaPlusMaxVol"]:Hide()
                LeaPlusCB["LeaPlusMaxVol"]:Show()
                return
            else
                -- Set sound level and refresh slider
                MasterVolUpdate()
            end
        end)

        -- ElvUI skin for slider control
        if LeaPlusLC.ElvUI then
            _G.LeaPlusGlobalVolumeButton = LeaPlusCB["LeaPlusMaxVol"]
            LeaPlusLC.ElvUI:GetModule("Skins"):HandleSliderFrame(_G.LeaPlusGlobalVolumeButton, false)
        end

    end

    ----------------------------------------------------------------------
    --	Use arrow keys in chat
    ----------------------------------------------------------------------

    if LeaPlusLC["UseArrowKeysInChat"] == "On" and not LeaLockList["UseArrowKeysInChat"] then
        -- Enable arrow keys for normal and existing chat frames
        for i = 1, 50 do
            if _G["ChatFrame" .. i] then
                _G["ChatFrame" .. i .. "EditBox"]:SetAltArrowKeyMode(false)
            end
        end
        -- Enable arrow keys for temporary chat frames
        hooksecurefunc("FCF_OpenTemporaryWindow", function()
            local cf = FCF_GetCurrentChatFrame():GetName() or nil
            if cf then
                _G[cf .. "EditBox"]:SetAltArrowKeyMode(false)
            end
        end)
    end

    ----------------------------------------------------------------------
    -- L41: Manage buffs
    ----------------------------------------------------------------------

    if LeaPlusLC["ManageBuffs"] == "On" and not LeaLockList["ManageBuffs"] then

        -- Allow buff frame to be moved
        ConsolidatedBuffs:SetMovable(true)
        ConsolidatedBuffs:SetUserPlaced(true)
        ConsolidatedBuffs:SetDontSavePosition(true)
        ConsolidatedBuffs:SetClampedToScreen(true)


        -- Set buff frame position at startup
        ConsolidatedBuffs:ClearAllPoints()

        ConsolidatedBuffs:SetPoint(LeaPlusLC["BuffFrameA"], UIParent, LeaPlusLC["BuffFrameR"], LeaPlusLC["BuffFrameX"], LeaPlusLC["BuffFrameY"])

        BuffFrame:SetScale(LeaPlusLC["BuffFrameScale"])
        ConsolidatedBuffs:SetScale(LeaPlusLC["BuffFrameScale"])


        -- Create drag frame
        local dragframe = CreateFrame("FRAME", nil, nil)
        dragframe:SetPoint("TOPRIGHT", ConsolidatedBuffs, "TOPRIGHT", 0, 2.5)
        dragframe:SetBackdropColor(0.0, 0.5, 1.0)
        dragframe:SetBackdrop({ edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
        dragframe:SetToplevel(true)
        dragframe:Hide()
        dragframe:EnableMouse(true)
        dragframe:SetScale(LeaPlusLC["BuffFrameScale"])

        dragframe.t = dragframe:CreateTexture()
        dragframe.t:SetAllPoints()
        dragframe.t:SetTexture(0.0, 1.0, 0.0, 0.5)
        dragframe.t:SetAlpha(0.5)

        dragframe.f = dragframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
        dragframe.f:SetPoint('CENTER', 0, 0)
        dragframe.f:SetText(L["Buffs"])

        local isBuffFrameMoving = false
        local buffFrameSetPoint = ConsolidatedBuffs.SetPoint

        ConsolidatedBuffs.SetPoint = function(self, ...)
            if not InCombatLockdown() and not isBuffFrameMoving then
                buffFrameSetPoint(self, LeaPlusLC["BuffFrameA"], UIParent, LeaPlusLC["BuffFrameR"], LeaPlusLC["BuffFrameX"], LeaPlusLC["BuffFrameY"])
            end
        end

        dragframe:SetScript("OnMouseDown", function(self, btn)
            -- Start dragging if left clicked
            if btn == "LeftButton" then
                isBuffFrameMoving = true
                ConsolidatedBuffs:StartMoving()
            end
        end)

        dragframe:SetScript("OnMouseUp", function()
            -- Save frame positions
            ConsolidatedBuffs:StopMovingOrSizing()
            isBuffFrameMoving = false
            LeaPlusLC["BuffFrameA"], void, LeaPlusLC["BuffFrameR"], LeaPlusLC["BuffFrameX"], LeaPlusLC["BuffFrameY"] = ConsolidatedBuffs:GetPoint()
            ConsolidatedBuffs:SetMovable(true)
            ConsolidatedBuffs:ClearAllPoints()
            ConsolidatedBuffs:SetPoint(LeaPlusLC["BuffFrameA"], UIParent, LeaPlusLC["BuffFrameR"], LeaPlusLC["BuffFrameX"], LeaPlusLC["BuffFrameY"])

        end)

        ---- Snap-to-grid
        --do
        --	local frame, grid = dragframe, 10
        --	local w, h = -190, 225
        --	local xpos, ypos, scale, uiscale
        --	frame:RegisterForDrag("RightButton")
        --	frame:HookScript("OnDragStart", function()
        --		frame:SetScript("OnUpdate", function()
        --			scale, uiscale = frame:GetScale(), UIParent:GetScale()
        --			xpos, ypos = GetCursorPosition()
        --			xpos = floor((xpos / scale / uiscale) / grid) * grid - w / 2
        --			ypos = ceil((ypos / scale / uiscale) / grid) * grid + h / 2
        --			BuffFrame:ClearAllPoints()
        --			BuffFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", xpos, ypos)
        --		end)
        --	end)
        --	frame:HookScript("OnDragStop", function()
        --		frame:SetScript("OnUpdate", nil)
        --		frame:GetScript("OnMouseUp")()
        --	end)
        --end

        -- Create configuration panel
        local BuffPanel = LeaPlusLC:CreatePanel("Manage buffs", "BuffPanel")

        LeaPlusLC:MakeTx(BuffPanel, "Scale", 16, -72)
        LeaPlusLC:MakeSL(BuffPanel, "BuffFrameScale", "Drag to set the buffs frame scale.", 0.5, 2, 0.05, 16, -92, "%.2f")

        -- Set scale when slider is changed
        LeaPlusCB["BuffFrameScale"]:HookScript("OnValueChanged", function()
            BuffFrame:SetScale(LeaPlusLC["BuffFrameScale"])
            ConsolidatedBuffs:SetScale(LeaPlusLC["BuffFrameScale"])
            dragframe:SetScale(LeaPlusLC["BuffFrameScale"])
            -- Show formatted slider value
            LeaPlusCB["BuffFrameScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["BuffFrameScale"] * 100)
        end)

        -- Hide frame alignment grid with panel
        BuffPanel:HookScript("OnHide", function()
            LeaPlusLC.grid:Hide()
        end)

        -- Toggle grid button
        local BuffsToggleGridButton = LeaPlusLC:CreateButton("BuffsToggleGridButton", BuffPanel, "Toggle Grid", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the frame alignment grid.")
        LeaPlusCB["BuffsToggleGridButton"]:ClearAllPoints()
        LeaPlusCB["BuffsToggleGridButton"]:SetPoint("LEFT", BuffPanel.h, "RIGHT", 10, 0)
        LeaPlusCB["BuffsToggleGridButton"]:SetScript("OnClick", function()
            if LeaPlusLC.grid:IsShown() then
                LeaPlusLC.grid:Hide()
            else
                LeaPlusLC.grid:Show()
            end
        end)
        BuffPanel:HookScript("OnHide", function()
            if LeaPlusLC.grid then
                LeaPlusLC.grid:Hide()
            end
        end)

        -- Help button tooltip
        BuffPanel.h.tiptext = L["Drag the frame overlay with the left button to position it freely or with the right button to position it using snap-to-grid."]

        -- Back button handler
        BuffPanel.b:SetScript("OnClick", function()
            BuffPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page6"]:Show()
            return
        end)

        -- Reset button handler
        BuffPanel.r:SetScript("OnClick", function()

            -- Reset position and scale
            LeaPlusLC["BuffFrameA"] = "TOPRIGHT"
            LeaPlusLC["BuffFrameR"] = "TOPRIGHT"
            LeaPlusLC["BuffFrameX"] = -205
            LeaPlusLC["BuffFrameY"] = -13
            LeaPlusLC["BuffFrameScale"] = 1
            ConsolidatedBuffs:ClearAllPoints()
            ConsolidatedBuffs:SetPoint(LeaPlusLC["BuffFrameA"], UIParent, LeaPlusLC["BuffFrameR"], LeaPlusLC["BuffFrameX"], LeaPlusLC["BuffFrameY"])

            -- Refresh configuration panel
            BuffPanel:Hide();
            BuffPanel:Show()
            dragframe:Show()

            -- Show frame alignment grid
            LeaPlusLC.grid:Show()

        end)

        -- Show configuration panel when options panel button is clicked
        LeaPlusCB["ManageBuffsButton"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["BuffFrameA"] = "TOPRIGHT"
                LeaPlusLC["BuffFrameR"] = "TOPRIGHT"
                LeaPlusLC["BuffFrameX"] = -271
                LeaPlusLC["BuffFrameY"] = 0
                LeaPlusLC["BuffFrameScale"] = 0.80
                ConsolidatedBuffs:ClearAllPoints()
                ConsolidatedBuffs:SetPoint(LeaPlusLC["BuffFrameA"], UIParent, LeaPlusLC["BuffFrameR"], LeaPlusLC["BuffFrameX"], LeaPlusLC["BuffFrameY"])
                BuffFrame:SetScale(LeaPlusLC["BuffFrameScale"])
                ConsolidatedBuffs:SetScale(LeaPlusLC["BuffFrameScale"])
            else
                -- Find out if the UI has a non-standard scale
                if GetCVar("useuiscale") == "1" then
                    LeaPlusLC["gscale"] = GetCVar("uiscale")
                else
                    LeaPlusLC["gscale"] = 1
                end

                -- Set drag frame size according to UI scale
                dragframe:SetWidth(280 * LeaPlusLC["gscale"])
                dragframe:SetHeight(225 * LeaPlusLC["gscale"])

                -- Show configuration panel
                BuffPanel:Show()
                LeaPlusLC:HideFrames()
                dragframe:Show()

                -- Show frame alignment grid
                LeaPlusLC.grid:Show()
            end
        end)

        -- Hide drag frame when configuration panel is closed
        BuffPanel:HookScript("OnHide", function()
            dragframe:Hide()
        end)

    end


    ----------------------------------------------------------------------
    -- L41: Manage debuffs
    ----------------------------------------------------------------------

    if LeaPlusLC["ManageDeBuffs"] == "On" and not LeaLockList["ManageDeBuffs"] then

        --if DebuffButton1 == nil then return end
        --
        ---- Allow buff frame to be moved
        --DebuffButton1:SetMovable(true)
        --DebuffButton1:SetUserPlaced(true)
        --DebuffButton1:SetDontSavePosition(true)
        --DebuffButton1:SetClampedToScreen(true)
        --
        ---- Set buff frame position at startup
        --DebuffButton1:ClearAllPoints()
        --DebuffButton1:SetPoint(LeaPlusLC["DebuffButton1A"], UIParent, LeaPlusLC["DebuffButton1R"], LeaPlusLC["DebuffButton1X"], LeaPlusLC["DebuffButton1Y"])
        --DebuffButton1:SetScale(LeaPlusLC["DebuffButton1Scale"])

        -- Function to update scale for all Debuff Buttons
        local function UpdateDebuffButtonScales(scale)
            for i = 1, DEBUFF_MAX_DISPLAY do
                local debuffButton = _G["DebuffButton" .. i]
                if debuffButton then
                    debuffButton:SetScale(scale)
                end
            end
        end

        -- Create drag frame
        local dragframe = CreateFrame("FRAME", nil, nil)

        if DebuffButton_UpdateAnchors then
            hooksecurefunc("DebuffButton_UpdateAnchors", function()
                local d = _G.DebuffButton1
                if d then
                    d:SetMovable(true)
                    d:SetUserPlaced(true)
                    d:SetDontSavePosition(true)
                    d:SetClampedToScreen(true)

                    -- Anchor DebuffButton1 using LeaPlusLC values
                    d:ClearAllPoints()
                    d:SetPoint(LeaPlusLC["DebuffButton1A"], UIParent, LeaPlusLC["DebuffButton1R"], LeaPlusLC["DebuffButton1X"], LeaPlusLC["DebuffButton1Y"])
                    UpdateDebuffButtonScales(LeaPlusLC["DebuffButton1Scale"])

                    -- Position dragframe
                    dragframe:SetPoint("TOPRIGHT", d, "TOPRIGHT", 5, 5)
                end
            end)
        end

        dragframe:SetBackdropColor(0.0, 0.5, 1.0)
        dragframe:SetBackdrop({ edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
        dragframe:SetToplevel(true)
        dragframe:Hide()
        dragframe:EnableMouse(true)
        dragframe:SetScale(LeaPlusLC["DebuffButton1Scale"])

        dragframe.t = dragframe:CreateTexture()
        dragframe.t:SetAllPoints()
        dragframe.t:SetTexture(0.0, 1.0, 0.0, 0.5)
        dragframe.t:SetAlpha(0.5)

        dragframe.f = dragframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
        dragframe.f:SetPoint('CENTER', 0, 0)
        dragframe.f:SetText(L["DeBuffs"])

        --local isDebuffButton1Moving = false
        --local deBuffFrameSetPoint = DebuffButton1.SetPoint
        --
        --DebuffButton1.SetPoint = function(self, ...)
        --	if not InCombatLockdown() and not isDebuffButton1Moving then
        --		deBuffFrameSetPoint(self, LeaPlusLC["DebuffButton1A"], UIParent, LeaPlusLC["DebuffButton1R"], LeaPlusLC["DebuffButton1X"], LeaPlusLC["DebuffButton1Y"])
        --	end
        --end

        dragframe:SetScript("OnMouseDown", function(self, btn)
            -- Start dragging if left clicked
            if btn == "LeftButton" then
                isDebuffButton1Moving = true
                DebuffButton1:StartMoving()
            end
        end)

        dragframe:SetScript("OnMouseUp", function()
            -- Save frame positions
            DebuffButton1:StopMovingOrSizing()
            isDebuffButton1Moving = false
            LeaPlusLC["DebuffButton1A"], void, LeaPlusLC["DebuffButton1R"], LeaPlusLC["DebuffButton1X"], LeaPlusLC["DebuffButton1Y"] = DebuffButton1:GetPoint()
            DebuffButton1:SetMovable(true)
            DebuffButton1:ClearAllPoints()
            DebuffButton1:SetPoint(LeaPlusLC["DebuffButton1A"], UIParent, LeaPlusLC["DebuffButton1R"], LeaPlusLC["DebuffButton1X"], LeaPlusLC["DebuffButton1Y"])
        end)

        -- Create configuration panel
        local DeBuffPanel = LeaPlusLC:CreatePanel("Manage DeBuffs", "DeBuffPanel")

        LeaPlusLC:MakeTx(DeBuffPanel, "Scale", 16, -72)
        LeaPlusLC:MakeSL(DeBuffPanel, "DebuffButton1Scale", "Drag to set the buffs frame scale.", 0.5, 2, 0.05, 16, -92, "%.2f")

        -- Set scale when slider is changed
        LeaPlusCB["DebuffButton1Scale"]:HookScript("OnValueChanged", function()
            UpdateDebuffButtonScales(LeaPlusLC["DebuffButton1Scale"])
            --DebuffButton1:SetScale(LeaPlusLC["DebuffButton1Scale"])
            dragframe:SetScale(LeaPlusLC["DebuffButton1Scale"])
            -- Show formatted slider value
            LeaPlusCB["DebuffButton1Scale"].f:SetFormattedText("%.0f%%", LeaPlusLC["DebuffButton1Scale"] * 100)
        end)

        -- Hide frame alignment grid with panel
        DeBuffPanel:HookScript("OnHide", function()
            LeaPlusLC.grid:Hide()
        end)

        -- Toggle grid button
        local DeBuffsToggleGridButton = LeaPlusLC:CreateButton("DeBuffsToggleGridButton", DeBuffPanel, "Toggle Grid", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the frame alignment grid.")
        LeaPlusCB["DeBuffsToggleGridButton"]:ClearAllPoints()
        LeaPlusCB["DeBuffsToggleGridButton"]:SetPoint("LEFT", DeBuffPanel.h, "RIGHT", 10, 0)
        LeaPlusCB["DeBuffsToggleGridButton"]:SetScript("OnClick", function()
            if LeaPlusLC.grid:IsShown() then
                LeaPlusLC.grid:Hide()
            else
                LeaPlusLC.grid:Show()
            end
        end)
        DeBuffPanel:HookScript("OnHide", function()
            if LeaPlusLC.grid then
                LeaPlusLC.grid:Hide()
            end
        end)

        -- Help button tooltip
        DeBuffPanel.h.tiptext = L["Drag the frame overlay with the left button to position it freely or with the right button to position it using snap-to-grid."]

        -- Back button handler
        DeBuffPanel.b:SetScript("OnClick", function()
            DeBuffPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page6"]:Show()
            return
        end)

        -- Reset button handler
        DeBuffPanel.r:SetScript("OnClick", function()

            -- Reset position and scale
            LeaPlusLC["DebuffButton1A"] = "TOPRIGHT"
            LeaPlusLC["DebuffButton1R"] = "TOPRIGHT"
            LeaPlusLC["DebuffButton1X"] = -205
            LeaPlusLC["DebuffButton1Y"] = -205
            LeaPlusLC["DebuffButton1Scale"] = 1
            if DebuffButton1 then
                DebuffButton1:ClearAllPoints()
                DebuffButton1:SetPoint(LeaPlusLC["DebuffButton1A"], UIParent, LeaPlusLC["DebuffButton1R"], LeaPlusLC["DebuffButton1X"], LeaPlusLC["DebuffButton1Y"])
            end

            -- Refresh configuration panel
            DeBuffPanel:Hide();
            DeBuffPanel:Show()
            dragframe:Show()

            -- Show frame alignment grid
            LeaPlusLC.grid:Show()

        end)

        -- Show configuration panel when options panel button is clicked
        LeaPlusCB["ManageDeBuffsButton"]:SetScript("OnClick", function()
            if not DebuffButton1 then
                print("Leatrix Plus: In order to move debuffs, need to have one. \nFor example Ghost.")
                return
            end
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["DebuffButton1A"] = "TOPRIGHT"
                LeaPlusLC["DebuffButton1R"] = "TOPRIGHT"
                LeaPlusLC["DebuffButton1X"] = -271
                LeaPlusLC["DebuffButton1Y"] = -205
                LeaPlusLC["DebuffButton1Scale"] = 0.80
                DebuffButton1:ClearAllPoints()
                DebuffButton1:SetPoint(LeaPlusLC["DebuffButton1A"], UIParent, LeaPlusLC["DebuffButton1R"], LeaPlusLC["DebuffButton1X"], LeaPlusLC["DebuffButton1Y"])
                --DebuffButton1:SetScale(LeaPlusLC["DebuffButton1Scale"])
                UpdateDebuffButtonScales(LeaPlusLC["DebuffButton1Scale"])
            else
                -- Find out if the UI has a non-standard scale
                if GetCVar("useuiscale") == "1" then
                    LeaPlusLC["gscale"] = GetCVar("uiscale")
                else
                    LeaPlusLC["gscale"] = 1
                end

                -- Set drag frame size according to UI scale
                dragframe:SetWidth(280 * LeaPlusLC["gscale"])
                dragframe:SetHeight(225 * LeaPlusLC["gscale"])

                -- Show configuration panel
                DeBuffPanel:Show()
                LeaPlusLC:HideFrames()
                dragframe:Show()

                -- Show frame alignment grid
                LeaPlusLC.grid:Show()
            end
        end)

        -- Hide drag frame when configuration panel is closed
        DeBuffPanel:HookScript("OnHide", function()
            dragframe:Hide()
        end)

    end


    ----------------------------------------------------------------------
    -- L42: Manage frames
    ----------------------------------------------------------------------

    -- Frame Movement
    if LeaPlusLC["FrmEnabled"] == "On" and not LeaLockList["FrmEnabled"] then

        -- Lock the player and target frames
        PlayerFrame:RegisterForDrag()
        TargetFrame:RegisterForDrag()

        -- Remove integrated movement functions to avoid conflicts
        _G.PlayerFrame_ResetUserPlacedPosition = function()
        end
        _G.TargetFrame_ResetUserPlacedPosition = function()
        end
        _G.PlayerFrame_SetLocked = function()
        end
        _G.TargetFrame_SetLocked = function()
        end



        -- Create frame table (used for local traversal)
        local FrameTable = { DragPlayerFrame = PlayerFrame, DragTargetFrame = TargetFrame }

        -- Create main table structure in saved variables if it doesn't exist
        if (LeaPlusDB["Frames"]) == nil then
            LeaPlusDB["Frames"] = {}
        end

        -- Create frame based table structure in saved variables if it doesn't exist and set initial scales
        for k, v in pairs(FrameTable) do
            local vf = v:GetName()
            -- Create frame table structure if it doesn't exist
            if not LeaPlusDB["Frames"][vf] then
                LeaPlusDB["Frames"][vf] = {}
            end
            -- Set saved scale value to default if it doesn't exist
            if not LeaPlusDB["Frames"][vf]["Scale"] then
                LeaPlusDB["Frames"][vf]["Scale"] = 1.00
            end
            -- Set frame scale to saved value
            _G[vf]:SetScale(LeaPlusDB["Frames"][vf]["Scale"])
            -- Don't save frame position
            _G[vf]:SetMovable(true)
            _G[vf]:SetUserPlaced(true)
            _G[vf]:SetDontSavePosition(true)
        end

        -- Set frames to manual values
        local function LeaFramesSetPos(frame, point, parent, relative, xoff, yoff)
            frame:SetMovable(true)
            frame:ClearAllPoints()
            frame:SetPoint(point, parent, relative, xoff, yoff)
        end

        -- Set frames to default values
        local function LeaPlusFramesDefaults()
            LeaFramesSetPos(PlayerFrame, "TOPLEFT", UIParent, "TOPLEFT", -19, -4)
            LeaFramesSetPos(TargetFrame, "TOPLEFT", UIParent, "TOPLEFT", 250, -4)
        end

        -- Create configuration panel
        local SideFrames = LeaPlusLC:CreatePanel("Manage frames", "SideFrames")

        -- Variable used to store currently selected frame
        local currentframe

        -- Create scale title
        LeaPlusLC:MakeTx(SideFrames, "Scale", 16, -72)

        -- Set initial slider value (will be changed when drag frames are selected)
        LeaPlusLC["FrameScale"] = 1.00

        -- Create scale slider
        LeaPlusLC:MakeSL(SideFrames, "FrameScale", "Drag to set the scale of the selected frame.", 0.5, 3.0, 0.05, 16, -92, "%.2f")
        LeaPlusCB["FrameScale"]:HookScript("OnValueChanged", function(self, value)
            if currentframe then
                -- If a frame is selected
                -- Set real and drag frame scale
                LeaPlusDB["Frames"][currentframe]["Scale"] = value
                _G[currentframe]:SetScale(LeaPlusDB["Frames"][currentframe]["Scale"])
                LeaPlusLC["Drag" .. currentframe]:SetScale(LeaPlusDB["Frames"][currentframe]["Scale"])
                -- If target frame scale is changed, also change combo point frame
                if currentframe == "TargetFrame" then
                    ComboFrame:SetScale(LeaPlusDB["Frames"]["TargetFrame"]["Scale"])
                end
                -- Set slider formatted text
                LeaPlusCB["FrameScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["FrameScale"] * 100)
            end
        end)

        -- Set initial scale slider state and value
        LeaPlusCB["FrameScale"]:HookScript("OnShow", function()
            if not currentframe then
                -- No frame selected so select the player frame
                currentframe = PlayerFrame:GetName()
                LeaPlusLC["DragPlayerFrame"].t:SetTexture(0.0, 1.0, 0.0, 0.5)
            end
            -- Set the scale slider value to the selected frame
            LeaPlusCB["FrameScale"]:SetValue(LeaPlusDB["Frames"][currentframe]["Scale"])
            -- Set slider formatted text
            LeaPlusCB["FrameScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["FrameScale"] * 100)
        end)

        -- Hide frame alignment grid with panel
        SideFrames:HookScript("OnHide", function()
            LeaPlusLC.grid:Hide()
        end)

        -- Toggle grid button
        local FramesToggleGridButton = LeaPlusLC:CreateButton("FramesToggleGridButton", SideFrames, "Toggle Grid", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the frame alignment grid.")
        LeaPlusCB["FramesToggleGridButton"]:ClearAllPoints()
        LeaPlusCB["FramesToggleGridButton"]:SetPoint("LEFT", SideFrames.h, "RIGHT", 10, 0)
        LeaPlusCB["FramesToggleGridButton"]:SetScript("OnClick", function()
            if LeaPlusLC.grid:IsShown() then
                LeaPlusLC.grid:Hide()
            else
                LeaPlusLC.grid:Show()
            end
        end)
        SideFrames:HookScript("OnHide", function()
            if LeaPlusLC.grid then
                LeaPlusLC.grid:Hide()
            end
        end)

        -- Help button tooltip
        SideFrames.h.tiptext = L["Drag the frame overlays with the left button to position them freely or with the right button to position them using snap-to-grid.|n|nTo change the scale of a frame, click it to select it then adjust the scale slider.|n|nThis panel will close automatically if you enter combat."]

        -- Back button handler
        SideFrames.b:SetScript("OnClick", function()
            -- Hide outer control frame
            SideFrames:Hide()
            -- Hide drag frames
            for k, void in pairs(FrameTable) do
                LeaPlusLC[k]:Hide()
            end
            -- Show options panel at frame section
            LeaPlusLC["PageF"]:Show()
            LeaPlusLC["Page6"]:Show()
        end)

        -- Reset button handler
        SideFrames.r:SetScript("OnClick", function()
            if LeaPlusLC:PlayerInCombat() then
                -- If player is in combat, print error and stop
                return
            else
                -- Set frames to default positions (presets)
                LeaPlusFramesDefaults()
                for k, v in pairs(FrameTable) do
                    local vf = v:GetName()
                    -- Store frame locations
                    LeaPlusDB["Frames"][vf]["Point"], void, LeaPlusDB["Frames"][vf]["Relative"], LeaPlusDB["Frames"][vf]["XOffset"], LeaPlusDB["Frames"][vf]["YOffset"] = _G[vf]:GetPoint()
                    -- Reset real frame scales and save them
                    LeaPlusDB["Frames"][vf]["Scale"] = 1.00
                    _G[vf]:SetScale(LeaPlusDB["Frames"][vf]["Scale"])
                    -- Reset drag frame scales
                    LeaPlusLC[k]:SetScale(LeaPlusDB["Frames"][vf]["Scale"])
                end
                -- Set combo frame scale to match target frame scale
                ComboFrame:SetScale(LeaPlusDB["Frames"]["TargetFrame"]["Scale"])
                -- Set the scale slider value to the selected frame scale
                LeaPlusCB["FrameScale"]:SetValue(LeaPlusDB["Frames"][currentframe]["Scale"])
                -- Refresh the panel
                SideFrames:Hide();
                SideFrames:Show()
                -- Show frame alignment grid
                LeaPlusLC.grid:Show()
            end
        end)

        -- Show drag frames with configuration panel
        SideFrames:HookScript("OnShow", function()
            for k, void in pairs(FrameTable) do
                LeaPlusLC[k]:Show()
            end
        end)
        SideFrames:HookScript("OnHide", function()
            for k, void in pairs(FrameTable) do
                LeaPlusLC[k]:Hide()
            end
        end)

        -- Save frame positions
        local function SaveAllFrames(DoNotSetPoint)
            for k, v in pairs(FrameTable) do
                local vf = v:GetName()
                -- Stop real frames from moving
                v:StopMovingOrSizing()
                -- Save frame positions
                LeaPlusDB["Frames"][vf]["Point"], void, LeaPlusDB["Frames"][vf]["Relative"], LeaPlusDB["Frames"][vf]["XOffset"], LeaPlusDB["Frames"][vf]["YOffset"] = v:GetPoint()
                if not DoNotSetPoint then
                    v:SetMovable(true)
                    v:ClearAllPoints()
                    v:SetPoint(LeaPlusDB["Frames"][vf]["Point"], UIParent, LeaPlusDB["Frames"][vf]["Relative"], LeaPlusDB["Frames"][vf]["XOffset"], LeaPlusDB["Frames"][vf]["YOffset"])
                end
            end
        end

        -- Prevent changes during combat
        SideFrames:SetScript("OnUpdate", function()
            if UnitAffectingCombat("player") then
                -- Hide controls frame
                SideFrames:Hide()
                -- Hide drag frames
                for k, void in pairs(FrameTable) do
                    LeaPlusLC[k]:Hide()
                end
                -- Save frame positions without setpoint
                SaveAllFrames(true)
            end
        end)

        -- Create drag frames
        local function LeaPlusMakeDrag(dragframe, realframe)

            local dragframe = CreateFrame("Frame", nil, nil)
            LeaPlusLC[dragframe] = dragframe
            dragframe:SetSize(realframe:GetSize())
            dragframe:SetPoint("TOP", realframe, "TOP", 0, 2.5)
            dragframe:SetBackdrop({
                bgFile = "Interface/Buttons/WHITE8X8",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                tile = false, tileSize = 0, edgeSize = 16,
                insets = { left = 0, right = 0, top = 0, bottom = 0 } })

            dragframe:SetBackdropColor(0.0, 0.5, 1.0, 0.5) -- Set the texture color and transparency of the background

            dragframe:SetToplevel(true)
            dragframe:SetFrameStrata("HIGH")

            -- Set frame clamps
            realframe:SetClampedToScreen(false)

            -- Hide the drag frame and make real frame movable
            dragframe:Hide()
            realframe:SetMovable(true)

            dragframe:EnableMouse(true)

            -- Click handler
            dragframe:SetScript("OnMouseDown", function(self, btn)

                -- Start dragging if left clicked
                if btn == "LeftButton" then
                    realframe:SetMovable(true)
                    realframe:StartMoving()
                end

                -- Set all drag frames to blue then tint the selected frame to green
                for k, v in pairs(FrameTable) do
                    LeaPlusLC[k].t:SetTexture(0.0, 0.5, 1.0, 0.5)
                end
                dragframe.t:SetTexture(0.0, 1.0, 0.0, 0.5)

                -- Set currentframe variable to selected frame and set the scale slider value
                currentframe = realframe:GetName()
                LeaPlusCB["FrameScale"]:SetValue(LeaPlusDB["Frames"][currentframe]["Scale"])

            end)

            dragframe:SetScript("OnMouseUp", function()
                -- Save frame positions
                SaveAllFrames()
            end)

            dragframe.t = dragframe:CreateTexture()
            dragframe.t:SetAllPoints()
            -- fix for 3.3.5 texture color
            dragframe.t:SetTexture(0.0, 0.5, 1.0, 0.5)
            dragframe.t:SetAlpha(0.5)

            dragframe.f = dragframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
            dragframe.f:SetPoint('CENTER', 0, 0)

            -- Add titles
            if realframe:GetName() == "PlayerFrame" then
                dragframe.f:SetText(L["Player"])
            end
            if realframe:GetName() == "TargetFrame" then
                dragframe.f:SetText(L["Target"])
            end

            -- Snap-to-grid
            do
                local frame, grid = dragframe, 10
                local w, h = frame:GetWidth(), frame:GetHeight()
                local xpos, ypos, scale, uiscale
                frame:RegisterForDrag("RightButton")
                frame:HookScript("OnDragStart", function()
                    frame:SetScript("OnUpdate", function()
                        scale, uiscale = frame:GetScale(), UIParent:GetScale()
                        xpos, ypos = GetCursorPosition()
                        xpos = floor((xpos / scale / uiscale) / grid) * grid - w / 2
                        ypos = ceil((ypos / scale / uiscale) / grid) * grid + h / 2
                        realframe:ClearAllPoints()
                        realframe:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", xpos, ypos)
                    end)
                end)
                frame:HookScript("OnDragStop", function()
                    frame:SetScript("OnUpdate", nil)
                    frame:GetScript("OnMouseUp")()
                end)
            end

            -- Return frame
            return LeaPlusLC[dragframe]

        end

        for k, v in pairs(FrameTable) do
            LeaPlusLC[k] = LeaPlusMakeDrag(k, v)
        end

        -- Set frame scales
        for k, v in pairs(FrameTable) do
            local vf = v:GetName()
            _G[vf]:SetScale(LeaPlusDB["Frames"][vf]["Scale"])
            LeaPlusLC[k]:SetScale(LeaPlusDB["Frames"][vf]["Scale"])
        end
        ComboFrame:SetScale(LeaPlusDB["Frames"]["TargetFrame"]["Scale"])

        -- Load defaults first then overwrite with saved values if they exist
        LeaPlusFramesDefaults()
        if LeaPlusDB["Frames"] then
            for k, v in pairs(FrameTable) do
                local vf = v:GetName()
                if LeaPlusDB["Frames"][vf] then
                    if LeaPlusDB["Frames"][vf]["Point"] and LeaPlusDB["Frames"][vf]["Relative"] and LeaPlusDB["Frames"][vf]["XOffset"] and LeaPlusDB["Frames"][vf]["YOffset"] then
                        _G[vf]:SetMovable(true)
                        _G[vf]:ClearAllPoints()
                        _G[vf]:SetPoint(LeaPlusDB["Frames"][vf]["Point"], UIParent, LeaPlusDB["Frames"][vf]["Relative"], LeaPlusDB["Frames"][vf]["XOffset"], LeaPlusDB["Frames"][vf]["YOffset"])
                    end
                end
            end
        end

        -- Add move button
        LeaPlusCB["MoveFramesButton"]:SetScript("OnClick", function()
            if LeaPlusLC:PlayerInCombat() then
                return
            else
                if IsShiftKeyDown() and IsControlKeyDown() then
                    -- Preset profile
                    LeaFramesSetPos(PlayerFrame, "TOPLEFT", UIParent, "TOPLEFT", "0", "-14")
                    LeaFramesSetPos(TargetFrame, "TOPLEFT", UIParent, "TOPLEFT", "225", "-14")
                    -- Player
                    LeaPlusDB["Frames"]["PlayerFrame"]["Scale"] = 1.20
                    PlayerFrame:SetScale(LeaPlusDB["Frames"]["PlayerFrame"]["Scale"])
                    LeaPlusLC["DragPlayerFrame"]:SetScale(LeaPlusDB["Frames"]["PlayerFrame"]["Scale"])
                    -- Target
                    LeaPlusDB["Frames"]["TargetFrame"]["Scale"] = 1.20
                    TargetFrame:SetScale(LeaPlusDB["Frames"]["TargetFrame"]["Scale"])
                    LeaPlusLC["DragTargetFrame"]:SetScale(LeaPlusDB["Frames"]["TargetFrame"]["Scale"])
                    -- Set the slider to the selected frame (if there is one)
                    if currentframe then
                        LeaPlusCB["FrameScale"]:SetValue(LeaPlusDB["Frames"][currentframe]["Scale"]);
                    end
                    -- Save locations
                    for k, v in pairs(FrameTable) do
                        local vf = v:GetName()
                        LeaPlusDB["Frames"][vf]["Point"], void, LeaPlusDB["Frames"][vf]["Relative"], LeaPlusDB["Frames"][vf]["XOffset"], LeaPlusDB["Frames"][vf]["YOffset"] = _G[vf]:GetPoint()
                    end
                else
                    -- Show mover frame
                    SideFrames:Show()
                    LeaPlusLC:HideFrames()

                    -- Find out if the UI has a non-standard scale
                    if GetCVar("useuiscale") == "1" then
                        LeaPlusLC["gscale"] = GetCVar("uiscale")
                    else
                        LeaPlusLC["gscale"] = 1
                    end

                    -- Set all scaled sizes
                    for k, v in pairs(FrameTable) do
                        LeaPlusLC[k]:SetWidth(v:GetWidth() * LeaPlusLC["gscale"])
                        LeaPlusLC[k]:SetHeight(v:GetHeight() * LeaPlusLC["gscale"])
                    end

                    -- Show frame alignment grid
                    LeaPlusLC.grid:Show()
                end
            end
        end)
        --Fix the blizzard bug with animating
        -- the PlayerFrame when entering / leavling Vehicle.
        -- This versions taints on some server, but is much more perfect.
        -- See below this for actual no-taint code.

        -- Disable Blizzard animation functions
        function PlayerFrame_AnimateOut(self)
            -- Instantly update art without animation
            PlayerFrame_UpdateArt(self)
        end

        function PlayerFrame_AnimFinished(self)
            -- No need for animation sequences, update instantly
            PlayerFrame_UpdateArt(self)
        end

        function PlayerFrame_UpdateArt(self)
            if UnitHasVehicleUI("player") then
                PlayerFrame_ToVehicleArt(self, UnitVehicleSkin("player"))
            else
                PlayerFrame_ToPlayerArt(self)
            end
        end

        --Fix for the blizzard bug with animating
        -- the PlayerFrame when entering / leavling Vehicle.
        -- This versions doesn't taint, but is NOT perfect.
        -- See above for perfect but tainted code.

        --do
        --    local function FixPlayerFrame()
        --        PlayerFrame:ClearAllPoints()
        --        PlayerFrame:SetPoint(LeaPlusDB["Frames"]["PlayerFrame"]["Point"], UIParent, LeaPlusDB["Frames"]["PlayerFrame"]["Relative"], LeaPlusDB["Frames"]["PlayerFrame"]["XOffset"], LeaPlusDB["Frames"]["PlayerFrame"]["YOffset"])
        --    end
        --
        --    local bugFrame = CreateFrame("FRAME")
        --
        --    bugFrame:SetScript("OnEvent", function()
        --        FixPlayerFrame()
        --        bugFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        --    end)
        --
        --    hooksecurefunc("PlayerFrame_SequenceFinished", function()
        --        if UnitAffectingCombat("player") then
        --            bugFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        --        else
        --            FixPlayerFrame()
        --        end
        --    end)
        --end

    end

    ----------------------------------------------------------------------
    -- L43: Manage widget
    ----------------------------------------------------------------------

    if LeaPlusLC["ManageWidget"] == "On" and not LeaLockList["ManageWidget"] then

        -- Create and manage container for WorldStateAlwaysUpFrame
        local topCenterHolder = CreateFrame("Frame", nil, UIParent)
        topCenterHolder:SetPoint("TOP", UIParent, "TOP", 0, -15)
        topCenterHolder:SetSize(10, 58)

        local topCenterContainer = _G.WorldStateAlwaysUpFrame
        topCenterContainer:ClearAllPoints()
        topCenterContainer:SetPoint('CENTER', topCenterHolder)

        hooksecurefunc(topCenterContainer, 'SetPoint', function(self, void, b)
            if b and (b ~= topCenterHolder) then
                -- Reset parent if it changes from topCenterHolder
                self:ClearAllPoints()
                self:SetPoint('CENTER', topCenterHolder)
                self:SetParent(topCenterHolder)
            end
        end)

        -- Allow widget frame to be moved
        topCenterHolder:SetMovable(true)
        topCenterHolder:SetUserPlaced(true)
        topCenterHolder:SetDontSavePosition(true)
        topCenterHolder:SetClampedToScreen(false)

        -- Set widget frame position at startup
        topCenterHolder:ClearAllPoints()
        topCenterHolder:SetPoint(LeaPlusLC["WidgetA"], UIParent, LeaPlusLC["WidgetR"], LeaPlusLC["WidgetX"], LeaPlusLC["WidgetY"])
        topCenterHolder:SetScale(LeaPlusLC["WidgetScale"])
        WorldStateAlwaysUpFrame:SetScale(LeaPlusLC["WidgetScale"])

        -- Create drag frame
        local dragframe = CreateFrame("FRAME", nil, nil)
        dragframe:SetPoint("CENTER", topCenterHolder, "CENTER", 0, 1)
        dragframe:SetBackdropColor(0.0, 0.5, 1.0)
        dragframe:SetBackdrop({ edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
        dragframe:SetToplevel(true)
        dragframe:EnableMouse(true)
        dragframe:Hide()
        dragframe:SetScale(LeaPlusLC["WidgetScale"])

        dragframe.t = dragframe:CreateTexture()
        dragframe.t:SetAllPoints()
        dragframe.t:SetTexture(0.0, 1.0, 0.0, 0.5)
        dragframe.t:SetAlpha(0.5)

        dragframe.f = dragframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
        dragframe.f:SetPoint('CENTER', 0, 0)
        dragframe.f:SetText(L["Widget"])

        -- Click handler
        dragframe:SetScript("OnMouseDown", function(self, btn)
            -- Start dragging if left clicked
            if btn == "LeftButton" then
                topCenterHolder:StartMoving()
            end
        end)

        dragframe:SetScript("OnMouseUp", function()
            -- Save frame position
            topCenterHolder:StopMovingOrSizing()
            LeaPlusLC["WidgetA"], void, LeaPlusLC["WidgetR"], LeaPlusLC["WidgetX"], LeaPlusLC["WidgetY"] = topCenterHolder:GetPoint()
            topCenterHolder:SetMovable(true)
            topCenterHolder:ClearAllPoints()
            topCenterHolder:SetPoint(LeaPlusLC["WidgetA"], UIParent, LeaPlusLC["WidgetR"], LeaPlusLC["WidgetX"], LeaPlusLC["WidgetY"])
        end)

        -- Snap-to-grid
        do
            local frame, grid = dragframe, 10
            local w, h = 0, 60
            local xpos, ypos, scale, uiscale
            frame:RegisterForDrag("RightButton")
            frame:HookScript("OnDragStart", function()
                frame:SetScript("OnUpdate", function()
                    scale, uiscale = frame:GetScale(), UIParent:GetScale()
                    xpos, ypos = GetCursorPosition()
                    xpos = floor((xpos / scale / uiscale) / grid) * grid - w / 2
                    ypos = ceil((ypos / scale / uiscale) / grid) * grid + h / 2
                    topCenterHolder:ClearAllPoints()
                    topCenterHolder:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", xpos, ypos)
                end)
            end)
            frame:HookScript("OnDragStop", function()
                frame:SetScript("OnUpdate", nil)
                frame:GetScript("OnMouseUp")()
            end)
        end

        -- Create configuration panel
        local WidgetPanel = LeaPlusLC:CreatePanel("Manage widget", "WidgetPanel")

        -- Create Titan Panel screen adjust warning
        local titanFrame = CreateFrame("FRAME", nil, WidgetPanel)
        titanFrame:SetAllPoints()
        titanFrame:Hide()
        LeaPlusLC:MakeTx(titanFrame, "Warning", 16, -172)
        titanFrame.txt = LeaPlusLC:MakeWD(titanFrame, "Titan Panel screen adjust needs to be disabled for the frame to be saved correctly.", 16, -192, 500)
        titanFrame.txt:SetWordWrap(false)
        titanFrame.txt:SetWidth(520)
        titanFrame.btn = LeaPlusLC:CreateButton("fixTitanBtn", titanFrame, "Okay, disable screen adjust for me", "TOPLEFT", 16, -212, 0, 25, true, "Click to disable Titan Panel screen adjust.  Your UI will be reloaded.")
        titanFrame.btn:SetScript("OnClick", function()
            TitanPanelSetVar("ScreenAdjust", 1)
            ReloadUI()
        end)

        LeaPlusLC:MakeTx(WidgetPanel, "Scale", 16, -72)
        LeaPlusLC:MakeSL(WidgetPanel, "WidgetScale", "Drag to set the widget scale.", 0.5, 2, 0.05, 16, -92, "%.2f")

        -- Set scale when slider is changed
        LeaPlusCB["WidgetScale"]:HookScript("OnValueChanged", function()
            topCenterHolder:SetScale(LeaPlusLC["WidgetScale"])
            WorldStateAlwaysUpFrame:SetScale(LeaPlusLC["WidgetScale"])
            dragframe:SetScale(LeaPlusLC["WidgetScale"])
            -- Show formatted slider value
            LeaPlusCB["WidgetScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["WidgetScale"] * 100)
        end)

        -- Hide frame alignment grid with panel
        WidgetPanel:HookScript("OnHide", function()
            LeaPlusLC.grid:Hide()
        end)

        -- Toggle grid button
        local WidgetToggleGridButton = LeaPlusLC:CreateButton("WidgetToggleGridButton", WidgetPanel, "Toggle Grid", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the frame alignment grid.")
        LeaPlusCB["WidgetToggleGridButton"]:ClearAllPoints()
        LeaPlusCB["WidgetToggleGridButton"]:SetPoint("LEFT", WidgetPanel.h, "RIGHT", 10, 0)
        LeaPlusCB["WidgetToggleGridButton"]:SetScript("OnClick", function()
            if LeaPlusLC.grid:IsShown() then
                LeaPlusLC.grid:Hide()
            else
                LeaPlusLC.grid:Show()
            end
        end)
        WidgetPanel:HookScript("OnHide", function()
            if LeaPlusLC.grid then
                LeaPlusLC.grid:Hide()
            end
        end)

        -- Help button tooltip
        WidgetPanel.h.tiptext = L["Drag the frame overlay with the left button to position it freely or with the right button to position it using snap-to-grid."]

        -- Back button handler
        WidgetPanel.b:SetScript("OnClick", function()
            WidgetPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page6"]:Show()
            return
        end)

        -- Reset button handler
        WidgetPanel.r:SetScript("OnClick", function()

            -- Reset position and scale
            LeaPlusLC["WidgetA"] = "TOP"
            LeaPlusLC["WidgetR"] = "TOP"
            LeaPlusLC["WidgetX"] = 0
            LeaPlusLC["WidgetY"] = -15
            LeaPlusLC["WidgetScale"] = 1
            topCenterHolder:ClearAllPoints()
            topCenterHolder:SetPoint(LeaPlusLC["WidgetA"], UIParent, LeaPlusLC["WidgetR"], LeaPlusLC["WidgetX"], LeaPlusLC["WidgetY"])

            -- Refresh configuration panel
            WidgetPanel:Hide();
            WidgetPanel:Show()
            dragframe:Show()

            -- Show frame alignment grid
            LeaPlusLC.grid:Show()

        end)

        -- Show configuration panel when options panel button is clicked
        LeaPlusCB["ManageWidgetButton"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["WidgetA"] = "CENTER"
                LeaPlusLC["WidgetR"] = "CENTER"
                LeaPlusLC["WidgetX"] = 0
                LeaPlusLC["WidgetY"] = -160
                LeaPlusLC["WidgetScale"] = 1.25
                topCenterHolder:ClearAllPoints()
                topCenterHolder:SetPoint(LeaPlusLC["WidgetA"], UIParent, LeaPlusLC["WidgetR"], LeaPlusLC["WidgetX"], LeaPlusLC["WidgetY"])
                topCenterHolder:SetScale(LeaPlusLC["WidgetScale"])
                WorldStateAlwaysUpFrame:SetScale(LeaPlusLC["WidgetScale"])
            else
                -- Show Titan Panel screen adjust warning if Titan Panel is installed with screen adjust enabled
                if select(2, GetAddOnInfo("TitanClassic")) then
                    if IsAddOnLoaded("TitanClassic") then
                        if TitanPanelSetVar and TitanPanelGetVar then
                            if not TitanPanelGetVar("ScreenAdjust") then
                                titanFrame:Show()
                            end
                        end
                    end
                end

                -- Find out if the UI has a non-standard scale
                if GetCVar("useuiscale") == "1" then
                    LeaPlusLC["gscale"] = GetCVar("uiscale")
                else
                    LeaPlusLC["gscale"] = 1
                end

                -- Set drag frame size according to UI scale
                dragframe:SetWidth(160 * LeaPlusLC["gscale"])
                dragframe:SetHeight(79 * LeaPlusLC["gscale"])

                -- Show configuration panel
                WidgetPanel:Show()
                LeaPlusLC:HideFrames()
                dragframe:Show()

                -- Show frame alignment grid
                LeaPlusLC.grid:Show()
            end
        end)

        -- Hide drag frame when configuration panel is closed
        WidgetPanel:HookScript("OnHide", function()
            dragframe:Hide()
        end)

    end

    ----------------------------------------------------------------------
    -- L44: Manage focus
    ----------------------------------------------------------------------

    if LeaPlusLC["ManageFocus"] == "On" and not LeaLockList["ManageFocus"] then

        -- Remove integrated movement function to avoid conflicts
        _G.FocusFrame_SetLock = function()
        end
        _G.FocusFrame.SetSmallSize = function()
        end

        -- Allow focus frame to be moved
        FocusFrame:SetMovable(true)
        FocusFrame:SetUserPlaced(true)
        FocusFrame:SetDontSavePosition(true)
        FocusFrame:SetClampedToScreen(true)

        -- Set focus frame position at startup
        FocusFrame:ClearAllPoints()
        FocusFrame:SetPoint(LeaPlusLC["FocusA"], UIParent, LeaPlusLC["FocusR"], LeaPlusLC["FocusX"], LeaPlusLC["FocusY"])
        FocusFrame:SetScale(LeaPlusLC["FocusScale"])

        -- Create drag frame
        local dragframe = CreateFrame("FRAME", nil, nil)
        dragframe:SetBackdropColor(0.0, 0.5, 1.0)
        dragframe:SetBackdrop({ edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
        dragframe:SetToplevel(true)
        dragframe:EnableMouse(true)
        dragframe:Hide()
        dragframe:SetScale(LeaPlusLC["FocusScale"])

        dragframe.t = dragframe:CreateTexture()
        dragframe.t:SetAllPoints()
        dragframe.t:SetTexture(0.0, 1.0, 0.0, 0.5)
        dragframe.t:SetAlpha(0.5)

        dragframe.f = dragframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
        dragframe.f:SetPoint('CENTER', 0, 0)
        dragframe.f:SetText(L["Focus"])

        -- Click handler
        dragframe:SetScript("OnMouseDown", function(self, btn)
            -- Start dragging if left clicked
            if btn == "LeftButton" then
                FocusFrame:StartMoving()
            end
        end)

        dragframe:SetScript("OnMouseUp", function()
            -- Save frame positions
            FocusFrame:StopMovingOrSizing()
            LeaPlusLC["FocusA"], void, LeaPlusLC["FocusR"], LeaPlusLC["FocusX"], LeaPlusLC["FocusY"] = FocusFrame:GetPoint()
            FocusFrame:SetMovable(true)
            FocusFrame:ClearAllPoints()
            FocusFrame:SetPoint(LeaPlusLC["FocusA"], UIParent, LeaPlusLC["FocusR"], LeaPlusLC["FocusX"], LeaPlusLC["FocusY"])
        end)

        -- Snap-to-grid
        do
            local frame, grid = dragframe, 10
            local w, h = 196, 86
            local xpos, ypos, scale, uiscale
            frame:RegisterForDrag("RightButton")
            frame:HookScript("OnDragStart", function()
                frame:SetScript("OnUpdate", function()
                    scale, uiscale = frame:GetScale(), UIParent:GetScale()
                    xpos, ypos = GetCursorPosition()
                    xpos = floor((xpos / scale / uiscale) / grid) * grid - w / 2
                    ypos = ceil((ypos / scale / uiscale) / grid) * grid + h / 2
                    FocusFrame:ClearAllPoints()
                    FocusFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", xpos, ypos)
                end)
            end)
            frame:HookScript("OnDragStop", function()
                frame:SetScript("OnUpdate", nil)
                frame:GetScript("OnMouseUp")()
            end)
        end

        -- Create configuration panel
        local FocusPanel = LeaPlusLC:CreatePanel("Manage focus", "FocusPanel")
        LeaPlusLC:MakeTx(FocusPanel, "Scale", 16, -72)
        LeaPlusLC:MakeSL(FocusPanel, "FocusScale", "Drag to set the focus frame scale.", 0.5, 2, 0.05, 16, -92, "%.2f")

        -- Hide panel during combat
        FocusPanel:SetScript("OnUpdate", function()
            if UnitAffectingCombat("player") then
                FocusFrame:StopMovingOrSizing()
                FocusPanel:Hide()
            end
        end)

        -- Set scale when slider is changed
        LeaPlusCB["FocusScale"]:HookScript("OnValueChanged", function()
            FocusFrame:SetScale(LeaPlusLC["FocusScale"])
            dragframe:SetScale(LeaPlusLC["FocusScale"])
            -- Show formatted slider value
            LeaPlusCB["FocusScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["FocusScale"] * 100)
        end)

        -- Hide frame alignment grid with panel
        FocusPanel:HookScript("OnHide", function()
            LeaPlusLC.grid:Hide()
        end)

        -- Toggle grid button
        local WidgetToggleGridButton = LeaPlusLC:CreateButton("FocusToggleGridButton", FocusPanel, "Toggle Grid", "TOPLEFT", 16, -72, 0, 25, true, "Click to toggle the frame alignment grid.")
        LeaPlusCB["FocusToggleGridButton"]:ClearAllPoints()
        LeaPlusCB["FocusToggleGridButton"]:SetPoint("LEFT", FocusPanel.h, "RIGHT", 10, 0)
        LeaPlusCB["FocusToggleGridButton"]:SetScript("OnClick", function()
            if LeaPlusLC.grid:IsShown() then
                LeaPlusLC.grid:Hide()
            else
                LeaPlusLC.grid:Show()
            end
        end)
        FocusPanel:HookScript("OnHide", function()
            if LeaPlusLC.grid then
                LeaPlusLC.grid:Hide()
            end
        end)

        -- Help button tooltip
        FocusPanel.h.tiptext = L["Drag the frame overlay with the left button to position it freely or with the right button to position it using snap-to-grid.|n|nThis panel will close automatically if you enter combat."]

        -- Back button handler
        FocusPanel.b:SetScript("OnClick", function()
            FocusPanel:Hide();
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page6"]:Show()
            return
        end)

        -- Reset button handler
        FocusPanel.r:SetScript("OnClick", function()

            -- Reset position and scale
            LeaPlusLC["FocusA"] = "CENTER"
            LeaPlusLC["FocusR"] = "CENTER"
            LeaPlusLC["FocusX"] = 0
            LeaPlusLC["FocusY"] = 0
            LeaPlusLC["FocusScale"] = 1
            FocusFrame:ClearAllPoints()
            FocusFrame:SetPoint(LeaPlusLC["FocusA"], UIParent, LeaPlusLC["FocusR"], LeaPlusLC["FocusX"], LeaPlusLC["FocusY"])

            -- Refresh configuration panel
            FocusPanel:Hide();
            FocusPanel:Show()
            dragframe:Show()

            -- Show frame alignment grid
            LeaPlusLC.grid:Show()

        end)

        -- Show configuration panel when options panel button is clicked
        LeaPlusCB["ManageFocusButton"]:SetScript("OnClick", function()
            if LeaPlusLC:PlayerInCombat() then
                return
            else
                if IsShiftKeyDown() and IsControlKeyDown() then
                    -- Preset profile
                    LeaPlusLC["FocusA"] = "TOPLEFT"
                    LeaPlusLC["FocusR"] = "TOPLEFT"
                    LeaPlusLC["FocusX"] = 250
                    LeaPlusLC["FocusY"] = -240
                    LeaPlusLC["FocusScale"] = 1.00
                    FocusFrame:ClearAllPoints()
                    FocusFrame:SetPoint(LeaPlusLC["FocusA"], UIParent, LeaPlusLC["FocusR"], LeaPlusLC["FocusX"], LeaPlusLC["FocusY"])
                    FocusFrame:SetScale(LeaPlusLC["FocusScale"])
                else
                    -- Find out if the UI has a non-standard scale
                    if GetCVar("useuiscale") == "1" then
                        LeaPlusLC["gscale"] = GetCVar("uiscale")
                    else
                        LeaPlusLC["gscale"] = 1
                    end

                    -- Set drag frame size and position according to UI scale
                    dragframe:SetWidth(196 * LeaPlusLC["gscale"])
                    dragframe:SetHeight(76 * LeaPlusLC["gscale"])
                    dragframe:ClearAllPoints()
                    dragframe:SetPoint("CENTER", FocusFrame, "CENTER", -18 * LeaPlusLC["gscale"], 6 * LeaPlusLC["gscale"])

                    -- Show configuration panel
                    FocusPanel:Show()
                    LeaPlusLC:HideFrames()
                    dragframe:Show()

                    -- Show frame alignment grid
                    LeaPlusLC.grid:Show()
                end
            end
        end)

        -- Hide drag frame when configuration panel is closed
        FocusPanel:HookScript("OnHide", function()
            dragframe:Hide()
        end)

    end

    ----------------------------------------------------------------------
    -- Hide chat buttons
    ----------------------------------------------------------------------

    if LeaPlusLC["NoChatButtons"] == "On" and not LeaLockList["NoChatButtons"] then

        -- Create hidden frame to store unwanted frames (more efficient than creating functions)
        local tframe = CreateFrame("FRAME")
        tframe:Hide()

        -- Function to enable mouse scrolling with CTRL and SHIFT key modifiers
        local function AddMouseScroll(chtfrm)
            if _G[chtfrm] then
                _G[chtfrm]:SetScript("OnMouseWheel", function(self, direction)
                    if direction == 1 then
                        if IsControlKeyDown() then
                            self:ScrollToTop()
                        elseif IsShiftKeyDown() then
                            self:PageUp()
                        else
                            self:ScrollUp()
                        end
                    else
                        if IsControlKeyDown() then
                            self:ScrollToBottom()
                        elseif IsShiftKeyDown() then
                            self:PageDown()
                        else
                            self:ScrollDown()
                        end
                    end
                end)
                _G[chtfrm]:EnableMouseWheel(true)
            end
        end

        -- Function to hide chat buttons
        local function HideButtons(chtfrm)
            _G[chtfrm .. "ButtonFrameUpButton"]:SetParent(tframe)
            _G[chtfrm .. "ButtonFrameDownButton"]:SetParent(tframe)
            _G[chtfrm .. "ButtonFrameMinimizeButton"]:SetParent(tframe)
            _G[chtfrm .. "ButtonFrameUpButton"]:Hide();
            _G[chtfrm .. "ButtonFrameDownButton"]:Hide();
            _G[chtfrm .. "ButtonFrameMinimizeButton"]:Hide();
            _G[chtfrm .. "ButtonFrame"]:SetSize(0.1, 0.1)
            _G[chtfrm .. "ButtonFrame"]:SetAlpha(0);
        end

        -- Function to highlight chat tabs and click to scroll to bottom
        local function HighlightTabs(chtfrm)

            -- Hide bottom button
            _G[chtfrm .. "ButtonFrameBottomButton"]:SetSize(0.1, 0.1) -- Positions it away

            -- Remove click from the bottom button
            _G[chtfrm .. "ButtonFrameBottomButton"]:SetScript("OnClick", nil)

            -- Remove textures
            _G[chtfrm .. "ButtonFrameBottomButton"]:SetNormalTexture("")
            _G[chtfrm .. "ButtonFrameBottomButton"]:SetHighlightTexture("")
            _G[chtfrm .. "ButtonFrameBottomButton"]:SetPushedTexture("")
            _G[chtfrm .. "ButtonFrameBottomButton"]:SetDisabledTexture("")

            -- Resize bottom button according to tab size
            _G[chtfrm .. "Tab"]:SetScript("OnSizeChanged", function()
                for j = 1, 50 do
                    -- Resize bottom button to tab width
                    if _G["ChatFrame" .. j .. "ButtonFrameBottomButton"] then
                        _G["ChatFrame" .. j .. "ButtonFrameBottomButton"]:SetWidth(_G["ChatFrame" .. j .. "Tab"]:GetWidth() - 10)
                    end
                end
                -- If combat log is hidden, resize it's bottom button
                if LeaPlusLC["NoCombatLogTab"] == "On" and not LeaLockList["NoCombatLogTab"] then
                    if _G["ChatFrame2ButtonFrameBottomButton"] then
                        -- Resize combat log bottom button
                        _G["ChatFrame2ButtonFrameBottomButton"]:SetWidth(0.1);
                    end
                end
            end)

            -- Remove click from the bottom button
            _G[chtfrm .. "ButtonFrameBottomButton"]:SetScript("OnClick", nil)

            -- Remove textures
            _G[chtfrm .. "ButtonFrameBottomButton"]:SetNormalTexture("")
            _G[chtfrm .. "ButtonFrameBottomButton"]:SetHighlightTexture("")
            _G[chtfrm .. "ButtonFrameBottomButton"]:SetPushedTexture("")

            -- Always scroll to bottom when clicking a tab
            _G[chtfrm .. "Tab"]:HookScript("OnClick", function(self, arg1)
                if arg1 == "LeftButton" then
                    _G[chtfrm]:ScrollToBottom();
                end
            end)

            -- Create new bottom button under tab
            _G[chtfrm .. "Tab"].newglow = _G[chtfrm .. "Tab"]:CreateTexture(nil, "BACKGROUND")
            _G[chtfrm .. "Tab"].newglow:ClearAllPoints()
            _G[chtfrm .. "Tab"].newglow:SetPoint("BOTTOMLEFT", _G[chtfrm .. "Tab"], "BOTTOMLEFT", 0, 0)
            _G[chtfrm .. "Tab"].newglow:SetTexture("Interface\\ChatFrame\\ChatFrameTab-NewMessage")
            _G[chtfrm .. "Tab"].newglow:SetWidth(_G[chtfrm .. "Tab"]:GetWidth())
            _G[chtfrm .. "Tab"].newglow:SetVertexColor(0.6, 0.6, 1, 1)
            _G[chtfrm .. "Tab"].newglow:Hide()

            -- -- Show new bottom button when old one glows
            -- _G[chtfrm .. "ButtonFrameBottomButtonFlash"]:HookScript("OnShow", function(self,arg1)
            -- 	_G[chtfrm .. "Tab"].newglow:Show()
            -- end)

            -- _G[chtfrm .. "ButtonFrameBottomButtonFlash"]:HookScript("OnHide", function(self,arg1)
            -- 	_G[chtfrm .. "Tab"].newglow:Hide()
            -- end)

            -- Match new bottom button size to tab
            _G[chtfrm .. "Tab"]:HookScript("OnSizeChanged", function()
                _G[chtfrm .. "Tab"].newglow:SetWidth(_G[chtfrm .. "Tab"]:GetWidth())
            end)

        end

        -- Hide chat menu buttons
        ChatFrameMenuButton:SetParent(tframe)
        -- ChatFrameChannelButton:SetParent(tframe)
        FriendsMicroButton:SetParent(tframe)


        -- Set options for normal and existing chat frames
        for i = 1, 50 do
            if _G["ChatFrame" .. i] then
                AddMouseScroll("ChatFrame" .. i);
                HideButtons("ChatFrame" .. i);
                HighlightTabs("ChatFrame" .. i)
            end
        end

        -- Do the functions above for temporary chat frames
        hooksecurefunc("FCF_OpenTemporaryWindow", function(chatType)
            local cf = FCF_GetCurrentChatFrame():GetName() or nil
            if cf then
                -- Set options for temporary frame
                AddMouseScroll(cf)
                HideButtons(cf)
                HighlightTabs(cf)
                -- Resize flashing alert to match tab width
                _G[cf .. "Tab"]:SetScript("OnSizeChanged", function()
                    _G[cf .. "ButtonFrameBottomButton"]:SetWidth(_G[cf .. "Tab"]:GetWidth() - 10)
                end)
            end
        end)

        -- Hide text to speech button
        -- TextToSpeechButton:SetParent(tframe)

    end

    ----------------------------------------------------------------------
    -- Recent chat window
    ----------------------------------------------------------------------

    if LeaPlusLC["RecentChatWindow"] == "On" and not LeaLockList["RecentChatWindow"] then

        -- only initialize once
        if not LeaPlusLC._RecentChatInit then
            LeaPlusLC._RecentChatInit = true

            ----------------------------------------
            -- 1) Main frame (Leatrix look)      --
            ----------------------------------------
            local frame = CreateFrame("Frame", "LeaPlusRecentChatFrame", UIParent)
            frame:Hide()
            frame:SetSize(600, LeaPlusLC["RecentChatSize"])
            frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 130)
            frame:SetFrameStrata("HIGH")
            frame:EnableMouse(true)
            frame:SetResizable(true)
            frame:SetMinResize(600, 50)
            frame:SetMaxResize(600, 680)
            frame:SetBackdrop({
                bgFile   = "Interface\\BUTTONS\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile     = true, tileSize = 16,
                edgeSize = 16, insets = { left=4, right=4, top=4, bottom=4 },
            })
            frame:SetBackdropColor(0, 0, 0, 0.6)

            -- ADDITION 1: Add to UISpecialFrames for ESC key functionality
            -- This allows the ESC key to close the window if it doesn't have a more specific target.
            if _G.UISpecialFrames then -- Ensure the table exists (it always should in WoW client)
                tinsert(_G.UISpecialFrames, "LeaPlusRecentChatFrame")
            end

            -- ADDITION 2: Define centralized cleanup logic for when the frame is hidden
            local function PerformRecentChatFrameCleanup()
                local editorToClose = LeaPlusLC.RecentChatEdit
                if editorToClose then
                    if editorToClose:IsShown() and editorToClose:HasFocus() then
                        editorToClose:ClearFocus()
                    end
                    editorToClose:SetText("")
                    editorToClose:Hide() -- Hide the editbox itself

                    -- Unset as scroll child if it is
                    if LeaPlusLC.RecentChatScroll and LeaPlusLC.RecentChatScroll:GetScrollChild() == editorToClose then
                        LeaPlusLC.RecentChatScroll:SetScrollChild(nil)
                    end
                end
                LeaPlusLC.RecentChatEdit = nil -- Clear the reference
            end

            -- ADDITION 3: Set the OnHide script for the main frame
            -- This will be called whenever frame:Hide() is executed,
            -- either by our Close() function or by the system (e.g., ESC key).
            frame:SetScript("OnHide", PerformRecentChatFrameCleanup)

            ----------------------------------------
            -- 2) Title bar (drag/resize/close) --
            ----------------------------------------
            local title = CreateFrame("Frame", nil, frame)
            title:SetSize(600, 36)
            title:SetPoint("TOP", frame, "TOP", 0, 40)
            title:SetFrameStrata("MEDIUM")
            title:EnableMouse(true)
            title:SetMovable(true)
            title:SetBackdrop(frame:GetBackdrop())
            title:SetBackdropColor(0, 0, 0, 0.6)

            -- message count
            title.count = title:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            title.count:SetPoint("LEFT", 9, 0)
            title.count:SetFont(title.count:GetFont(), 16)
            title.count:SetText("Messages: 0")

            -- drag-to-size & close hint
            title.hint = title:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            title.hint:SetPoint("RIGHT", -9, 0)
            title.hint:SetFont(title.hint:GetFont(), 16)
            title.hint:SetText(L["Drag to size"] .. " | " .. L["Right-click to close"])
            title.hint:SetWidth(600 - title.count:GetStringWidth() - 30)
            title.hint:SetJustifyH("RIGHT")

            -- Forward declare Close, ShowChatbox, ResizeEdit, ScrollToBottomReliable
            local Close
            local ShowChatbox
            local ResizeEdit
            local ScrollToBottomReliable

            -- MODIFICATION 1: Simplify the Close function
            -- The actual cleanup is now handled by the frame's OnHide script (PerformRecentChatFrameCleanup)
            Close = function()
                if frame:IsShown() then
                    frame:Hide() -- This will trigger the OnHide script
                end
            end

            -- drag, resize and close handlers for the title bar
            title:HookScript("OnMouseDown", function(self, btn)
                if btn == "LeftButton" then
                    frame:StartSizing("TOP")
                elseif btn == "RightButton" then
                    Close() -- Call the modified Close function
                end
            end)
            title:HookScript("OnMouseUp", function(self, btn)
                if btn == "LeftButton" then
                    frame:StopMovingOrSizing()
                    LeaPlusLC["RecentChatSize"] = frame:GetHeight()
                elseif btn == "MiddleButton" then
                    LeaPlusLC["RecentChatSize"] = 170
                    frame:SetSize(600, 170)
                    frame:ClearAllPoints()
                    frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 130)
                end
            end)

            ----------------------------------------
            -- 3) ScrollFrame (ElvUI)           --
            ----------------------------------------
            local scroll = CreateFrame("ScrollFrame", "LeaPlusRecentChatScroll", frame, "UIPanelScrollFrameTemplate")
            scroll:SetPoint("TOPLEFT",    frame, "TOPLEFT",    26, -36)
            scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 8)

            local sb = scroll.ScrollBar or LeaPlusRecentChatScrollScrollBar
            sb:ClearAllPoints()
            sb:SetPoint("TOPLEFT",  scroll, "TOPRIGHT", 3, -16)
            sb:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 3, 16)

            -- right-click to close on all areas (frame and scroll are static)
            frame:HookScript("OnMouseDown", function(_, btn) if btn == "RightButton" then Close() end end)
            scroll:HookScript("OnMouseDown", function(_,btn)  if btn == "RightButton" then Close() end end)

            -- dynamically resize edit-box height
            ResizeEdit = function(count)
                local currentEdit = LeaPlusLC.RecentChatEdit
                if not currentEdit then return end
                local _, size = currentEdit:GetFont()
                local needed = count * (size + 2)
                currentEdit:SetHeight(math.max(needed, scroll:GetHeight()))
            end

            -- scroll with mouse-wheel (existing logic seems fine)
            scroll:SetScript("OnMouseWheel", function(self, delta)
                local currentEdit = LeaPlusLC.RecentChatEdit
                local maxScrollRange = self:GetVerticalScrollRange()
                if not maxScrollRange or maxScrollRange <= 0 then return end
                local currentScroll = self:GetVerticalScroll()
                local viewHeight = self:GetHeight()
                local stepAmount
                if IsAltKeyDown() then
                    stepAmount = viewHeight
                else
                    local fontHeight = 14
                    if currentEdit and currentEdit:IsShown() then
                        local _, fh = currentEdit:GetFont()
                        if fh and fh > 0 then fontHeight = fh end
                    end
                    local linesToScroll = 3
                    stepAmount = fontHeight * linesToScroll
                end
                local newScrollPosition
                if delta > 0 then
                    newScrollPosition = IsShiftKeyDown() and 0 or (currentScroll - stepAmount)
                else
                    newScrollPosition = IsShiftKeyDown() and maxScrollRange or (currentScroll + stepAmount)
                end
                newScrollPosition = math.max(0, newScrollPosition)
                newScrollPosition = math.min(newScrollPosition, maxScrollRange)
                self:SetVerticalScroll(newScrollPosition)
            end)

            ----------------------------------------
            -- 4) Populate on Ctrl+Click tabs    --
            ----------------------------------------
            local chatTypeIndexToName = {}
            for chatType in pairs(ChatTypeInfo) do
                chatTypeIndexToName[ GetChatTypeIndex(chatType) ] = chatType
            end

            ScrollToBottomReliable = function(scrollInstance, editInstance, maxAttempts)
                maxAttempts = maxAttempts or 20
                local lastHeight = 0
                local attempts = 0
                local function tryScroll()
                    attempts = attempts + 1
                    if not editInstance or not editInstance:IsShown() then return end
                    local curHeight = editInstance:GetHeight()
                    if curHeight ~= lastHeight and attempts < maxAttempts then
                        lastHeight = curHeight
                        LibCompat.After(0.02, tryScroll)
                    else
                        if scrollInstance and scrollInstance:IsShown() then
                            scrollInstance:SetVerticalScroll(scrollInstance:GetVerticalScrollRange())
                        end
                    end
                end
                tryScroll()
            end

            ShowChatbox = function(chatFrame)
                -- OPTIONAL BUT RECOMMENDED: Clean up previous edit box if one exists
                if LeaPlusLC.RecentChatEdit then
                    -- Perform a light cleanup; full cleanup is via OnHide if frame closes.
                    -- This handles the case where the frame remains open but content changes.
                    local oldEdit = LeaPlusLC.RecentChatEdit
                    oldEdit:Hide()
                    oldEdit:SetText("")
                    if LeaPlusLC.RecentChatScroll and LeaPlusLC.RecentChatScroll:GetScrollChild() == oldEdit then
                        LeaPlusLC.RecentChatScroll:SetScrollChild(nil)
                    end
                    -- oldEdit will be garbage collected if it has no other references/parentage issues
                end
                LeaPlusLC.RecentChatEdit = nil -- Ensure it's nil before creating a new one


                local edit = CreateFrame("EditBox", nil, scroll)
                edit:SetFontObject(ChatFontNormal)
                edit:SetMultiLine(true)
                edit:SetMaxLetters(0)
                edit:SetAutoFocus(false)
                edit:EnableMouse(true)
                edit:EnableMouseWheel(true)
                edit:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
                edit:SetWidth(scroll:GetWidth())
                scroll:SetScrollChild(edit)
                LeaPlusLC.RecentChatEdit = edit

                edit:HookScript("OnCursorChanged", function(self_hooked_edit)
                    if not IsMouseButtonDown("LeftButton") and not IsMouseButtonDown("RightButton") then
                        LibCompat.After(0.02, function()
                            local currentEdit = LeaPlusLC.RecentChatEdit
                            local currentScroll = LeaPlusLC.RecentChatScroll
                            if not currentEdit or not currentEdit:IsShown() or currentEdit ~= self_hooked_edit then return end
                            local fontHeight = select(2, currentEdit:GetFont()) or 14
                            local cursorPos = currentEdit:GetCursorPosition()
                            local text = currentEdit:GetText()
                            local n = 0; for i = 1, cursorPos do if text:sub(i,i) == "\n" then n = n + 1 end end
                            local line = n + 1
                            local totalLines = 1; for _ in text:gmatch("\n") do totalLines = totalLines + 1 end
                            local scrollMax = currentScroll:GetVerticalScrollRange()
                            if line == totalLines then
                                currentScroll:SetVerticalScroll(scrollMax)
                            else
                                local scrollMin = currentScroll:GetVerticalScroll()
                                local scrollHeight = currentScroll:GetHeight()
                                local minLine = math.floor(scrollMin / fontHeight + 1.5)
                                local maxLine = math.floor((scrollMin + scrollHeight) / fontHeight + 0.5)
                                if line < minLine then currentScroll:SetVerticalScroll((line - 1) * fontHeight)
                                elseif line > maxLine then currentScroll:SetVerticalScroll(math.max(0, (line - math.floor(scrollHeight / fontHeight)) * fontHeight))
                                end
                            end
                        end)
                    end
                end)

                edit:HookScript("OnMouseDown", function(_, btn) if btn == "RightButton" then Close() end end)
                edit:SetScript("OnEscapePressed", Close) -- This is important for when editbox has focus

                edit:ClearFocus()
                edit:SetText("")
                local num = chatFrame:GetNumMessages()

                if num == 0 then
                    title.count:SetText("Messages: 0")
                    ResizeEdit(0)
                    frame:Show() -- Ensure frame is shown even if empty
                    return
                end

                local lines, count = {}, 0
                for i = 1, num do
                    local msg, _, lineID = chatFrame:GetMessageInfo(i)
                    if msg then
                        msg = gsub(msg, "|T.-|t", "")
                        msg = gsub(msg, "|A.-|a", "")
                        local info = ChatTypeInfo[ chatTypeIndexToName[lineID] ]
                        local r,g,b = (info and info.r) or 1, (info and info.g) or 1, (info and info.b) or 1
                        local hex = format("|cff%02x%02x%02x", r*255, g*255, b*255)
                        msg = hex .. msg:gsub("|r","|r"..hex) .. "|r"
                        table.insert(lines, msg)
                        count = count + 1
                    end
                end

                title.count:SetText("Messages: "..count)
                edit:SetText(table.concat(lines, "\n"))
                ResizeEdit(count)
                ScrollToBottomReliable(scroll, edit, 20)
                frame:Show()
            end

            for id = 1, NUM_CHAT_WINDOWS do
                local tab = _G["ChatFrame"..id.."Tab"]
                if tab then
                    tab:HookScript("OnMouseUp", (function(idx)
                        return function(self, btn)
                            if btn == "LeftButton" and IsControlKeyDown() then
                                -- If the same frame is already shown, toggle it off.
                                -- Otherwise, show new content or first content.
                                if frame:IsShown() and LeaPlusLC.RecentChatEdit and LeaPlusLC.CurrentRecentChatSource == _G["ChatFrame"..idx] then
                                    Close()
                                else
                                    LeaPlusLC.CurrentRecentChatSource = _G["ChatFrame"..idx] -- Track source
                                    ShowChatbox(_G["ChatFrame"..idx])
                                end
                            end
                        end
                    end)(id))
                end
            end

            LeaPlusLC.RecentChatFrame  = frame
            LeaPlusLC.RecentChatTitle  = title
            LeaPlusLC.RecentChatScroll = scroll
            -- LeaPlusLC.RecentChatEdit is now set dynamically in ShowChatbox
            -- LeaPlusLC.CurrentRecentChatSource is a new helper variable to track the source for toggling
        end
    end

    ----------------------------------------------------------------------
    -- Show cooldowns
    ----------------------------------------------------------------------

    -- if LeaPlusLC["ShowCooldowns"] == "On" then

    -- 	-- Create main table structure in saved variables if it doesn't exist
    -- 	if LeaPlusDB["Cooldowns"] == nil then
    -- 		LeaPlusDB["Cooldowns"] = {}
    -- 	end

    -- 	-- Create class tables if they don't exist
    -- 	local classList = {"WARRIOR", "PALADIN", "HUNTER", "SHAMAN", "ROGUE", "DRUID", "MAGE", "WARLOCK", "PRIEST", "DEATHKNIGHT"}
    -- 	for index = 1, #classList do
    -- 		if LeaPlusDB["Cooldowns"][classList[index]] == nil then
    -- 			LeaPlusDB["Cooldowns"][classList[index]] = {}
    -- 		end
    -- 	end

    -- 	-- Get current class
    -- 	local PlayerClass = select(2, UnitClass("player"))
    -- 	local activeSpec = 1 -- Fixed to 1 for Classic

    -- 	-- Create local tables to store cooldown frames and editboxes
    -- 	local icon = {} -- Used to store cooldown frames
    -- 	local SpellEB = {} -- Used to store editbox values
    -- 	local iCount = 5 -- Number of cooldowns

    -- 	-- Create cooldown frames
    -- 	for i = 1, iCount do

    -- 		-- Create cooldown frame
    -- 		icon[i] = CreateFrame("Frame", nil, UIParent)
    -- 		icon[i]:SetFrameStrata("BACKGROUND")
    -- 		icon[i]:SetWidth(20)
    -- 		icon[i]:SetHeight(20)

    -- 		-- Create cooldown icon
    -- 		icon[i].c = CreateFrame("Cooldown", nil, icon[i], "CooldownFrameTemplate")
    -- 		icon[i].c:SetAllPoints()
    -- 		-- icon[i].c:SetReverse(true)

    -- 		-- Create blank texture (will be assigned a cooldown texture later)
    -- 		icon[i].t = icon[i]:CreateTexture(nil,"BACKGROUND")
    -- 		icon[i].t:SetAllPoints()

    -- 		-- Show icon above target frame and set initial scale
    -- 		icon[i]:ClearAllPoints()
    -- 		icon[i]:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", 6 + (22 * (i - 1)), 5)
    -- 		icon[i]:SetScale(TargetFrame:GetScale())

    -- 		-- Show tooltip
    -- 		icon[i]:SetScript("OnEnter", function(self)
    -- 			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 15, -25)
    -- 			GameTooltip:SetText(GetSpellInfo(LeaPlusCB["Spell" .. i]:GetText()))
    -- 		end)

    -- 		-- Hide tooltip
    -- 		icon[i]:SetScript("OnLeave", GameTooltip_Hide)

    -- 	end

    -- 	-- Change cooldown icon scale when player frame scale changes
    -- 	PlayerFrame:HookScript("OnSizeChanged", function()
    -- 		if LeaPlusLC["CooldownsOnPlayer"] == "On" then
    -- 			for i = 1, iCount do
    -- 				icon[i]:SetScale(PlayerFrame:GetScale())
    -- 			end
    -- 		end
    -- 	end)

    -- 	-- Change cooldown icon scale when target frame scale changes
    -- 	TargetFrame:HookScript("OnSizeChanged", function()
    -- 		if LeaPlusLC["CooldownsOnPlayer"] == "Off" then
    -- 			for i = 1, iCount do
    -- 				icon[i]:SetScale(TargetFrame:GetScale())
    -- 			end
    -- 		end
    -- 	end)

    -- 	-- Function to show cooldown textures in the cooldown frames (run when icons are loaded or changed)
    -- 	local function ShowIcon(i, id, owner)

    -- 		local void

    -- 		-- Get spell information
    -- 		local spell, void, path = GetSpellInfo(id)
    -- 		print(path)
    -- 		print(spell)
    -- 		if spell and path then

    -- 			-- Set icon texture to the spell texture
    -- 			icon[i].t:SetTexture(path)

    -- 			-- Set top level and raise frame strata (ensures tooltips show properly)
    -- 			icon[i]:SetToplevel(true)
    -- 			icon[i]:SetFrameStrata("LOW")

    -- 			-- Handle events
    -- 			-- 3.3.5 FIXME
    -- 			icon[i]:RegisterUnitEvent("UNIT_AURA", owner)
    -- 			icon[i]:RegisterUnitEvent("UNIT_PET", "player")
    -- 			icon[i]:SetScript("OnEvent", function(self, event, arg1)

    -- 				-- If pet was dismissed (or otherwise disappears such as when flying), hide pet cooldowns
    -- 				if event == "UNIT_PET" then
    -- 					if not UnitExists("pet") then
    -- 						if LeaPlusDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"] then
    -- 							icon[i]:Hide()
    -- 						end
    -- 					end

    -- 				-- Ensure cooldown belongs to the owner we are watching (player or pet)
    -- 				elseif arg1 == owner then

    -- 					-- Hide the cooldown frame (required for cooldowns to disappear after the duration)
    -- 					icon[i]:Hide()

    -- 					-- If buff matches cooldown we want, start the cooldown
    -- 					for q = 1, 40 do
    -- 						local void, void, void, void, void, length, expire, void, void, void, spellID = UnitBuff(owner, q)
    -- 						if spellID and id == spellID then
    -- 							icon[i]:Show()
    -- 							local start = expire - length
    -- 							CooldownFrame_SetTimer(icon[i].c, start, length, 1)
    -- 						end
    -- 					end

    -- 				end
    -- 			end)

    -- 		else

    -- 			-- Spell does not exist so stop watching it
    -- 			icon[i]:SetScript("OnEvent", nil)
    -- 			icon[i]:Hide()

    -- 		end

    -- 	end

    -- 	-- Create configuration panel
    -- 	local CooldownPanel = LeaPlusLC:CreatePanel("Show cooldowns", "CooldownPanel")

    -- 	-- Function to refresh the editbox tooltip with the spell name
    -- 	local function RefSpellTip(self,elapsed)
    -- 		local spellinfo, void, icon = GetSpellInfo(self:GetText())
    -- 		if spellinfo and spellinfo ~= "" and icon and icon ~= "" then
    -- 			GameTooltip:SetOwner(self, "ANCHOR_NONE")
    -- 			GameTooltip:ClearAllPoints()
    -- 			GameTooltip:SetPoint("RIGHT", self, "LEFT", -10, 0)
    -- 			GameTooltip:SetText("|T" .. icon .. ":0|t " .. spellinfo, nil, nil, nil, nil, true)
    -- 		else
    -- 			GameTooltip:Hide()
    -- 		end
    -- 	end

    -- 	-- Function to create spell ID editboxes and pet checkboxes
    -- 	local function MakeSpellEB(num, x, y, tab, shifttab)

    -- 		-- Create editbox for spell ID
    --         SpellEB[num] = LeaPlusLC:CreateEditBox("Spell" .. num, CooldownPanel, 70, 6, "TOPLEFT", x, y - 20, "Spell" .. tab, "Spell" .. shifttab)
    -- 		SpellEB[num]:SetNumeric(true)

    -- 		-- Set initial value (for current spec)
    -- 		SpellEB[num]:SetText(LeaPlusDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. num .. "Idn"] or "")

    -- 		-- Refresh tooltip when mouse is hovering over the editbox
    -- 		SpellEB[num]:SetScript("OnEnter", function()
    -- 			SpellEB[num]:SetScript("OnUpdate", RefSpellTip)
    -- 		end)
    -- 		SpellEB[num]:SetScript("OnLeave", function()
    -- 			SpellEB[num]:SetScript("OnUpdate", nil)
    -- 			GameTooltip:Hide()
    -- 		end)

    -- 		-- Create checkbox for pet cooldown
    -- 		LeaPlusLC:MakeCB(CooldownPanel, "Spell" .. num .."Pet", "", 462, y - 20, false, "")
    -- 		LeaPlusCB["Spell" .. num .."Pet"]:SetHitRectInsets(0, 0, 0, 0)

    -- 	end

    -- 	-- Add titles
    -- 	LeaPlusLC:MakeTx(CooldownPanel, "Spell ID", 384, -92)
    -- 	LeaPlusLC:MakeTx(CooldownPanel, "Pet", 462, -92)

    -- 	-- Add editboxes and checkboxes
    -- 	MakeSpellEB(1, 386, -92, "2", "5")
    -- 	MakeSpellEB(2, 386, -122, "3", "1")
    -- 	MakeSpellEB(3, 386, -152, "4", "2")
    -- 	MakeSpellEB(4, 386, -182, "5", "3")
    -- 	MakeSpellEB(5, 386, -212, "1", "4")

    -- 	-- Add checkboxes
    -- 	LeaPlusLC:MakeTx(CooldownPanel, "Settings", 16, -72)
    -- 	LeaPlusLC:MakeCB(CooldownPanel, "ShowCooldownID", "Show the spell ID in buff icon tooltips", 16, -92, false, "If checked, spell IDs will be shown in buff icon tooltips located in the buff frame and under the target frame.");
    -- 	LeaPlusLC:MakeCB(CooldownPanel, "NoCooldownDuration", "Hide cooldown duration numbers (if enabled)", 16, -112, false, "If checked, cooldown duration numbers will not be shown over the cooldowns.|n|nIf unchecked, cooldown duration numbers will be shown over the cooldowns if they are enabled in the game options panel ('ActionBars' menu).")
    -- 	LeaPlusLC:MakeCB(CooldownPanel, "CooldownsOnPlayer", "Show cooldowns above the player frame", 16, -132, false, "If checked, cooldown icons will be shown above the player frame instead of the target frame.|n|nIf unchecked, cooldown icons will be shown above the target frame.")

    -- 	-- Function to save the panel control settings and refresh the cooldown icons
    -- 	local function SavePanelControls()
    -- 		for i = 1, iCount do

    -- 			-- -- Refresh the cooldown texture
    -- 			-- icon[i].c:SetCooldown(0,0)

    -- 			-- Show icons above target or player frame
    -- 			icon[i]:ClearAllPoints()
    -- 			if LeaPlusLC["CooldownsOnPlayer"] == "On" then
    -- 				icon[i]:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 116 + (22 * (i - 1)), 5)
    -- 				icon[i]:SetScale(PlayerFrame:GetScale())
    -- 			else
    -- 				icon[i]:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", 6 + (22 * (i - 1)), 5)
    -- 				icon[i]:SetScale(TargetFrame:GetScale())
    -- 			end

    -- 			-- Save control states to globals
    -- 			LeaPlusDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Idn"] = SpellEB[i]:GetText()
    -- 			LeaPlusDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"] = LeaPlusCB["Spell" .. i .."Pet"]:GetChecked()

    -- 			-- Set cooldowns
    -- 			if LeaPlusCB["Spell" .. i .."Pet"]:GetChecked() then
    -- 				ShowIcon(i, tonumber(SpellEB[i]:GetText()), "pet")
    -- 			else
    -- 				ShowIcon(i, tonumber(SpellEB[i]:GetText()), "player")
    -- 			end

    -- 			-- -- Show or hide cooldown duration
    -- 			-- if LeaPlusLC["NoCooldownDuration"] == "On" then
    -- 			-- 	icon[i].c:SetHideCountdownNumbers(true)
    -- 			-- else
    -- 			-- 	icon[i].c:SetHideCountdownNumbers(false)
    -- 			-- end

    -- 			-- Show or hide cooldown icons depending on current buffs
    -- 			local newowner
    -- 			local newspell = tonumber(SpellEB[i]:GetText())
    -- 			print(newspell)

    -- 			if newspell then
    -- 				if LeaPlusDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"] then
    -- 					newowner = "pet"
    -- 				else
    -- 					newowner = "player"
    -- 				end
    -- 				-- Hide cooldown icon
    -- 				icon[i]:Hide()

    -- 				-- If buff matches spell we want, show cooldown icon
    -- 				for q = 1, 40 do
    -- 					local void, void, void, void, void, length, expire, void, void, void, spellID = UnitBuff(newowner, q)
    -- 					if spellID and newspell == spellID then
    -- 						icon[i]:Show()
    -- 						-- Set the cooldown to the buff cooldown
    -- 						CooldownFrame_SetTimer(icon[i].c, expire - length, length, 1)
    -- 					end
    -- 				end
    -- 			end

    -- 		end

    -- 	end

    -- 	-- Update cooldown icons when checkboxes are clicked
    -- 	LeaPlusCB["NoCooldownDuration"]:HookScript("OnClick", SavePanelControls)
    -- 	LeaPlusCB["CooldownsOnPlayer"]:HookScript("OnClick", SavePanelControls)

    -- 	-- Help button tooltip
    -- 	CooldownPanel.h.tiptext = L["Enter the spell IDs for the cooldown icons that you want to see.|n|nIf a cooldown icon normally appears under the pet frame, check the pet checkbox.|n|nCooldown icons are saved to your class."]

    -- 	-- Back button handler
    -- 	CooldownPanel.b:SetScript("OnClick", function()
    -- 		CooldownPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
    -- 		return
    -- 	end)

    -- 	-- Reset button handler
    -- 	CooldownPanel.r:SetScript("OnClick", function()
    -- 		-- Reset the checkboxes
    -- 		LeaPlusLC["ShowCooldownID"] = "On"
    -- 		LeaPlusLC["NoCooldownDuration"] = "On"
    -- 		LeaPlusLC["CooldownsOnPlayer"] = "Off"
    -- 		for i = 1, iCount do
    -- 			-- Reset the panel controls
    -- 			SpellEB[i]:SetText("");
    -- 			LeaPlusDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"] = false
    -- 			-- Hide cooldowns and clear scripts
    -- 			icon[i]:Hide()
    -- 			icon[i]:SetScript("OnEvent", nil)
    -- 		end
    -- 		CooldownPanel:Hide(); CooldownPanel:Show()
    -- 	end)

    -- 	-- Save settings when changed
    -- 	for i = 1, iCount do
    -- 		-- Set initial checkbox states
    -- 		LeaPlusCB["Spell" .. i .."Pet"]:SetChecked(LeaPlusDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"])
    -- 		-- Set checkbox states when shown
    -- 		LeaPlusCB["Spell" .. i .."Pet"]:SetScript("OnShow", function()
    -- 			LeaPlusCB["Spell" .. i .."Pet"]:SetChecked(LeaPlusDB["Cooldowns"][PlayerClass]["S" .. activeSpec .. "R" .. i .. "Pet"])
    -- 		end)
    -- 		-- Set states when changed
    -- 		SpellEB[i]:SetScript("OnTextChanged", SavePanelControls)
    -- 		LeaPlusCB["Spell" .. i .."Pet"]:SetScript("OnClick", SavePanelControls)
    -- 	end

    -- 	-- Show cooldowns on startup
    -- 	SavePanelControls()

    -- 	-- Show panel when configuration button is clicked
    -- 	LeaPlusCB["CooldownsButton"]:SetScript("OnClick", function()
    -- 		if IsShiftKeyDown() and IsControlKeyDown() then
    -- 			-- No preset profile
    -- 		else
    -- 			-- Show panel
    -- 			CooldownPanel:Show()
    -- 			LeaPlusLC:HideFrames()
    -- 		end
    -- 	end)

    -- 	-- Create class tag banner fontstring
    -- 	local classTagBanner = CooldownPanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    -- 	local myClassName = UnitClass("player")
    -- 	classTagBanner:SetPoint("TOPLEFT", 384, -72)
    -- 	classTagBanner:SetText(myClassName)

    -- 	-- Function to show spell ID in tooltips
    -- 	local function CooldownIDFunc(unit, target, index, auratype)
    -- 		if LeaPlusLC["ShowCooldownID"] == "On" and auratype ~= "HARMFUL" then
    -- 			local spellid = select(11, UnitAura(target, index))
    -- 			if spellid then
    -- 				GameTooltip:AddLine(L["Spell ID"] .. ": " .. spellid)
    -- 				GameTooltip:Show()
    -- 			end
    -- 		end
    -- 	end

    -- 	-- Add spell ID to tooltip when buff frame buffs are hovered
    -- 	hooksecurefunc(GameTooltip, 'SetUnitAura', CooldownIDFunc)

    -- 	-- Add spell ID to tooltip when target frame buffs are hovered
    -- 	hooksecurefunc(GameTooltip, 'SetUnitBuff', CooldownIDFunc)

    -- end

    ----------------------------------------------------------------------
    -- Combat plates
    ----------------------------------------------------------------------

    if LeaPlusLC["CombatPlates"] == "On" then

        -- Toggle nameplates with combat
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_REGEN_DISABLED")
        f:RegisterEvent("PLAYER_REGEN_ENABLED")
        f:SetScript("OnEvent", function(self, event)
            SetCVar("nameplateShowEnemies", event == "PLAYER_REGEN_DISABLED" and 1 or 0)
        end)

        -- Run combat check on startup
        SetCVar("nameplateShowEnemies", UnitAffectingCombat("player") and 1 or 0)

    end

    ----------------------------------------------------------------------
    -- Enhance tooltip
    ----------------------------------------------------------------------

    if LeaPlusLC["TipModEnable"] == "On" and not LeaLockList["TipModEnable"] then

        ----------------------------------------------------------------------
        --	Position the tooltip
        ----------------------------------------------------------------------

        hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
            if LeaPlusLC["TooltipAnchorMenu"] ~= 1 then
                if (not tooltip or not parent) then
                    return
                end
                if LeaPlusLC["TooltipAnchorMenu"] == 2 or GetMouseFocus() ~= WorldFrame then
                    local a, b, c, d, e = tooltip:GetPoint()
                    if a ~= "BOTTOMRIGHT" or c ~= "BOTTOMRIGHT" then
                        tooltip:ClearAllPoints()
                    end
                    tooltip:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", LeaPlusLC["TipOffsetX"], LeaPlusLC["TipOffsetY"]);
                    return
                else
                    if LeaPlusLC["TooltipAnchorMenu"] == 3 then
                        tooltip:SetOwner(parent, "ANCHOR_CURSOR")
                        return
                        -- elseif LeaPlusLC["TooltipAnchorMenu"] == 4 then
                        -- 	tooltip:SetOwner(parent, "ANCHOR_CURSOR_LEFT", LeaPlusLC["TipCursorX"], LeaPlusLC["TipCursorY"])
                        -- 	return
                    elseif LeaPlusLC["TooltipAnchorMenu"] == 4 then
                        tooltip:SetOwner(parent, "ANCHOR_CURSOR_RIGHT", LeaPlusLC["TipCursorX"], LeaPlusLC["TipCursorY"])
                        return
                    end
                end
            end
        end)

        ----------------------------------------------------------------------
        --	Tooltip Configuration
        ----------------------------------------------------------------------

        local LT = {}

        -- Create locale specific level string
        LT["LevelLocale"] = strtrim(strtrim(string.gsub(TOOLTIP_UNIT_LEVEL, "%%s", "")))
        if GameLocale == "ruRU" then
            LT["LevelLocale"] = "-ro уровня"
        end

        -- Tooltip
        LT["ColorBlind"] = GetCVar("colorblindMode")

        -- 	Create drag frame
        local TipDrag = CreateFrame("Frame", nil, UIParent)
        TipDrag:SetToplevel(true);
        TipDrag:SetClampedToScreen(false);
        TipDrag:SetSize(130, 64);
        TipDrag:Hide();
        TipDrag:SetFrameStrata("TOOLTIP")
        TipDrag:SetMovable(true)
        TipDrag:EnableMouse(true)
        TipDrag:RegisterForDrag("LeftButton")
        TipDrag:SetBackdropColor(0.0, 0.5, 1.0);
        TipDrag:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, tileSize = 0, edgeSize = 16,
            insets = { left = 0, right = 0, top = 0, bottom = 0 } });

        -- Show text in drag frame
        TipDrag.f = TipDrag:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
        TipDrag.f:SetPoint("CENTER", 0, 0)
        TipDrag.f:SetText(L["Tooltip"])

        -- Create texture
        TipDrag.t = TipDrag:CreateTexture();
        TipDrag.t:SetAllPoints();
        TipDrag.t:SetTexture(0.0, 0.5, 1.0, 0.5)
        TipDrag.t:SetAlpha(0.5);


        ---- Create moving message
        --local LeaPlusMoveTipMsg = UIParent:CreateFontString(nil, "OVERLAY", 'GameFontNormalLarge')
        --LeaPlusMoveTipMsg:SetParent(TipDrag)
        --LeaPlusMoveTipMsg:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        --LeaPlusMoveTipMsg:SetText("Drag the blue tooltip frame or right-click it to hide")
        --LeaPlusMoveTipMsg:Hide();

        ---------------------------------------------------------------------------------------------------------
        -- Tooltip movement settings
        ---------------------------------------------------------------------------------------------------------

        -- Create tooltip customisation side panel
        local SideTip = LeaPlusLC:CreatePanel("Enhance tooltip", "SideTip")

        -- Add controls
        LeaPlusLC:MakeTx(SideTip, "Settings", 16, -72)
        LeaPlusLC:MakeCB(SideTip, "TipShowRank", "Show guild ranks for your guild", 16, -92, false, "If checked, guild ranks will be shown for players in your guild.")
        LeaPlusLC:MakeCB(SideTip, "TipShowOtherRank", "Show guild ranks for other guilds", 16, -112, false, "If checked, guild ranks will be shown for players who are not in your guild.")
        LeaPlusLC:MakeCB(SideTip, "TipShowTarget", "Show unit targets", 16, -132, false, "If checked, unit targets will be shown.")
        LeaPlusLC:MakeCB(SideTip, "TipNoHealthBar", "Hide the health bar", 16, -152, true, "If checked, the health bar will not be shown.")

        LeaPlusLC:MakeTx(SideTip, "Hide tooltips", 16, -192)
        LeaPlusLC:MakeCB(SideTip, "TipHideInCombat", "Hide tooltips for world units during combat", 16, -212, false, "If checked, tooltips for world units will be hidden during combat.")
        LeaPlusLC:MakeCB(SideTip, "TipHideShiftOverride", "Show tooltips with shift key", 16, -232, false, "If checked, you can hold shift while tooltips are hidden to show them temporarily.")

        -- Handle show tooltips with shift key lock
        local function SetTipHideShiftOverrideFunc()
            if LeaPlusLC["TipHideInCombat"] == "On" then
                LeaPlusLC:LockItem(LeaPlusCB["TipHideShiftOverride"], false)
            else
                LeaPlusLC:LockItem(LeaPlusCB["TipHideShiftOverride"], true)
            end
        end

        LeaPlusCB["TipHideInCombat"]:HookScript("OnClick", SetTipHideShiftOverrideFunc)
        SetTipHideShiftOverrideFunc()

        LeaPlusLC:CreateDropDown("TooltipAnchorMenu", "Anchor", SideTip, 146, "TOPLEFT", 356, -115, { L["None"], L["Overlay"], L["Cursor"], L["Cursor Right"] }, "")

        local XOffsetHeading = LeaPlusLC:MakeTx(SideTip, "X Offset", 356, -132)
        LeaPlusLC:MakeSL(SideTip, "TipCursorX", "Drag to set the cursor X offset.", -128, 128, 1, 356, -152, "%.0f")

        local YOffsetHeading = LeaPlusLC:MakeTx(SideTip, "Y Offset", 356, -182)
        LeaPlusLC:MakeSL(SideTip, "TipCursorY", "Drag to set the cursor Y offset.", -128, 128, 1, 356, -202, "%.0f")

        LeaPlusLC:MakeTx(SideTip, "Scale", 356, -232)
        LeaPlusLC:MakeSL(SideTip, "LeaPlusTipSize", "Drag to set the tooltip scale.", 0.50, 2.00, 0.05, 356, -252, "%.2f")

        -- Function to enable or disable anchor controls
        local function SetAnchorControls()
            -- Hide overlay if anchor is set to none
            if LeaPlusLC["TooltipAnchorMenu"] == 2 then
                --LeaPlusMoveTipMsg:Show()
                TipDrag:Show()
            else
                --LeaPlusMoveTipMsg:Hide()
                TipDrag:Hide()
            end
            -- Set the X and Y sliders
            if LeaPlusLC["TooltipAnchorMenu"] == 1 or LeaPlusLC["TooltipAnchorMenu"] == 2 or LeaPlusLC["TooltipAnchorMenu"] == 3 then
                -- Dropdown is set to screen or cursor so disable X and Y offset sliders
                LeaPlusLC:LockItem(LeaPlusCB["TipCursorX"], true)
                LeaPlusLC:LockItem(LeaPlusCB["TipCursorY"], true)
                XOffsetHeading:SetAlpha(0.3)
                YOffsetHeading:SetAlpha(0.3)
                LeaPlusCB["TipCursorX"]:SetScript("OnEnter", nil)
                LeaPlusCB["TipCursorY"]:SetScript("OnEnter", nil)
            else
                -- Dropdown is set to cursor left or cursor right so enable X and Y offset sliders
                LeaPlusLC:LockItem(LeaPlusCB["TipCursorX"], false)
                LeaPlusLC:LockItem(LeaPlusCB["TipCursorY"], false)
                XOffsetHeading:SetAlpha(1.0)
                YOffsetHeading:SetAlpha(1.0)
                LeaPlusCB["TipCursorX"]:SetScript("OnEnter", LeaPlusLC.TipSee)
                LeaPlusCB["TipCursorY"]:SetScript("OnEnter", LeaPlusLC.TipSee)
            end
        end

        -- Set controls when anchor dropdown menu is changed and on startup
        LeaPlusCB["ListFrameTooltipAnchorMenu"]:HookScript("OnHide", SetAnchorControls)
        SetAnchorControls()

        -- Help button hidden
        SideTip.h:Hide()

        -- Back button handler
        SideTip.b:SetScript("OnClick", function()
            --LeaPlusMoveTipMsg:Hide()
            SideTip:Hide();
            if TipDrag:IsShown() then
                TipDrag:Hide();
            end
            LeaPlusLC["PageF"]:Show();
            LeaPlusLC["Page5"]:Show();
            return
        end)

        -- Reset button handler
        SideTip.r.tiptext = SideTip.r.tiptext .. "|n|n" .. L["Note that this will not reset settings that require a UI reload."]
        SideTip.r:SetScript("OnClick", function()
            LeaPlusLC["TipShowRank"] = "On"
            LeaPlusLC["TipShowOtherRank"] = "Off"
            LeaPlusLC["TipShowTarget"] = "On"
            LeaPlusLC["TipHideInCombat"] = "Off";
            SetTipHideShiftOverrideFunc()
            LeaPlusLC["TipHideShiftOverride"] = "On"
            LeaPlusLC["LeaPlusTipSize"] = 1.00
            LeaPlusLC["TipOffsetX"] = -13
            LeaPlusLC["TipOffsetY"] = 94
            LeaPlusLC["TooltipAnchorMenu"] = 1
            LeaPlusLC["TipCursorX"] = 0
            LeaPlusLC["TipCursorY"] = 0
            TipDrag:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", LeaPlusLC["TipOffsetX"], LeaPlusLC["TipOffsetY"]);
            SetAnchorControls()
            LeaPlusLC:SetTipScale()
            SideTip:Hide();
            SideTip:Show();
            --LeaPlusMoveTipMsg:Hide()
        end)

        -- Show drag frame with configuration panel if anchor is not set to none
        SideTip:HookScript("OnShow", function()
            if LeaPlusLC["TooltipAnchorMenu"] == 1 then
                TipDrag:Hide()
            else
                TipDrag:Show()
            end
        end)
        SideTip:HookScript("OnHide", function()
            TipDrag:Hide()
        end)

        -- Control movement functions
        local void, LTax, LTay, LTbx, LTby, LTcx, LTcy
        TipDrag:SetScript("OnMouseDown", function(self, btn)
            if btn == "LeftButton" then
                void, void, void, LTax, LTay = TipDrag:GetPoint()
                TipDrag:StartMoving()
                --LeaPlusMoveTipMsg:Show()
                void, void, void, LTbx, LTby = TipDrag:GetPoint()

            elseif btn == "RightButton" then
                --LeaPlusMoveTipMsg:Hide();
                if TipDrag:IsShown() then
                    TipDrag:Hide();
                end
            end
        end)
        TipDrag:SetScript("OnMouseUp", function(self, btn)
            if btn == "LeftButton" then
                void, void, void, LTcx, LTcy = TipDrag:GetPoint()
                TipDrag:StopMovingOrSizing();
                LeaPlusLC["TipOffsetX"], LeaPlusLC["TipOffsetY"] = LTcx - LTbx + LTax, LTcy - LTby + LTay
                TipDrag:ClearAllPoints()
                TipDrag:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", LeaPlusLC["TipOffsetX"], LeaPlusLC["TipOffsetY"])
            end
        end)

        --	Move the tooltip
        LeaPlusCB["MoveTooltipButton"]:SetScript("OnClick", function()
            if IsShiftKeyDown() and IsControlKeyDown() then
                -- Preset profile
                LeaPlusLC["TipShowRank"] = "On"
                LeaPlusLC["TipShowOtherRank"] = "Off"
                LeaPlusLC["TipShowTarget"] = "On"
                LeaPlusLC["TipHideInCombat"] = "Off";
                SetTipHideShiftOverrideFunc()
                LeaPlusLC["TipHideShiftOverride"] = "On"
                LeaPlusLC["LeaPlusTipSize"] = 1.25
                LeaPlusLC["TipOffsetX"] = -13
                LeaPlusLC["TipOffsetY"] = 94
                LeaPlusLC["TooltipAnchorMenu"] = 2
                LeaPlusLC["TipCursorX"] = 0
                LeaPlusLC["TipCursorY"] = 0
                TipDrag:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", LeaPlusLC["TipOffsetX"], LeaPlusLC["TipOffsetY"]);
                SetAnchorControls()
                LeaPlusLC:SetTipScale()
                LeaPlusLC:SetDim();
                LeaPlusLC:ReloadCheck()
                SideTip:Show();
                SideTip:Hide(); -- Needed to update tooltip scale
                LeaPlusLC["PageF"]:Hide();
                LeaPlusLC["PageF"]:Show()
            else
                -- Show tooltip configuration panel
                LeaPlusLC:HideFrames()
                SideTip:Show()

                -- Set scale
                TipDrag:SetScale(LeaPlusLC["LeaPlusTipSize"])

                -- Set position of the drag frame
                TipDrag:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", LeaPlusLC["TipOffsetX"], LeaPlusLC["TipOffsetY"])
            end

        end)

        -- Hide health bar
        if LeaPlusLC["TipNoHealthBar"] == "On" then
            local tipHide = GameTooltip.Hide
            GameTooltipStatusBar:HookScript("OnShow", tipHide)
            GameTooltipStatusBar:Hide()
        end

        ---------------------------------------------------------------------------------------------------------
        -- Tooltip scale settings
        ---------------------------------------------------------------------------------------------------------

        -- Function to set the tooltip scale
        local function SetTipScale()

            -- General tooltip
            if GameTooltip then
                GameTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
            end

            -- Friends
            if FriendsTooltip then
                FriendsTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
            end

            -- AutoCompleteBox
            if AutoCompleteBox then
                AutoCompleteBox:SetScale(LeaPlusLC["LeaPlusTipSize"])
            end

            -- Items (links, comparisons)
            if ItemRefTooltip then
                ItemRefTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
            end
            if ItemRefShoppingTooltip1 then
                ItemRefShoppingTooltip1:SetScale(LeaPlusLC["LeaPlusTipSize"])
            end
            if ItemRefShoppingTooltip2 then
                ItemRefShoppingTooltip2:SetScale(LeaPlusLC["LeaPlusTipSize"])
            end
            if ShoppingTooltip1 then
                ShoppingTooltip1:SetScale(LeaPlusLC["LeaPlusTipSize"])
            end
            if ShoppingTooltip2 then
                ShoppingTooltip2:SetScale(LeaPlusLC["LeaPlusTipSize"])
            end

            -- Embedded item tooltip (as used in PVP UI)
            if EmbeddedItemTooltip then
                EmbeddedItemTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
            end

            -- Nameplate tooltip
            if NamePlateTooltip then
                NamePlateTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
            end

            -- Leatrix Plus
            TipDrag:SetScale(LeaPlusLC["LeaPlusTipSize"])

            -- Set slider formatted text
            LeaPlusCB["LeaPlusTipSize"].f:SetFormattedText("%.0f%%", LeaPlusLC["LeaPlusTipSize"] * 100)

        end

        -- Give function a file level scope
        LeaPlusLC.SetTipScale = SetTipScale

        -- Set tooltip scale when slider or checkbox changes and on startup
        LeaPlusCB["LeaPlusTipSize"]:HookScript("OnValueChanged", SetTipScale)
        SetTipScale()

        ---------------------------------------------------------------------------------------------------------
        -- Total RP 3
        ---------------------------------------------------------------------------------------------------------

        -- Total RP 3
        local function TotalRP3Func()
            if TRP3_MainTooltip and TRP3_CharacterTooltip then

                -- Function to set tooltip scale
                local function SetTotalRP3TipScale()
                    TRP3_MainTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
                    TRP3_CharacterTooltip:SetScale(LeaPlusLC["LeaPlusTipSize"])
                end

                -- Set tooltip scale when slider changes and on startup
                LeaPlusCB["LeaPlusTipSize"]:HookScript("OnValueChanged", SetTotalRP3TipScale)
                SetTotalRP3TipScale()

            end
        end

        -- Run function when Total RP 3 addon has loaded
        if IsAddOnLoaded("totalRP3") then
            TotalRP3Func()
        else
            local waitFrame = CreateFrame("FRAME")
            waitFrame:RegisterEvent("ADDON_LOADED")
            waitFrame:SetScript("OnEvent", function(self, event, arg1)
                if arg1 == "totalRP3" then
                    TotalRP3Func()
                    waitFrame:UnregisterAllEvents()
                end
            end)
        end

        ---------------------------------------------------------------------------------------------------------
        -- Other tooltip code
        ---------------------------------------------------------------------------------------------------------

        -- Colorblind setting change
        TipDrag:RegisterEvent("CVAR_UPDATE");
        TipDrag:SetScript("OnEvent", function(self, event, arg1, arg2)
            if (arg1 == "USE_COLORBLIND_MODE") then
                LT["ColorBlind"] = arg2;
            end
        end)

        -- Store locals
        local TipMClass = LOCALIZED_CLASS_NAMES_MALE
        local TipFClass = LOCALIZED_CLASS_NAMES_FEMALE

        -- Level string
        local LevelString, LevelString2
        if GameLocale == "ruRU" then
            -- Level string for ruRU
            LevelString = "уровня"
            LevelString2 = "уровень"
        else
            -- Level string for all other locales
            LevelString = string.lower(TOOLTIP_UNIT_LEVEL:gsub("%%s", ".+"))
            LevelString2 = ""
        end

        -- Tag locale (code construction from tiplang)
        local ttYou, ttLevel, ttBoss, ttElite, ttRare, ttRareElite, ttRareBoss, ttTarget
        if GameLocale == "zhCN" then
            ttYou = "您";
            ttLevel = "等级";
            ttBoss = "首领";
            ttElite = "精英";
            ttRare = "精良";
            ttRareElite = "精良 精英";
            ttRareBoss = "精良 首领";
            ttTarget = "目标"
        elseif GameLocale == "zhTW" then
            ttYou = "您";
            ttLevel = "等級";
            ttBoss = "首領";
            ttElite = "精英";
            ttRare = "精良";
            ttRareElite = "精良 精英";
            ttRareBoss = "精良 首領";
            ttTarget = "目標"
        elseif GameLocale == "ruRU" then
            ttYou = "ВЫ";
            ttLevel = "Уровень";
            ttBoss = "босс";
            ttElite = "элита";
            ttRare = "Редкое";
            ttRareElite = "Редкое элита";
            ttRareBoss = "Редкое босс";
            ttTarget = "Цель"
        elseif GameLocale == "koKR" then
            ttYou = "당신";
            ttLevel = "레벨";
            ttBoss = "우두머리";
            ttElite = "정예";
            ttRare = "희귀";
            ttRareElite = "희귀 정예";
            ttRareBoss = "희귀 우두머리";
            ttTarget = "대상"
        elseif GameLocale == "esMX" then
            ttYou = "TÚ";
            ttLevel = "Nivel";
            ttBoss = "Jefe";
            ttElite = "Élite";
            ttRare = "Raro";
            ttRareElite = "Raro Élite";
            ttRareBoss = "Raro Jefe";
            ttTarget = "Objetivo"
        elseif GameLocale == "ptBR" then
            ttYou = "VOCÊ";
            ttLevel = "Nível";
            ttBoss = "Chefe";
            ttElite = "Elite";
            ttRare = "Raro";
            ttRareElite = "Raro Elite";
            ttRareBoss = "Raro Chefe";
            ttTarget = "Alvo"
        elseif GameLocale == "deDE" then
            ttYou = "SIE";
            ttLevel = "Stufe";
            ttBoss = "Boss";
            ttElite = "Elite";
            ttRare = "Selten";
            ttRareElite = "Selten Elite";
            ttRareBoss = "Selten Boss";
            ttTarget = "Ziel"
        elseif GameLocale == "esES" then
            ttYou = "TÚ";
            ttLevel = "Nivel";
            ttBoss = "Jefe";
            ttElite = "Élite";
            ttRare = "Raro";
            ttRareElite = "Raro Élite";
            ttRareBoss = "Raro Jefe";
            ttTarget = "Objetivo"
        elseif GameLocale == "frFR" then
            ttYou = "TOI";
            ttLevel = "Niveau";
            ttBoss = "Boss";
            ttElite = "Élite";
            ttRare = "Rare";
            ttRareElite = "Rare Élite";
            ttRareBoss = "Rare Boss";
            ttTarget = "Cible"
        elseif GameLocale == "itIT" then
            ttYou = "TU";
            ttLevel = "Livello";
            ttBoss = "Boss";
            ttElite = "Élite";
            ttRare = "Raro";
            ttRareElite = "Raro Élite";
            ttRareBoss = "Raro Boss";
            ttTarget = "Bersaglio"
        else
            ttYou = "YOU";
            ttLevel = "Level";
            ttBoss = "Boss";
            ttElite = "Elite";
            ttRare = "Rare";
            ttRareElite = "Rare Elite";
            ttRareBoss = "Rare Boss";
            ttTarget = "Target"
        end

        -- Show tooltip
        local function ShowTip()

            -- Do nothing if CTRL, SHIFT and ALT are being held
            if IsControlKeyDown() and IsAltKeyDown() and IsShiftKeyDown() then
                return
            end

            -- Get unit information
            if GetMouseFocus() == WorldFrame then
                LT["Unit"] = "mouseover"
                -- Hide and quit if tips should be hidden during combat
                if LeaPlusLC["TipHideInCombat"] == "On" and UnitAffectingCombat("player") then
                    if not IsShiftKeyDown() or LeaPlusLC["TipHideShiftOverride"] == "Off" then
                        GameTooltip:Hide()
                        return
                    end
                end
            else
                LT["Unit"] = select(2, GameTooltip:GetUnit())
                if not (LT["Unit"]) then
                    return
                end
            end

            -- Quit if unit has no reaction to player
            LT["Reaction"] = UnitReaction(LT["Unit"], "player") or nil
            if not LT["Reaction"] then
                return
            end

            -- Setup variables
            LT["TipUnitName"], LT["TipUnitRealm"] = UnitName(LT["Unit"])
            LT["TipIsPlayer"] = UnitIsPlayer(LT["Unit"])
            LT["UnitLevel"] = UnitLevel(LT["Unit"])
            -- LT["UnitClass"] = UnitClassBase(LT["Unit"])
            local _, TipUnitClass = UnitClassBase(LT["Unit"])
            LT["PlayerControl"] = UnitPlayerControlled(LT["Unit"])
            LT["PlayerRace"] = UnitRace(LT["Unit"])

            -- Get guild information
            if LT["TipIsPlayer"] then
                local unitGuild, unitRank = GetGuildInfo(LT["Unit"])
                if unitGuild and unitRank then
                    -- Unit is guilded
                    if LT["ColorBlind"] == "1" then
                        LT["GuildLine"], LT["InfoLine"] = 2, 4
                    else
                        LT["GuildLine"], LT["InfoLine"] = 2, 3
                    end
                    LT["GuildName"], LT["GuildRank"] = unitGuild, unitRank
                else
                    -- Unit is not guilded
                    LT["GuildName"] = nil
                    if LT["ColorBlind"] == "1" then
                        LT["GuildLine"], LT["InfoLine"] = 0, 3
                    else
                        LT["GuildLine"], LT["InfoLine"] = 0, 2
                    end
                end
                -- Lower information line if unit is charmed
                if UnitIsCharmed(LT["Unit"]) then
                    LT["InfoLine"] = LT["InfoLine"] + 1
                end
            end

            if TipUnitClass then
                -- print("LT['UnitClass']:", LT['UnitClass'])

                LT["Sex"] = UnitSex(LT["Unit"])
                -- print("LT['Sex']:", LT['Sex'])

                if LT["Sex"] == 2 then
                    LT["Class"] = TipMClass[TipUnitClass]
                else
                    LT["Class"] = TipFClass[TipUnitClass]
                end
                -- print(TipUnitClass)




                LT["ClassCol"] = LeaPlusLC["RaidColors"][TipUnitClass]
                -- print(LeaPlusLC["RaidColors"])
                -- print(LT["ClassCol"])

                if LT["ClassCol"] then
                    LT["LpTipClassColor"] = "|cff" .. string.format("%02x%02x%02x", LT["ClassCol"].r * 255, LT["ClassCol"].g * 255, LT["ClassCol"].b * 255)
                else
                    -- print("No raid color defined for class:", TipUnitClass)
                end
            end





            ----------------------------------------------------------------------
            -- Name line
            ----------------------------------------------------------------------

            if ((LT["TipIsPlayer"]) or (LT["PlayerControl"])) or LT["Reaction"] > 4 then

                -- If it's a player show name in class color
                if LT["TipIsPlayer"] then
                    LT["NameColor"] = LT["LpTipClassColor"]
                else
                    -- If not, set to green or blue depending on PvP status
                    if UnitIsPVP(LT["Unit"]) then
                        LT["NameColor"] = "|cff00ff00"
                    else
                        LT["NameColor"] = "|cff00aaff"
                    end
                end

                -- Show name
                LT["NameText"] = UnitPVPName(LT["Unit"]) or LT["TipUnitName"]

                -- Show realm
                if LT["TipUnitRealm"] then
                    LT["NameText"] = LT["NameText"] .. " - " .. LT["TipUnitRealm"]
                end

                -- Show dead units in grey
                if UnitIsDeadOrGhost(LT["Unit"]) then
                    LT["NameColor"] = "|c88888888"
                end

                -- Show name line
                _G["GameTooltipTextLeft1"]:SetText(LT["NameColor"] .. LT["NameText"] .. "|cffffffff|r")

            elseif UnitIsDeadOrGhost(LT["Unit"]) then

                -- Show grey name for other dead units
                _G["GameTooltipTextLeft1"]:SetText("|c88888888" .. (_G["GameTooltipTextLeft1"]:GetText() or "") .. "|cffffffff|r")
                return

            end

            ----------------------------------------------------------------------
            -- Guild line
            ----------------------------------------------------------------------

            if LT["TipIsPlayer"] and LT["GuildName"] then

                -- Show guild line
                if UnitIsInMyGuild(LT["Unit"]) then
                    if LeaPlusLC["TipShowRank"] == "On" then
                        _G["GameTooltipTextLeft" .. LT["GuildLine"]]:SetText("|c00aaaaff" .. LT["GuildName"] .. " - " .. LT["GuildRank"] .. "|r")
                    else
                        _G["GameTooltipTextLeft" .. LT["GuildLine"]]:SetText("|c00aaaaff" .. LT["GuildName"] .. "|cffffffff|r")
                    end
                else
                    if LeaPlusLC["TipShowOtherRank"] == "On" then
                        _G["GameTooltipTextLeft" .. LT["GuildLine"]]:SetText("|c00aaaaff" .. LT["GuildName"] .. " - " .. LT["GuildRank"] .. "|r")
                    else
                        _G["GameTooltipTextLeft" .. LT["GuildLine"]]:SetText("|c00aaaaff" .. LT["GuildName"] .. "|cffffffff|r")
                    end
                end

            end

            ----------------------------------------------------------------------
            -- Information line (level, class, race)
            ----------------------------------------------------------------------

            if LT["TipIsPlayer"] then

                if GameLocale == "ruRU" then

                    LT["InfoText"] = ""

                    -- Show race
                    if LT["PlayerRace"] then
                        LT["InfoText"] = LT["InfoText"] .. LT["PlayerRace"] .. ","
                    end

                    -- Show class
                    LT["InfoText"] = LT["InfoText"] .. " " .. LT["LpTipClassColor"] .. LT["Class"] .. "|r " or LT["InfoText"] .. "|r "

                    -- Show level
                    if LT["Reaction"] < 5 then
                        if LT["UnitLevel"] == -1 then
                            LT["InfoText"] = LT["InfoText"] .. ("|cffff3333" .. "??-ro" .. " " .. ttLevel .. "|cffffffff")
                        else
                            -- LT["LevelColor"] = GetCreatureDifficultyColor(LT["UnitLevel"])
                            LT["LevelColor"] = GetQuestDifficultyColor(LT["UnitLevel"])
                            -- (GetQuestDifficultyColor(UnitLevel(LeaPlusTT["LpTipUnitTarget"])))
                            LT["LevelColor"] = string.format('%02x%02x%02x', LT["LevelColor"].r * 255, LT["LevelColor"].g * 255, LT["LevelColor"].b * 255)
                            LT["InfoText"] = LT["InfoText"] .. ("|cff" .. LT["LevelColor"] .. LT["UnitLevel"] .. LT["LevelLocale"] .. "|cffffffff")
                        end
                    else
                        LT["InfoText"] = LT["InfoText"] .. LT["UnitLevel"] .. LT["LevelLocale"]
                    end

                    -- Show information line
                    _G["GameTooltipTextLeft" .. LT["InfoLine"]]:SetText(LT["InfoText"] .. "|cffffffff|r")

                else

                    -- Show level
                    if LT["Reaction"] < 5 then
                        if LT["UnitLevel"] == -1 then
                            LT["InfoText"] = ("|cffff3333" .. ttLevel .. " ??|cffffffff")
                        else
                            LT["LevelColor"] = GetQuestDifficultyColor(LT["UnitLevel"])
                            LT["LevelColor"] = string.format('%02x%02x%02x', LT["LevelColor"].r * 255, LT["LevelColor"].g * 255, LT["LevelColor"].b * 255)
                            LT["InfoText"] = ("|cff" .. LT["LevelColor"] .. LT["LevelLocale"] .. " " .. LT["UnitLevel"] .. "|cffffffff")
                        end
                    else
                        LT["InfoText"] = LT["LevelLocale"] .. " " .. LT["UnitLevel"]
                    end

                    -- Show race
                    if LT["PlayerRace"] then
                        LT["InfoText"] = LT["InfoText"] .. " " .. LT["PlayerRace"]
                    end

                    -- Show class
                    LT["InfoText"] = LT["InfoText"] .. " " .. LT["LpTipClassColor"] .. LT["Class"] or LT["InfoText"]

                    -- Show information line
                    _G["GameTooltipTextLeft" .. LT["InfoLine"]]:SetText(LT["InfoText"] .. "|cffffffff|r")

                end

            end

            ----------------------------------------------------------------------
            -- Mob name in brighter red (alive) and steel blue (tap denied)
            ----------------------------------------------------------------------

            if not (LT["TipIsPlayer"]) and LT["Reaction"] < 4 and not (LT["PlayerControl"]) then
                if UnitIsTapped(LT["Unit"]) then
                    LT["NameText"] = "|c8888bbbb" .. LT["TipUnitName"] .. "|r"
                else
                    LT["NameText"] = "|cffff3333" .. LT["TipUnitName"] .. "|r"
                end
                _G["GameTooltipTextLeft1"]:SetText(LT["NameText"])
            end

            ----------------------------------------------------------------------
            -- Mob level in color (neutral or lower)
            ----------------------------------------------------------------------

            if UnitCanAttack(LT["Unit"], "player") and not (LT["TipIsPlayer"]) and LT["Reaction"] < 5 and not (LT["PlayerControl"]) then

                -- Find the level line
                LT["MobInfoLine"] = 0
                local line2, line3, line4
                if _G["GameTooltipTextLeft2"] then
                    line2 = _G["GameTooltipTextLeft2"]:GetText()
                end
                if _G["GameTooltipTextLeft3"] then
                    line3 = _G["GameTooltipTextLeft3"]:GetText()
                end
                if _G["GameTooltipTextLeft4"] then
                    line4 = _G["GameTooltipTextLeft4"]:GetText()
                end
                if GameLocale == "ruRU" then
                    -- Additional check for ruRU
                    if line2 and string.lower(line2):find(LevelString2) then
                        LT["MobInfoLine"] = 2
                    end
                    if line3 and string.lower(line3):find(LevelString2) then
                        LT["MobInfoLine"] = 3
                    end
                    if line4 and string.lower(line4):find(LevelString2) then
                        LT["MobInfoLine"] = 4
                    end
                end
                if line2 and string.lower(line2):find(LevelString) then
                    LT["MobInfoLine"] = 2
                end
                if line3 and string.lower(line3):find(LevelString) then
                    LT["MobInfoLine"] = 3
                end
                if line4 and string.lower(line4):find(LevelString) then
                    LT["MobInfoLine"] = 4
                end

                -- Show level line
                if LT["MobInfoLine"] > 1 then

                    if GameLocale == "ruRU" then

                        LT["InfoText"] = ""

                        -- Show creature type and classification
                        LT["CreatureType"] = UnitCreatureType(LT["Unit"])
                        if (LT["CreatureType"]) and not (LT["CreatureType"] == "Not specified") then
                            LT["InfoText"] = LT["InfoText"] .. "|cffffffff" .. LT["CreatureType"] .. "|cffffffff "
                        end

                        -- Level ?? mob
                        if LT["UnitLevel"] == -1 then
                            LT["InfoText"] = LT["InfoText"] .. "|cffff3333" .. "??-ro " .. ttLevel .. "|cffffffff "

                            -- Mobs within level range
                        else
                            LT["MobColor"] = GetQuestDifficultyColor(LT["UnitLevel"])
                            LT["MobColor"] = string.format('%02x%02x%02x', LT["MobColor"].r * 255, LT["MobColor"].g * 255, LT["MobColor"].b * 255)
                            LT["InfoText"] = LT["InfoText"] .. "|cff" .. LT["MobColor"] .. LT["UnitLevel"] .. LT["LevelLocale"] .. "|cffffffff "
                        end

                    else

                        -- Level ?? mob
                        if LT["UnitLevel"] == -1 then
                            LT["InfoText"] = "|cffff3333" .. ttLevel .. " ??|cffffffff "

                            -- Mobs within level range
                        else
                            LT["MobColor"] = GetQuestDifficultyColor(LT["UnitLevel"])
                            LT["MobColor"] = string.format('%02x%02x%02x', LT["MobColor"].r * 255, LT["MobColor"].g * 255, LT["MobColor"].b * 255)
                            LT["InfoText"] = "|cff" .. LT["MobColor"] .. LT["LevelLocale"] .. " " .. LT["UnitLevel"] .. "|cffffffff "
                        end

                        -- Show creature type and classification
                        LT["CreatureType"] = UnitCreatureType(LT["Unit"])
                        if (LT["CreatureType"]) and not (LT["CreatureType"] == "Not specified") then
                            LT["InfoText"] = LT["InfoText"] .. "|cffffffff" .. LT["CreatureType"] .. "|cffffffff "
                        end

                    end

                    -- Rare, elite and boss mobs
                    LT["Special"] = UnitClassification(LT["Unit"])
                    if LT["Special"] then
                        if LT["Special"] == "elite" then
                            if strfind(_G["GameTooltipTextLeft" .. LT["MobInfoLine"]]:GetText(), "(" .. ttBoss .. ")") then
                                LT["Special"] = "(" .. ttBoss .. ")"
                            else
                                LT["Special"] = "(" .. ttElite .. ")"
                            end
                        elseif LT["Special"] == "rare" then
                            LT["Special"] = "|c00e066ff(" .. ttRare .. ")"
                        elseif LT["Special"] == "rareelite" then
                            if strfind(_G["GameTooltipTextLeft" .. LT["MobInfoLine"]]:GetText(), "(" .. ttBoss .. ")") then
                                LT["Special"] = "|c00e066ff(" .. ttRareBoss .. ")"
                            else
                                LT["Special"] = "|c00e066ff(" .. ttRareElite .. ")"
                            end
                        elseif LT["Special"] == "worldboss" then
                            LT["Special"] = "(" .. ttBoss .. ")"
                        elseif LT["UnitLevel"] == -1 and LT["Special"] == "normal" and strfind(_G["GameTooltipTextLeft" .. LT["MobInfoLine"]]:GetText(), "(" .. ttBoss .. ")") then
                            LT["Special"] = "(" .. ttBoss .. ")"
                        else
                            LT["Special"] = nil
                        end

                        if (LT["Special"]) then
                            LT["InfoText"] = LT["InfoText"] .. LT["Special"]
                        end
                    end

                    -- Show mob info line
                    _G["GameTooltipTextLeft" .. LT["MobInfoLine"]]:SetText(LT["InfoText"])

                end

            end

            ----------------------------------------------------------------------
            --	Show target
            ----------------------------------------------------------------------

            if LeaPlusLC["TipShowTarget"] == "On" then

                -- Get target
                LT["Target"] = UnitName(LT["Unit"] .. "target");

                -- If target doesn't exist, quit
                if LT["Target"] == nil or LT["Target"] == "" then
                    return
                end

                -- If target is you, set target to YOU
                if (UnitIsUnit(LT["Target"], "player")) then
                    LT["Target"] = ("|c12ff4400" .. ttYou)

                    -- If it's not you, but it's a player, show target in class color
                elseif UnitIsPlayer(LT["Unit"] .. "target") then
                    -- LT["TargetBase"] = UnitClassBase(LT["Unit"] .. "target")
                    local _, TargetBase = UnitClassBase(LT["Unit"] .. "target")
                    LT["TargetCol"] = LeaPlusLC["RaidColors"][TargetBase]
                    LT["TargetCol"] = "|cff" .. string.format('%02x%02x%02x', LT["TargetCol"].r * 255, LT["TargetCol"].g * 255, LT["TargetCol"].b * 255)
                    LT["Target"] = (LT["TargetCol"] .. LT["Target"])

                end

                -- Add target line
                GameTooltip:AddLine(ttTarget .. ": " .. LT["Target"])

            end

        end

        GameTooltip:HookScript("OnTooltipSetUnit", ShowTip)

    end

    ----------------------------------------------------------------------
    --	Move chat editbox to top
    ----------------------------------------------------------------------

    if LeaPlusLC["MoveChatEditBoxToTop"] == "On" and not LeaLockList["MoveChatEditBoxToTop"] then

        -- Set options for normal chat frames
        for i = 1, 50 do
            if _G["ChatFrame" .. i] then
                -- Position the editbox
                _G["ChatFrame" .. i .. "EditBox"]:ClearAllPoints();
                _G["ChatFrame" .. i .. "EditBox"]:SetPoint("TOPLEFT", _G["ChatFrame" .. i], 0, 0);
                _G["ChatFrame" .. i .. "EditBox"]:SetWidth(_G["ChatFrame" .. i]:GetWidth());
                -- Ensure editbox width matches chatframe width
                _G["ChatFrame" .. i]:HookScript("OnSizeChanged", function()
                    _G["ChatFrame" .. i .. "EditBox"]:SetWidth(_G["ChatFrame" .. i]:GetWidth())
                end)
            end
        end

        -- Do the functions above for other chat frames (pet battles, whispers, etc)
        hooksecurefunc("FCF_OpenTemporaryWindow", function()

            local cf = FCF_GetCurrentChatFrame():GetName() or nil
            if cf then

                -- Position the editbox
                _G[cf .. "EditBox"]:ClearAllPoints();
                _G[cf .. "EditBox"]:SetPoint("TOPLEFT", cf, "TOPLEFT", 0, 0);
                _G[cf .. "EditBox"]:SetWidth(_G[cf]:GetWidth());

                -- Ensure editbox width matches chatframe width
                _G[cf]:HookScript("OnSizeChanged", function()
                    _G[cf .. "EditBox"]:SetWidth(_G[cf]:GetWidth())
                end)

            end
        end)

    end

    ----------------------------------------------------------------------
    -- Viewport
    ----------------------------------------------------------------------

    if LeaPlusLC["ViewPortEnable"] == "On" then

        -- Create border textures
        local BordTop = WorldFrame:CreateTexture(nil, "ARTWORK");
        BordTop:SetVertexColor(0, 0, 0, 1);
        BordTop:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0);
        BordTop:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
        local BordBot = WorldFrame:CreateTexture(nil, "ARTWORK");
        BordBot:SetVertexColor(0, 0, 0, 1);
        BordBot:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0);
        BordBot:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
        local BordLeft = WorldFrame:CreateTexture(nil, "ARTWORK");
        BordLeft:SetVertexColor(0, 0, 0, 1);
        BordLeft:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0);
        BordLeft:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
        local BordRight = WorldFrame:CreateTexture(nil, "ARTWORK");
        BordRight:SetVertexColor(0, 0, 0, 1);
        BordRight:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0);
        BordRight:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)

        -- Create viewport configuration panel
        local SideViewport = LeaPlusLC:CreatePanel("Enable viewport", "SideViewport")

        -- Create resize screen button
        local resizeScreenBtn = LeaPlusLC:CreateButton("resizeScreenBtn", SideViewport, "Resize Screen", "BOTTOMRIGHT", -16, 10, 0, 25, true, "Click to resize the screen to fit between the top and bottom borders.")
        resizeScreenBtn:ClearAllPoints()
        resizeScreenBtn:SetPoint("LEFT", SideViewport.h, "RIGHT", 10, 0)
        resizeScreenBtn:SetScript("OnClick", function()
            LeaPlusLC["ViewPortResizeTop"] = LeaPlusLC["ViewPortTop"]
            LeaPlusLC["ViewPortResizeBottom"] = LeaPlusLC["ViewPortBottom"]
            WorldFrame:SetPoint("TOPLEFT", 0, -LeaPlusLC["ViewPortResizeTop"])
            WorldFrame:SetPoint("BOTTOMRIGHT", 0, LeaPlusLC["ViewPortResizeBottom"])
            -- Disable lock button if borders match viewport size
            if LeaPlusLC["ViewPortTop"] == LeaPlusLC["ViewPortResizeTop"] and LeaPlusLC["ViewPortBottom"] == LeaPlusLC["ViewPortResizeBottom"] then
                LeaPlusLC:LockItem(resizeScreenBtn, true)
            else
                LeaPlusLC:LockItem(resizeScreenBtn, false)
            end
        end)

        -- Function to set viewport parameters
        local function RefreshViewport()

            -- Set border size and transparency
            BordTop:SetHeight(LeaPlusLC["ViewPortTop"]);
            BordTop:SetAlpha(1 - LeaPlusLC["ViewPortAlpha"])
            BordBot:SetHeight(LeaPlusLC["ViewPortBottom"]);
            BordBot:SetAlpha(1 - LeaPlusLC["ViewPortAlpha"])
            BordLeft:SetWidth(LeaPlusLC["ViewPortLeft"]);
            BordLeft:SetAlpha(1 - LeaPlusLC["ViewPortAlpha"])
            BordRight:SetWidth(LeaPlusLC["ViewPortRight"]);
            BordRight:SetAlpha(1 - LeaPlusLC["ViewPortAlpha"])

            ---- Show formatted slider value
            --LeaPlusCB["ViewPortAlpha"].f:SetFormattedText("%.0f%%", LeaPlusLC["ViewPortAlpha"] * 100)

            -- Disable lock button if borders match viewport size
            if LeaPlusLC["ViewPortTop"] == LeaPlusLC["ViewPortResizeTop"] and LeaPlusLC["ViewPortBottom"] == LeaPlusLC["ViewPortResizeBottom"] then
                LeaPlusLC:LockItem(resizeScreenBtn, true)
            else
                LeaPlusLC:LockItem(resizeScreenBtn, false)
            end

        end

        -- Create slider controls
        LeaPlusLC:MakeTx(SideViewport, "Top", 16, -72)
        LeaPlusLC:MakeSL(SideViewport, "ViewPortTop", "Drag to set the size of the top border.", 0, 300, 5, 16, -92, "%.0f")
        LeaPlusCB["ViewPortTop"]:HookScript("OnValueChanged", RefreshViewport)

        LeaPlusLC:MakeTx(SideViewport, "Bottom", 16, -132)
        LeaPlusLC:MakeSL(SideViewport, "ViewPortBottom", "Drag to set the size of the bottom border.", 0, 300, 5, 16, -152, "%.0f")
        LeaPlusCB["ViewPortBottom"]:HookScript("OnValueChanged", RefreshViewport)

        --LeaPlusLC:MakeTx(SideViewport, "Left", 186, -72)
        --LeaPlusLC:MakeSL(SideViewport, "ViewPortLeft", "Drag to set the size of the left border.", 0, 300, 5, 186, -92, "%.0f")
        --LeaPlusCB["ViewPortLeft"]:HookScript("OnValueChanged", RefreshViewport)
        --
        --LeaPlusLC:MakeTx(SideViewport, "Right", 186, -132)
        --LeaPlusLC:MakeSL(SideViewport, "ViewPortRight", "Drag to set the size of the right border.", 0, 300, 5, 186, -152, "%.0f")
        --LeaPlusCB["ViewPortRight"]:HookScript("OnValueChanged", RefreshViewport)
        --
        --LeaPlusLC:MakeTx(SideViewport, "Transparency", 356, -132)
        --LeaPlusLC:MakeSL(SideViewport, "ViewPortAlpha", "Drag to set the transparency of the borders.", 0, 0.9, 0.1, 356, -152, "%.1f")
        --LeaPlusCB["ViewPortAlpha"]:HookScript("OnValueChanged", RefreshViewport)

        -- Help button tooltip
        SideViewport.h.tiptext = L["This panel will close automatically if you enter combat."]

        -- Back button handler
        SideViewport.b:SetScript("OnClick", function()
            SideViewport:Hide()
            LeaPlusLC["PageF"]:Show()
            LeaPlusLC["Page7"]:Show()
            return
        end)

        -- Reset button handler
        SideViewport.r:SetScript("OnClick", function()
            LeaPlusLC["ViewPortTop"] = 0
            LeaPlusLC["ViewPortBottom"] = 0
            LeaPlusLC["ViewPortLeft"] = 0
            LeaPlusLC["ViewPortRight"] = 0
            LeaPlusLC["ViewPortResizeTop"] = 0
            LeaPlusLC["ViewPortResizeBottom"] = 0
            LeaPlusLC["ViewPortAlpha"] = 0
            SideViewport:Hide();
            SideViewport:Show()
            RefreshViewport()
            WorldFrame:SetPoint("TOPLEFT", 0, -LeaPlusLC["ViewPortResizeTop"])
            WorldFrame:SetPoint("BOTTOMRIGHT", 0, LeaPlusLC["ViewPortResizeBottom"])
        end)

        -- Configuration button handler
        LeaPlusCB["ModViewportBtn"]:SetScript("OnClick", function()
            if LeaPlusLC:PlayerInCombat() then
                return
            else
                if IsShiftKeyDown() and IsControlKeyDown() then
                    -- Preset profile
                    LeaPlusLC["ViewPortTop"] = 0
                    LeaPlusLC["ViewPortBottom"] = 0
                    LeaPlusLC["ViewPortLeft"] = 0
                    LeaPlusLC["ViewPortRight"] = 0
                    LeaPlusLC["ViewPortResizeTop"] = 0
                    LeaPlusLC["ViewPortResizeBottom"] = 0
                    LeaPlusLC["ViewPortAlpha"] = 0.7
                    RefreshViewport()
                    WorldFrame:SetPoint("TOPLEFT", 0, -LeaPlusLC["ViewPortResizeTop"])
                    WorldFrame:SetPoint("BOTTOMRIGHT", 0, LeaPlusLC["ViewPortResizeBottom"])
                else
                    SideViewport:Show()
                    LeaPlusLC:HideFrames()
                end
            end
        end)

        -- Set viewport on startup
        RefreshViewport()
        WorldFrame:SetPoint("TOPLEFT", 0, -LeaPlusLC["ViewPortResizeTop"])
        WorldFrame:SetPoint("BOTTOMRIGHT", 0, LeaPlusLC["ViewPortResizeBottom"])

        -- Hide the configuration panel if combat starts
        SideViewport:SetScript("OnUpdate", function()
            if UnitAffectingCombat("player") then
                SideViewport:Hide()
            end
        end)

        -- Hide borders when cinematic is shown
        hooksecurefunc(CinematicFrame, "Hide", function()
            BordTop:Show();
            BordBot:Show();
            BordLeft:Show();
            BordRight:Show()
        end)
        hooksecurefunc(CinematicFrame, "Show", function()
            BordTop:Hide();
            BordBot:Hide();
            BordLeft:Hide();
            BordRight:Hide()
        end)

    end

    ----------------------------------------------------------------------
    -- Silence rested emotes
    ----------------------------------------------------------------------

    -- Manage emotes
    if LeaPlusLC["NoRestedEmotes"] == "On" then

        -- Zone table 		English					, French					, German					, Italian						, Russian					, S Chinese	, Spanish					, T Chinese	,
        local zonetable = { "The Grim Guzzler", "Le Sinistre écluseur", "Zum Grimmigen Säufer", "Torvo Beone", "Трактир Угрюмый обжора", "黑铁酒吧", "Tragapenas", "黑鐵酒吧", }

        -- Function to set rested state
        local function UpdateEmoteSound()

            -- Find character's current zone
            local szone = GetSubZoneText() or "None"

            -- Find out if emote sounds are disabled or enabled
            local emoset = GetCVar("Sound_EnableEmoteSounds")

            if IsResting() then
                -- Character is resting so silence emotes
                if emoset ~= "0" then
                    SetCVar("Sound_EnableEmoteSounds", "0")
                end
                return
            end

            -- Traverse zone table and silence emotes if character is in a designated zone
            for k, v in next, zonetable do
                if szone == zonetable[k] then
                    if emoset ~= "0" then
                        SetCVar("Sound_EnableEmoteSounds", "0")
                    end
                    return
                end
            end

            -- If the above didn't return, emote sounds should be enabled
            if emoset ~= "1" then
                SetCVar("Sound_EnableEmoteSounds", "1")
            end
            return

        end

        -- Set emote sound when rest state or zone changes
        local RestEvent = CreateFrame("FRAME")
        RestEvent:RegisterEvent("PLAYER_UPDATE_RESTING")
        RestEvent:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        RestEvent:RegisterEvent("ZONE_CHANGED")
        RestEvent:RegisterEvent("ZONE_CHANGED_INDOORS")
        RestEvent:SetScript("OnEvent", UpdateEmoteSound)

        -- Set sound setting at startup
        UpdateEmoteSound()

    end

    ----------------------------------------------------------------------
    -- Create panel in game options panel
    ----------------------------------------------------------------------

    do

        local interPanel = CreateFrame("FRAME")
        interPanel.name = "Leatrix Plus"

        local maintitle = LeaPlusLC:MakeTx(interPanel, "Leatrix Plus", 0, 0)
        maintitle:SetFont(maintitle:GetFont(), 72)
        maintitle:ClearAllPoints()
        maintitle:SetPoint("TOP", 0, -72)

        local expTitle = LeaPlusLC:MakeTx(interPanel, "Wrath of the Lich King 3.3.5", 0, 0)
        expTitle:SetFont(expTitle:GetFont(), 32)
        expTitle:ClearAllPoints()
        expTitle:SetPoint("TOP", 0, -152)

        local subTitle = LeaPlusLC:MakeTx(interPanel, "Feedback Discord: sattva108", 0, 0)
        subTitle:SetFont(subTitle:GetFont(), 20)
        subTitle:ClearAllPoints()
        subTitle:SetPoint("BOTTOM", 0, 72)

        local slashTitle = LeaPlusLC:MakeTx(interPanel, "/ltp help", 0, 0)
        slashTitle:SetFont(slashTitle:GetFont(), 72)
        slashTitle:ClearAllPoints()
        slashTitle:SetPoint("BOTTOM", subTitle, "TOP", 0, 40)

        local pTex = interPanel:CreateTexture(nil, "BACKGROUND")
        pTex:SetAllPoints()
        pTex:SetTexture("Interface\\GLUES\\Models\\UI_MainMenu\\swordgradient2")
        pTex:SetAlpha(0.2)
        pTex:SetTexCoord(0, 1, 1, 0)

        InterfaceOptions_AddCategory(interPanel)

    end

    ----------------------------------------------------------------------
    -- Final code for Player
    ----------------------------------------------------------------------

    -- Show first run message
    if not LeaPlusDB["FirstRunMessageSeen"] then
        LibCompat.After(1, function()
            LeaPlusLC:Print(L["Enter"] .. " |cff00ff00" .. "/ltp" .. "|r " .. L["or click the minimap button to open Leatrix Plus."])
            LeaPlusDB["FirstRunMessageSeen"] = true
        end)
    end

    -- Register logout event to save settings
    LpEvt:RegisterEvent("PLAYER_LOGOUT")

    -- Release memory
    LeaPlusLC.Player = nil

end

----------------------------------------------------------------------
--	L45: World
----------------------------------------------------------------------

function LeaPlusLC:World()

    ----------------------------------------------------------------------
    --	Max camera zoom (no reload required)
    ----------------------------------------------------------------------

    do

        -- Function to set camera zoom
        local function SetZoom()
            if LeaPlusLC["MaxCameraZoom"] == "On" then
                SetCVar("cameraDistanceMaxFactor", 4.0)
            else
                SetCVar("cameraDistanceMaxFactor", 1.9)
            end
        end

        -- Set camera zoom when option is clicked and on startup (if enabled)
        LeaPlusCB["MaxCameraZoom"]:HookScript("OnClick", SetZoom)
        if LeaPlusLC["MaxCameraZoom"] == "On" then
            SetZoom()
        end

    end

end

----------------------------------------------------------------------
-- 	L50: RunOnce
----------------------------------------------------------------------

function LeaPlusLC:RunOnce()

    ----------------------------------------------------------------------
    -- Frame alignment grid
    ----------------------------------------------------------------------

    do

        -- Create frame alignment grid
        local grid = CreateFrame('FRAME')
        LeaPlusLC.grid = grid
        grid:Hide()
        grid:SetAllPoints(UIParent)
        local w, h = GetScreenWidth() * UIParent:GetEffectiveScale(), GetScreenHeight() * UIParent:GetEffectiveScale()
        local ratio = w / h
        local sqsize = w / 20
        local wline = floor(sqsize - (sqsize % 2))
        local hline = floor(sqsize / ratio - ((sqsize / ratio) % 2))
        -- Plot vertical lines
        for i = 0, wline do
            local t = LeaPlusLC.grid:CreateTexture(nil, 'BACKGROUND')
            if i == wline / 2 then
                t:SetTexture(1, 0, 0, 0.5)
            else
                t:SetTexture(0, 0, 0, 0.5)
            end
            t:SetPoint('TOPLEFT', grid, 'TOPLEFT', i * w / wline - 1, 0)
            t:SetPoint('BOTTOMRIGHT', grid, 'BOTTOMLEFT', i * w / wline + 1, 0)
        end
        -- Plot horizontal lines
        for i = 0, hline do
            local t = LeaPlusLC.grid:CreateTexture(nil, 'BACKGROUND')
            if i == hline / 2 then
                t:SetTexture(1, 0, 0, 0.5)
            else
                t:SetTexture(0, 0, 0, 0.5)
            end
            t:SetPoint('TOPLEFT', grid, 'TOPLEFT', 0, -i * h / hline + 1)
            t:SetPoint('BOTTOMRIGHT', grid, 'TOPRIGHT', 0, -i * h / hline - 1)
        end

    end

    ----------------------------------------------------------------------
    -- Media player
    ----------------------------------------------------------------------

    function LeaPlusLC:MediaFunc()

        -- Create tables for list data and zone listing
        local ListData, playlist = {}, {}
        local scrollFrame, willPlay, musicHandle, ZonePage, LastPlayed, LastFolder, TempFolder, HeadingOfClickedTrack, LastMusicHandle
        local numButtons = 15
        local uframe = CreateFrame("FRAME")

        -- These categories will not appear in random track selections
        local randomBannedList = { L["Narration"], L["Cinematics"] }

        -- Get media table
        local ZoneList = Leatrix_Plus["ZoneList"]

        -- Show relevant list items
        local function UpdateList()
            FauxScrollFrame_Update(scrollFrame, #ListData, numButtons, 16)
            for index = 1, numButtons do
                local offset = index + FauxScrollFrame_GetOffset(scrollFrame)
                local button = scrollFrame.buttons[index]
                button.index = offset
                if offset <= #ListData then
                    -- Show zone listing or track listing
                    button:SetText(ListData[offset].zone or ListData[offset])
                    -- Set width of highlight texture
                    if button:GetTextWidth() > 290 then
                        button.t:SetSize(290, 16)
                    else
                        button.t:SetSize(button:GetTextWidth(), 16)
                    end
                    -- Show the button
                    button:Show()
                    -- Hide highlight bar texture by default
                    button.s:Hide()
                    -- Hide highlight bar if the button is a heading
                    if strfind(button:GetText(), "|c") then
                        button.t:Hide()
                    end
                    -- Show last played track highlight bar texture
                    if LastPlayed == button:GetText() then
                        local HeadingOfCurrentFolder = ListData[1]
                        if HeadingOfCurrentFolder == HeadingOfClickedTrack then
                            button.s:Show()
                        end
                    end
                    -- Show last played folder highlight bar texture
                    if LastFolder == button:GetText() then
                        button.s:Show()
                    end
                    -- Set width of highlight bar
                    if button:GetTextWidth() > 290 then
                        button.s:SetSize(290, 16)
                    else
                        button.s:SetSize(button:GetTextWidth(), 16)
                    end
                    -- Limit click to label width
                    local bWidth = button:GetFontString():GetStringWidth() or 0
                    if bWidth > 290 then
                        bWidth = 290
                    end
                    button:SetHitRectInsets(0, 454 - bWidth, 0, 0)
                    -- Disable label click movement
                    button:SetPushedTextOffset(0, 0)
                    -- Disable word wrap and set width
                    button:GetFontString():SetWidth(290)
                    button:GetFontString():SetWordWrap(false)
                else
                    button:Hide()
                end
            end
        end

        -- Give function file level scope (it's used in SetPlusScale to set the highlight bar scale)
        LeaPlusLC.UpdateList = UpdateList

        -- Right-button click to go back
        local function BackClick()
            -- Return to the current zone list (back button)
            if type(ListData[1]) == "string" then
                -- Strip the color code from the list data
                local nocol = string.gsub(ListData[1], "|cffffd800", "")
                -- Strip the zone
                local backzone = strsplit(":", nocol, 2)
                -- Don't go back if random or search category is being shown
                if backzone == L["Random"] or backzone == L["Search"] then
                    return
                end
                -- Show the tracklist continent
                if ZoneList[backzone] then
                    ListData = ZoneList[backzone]
                end
                UpdateList()
                scrollFrame:SetVerticalScroll(ZonePage or 0)
            end
        end

        -- Function to make navigation menu buttons
        local function MakeButton(where, y)
            local mbtn = CreateFrame("Button", nil, LeaPlusLC["Page9"])
            mbtn:Show()
            mbtn:SetAlpha(1.0)
            mbtn:SetPoint("TOPLEFT", 146, y)

            -- Create hover texture
            mbtn.t = mbtn:CreateTexture(nil, "BACKGROUND")
            mbtn.t:SetTexture(0.3, 0.3, 0.00, 0.8)
            mbtn.t:SetAlpha(0.7)
            mbtn.t:SetAllPoints()
            mbtn.t:Hide()

            -- Create highlight texture
            mbtn.s = mbtn:CreateTexture(nil, "BACKGROUND")
            mbtn.s:SetTexture(0.3, 0.3, 0.00, 0.8)
            mbtn.s:SetAlpha(1.0)
            mbtn.s:SetAllPoints()
            mbtn.s:Hide()

            -- Create fontstring
            mbtn.f = mbtn:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
            mbtn.f:SetPoint('LEFT', 1, 0)
            mbtn.f:SetText(L[where])

            mbtn:SetScript("OnEnter", function()
                mbtn.t:Show()
            end)

            mbtn:SetScript("OnLeave", function()
                mbtn.t:Hide()
            end)

            -- Set button size when shown
            mbtn:SetScript("OnShow", function()
                mbtn:SetSize(mbtn.f:GetStringWidth() + 1, 16)
            end)

            mbtn:SetScript("OnClick", function()
                -- Show zone listing for clicked item
                ListData = ZoneList[where]
                UpdateList()
            end)

            return mbtn, mbtn.s

        end

        -- Create a table for each button
        local conbtn = {}
        for q, w in pairs(ZoneList) do
            conbtn[q] = {}
        end

        -- Create buttons
        local function MakeButtonNow(title, anchor)
            conbtn[title], conbtn[title].s = MakeButton(title, height)
            conbtn[title]:ClearAllPoints()
            if title == L["Zones"] then
                -- Set first button position
                conbtn[title]:SetPoint("TOPLEFT", LeaPlusLC["Page9"], "TOPLEFT", 145, -70)
            elseif anchor then
                -- Set subsequent button positions
                conbtn[title]:SetPoint("TOPLEFT", conbtn[anchor], "BOTTOMLEFT", 0, 0)
                conbtn[title].f:SetText(L[title])
            end
        end

        MakeButtonNow(L["Zones"])
        MakeButtonNow(L["Dungeons"], L["Zones"])
        MakeButtonNow(L["Various"], L["Dungeons"])
        MakeButtonNow(L["Movies"], L["Various"])
        MakeButtonNow(L["Random"], L["Movies"])
        MakeButtonNow(L["Search"]) -- Positioned when search editbox is created

        -- Show button highlight for clicked button
        for q, w in pairs(ZoneList) do
            if type(w) == "string" and conbtn[w] then
                conbtn[w]:HookScript("OnClick", function()
                    -- Hide all button highlights
                    for k, v in pairs(ZoneList) do
                        if type(v) == "string" and conbtn[v] then
                            conbtn[v].s:Hide()
                        end
                    end
                    -- Show clicked button highlight
                    conbtn[w].s:Show()
                    LeaPlusDB["MusicContinent"] = w
                    scrollFrame:SetVerticalScroll(0)
                    -- Set TempFolder for listings without folders
                    if w == L["Random"] then
                        TempFolder = L["Random"]
                    end
                    if w == L["Search"] then
                        TempFolder = L["Search"]
                    end
                end)
            end
        end

        -- Create scroll bar
        scrollFrame = CreateFrame("ScrollFrame", "LeaPlusScrollFrame", LeaPlusLC["Page9"], "FauxScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 0, -32)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
        scrollFrame:SetFrameLevel(10)
        scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
            FauxScrollFrame_OnVerticalScroll(self, offset, 16, UpdateList)
        end)

        -- Add stop button
        local stopBtn = LeaPlusLC:CreateButton("StopMusicBtn", LeaPlusLC["Page9"], "Stop", "TOPLEFT", 146, -292, 0, 25, true, "")
        stopBtn:Hide();
        stopBtn:Show()
        LeaPlusLC:LockItem(stopBtn, true)
        stopBtn:SetScript("OnClick", function()
            Sound_GameSystem_RestartSoundSystem()
            if musicHandle then
                StopSound(musicHandle)
                musicHandle = nil
                -- Hide highlight bars
                LastPlayed = ""
                LastFolder = ""
                UpdateList()
            end
            -- Cancel sound file music timer
            if LeaPlusLC.TrackTimer then
                LeaPlusLC.TrackTimer:Cancel()
            end
            -- Lock button and unregister next track events
            LeaPlusLC:LockItem(stopBtn, true)
            uframe:UnregisterEvent("SOUNDKIT_FINISHED")
            uframe:UnregisterEvent("LOADING_SCREEN_DISABLED")
        end)

        -- Store currently playing track number
        local tracknumber = 1
        local isPlayingTrack = 0

        -- Function to play a track and show the static highlight bar
        local function PlayTrack()
            -- Play tracks
            -- if musicHandle then StopSound(musicHandle) end
            if isPlayingTrack == 1 then
                Sound_GameSystem_RestartSoundSystem()
            end
            -- Sound_GameSystem_RestartSoundSystem()
            local file, soundID, trackTime
            if strfind(playlist[tracknumber], "#") then
                if strfind(playlist[tracknumber], ".mp3") then
                    -- Music file with track time
                    file, trackTime = playlist[tracknumber]:match("([^,]+)%#([^,]+)")
                    local cleanFile = file:gsub("(|C%a%a%a%a%a%a%a%a)[^|]*(|r)", "") -- Remove color tags
                    if strfind(file, "cinematics/") then
                        cleanFile = "interface/" .. cleanFile
                    elseif strfind(file, "cinematicvoices/") or strfind(file, "ambience/") or strfind(file, "spells/") then
                        cleanFile = "sound/" .. cleanFile
                    else
                        cleanFile = "sound/music/" .. cleanFile
                    end
                    willPlay, musicHandle = PlaySoundFile(cleanFile, "Master", false, true)
                    isPlayingTrack = 1
                else
                    -- Sound kit without track time
                    file, soundID = playlist[tracknumber]:match("([^,]+)%#([^,]+)")
                    willPlay, musicHandle = PlaySound(soundID, "Master", false, true)
                    isPlayingTrack = 1
                end
            end
            -- Cancel existing music timer for a sound file
            if LeaPlusLC.TrackTimer then
                LeaPlusLC.TrackTimer:Cancel()
            end
            if strfind(playlist[tracknumber], "#") then
                if strfind(playlist[tracknumber], ".mp3") then
                    -- Track is a sound file with track time so create track timer
                    LeaPlusLC.TrackTimer = LibCompat.NewTimer(trackTime + 1, function()
                        if musicHandle then
                            StopSound(musicHandle)
                        end
                        if tracknumber == #playlist then
                            -- Playlist is at the end, restart from first track
                            tracknumber = 1
                        end
                        PlayTrack()
                        isPlayingTrack = 1
                    end)
                end
            end
            -- Store its handle for later use
            LastMusicHandle = musicHandle
            LastPlayed = playlist[tracknumber]
            tracknumber = tracknumber + 1
            -- Show static highlight bar
            for index = 1, numButtons do
                local button = scrollFrame.buttons[index]
                local item = button:GetText()
                if item then
                    if strfind(item, "#") then
                        local item, void = item:match("([^,]+)%#([^,]+)")
                        if item then
                            if item == file and LastFolder == TempFolder then
                                button.s:Show()
                            else
                                button.s:Hide()
                            end
                        end
                    end
                end
            end
        end

        -- Create editbox for search
        local sBox = LeaPlusLC:CreateEditBox("MusicSearchBox", LeaPlusLC["Page9"], 78, 10, "TOPLEFT", 150, -260, "MusicSearchBox", "MusicSearchBox")
        sBox:SetMaxLetters(50)

        -- Position search button above editbox
        conbtn[L["Search"]]:ClearAllPoints()
        conbtn[L["Search"]]:SetPoint("BOTTOMLEFT", sBox, "TOPLEFT", -4, 0)

        -- Set initial search data
        for q, w in pairs(ZoneList) do
            if conbtn[w] then
                conbtn[w]:HookScript("OnClick", function()
                    if w == L["Search"] then
                        ListData[1] = "|cffffd800" .. L["Search"]
                        if #ListData == 1 then
                            ListData[2] = "|cffffffaa{" .. L["enter zone or track name"] .. "}"
                        end
                        UpdateList()
                    else
                        sBox:ClearFocus()
                    end
                end)
            end
        end

        -- Function to show search results
        local function ShowSearchResults()
            -- Get unescaped editbox text
            local searchText = gsub(strlower(sBox:GetText()), '([' .. ("%^$().[]*+-?"):gsub("(.)", "%%%1") .. '])', "%%%1")
            -- Wipe the track listing
            wipe(ListData)
            -- Set the track list heading
            ListData[1] = "|cffffd800" .. L["Search"]
            -- Show the subheading only if no search results are being shown
            if searchText == "" then
                ListData[2] = "|cffffffaa{" .. L["enter zone or track name"] .. "}"
            else
                ListData[2] = ""
            end
            -- Traverse music listing and populate ListData
            if searchText ~= "" then
                local word1, word2, word3, word4, word5 = strsplit(" ", (strtrim(searchText):gsub("%s+", " ")))
                RunScript('LeaPlusGlobalHash = {}')
                local hash = LeaPlusGlobalHash
                local trackCount = 0
                for i, e in pairs(ZoneList) do
                    if ZoneList[e] then
                        for a, b in pairs(ZoneList[e]) do
                            if b.tracks then
                                for k, v in pairs(b.tracks) do
                                    if (strfind(v, "#") or strfind(v, "|r")) and (strfind(strlower(v), word1) or strfind(strlower(b.zone), word1) or strfind(strlower(b.category), word1)) then
                                        if not word2 or word2 ~= "" and (strfind(strlower(v), word2) or strfind(strlower(b.zone), word2) or strfind(strlower(b.category), word2)) then
                                            if not word3 or word3 ~= "" and (strfind(strlower(v), word3) or strfind(strlower(b.zone), word3) or strfind(strlower(b.category), word3)) then
                                                if not word4 or word4 ~= "" and (strfind(strlower(v), word4) or strfind(strlower(b.zone), word4) or strfind(strlower(b.category), word4)) then
                                                    if not word5 or word5 ~= "" and (strfind(strlower(v), word5) or strfind(strlower(b.zone), word5) or strfind(strlower(b.category), word5)) then
                                                        -- Show category
                                                        if not hash[b.category] then
                                                            tinsert(ListData, "|cffffffff")
                                                            if b.category == e then
                                                                -- No category so just show ZoneList entry (such as Various)
                                                                tinsert(ListData, "|cffffd800" .. e)
                                                            else
                                                                -- Category exists so show that
                                                                tinsert(ListData, "|cffffd800" .. e .. ": " .. b.category)
                                                            end
                                                            hash[b.category] = true
                                                        end
                                                        -- Show track
                                                        tinsert(ListData, "|Cffffffaa" .. b.zone .. " |r" .. v)
                                                        trackCount = trackCount + 1
                                                        hash[v] = true
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                -- Set results tag
                if trackCount == 1 then
                    ListData[2] = "|cffffffaa{" .. trackCount .. " " .. L["result"] .. "}"
                else
                    ListData[2] = "|cffffffaa{" .. trackCount .. " " .. L["results"] .. "}"
                end
            end
            -- Refresh the track listing
            UpdateList()
            -- Set track listing to top
            scrollFrame:SetVerticalScroll(0)
        end

        -- Populate ListData when editbox is changed by user
        sBox:HookScript("OnTextChanged", function(self, userInput)
            if userInput then
                -- Show search page
                conbtn[L["Search"]]:Click()
                -- If search results are currently playing, stop playback since search results will be changed
                if LastFolder == L["Search"] then
                    stopBtn:Click()
                end
                -- Show search results
                ShowSearchResults()
            end
        end)

        -- Populate ListData when editbox enter key is pressed
        sBox:HookScript("OnEnterPressed", function()
            -- Show search page
            conbtn[L["Search"]]:Click()
            -- If search results are currently playing, stop playback since search results will be changed
            if LastFolder == L["Search"] then
                stopBtn:Click()
            end
            -- Show search results
            ShowSearchResults()
        end)

        -- Function to show random track listing
        local function ShowRandomList()
            -- If random track is currently playing, stop playback since random track list will be changed
            if LastFolder == L["Random"] then
                stopBtn:Click()
            end
            -- Wipe the track listing for random
            wipe(ListData)
            -- Set the track list heading
            ListData[1] = "|cffffd800" .. L["Random"]
            ListData[2] = "|Cffffffaa{" .. L["click here for new selection"] .. "}" -- Must be capital |C
            ListData[3] = "|cffffd800"
            ListData[4] = "|cffffd800" .. L["Selection of music tracks"] -- Must be lower case |c
            -- Populate list data until it contains desired number of tracks
            while #ListData < 50 do
                -- Get random category
                local rCategory = GetRandomArgument(L["Zones"], L["Dungeons"], L["Various"])
                -- Get random zone within category
                local rZone = random(1, #ZoneList[rCategory])
                -- Get random track within zone
                local rTrack = ZoneList[rCategory][rZone].tracks[random(1, #ZoneList[rCategory][rZone].tracks)]
                -- Insert track into ListData if it's not a duplicate or on the banned list
                if rTrack and rTrack ~= "" and strfind(rTrack, "#") and not tContains(ListData, "|Cffffffaa" .. ZoneList[rCategory][rZone].zone .. " |r" .. rTrack) then
                    if not tContains(randomBannedList, L[ZoneList[rCategory][rZone].zone]) and not tContains(randomBannedList, rTrack) then
                        tinsert(ListData, "|Cffffffaa" .. ZoneList[rCategory][rZone].zone .. " |r" .. rTrack)
                    end
                end
            end
            -- Refresh the track listing
            UpdateList()
            -- Set track listing to top
            scrollFrame:SetVerticalScroll(0)
        end

        -- Show random track listing on startup when random button is clicked
        for q, w in pairs(ZoneList) do
            if conbtn[w] then
                conbtn[w]:HookScript("OnClick", function()
                    if w == L["Random"] then
                        -- Generate initial playlist for first run
                        if #ListData == 0 then
                            ShowRandomList()
                        end
                    end
                end)
            end
        end

        -- Create list items
        scrollFrame.buttons = {}
        for i = 1, numButtons do
            scrollFrame.buttons[i] = CreateFrame("Button", nil, LeaPlusLC["Page9"])
            local button = scrollFrame.buttons[i]

            button:SetSize(470 - 14, 16)
            button:SetNormalFontObject("GameFontHighlightLeft")
            button:SetPoint("TOPLEFT", 246, -62 + -(i - 1) * 16 - 8)

            -- Create highlight bar texture
            button.t = button:CreateTexture(nil, "BACKGROUND")
            button.t:SetPoint("TOPLEFT", button, 0, 0)
            button.t:SetSize(516, 16)

            button.t:SetTexture(0.3, 0.3, 0.0, 0.8)
            button.t:SetAlpha(0.7)
            button.t:Hide()

            -- Create last playing highlight bar texture
            button.s = button:CreateTexture(nil, "BACKGROUND")
            button.s:SetPoint("TOPLEFT", button, 0, 0)
            button.s:SetSize(516, 16)

            button.s:SetVertexColor(0.3, 0.4, 0.00, 0.6)
            button.s:Hide()

            button:SetScript("OnEnter", function()
                -- Highlight links only
                if not string.match(button:GetText() or "", "|c") then
                    button.t:Show()
                end
            end)

            button:SetScript("OnLeave", function()
                button.t:Hide()
            end)

            button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

            -- Handler for playing next SoundKit track in playlist
            uframe:SetScript("OnEvent", function(self, event, stoppedHandle)
                if event == "SOUNDKIT_FINISHED" then
                    -- Do nothing if stopped sound kit handle doesnt match last played track handle
                    if LastMusicHandle and LastMusicHandle ~= stoppedHandle then
                        return
                    end
                    -- Reset track number if playlist has reached the end
                    if tracknumber == #playlist then
                        tracknumber = 1
                    end
                    -- Play next track
                    PlayTrack()
                elseif event == "LOADING_SCREEN_DISABLED" then
                    -- Restart player if it stopped between tracks during loading screen
                    if playlist and tracknumber and playlist[tracknumber] and not willPlay and not musicHandle then
                        tracknumber = tracknumber - 1
                        LibCompat.After(0.1, PlayTrack)
                    end
                end
            end)

            -- Click handler for track, zone and back button
            button:SetScript("OnClick", function(self, btn)
                if btn == "LeftButton" then
                    -- Remove focus from search box
                    sBox:ClearFocus()
                    -- Get clicked track text
                    local item = self:GetText()
                    -- Do nothing if its a blank line or informational heading
                    if not item or strfind(item, "|c") then
                        return
                    end
                    if item == "|Cffffffaa{" .. L["click here for new selection"] .. "}" then
                        -- must be capital |C
                        -- Create new random track listing
                        ShowRandomList()
                        return
                    elseif strfind(item, "#") then
                        -- Enable sound if required
                        if GetCVar("Sound_EnableAllSound") == "0" then
                            SetCVar("Sound_EnableAllSound", "1")
                        end
                        -- Disable music if it's currently enabled
                        if GetCVar("Sound_EnableMusic") == "1" then
                            SetCVar("Sound_EnableMusic", "0")
                        end
                        -- Add all tracks to playlist
                        wipe(playlist)
                        local StartItem = 0
                        -- Get item clicked row number
                        for index = 1, #ListData do
                            local item = ListData[index]
                            if self:GetText() == item then
                                StartItem = index
                            end
                        end
                        -- Add all items from clicked item onwards to playlist
                        for index = StartItem, #ListData do
                            local item = ListData[index]
                            if item then
                                if strfind(item, "#") then
                                    tinsert(playlist, item)
                                end
                            end
                        end
                        -- Add all items up to clicked item to playlist
                        for index = 1, StartItem do
                            local item = ListData[index]
                            if item then
                                if strfind(item, "#") then
                                    tinsert(playlist, item)
                                end
                            end
                        end
                        -- Enable the stop button
                        LeaPlusLC:LockItem(stopBtn, false)
                        -- Set Temp Folder to Random if track is in Random
                        if ListData[1] == "|cffffd800" .. L["Random"] then
                            TempFolder = L["Random"]
                        end
                        -- Set Temp Folder to Search if track is in Search
                        if ListData[1] == "|cffffd800" .. L["Search"] then
                            TempFolder = L["Search"]
                        end
                        -- Store information about the track we are about to play
                        tracknumber = 1
                        LastPlayed = item
                        LastFolder = TempFolder
                        HeadingOfClickedTrack = ListData[1]
                        -- Play first track
                        PlayTrack()
                        -- Play subsequent tracks
                        uframe:RegisterEvent("SOUNDKIT_FINISHED")
                        uframe:RegisterEvent("LOADING_SCREEN_DISABLED")
                        return
                    elseif strfind(item, "|r") then
                        --print(item)
                        -- A movie was clicked
                        local movieName, movieID = item:match("([^,]+)%|r([^,]+)")
                        --print(movieName)
                        movieID = strtrim(movieID, "()")
                        --if IsMoviePlayable(movieID) then
                        stopBtn:Click()
                        --MovieFrame_PlayMovie(MovieFrame, movieName)
                        --FIXME
                        --_G["MovieFrame"]:StartMovie(movieName,100); MovieFrame:Show()
                        print("Movies are not yet supported in 3.3.5 backport.")
                        --else
                        --	LeaPlusLC:Print("Movie not playable.")
                        --end
                        return
                    else
                        -- A zone was clicked so show track listing
                        ZonePage = scrollFrame:GetVerticalScroll()
                        -- Find the track listing for the clicked zone
                        for q, w in pairs(ZoneList) do
                            for k, v in pairs(ZoneList[w]) do
                                if item == v.zone then
                                    -- Show track listing
                                    TempFolder = item
                                    LeaPlusDB["MusicZone"] = item
                                    ListData = v.tracks
                                    UpdateList()
                                    -- Hide hover highlight if track under pointer is a heading
                                    if strfind(scrollFrame.buttons[i]:GetText(), "|c") then
                                        scrollFrame.buttons[i].t:Hide()
                                    end
                                    -- Show top of track list
                                    scrollFrame:SetVerticalScroll(0)
                                    return
                                end
                            end
                        end
                    end
                elseif btn == "RightButton" then
                    -- Back button was clicked
                    BackClick()
                end
            end)

        end

        -- Right-click to go back (from anywhere on the main content area of the panel)
        LeaPlusLC["PageF"]:HookScript("OnMouseUp", function(self, btn)
            if LeaPlusLC["Page9"]:IsShown() and LeaPlusLC["Page9"]:IsMouseOver(0, 0, 0, -440) == false and LeaPlusLC["Page9"]:IsMouseOver(-330, 0, 0, 0) == false then
                if btn == "RightButton" then
                    BackClick()
                end
            end
        end)

        -- Delete the global scroll frame pointer
        _G.LeaPlusScrollFrame = nil

        -- Set zone listing on startup
        if LeaPlusDB["MusicContinent"] and LeaPlusDB["MusicContinent"] ~= "" then
            -- Saved music continent exists
            if conbtn[LeaPlusDB["MusicContinent"]] then
                -- Saved continent is valid button so click it
                conbtn[LeaPlusDB["MusicContinent"]]:Click()
            else
                -- Saved continent is not valid button so click default button
                conbtn[L["Zones"]]:Click()
            end
        else
            -- Saved music continent does not exist so click default button
            conbtn[L["Zones"]]:Click()
        end
        UpdateList()

        -- Manage events
        LeaPlusLC["Page9"]:RegisterEvent("PLAYER_LOGOUT")
        LeaPlusLC["Page9"]:RegisterEvent("UI_SCALE_CHANGED")
        LeaPlusLC["Page9"]:SetScript("OnEvent", function(self, event)
            if event == "PLAYER_LOGOUT" then
                -- Stop playing at reload or logout
                if isPlayingTrack == 1 then
                    Sound_GameSystem_RestartSoundSystem()
                end
                if musicHandle then
                    StopSound(musicHandle)
                end
            elseif event == "UI_SCALE_CHANGED" then
                -- Refresh list
                UpdateList()
            end
        end)

    end

    -- Run on startup
    LeaPlusLC:MediaFunc()

    -- Release memory
    LeaPlusLC.MediaFunc = nil

    ----------------------------------------------------------------------
    -- Panel alpha
    ----------------------------------------------------------------------

    -- Function to set panel alpha
    local function SetPlusAlpha()
        -- Set panel alpha
        LeaPlusLC["PageF"].t:SetAlpha(1 - LeaPlusLC["PlusPanelAlpha"])
        -- Show formatted value
        LeaPlusCB["PlusPanelAlpha"].f:SetFormattedText("%.0f%%", LeaPlusLC["PlusPanelAlpha"] * 100)
    end

    -- Set alpha on startup
    SetPlusAlpha()

    -- Set alpha after changing slider
    LeaPlusCB["PlusPanelAlpha"]:HookScript("OnValueChanged", SetPlusAlpha)

    ----------------------------------------------------------------------
    -- Panel scale
    ----------------------------------------------------------------------

    -- Function to set panel scale
    local function SetPlusScale()
        -- Reset panel position
        LeaPlusLC["MainPanelA"], LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = "CENTER", "CENTER", 0, 0
        if LeaPlusLC["PageF"]:IsShown() then
            LeaPlusLC["PageF"]:Hide()
            LeaPlusLC["PageF"]:Show()
        end
        -- Set panel scale
        LeaPlusLC["PageF"]:SetScale(LeaPlusLC["PlusPanelScale"])
        -- Update music player highlight bar scale
        LeaPlusLC:UpdateList()
    end

    -- Set scale on startup
    LeaPlusLC["PageF"]:SetScale(LeaPlusLC["PlusPanelScale"])

    -- Set scale and reset panel position after changing slider
    LeaPlusCB["PlusPanelScale"]:HookScript("OnMouseUp", SetPlusScale)
    LeaPlusCB["PlusPanelScale"]:HookScript("OnMouseWheel", SetPlusScale)

    -- Show formatted slider value
    LeaPlusCB["PlusPanelScale"]:HookScript("OnValueChanged", function()
        LeaPlusCB["PlusPanelScale"].f:SetFormattedText("%.0f%%", LeaPlusLC["PlusPanelScale"] * 100)
    end)

    ----------------------------------------------------------------------
    -- Options panel
    ----------------------------------------------------------------------

    -- Hide Leatrix Plus if game options panel is shown
    InterfaceOptionsFrame:HookScript("OnShow", LeaPlusLC.HideFrames);
    VideoOptionsFrame:HookScript("OnShow", LeaPlusLC.HideFrames);

    ----------------------------------------------------------------------
    -- Block friend requests
    ----------------------------------------------------------------------


    -- -- Function to decline friend requests
    -- local function DeclineReqs()
    -- 	if LeaPlusLC["NoFriendRequests"] == "On" then
    -- 		for i = BNGetNumFriendInvites(), 1, -1 do
    -- 			local id, player = BNGetFriendInviteInfo(i)
    -- 			if id and player then
    -- 				BNDeclineFriendInvite(id)
    -- 				LibCompat.After(0.1, function()
    -- 					LeaPlusLC:Print(L["A friend request from"] .. " " .. player .. " " .. L["was automatically declined."])
    -- 				end)
    -- 			end
    -- 		end
    -- 	end
    -- end

    -- -- Event frame for incoming friend requests
    -- local DecEvt = CreateFrame("FRAME")
    -- DecEvt:SetScript("OnEvent", DeclineReqs)

    -- -- Function to register or unregister the event
    -- local function ControlEvent()
    -- 	if LeaPlusLC["NoFriendRequests"] == "On" then
    -- 		DecEvt:RegisterEvent("BN_FRIEND_INVITE_ADDED")
    -- 		DeclineReqs()
    -- 	else
    -- 		DecEvt:UnregisterEvent("BN_FRIEND_INVITE_ADDED")
    -- 	end
    -- end

    -- -- Set event status when option is enabled
    -- LeaPlusCB["NoFriendRequests"]:HookScript("OnClick", ControlEvent)

    -- -- Set event status on startup
    -- ControlEvent()

    ----------------------------------------------------------------------
    -- Invite from whisper (configuration panel)
    ----------------------------------------------------------------------

    -- Create configuration panel
    local InvPanel = LeaPlusLC:CreatePanel("Invite from whispers", "InvPanel")

    -- Add editbox
    LeaPlusLC:MakeTx(InvPanel, "Settings", 16, -72)
    LeaPlusLC:MakeCB(InvPanel, "InviteFriendsOnly", "Restrict to friends", 16, -92, false, "If checked, group invites will only be sent to friends.|n|nIf unchecked, group invites will be sent to everyone.")

    LeaPlusLC:MakeTx(InvPanel, "Keyword", 356, -72)
    local KeyBox = LeaPlusLC:CreateEditBox("KeyBox", InvPanel, 140, 10, "TOPLEFT", 356, -92, "KeyBox", "KeyBox")

    -- Function to show the keyword in the option tooltip
    local function SetKeywordTip()
        LeaPlusCB["InviteFromWhisper"].tiptext = gsub(LeaPlusCB["InviteFromWhisper"].tiptext, "(|cffffffff)[^|]*(|r)", "%1" .. LeaPlusLC["InvKey"] .. "%2")
    end

    -- Function to save the keyword
    local function SetInvKey()
        local keytext = KeyBox:GetText()
        if keytext and keytext ~= "" then
            LeaPlusLC["InvKey"] = strtrim(KeyBox:GetText())
        else
            LeaPlusLC["InvKey"] = "inv"
        end
        -- Show the keyword in the option tooltip
        SetKeywordTip()
    end

    -- Show the keyword in the option tooltip on startup
    SetKeywordTip()

    -- Save the keyword when it changes
    KeyBox:SetScript("OnTextChanged", SetInvKey)

    -- Refresh editbox with trimmed keyword when edit focus is lost (removes additional spaces)
    KeyBox:SetScript("OnEditFocusLost", function()
        KeyBox:SetText(LeaPlusLC["InvKey"])
    end)

    -- Help button hidden
    InvPanel.h:Hide()

    -- Back button handler
    InvPanel.b:SetScript("OnClick", function()
        -- Save the keyword
        SetInvKey()
        -- Show the options panel
        InvPanel:Hide();
        LeaPlusLC["PageF"]:Show();
        LeaPlusLC["Page2"]:Show()
        return
    end)

    -- Add reset button
    InvPanel.r:SetScript("OnClick", function()
        -- Settings
        LeaPlusLC["InviteFriendsOnly"] = "Off"
        -- Reset the keyword to default
        LeaPlusLC["InvKey"] = "inv"
        -- Set the editbox to default
        KeyBox:SetText("inv")
        -- Save the keyword
        SetInvKey()
        -- Refresh panel
        InvPanel:Hide();
        InvPanel:Show()
    end)

    -- Ensure keyword is a string on startup
    LeaPlusLC["InvKey"] = tostring(LeaPlusLC["InvKey"]) or "inv"

    -- Set editbox value when shown
    KeyBox:HookScript("OnShow", function()
        KeyBox:SetText(LeaPlusLC["InvKey"])
    end)

    -- Configuration button handler
    LeaPlusCB["InvWhisperBtn"]:SetScript("OnClick", function()
        if IsShiftKeyDown() and IsControlKeyDown() then
            -- Preset profile
            LeaPlusLC["InviteFriendsOnly"] = "On"
            LeaPlusLC["InvKey"] = "inv"
            KeyBox:SetText(LeaPlusLC["InvKey"])
            SetInvKey()
        else
            -- Show panel
            InvPanel:Show()
            LeaPlusLC:HideFrames()
        end
    end)

    ----------------------------------------------------------------------
    -- Final code for RunOnce
    ----------------------------------------------------------------------

    -- Update addon memory usage (speeds up initial value)
    UpdateAddOnMemoryUsage();

    -- Release memory
    LeaPlusLC.RunOnce = nil

end

----------------------------------------------------------------------
-- 	L60: Default events
----------------------------------------------------------------------

local function eventHandler(self, event, arg1, arg2, ...)

    --------------------------------------------------------------------------------
    -- Auto Spirit Healer Res
    --------------------------------------------------------------------------------


    if event == "PLAYER_LOGIN" and UnitIsGhost("player") then
        self:RegisterEvent("GOSSIP_SHOW")
    elseif event == "PLAYER_DEAD" then
        self:RegisterEvent("GOSSIP_SHOW")
    elseif event == "CONFIRM_XP_LOSS" then
        AcceptXPLoss()
    elseif event == "GOSSIP_SHOW" then
        if UnitIsGhost("player") then
            local _, type = GetGossipOptions()
            if type == "healer" then
                SelectGossipOption(1)
                self:UnregisterEvent("GOSSIP_SHOW")
            end
        else
            self:UnregisterEvent("GOSSIP_SHOW")
        end
    end


    ----------------------------------------------------------------------
    -- Invite from whisper
    ----------------------------------------------------------------------

    if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_BN_WHISPER" then
        if (not UnitExists("party1") or LibCompat.UnitIsGroupLeader("player") or LibCompat.UnitIsGroupAssistant("player")) and strlower(strtrim(arg1)) == strlower(LeaPlusLC["InvKey"]) then
            if not LeaPlusLC:IsInLFGQueue() then
                if event == "CHAT_MSG_WHISPER" then
                    local void, void, void, void, void, void, void, void, void, guid = ...
                    if LeaPlusLC:FriendCheck(arg2, guid) or LeaPlusLC["InviteFriendsOnly"] == "Off" then
                        InviteUnit(arg2)
                    end
                elseif event == "CHAT_MSG_BN_WHISPER" then
                    local presenceID = select(11, ...)
                    if presenceID and BNIsFriend(presenceID) then
                        local index = BNGetFriendIndex(presenceID)
                        if index then
                            local accountInfo = C_BattleNet.GetFriendAccountInfo(index)
                            local gameAccountInfo = accountInfo.gameAccountInfo
                            local gameAccountID = gameAccountInfo.gameAccountID
                            if gameAccountID then
                                BNInviteFriend(gameAccountID)
                            end
                        end
                    end
                end
            end
        end
        return
    end

    ----------------------------------------------------------------------
    -- Block duel requests
    ----------------------------------------------------------------------

    if event == "DUEL_REQUESTED" and not LeaPlusLC:FriendCheck(arg1) then
        CancelDuel()
        StaticPopup_Hide("DUEL_REQUESTED")
        return
    end

    ----------------------------------------------------------------------
    -- Accept summon
    ----------------------------------------------------------------------

    if event == "CONFIRM_SUMMON" then
        if not UnitAffectingCombat("player") then
            local sName = GetSummonConfirmSummoner()
            local sLocation = GetSummonConfirmAreaName()
            LeaPlusLC:Print(L["The summon from"] .. " |cFFFFFFFF" .. sName .. "|r - |cFFFFFF00(" .. sLocation .. ")|r " .. L["will be automatically accepted in |cFF00FF0010 seconds|r unless cancelled."])

            LibCompat.After(10, function()
                local sNameNew = GetSummonConfirmSummoner()
                local sLocationNew = GetSummonConfirmAreaName()
                if sName == sNameNew and sLocation == sLocationNew then
                    -- Automatically accept summon after 10 seconds if summoner name and location have not changed
                    ConfirmSummon()
                    StaticPopup_Hide("CONFIRM_SUMMON")
                end
            end)
        end
        return
    end

    ----------------------------------------------------------------------
    -- Block party invites and party from friends
    ----------------------------------------------------------------------

    if event == "PARTY_INVITE_REQUEST" then

        -- If a friend, accept if you're accepting friends and not in battleground queue
        local void, void, void, void, guid = ...
        if (LeaPlusLC["AcceptPartyFriends"] == "On" and LeaPlusLC:FriendCheck(arg1, guid)) then
            if not LeaPlusLC:IsInLFGQueue() then
                AcceptGroup()
                for i = 1, STATICPOPUP_NUMDIALOGS do
                    if _G["StaticPopup" .. i].which == "PARTY_INVITE" then
                        _G["StaticPopup" .. i].inviteAccepted = 1
                        StaticPopup_Hide("PARTY_INVITE")
                        break
                    elseif _G["StaticPopup" .. i].which == "PARTY_INVITE_XREALM" then
                        _G["StaticPopup" .. i].inviteAccepted = 1
                        StaticPopup_Hide("PARTY_INVITE_XREALM")
                        break
                    end
                end
                return
            end
        end

        -- If not a friend and you're blocking invites, decline
        if LeaPlusLC["NoPartyInvites"] == "On" then
            if LeaPlusLC:FriendCheck(arg1, guid) then
                return
            else
                DeclineGroup()
                StaticPopup_Hide("PARTY_INVITE")
                StaticPopup_Hide("PARTY_INVITE_XREALM")
                return
            end
        end

        return
    end

    ----------------------------------------------------------------------
    -- Block guild invites
    ----------------------------------------------------------------------

    if event == "GUILD_INVITE_REQUEST" then

        -- If a friend, accept if you're accepting friends and not in battleground queue
        local void, void, void, void, guid = ...
        -- If not a friend and you're blocking invites, decline
        if LeaPlusLC["NoGuildInvites"] == "On" then
            if LeaPlusLC:FriendCheck(arg1, guid) then
                return
            else
                DeclineGuild()
                StaticPopup_Hide("GUILD_INVITE")
                return
            end
        end

        return
    end

    ----------------------------------------------------------------------
    -- Disable loot warnings
    ----------------------------------------------------------------------

    -- Disable warnings for attempting to roll Need on loot
    if event == "CONFIRM_LOOT_ROLL" then
        ConfirmLootRoll(arg1, arg2)
        StaticPopup_Hide("CONFIRM_LOOT_ROLL")
        return
    end

    -- Disable warning for attempting to loot a Bind on Pickup item
    if event == "LOOT_BIND_CONFIRM" then
        ConfirmLootSlot(arg1, arg2)
        StaticPopup_Hide("LOOT_BIND", ...)
        return
    end

    function Leatrix_CustomSellCursorItem()
        -- Fetch the mouseovered item
        local bag, slot = GetMouseFocus():GetParent():GetID(), GetMouseFocus():GetID()

        -- Check if the bag and slot are valid (i.e., an actual item)
        if bag and slot and bag > 0 and slot > 0 then
            local cursorType, itemId = GetCursorInfo()

            -- Pick up the mouseovered item
            PickupContainerItem(bag, slot)

            -- Get the updated cursor info
            cursorType, itemId = GetCursorInfo()

            -- Check if the item is on the cursor
            if cursorType == "item" and itemId then
                -- Check if the player is at the vendor
                if MerchantFrame:IsVisible() then
                    PickupMerchantItem() -- Put the item in the buyback slot, effectively selling it
                else
                    ClearCursor() -- Remove the item from the cursor if not at a vendor
                end
            end
        end
    end



    -- Disable warning for attempting to vendor an item within its refund window
    -- FIXME 3.3.5 what event is this used for in retail? Is it safe to fix this? Does anybody want that?
    if event == "MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL" then
        -- TODO: Rename me from global. MUST DO
        Leatrix_CustomSellCursorItem()
        return
    end

    -- Disable warning for attempting to mail an item within its refund window
    -- FIXME 3.3.5 what event is this used for in retail? Is it safe to fix this? Does anybody want that?
    if event == "MAIL_LOCK_SEND_ITEMS" then
        RespondMailLockSendItem(arg1, true)
        return
    end

    ----------------------------------------------------------------------
    -- Hide the combat log
    ----------------------------------------------------------------------

    if event == "UPDATE_CHAT_WINDOWS" then
        ChatFrame2Tab:EnableMouse(false)
        ChatFrame2Tab:SetText(" ") -- Needs to be something for chat settings to function
        ChatFrame2Tab:SetScale(0.01)
        ChatFrame2Tab:SetWidth(0.01)
        ChatFrame2Tab:SetHeight(0.01)
    end

    ----------------------------------------------------------------------
    -- L62: Profile events
    ----------------------------------------------------------------------

    if event == "ADDON_LOADED" then
        if arg1 == "Leatrix_Plus" then

            -- Replace old var names with new ones
            local function UpdateVars(oldvar, newvar)
                if LeaPlusDB[oldvar] and not LeaPlusDB[newvar] then
                    LeaPlusDB[newvar] = LeaPlusDB[oldvar];
                    LeaPlusDB[oldvar] = nil
                end
            end

            UpdateVars("MuteStriders", "MuteMechSteps")                    -- 2.5.108 (1st June 2022)
            UpdateVars("MinimapMod", "MinimapModder")                    -- 2.5.120 (24th August 2022)

            -- Automation
            LeaPlusLC:LoadVarChk("AutomateQuests", "Off")                -- Automate quests
            LeaPlusLC:LoadVarChk("AutoQuestShift", "Off")                -- Automate quests requires shift
            LeaPlusLC:LoadVarChk("AutoQuestAvailable", "On")            -- Accept available quests
            LeaPlusLC:LoadVarChk("AutoQuestCompleted", "On")            -- Turn-in completed quests
            LeaPlusLC:LoadVarNum("AutoQuestKeyMenu", 1, 1, 3)            -- Automate quests override key
            LeaPlusLC:LoadVarChk("AutomateGossip", "Off")                -- Automate gossip
            LeaPlusLC:LoadVarChk("AutoAcceptSummon", "Off")                -- Accept summon
            LeaPlusLC:LoadVarChk("AutoAcceptRes", "Off")                -- Accept resurrection
            LeaPlusLC:LoadVarChk("AutoResNoCombat", "On")                -- Accept resurrection exclude combat
            LeaPlusLC:LoadVarChk("AutoReleasePvP", "Off")                -- Release in PvP
            LeaPlusLC:LoadVarChk("AutoReleaseNoAlterac", "Off")            -- Release in PvP Exclude Alterac Valley
            LeaPlusLC:LoadVarNum("AutoReleaseDelay", 200, 200, 3000)    -- Release in PvP Delay
            LeaPlusLC:LoadVarChk("AutoSpiritRes", "Off")                -- Release in PvP

            LeaPlusLC:LoadVarChk("AutoSellJunk", "Off")                    -- Sell junk automatically
            LeaPlusLC:LoadVarChk("AutoSellShowSummary", "On")            -- Sell junk summary in chat
            LeaPlusLC:LoadVarStr("AutoSellExcludeList", "")                -- Sell junk exclude list
            LeaPlusLC:LoadVarChk("AutoRepairGear", "Off")                -- Repair automatically
            LeaPlusLC:LoadVarChk("AutoRepairGuildFunds", "On")            -- Repair using guild funds
            LeaPlusLC:LoadVarChk("AutoRepairShowSummary", "On")            -- Repair show summary in chat

            -- Social
            LeaPlusLC:LoadVarChk("NoDuelRequests", "Off")                -- Block duels
            LeaPlusLC:LoadVarChk("NoPartyInvites", "Off")                -- Block party invites
            LeaPlusLC:LoadVarChk("NoGuildInvites", "Off")                -- Block party invites
            -- LeaPlusLC:LoadVarChk("NoFriendRequests", "Off")				-- Block friend requests
            LeaPlusLC:LoadVarChk("NoSharedQuests", "Off")                -- Block shared quests

            LeaPlusLC:LoadVarChk("AcceptPartyFriends", "Off")            -- Party from friends
            LeaPlusLC:LoadVarChk("InviteFromWhisper", "Off")            -- Invite from whispers
            LeaPlusLC:LoadVarChk("InviteFriendsOnly", "Off")            -- Restrict invites to friends
            LeaPlusLC["InvKey"] = LeaPlusDB["InvKey"] or "inv"            -- Invite from whisper keyword
            LeaPlusLC:LoadVarChk("FriendlyGuild", "On")                    -- Friendly guild

            -- Chat
            LeaPlusLC:LoadVarChk("UseEasyChatResizing", "Off")            -- Use easy resizing
            LeaPlusLC:LoadVarChk("NoCombatLogTab", "Off")                -- Hide the combat log
            LeaPlusLC:LoadVarChk("NoChatButtons", "Off")                -- Hide chat buttons
            LeaPlusLC:LoadVarChk("UnclampChat", "Off")                    -- Unclamp chat frame
            LeaPlusLC:LoadVarChk("MoveChatEditBoxToTop", "Off")            -- Move editbox to top
            LeaPlusLC:LoadVarChk("MoreFontSizes", "Off")                -- More font sizes
            LeaPlusLC:LoadVarChk("AltClickInv", "Off")                -- More font sizes

            LeaPlusLC:LoadVarChk("NoStickyChat", "Off")                    -- Disable sticky chat
            LeaPlusLC:LoadVarChk("UseArrowKeysInChat", "Off")            -- Use arrow keys in chat
            LeaPlusLC:LoadVarChk("NoChatFade", "Off")                    -- Disable chat fade
            LeaPlusLC:LoadVarChk("UnivGroupColor", "Off")                -- Universal group color
            LeaPlusLC:LoadVarChk("ClassColorsInChat", "Off")            -- Use class colors in chat
            LeaPlusLC:LoadVarChk("RecentChatWindow", "Off")                -- Recent chat window
            LeaPlusLC:LoadVarNum("RecentChatSize", 170, 170, 600)        -- Recent chat size
            LeaPlusLC:LoadVarChk("MaxChatHstory", "Off")                -- Increase chat history
            LeaPlusLC:LoadVarChk("FilterChatMessages", "Off")            -- Filter chat messages
            LeaPlusLC:LoadVarChk("BlockSpellLinks", "Off")                -- Block spell links
            LeaPlusLC:LoadVarChk("BlockDrunkenSpam", "Off")                -- Block drunken spam
            LeaPlusLC:LoadVarChk("BlockDuelSpam", "Off")                -- Block duel spam
            LeaPlusLC:LoadVarChk("RestoreChatMessages", "Off")            -- Restore chat messages

            -- Text
            LeaPlusLC:LoadVarChk("HideErrorMessages", "Off")            -- Hide error messages
            LeaPlusLC:LoadVarChk("NoHitIndicators", "Off")                -- Hide portrait text
            LeaPlusLC:LoadVarChk("HideZoneText", "Off")                    -- Hide zone text
            LeaPlusLC:LoadVarChk("HideKeybindText", "Off")                -- Hide keybind text
            LeaPlusLC:LoadVarChk("HideMacroText", "Off")                -- Hide macro text

            LeaPlusLC:LoadVarChk("MailFontChange", "Off")                -- Resize mail text
            LeaPlusLC:LoadVarNum("LeaPlusMailFontSize", 15, 10, 36)        -- Mail text slider

            LeaPlusLC:LoadVarChk("QuestFontChange", "Off")                -- Resize quest text
            LeaPlusLC:LoadVarNum("LeaPlusQuestFontSize", 12, 10, 36)    -- Quest text slider

            LeaPlusLC:LoadVarChk("BookFontChange", "Off")                -- Resize book text
            LeaPlusLC:LoadVarNum("LeaPlusBookFontSize", 15, 10, 36)        -- Book text slider

            -- Interface
            LeaPlusLC:LoadVarChk("MinimapModder", "Off")                -- Enhance minimap
            LeaPlusLC:LoadVarChk("SquareMinimap", "Off")                -- Square minimap
            LeaPlusLC:LoadVarChk("ShowWhoPinged", "On")                    -- Show who pinged
            LeaPlusLC:LoadVarChk("CombineAddonButtons", "Off")            -- Combine addon buttons
            LeaPlusLC:LoadVarStr("MiniExcludeList", "")                    -- Minimap exclude list
            LeaPlusLC:LoadVarChk("HideMiniZoomBtns", "Off")                -- Hide zoom buttons
            LeaPlusLC:LoadVarChk("HideMiniZoneText", "Off")                -- Hide the zone text bar
            LeaPlusLC:LoadVarChk("HideMiniAddonButtons", "On")            -- Hide addon buttons
            LeaPlusLC:LoadVarChk("HideMiniMapButton", "On")                -- Hide the world map button
            LeaPlusLC:LoadVarChk("HideMiniTracking", "Off")                -- Hide the tracking button
            LeaPlusLC:LoadVarChk("HideMiniCalendar", "Off")                -- Hide the tracking button
            LeaPlusLC:LoadVarChk("HideMiniPOIArrows", "Off")                -- Hide the tracking button
            LeaPlusLC:LoadVarChk("ClockMouseover", "Off")                -- Hide the tracking button
            LeaPlusLC:LoadVarNum("MinimapScale", 1, 1, 4)                -- Minimap scale slider
            LeaPlusLC:LoadVarNum("MinimapSize", 140, 140, 560)            -- Minimap size slider
            LeaPlusLC:LoadVarNum("MiniClusterScale", 1, 1, 2)            -- Minimap cluster scale
            LeaPlusLC:LoadVarNum("MiniAddonPanelScale", 1, 0, 2)            -- Minimap cluster scale

            LeaPlusLC:LoadVarChk("MinimapNoScale", "Off")                -- Minimap not minimap
            LeaPlusLC:LoadVarAnc("MinimapA", "TOPRIGHT")                -- Minimap anchor
            LeaPlusLC:LoadVarAnc("MinimapR", "TOPRIGHT")                -- Minimap relative
            LeaPlusLC:LoadVarNum("MinimapX", -17, -5000, 5000)            -- Minimap X
            LeaPlusLC:LoadVarNum("MinimapY", -22, -5000, 5000)            -- Minimap Y
            LeaPlusLC:LoadVarChk("TipModEnable", "Off")                    -- Enhance tooltip
            LeaPlusLC:LoadVarChk("TipShowRank", "On")                    -- Show rank
            LeaPlusLC:LoadVarChk("TipShowOtherRank", "Off")                -- Show rank for other guilds
            LeaPlusLC:LoadVarChk("TipShowTarget", "On")                    -- Show target
            LeaPlusLC:LoadVarChk("TipHideInCombat", "Off")                -- Hide tooltips during combat
            LeaPlusLC:LoadVarChk("TipHideShiftOverride", "On")            -- Hide tooltips shift override
            LeaPlusLC:LoadVarChk("TipNoHealthBar", "Off")                -- Hide health bar
            LeaPlusLC:LoadVarNum("LeaPlusTipSize", 1.00, 0.50, 2.00)    -- Tooltip scale slider
            LeaPlusLC:LoadVarNum("TipOffsetX", -13, -5000, 5000)        -- Tooltip X offset
            LeaPlusLC:LoadVarNum("TipOffsetY", 94, -5000, 5000)            -- Tooltip Y offset
            LeaPlusLC:LoadVarNum("TooltipAnchorMenu", 1, 1, 5)            -- Tooltip anchor menu
            LeaPlusLC:LoadVarNum("MiniMapMailIconPos", 1, 1, 4)            -- Tooltip anchor menu
            LeaPlusLC:LoadVarNum("MiniMapLFGIconPos", 3, 1, 4)            -- Tooltip anchor menu
            LeaPlusLC:LoadVarNum("MiniMapBattlefieldIconPos", 1, 1, 4)            -- Tooltip anchor menu
            LeaPlusLC:LoadVarNum("TipCursorX", 0, -128, 128)            -- Tooltip cursor X offset
            LeaPlusLC:LoadVarNum("TipCursorY", 0, -128, 128)            -- Tooltip cursor Y offset

            LeaPlusLC:LoadVarChk("EnhanceDressup", "Off")                -- Enhance dressup
            LeaPlusLC:LoadVarChk("DressupItemButtons", "On")            -- Dressup item buttons
            LeaPlusLC:LoadVarChk("DressupAnimControl", "On")            -- Dressup animation control
            LeaPlusLC:LoadVarChk("HideDressupStats", "Off")                -- Hide dressup stats
            LeaPlusLC:LoadVarChk("EnhanceQuestLog", "Off")                -- Enhance quest log
            LeaPlusLC:LoadVarChk("EnhanceQuestHeaders", "On")            -- Enhance quest log toggle headers
            LeaPlusLC:LoadVarChk("EnhanceQuestLevels", "On")            -- Enhance quest log quest levels
            LeaPlusLC:LoadVarChk("EnhanceQuestDifficulty", "On")        -- Enhance quest log quest difficulty
            LeaPlusLC:LoadVarChk("EnhanceProfessions", "Off")            -- Enhance professions
            LeaPlusLC:LoadVarChk("EnhanceTrainers", "Off")                -- Enhance trainers
            LeaPlusLC:LoadVarChk("ShowTrainAllBtn", "On")                -- Enhance trainers train all button

            LeaPlusLC:LoadVarChk("ShowVolume", "Off")                    -- Show volume slider
            LeaPlusLC:LoadVarChk("AhExtras", "Off")                        -- Show auction controls
            LeaPlusLC:LoadVarChk("AhBuyoutOnly", "Off")                    -- Auction buyout only
            LeaPlusLC:LoadVarChk("AhGoldOnly", "Off")                    -- Auction gold only
            LeaPlusLC:LoadVarChk("AhTabConfirm", "Off")                    -- Auction confirm on TAB pressed

            -- LeaPlusLC:LoadVarChk("ShowCooldowns", "Off")				-- Show cooldowns
            -- LeaPlusLC:LoadVarChk("ShowCooldownID", "On")				-- Show cooldown ID in tips
            -- LeaPlusLC:LoadVarChk("NoCooldownDuration", "On")			-- Hide cooldown duration
            -- LeaPlusLC:LoadVarChk("CooldownsOnPlayer", "Off")			-- Anchor to player
            LeaPlusLC:LoadVarChk("DurabilityStatus", "Off")                -- Show durability status
            LeaPlusLC:LoadVarChk("ShowVanityControls", "Off")            -- Show vanity controls
            LeaPlusLC:LoadVarChk("VanityAltLayout", "Off")                -- Vanity alternative layout
            LeaPlusLC:LoadVarChk("ShowBagSearchBox", "Off")                -- Show bag search box
            -- LeaPlusLC:LoadVarChk("ShowRaidToggle", "Off")				-- Show raid button
            LeaPlusLC:LoadVarChk("ShowPlayerChain", "Off")                -- Show player chain
            LeaPlusLC:LoadVarNum("PlayerChainMenu", 2, 1, 3)            -- Player chain dropdown value
            LeaPlusLC:LoadVarChk("ShowReadyTimer", "Off")                -- Show ready timer
            LeaPlusLC:LoadVarChk("ShowWowheadLinks", "Off")                -- Show Wowhead links
            LeaPlusLC:LoadVarChk("WowheadLinkComments", "Off")            -- Show Wowhead links to comments

            LeaPlusLC:LoadVarChk("ShowFlightTimes", "Off")                -- Show flight times
            LeaPlusLC:LoadVarChk("FlightBarBackground", "On")            -- Show flight times bar background
            LeaPlusLC:LoadVarChk("FlightBarDestination", "On")            -- Show flight times bar destination
            LeaPlusLC:LoadVarChk("FlightBarFillBar", "Off")                -- Show flight times bar fill mode
            LeaPlusLC:LoadVarChk("FlightBarSpeech", "Off")                -- Show flight times bar speech

            LeaPlusLC:LoadVarChk("FlightBarContribute", "Off")            -- Show flight times contribute
            LeaPlusLC:LoadVarAnc("FlightBarA", "TOP")                    -- Show flight times anchor
            LeaPlusLC:LoadVarAnc("FlightBarR", "TOP")                    -- Show flight times relative
            LeaPlusLC:LoadVarNum("FlightBarX", 0, -5000, 5000)            -- Show flight position X
            LeaPlusLC:LoadVarNum("FlightBarY", -66, -5000, 5000)        -- Show flight position Y
            LeaPlusLC:LoadVarNum("FlightBarScale", 2, 1, 5)                -- Show flight times bar scale
            LeaPlusLC:LoadVarNum("FlightBarWidth", 230, 40, 460)        -- Show flight times bar width

            -- Frames
            LeaPlusLC:LoadVarChk("FrmEnabled", "Off")                    -- Manage frames

            LeaPlusLC:LoadVarChk("ManageBuffs", "Off")                    -- Manage buffs
            LeaPlusLC:LoadVarAnc("BuffFrameA", "TOPRIGHT")                -- Manage buffs anchor
            LeaPlusLC:LoadVarAnc("BuffFrameR", "TOPRIGHT")                -- Manage buffs relative
            LeaPlusLC:LoadVarNum("BuffFrameX", -205, -5000, 5000)        -- Manage buffs position X
            LeaPlusLC:LoadVarNum("BuffFrameY", -13, -5000, 5000)        -- Manage buffs position Y
            LeaPlusLC:LoadVarNum("BuffFrameScale", 1, 0.5, 2)            -- Manage buffs scale

            LeaPlusLC:LoadVarChk("ManageDeBuffs", "Off")                    -- Manage buffs
            LeaPlusLC:LoadVarAnc("DebuffButton1A", "TOPRIGHT")                -- Manage buffs anchor
            LeaPlusLC:LoadVarAnc("DebuffButton1R", "TOPRIGHT")                -- Manage buffs relative
            LeaPlusLC:LoadVarNum("DebuffButton1X", -205, -5000, 5000)        -- Manage buffs position X
            LeaPlusLC:LoadVarNum("DebuffButton1Y", -13, -5000, 5000)        -- Manage buffs position Y
            LeaPlusLC:LoadVarNum("DebuffButton1Scale", 1, 0.5, 2)            -- Manage buffs scale

            LeaPlusLC:LoadVarChk("ManageWidget", "Off")                    -- Manage widget
            LeaPlusLC:LoadVarAnc("WidgetA", "TOP")                        -- Manage widget anchor
            LeaPlusLC:LoadVarAnc("WidgetR", "TOP")                        -- Manage widget relative
            LeaPlusLC:LoadVarNum("WidgetX", 0, -5000, 5000)                -- Manage widget position X
            LeaPlusLC:LoadVarNum("WidgetY", -15, -5000, 5000)            -- Manage widget position Y
            LeaPlusLC:LoadVarNum("WidgetScale", 1, 0.5, 2)                -- Manage widget scale

            LeaPlusLC:LoadVarChk("ManageFocus", "Off")                    -- Manage focus
            LeaPlusLC:LoadVarAnc("FocusA", "CENTER")                    -- Manage focus anchor
            LeaPlusLC:LoadVarAnc("FocusR", "CENTER")                    -- Manage focus relative
            LeaPlusLC:LoadVarNum("FocusX", 0, -5000, 5000)                -- Manage focus position X
            LeaPlusLC:LoadVarNum("FocusY", 0, -5000, 5000)                -- Manage focus position Y
            LeaPlusLC:LoadVarNum("FocusScale", 1, 0.5, 2)                -- Manage focus scale

            LeaPlusLC:LoadVarChk("ManageTimer", "Off")                    -- Manage timer
            LeaPlusLC:LoadVarAnc("TimerA", "TOP")                        -- Manage timer anchor
            LeaPlusLC:LoadVarAnc("TimerR", "TOP")                        -- Manage timer relative
            LeaPlusLC:LoadVarNum("TimerX", -5, -5000, 5000)                -- Manage timer position X
            LeaPlusLC:LoadVarNum("TimerY", -96, -5000, 5000)            -- Manage timer position Y
            LeaPlusLC:LoadVarNum("TimerScale", 1, 0.5, 2)                -- Manage timer scale

            LeaPlusLC:LoadVarChk("ManageDurability", "Off")                -- Manage durability
            LeaPlusLC:LoadVarAnc("DurabilityA", "TOPRIGHT")                -- Manage durability anchor
            LeaPlusLC:LoadVarAnc("DurabilityR", "TOPRIGHT")                -- Manage durability relative
            LeaPlusLC:LoadVarNum("DurabilityX", 0, -5000, 5000)            -- Manage durability position X
            LeaPlusLC:LoadVarNum("DurabilityY", -170, -5000, 5000)        -- Manage durability position Y
            LeaPlusLC:LoadVarNum("DurabilityScale", 1, 0.5, 2)            -- Manage durability scale

            LeaPlusLC:LoadVarAnc("CombineAddonsFrameA", "BOTTOMRIGHT")                -- Manage CombineAddonsFrame anchor
            LeaPlusLC:LoadVarAnc("CombineAddonsFrameR", "BOTTOMLEFT")                -- Manage CombineAddonsFrame relative
            LeaPlusLC:LoadVarNum("CombineAddonsFrameX", -2, -5000, 5000)            -- Manage CombineAddonsFrame position X
            LeaPlusLC:LoadVarNum("CombineAddonsFrameY", -1.2, -5000, 5000)        -- Manage CombineAddonsFrame position Y
            --LeaPlusLC:LoadVarNum("CombineAddonsFrameScale", 1, 0.5, 2)			-- Manage CombineAddonsFrame scale

            LeaPlusLC:LoadVarChk("ManageTracker", "Off")                -- Manage Tracker
            LeaPlusLC:LoadVarAnc("TrackerA", "TOPRIGHT")                -- Manage Tracker anchor
            LeaPlusLC:LoadVarAnc("TrackerR", "TOPRIGHT")                -- Manage Tracker relative
            LeaPlusLC:LoadVarNum("TrackerX", 0, -5000, 5000)            -- Manage Tracker position X
            LeaPlusLC:LoadVarNum("TrackerY", -170, -5000, 5000)        -- Manage Tracker position Y
            LeaPlusLC:LoadVarNum("TrackerScale", 1, 0.5, 2)            -- Manage Tracker scale

            LeaPlusLC:LoadVarChk("ManageVehicle", "Off")                -- Manage vehicle
            LeaPlusLC:LoadVarAnc("VehicleA", "TOPRIGHT")                -- Manage vehicle anchor
            LeaPlusLC:LoadVarAnc("VehicleR", "TOPRIGHT")                -- Manage vehicle relative
            LeaPlusLC:LoadVarNum("VehicleX", -100, -5000, 5000)            -- Manage vehicle position X
            LeaPlusLC:LoadVarNum("VehicleY", -192, -5000, 5000)            -- Manage vehicle position Y
            LeaPlusLC:LoadVarNum("VehicleScale", 1, 0.5, 2)                -- Manage vehicle scale

            LeaPlusLC:LoadVarChk("ClassColFrames", "Off")                -- Class colored frames
            LeaPlusLC:LoadVarChk("ClassColPlayer", "On")                -- Class colored player frame
            LeaPlusLC:LoadVarChk("ClassColTarget", "On")                -- Class colored target frame

            LeaPlusLC:LoadVarChk("NoAlerts", "Off")                        -- Hide alerts
            LeaPlusLC:LoadVarChk("NoGryphons", "Off")                    -- Hide gryphons
            LeaPlusLC:LoadVarChk("NoClassBar", "Off")                    -- Hide stance bar

            -- System
            LeaPlusLC:LoadVarChk("NoScreenGlow", "Off")                    -- Disable screen glow
            LeaPlusLC:LoadVarChk("NoScreenEffects", "Off")                -- Disable screen effects
            LeaPlusLC:LoadVarChk("SetWeatherDensity", "Off")            -- Set weather density
            LeaPlusLC:LoadVarNum("WeatherLevel", 3, 0, 3)                -- Weather density level
            LeaPlusLC:LoadVarChk("MaxCameraZoom", "Off")                -- Max camera zoom
            LeaPlusLC:LoadVarChk("ViewPortEnable", "Off")                -- Enable viewport
            LeaPlusLC:LoadVarNum("ViewPortTop", 0, 0, 300)                -- Top border
            LeaPlusLC:LoadVarNum("ViewPortBottom", 0, 0, 300)            -- Bottom border
            LeaPlusLC:LoadVarNum("ViewPortLeft", 0, 0, 300)                -- Left border
            LeaPlusLC:LoadVarNum("ViewPortRight", 0, 0, 300)            -- Right border
            LeaPlusLC:LoadVarNum("ViewPortResizeTop", 0, 0, 300)        -- Resize top border
            LeaPlusLC:LoadVarNum("ViewPortResizeBottom", 0, 0, 300)        -- Resize bottom border
            LeaPlusLC:LoadVarNum("ViewPortAlpha", 0, 0, 0.9)            -- Border alpha
            LeaPlusLC:LoadVarNum("FullInvSound", 1, 0, 3)
            LeaPlusLC:LoadVarChk("SmallerErrorFrame", "Off")            -- Release in PvP Exclude Alterac Valley
            LeaPlusLC:LoadVarChk("FasterErrorFrame", "Off")            -- Release in PvP Exclude Alterac Valley


            LeaPlusLC:LoadVarChk("NoRestedEmotes", "Off")                -- Silence rested emotes
            --LeaPlusLC:LoadVarChk("MuteGameSounds", "Off")				-- Mute game sounds
            --LeaPlusLC:LoadVarChk("MuteCustomSounds", "Off")				-- Mute custom sounds
            --LeaPlusLC:LoadVarStr("MuteCustomList", "")					-- Mute custom sounds list

            LeaPlusLC:LoadVarChk("NoBagAutomation", "Off")                -- Disable bag automation
            --LeaPlusLC:LoadVarChk("CharAddonList", "Off")				-- Show character addons
            LeaPlusLC:LoadVarChk("NoConfirmLoot", "Off")                -- Disable loot warnings
            LeaPlusLC:LoadVarChk("FasterLooting", "Off")                -- Faster auto loot
            LeaPlusLC:LoadVarChk("FasterMovieSkip", "Off")                -- Faster movie skip
            --LeaPlusLC:LoadVarChk("StandAndDismount", "Off")				-- Dismount me
            LeaPlusLC:LoadVarChk("DismountNoResource", "On")            -- Dismount on resource error
            LeaPlusLC:LoadVarChk("DismountNoMoving", "On")                -- Dismount on moving
            LeaPlusLC:LoadVarChk("DismountNoTaxi", "On")                -- Dismount on flight map open
            LeaPlusLC:LoadVarChk("DismountShowFormBtn", "On")            -- Dismount cancel form button
            --LeaPlusLC:LoadVarChk("ShowVendorPrice", "Off")				-- Show vendor price
            LeaPlusLC:LoadVarChk("CombatPlates", "Off")                    -- Combat plates
            LeaPlusLC:LoadVarChk("EasyItemDestroy", "Off")                -- Easy item destroy

            -- Settings
            LeaPlusLC:LoadVarChk("ShowMinimapIcon", "On")                -- Show minimap button
            LeaPlusLC:LoadVarNum("PlusPanelScale", 1, 1, 2)                -- Panel scale
            LeaPlusLC:LoadVarNum("PlusPanelAlpha", 0, 0, 1)                -- Panel alpha

            -- Panel position
            LeaPlusLC:LoadVarAnc("MainPanelA", "CENTER")                -- Panel anchor
            LeaPlusLC:LoadVarAnc("MainPanelR", "CENTER")                -- Panel relative
            LeaPlusLC:LoadVarNum("MainPanelX", 0, -5000, 5000)            -- Panel X axis
            LeaPlusLC:LoadVarNum("MainPanelY", 0, -5000, 5000)            -- Panel Y axis

            -- Start page
            LeaPlusLC:LoadVarNum("LeaStartPage", 0, 0, LeaPlusLC["NumberOfPages"])

            -- Lock conflicting options
            do

                -- Function to disable and lock an option and add a note to the tooltip
                local function Lock(option, reason, optmodule)
                    LeaLockList[option] = LeaPlusLC[option]
                    LeaPlusLC:LockItem(LeaPlusCB[option], true)
                    LeaPlusCB[option].tiptext = LeaPlusCB[option].tiptext .. "|n|n|cff00AAFF" .. reason
                    if optmodule then
                        LeaPlusCB[option].tiptext = LeaPlusCB[option].tiptext .. " " .. optmodule .. " " .. L["module"]
                    end
                    LeaPlusCB[option].tiptext = LeaPlusCB[option].tiptext .. "."
                    -- Remove hover from configuration button if there is one
                    local temp = { LeaPlusCB[option]:GetChildren() }
                    if temp and temp[1] and temp[1].t and temp[1].t:GetTexture() == "Interface\\WorldMap\\Gear_64.png" then
                        temp[1]:SetHighlightTexture(0)
                        temp[1]:SetScript("OnEnter", nil)
                    end
                end

                -- Disable items that conflict with Glass
                if LeaPlusLC.Glass then
                    local reason = L["Cannot be used with Glass"]
                    Lock("UseEasyChatResizing", reason) -- Use easy resizing
                    Lock("NoCombatLogTab", reason) -- Hide the combat log
                    Lock("NoChatButtons", reason) -- Hide chat buttons
                    Lock("UnclampChat", reason) -- Unclamp chat frame
                    Lock("MoveChatEditBoxToTop", reason) -- Move editbox to top
                    Lock("MoreFontSizes", reason) --  More font sizes
                    Lock("NoChatFade", reason) --  Disable chat fade
                    Lock("ClassColorsInChat", reason) -- Use class colors in chat
                    Lock("RecentChatWindow", reason) -- Recent chat window
                end

                -- Disable items that conflict with ElvUI
                if LeaPlusLC.ElvUI then
                    local E = LeaPlusLC.ElvUI
                    if E and E.private then

                        local reason = L["Cannot be used with ElvUI"]

                        -- Chat
                        if E.private.chat.enable then
                            Lock("UseEasyChatResizing", reason, "Chat") -- Use easy resizing
                            Lock("NoCombatLogTab", reason, "Chat") -- Hide the combat log
                            Lock("NoChatButtons", reason, "Chat") -- Hide chat buttons
                            Lock("UnclampChat", reason, "Chat") -- Unclamp chat frame
                            Lock("MoreFontSizes", reason, "Chat") --  More font sizes
                            Lock("NoStickyChat", reason, "Chat") -- Disable sticky chat
                            Lock("UseArrowKeysInChat", reason, "Chat") -- Use arrow keys in chat
                            Lock("NoChatFade", reason, "Chat") -- Disable chat fade
                            Lock("MaxChatHstory", reason, "Chat") -- Increase chat history
                            Lock("RestoreChatMessages", reason, "Chat") -- Restore chat messages
                        end

                        if E.private.skins.blizzard.enable and E.private.skins.blizzard.tradeskill then
                            Lock("EnhanceProfessions", reason, "Interface")
                        end

                        -- Minimap
                        if E.private.general.minimap.enable then
                            Lock("MinimapModder", reason, "Minimap") -- Enhance minimap
                        end

                        -- -- UnitFrames
                        -- if E.private.unitframe.enable then
                        -- 	Lock("ShowRaidToggle", reason, "UnitFrames") -- Show raid button
                        -- end

                        -- ActionBars
                        if E.private.actionbar.enable then
                            Lock("NoGryphons", reason, "ActionBars") -- Hide gryphons
                            Lock("NoClassBar", reason, "ActionBars") -- Hide stance bar
                            Lock("HideKeybindText", reason, "ActionBars") -- Hide keybind text
                            Lock("HideMacroText", reason, "ActionBars") -- Hide macro text
                        end

                        -- Bags
                        if E.private.bags.enable then
                            Lock("NoBagAutomation", reason, "Bags") -- Disable bag automation
                            Lock("ShowBagSearchBox", reason, "Bags") -- Show bag search box
                        end

                        -- Tooltip
                        if E.private.tooltip.enable then
                            Lock("TipModEnable", reason, "Tooltip") -- Enhance tooltip
                        end

                        -- Buffs: Disable Blizzard
                        if E.private.auras.disableBlizzard then
                            Lock("ManageBuffs", reason, "Buffs and Debuffs (Disable Blizzard)") -- Manage buffs
                            Lock("ManageDeBuffs", reason, "Buffs and Debuffs (Disable Blizzard)") -- Manage buffs
                        end

                        -- UnitFrames: Disabled Blizzard: Focus
                        if E.private.unitframe.disabledBlizzardFrames.focus then
                            Lock("ManageFocus", reason, "UnitFrames (Disabled Blizzard Frames Focus)") -- Manage focus
                        end

                        -- UnitFrames: Disabled Blizzard: Player
                        if E.private.unitframe.disabledBlizzardFrames.player then
                            Lock("ShowPlayerChain", reason, "UnitFrames (Disabled Blizzard Frames Player)") -- Show player chain
                            Lock("NoHitIndicators", reason, "UnitFrames (Disabled Blizzard Frames Player)") -- Hide portrait numbers
                        end

                        -- UnitFrames: Disabled Blizzard: Player and Target
                        if E.private.unitframe.disabledBlizzardFrames.player or E.private.unitframe.disabledBlizzardFrames.target then
                            Lock("FrmEnabled", reason, "UnitFrames (Disabled Blizzard Frames Player and Target)") -- Manage frames
                        end

                        -- UnitFrames: Disabled Blizzard: Player, Target and Focus
                        if E.private.unitframe.disabledBlizzardFrames.player or E.private.unitframe.disabledBlizzardFrames.target or E.private.unitframe.disabledBlizzardFrames.focus then
                            Lock("ClassColFrames", reason, "UnitFrames (Disabled Blizzard Frames Player, Target and Focus)") -- Class-colored frames
                        end

                        -- Skins: Blizzard Gossip Frame
                        if E.private.skins.blizzard.enable and E.private.skins.blizzard.gossip then
                            Lock("QuestFontChange", reason, "Skins (Blizzard Gossip Frame)") -- Resize quest font
                        end

                        -- Base
                        do
                            Lock("ManageWidget", reason) -- Manage widget
                            Lock("ManageTimer", reason) -- Manage timer
                            Lock("ManageDurability", reason) -- Manage durability
                            Lock("ManageVehicle", reason) -- Manage vehicle
                            Lock("ManageTracker", reason) -- Manage tracker
                        end

                    end

                    EnableAddOn("Leatrix_Plus")
                end

            end

            -- Run other startup items
            LeaPlusLC:Live()
            LeaPlusLC:Isolated()
            LeaPlusLC:RunOnce()
            LeaPlusLC:SetDim()

        end
        return
    end

    if event == "PLAYER_LOGIN" then
        LeaPlusLC:Player()
        collectgarbage()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        LeaPlusLC:World()
        LpEvt:UnregisterEvent("PLAYER_ENTERING_WORLD")
        return
    end

    -- Save locals back to globals on logout
    if event == "PLAYER_LOGOUT" then

        -- Run the logout function without wipe flag
        LeaPlusLC:PlayerLogout(false)

        -- Automation
        LeaPlusDB["AutomateQuests"] = LeaPlusLC["AutomateQuests"]
        LeaPlusDB["AutoQuestShift"] = LeaPlusLC["AutoQuestShift"]
        LeaPlusDB["AutoQuestAvailable"] = LeaPlusLC["AutoQuestAvailable"]
        LeaPlusDB["AutoQuestCompleted"] = LeaPlusLC["AutoQuestCompleted"]
        LeaPlusDB["AutoQuestKeyMenu"] = LeaPlusLC["AutoQuestKeyMenu"]
        LeaPlusDB["AutomateGossip"] = LeaPlusLC["AutomateGossip"]
        LeaPlusDB["AutoAcceptSummon"] = LeaPlusLC["AutoAcceptSummon"]
        LeaPlusDB["AutoAcceptRes"] = LeaPlusLC["AutoAcceptRes"]
        LeaPlusDB["AutoResNoCombat"] = LeaPlusLC["AutoResNoCombat"]
        LeaPlusDB["AutoReleasePvP"] = LeaPlusLC["AutoReleasePvP"]
        LeaPlusDB["AutoSpiritRes"] = LeaPlusLC["AutoSpiritRes"]
        LeaPlusDB["AutoReleaseNoAlterac"] = LeaPlusLC["AutoReleaseNoAlterac"]
        LeaPlusDB["AutoReleaseDelay"] = LeaPlusLC["AutoReleaseDelay"]

        LeaPlusDB["AutoSellJunk"] = LeaPlusLC["AutoSellJunk"]
        LeaPlusDB["AutoSellShowSummary"] = LeaPlusLC["AutoSellShowSummary"]
        LeaPlusDB["AutoSellExcludeList"] = LeaPlusLC["AutoSellExcludeList"]
        LeaPlusDB["AutoRepairGear"] = LeaPlusLC["AutoRepairGear"]
        LeaPlusDB["AutoRepairGuildFunds"] = LeaPlusLC["AutoRepairGuildFunds"]
        LeaPlusDB["AutoRepairShowSummary"] = LeaPlusLC["AutoRepairShowSummary"]

        -- Social
        LeaPlusDB["NoDuelRequests"] = LeaPlusLC["NoDuelRequests"]
        LeaPlusDB["NoPartyInvites"] = LeaPlusLC["NoPartyInvites"]
        LeaPlusDB["NoGuildInvites"] = LeaPlusLC["NoGuildInvites"]
        -- LeaPlusDB["NoFriendRequests"]		= LeaPlusLC["NoFriendRequests"]
        LeaPlusDB["NoSharedQuests"] = LeaPlusLC["NoSharedQuests"]

        LeaPlusDB["AcceptPartyFriends"] = LeaPlusLC["AcceptPartyFriends"]
        LeaPlusDB["InviteFromWhisper"] = LeaPlusLC["InviteFromWhisper"]
        LeaPlusDB["InviteFriendsOnly"] = LeaPlusLC["InviteFriendsOnly"]
        LeaPlusDB["InvKey"] = LeaPlusLC["InvKey"]
        LeaPlusDB["FriendlyGuild"] = LeaPlusLC["FriendlyGuild"]

        -- Chat
        LeaPlusDB["UseEasyChatResizing"] = LeaPlusLC["UseEasyChatResizing"]
        LeaPlusDB["NoCombatLogTab"] = LeaPlusLC["NoCombatLogTab"]
        LeaPlusDB["NoChatButtons"] = LeaPlusLC["NoChatButtons"]
        LeaPlusDB["UnclampChat"] = LeaPlusLC["UnclampChat"]
        LeaPlusDB["MoveChatEditBoxToTop"] = LeaPlusLC["MoveChatEditBoxToTop"]
        LeaPlusDB["MoreFontSizes"] = LeaPlusLC["MoreFontSizes"]
        LeaPlusDB["AltClickInv"] = LeaPlusLC["AltClickInv"]

        LeaPlusDB["NoStickyChat"] = LeaPlusLC["NoStickyChat"]
        LeaPlusDB["UseArrowKeysInChat"] = LeaPlusLC["UseArrowKeysInChat"]
        LeaPlusDB["NoChatFade"] = LeaPlusLC["NoChatFade"]
        LeaPlusDB["UnivGroupColor"] = LeaPlusLC["UnivGroupColor"]
        LeaPlusDB["ClassColorsInChat"] = LeaPlusLC["ClassColorsInChat"]
        LeaPlusDB["RecentChatWindow"] = LeaPlusLC["RecentChatWindow"]
        LeaPlusDB["RecentChatSize"] = LeaPlusLC["RecentChatSize"]
        LeaPlusDB["MaxChatHstory"] = LeaPlusLC["MaxChatHstory"]
        LeaPlusDB["FilterChatMessages"] = LeaPlusLC["FilterChatMessages"]
        LeaPlusDB["BlockSpellLinks"] = LeaPlusLC["BlockSpellLinks"]
        LeaPlusDB["BlockDrunkenSpam"] = LeaPlusLC["BlockDrunkenSpam"]
        LeaPlusDB["BlockDuelSpam"] = LeaPlusLC["BlockDuelSpam"]
        LeaPlusDB["RestoreChatMessages"] = LeaPlusLC["RestoreChatMessages"]

        -- Text
        LeaPlusDB["HideErrorMessages"] = LeaPlusLC["HideErrorMessages"]
        LeaPlusDB["NoHitIndicators"] = LeaPlusLC["NoHitIndicators"]
        LeaPlusDB["HideZoneText"] = LeaPlusLC["HideZoneText"]
        LeaPlusDB["HideKeybindText"] = LeaPlusLC["HideKeybindText"]
        LeaPlusDB["HideMacroText"] = LeaPlusLC["HideMacroText"]

        LeaPlusDB["MailFontChange"] = LeaPlusLC["MailFontChange"]
        LeaPlusDB["LeaPlusMailFontSize"] = LeaPlusLC["LeaPlusMailFontSize"]

        LeaPlusDB["QuestFontChange"] = LeaPlusLC["QuestFontChange"]
        LeaPlusDB["LeaPlusQuestFontSize"] = LeaPlusLC["LeaPlusQuestFontSize"]

        LeaPlusDB["BookFontChange"] = LeaPlusLC["BookFontChange"]
        LeaPlusDB["LeaPlusBookFontSize"] = LeaPlusLC["LeaPlusBookFontSize"]

        -- Interface
        LeaPlusDB["MinimapModder"] = LeaPlusLC["MinimapModder"]
        LeaPlusDB["SquareMinimap"] = LeaPlusLC["SquareMinimap"]
        LeaPlusDB["ShowWhoPinged"] = LeaPlusLC["ShowWhoPinged"]
        LeaPlusDB["CombineAddonButtons"] = LeaPlusLC["CombineAddonButtons"]
        LeaPlusDB["MiniExcludeList"] = LeaPlusLC["MiniExcludeList"]
        LeaPlusDB["HideMiniZoomBtns"] = LeaPlusLC["HideMiniZoomBtns"]
        LeaPlusDB["HideMiniZoneText"] = LeaPlusLC["HideMiniZoneText"]
        LeaPlusDB["HideMiniAddonButtons"] = LeaPlusLC["HideMiniAddonButtons"]
        LeaPlusDB["HideMiniMapButton"] = LeaPlusLC["HideMiniMapButton"]
        LeaPlusDB["HideMiniTracking"] = LeaPlusLC["HideMiniTracking"]
        LeaPlusDB["HideMiniCalendar"] = LeaPlusLC["HideMiniCalendar"]
        LeaPlusDB["HideMiniPOIArrows"] = LeaPlusLC["HideMiniPOIArrows"]
        LeaPlusDB["ClockMouseover"] = LeaPlusLC["ClockMouseover"]
        LeaPlusDB["MinimapScale"] = LeaPlusLC["MinimapScale"]
        LeaPlusDB["MinimapSize"] = LeaPlusLC["MinimapSize"]
        LeaPlusDB["MiniClusterScale"] = LeaPlusLC["MiniClusterScale"]
        LeaPlusDB["MiniAddonPanelScale"] = LeaPlusLC["MiniAddonPanelScale"]
        LeaPlusDB["MinimapNoScale"] = LeaPlusLC["MinimapNoScale"]
        LeaPlusDB["MinimapA"] = LeaPlusLC["MinimapA"]
        LeaPlusDB["MinimapR"] = LeaPlusLC["MinimapR"]
        LeaPlusDB["MinimapX"] = LeaPlusLC["MinimapX"]
        LeaPlusDB["MinimapY"] = LeaPlusLC["MinimapY"]

        LeaPlusDB["TipModEnable"] = LeaPlusLC["TipModEnable"]
        LeaPlusDB["TipShowRank"] = LeaPlusLC["TipShowRank"]
        LeaPlusDB["TipShowOtherRank"] = LeaPlusLC["TipShowOtherRank"]
        LeaPlusDB["TipShowTarget"] = LeaPlusLC["TipShowTarget"]
        LeaPlusDB["TipHideInCombat"] = LeaPlusLC["TipHideInCombat"]
        LeaPlusDB["TipHideShiftOverride"] = LeaPlusLC["TipHideShiftOverride"]
        LeaPlusDB["TipNoHealthBar"] = LeaPlusLC["TipNoHealthBar"]
        LeaPlusDB["LeaPlusTipSize"] = LeaPlusLC["LeaPlusTipSize"]
        LeaPlusDB["TipOffsetX"] = LeaPlusLC["TipOffsetX"]
        LeaPlusDB["TipOffsetY"] = LeaPlusLC["TipOffsetY"]
        LeaPlusDB["TooltipAnchorMenu"] = LeaPlusLC["TooltipAnchorMenu"]
        LeaPlusDB["MiniMapMailIconPos"] = LeaPlusLC["MiniMapMailIconPos"]
        LeaPlusDB["MiniMapLFGIconPos"] = LeaPlusLC["MiniMapLFGIconPos"]
        LeaPlusDB["MiniMapBattlefieldIconPos"] = LeaPlusLC["MiniMapBattlefieldIconPos"]
        LeaPlusDB["TipCursorX"] = LeaPlusLC["TipCursorX"]
        LeaPlusDB["TipCursorY"] = LeaPlusLC["TipCursorY"]

        LeaPlusDB["EnhanceDressup"] = LeaPlusLC["EnhanceDressup"]
        LeaPlusDB["DressupItemButtons"] = LeaPlusLC["DressupItemButtons"]
        LeaPlusDB["DressupAnimControl"] = LeaPlusLC["DressupAnimControl"]
        LeaPlusDB["HideDressupStats"] = LeaPlusLC["HideDressupStats"]
        LeaPlusDB["EnhanceQuestLog"] = LeaPlusLC["EnhanceQuestLog"]
        LeaPlusDB["EnhanceQuestHeaders"] = LeaPlusLC["EnhanceQuestHeaders"]
        LeaPlusDB["EnhanceQuestLevels"] = LeaPlusLC["EnhanceQuestLevels"]
        LeaPlusDB["EnhanceQuestDifficulty"] = LeaPlusLC["EnhanceQuestDifficulty"]

        LeaPlusDB["EnhanceProfessions"] = LeaPlusLC["EnhanceProfessions"]
        LeaPlusDB["EnhanceTrainers"] = LeaPlusLC["EnhanceTrainers"]
        LeaPlusDB["ShowTrainAllBtn"] = LeaPlusLC["ShowTrainAllBtn"]

        LeaPlusDB["ShowVolume"] = LeaPlusLC["ShowVolume"]
        LeaPlusDB["AhExtras"] = LeaPlusLC["AhExtras"]
        LeaPlusDB["AhBuyoutOnly"] = LeaPlusLC["AhBuyoutOnly"]
        LeaPlusDB["AhGoldOnly"] = LeaPlusLC["AhGoldOnly"]
        LeaPlusDB["AhTabConfirm"] = LeaPlusLC["AhTabConfirm"]

        -- LeaPlusDB["ShowCooldowns"]			= LeaPlusLC["ShowCooldowns"]
        -- LeaPlusDB["ShowCooldownID"]			= LeaPlusLC["ShowCooldownID"]
        -- LeaPlusDB["NoCooldownDuration"]		= LeaPlusLC["NoCooldownDuration"]
        -- LeaPlusDB["CooldownsOnPlayer"]		= LeaPlusLC["CooldownsOnPlayer"]
        LeaPlusDB["DurabilityStatus"] = LeaPlusLC["DurabilityStatus"]
        LeaPlusDB["ShowVanityControls"] = LeaPlusLC["ShowVanityControls"]
        LeaPlusDB["VanityAltLayout"] = LeaPlusLC["VanityAltLayout"]
        LeaPlusDB["ShowBagSearchBox"] = LeaPlusLC["ShowBagSearchBox"]
        -- LeaPlusDB["ShowRaidToggle"]			= LeaPlusLC["ShowRaidToggle"]
        LeaPlusDB["ShowPlayerChain"] = LeaPlusLC["ShowPlayerChain"]
        LeaPlusDB["PlayerChainMenu"] = LeaPlusLC["PlayerChainMenu"]
        LeaPlusDB["ShowReadyTimer"] = LeaPlusLC["ShowReadyTimer"]
        LeaPlusDB["ShowWowheadLinks"] = LeaPlusLC["ShowWowheadLinks"]
        LeaPlusDB["WowheadLinkComments"] = LeaPlusLC["WowheadLinkComments"]

        LeaPlusDB["ShowFlightTimes"] = LeaPlusLC["ShowFlightTimes"]
        LeaPlusDB["FlightBarBackground"] = LeaPlusLC["FlightBarBackground"]
        LeaPlusDB["FlightBarDestination"] = LeaPlusLC["FlightBarDestination"]
        LeaPlusDB["FlightBarFillBar"] = LeaPlusLC["FlightBarFillBar"]
        LeaPlusDB["FlightBarSpeech"] = LeaPlusLC["FlightBarSpeech"]

        LeaPlusDB["FlightBarContribute"] = LeaPlusLC["FlightBarContribute"]
        LeaPlusDB["FlightBarA"] = LeaPlusLC["FlightBarA"]
        LeaPlusDB["FlightBarR"] = LeaPlusLC["FlightBarR"]
        LeaPlusDB["FlightBarX"] = LeaPlusLC["FlightBarX"]
        LeaPlusDB["FlightBarY"] = LeaPlusLC["FlightBarY"]
        LeaPlusDB["FlightBarScale"] = LeaPlusLC["FlightBarScale"]
        LeaPlusDB["FlightBarWidth"] = LeaPlusLC["FlightBarWidth"]

        -- Frames
        LeaPlusDB["FrmEnabled"] = LeaPlusLC["FrmEnabled"]

        LeaPlusDB["ManageBuffs"] = LeaPlusLC["ManageBuffs"]
        LeaPlusDB["BuffFrameA"] = LeaPlusLC["BuffFrameA"]
        LeaPlusDB["BuffFrameR"] = LeaPlusLC["BuffFrameR"]
        LeaPlusDB["BuffFrameX"] = LeaPlusLC["BuffFrameX"]
        LeaPlusDB["BuffFrameY"] = LeaPlusLC["BuffFrameY"]
        LeaPlusDB["BuffFrameScale"] = LeaPlusLC["BuffFrameScale"]

        LeaPlusDB["ManageDeBuffs"] = LeaPlusLC["ManageDeBuffs"]
        LeaPlusDB["DebuffButton1A"] = LeaPlusLC["DebuffButton1A"]
        LeaPlusDB["DebuffButton1R"] = LeaPlusLC["DebuffButton1R"]
        LeaPlusDB["DebuffButton1X"] = LeaPlusLC["DebuffButton1X"]
        LeaPlusDB["DebuffButton1Y"] = LeaPlusLC["DebuffButton1Y"]
        LeaPlusDB["DebuffButton1Scale"] = LeaPlusLC["DebuffButton1Scale"]

        LeaPlusDB["ManageWidget"] = LeaPlusLC["ManageWidget"]
        LeaPlusDB["WidgetA"] = LeaPlusLC["WidgetA"]
        LeaPlusDB["WidgetR"] = LeaPlusLC["WidgetR"]
        LeaPlusDB["WidgetX"] = LeaPlusLC["WidgetX"]
        LeaPlusDB["WidgetY"] = LeaPlusLC["WidgetY"]
        LeaPlusDB["WidgetScale"] = LeaPlusLC["WidgetScale"]

        LeaPlusDB["ManageFocus"] = LeaPlusLC["ManageFocus"]
        LeaPlusDB["FocusA"] = LeaPlusLC["FocusA"]
        LeaPlusDB["FocusR"] = LeaPlusLC["FocusR"]
        LeaPlusDB["FocusX"] = LeaPlusLC["FocusX"]
        LeaPlusDB["FocusY"] = LeaPlusLC["FocusY"]
        LeaPlusDB["FocusScale"] = LeaPlusLC["FocusScale"]

        LeaPlusDB["ManageTimer"] = LeaPlusLC["ManageTimer"]
        LeaPlusDB["TimerA"] = LeaPlusLC["TimerA"]
        LeaPlusDB["TimerR"] = LeaPlusLC["TimerR"]
        LeaPlusDB["TimerX"] = LeaPlusLC["TimerX"]
        LeaPlusDB["TimerY"] = LeaPlusLC["TimerY"]
        LeaPlusDB["TimerScale"] = LeaPlusLC["TimerScale"]

        LeaPlusDB["ManageDurability"] = LeaPlusLC["ManageDurability"]
        LeaPlusDB["DurabilityA"] = LeaPlusLC["DurabilityA"]
        LeaPlusDB["DurabilityR"] = LeaPlusLC["DurabilityR"]
        LeaPlusDB["DurabilityX"] = LeaPlusLC["DurabilityX"]
        LeaPlusDB["DurabilityY"] = LeaPlusLC["DurabilityY"]
        LeaPlusDB["DurabilityScale"] = LeaPlusLC["DurabilityScale"]

        LeaPlusDB["CombineAddonsFrameA"] = LeaPlusLC["CombineAddonsFrameA"]
        LeaPlusDB["CombineAddonsFrameR"] = LeaPlusLC["CombineAddonsFrameR"]
        LeaPlusDB["CombineAddonsFrameX"] = LeaPlusLC["CombineAddonsFrameX"]
        LeaPlusDB["CombineAddonsFrameY"] = LeaPlusLC["CombineAddonsFrameY"]
        --LeaPlusDB["CombineAddonsFrameScale"]		= LeaPlusLC["CombineAddonsFrameScale"]

        LeaPlusDB["ManageVehicle"] = LeaPlusLC["ManageVehicle"]
        LeaPlusDB["VehicleA"] = LeaPlusLC["VehicleA"]
        LeaPlusDB["VehicleR"] = LeaPlusLC["VehicleR"]
        LeaPlusDB["VehicleX"] = LeaPlusLC["VehicleX"]
        LeaPlusDB["VehicleY"] = LeaPlusLC["VehicleY"]
        LeaPlusDB["VehicleScale"] = LeaPlusLC["VehicleScale"]

        LeaPlusDB["ManageTracker"] = LeaPlusLC["ManageTracker"]
        LeaPlusDB["TrackerA"] = LeaPlusLC["TrackerA"]
        LeaPlusDB["TrackerR"] = LeaPlusLC["TrackerR"]
        LeaPlusDB["TrackerX"] = LeaPlusLC["TrackerX"]
        LeaPlusDB["TrackerY"] = LeaPlusLC["TrackerY"]
        LeaPlusDB["TrackerScale"] = LeaPlusLC["TrackerScale"]

        LeaPlusDB["ClassColFrames"] = LeaPlusLC["ClassColFrames"]
        LeaPlusDB["ClassColPlayer"] = LeaPlusLC["ClassColPlayer"]
        LeaPlusDB["ClassColTarget"] = LeaPlusLC["ClassColTarget"]

        LeaPlusDB["NoAlerts"] = LeaPlusLC["NoAlerts"]
        LeaPlusDB["NoGryphons"] = LeaPlusLC["NoGryphons"]
        LeaPlusDB["NoClassBar"] = LeaPlusLC["NoClassBar"]

        -- System
        LeaPlusDB["NoScreenGlow"] = LeaPlusLC["NoScreenGlow"]
        LeaPlusDB["NoScreenEffects"] = LeaPlusLC["NoScreenEffects"]
        LeaPlusDB["SetWeatherDensity"] = LeaPlusLC["SetWeatherDensity"]
        LeaPlusDB["WeatherLevel"] = LeaPlusLC["WeatherLevel"]
        LeaPlusDB["MaxCameraZoom"] = LeaPlusLC["MaxCameraZoom"]
        LeaPlusDB["ViewPortEnable"] = LeaPlusLC["ViewPortEnable"]
        LeaPlusDB["ViewPortTop"] = LeaPlusLC["ViewPortTop"]
        LeaPlusDB["ViewPortBottom"] = LeaPlusLC["ViewPortBottom"]
        LeaPlusDB["ViewPortLeft"] = LeaPlusLC["ViewPortLeft"]
        LeaPlusDB["ViewPortRight"] = LeaPlusLC["ViewPortRight"]
        LeaPlusDB["ViewPortResizeTop"] = LeaPlusLC["ViewPortResizeTop"]
        LeaPlusDB["ViewPortResizeBottom"] = LeaPlusLC["ViewPortResizeBottom"]
        LeaPlusDB["ViewPortAlpha"] = LeaPlusLC["ViewPortAlpha"]
        LeaPlusDB["FullInvSound"] = LeaPlusLC["FullInvSound"]
        LeaPlusDB["SmallerErrorFrame"] = LeaPlusLC["SmallerErrorFrame"]
        LeaPlusDB["FasterErrorFrame"] = LeaPlusLC["SmallerErrorFrame"]

        LeaPlusDB["NoRestedEmotes"] = LeaPlusLC["NoRestedEmotes"]
        LeaPlusDB["MuteGameSounds"] = LeaPlusLC["MuteGameSounds"]
        --LeaPlusDB["MuteCustomSounds"]		= LeaPlusLC["MuteCustomSounds"]
        --LeaPlusDB["MuteCustomList"]			= LeaPlusLC["MuteCustomList"]

        LeaPlusDB["NoBagAutomation"] = LeaPlusLC["NoBagAutomation"]
        --LeaPlusDB["CharAddonList"]			= LeaPlusLC["CharAddonList"]
        LeaPlusDB["NoConfirmLoot"] = LeaPlusLC["NoConfirmLoot"]
        LeaPlusDB["FasterLooting"] = LeaPlusLC["FasterLooting"]
        LeaPlusDB["FasterMovieSkip"] = LeaPlusLC["FasterMovieSkip"]
        --LeaPlusDB["StandAndDismount"] 		= LeaPlusLC["StandAndDismount"]
        LeaPlusDB["DismountNoResource"] = LeaPlusLC["DismountNoResource"]
        LeaPlusDB["DismountNoMoving"] = LeaPlusLC["DismountNoMoving"]
        LeaPlusDB["DismountNoTaxi"] = LeaPlusLC["DismountNoTaxi"]
        LeaPlusDB["DismountShowFormBtn"] = LeaPlusLC["DismountShowFormBtn"]
        --LeaPlusDB["ShowVendorPrice"] 		= LeaPlusLC["ShowVendorPrice"]
        LeaPlusDB["CombatPlates"] = LeaPlusLC["CombatPlates"]
        LeaPlusDB["EasyItemDestroy"] = LeaPlusLC["EasyItemDestroy"]

        -- Settings
        LeaPlusDB["ShowMinimapIcon"] = LeaPlusLC["ShowMinimapIcon"]
        LeaPlusDB["PlusPanelScale"] = LeaPlusLC["PlusPanelScale"]
        LeaPlusDB["PlusPanelAlpha"] = LeaPlusLC["PlusPanelAlpha"]

        -- Panel position
        LeaPlusDB["MainPanelA"] = LeaPlusLC["MainPanelA"]
        LeaPlusDB["MainPanelR"] = LeaPlusLC["MainPanelR"]
        LeaPlusDB["MainPanelX"] = LeaPlusLC["MainPanelX"]
        LeaPlusDB["MainPanelY"] = LeaPlusLC["MainPanelY"]

        -- Start page
        LeaPlusDB["LeaStartPage"] = LeaPlusLC["LeaStartPage"]

        -- Mute game sounds (LeaPlusLC["MuteGameSounds"])
        --for k, v in pairs(LeaPlusLC["muteTable"]) do
        --	LeaPlusDB[k] = LeaPlusLC[k]
        --end

    end

end

--	Register event handler
LpEvt:SetScript("OnEvent", eventHandler);

----------------------------------------------------------------------
--	L70: Player logout
----------------------------------------------------------------------

-- Player Logout
function LeaPlusLC:PlayerLogout(wipe)

    ----------------------------------------------------------------------
    -- Restore default values for options that do not require reloads
    ----------------------------------------------------------------------

    if wipe then

        -- Disable screen glow (LeaPlusLC["NoScreenGlow"])
        SetCVar("ffxGlow", "1")

        -- Disable screen effects (LeaPlusLC["NoScreenEffects"])
        SetCVar("ffxDeath", "1")
        SetCVar("ffxNetherWorld", "1")

        -- Set weather density (LeaPlusLC["SetWeatherDensity"])
        SetCVar("weatherDensity", "3")
        --SetCVar("RAIDweatherDensity", "3")

        -- Max camera zoom (LeaPlusLC["MaxCameraZoom"])
        SetCVar("cameraDistanceMaxFactor", 1.9)

        -- Universal group color (LeaPlusLC["UnivGroupColor"])
        ChangeChatColor("RAID", 1, 0.50, 0)
        ChangeChatColor("RAID_LEADER", 1, 0.28, 0.04)

        -- -- Use class colors in chat (LeaPlusLC["ClassColorsInChat"])
        -- SetCVar("chatClassColorOverride", "1")

        -- Mute game sounds (LeaPlusLC["MuteGameSounds"])
        --for k, v in pairs(LeaPlusLC["muteTable"]) do
        --	for i, e in pairs(v) do
        --		local file, soundID = e:match("([^,]+)%#([^,]+)")
        --		UnmuteSoundFile(soundID)
        --	end
        --end

    end

    ----------------------------------------------------------------------
    -- Restore default values for options that require reloads
    ----------------------------------------------------------------------

    -- Use class colors
    if LeaPlusDB["ClassColorsInChat"] == "On" then
        if wipe or (not wipe and LeaPlusLC["ClassColorsInChat"] == "Off") and not LeaLockList["ClassColorsInChat"] then
            -- Restore local channel color
            for i = 1, 18 do
                if _G["ChatConfigChatSettingsLeftCheckBox" .. i .. "Check"] then
                    ToggleChatColorNamesByClassGroup(false, _G["ChatConfigChatSettingsLeftCheckBox" .. i .. "Check"]:GetParent().type)
                end
            end
            -- Restore global channel color
            for i = 1, 50 do
                ToggleChatColorNamesByClassGroup(false, "CHANNEL" .. i)
            end
        end
    end

    -- Enhance minimap restore round minimap if wipe or enhance minimap is toggled off
    if LeaPlusDB["MinimapModder"] == "On" and LeaPlusDB["SquareMinimap"] == "On" and not LeaLockList["MinimapModder"] then
        if wipe or (not wipe and LeaPlusLC["MinimapModder"] == "Off") then
            Minimap:SetMaskTexture([[Interface\CharacterFrame\TempPortraitAlphaMask]])
        end
    end

    -- Silence rested emotes
    if LeaPlusDB["NoRestedEmotes"] == "On" then
        if wipe or (not wipe and LeaPlusLC["NoRestedEmotes"] == "Off") then
            SetCVar("Sound_EnableEmoteSounds", "1")
        end
    end

    -- More font sizes
    if LeaPlusDB["MoreFontSizes"] == "On" and not LeaLockList["MoreFontSizes"] then
        if wipe or (not wipe and LeaPlusLC["MoreFontSizes"] == "Off") then
            RunScript('for i = 1, 50 do if _G["ChatFrame" .. i] then local void, fontSize = FCF_GetChatWindowInfo(i); if fontSize and fontSize ~= 12 and fontSize ~= 14 and fontSize ~= 16 and fontSize ~= 18 then FCF_SetChatWindowFontSize(self, _G["ChatFrame" .. i], CHAT_FRAME_DEFAULT_FONT_SIZE) end end end')
        end
    end

    ----------------------------------------------------------------------
    -- Do other stuff during logout
    ----------------------------------------------------------------------

    -- Store the auction house duration and price type values if auction house option is enabled
    if LeaPlusDB["AhExtras"] == "On" then
        if AuctionFrameAuctions then
            if AuctionFrameAuctions.duration then
                LeaPlusDB["AHDuration"] = AuctionFrameAuctions.duration
            end
        end
    end

end

----------------------------------------------------------------------
-- 	Options panel functions
----------------------------------------------------------------------

-- Function to add textures to panels
function LeaPlusLC:CreateBar(name, parent, width, height, anchor, r, g, b, alp, tex)
    local ft = parent:CreateTexture(nil, "BORDER")
    ft:SetTexture(tex)
    ft:SetSize(width, height)
    ft:SetPoint(anchor)
    ft:SetVertexColor(r, g, b, alp)
    if name == "MainTexture" then
        ft:SetTexCoord(0.09, 1, 0, 1);
    end
end

-- Create a configuration panel
function LeaPlusLC:CreatePanel(title, globref)

    -- Create the panel
    local Side = CreateFrame("Frame", nil, UIParent)

    -- Make it a system frame
    _G["LeaPlusGlobalPanel_" .. globref] = Side
    table.insert(UISpecialFrames, "LeaPlusGlobalPanel_" .. globref)

    -- Store it in the configuration panel table
    tinsert(LeaConfigList, Side)

    -- Set frame parameters
    Side:Hide();
    Side:SetSize(570, 370);
    Side:SetClampedToScreen(true)
    Side:SetClampRectInsets(500, -500, -300, 300)
    Side:SetFrameStrata("FULLSCREEN_DIALOG")

    -- Set the background color
    Side.t = Side:CreateTexture(nil, "BACKGROUND")
    Side.t:SetAllPoints()
    Side.t:SetTexture(0.05, 0.05, 0.05, 0.9)

    -- Add a close Button
    Side.c = CreateFrame("Button", nil, Side, "UIPanelCloseButton")
    Side.c:SetSize(30, 30)
    Side.c:SetPoint("TOPRIGHT", 0, 0)
    Side.c:SetScript("OnClick", function()
        Side:Hide()
    end)

    -- Add reset, help and back buttons
    Side.r = LeaPlusLC:CreateButton("ResetButton", Side, "Reset", "TOPLEFT", 16, -292, 0, 25, true, "Click to reset the settings on this page.")
    Side.h = LeaPlusLC:CreateButton("HelpButton", Side, "Help", "TOPLEFT", 76, -292, 0, 25, true, "No help is available for this page.")
    Side.b = LeaPlusLC:CreateButton("BackButton", Side, "Back to Main Menu", "TOPRIGHT", -16, -292, 0, 25, true, "Click to return to the main menu.")

    -- Reposition help button so it doesn't overlap reset button
    Side.h:ClearAllPoints()
    Side.h:SetPoint("LEFT", Side.r, "RIGHT", 10, 0)

    -- Remove the click texture from the help button
    Side.h:SetPushedTextOffset(0, 0)

    -- Add a reload button and syncronise it with the main panel reload button
    local reloadb = LeaPlusLC:CreateButton("ConfigReload", Side, "Reload", "BOTTOMRIGHT", -16, 10, 0, 25, true, LeaPlusCB["ReloadUIButton"].tiptext)
    LeaPlusLC:LockItem(reloadb, true)
    reloadb:SetScript("OnClick", ReloadUI)

    reloadb.f = reloadb:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
    reloadb.f:SetHeight(32);
    reloadb.f:SetPoint('RIGHT', reloadb, 'LEFT', -10, 0)
    reloadb.f:SetText(LeaPlusCB["ReloadUIButton"].f:GetText())
    reloadb.f:Hide()

    LeaPlusCB["ReloadUIButton"]:HookScript("OnEnable", function()
        LeaPlusLC:LockItem(reloadb, false)
        reloadb.f:Show()
    end)

    LeaPlusCB["ReloadUIButton"]:HookScript("OnDisable", function()
        LeaPlusLC:LockItem(reloadb, true)
        reloadb.f:Hide()
    end)

    -- Set textures
    LeaPlusLC:CreateBar("FootTexture", Side, 570, 48, "BOTTOM", 0.5, 0.5, 0.5, 1.0, "Interface\\addons\\Leatrix_Plus\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")
    LeaPlusLC:CreateBar("MainTexture", Side, 570, 323, "TOPRIGHT", 0.7, 0.7, 0.7, 0.9, "Interface\\addons\\Leatrix_Plus\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")

    -- Allow movement
    Side:EnableMouse(true)
    Side:SetMovable(true)
    Side:RegisterForDrag("LeftButton")
    Side:SetScript("OnDragStart", Side.StartMoving)
    Side:SetScript("OnDragStop", function()
        Side:StopMovingOrSizing();
        Side:SetUserPlaced(false);
        -- Save panel position
        LeaPlusLC["MainPanelA"], void, LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = Side:GetPoint()
    end)

    -- Set panel attributes when shown
    Side:SetScript("OnShow", function()
        Side:ClearAllPoints()
        Side:SetPoint(LeaPlusLC["MainPanelA"], UIParent, LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"])
        Side:SetScale(LeaPlusLC["PlusPanelScale"])
        Side.t:SetAlpha(1 - LeaPlusLC["PlusPanelAlpha"])
    end)

    -- Add title
    Side.f = Side:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
    Side.f:SetPoint('TOPLEFT', 16, -16);
    Side.f:SetText(L[title])

    -- Add description
    Side.v = Side:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
    Side.v:SetHeight(32);
    Side.v:SetPoint('TOPLEFT', Side.f, 'BOTTOMLEFT', 0, -8);
    Side.v:SetPoint('RIGHT', Side, -32, 0)
    Side.v:SetJustifyH('LEFT');
    Side.v:SetJustifyV('TOP');
    Side.v:SetText(L["Configuration Panel"])

    -- Prevent options panel from showing while side panel is showing
    LeaPlusLC["PageF"]:HookScript("OnShow", function()
        if Side:IsShown() then
            LeaPlusLC["PageF"]:Hide();
        end
    end)

    -- Return the frame
    return Side

end

-- Define subheadings
function LeaPlusLC:MakeTx(frame, title, x, y)
    local text = frame:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    text:SetPoint("TOPLEFT", x, y)
    text:SetText(L[title])
    return text
end

-- Define text
function LeaPlusLC:MakeWD(frame, title, x, y)
    local text = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    text:SetPoint("TOPLEFT", x, y)
    text:SetText(L[title])
    text:SetJustifyH "LEFT";
    return text
end

-- Create a slider control (uses standard template)
function LeaPlusLC:MakeSL(frame, field, caption, low, high, step, x, y, form)

    -- Create slider control
    local Slider = CreateFrame("Slider", "LeaPlusGlobalSlider" .. field, frame, "OptionssliderTemplate")
    LeaPlusCB[field] = Slider;
    Slider:SetMinMaxValues(low, high)
    Slider:SetValueStep(step)
    Slider:EnableMouseWheel(true)
    Slider:SetPoint('TOPLEFT', x, y)
    Slider:SetWidth(100)
    Slider:SetHeight(20)
    Slider:SetHitRectInsets(0, 0, 0, 0);
    Slider.tiptext = L[caption]
    Slider:SetScript("OnEnter", LeaPlusLC.TipSee)
    Slider:SetScript("OnLeave", GameTooltip_Hide)

    -- Remove slider text
    _G[Slider:GetName() .. "Low"]:SetText('');
    _G[Slider:GetName() .. "High"]:SetText('');

    -- Create slider label
    Slider.f = Slider:CreateFontString(nil, 'BACKGROUND')
    Slider.f:SetFontObject('GameFontHighlight')
    Slider.f:SetPoint('LEFT', Slider, 'RIGHT', 12, 0)
    Slider.f:SetFormattedText("%.2f", Slider:GetValue())

    -- Process mousewheel scrolling
    Slider:SetScript("OnMouseWheel", function(self, arg1)
        if Slider:IsEnabled() then
            local step = step * arg1
            local value = self:GetValue()
            if step > 0 then
                self:SetValue(min(value + step, high))
            else
                self:SetValue(max(value + step, low))
            end
        end
    end)

    -- Process value changed
    Slider:SetScript("OnValueChanged", function(self, value)
        local value = floor((value - low) / step + 0.5) * step + low
        Slider.f:SetFormattedText(form, value)
        LeaPlusLC[field] = value
    end)

    -- Set slider value when shown
    Slider:SetScript("OnShow", function(self)
        self:SetValue(LeaPlusLC[field])
    end)

end

-- Create a checkbox control (uses standard template)
function LeaPlusLC:MakeCB(parent, field, caption, x, y, reload, tip, extratip)

    -- Create the checkbox
    local Cbox = CreateFrame('CheckButton', nil, parent, "ChatConfigCheckButtonTemplate")
    LeaPlusCB[field] = Cbox
    Cbox:SetPoint("TOPLEFT", x, y)
    Cbox:SetScript("OnEnter", LeaPlusLC.TipSee)
    Cbox:SetScript("OnLeave", GameTooltip_Hide)

    -- Add label and tooltip
    Cbox.f = Cbox:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    Cbox.f:SetPoint('LEFT', 23, 0)
    local tooltipText = L[tip]
    -- Add extra tip if provided
    if extratip and extratip ~= "" then
        tooltipText = tooltipText .. "|n|n" .. L[extratip]
    end

    -- Add indicator and text if UI reload is required
    if reload then
        -- Checkbox requires UI reload
        Cbox.f:SetText(L[caption] .. "*")
        tooltipText = tooltipText .. "|n|n* " .. L["Requires UI reload."]
    else
        -- Checkbox does not require UI reload
        Cbox.f:SetText(L[caption])
    end

    -- Set the tooltip text
    Cbox.tiptext = tooltipText

    -- Set label parameters
    Cbox.f:SetJustifyH("LEFT")
    Cbox.f:SetWordWrap(false)

    -- Set maximum label width
    if parent:GetParent() == LeaPlusLC["PageF"] then
        -- Main panel checkbox labels
        if Cbox.f:GetWidth() > 152 then
            Cbox.f:SetWidth(152)
            LeaPlusLC["TruncatedLabelsList"] = LeaPlusLC["TruncatedLabelsList"] or {}
            LeaPlusLC["TruncatedLabelsList"][Cbox.f] = L[caption]
        end
        -- Set checkbox click width
        if Cbox.f:GetStringWidth() > 152 then
            Cbox:SetHitRectInsets(0, -142, 0, 0)
        else
            Cbox:SetHitRectInsets(0, -Cbox.f:GetStringWidth() + 4, 0, 0)
        end
    else
        -- Configuration panel checkbox labels (other checkboxes either have custom functions or blank labels)
        if Cbox.f:GetWidth() > 302 then
            Cbox.f:SetWidth(302)
            LeaPlusLC["TruncatedLabelsList"] = LeaPlusLC["TruncatedLabelsList"] or {}
            LeaPlusLC["TruncatedLabelsList"][Cbox.f] = L[caption]
        end
        -- Set checkbox click width
        if Cbox.f:GetStringWidth() > 302 then
            Cbox:SetHitRectInsets(0, -292, 0, 0)
        else
            Cbox:SetHitRectInsets(0, -Cbox.f:GetStringWidth() + 4, 0, 0)
        end
    end

    -- Set default checkbox state and click area
    Cbox:SetScript('OnShow', function(self)
        if LeaPlusLC[field] == "On" then
            self:SetChecked(true)
        else
            self:SetChecked(false)
        end
    end)

    -- Process clicks
    Cbox:SetScript('OnClick', function()
        if Cbox:GetChecked() then
            LeaPlusLC[field] = "On"
        else
            LeaPlusLC[field] = "Off"
        end
        LeaPlusLC:SetDim(); -- Lock invalid options
        LeaPlusLC:ReloadCheck(); -- Show reload button if needed
        LeaPlusLC:Live(); -- Run live code
    end)
end

-- Create an editbox (uses standard template)
function LeaPlusLC:CreateEditBox(frame, parent, width, maxchars, anchor, x, y, tab, shifttab)

    -- Create editbox
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    LeaPlusCB[frame] = eb
    eb:SetPoint(anchor, x, y)
    eb:SetWidth(width)
    eb:SetHeight(24)
    eb:SetFontObject("GameFontNormal")
    eb:SetTextColor(1.0, 1.0, 1.0)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(maxchars)
    eb:SetScript("OnEscapePressed", eb.ClearFocus)
    eb:SetScript("OnEnterPressed", eb.ClearFocus)
    eb:DisableDrawLayer("BACKGROUND")

    -- Add editbox border and backdrop
    eb.f = CreateFrame("FRAME", nil, eb)
    eb.f:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 } })
    eb.f:SetPoint("LEFT", -6, 0)
    eb.f:SetWidth(eb:GetWidth() + 6)
    eb.f:SetHeight(eb:GetHeight())
    eb.f:SetBackdropColor(1.0, 1.0, 1.0, 0.3)

    -- Move onto next editbox when tab key is pressed
    eb:SetScript("OnTabPressed", function(self)
        self:ClearFocus()
        if IsShiftKeyDown() then
            LeaPlusCB[shifttab]:SetFocus()
        else
            LeaPlusCB[tab]:SetFocus()
        end
    end)

    return eb

end

--===== Bottom left button web link =====--

-- Create a standard button (using standard button template)
function LeaPlusLC:CreateButton(name, frame, label, anchor, x, y, width, height, reskin, tip, naked)
    local mbtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    LeaPlusCB[name] = mbtn
    mbtn:SetSize(width, height)
    mbtn:SetPoint(anchor, x, y)
    mbtn:SetHitRectInsets(0, 0, 0, 0)
    mbtn:SetText(L[label])

    -- Create fontstring so the button can be sized correctly
    mbtn.f = mbtn:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    mbtn.f:SetText(L[label])
    if width > 0 then
        -- Button should have static width
        mbtn:SetWidth(width)
    else
        -- Button should have variable width
        mbtn:SetWidth(mbtn.f:GetStringWidth() + 20)
    end

    -- Tooltip handler
    mbtn.tiptext = L[tip]
    mbtn:SetScript("OnEnter", LeaPlusLC.TipSee)
    mbtn:SetScript("OnLeave", GameTooltip_Hide)

    -- Texture the button
    if reskin then

        -- Set skinned button textures
        if not naked then
            mbtn:SetNormalTexture("Interface\\AddOns\\Leatrix_Plus\\LeatrixPlus.blp")
            if mbtn:GetNormalTexture() then
                mbtn:GetNormalTexture():SetTexCoord(0.125, 0.25, 0.4375, 0.5)
            end
        end
        mbtn:SetHighlightTexture("Interface\\AddOns\\Leatrix_Plus\\LeatrixPlus.blp")
        mbtn:GetHighlightTexture():SetTexCoord(0, 0.125, 0.4375, 0.5)

        -- Hide the default textures
        -- mbtn:HookScript("OnShow", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
        -- mbtn:HookScript("OnEnable", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
        -- mbtn:HookScript("OnDisable", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
        -- mbtn:HookScript("OnMouseDown", function() mbtn:GetPushedTexture():Hide() end)
        -- mbtn:HookScript("OnMouseUp", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)


        --===== 3.3.5 texture disables =====--

        -- mbtn:GetNormalTexture():SetTexture(nil)
        if mbtn:GetPushedTexture() then
            mbtn:GetPushedTexture():SetTexture(nil)
        end
        -- mbtn:GetDisabledTexture():SetTexture(nil)
        -- mbtn:GetHighlightTexture():SetTexture(nil)

    end

    return mbtn
end

-- Create a dropdown menu (using custom function to avoid taint)
function LeaPlusLC:CreateDropDown(ddname, label, parent, width, anchor, x, y, items, tip)

    -- Add the dropdown name to a table
    tinsert(LeaDropList, ddname)

    -- Populate variable with item list
    LeaPlusLC[ddname .. "Table"] = items

    -- Create outer frame
    local frame = CreateFrame("FRAME", nil, parent);
    frame:SetWidth(width);
    frame:SetHeight(42);
    frame:SetPoint("BOTTOMLEFT", parent, anchor, x, y);

    -- Create dropdown inside outer frame
    local dd = CreateFrame("Frame", nil, frame);
    dd:SetPoint("BOTTOMLEFT", -16, -8);
    dd:SetPoint("BOTTOMRIGHT", 15, -4);
    dd:SetHeight(32);

    -- Create dropdown textures
    local lt = dd:CreateTexture(nil, "ARTWORK");
    lt:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame");
    lt:SetTexCoord(0, 0.1953125, 0, 1);
    lt:SetPoint("TOPLEFT", dd, 0, 17);
    lt:SetWidth(25);
    lt:SetHeight(64);
    local rt = dd:CreateTexture(nil, "BORDER");
    rt:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame");
    rt:SetTexCoord(0.8046875, 1, 0, 1);
    rt:SetPoint("TOPRIGHT", dd, 0, 17);
    rt:SetWidth(25);
    rt:SetHeight(64);
    local mt = dd:CreateTexture(nil, "BORDER");
    mt:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame");
    mt:SetTexCoord(0.1953125, 0.8046875, 0, 1);
    mt:SetPoint("LEFT", lt, "RIGHT");
    mt:SetPoint("RIGHT", rt, "LEFT");
    mt:SetHeight(64);

    -- Create dropdown label
    local lf = dd:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    lf:SetPoint("TOPLEFT", frame, 0, 0);
    lf:SetPoint("TOPRIGHT", frame, -5, 0);
    lf:SetJustifyH("LEFT");
    lf:SetText(L[label])

    -- Create dropdown placeholder for value (set it using OnShow)
    local value = dd:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("LEFT", lt, 26, 2);
    value:SetPoint("RIGHT", rt, -43, 0);
    value:SetJustifyH("LEFT");
    value:SetWordWrap(false)
    dd:SetScript("OnShow", function()
        value:SetText(LeaPlusLC[ddname .. "Table"][LeaPlusLC[ddname]])
    end)

    -- Create dropdown button (clicking it opens the dropdown list)
    local dbtn = CreateFrame("Button", nil, dd)
    dbtn:SetPoint("TOPRIGHT", rt, -16, -18);
    dbtn:SetWidth(24);
    dbtn:SetHeight(24)
    dbtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up");
    dbtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down");
    dbtn:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled");
    dbtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
    dbtn:GetHighlightTexture():SetBlendMode("ADD")
    dbtn.tiptext = tip;
    dbtn:SetScript("OnEnter", LeaPlusLC.ShowDropTip)
    dbtn:SetScript("OnLeave", GameTooltip_Hide)

    -- Create dropdown list
    local ddlist = CreateFrame("Frame", nil, frame)
    LeaPlusCB["ListFrame" .. ddname] = ddlist
    ddlist:SetPoint("TOP", 0, -42)
    ddlist:SetWidth(frame:GetWidth())
    ddlist:SetHeight((#items * 16) + 16 + 16)
    ddlist:SetFrameStrata("FULLSCREEN_DIALOG")
    ddlist:SetFrameLevel(12)
    ddlist:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = false, tileSize = 0, edgeSize = 32, insets = { left = 4, right = 4, top = 4, bottom = 4 } });
    ddlist:Hide()

    -- Hide list if parent is closed
    parent:HookScript("OnHide", function()
        ddlist:Hide()
    end)

    -- Create checkmark (it marks the currently selected item)
    local ddlistchk = CreateFrame("FRAME", nil, ddlist)
    ddlistchk:SetHeight(16);
    ddlistchk:SetWidth(16)
    ddlistchk.t = ddlistchk:CreateTexture(nil, "ARTWORK");
    ddlistchk.t:SetAllPoints();
    ddlistchk.t:SetTexture("Interface\\Common\\UI-DropDownRadioChecks");
    ddlistchk.t:SetTexCoord(0, 0.5, 0.5, 1.0);

    -- Create dropdown list items
    for k, v in pairs(items) do

        local dditem = CreateFrame("Button", nil, LeaPlusCB["ListFrame" .. ddname])
        LeaPlusCB["Drop" .. ddname .. k] = dditem;
        dditem:Show();
        dditem:SetWidth(ddlist:GetWidth() - 22)
        dditem:SetHeight(16)
        dditem:SetPoint("TOPLEFT", 12, -k * 16)

        dditem.f = dditem:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
        dditem.f:SetPoint('LEFT', 16, 0)
        dditem.f:SetText(items[k])

        dditem.f:SetWordWrap(false)
        dditem.f:SetJustifyH("LEFT")
        dditem.f:SetWidth(ddlist:GetWidth() - 36)

        dditem.t = dditem:CreateTexture(nil, "BACKGROUND")
        dditem.t:SetAllPoints()
        dditem.t:SetTexture(0.3, 0.3, 0.00, 0.8)
        dditem.t:Hide();

        dditem:SetScript("OnEnter", function()
            dditem.t:Show()
        end)
        dditem:SetScript("OnLeave", function()
            dditem.t:Hide()
        end)
        dditem:SetScript("OnClick", function()
            LeaPlusLC[ddname] = k
            value:SetText(LeaPlusLC[ddname .. "Table"][k])
            ddlist:Hide(); -- Must be last in click handler as other functions hook it
        end)

        -- Show list when button is clicked
        dbtn:SetScript("OnClick", function()
            -- Show the dropdown
            if ddlist:IsShown() then
                ddlist:Hide()
            else
                ddlist:Show();
                ddlistchk:SetPoint("TOPLEFT", 10, select(5, LeaPlusCB["Drop" .. ddname .. LeaPlusLC[ddname]]:GetPoint()))
                ddlistchk:Show();
            end ;
            -- Hide all other dropdowns except the one we're dealing with
            for void, v in pairs(LeaDropList) do
                if v ~= ddname then
                    LeaPlusCB["ListFrame" .. v]:Hide()
                end
            end
        end)

        -- Expand the clickable area of the button to include the entire menu width
        dbtn:SetHitRectInsets(-width + 28, 0, 0, 0)

    end

    return frame

end

----------------------------------------------------------------------
-- 	Create main options panel frame
----------------------------------------------------------------------

function LeaPlusLC:CreateMainPanel()

    -- Create the panel
    local PageF = CreateFrame("Frame", nil, UIParent);

    -- Make it a system frame
    _G["LeaPlusGlobalPanel"] = PageF
    table.insert(UISpecialFrames, "LeaPlusGlobalPanel")

    -- Set frame parameters
    LeaPlusLC["PageF"] = PageF
    PageF:SetSize(570, 370)
    PageF:Hide();
    PageF:SetFrameStrata("FULLSCREEN_DIALOG")
    PageF:SetClampedToScreen(true)
    PageF:SetClampRectInsets(500, -500, -300, 300)
    PageF:EnableMouse(true)
    PageF:SetMovable(true)
    PageF:RegisterForDrag("LeftButton")
    PageF:SetScript("OnDragStart", PageF.StartMoving)
    PageF:SetScript("OnDragStop", function()
        PageF:StopMovingOrSizing();
        PageF:SetUserPlaced(false);
        -- Save panel position
        LeaPlusLC["MainPanelA"], void, LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = PageF:GetPoint()
    end)

    -- Add background color
    PageF.t = PageF:CreateTexture(nil, "BACKGROUND")
    PageF.t:SetAllPoints()
    PageF.t:SetTexture(0.05, 0.05, 0.05, 0.9)

    -- Add textures
    LeaPlusLC:CreateBar("FootTexture", PageF, 570, 42, "BOTTOM", 0.5, 0.5, 0.5, 1.0, "Interface\\addons\\Leatrix_Plus\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")
    LeaPlusLC:CreateBar("MainTexture", PageF, 440, 348, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7, "Interface\\addons\\Leatrix_Plus\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")
    LeaPlusLC:CreateBar("MenuTexture", PageF, 130, 348, "TOPLEFT", 0.7, 0.7, 0.7, 0.7, "Interface\\addons\\Leatrix_Plus\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")

    -- Set panel position when shown
    PageF:SetScript("OnShow", function()
        PageF:ClearAllPoints()
        PageF:SetPoint(LeaPlusLC["MainPanelA"], UIParent, LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"])
    end)

    -- Add main title (shown above menu in the corner)
    PageF.mt = PageF:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
    PageF.mt:SetPoint('TOPLEFT', 16, -16)
    PageF.mt:SetText("Leatrix Plus")

    -- Add version text (shown underneath main title)
    PageF.v = PageF:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
    PageF.v:SetHeight(32);
    PageF.v:SetPoint('TOPLEFT', PageF.mt, 'BOTTOMLEFT', 0, -8);
    PageF.v:SetPoint('RIGHT', PageF, -32, 0)
    PageF.v:SetJustifyH('LEFT');
    PageF.v:SetJustifyV('TOP');
    PageF.v:SetNonSpaceWrap(true);
    PageF.v:SetText(L["Version"] .. " " .. LeaPlusLC["AddonVer"])

    -- Add reload UI Button
    local reloadb = LeaPlusLC:CreateButton("ReloadUIButton", PageF, "Reload", "BOTTOMRIGHT", -16, 10, 0, 25, true, "Your UI needs to be reloaded for some of the changes to take effect.|n|nYou don't have to click the reload button immediately but you do need to click it when you are done making changes and you want the changes to take effect.")
    LeaPlusLC:LockItem(reloadb, true)
    reloadb:SetScript("OnClick", ReloadUI)

    reloadb.f = reloadb:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
    reloadb.f:SetHeight(32);
    reloadb.f:SetPoint('RIGHT', reloadb, 'LEFT', -10, 0)
    reloadb.f:SetText(L["Your UI needs to be reloaded."])
    reloadb.f:Hide()

    -- Add close Button
    local CloseB = CreateFrame("Button", nil, PageF, "UIPanelCloseButton")
    CloseB:SetSize(30, 30)
    CloseB:SetPoint("TOPRIGHT", 0, 0)
    CloseB:SetScript("OnClick", LeaPlusLC.HideFrames)

    -- Add web link Button
    local PageFAlertButton = LeaPlusLC:CreateButton("PageFAlertButton", PageF, "You should keybind web link!", "BOTTOMLEFT", 16, 10, 0, 25, true, "You should set a keybind for the web link feature.  It's very useful.|n|nOpen the key bindings window (accessible from the game menu) and click Leatrix Plus.|n|nSet a keybind for Show web link.|n|nNow when your pointer is over an item, NPC or spell (and more), press your keybind to get a web link.")
    PageFAlertButton:SetPushedTextOffset(0, 0)
    PageF:HookScript("OnShow", function()
        if GetBindingKey("LEATRIX_PLUS_GLOBAL_WEBLINK") then
            PageFAlertButton:Hide()
        else
            PageFAlertButton:Show()
        end
    end)

    -- Release memory
    LeaPlusLC.CreateMainPanel = nil

end

LeaPlusLC:CreateMainPanel();

----------------------------------------------------------------------
-- 	L80: Commands
----------------------------------------------------------------------

-- Slash command function
function LeaPlusLC:SlashFunc(str)
    if str and str ~= "" then
        -- Get parameters in lower case with duplicate spaces removed
        local str, arg1, arg2, arg3 = strsplit(" ", string.lower(str:gsub("%s+", " ")))
        -- Traverse parameters
        if str == "wipe" then
            -- Wipe settings
            LeaPlusLC:PlayerLogout(true) -- Run logout function with wipe parameter
            wipe(LeaPlusDB)
            LpEvt:UnregisterAllEvents(); -- Don't save any settings
            ReloadUI();
        elseif str == "nosave" then
            -- Prevent Leatrix Plus from overwriting LeaPlusDB at next logout
            LpEvt:UnregisterEvent("PLAYER_LOGOUT")
            LeaPlusLC:Print("Leatrix Plus will not overwrite LeaPlusDB at next logout.")
            return
        elseif str == "reset" then
            -- Reset panel positions
            LeaPlusLC["MainPanelA"], LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = "CENTER", "CENTER", 0, 0
            LeaPlusLC["PlusPanelScale"] = 1
            LeaPlusLC["PlusPanelAlpha"] = 0
            LeaPlusLC["PageF"]:SetScale(1)
            LeaPlusLC["PageF"].t:SetAlpha(1 - LeaPlusLC["PlusPanelAlpha"])
            -- Refresh panels
            LeaPlusLC["PageF"]:ClearAllPoints()
            LeaPlusLC["PageF"]:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            -- Reset currently showing configuration panel
            for k, v in pairs(LeaConfigList) do
                if v:IsShown() then
                    v:ClearAllPoints()
                    v:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                    v:SetScale(1)
                    v.t:SetAlpha(1 - LeaPlusLC["PlusPanelAlpha"])
                end
            end
            -- Refresh Leatrix Plus settings menu only
            if LeaPlusLC["Page8"]:IsShown() then
                LeaPlusLC["Page8"]:Hide()
                LeaPlusLC["Page8"]:Show()
            end
            return
        elseif str == "taint" then
            -- Set taint log level
            if arg1 and arg1 ~= "" then
                arg1 = tonumber(arg1)
                if arg1 and arg1 >= 0 and arg1 <= 2 then
                    if arg1 == 0 then
                        -- Disable taint log
                        ConsoleExec("taintLog 0")
                        LeaPlusLC:Print("Taint level: Disabled (0).")
                    elseif arg1 == 1 then
                        -- Basic taint log
                        ConsoleExec("taintLog 1")
                        LeaPlusLC:Print("Taint level: Basic (1).")
                    elseif arg1 == 2 then
                        -- Full taint log
                        ConsoleExec("taintLog 2")
                        LeaPlusLC:Print("Taint level: Full (2).")
                    end
                else
                    LeaPlusLC:Print("Invalid taint level.")
                end
            else
                -- Show current taint level
                local taintCurrent = GetCVar("taintLog")
                if taintCurrent == "0" then
                    LeaPlusLC:Print("Taint level: Disabled (0).")
                elseif taintCurrent == "1" then
                    LeaPlusLC:Print("Taint level: Basic (1).")
                elseif taintCurrent == "2" then
                    LeaPlusLC:Print("Taint level: Full (2).")
                end
            end
            return
        elseif str == "quest" then
            -- Show quest completed status
            if arg1 and arg1 ~= "" then
                if tonumber(arg1) and tonumber(arg1) < 999999999 then
                    local questCompleted = C_QuestLog.IsQuestFlaggedCompleted(arg1)
                    local questTitle = C_QuestLog.GetQuestInfo(arg1) or L["Unknown"]
                    LibCompat.After(0.5, function()
                        local questTitle = C_QuestLog.GetQuestInfo(arg1) or L["Unknown"]
                        if questCompleted then
                            LeaPlusLC:Print(questTitle .. " (" .. arg1 .. "):" .. "|cffffffff " .. L["Completed."])
                        else
                            LeaPlusLC:Print(questTitle .. " (" .. arg1 .. "):" .. "|cffffffff " .. L["Not completed."])
                        end
                    end)
                else
                    LeaPlusLC:Print("Invalid quest ID.")
                end
            else
                LeaPlusLC:Print("Missing quest ID.")
            end
            return
        elseif str == "rest" then
            -- Show rested bubbles
            LeaPlusLC:Print(L["Rested bubbles"] .. ": |cffffffff" .. (math.floor(20 * (GetXPExhaustion() or 0) / UnitXPMax("player") + 0.5)))
            return
        elseif str == "zygor" then
            -- Toggle Zygor addon
            LeaPlusLC:ZygorToggle()
            return
        elseif str == "npcid" then
            -- Print NPC ID
            local npcName = UnitName("target")
            local npcGuid = UnitGUID("target") or nil
            if npcName and npcGuid then
                local void, void, void, void, void, npcID = strsplit("-", npcGuid)
                if npcID then
                    LeaPlusLC:Print(npcName .. ": |cffffffff" .. npcID)
                end
            end
            return
        elseif str == "id" then
            --------------------------------------------------------------------------------
            -- Define urlencode function for Lua 5.3
            --------------------------------------------------------------------------------


            local function urlencode(str)
                return string.gsub(str, "([^%w%.%- ])", function(c)
                    return string.format("%%%02X", string.byte(c))
                end)         :gsub(" ", "+")
            end

            -- Show web link
            if not LeaPlusLC.WowheadLock then
                -- Set Wowhead link prefix
                if GameLocale == "deDE" then
                    LeaPlusLC.WowheadLock = "wowhead.com/wotlk/de"
                elseif GameLocale == "esMX" then
                    LeaPlusLC.WowheadLock = "wowhead.com/wotlk/es"
                elseif GameLocale == "esES" then
                    LeaPlusLC.WowheadLock = "wowhead.com/wotlk/es"
                elseif GameLocale == "frFR" then
                    LeaPlusLC.WowheadLock = "wowhead.com/wotlk/fr"
                elseif GameLocale == "itIT" then
                    LeaPlusLC.WowheadLock = "wowhead.com/wotlk/it"
                elseif GameLocale == "ptBR" then
                    LeaPlusLC.WowheadLock = "wowhead.com/wotlk/pt"
                elseif GameLocale == "ruRU" then
                    LeaPlusLC.WowheadLock = "wowhead.com/wotlk/ru"
                elseif GameLocale == "koKR" then
                    LeaPlusLC.WowheadLock = "wowhead.com/wotlk/ko"
                elseif GameLocale == "zhCN" then
                    LeaPlusLC.WowheadLock = "wowhead.com/wotlk/cn"
                elseif GameLocale == "zhTW" then
                    LeaPlusLC.WowheadLock = "wowhead.com/wotlk/cn"
                else
                    LeaPlusLC.WowheadLock = "wowhead.com/wotlk"
                end
            end
            -- Store frame under mouse
            local mouseFocus = GetMouseFocus()
            -- ItemRefTooltip or GameTooltip
            local tooltip
            if mouseFocus == ItemRefTooltip then
                tooltip = ItemRefTooltip
            else
                tooltip = GameTooltip
            end
            -- Process tooltip
            if tooltip:IsShown() then
                -- Item
                local void, itemLink = tooltip:GetItem()
                if itemLink then
                    local itemID = itemLink:match("item:(%d+):")
                    if itemID then
                        LeaPlusLC:ShowSystemEditBox("https://" .. LeaPlusLC.WowheadLock .. "/item=" .. itemID, false)
                        LeaPlusLC.FactoryEditBox.f:SetText(L["Item"] .. ": " .. itemLink .. " (" .. itemID .. ")")
                        return
                    end
                end
                -- Spell
                local name, void, spellID = tooltip:GetSpell()
                if name and spellID then
                    LeaPlusLC:ShowSystemEditBox("https://" .. LeaPlusLC.WowheadLock .. "/spell=" .. spellID, false)
                    LeaPlusLC.FactoryEditBox.f:SetText(L["Spell"] .. ": " .. name .. " (" .. spellID .. ")")
                    return
                end
                -- NPC
                local npcName = UnitName("mouseover")
                local npcGuid = UnitGUID("mouseover") or nil
                if npcName and npcGuid then
                    local void, void, void, void, void, npcID = strsplit("-", npcGuid)
                    if npcID then
                        LeaPlusLC:ShowSystemEditBox("https://" .. LeaPlusLC.WowheadLock .. "/npc=" .. npcID, false)
                        LeaPlusLC.FactoryEditBox.f:SetText(L["NPC"] .. ": " .. npcName .. " (" .. npcID .. ")")
                        return
                    end
                end
                -- Buffs and debuffs
                for i = 1, BUFF_MAX_DISPLAY do
                    if _G["BuffButton" .. i] and mouseFocus == _G["BuffButton" .. i] then
                        local spellName, void, void, void, void, void, void, void, void, void, spellID = UnitBuff("player", i)
                        if spellName and spellID then
                            LeaPlusLC:ShowSystemEditBox("https://" .. LeaPlusLC.WowheadLock .. "/spell=" .. spellID, false)
                            LeaPlusLC.FactoryEditBox.f:SetText(L["Spell"] .. ": " .. spellName .. " (" .. spellID .. ")")
                        end
                        return
                    end
                end
                for i = 1, DEBUFF_MAX_DISPLAY do
                    if _G["DebuffButton" .. i] and mouseFocus == _G["DebuffButton" .. i] then
                        local spellName, void, void, void, void, void, void, void, void, void, spellID = UnitDebuff("player", i)
                        if spellName and spellID then
                            LeaPlusLC:ShowSystemEditBox("https://" .. LeaPlusLC.WowheadLock .. "/spell=" .. spellID, false)
                            LeaPlusLC.FactoryEditBox.f:SetText(L["Spell"] .. ": " .. spellName .. " (" .. spellID .. ")")
                        end
                        return
                    end
                end

                -- Target Buffs and debuffs
                for i = 1, MAX_TARGET_BUFFS do
                    if _G["TargetFrameBuff" .. i] and mouseFocus == _G["TargetFrameBuff" .. i] then
                        local spellName, void, void, void, void, void, void, void, void, void, spellID = UnitBuff("target", i)
                        if spellName and spellID then
                            LeaPlusLC:ShowSystemEditBox("https://" .. LeaPlusLC.WowheadLock .. "/spell=" .. spellID, false)
                            LeaPlusLC.FactoryEditBox.f:SetText(L["Spell"] .. ": " .. spellName .. " (" .. spellID .. ")")
                        end
                        return
                    end
                end
                for i = 1, MAX_TARGET_DEBUFFS do
                    if _G["TargetFrameDebuff" .. i] and mouseFocus == _G["TargetFrameDebuff" .. i] then
                        local spellName, void, void, void, void, void, void, void, void, void, spellID = UnitDebuff("target", i)
                        if spellName and spellID then
                            LeaPlusLC:ShowSystemEditBox("https://" .. LeaPlusLC.WowheadLock .. "/spell=" .. spellID, false)
                            LeaPlusLC.FactoryEditBox.f:SetText(L["Spell"] .. ": " .. spellName .. " (" .. spellID .. ")")
                        end
                        return
                    end
                end

                -- --===== 3.3.5 FIXME Didn't work, MAX_FOCUS_DEBUFFS, seems to not give me a number. Focus Debuffs! There is no MAX_FOCUS_BUFFS, they are not shown. =====--
                -- for i = 1, MAX_FOCUS_DEBUFFS do
                -- 	if _G["FocusFrameDebuff" .. i] and mouseFocus == _G["FocusFrameDebuff" .. i] then
                -- 		local spellName, void, void, void, void, void, void, void, void, void, spellID = UnitDebuff("focus", i)
                -- 		if spellName and spellID then
                -- 			LeaPlusLC:ShowSystemEditBox("https://" .. LeaPlusLC.WowheadLock .. "/spell=" .. spellID, false)
                -- 			LeaPlusLC.FactoryEditBox.f:SetText(L["Spell"] .. ": " .. spellName .. " (" .. spellID .. ")")
                -- 		end
                -- 		return
                -- 	end
                -- end

                -- Unknown tooltip (this must be last)
                local tipTitle = GameTooltipTextLeft1:GetText()
                if tipTitle then
                    -- Show unknown link
                    local unitFocus
                    if mouseFocus == WorldFrame then
                        unitFocus = "mouseover"
                    else
                        unitFocus = select(2, GameTooltip:GetUnit())
                    end
                    if not unitFocus or not UnitIsPlayer(unitFocus) then
                        tipTitle = tipTitle:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                        LeaPlusLC:ShowSystemEditBox("https://" .. LeaPlusLC.WowheadLock .. "/search?q=" .. urlencode(tipTitle), false)
                        LeaPlusLC.FactoryEditBox.f:SetText("|cffff0000" .. L["Link will search Wowhead"])
                        return
                    end
                end
            end
            return
        elseif str == "tooltip" then
            -- Print tooltip frame name
            local enumf = EnumerateFrames()
            while enumf do
                if (enumf:GetObjectType() == "GameTooltip" or strfind((enumf:GetName() or ""):lower(), "tip")) and enumf:IsVisible() and enumf:GetPoint() then
                    print(enumf:GetName())
                end
                enumf = EnumerateFrames(enumf)
            end
            collectgarbage()
            return
        elseif str == "rsnd" then
            -- Restart sound system
            if LeaPlusCB["StopMusicBtn"] then
                LeaPlusCB["StopMusicBtn"]:Click()
            end
            Sound_GameSystem_RestartSoundSystem()
            LeaPlusLC:Print("Sound system restarted.")
            return
        elseif str == "event" then
            -- List events (used for debug)
            LeaPlusLC["DbF"] = LeaPlusLC["DbF"] or CreateFrame("FRAME")
            if not LeaPlusLC["DbF"]:GetScript("OnEvent") then
                LeaPlusLC:Print("Tracing started.")
                LeaPlusLC["DbF"]:RegisterAllEvents()
                LeaPlusLC["DbF"]:SetScript("OnEvent", function(self, event)
                    if event == "ACTIONBAR_UPDATE_COOLDOWN"
                            or event == "BAG_UPDATE_COOLDOWN"
                            or event == "CHAT_MSG_TRADESKILLS"
                            or event == "COMBAT_LOG_EVENT_UNFILTERED"
                            or event == "SPELL_UPDATE_COOLDOWN"
                            or event == "SPELL_UPDATE_USABLE"
                            or event == "UNIT_POWER_FREQUENT"
                            or event == "UPDATE_INVENTORY_DURABILITY"
                    then
                        return
                    else
                        print(event)
                    end
                end)
            else
                LeaPlusLC["DbF"]:UnregisterAllEvents()
                LeaPlusLC["DbF"]:SetScript("OnEvent", nil)
                LeaPlusLC:Print("Tracing stopped.")
            end
            return
        elseif str == "game" then
            -- Show game build
            local version, build, gdate, tocversion = GetBuildInfo()
            LeaPlusLC:Print(L["World of Warcraft"] .. ": |cffffffff" .. version .. "." .. build .. " (" .. gdate .. ") (" .. tocversion .. ")")
            return
        elseif str == "config" then
            -- Show maximum camera distance
            LeaPlusLC:Print(L["Camera distance"] .. ": |cffffffff" .. GetCVar("cameraDistanceMaxZoomFactor"))
            -- Show particle density
            LeaPlusLC:Print(L["Particle density"] .. ": |cffffffff" .. GetCVar("particleDensity"))
            LeaPlusLC:Print(L["Weather density"] .. ": |cffffffff" .. GetCVar("weatherDensity"))
            -- Show config
            LeaPlusLC:Print("SynchroniseConfig: |cffffffff" .. GetCVar("synchronizeConfig"))
            -- Show raid restrictions
            local unRaid = GetAllowLowLevelRaid()
            if unRaid and unRaid == true then
                LeaPlusLC:Print("GetAllowLowLevelRaid: |cffffffff" .. "True")
            else
                LeaPlusLC:Print("GetAllowLowLevelRaid: |cffffffff" .. "False")
            end
            return
        elseif str == "move" then
            -- Move minimap
            MinimapZoneTextButton:Hide()
            MinimapBorderTop:SetTexture("")
            MiniMapWorldMapButton:Hide()
            MinimapBackdrop:ClearAllPoints()
            MinimapBackdrop:SetPoint("CENTER", UIParent, "CENTER", -330, -75)
            Minimap:SetPoint("CENTER", UIParent, "CENTER", -320, -50)
            return
        elseif str == "tipcol" then
            -- Show default tooltip title color
            if GameTooltipTextLeft1:IsShown() then
                local r, g, b, a = GameTooltipTextLeft1:GetTextColor()
                r = r <= 1 and r >= 0 and r or 0
                g = g <= 1 and g >= 0 and g or 0
                b = b <= 1 and b >= 0 and b or 0
                LeaPlusLC:Print(L["Tooltip title color"] .. ": " .. strupper(string.format("%02x%02x%02x", r * 255, g * 255, b * 255) .. "."))
            else
                LeaPlusLC:Print("No tooltip showing.")
            end
            return
        elseif str == "list" then
            -- Enumerate frames
            local frame = EnumerateFrames()
            while frame do
                if (frame:IsVisible() and MouseIsOver(frame)) then
                    LeaPlusLC:Print(frame:GetName() or string.format("[Unnamed Frame: %s]", tostring(frame)))
                end
                frame = EnumerateFrames(frame)
            end
            return
        elseif str == "grid" then
            -- Toggle frame alignment grid
            if LeaPlusLC.grid:IsShown() then
                LeaPlusLC.grid:Hide()
            else
                LeaPlusLC.grid:Show()
            end
            return
        elseif str == "chk" then
            -- List truncated checkbox labels
            if LeaPlusLC["TruncatedLabelsList"] then
                for i, v in pairs(LeaPlusLC["TruncatedLabelsList"]) do
                    LeaPlusLC:Print(LeaPlusLC["TruncatedLabelsList"][i])
                end
            else
                LeaPlusLC:Print("Checkbox labels are Ok.")
            end
            return
        elseif str == "cv" then
            -- Print and set console variable setting
            if arg1 and arg1 ~= "" then
                if GetCVar(arg1) then
                    if arg2 and arg2 ~= "" then
                        if tonumber(arg2) then
                            SetCVar(arg1, arg2)
                        else
                            LeaPlusLC:Print("Value must be a number.")
                            return
                        end
                    end
                    LeaPlusLC:Print(arg1 .. ": |cffffffff" .. GetCVar(arg1))
                else
                    LeaPlusLC:Print("Invalid console variable.")
                end
            else
                LeaPlusLC:Print("Missing console variable.")
            end
            return
        elseif str == "play" then
            -- Play sound ID
            if arg1 and arg1 ~= "" then
                if tonumber(arg1) then
                    -- Stop last played sound ID
                    if LeaPlusLC.SNDcanitHandle then
                        StopSound(LeaPlusLC.SNDcanitHandle)
                    end
                    -- Play sound ID
                    LeaPlusLC.SNDcanitPlay, LeaPlusLC.SNDcanitHandle = PlaySound(arg1, "Master", false, false)
                    if not LeaPlusLC.SNDcanitPlay then
                        LeaPlusLC:Print(L["Invalid sound ID"] .. ": |cffffffff" .. arg1)
                    end
                else
                    LeaPlusLC:Print(L["Invalid sound ID"] .. ": |cffffffff" .. arg1)
                end
            else
                LeaPlusLC:Print("Missing sound ID.")
            end
            return
        elseif str == "stop" then
            -- Stop last played sound ID
            if LeaPlusLC.SNDcanitHandle then
                StopSound(LeaPlusLC.SNDcanitHandle)
            end
            return
        elseif str == "wipecds" then
            -- Wipe cooldowns
            LeaPlusDB["Cooldowns"] = nil
            ReloadUI()
            return
        elseif str == "tipchat" then
            -- Print tooltip contents in chat
            local numLines = GameTooltip:NumLines()
            if numLines then
                for i = 1, numLines do
                    print(_G["GameTooltipTextLeft" .. i]:GetText() or "")
                end
            end
            return
        elseif str == "tiplang" then
            -- Tooltip tag locale code constructor
            local msg = ""
            msg = msg .. 'if GameLocale == "' .. GameLocale .. '" then '
            msg = msg .. 'ttLevel = "' .. LEVEL .. '"; '
            msg = msg .. 'ttBoss = "' .. BOSS .. '"; '
            msg = msg .. 'ttElite = "' .. ELITE .. '"; '
            msg = msg .. 'ttRare = "' .. ITEM_QUALITY3_DESC .. '"; '
            msg = msg .. 'ttRareElite = "' .. ITEM_QUALITY3_DESC .. " " .. ELITE .. '"; '
            msg = msg .. 'ttRareBoss = "' .. ITEM_QUALITY3_DESC .. " " .. BOSS .. '"; '
            msg = msg .. 'ttTarget = "' .. TARGET .. '"; '
            msg = msg .. "end"
            print(msg)
            return
        elseif str == "con" then
            -- Show the developer console
            C_Console.SetFontHeight(28)
            DeveloperConsole:Toggle(true)
            return
        elseif str == "movlist" then
            -- List playable movie IDs
            local count = 0
            for i = 1, 1000 do
                if IsMoviePlayable(i) then
                    print(i)
                    count = count + 1
                end
            end
            LeaPlusLC:Print("Total movies: |cffffffff" .. count)
            return
        elseif str == "movie" then
            -- Playback movie by ID
            arg1 = tonumber(arg1)
            if arg1 and arg1 ~= "" then
                if IsMoviePlayable(arg1) then
                    MovieFrame_PlayMovie(MovieFrame, arg1)
                else
                    LeaPlusLC:Print("Movie not playable.")
                end
            else
                LeaPlusLC:Print("Missing movie ID.")
            end
            return
        elseif str == "cin" then
            -- Play opening cinematic (only works if character has never gained XP) (used for testing)
            OpeningCinematic()
            return
        elseif str == "skit" then
            -- Play a test sound kit
            PlaySound("1020", "Master", false, true)
            return
        elseif str == "marker" then
            -- Prevent showing raid target markers on self
            if not LeaPlusLC.MarkerFrame then
                LeaPlusLC.MarkerFrame = CreateFrame("FRAME")
                LeaPlusLC.MarkerFrame:RegisterEvent("RAID_TARGET_UPDATE")
            end
            LeaPlusLC.MarkerFrame.Update = true
            if LeaPlusLC.MarkerFrame.Toggle == false then
                -- Show markers
                LeaPlusLC.MarkerFrame:SetScript("OnEvent", nil)
                ActionStatus_DisplayMessage(L["Self Markers Allowed"], true)
                LeaPlusLC.MarkerFrame.Toggle = true
            else
                -- Hide markers
                SetRaidTarget("player", 0)
                LeaPlusLC.MarkerFrame:SetScript("OnEvent", function()
                    if LeaPlusLC.MarkerFrame.Update == true then
                        LeaPlusLC.MarkerFrame.Update = false
                        SetRaidTarget("player", 0)
                    end
                    LeaPlusLC.MarkerFrame.Update = true
                end)
                ActionStatus_DisplayMessage(L["Self Markers Blocked"], true)
                LeaPlusLC.MarkerFrame.Toggle = false
            end
            return
        elseif str == "pos" then
            -- Map POI code builder
            local mapID = C_Map.GetBestMapForUnit("player") or nil
            local mapName = C_Map.GetMapInfo(mapID).name or nil
            local mapRects = {}
            local tempVec2D = CreateVector2D(0, 0)
            local void
            -- Get player map position
            tempVec2D.x, tempVec2D.y = UnitPosition("player")
            if not tempVec2D.x then
                return
            end
            local mapRect = mapRects[mapID]
            if not mapRect then
                mapRect = {}
                void, mapRect[1] = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(0, 0))
                void, mapRect[2] = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(1, 1))
                mapRect[2]:Subtract(mapRect[1])
                mapRects[mapID] = mapRect
            end
            tempVec2D:Subtract(mapRects[mapID][1])
            local pX, pY = tempVec2D.y / mapRects[mapID][2].y, tempVec2D.x / mapRects[mapID][2].x
            pX = string.format("%0.1f", 100 * pX)
            pY = string.format("%0.1f", 100 * pY)
            if mapID and mapName and pX and pY then
                ChatFrame1:Clear()
                local dnType, dnTex = "Dungeon", "dnTex"
                if arg1 == "raid" then
                    dnType, dnTex = "Raid", "rdTex"
                end
                if arg1 == "portal" then
                    dnType = "Portal"
                end
                print('[' .. mapID .. '] =  --[[' .. mapName .. ']] {{' .. pX .. ', ' .. pY .. ', L[' .. '"Name"' .. '], L[' .. '"' .. dnType .. '"' .. '], ' .. dnTex .. '},},')
            end
            return
        elseif str == "mapref" then
            -- Print map reveal structure code
            if not WorldMapFrame:IsShown() then
                LeaPlusLC:Print("Open the map first!")
                return
            end
            ChatFrame1:Clear()
            local msg = ""
            local mapID = WorldMapFrame.mapID
            local mapName = C_Map.GetMapInfo(mapID).name
            local mapArt = C_Map.GetMapArtID(mapID)
            msg = msg .. "--[[" .. mapName .. "]] [" .. mapArt .. "] = {"
            local exploredMapTextures = C_MapExplorationInfo.GetExploredMapTextures(mapID);
            if exploredMapTextures then
                for i, exploredTextureInfo in ipairs(exploredMapTextures) do
                    local twidth = exploredTextureInfo.textureWidth or 0
                    if twidth > 0 then
                        local theight = exploredTextureInfo.textureHeight or 0
                        local offsetx = exploredTextureInfo.offsetX
                        local offsety = exploredTextureInfo.offsetY
                        local filedataIDS = exploredTextureInfo.fileDataIDs
                        msg = msg .. "[" .. '"' .. twidth .. ":" .. theight .. ":" .. offsetx .. ":" .. offsety .. '"' .. "] = " .. '"'
                        for fileData = 1, #filedataIDS do
                            msg = msg .. filedataIDS[fileData]
                            if fileData < #filedataIDS then
                                msg = msg .. ", "
                            else
                                msg = msg .. '",'
                                if i < #exploredMapTextures then
                                    msg = msg .. " "
                                end
                            end
                        end
                    end
                end
                msg = msg .. "},"
                print(msg)
            end
            return
        elseif str == "mk" then
            -- Print a map key
            if not arg1 then
                LeaPlusLC:Print("Key missing!")
                return
            end
            if not tonumber(arg1) then
                LeaPlusLC:Print("Must be a number!")
                return
            end
            local key = arg1
            ChatFrame1:Clear()
            print('"' .. mod(floor(key / 2 ^ 36), 2 ^ 12) .. ":" .. mod(floor(key / 2 ^ 24), 2 ^ 12) .. ":" .. mod(floor(key / 2 ^ 12), 2 ^ 12) .. ":" .. mod(key, 2 ^ 12) .. '"')
            return
        elseif str == "map" then
            -- Set map by ID, print currently showing map ID or print character map ID
            if not arg1 then
                -- Print map ID
                if WorldMapFrame:IsShown() then
                    -- Show world map ID
                    local mapID = WorldMapFrame.mapID or nil
                    local artID = C_Map.GetMapArtID(mapID) or nil
                    local mapName = C_Map.GetMapInfo(mapID).name or nil
                    if mapID and artID and mapName then
                        LeaPlusLC:Print(mapID .. " (" .. artID .. "): " .. mapName .. " (map)")
                    end
                else
                    -- Show character map ID
                    local mapID = C_Map.GetBestMapForUnit("player") or nil
                    local artID = C_Map.GetMapArtID(mapID) or nil
                    local mapName = C_Map.GetMapInfo(mapID).name or nil
                    if mapID and artID and mapName then
                        LeaPlusLC:Print(mapID .. " (" .. artID .. "): " .. mapName .. " (player)")
                    end
                end
                return
            elseif not tonumber(arg1) or not C_Map.GetMapInfo(arg1) then
                -- Invalid map ID
                LeaPlusLC:Print("Invalid map ID.")
            else
                -- Set map by ID
                WorldMapFrame:SetMapID(tonumber(arg1))
            end
            return
        elseif str == "cls" then
            -- Clear chat frame
            ChatFrame1:Clear()
            return
        elseif str == "al" then
            -- Enable auto loot
            SetCVar("autoLootDefault", "1")
            LeaPlusLC:Print("Auto loot is now enabled.")
            return
        elseif str == "realm" then
            -- Show list of connected realms
            local titleRealm = GetRealmName()
            local userRealm = GetNormalizedRealmName()
            local connectedServers = GetAutoCompleteRealms()
            if titleRealm and userRealm and connectedServers then
                LeaPlusLC:Print(L["Connections for"] .. "|cffffffff " .. titleRealm)
                if #connectedServers > 0 then
                    local count = 1
                    for i = 1, #connectedServers do
                        if userRealm ~= connectedServers[i] then
                            LeaPlusLC:Print(count .. ".  " .. connectedServers[i])
                            count = count + 1
                        end
                    end
                else
                    LeaPlusLC:Print("None")
                end
            end
            return
        elseif str == "dup" then
            -- Print music track duplicates
            local mask, found, badidfound = false, false, false
            for i, e in pairs(Leatrix_Plus["ZoneList"]) do
                if Leatrix_Plus["ZoneList"][e] then
                    for a, b in pairs(Leatrix_Plus["ZoneList"][e]) do
                        local same = {}
                        if b.tracks then
                            for k, v in pairs(b.tracks) do
                                -- Check for bad sound IDs
                                if not strfind(v, "|c") then
                                    if not strfind(v, ".mp3") then
                                        local temFile, temSoundID = v:match("([^,]+)%#([^,]+)")
                                        if temSoundID then
                                            local temPlay, temHandle = PlaySound(temSoundID, "Master", false, true)
                                            if temHandle then
                                                StopSound(temHandle)
                                            end
                                            temPlay, temHandle = PlaySound(temSoundID, "Master", false, true)
                                            if not temPlay and not temHandle then
                                                print("|cffff5400" .. L["Bad ID"] .. ": |r" .. e, v)
                                                badidfound = true
                                            else
                                                if temHandle then
                                                    StopSound(temHandle)
                                                end
                                            end
                                        end
                                    end
                                    -- Check for duplicate IDs
                                    if tContains(same, v) and mask == false then
                                        mask = true
                                        found = true
                                        print("|cffec51ff" .. L["Dup ID"] .. ": |r" .. e, v)
                                    end
                                    tinsert(same, v)
                                    mask = false
                                end
                            end
                        end
                    end
                end
            end
            if badidfound == false then
                LeaPlusLC:Print("No bad sound IDs found.")
            end
            if found == false then
                LeaPlusLC:Print("No media duplicates found.")
            end
            Sound_GameSystem_RestartSoundSystem()
            collectgarbage()
            return
        elseif str == "help" then
            -- Help panel
            if not LeaPlusLC.HelpFrame then
                local frame = CreateFrame("FRAME", nil, UIParent)
                frame:SetSize(570, 340);
                frame:SetFrameStrata("FULLSCREEN_DIALOG");
                frame:SetFrameLevel(100)
                frame.tex = frame:CreateTexture(nil, "BACKGROUND");
                frame.tex:SetAllPoints();
                frame.tex:SetVertexColor(0.05, 0.05, 0.05, 0.9)
                frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton");
                frame.close:SetSize(30, 30);
                frame.close:SetPoint("TOPRIGHT", 0, 0);
                frame.close:SetScript("OnClick", function()
                    frame:Hide()
                end)
                frame:ClearAllPoints();
                frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                frame:SetClampedToScreen(true)
                frame:SetClampRectInsets(450, -450, -300, 300)
                frame:EnableMouse(true)
                frame:SetMovable(true)
                frame:RegisterForDrag("LeftButton")
                frame:SetScript("OnDragStart", frame.StartMoving)
                frame:SetScript("OnDragStop", function()
                    frame:StopMovingOrSizing()
                    frame:SetUserPlaced(false)
                end)
                frame:Hide()
                LeaPlusLC:CreateBar("HelpPanelMainTexture", frame, 570, 340, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7, "Interface\\addons\\Leatrix_Plus\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")
                -- Panel contents
                local col1, col2, color1 = 10, 120, "|cffffffaa"
                LeaPlusLC:MakeTx(frame, "Leatrix Plus Help", col1, -10)
                LeaPlusLC:MakeWD(frame, color1 .. "/ltp", col1, -30)
                LeaPlusLC:MakeWD(frame, "Toggle options panel.", col2, -30)
                LeaPlusLC:MakeWD(frame, color1 .. "/ltp reset", col1, -50)
                LeaPlusLC:MakeWD(frame, "Reset addon panel position and scale.", col2, -50)
                LeaPlusLC:MakeWD(frame, color1 .. "/ltp wipe", col1, -70)
                LeaPlusLC:MakeWD(frame, "Wipe all addon settings (reloads UI).", col2, -70)
                LeaPlusLC:MakeWD(frame, color1 .. "/ltp realm", col1, -90)
                LeaPlusLC:MakeWD(frame, "Show realms connected to yours.", col2, -90)
                LeaPlusLC:MakeWD(frame, color1 .. "/ltp rest", col1, -110)
                LeaPlusLC:MakeWD(frame, "Show number of rested XP bubbles remaining.", col2, -110)
                LeaPlusLC:MakeWD(frame, color1 .. "/ltp quest <id>", col1, -130)
                LeaPlusLC:MakeWD(frame, "Show quest completion status for <quest id>.", col2, -130)
                LeaPlusLC:MakeWD(frame, color1 .. "/ltp grid", col1, -150)
                LeaPlusLC:MakeWD(frame, "Toggle a frame alignment grid.", col2, -150)
                LeaPlusLC:MakeWD(frame, color1 .. "/ltp id", col1, -170)
                LeaPlusLC:MakeWD(frame, "Show a web link for whatever the pointer is over.", col2, -170)
                LeaPlusLC:MakeWD(frame, color1 .. "/ltp zygor", col1, -190)
                LeaPlusLC:MakeWD(frame, "Toggle the Zygor addon (reloads UI).", col2, -190)
                LeaPlusLC:MakeWD(frame, color1 .. "/ltp movie <id>", col1, -210)
                LeaPlusLC:MakeWD(frame, "Play a movie by its ID.", col2, -210)
                LeaPlusLC:MakeWD(frame, color1 .. "/ltp marker", col1, -230)
                LeaPlusLC:MakeWD(frame, "Block target markers (toggle) (requires assistant or leader in raid).", col2, -230)
                LeaPlusLC:MakeWD(frame, color1 .. "/ltp rsnd", col1, -250)
                LeaPlusLC:MakeWD(frame, "Restart the sound system.", col2, -250)
                LeaPlusLC:MakeWD(frame, color1 .. "/ltp ra", col1, -270)
                LeaPlusLC:MakeWD(frame, "Announce target in General chat channel (useful for rares).", col2, -270)
                LeaPlusLC:MakeWD(frame, color1 .. "/ltp con", col1, -290)
                LeaPlusLC:MakeWD(frame, "Launch the developer console with a large font.", col2, -290)
                LeaPlusLC:MakeWD(frame, color1 .. "/rl", col1, -310)
                LeaPlusLC:MakeWD(frame, "Reload the UI.", col2, -310)
                LeaPlusLC.HelpFrame = frame
                _G["LeaPlusGlobalHelpPanel"] = frame
                table.insert(UISpecialFrames, "LeaPlusGlobalHelpPanel")
            end
            if LeaPlusLC.HelpFrame:IsShown() then
                LeaPlusLC.HelpFrame:Hide()
            else
                LeaPlusLC.HelpFrame:Show()
            end
            return
        elseif str == "ra" then
            -- Announce target name, health percentage, coordinates and map pin link in General chat channel
            local genChannel
            if GameLocale == "deDE" then
                genChannel = "Allgemein"
            elseif GameLocale == "esMX" then
                genChannel = "General"
            elseif GameLocale == "esES" then
                genChannel = "General"
            elseif GameLocale == "frFR" then
                genChannel = "Général"
            elseif GameLocale == "itIT" then
                genChannel = "Generale"
            elseif GameLocale == "ptBR" then
                genChannel = "Geral"
            elseif GameLocale == "ruRU" then
                genChannel = "Общий"
            elseif GameLocale == "koKR" then
                genChannel = "공개"
            elseif GameLocale == "zhCN" then
                genChannel = "综合"
            elseif GameLocale == "zhTW" then
                genChannel = "綜合"
            else
                genChannel = "General"
            end
            if genChannel then
                local index = GetChannelName(genChannel)
                if index and index > 0 then
                    local mapID = C_Map.GetBestMapForUnit("player")
                    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
                    if pos.x and pos.x ~= "0" and pos.y and pos.y ~= "0" then
                        local uHealth = UnitHealth("target")
                        local uHealthMax = UnitHealthMax("target")
                        -- Announce in chat
                        if uHealth and uHealth > 0 and uHealthMax and uHealthMax > 0 then
                            -- Get unit classification (elite, rare, rare elite or boss)
                            local unitType, unitTag = UnitClassification("target"), ""
                            if unitType then
                                if unitType == "rare" or unitType == "rareelite" then
                                    unitTag = "(" .. L["Rare"] .. ") "
                                elseif unitType == "worldboss" then
                                    unitTag = "(" .. L["Boss"] .. ") "
                                end
                            end
                            SendChatMessage(format("%%t " .. unitTag .. "(%d%%)%s", uHealth / uHealthMax * 100, " " .. string.format("%.0f", pos.x * 100) .. ":" .. string.format("%.0f", pos.y * 100)), "CHANNEL", nil, index)
                            -- SendChatMessage(format("%%t " .. unitTag .. "(%d%%)%s", uHealth / uHealthMax * 100, " " .. string.format("%.0f", pos.x * 100) .. ":" .. string.format("%.0f", pos.y * 100)), "WHISPER", nil, GetUnitName("player")) -- Debug
                        else
                            LeaPlusLC:Print("Invalid target.")
                        end
                    else
                        LeaPlusLC:Print("Cannot announce in this zone.")
                    end
                else
                    LeaPlusLC:Print("Cannot find General chat channel.")
                end
            end
            return
        elseif str == "camp" then
            -- Camp
            if not LeaPlusLC.NoCampFrame then
                -- Load LibChatAnims
                Leatrix_Plus:LeaPlusLCA()
                -- Chat filter
                function LeaPlusLC.CampFilterFunc(self, event, msg)
                    if msg:match(_G["MARKED_AFK_MESSAGE"]:gsub("%%s", "%s-"))
                            or msg:match(_G["MARKED_AFK"])
                            or msg:match(_G["CLEARED_AFK"])
                            or msg:match(_G["IDLE_MESSAGE"])
                    then
                        return true
                    end
                end
                LeaPlusLC.NoCampFrame = CreateFrame("FRAME", nil, UIParent)
            end
            if LeaPlusLC.NoCampFrame:IsEventRegistered("PLAYER_CAMPING") then
                -- Disable camp
                LeaPlusLC.NoCampFrame:UnregisterEvent("PLAYER_CAMPING")
                ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", LeaPlusLC.CampFilterFunc)
                LeaPlusLC:Print("Camping enabled.  You will camp.")
            else
                -- Enable camp
                LeaPlusLC.NoCampFrame:RegisterEvent("PLAYER_CAMPING")
                ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", LeaPlusLC.CampFilterFunc)
                LeaPlusLC:Print("Camping disabled.  You won't camp.")
            end
            -- Event handler
            LeaPlusLC.NoCampFrame:SetScript("OnEvent", function()
                local p = StaticPopup_Visible("CAMP")
                _G[p .. "Button1"]:Click()
            end)
            return
        elseif str == "perf" then
            -- Average FPS during combat
            local fTab = {}
            if not LeaPlusLC.perf then
                LeaPlusLC.perf = CreateFrame("FRAME")
            end
            local fFrm = LeaPlusLC.perf
            local k, startTime = 0, 0
            if fFrm:IsEventRegistered("PLAYER_REGEN_DISABLED") then
                fFrm:UnregisterAllEvents()
                fFrm:SetScript("OnUpdate", nil)
                LeaPlusLC:Print("PERF unloaded.")
            else
                fFrm:RegisterEvent("PLAYER_REGEN_DISABLED")
                fFrm:RegisterEvent("PLAYER_REGEN_ENABLED")
                LeaPlusLC:Print("Waiting for combat to start...")
            end
            fFrm:SetScript("OnEvent", function(self, event)
                if event == "PLAYER_REGEN_DISABLED" then
                    LeaPlusLC:Print("Monitoring FPS during combat...")
                    fFrm:SetScript("OnUpdate", function()
                        k = k + 1
                        fTab[k] = GetFramerate()
                    end)
                    startTime = GetTime()
                else
                    fFrm:SetScript("OnUpdate", nil)
                    local tSum = 0
                    for i = 1, #fTab do
                        tSum = tSum + fTab[i]
                    end
                    local timeTaken = string.format("%.0f", GetTime() - startTime)
                    if tSum > 0 then
                        LeaPlusLC:Print("Average FPS for " .. timeTaken .. " seconds of combat: " .. string.format("%.0f", tSum / #fTab))
                    end
                end
            end)
            return
        elseif str == "col" then
            -- Convert color values
            LeaPlusLC:Print("|n")
            local r, g, b = tonumber(arg1), tonumber(arg2), tonumber(arg3)
            if r and g and b then
                -- RGB source
                LeaPlusLC:Print("Source: |cffffffff" .. r .. " " .. g .. " " .. b .. " ")
                -- RGB to Hex
                if r > 1 and g > 1 and b > 1 then
                    -- RGB to Hex
                    LeaPlusLC:Print("Hex: |cffffffff" .. strupper(string.format("%02x%02x%02x", r, g, b)) .. " (from RGB)")
                else
                    -- Wow to Hex
                    LeaPlusLC:Print("Hex: |cffffffff" .. strupper(string.format("%02x%02x%02x", r * 255, g * 255, b * 255)) .. " (from Wow)")
                    -- Wow to RGB
                    local rwow = string.format("%.0f", r * 255)
                    local gwow = string.format("%.0f", g * 255)
                    local bwow = string.format("%.0f", b * 255)
                    if rwow ~= "0.0" and gwow ~= "0.0" and bwow ~= "0.0" then
                        LeaPlusLC:Print("RGB: |cffffffff" .. rwow .. " " .. gwow .. " " .. bwow .. " (from Wow)")
                    end
                end
                -- RGB to Wow
                local rwow = string.format("%.1f", r / 255)
                local gwow = string.format("%.1f", g / 255)
                local bwow = string.format("%.1f", b / 255)
                if rwow ~= "0.0" and gwow ~= "0.0" and bwow ~= "0.0" then
                    LeaPlusLC:Print("Wow: |cffffffff" .. rwow .. " " .. gwow .. " " .. bwow)
                end
                LeaPlusLC:Print("|n")
            elseif arg1 and strlen(arg1) == 6 and strmatch(arg1, "%x") and arg2 == nil and arg3 == nil then
                -- Hex source
                local rhex, ghex, bhex = string.sub(arg1, 1, 2), string.sub(arg1, 3, 4), string.sub(arg1, 5, 6)
                if strmatch(rhex, "%x") and strmatch(ghex, "%x") and strmatch(bhex, "%x") then
                    LeaPlusLC:Print("Source: |cffffffff" .. strupper(arg1))
                    LeaPlusLC:Print("Wow: |cffffffff" .. string.format("%.1f", tonumber(rhex, 16) / 255) .. "  " .. string.format("%.1f", tonumber(ghex, 16) / 255) .. "  " .. string.format("%.1f", tonumber(bhex, 16) / 255))
                    LeaPlusLC:Print("RGB: |cffffffff" .. tonumber(rhex, 16) .. "  " .. tonumber(ghex, 16) .. "  " .. tonumber(bhex, 16))
                else
                    LeaPlusLC:Print("Invalid arguments.")
                end
                LeaPlusLC:Print("|n")
            else
                LeaPlusLC:Print("Invalid arguments.")
            end
            return
        elseif str == "click" then
            -- Click a button
            local frame = GetMouseFocus()
            local ftype = frame:GetObjectType()
            if frame and ftype and ftype == "Button" then
                frame:Click()
            else
                LeaPlusLC:Print("Hover the pointer over a button.")
            end
            return
        elseif str == "frame" then
            -- Print frame name under mouse
            local frame = GetMouseFocus()
            local ftype = frame:GetObjectType()
            if frame and ftype then
                local fname = frame:GetName()
                local issecure, tainted = issecurevariable(fname)
                if issecure then
                    issecure = "Yes"
                else
                    issecure = "No"
                end
                if tainted then
                    tainted = "Yes"
                else
                    tainted = "No"
                end
                if fname then
                    LeaPlusLC:Print("Name: |cffffffff" .. fname)
                    LeaPlusLC:Print("Type: |cffffffff" .. ftype)
                    LeaPlusLC:Print("Secure: |cffffffff" .. issecure)
                    LeaPlusLC:Print("Tainted: |cffffffff" .. tainted)
                end
            end
            return
        elseif str == "arrow" then
            -- Arrow (left: drag, shift/ctrl: rotate, mouseup: loc, pointer must be on arrow stem)
            local f = CreateFrame("Frame", nil, WorldMapFrame.ScrollContainer)
            f:SetSize(64, 64)
            f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            f:SetFrameLevel(500)
            f:SetParent(WorldMapFrame.ScrollContainer)
            f:SetScale(0.6)

            f.t = f:CreateTexture(nil, "ARTWORK")
            f.t:SetAtlas("Garr_LevelUpgradeArrow")
            f.t:SetAllPoints()

            f.f = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            f.f:SetText("0.0")

            local x = 0
            f:SetScript("OnUpdate", function()
                if IsShiftKeyDown() then
                    x = x + 0.01
                    if x > 6.3 then
                        x = 0
                    end
                    f.t:SetRotation(x)
                    f.f:SetFormattedText("%.1f", x)
                elseif IsControlKeyDown() then
                    x = x - 0.01
                    if x < 0 then
                        x = 6.3
                    end
                    f.t:SetRotation(x)
                    f.f:SetFormattedText("%.1f", x)
                end
                -- Print coordinates when mouse is in right place
                local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
                if x and y and x > 0 and y > 0 then
                    if MouseIsOver(f, -31, 31, 31, -31) then
                        ChatFrame1:Clear()
                        print(('{"Arrow", ' .. floor(x * 1000 + 0.5) / 10) .. ',', (floor(y * 1000 + 0.5) / 10) .. ', L["Step 1"], L["Start here."], arTex, nil, nil, nil, nil, nil, ' .. f.f:GetText() .. "},")
                        PlaySoundFile(567412, "Master", false, true)
                    end
                end
            end)

            f:SetMovable(true)
            f:SetScript("OnMouseDown", function(self, btn)
                if btn == "LeftButton" then
                    f:StartMoving()
                end
            end)

            f:SetScript("OnMouseUp", function()
                f:StopMovingOrSizing()
                --ChatFrame1:Clear()
                --local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
                --if x and y and x > 0 and y > 0 and MouseIsOver(f) then
                --	print(('{"Arrow", ' .. floor(x * 1000 + 0.5) / 10) .. ',', (floor(y * 1000 + 0.5) / 10) .. ', L["Step 1"], L["Start here."], ' .. f.f:GetText() .. "},")
                --end
            end)
            return
        elseif str == "dis" then
            -- Disband group
            if not LeaPlusLC:IsInLFGQueue() and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
                local x = GetNumGroupMembers() or 0
                for i = x, 1, -1 do
                    if GetNumGroupMembers() > 0 then
                        local name = GetRaidRosterInfo(i)
                        if name and name ~= UnitName("player") then
                            UninviteUnit(name)
                        end
                    end
                end
            else
                LeaPlusLC:Print("You cannot do that while in group finder.")
            end
            return
        elseif str == "reinv" then
            -- Disband and reinvite raid
            if not LeaPlusLC:IsInLFGQueue() then
                if UnitIsGroupLeader("player") then
                    -- Disband
                    local groupNames = {}
                    local x = GetNumGroupMembers() or 0
                    for i = x, 1, -1 do
                        if GetNumGroupMembers() > 0 then
                            local name = GetRaidRosterInfo(i)
                            if name and name ~= UnitName("player") then
                                UninviteUnit(name)
                                tinsert(groupNames, name)
                            end
                        end
                    end
                    -- Reinvite
                    LibCompat.After(0.1, function()
                        for k, v in pairs(groupNames) do
                            C_PartyInfo.InviteUnit(v)
                        end
                    end)
                else
                    LeaPlusLC:Print("You need to be group leader.")
                end
            else
                LeaPlusLC:Print("You cannot do that while in group finder.")
            end
            return
        elseif str == "limit" then
            -- Sound Limit
            if not LeaPlusLC.MuteFrame then
                -- Panel frame
                local frame = CreateFrame("FRAME", nil, UIParent)
                frame:SetSize(294, 86);
                frame:SetFrameStrata("FULLSCREEN_DIALOG");
                frame:SetFrameLevel(100);
                frame:SetScale(2)
                frame.tex = frame:CreateTexture(nil, "BACKGROUND");
                frame.tex:SetAllPoints();
                frame.tex:SetVertexColor(0.05, 0.05, 0.05, 0.9)
                frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton");
                frame.close:SetSize(30, 30);
                frame.close:SetPoint("TOPRIGHT", 0, 0);
                frame.close:SetScript("OnClick", function()
                    frame:Hide()
                end)
                frame:ClearAllPoints();
                frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                frame:SetClampedToScreen(true)
                frame:EnableMouse(true)
                frame:SetMovable(true)
                frame:RegisterForDrag("LeftButton")
                frame:SetScript("OnDragStart", frame.StartMoving)
                frame:SetScript("OnDragStop", function()
                    frame:StopMovingOrSizing()
                    frame:SetUserPlaced(false)
                end)
                frame:Hide()
                LeaPlusLC:CreateBar("MutePanelMainTexture", frame, 294, 86, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7, "Interface\\DressUpFrame\\DressUpBackground-NightElf1")
                -- Panel contents
                LeaPlusLC:MakeTx(frame, "Sound Limit", 16, -12)
                local endBox = LeaPlusLC:CreateEditBox("SoundEndBox", frame, 116, 10, "TOPLEFT", 16, -32, "SoundEndBox", "SoundEndBox")
                endBox:SetText(3000000)
                endBox:SetScript("OnMouseWheel", function(self, delta)
                    local endSound = tonumber(endBox:GetText())
                    if endSound then
                        if delta == 1 then
                            endSound = endSound + LeaPlusLC.SoundByte
                        else
                            endSound = endSound - LeaPlusLC.SoundByte
                        end
                        if endSound < 1 then
                            endSound = 1
                        elseif endSound >= 3000000 then
                            endSound = 3000000
                        end
                        endBox:SetText(endSound)
                    else
                        endSound = 100000
                        endBox:SetText(endSound)
                    end
                end)
                -- Set limit button
                frame.btn = LeaPlusLC:CreateButton("muteRangeButton", frame, "SET LIMIT", "TOPLEFT", 16, -72, 0, 25, true, "Click to set the sound file limit.  Use the mousewheel on the editbox along with the step buttons below to adjust the sound limit.  Acceptable range is from 1 to 3000000.  Sound files higher than this limit will be muted.")
                frame.btn:ClearAllPoints()
                frame.btn:SetPoint("LEFT", endBox, "RIGHT", 10, 0)
                frame.btn:SetScript("OnClick", function()
                    local endSound = tonumber(endBox:GetText())
                    if endSound then
                        if endSound > 3000000 then
                            endSound = 3000000
                            endBox:SetText(endSound)
                        end
                        frame.btn:SetText("WAIT")
                        LibCompat.After(0.1, function()
                            for i = 1, 3000000 do
                                MuteSoundFile(i)
                            end
                            for i = 1, endSound do
                                UnmuteSoundFile(i)
                            end
                            Sound_GameSystem_RestartSoundSystem()
                            frame.btn:SetText("SET LIMIT")
                        end)
                    else
                        frame.btn:SetText("INVALID")
                        frame.btn:EnableMouse(false)
                        LibCompat.After(2, function()
                            frame.btn:SetText("SET LIMIT")
                            frame.btn:EnableMouse(true)
                        end)
                    end
                end)
                -- Mute all button
                frame.MuteAllBtn = LeaPlusLC:CreateButton("muteMuteAllButton", frame, "MUTE ALL", "TOPLEFT", 16, -92, 0, 25, true, "Click to mute every sound in the game.")
                frame.MuteAllBtn:SetScale(0.5)
                frame.MuteAllBtn:ClearAllPoints()
                frame.MuteAllBtn:SetPoint("TOPLEFT", frame.btn, "TOPRIGHT", 20, 0)
                frame.MuteAllBtn:SetScript("OnClick", function()
                    frame.MuteAllBtn:SetText("WAIT")
                    LibCompat.After(0.1, function()
                        for i = 1, 3000000 do
                            MuteSoundFile(i)
                        end
                        Sound_GameSystem_RestartSoundSystem()
                        frame.MuteAllBtn:SetText("MUTE ALL")
                    end)
                    return
                end)
                -- Unmute all button
                frame.UnmuteAllBtn = LeaPlusLC:CreateButton("muteUnmuteAllButton", frame, "UNMUTE ALL", "TOPLEFT", 16, -92, 0, 25, true, "Click to unmute every sound in the game.")
                frame.UnmuteAllBtn:SetScale(0.5)
                frame.UnmuteAllBtn:ClearAllPoints()
                frame.UnmuteAllBtn:SetPoint("TOPLEFT", frame.MuteAllBtn, "BOTTOMLEFT", 0, -10)
                frame.UnmuteAllBtn:SetScript("OnClick", function()
                    frame.UnmuteAllBtn:SetText("WAIT")
                    LibCompat.After(0.1, function()
                        for i = 1, 3000000 do
                            UnmuteSoundFile(i)
                        end
                        Sound_GameSystem_RestartSoundSystem()
                        frame.UnmuteAllBtn:SetText("UNMUTE ALL")
                    end)
                    return
                end)
                -- Step buttons
                frame.millionBtn = LeaPlusLC:CreateButton("SoundMillionButton", frame, "1000000", "TOPLEFT", 26, -122, 0, 25, true, "Set the editbox step value to 1000000.")
                frame.millionBtn:SetScale(0.5)

                frame.hundredThousandBtn = LeaPlusLC:CreateButton("SoundHundredThousandButton", frame, "100000", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 100000.")
                frame.hundredThousandBtn:ClearAllPoints()
                frame.hundredThousandBtn:SetPoint("LEFT", frame.millionBtn, "RIGHT", 10, 0)
                frame.hundredThousandBtn:SetScale(0.5)

                frame.tenThousandBtn = LeaPlusLC:CreateButton("SoundTenThousandButton", frame, "10000", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 10000.")
                frame.tenThousandBtn:ClearAllPoints()
                frame.tenThousandBtn:SetPoint("LEFT", frame.hundredThousandBtn, "RIGHT", 10, 0)
                frame.tenThousandBtn:SetScale(0.5)

                frame.thousandBtn = LeaPlusLC:CreateButton("SoundThousandButton", frame, "1000", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 1000.")
                frame.thousandBtn:ClearAllPoints()
                frame.thousandBtn:SetPoint("LEFT", frame.tenThousandBtn, "RIGHT", 10, 0)
                frame.thousandBtn:SetScale(0.5)

                frame.hundredBtn = LeaPlusLC:CreateButton("SoundHundredButton", frame, "100", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 100.")
                frame.hundredBtn:ClearAllPoints()
                frame.hundredBtn:SetPoint("LEFT", frame.thousandBtn, "RIGHT", 10, 0)
                frame.hundredBtn:SetScale(0.5)

                frame.tenBtn = LeaPlusLC:CreateButton("SoundTenButton", frame, "10", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 10.")
                frame.tenBtn:ClearAllPoints()
                frame.tenBtn:SetPoint("LEFT", frame.hundredBtn, "RIGHT", 10, 0)
                frame.tenBtn:SetScale(0.5)

                frame.oneBtn = LeaPlusLC:CreateButton("SoundTenButton", frame, "1", "TOPLEFT", 16, -112, 0, 25, true, "Set the editbox step value to 1.")
                frame.oneBtn:ClearAllPoints()
                frame.oneBtn:SetPoint("LEFT", frame.tenBtn, "RIGHT", 10, 0)
                frame.oneBtn:SetScale(0.5)

                local function DimAllBoxes()
                    frame.millionBtn:SetAlpha(0.3)
                    frame.hundredThousandBtn:SetAlpha(0.3)
                    frame.tenThousandBtn:SetAlpha(0.3)
                    frame.thousandBtn:SetAlpha(0.3)
                    frame.hundredBtn:SetAlpha(0.3)
                    frame.tenBtn:SetAlpha(0.3)
                    frame.oneBtn:SetAlpha(0.3)
                end

                LeaPlusLC.SoundByte = 1000000
                DimAllBoxes()
                frame.millionBtn:SetAlpha(1)

                -- Step button handlers
                frame.millionBtn:SetScript("OnClick", function()
                    LeaPlusLC.SoundByte = 1000000
                    DimAllBoxes()
                    frame.millionBtn:SetAlpha(1)
                end)

                frame.hundredThousandBtn:SetScript("OnClick", function()
                    LeaPlusLC.SoundByte = 100000
                    DimAllBoxes()
                    frame.hundredThousandBtn:SetAlpha(1)
                end)

                frame.tenThousandBtn:SetScript("OnClick", function()
                    LeaPlusLC.SoundByte = 10000
                    DimAllBoxes()
                    frame.tenThousandBtn:SetAlpha(1)
                end)

                frame.thousandBtn:SetScript("OnClick", function()
                    LeaPlusLC.SoundByte = 1000
                    DimAllBoxes()
                    frame.thousandBtn:SetAlpha(1)
                end)

                frame.hundredBtn:SetScript("OnClick", function()
                    LeaPlusLC.SoundByte = 100
                    DimAllBoxes()
                    frame.hundredBtn:SetAlpha(1)
                end)

                frame.tenBtn:SetScript("OnClick", function()
                    LeaPlusLC.SoundByte = 10
                    DimAllBoxes()
                    frame.tenBtn:SetAlpha(1)
                end)

                frame.oneBtn:SetScript("OnClick", function()
                    LeaPlusLC.SoundByte = 1
                    DimAllBoxes()
                    frame.oneBtn:SetAlpha(1)
                end)

                -- Final code
                LeaPlusLC.MuteFrame = frame
                _G["LeaPlusGlobalMutePanel"] = frame
                table.insert(UISpecialFrames, "LeaPlusGlobalMutePanel")
            end
            if LeaPlusLC.MuteFrame:IsShown() then
                LeaPlusLC.MuteFrame:Hide()
            else
                LeaPlusLC.MuteFrame:Show()
            end
            return
        elseif str == "mem" or str == "m" then
            -- Show addon panel with memory usage
            if LeaPlusLC.ShowMemoryUsage then
                LeaPlusLC:ShowMemoryUsage(LeaPlusLC["Page8"], "TOPLEFT", 146, -262)
            end
            -- Prevent options panel from showing if a game options panel is showing
            if InterfaceOptionsFrame:IsShown() or VideoOptionsFrame:IsShown() or ChatConfigFrame:IsShown() then
                return
            end
            -- Prevent options panel from showing if Blizzard Store is showing
            if StoreFrame and StoreFrame:GetAttribute("isshown") then
                return
            end
            -- Toggle the options panel if game options panel is not showing
            if LeaPlusLC:IsPlusShowing() then
                LeaPlusLC:HideFrames()
                LeaPlusLC:HideConfigPanels()
            else
                LeaPlusLC:HideFrames()
                LeaPlusLC["PageF"]:Show()
            end
            LeaPlusLC["Page" .. LeaPlusLC["LeaStartPage"]]:Show()
            return
        elseif str == "gossinfo" then
            -- Print gossip frame information
            if GossipFrame:IsShown() then
                local npcName = UnitName("target")
                local npcGuid = UnitGUID("target") or nil
                if npcName and npcGuid then
                    local void, void, void, void, void, npcID = strsplit("-", npcGuid)
                    if npcID then
                        LeaPlusLC:Print(npcName .. ": |cffffffff" .. npcID)
                    end
                end
                LeaPlusLC:Print("Available quests: |cffffffff" .. GetNumGossipAvailableQuests())
                LeaPlusLC:Print("Active quests: |cffffffff" .. GetNumGossipActiveQuests())
                LeaPlusLC:Print("Gossip count: |cffffffff" .. GetNumGossipOptions())
                if GetGossipOptions() then
                    local void, gossipType = GetGossipOptions()
                    LeaPlusLC:Print("Gossip type: |cffffffff" .. gossipType)
                else
                    LeaPlusLC:Print("Gossip type: |cffffffff" .. "Nil")
                end
                if GossipTitleButton1 and GossipTitleButton1:GetText() then
                    LeaPlusLC:Print("First option: |cffffffff" .. GossipTitleButton1:GetText())
                end
                -- LeaPlusLC:Print("Gossip text: |cffffffff" .. GetGossipText())
                if not IsShiftKeyDown() then
                    SelectGossipOption(1)
                end
            else
                LeaPlusLC:Print("Gossip frame not open.")
            end
            return
        elseif str == "admin" then
            -- Preset profile (used for testing)
            LpEvt:UnregisterAllEvents()                        -- Prevent changes
            wipe(LeaPlusDB)                                    -- Wipe settings
            LeaPlusLC:PlayerLogout(true)                    -- Reset permanent settings
            -- Automation
            LeaPlusDB["AutomateQuests"] = "On"                -- Automate quests
            LeaPlusDB["AutoQuestShift"] = "Off"                -- Automate quests requires shift
            LeaPlusDB["AutoQuestAvailable"] = "On"            -- Accept available quests
            LeaPlusDB["AutoQuestCompleted"] = "On"            -- Turn-in completed quests
            LeaPlusDB["AutoQuestKeyMenu"] = 1                -- Automate quests override key
            LeaPlusDB["AutomateGossip"] = "On"                -- Automate gossip
            LeaPlusDB["AutoAcceptSummon"] = "On"            -- Accept summon
            LeaPlusDB["AutoAcceptRes"] = "On"                -- Accept resurrection
            LeaPlusDB["AutoReleasePvP"] = "On"                -- Release in PvP
            LeaPlusDB["AutoSpiritRes"] = "On"                -- Release in PvP
            LeaPlusDB["AutoSellJunk"] = "On"                -- Sell junk automatically
            LeaPlusDB["AutoSellExcludeList"] = ""            -- Sell junk exclusions list
            LeaPlusDB["AutoRepairGear"] = "On"                -- Repair automatically

            -- Social
            LeaPlusDB["NoDuelRequests"] = "On"                -- Block duels
            LeaPlusDB["NoPartyInvites"] = "Off"                -- Block party invites
            LeaPlusDB["NoGuildInvites"] = "Off"                -- Block party invites
            -- LeaPlusDB["NoFriendRequests"] = "Off"			-- Block friend requests
            LeaPlusDB["NoSharedQuests"] = "Off"                -- Block shared quests

            LeaPlusDB["AcceptPartyFriends"] = "On"            -- Party from friends
            LeaPlusDB["InviteFromWhisper"] = "On"            -- Invite from whispers
            LeaPlusDB["InviteFriendsOnly"] = "On"            -- Restrict invites to friends
            LeaPlusDB["FriendlyGuild"] = "On"                -- Friendly guild

            -- Chat
            LeaPlusDB["UseEasyChatResizing"] = "On"            -- Use easy resizing
            LeaPlusDB["NoCombatLogTab"] = "On"                -- Hide the combat log
            LeaPlusDB["NoChatButtons"] = "On"                -- Hide chat buttons
            LeaPlusDB["UnclampChat"] = "On"                    -- Unclamp chat frame
            LeaPlusDB["MoveChatEditBoxToTop"] = "On"        -- Move editbox to top
            LeaPlusDB["MoreFontSizes"] = "On"                -- More font sizes
            LeaPlusDB["AltClickInv"] = "On"                -- More font sizes

            LeaPlusDB["NoStickyChat"] = "On"                -- Disable sticky chat
            LeaPlusDB["UseArrowKeysInChat"] = "On"            -- Use arrow keys in chat
            LeaPlusDB["NoChatFade"] = "On"                    -- Disable chat fade
            LeaPlusDB["UnivGroupColor"] = "On"                -- Universal group color
            LeaPlusDB["ClassColorsInChat"] = "On"            -- Use class colors in chat
            LeaPlusDB["RecentChatWindow"] = "On"            -- Recent chat window
            LeaPlusDB["RecentChatSize"] = 170                -- Recent chat size
            LeaPlusDB["MaxChatHstory"] = "Off"                -- Increase chat history
            LeaPlusDB["FilterChatMessages"] = "On"            -- Filter chat messages
            LeaPlusDB["BlockSpellLinks"] = "On"                -- Block spell links
            LeaPlusDB["BlockDrunkenSpam"] = "On"            -- Block drunken spam
            LeaPlusDB["BlockDuelSpam"] = "On"                -- Block duel spam
            LeaPlusDB["RestoreChatMessages"] = "On"            -- Restore chat messages

            -- Text
            LeaPlusDB["HideErrorMessages"] = "On"            -- Hide error messages
            LeaPlusDB["NoHitIndicators"] = "On"                -- Hide portrait text
            LeaPlusDB["HideKeybindText"] = "On"                -- Hide keybind text
            LeaPlusDB["HideMacroText"] = "On"                -- Hide macro text

            LeaPlusDB["MailFontChange"] = "On"                -- Resize mail text
            LeaPlusDB["LeaPlusMailFontSize"] = 22            -- Mail font size
            LeaPlusDB["QuestFontChange"] = "On"                -- Resize quest text
            LeaPlusDB["LeaPlusQuestFontSize"] = 18            -- Quest font size
            LeaPlusDB["BookFontChange"] = "On"                -- Resize book text
            LeaPlusDB["LeaPlusBookFontSize"] = 22            -- Book font size

            -- Interface
            LeaPlusDB["MinimapModder"] = "On"                -- Enhance minimap
            LeaPlusDB["SquareMinimap"] = "On"                -- Square minimap
            LeaPlusDB["ShowWhoPinged"] = "On"                -- Show who pinged
            LeaPlusDB["CombineAddonButtons"] = "Off"        -- Combine addon buttons
            LeaPlusDB["MiniExcludeList"] = "BugSack, Leatrix_Plus" -- Excluded addon list
            LeaPlusDB["MinimapScale"] = 1.40                -- Minimap scale slider
            LeaPlusDB["MinimapSize"] = 180                    -- Minimap size slider
            LeaPlusDB["MiniClusterScale"] = 1                -- Minimap cluster scale
            LeaPlusDB["MiniAddonPanelScale"] = 1                -- Minimap cluster scale
            LeaPlusDB["MinimapNoScale"] = "Off"                -- Minimap not minimap
            LeaPlusDB["HideMiniZoneText"] = "On"            -- Hide zone text bar
            LeaPlusDB["HideMiniMapButton"] = "On"            -- Hide world map button
            LeaPlusDB["HideMiniTracking"] = "On"            -- Hide tracking button
            LeaPlusDB["HideMiniCalendar"] = "On"            -- Hide tracking button
            LeaPlusDB["HideMiniPOIArrows"] = "On"            -- Hide tracking button
            LeaPlusDB["ClockMouseover"] = "On"            -- Hide tracking button
            LeaPlusDB["MinimapA"] = "TOPRIGHT"                -- Minimap anchor
            LeaPlusDB["MinimapR"] = "TOPRIGHT"                -- Minimap relative
            LeaPlusDB["MinimapX"] = 0                        -- Minimap X
            LeaPlusDB["MinimapY"] = 0                        -- Minimap Y

            LeaPlusDB["TipModEnable"] = "On"                -- Enhance tooltip
            LeaPlusDB["LeaPlusTipSize"] = 1.25                -- Tooltip scale slider
            LeaPlusDB["TooltipAnchorMenu"] = 2                -- Tooltip anchor
            LeaPlusDB["MiniMapMailIconPos"] = 1                -- Tooltip anchor
            LeaPlusDB["MiniMapLFGIconPos"] = 4                -- Tooltip anchor
            LeaPlusDB["MiniMapBattlefieldIconPos"] = 2                -- Tooltip anchor
            LeaPlusDB["TipCursorX"] = 0                        -- X offset
            LeaPlusDB["TipCursorY"] = 0                        -- Y offset
            LeaPlusDB["EnhanceDressup"] = "On"                -- Enhance dressup
            LeaPlusDB["HideDressupStats"] = "On"            -- Hide dressup stats
            LeaPlusDB["EnhanceQuestLog"] = "On"                -- Enhance quest log
            LeaPlusDB["EnhanceQuestHeaders"] = "On"            -- Enhance quest log toggle headers
            LeaPlusDB["EnhanceQuestLevels"] = "On"            -- Enhance quest log quest levels
            LeaPlusDB["EnhanceQuestDifficulty"] = "On"        -- Enhance quest log quest difficulty

            LeaPlusDB["EnhanceProfessions"] = "On"            -- Enhance professions
            LeaPlusDB["EnhanceTrainers"] = "On"                -- Enhance trainers
            LeaPlusDB["ShowTrainAllBtn"] = "On"                -- Show train all button

            LeaPlusDB["ShowVolume"] = "On"                    -- Show volume slider
            LeaPlusDB["AhExtras"] = "On"                    -- Show auction controls
            -- LeaPlusDB["ShowCooldowns"] = "On"				-- Show cooldowns
            LeaPlusDB["DurabilityStatus"] = "On"            -- Show durability status
            LeaPlusDB["ShowVanityControls"] = "On"            -- Show vanity controls
            LeaPlusDB["ShowBagSearchBox"] = "On"            -- Show bag search box
            -- LeaPlusDB["ShowRaidToggle"] = "On"				-- Show raid button
            LeaPlusDB["ShowPlayerChain"] = "On"                -- Show player chain
            LeaPlusDB["PlayerChainMenu"] = 3                -- Player chain style
            LeaPlusDB["ShowReadyTimer"] = "On"                -- Show ready timer
            LeaPlusDB["ShowWowheadLinks"] = "On"            -- Show Wowhead links
            LeaPlusDB["WowheadLinkComments"] = "On"            -- Show Wowhead links to comments
            LeaPlusDB["ShowFlightTimes"] = "On"                -- Show flight times
            LeaPlusDB["FlightBarBackground"] = "Off"        -- Show flight times bar background
            LeaPlusDB["FlightBarDestination"] = "On"        -- Show flight times bar destination
            LeaPlusDB["FlightBarFillBar"] = "Off"            -- Show flight times bar fill mode
            LeaPlusDB["FlightBarSpeech"] = "Off"                -- Show flight times bar speech
            LeaPlusDB["FlightBarContribute"] = "On"            -- Show flight times contribute

            -- Interface: Manage frames
            LeaPlusDB["FrmEnabled"] = "On"

            LeaPlusDB["Frames"] = {}
            LeaPlusDB["Frames"]["PlayerFrame"] = {}
            LeaPlusDB["Frames"]["PlayerFrame"]["Point"] = "TOPLEFT"
            LeaPlusDB["Frames"]["PlayerFrame"]["Relative"] = "TOPLEFT"
            LeaPlusDB["Frames"]["PlayerFrame"]["XOffset"] = -35
            LeaPlusDB["Frames"]["PlayerFrame"]["YOffset"] = -14
            LeaPlusDB["Frames"]["PlayerFrame"]["Scale"] = 1.20

            LeaPlusDB["Frames"]["TargetFrame"] = {}
            LeaPlusDB["Frames"]["TargetFrame"]["Point"] = "TOPLEFT"
            LeaPlusDB["Frames"]["TargetFrame"]["Relative"] = "TOPLEFT"
            LeaPlusDB["Frames"]["TargetFrame"]["XOffset"] = 190
            LeaPlusDB["Frames"]["TargetFrame"]["YOffset"] = -14
            LeaPlusDB["Frames"]["TargetFrame"]["Scale"] = 1.20

            LeaPlusDB["ManageBuffs"] = "On"                    -- Manage buffs
            LeaPlusDB["BuffFrameA"] = "TOPRIGHT"            -- Manage buffs anchor
            LeaPlusDB["BuffFrameR"] = "TOPRIGHT"            -- Manage buffs relative
            LeaPlusDB["BuffFrameX"] = -271                    -- Manage buffs position X
            LeaPlusDB["BuffFrameY"] = 0                        -- Manage buffs position Y
            LeaPlusDB["BuffFrameScale"] = 0.8                -- Manage buffs scale

            LeaPlusDB["ManageDeBuffs"] = "On"                    -- Manage buffs
            LeaPlusDB["DebuffButton1A"] = "TOPRIGHT"            -- Manage buffs anchor
            LeaPlusDB["DebuffButton1R"] = "TOPRIGHT"            -- Manage buffs relative
            LeaPlusDB["DebuffButton1X"] = -271                    -- Manage buffs position X
            LeaPlusDB["DebuffButton1Y"] = 0                        -- Manage buffs position Y
            LeaPlusDB["DebuffButton1Scale"] = 0.8                -- Manage buffs scale

            LeaPlusDB["ManageWidget"] = "On"                -- Manage widget
            LeaPlusDB["WidgetA"] = "TOP"                    -- Manage widget anchor
            LeaPlusDB["WidgetR"] = "TOP"                    -- Manage widget relative
            LeaPlusDB["WidgetX"] = 0                        -- Manage widget position X
            LeaPlusDB["WidgetY"] = -432                        -- Manage widget position Y
            LeaPlusDB["WidgetScale"] = 1.25                    -- Manage widget scale

            LeaPlusDB["ManageFocus"] = "On"                    -- Manage focus
            LeaPlusDB["FocusA"] = "TOPLEFT"                    -- Manage focus anchor
            LeaPlusDB["FocusR"] = "TOPLEFT"                    -- Manage focus relative
            LeaPlusDB["FocusX"] = 250                        -- Manage focus position X
            LeaPlusDB["FocusY"] = -240                        -- Manage focus position Y
            LeaPlusDB["FocusScale"] = 1.00                    -- Manage focus scale

            LeaPlusDB["ManageTimer"] = "On"                    -- Manage timer
            LeaPlusDB["TimerA"] = "TOP"                        -- Manage timer anchor
            LeaPlusDB["TimerR"] = "TOP"                        -- Manage timer relative
            LeaPlusDB["TimerX"] = 0                            -- Manage timer position X
            LeaPlusDB["TimerY"] = -120                        -- Manage timer position Y
            LeaPlusDB["TimerScale"] = 1.00                    -- Manage timer scale

            LeaPlusDB["ManageDurability"] = "On"            -- Manage durability
            LeaPlusDB["DurabilityA"] = "TOPRIGHT"            -- Manage durability anchor
            LeaPlusDB["DurabilityR"] = "TOPRIGHT"            -- Manage durability relative
            LeaPlusDB["DurabilityX"] = 0                    -- Manage durability position X
            LeaPlusDB["DurabilityY"] = -170                    -- Manage durability position Y
            LeaPlusDB["DurabilityScale"] = 1.00                -- Manage durability scale

            LeaPlusDB["CombineAddonsFrameA"] = "TOPRIGHT"            -- Manage CombineAddonsFrame anchor
            LeaPlusDB["CombineAddonsFrameR"] = "TOPRIGHT"            -- Manage CombineAddonsFrame relative
            LeaPlusDB["CombineAddonsFrameX"] = 0                    -- Manage CombineAddonsFrame position X
            LeaPlusDB["CombineAddonsFrameY"] = -170                    -- Manage CombineAddonsFrame position Y
            --LeaPlusDB["CombineAddonsFrameScale"] = 1.00				-- Manage CombineAddonsFrame scale

            LeaPlusDB["ManageTracker"] = "On"                -- Manage Tracker
            LeaPlusDB["TrackerA"] = "TOPRIGHT"                -- Manage Tracker anchor
            LeaPlusDB["TrackerR"] = "TOPRIGHT"                -- Manage Tracker relative
            LeaPlusDB["TrackerX"] = 0                        -- Manage Tracker position X
            LeaPlusDB["TrackerY"] = -170                    -- Manage Tracker position Y
            LeaPlusDB["TrackerScale"] = 1.00                -- Manage Tracker scale

            LeaPlusDB["ManageVehicle"] = "On"                -- Manage vehicle
            LeaPlusDB["VehicleA"] = "TOPRIGHT"                -- Manage vehicle anchor
            LeaPlusDB["VehicleR"] = "TOPRIGHT"                -- Manage vehicle relative
            LeaPlusDB["VehicleX"] = -100                    -- Manage vehicle position X
            LeaPlusDB["VehicleY"] = -192                    -- Manage vehicle position Y
            LeaPlusDB["VehicleScale"] = 1.00                -- Manage vehicle scale

            LeaPlusDB["ClassColFrames"] = "On"                -- Class colored frames

            LeaPlusDB["NoAlerts"] = "On"                    -- Hide alerts
            LeaPlusDB["NoGryphons"] = "On"                    -- Hide gryphons
            LeaPlusDB["NoClassBar"] = "On"                    -- Hide stance bar

            -- System
            LeaPlusDB["NoScreenGlow"] = "On"                -- Disable screen glow
            LeaPlusDB["NoScreenEffects"] = "On"                -- Disable screen effects
            LeaPlusDB["SetWeatherDensity"] = "On"            -- Set weather density
            LeaPlusDB["WeatherLevel"] = 0                    -- Weather density level
            LeaPlusDB["MaxCameraZoom"] = "On"                -- Max camera zoom
            LeaPlusDB["ViewPortEnable"] = "On"                -- Enable viewport
            LeaPlusDB["NoRestedEmotes"] = "On"                -- Silence rested emotes
            --LeaPlusDB["MuteGameSounds"] = "On"				-- Mute game sounds
            --LeaPlusDB["MuteCustomSounds"] = "On"			-- Mute custom sounds
            --LeaPlusDB["MuteCustomList"] = ""				-- Mute custom sounds list

            LeaPlusDB["NoBagAutomation"] = "On"                -- Disable bag automation
            --LeaPlusDB["CharAddonList"] = "On"				-- Show character addons
            LeaPlusDB["NoConfirmLoot"] = "On"                -- Disable loot warnings
            LeaPlusDB["FasterLooting"] = "On"                -- Faster auto loot
            LeaPlusDB["FasterMovieSkip"] = "On"                -- Faster movie skip
            --LeaPlusDB["StandAndDismount"] = "On"			-- Dismount me
            --LeaPlusDB["ShowVendorPrice"] = "On"				-- Show vendor price
            LeaPlusDB["CombatPlates"] = "On"                -- Combat plates
            LeaPlusDB["EasyItemDestroy"] = "On"                -- Easy item destroy

            -- Function to assign cooldowns
            local function setIcon(pclass, pspec, sp1, pt1, sp2, pt2, sp3, pt3, sp4, pt4, sp5, pt5)
                -- Set spell ID
                if sp1 == 0 then
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R1Idn"] = ""
                else
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R1Idn"] = sp1
                end
                if sp2 == 0 then
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R2Idn"] = ""
                else
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R2Idn"] = sp2
                end
                if sp3 == 0 then
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R3Idn"] = ""
                else
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R3Idn"] = sp3
                end
                if sp4 == 0 then
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R4Idn"] = ""
                else
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R4Idn"] = sp4
                end
                if sp5 == 0 then
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R5Idn"] = ""
                else
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R5Idn"] = sp5
                end
                -- Set pet checkbox
                if pt1 == 0 then
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R1Pet"] = false
                else
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R1Pet"] = true
                end
                if pt2 == 0 then
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R2Pet"] = false
                else
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R2Pet"] = true
                end
                if pt3 == 0 then
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R3Pet"] = false
                else
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R3Pet"] = true
                end
                if pt4 == 0 then
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R4Pet"] = false
                else
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R4Pet"] = true
                end
                if pt5 == 0 then
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R5Pet"] = false
                else
                    LeaPlusDB["Cooldowns"][pclass]["S" .. pspec .. "R5Pet"] = true
                end
            end

            -- Create main table
            LeaPlusDB["Cooldowns"] = {}

            -- Create class tables
            local classList = { "WARRIOR", "PALADIN", "HUNTER", "SHAMAN", "ROGUE", "DRUID", "MAGE", "WARLOCK", "PRIEST" }
            for index = 1, #classList do
                if LeaPlusDB["Cooldowns"][classList[index]] == nil then
                    LeaPlusDB["Cooldowns"][classList[index]] = {}
                end
            end

            -- Assign cooldowns
            setIcon("WARRIOR", 1, --[[1]] 0, 0, --[[2]] 0, 0, --[[3]] 0, 0, --[[4]] 0, 0, --[[5]] 0, 0)
            setIcon("PALADIN", 1, --[[1]] 0, 0, --[[2]] 0, 0, --[[3]] 0, 0, --[[4]] 0, 0, --[[5]] 19740, 0) -- nil, nil, nil, nil, Might
            setIcon("HUNTER", 1, --[[1]] 136, 1, --[[2]] 118455, 1, --[[3]] 0, 0, --[[4]] 0, 0, --[[5]] 5384, 0) -- Mend Pet, nil, nil, nil, Feign Death
            setIcon("SHAMAN", 1, --[[1]] 0, 0, --[[2]] 0, 0, --[[3]] 0, 0, --[[4]] 215864, 0, --[[5]] 546, 0) -- nil, nil, nil, Rainfall, Water Walking
            setIcon("ROGUE", 1, --[[1]] 1784, 0, --[[2]] 0, 0, --[[3]] 0, 0, --[[4]] 2823, 0, --[[5]] 3408, 0) -- Stealth, nil, nil, Deadly Poison, Crippling Poison
            setIcon("DRUID", 1, --[[1]] 0, 0, --[[2]] 0, 0, --[[3]] 0, 0, --[[4]] 0, 0, --[[5]] 0, 0)
            setIcon("MAGE", 1, --[[1]] 235450, 0, --[[2]] 0, 0, --[[3]] 0, 0, --[[4]] 0, 0, --[[5]] 0, 0) -- Prismatic Barrier
            setIcon("WARLOCK", 1, --[[1]] 0, 0, --[[2]] 0, 0, --[[3]] 0, 0, --[[4]] 0, 0, --[[5]] 0, 0)
            setIcon("PRIEST", 1, --[[1]] 17, 0, --[[2]] 0, 0, --[[3]] 0, 0, --[[4]] 0, 0, --[[5]] 0, 0) -- Power Word: Shield

            ---- Mute game sounds (LeaPlusLC["MuteGameSounds"])
            --for k, v in pairs(LeaPlusLC["muteTable"]) do
            --	LeaPlusDB[k] = "On"
            --end
            --LeaPlusDB["MuteReady"] = "Off"	-- Mute ready check

            -- Set chat font sizes
            RunScript('for i = 1, 50 do if _G["ChatFrame" .. i] then FCF_SetChatWindowFontSize(self, _G["ChatFrame" .. i], 20) end end')

            -- Reload
            ReloadUI()
        else
            LeaPlusLC:Print("Invalid parameter.")
        end
        return
    else
        -- Prevent options panel from showing if a game options panel is showing
        if InterfaceOptionsFrame:IsShown() or VideoOptionsFrame:IsShown() or ChatConfigFrame:IsShown() then
            return
        end
        -- Prevent options panel from showing if Blizzard Store is showing
        if StoreFrame and StoreFrame:GetAttribute("isshown") then
            return
        end
        -- Toggle the options panel if game options panel is not showing
        if LeaPlusLC:IsPlusShowing() then
            LeaPlusLC:HideFrames()
            LeaPlusLC:HideConfigPanels()
        else
            LeaPlusLC:HideFrames()
            LeaPlusLC["PageF"]:Show()
        end
        LeaPlusLC["Page" .. LeaPlusLC["LeaStartPage"]]:Show()
    end
end

-- Slash command for global function
_G.SLASH_Leatrix_Plus1 = "/ltp"
-- _G.SLASH_Leatrix_Plus2 = "/leaplus"
-- _G.SLASH_Leatrix_Plus1 = "/ztp" -- temp

SlashCmdList["Leatrix_Plus"] = function(self)
    -- Run slash command function
    LeaPlusLC:SlashFunc(self)
    -- Redirect tainted variables
    RunScript('ACTIVE_CHAT_EDIT_BOX = ACTIVE_CHAT_EDIT_BOX')
    RunScript('LAST_ACTIVE_CHAT_EDIT_BOX = LAST_ACTIVE_CHAT_EDIT_BOX')
end

-- Slash command for UI reload
_G.SLASH_LEATRIX_PLUS_RL1 = "/rl"
SlashCmdList["LEATRIX_PLUS_RL"] = function()
    ReloadUI()
end

-- Replacement for broken slash command system
function leaplus(self)
    LeaPlusLC:SlashFunc(self)
end

-- To reproduce slash command bug, enter combat, enter an addn related slash command, toggle tracking on a
-- quest 4 times then click that quest in the objective tracker.

----------------------------------------------------------------------
-- 	L90: Create options panel pages (no content yet)
----------------------------------------------------------------------

-- Function to add menu button
function LeaPlusLC:MakeMN(name, text, parent, anchor, x, y, width, height)

    local mbtn = CreateFrame("Button", nil, parent)
    LeaPlusLC[name] = mbtn
    mbtn:Show();
    mbtn:SetSize(width, height)
    mbtn:SetAlpha(1.0)
    mbtn:SetPoint(anchor, x, y)

    mbtn.t = mbtn:CreateTexture(nil, "BACKGROUND")
    mbtn.t:SetAllPoints()
    mbtn.t:SetTexture("Interface\\Buttons\\WHITE8X8")
    mbtn.t:SetVertexColor(1.0, 0.5, 0.0, 0.8)
    mbtn.t:SetAlpha(0.7)
    mbtn.t:Hide()

    mbtn.s = mbtn:CreateTexture(nil, "BACKGROUND")
    mbtn.s:SetAllPoints()
    mbtn.s:SetTexture("Interface\\Buttons\\WHITE8X8")
    mbtn.s:SetVertexColor(1.0, 0.5, 0.0, 0.8)
    mbtn.s:Hide()

    mbtn.f = mbtn:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    mbtn.f:SetPoint('LEFT', 16, 0)
    mbtn.f:SetText(L[text])

    mbtn:SetScript("OnEnter", function()
        mbtn.t:Show()
    end)

    mbtn:SetScript("OnLeave", function()
        mbtn.t:Hide()
    end)

    return mbtn, mbtn.s

end

-- Function to create individual options panel pages
function LeaPlusLC:MakePage(name, title, menu, menuname, menuparent, menuanchor, menux, menuy, menuwidth, menuheight)

    -- Create frame
    local oPage = CreateFrame("Frame", nil, LeaPlusLC["PageF"]);
    LeaPlusLC[name] = oPage
    oPage:SetAllPoints(LeaPlusLC["PageF"])
    oPage:Hide();

    -- Add page title
    oPage.s = oPage:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
    oPage.s:SetPoint('TOPLEFT', 146, -16)
    oPage.s:SetText(L[title])

    -- Add menu item if needed
    if menu then
        LeaPlusLC[menu], LeaPlusLC[menu .. ".s"] = LeaPlusLC:MakeMN(menu, menuname, menuparent, menuanchor, menux, menuy, menuwidth, menuheight)
        LeaPlusLC[name]:SetScript("OnShow", function()
            LeaPlusLC[menu .. ".s"]:Show();
        end)
        LeaPlusLC[name]:SetScript("OnHide", function()
            LeaPlusLC[menu .. ".s"]:Hide();
        end)
    end

    return oPage;

end

-- Create options pages
LeaPlusLC["Page0"] = LeaPlusLC:MakePage("Page0", "Home", "LeaPlusNav0", "Home", LeaPlusLC["PageF"], "TOPLEFT", 16, -72, 112, 20)
LeaPlusLC["Page1"] = LeaPlusLC:MakePage("Page1", "Automation", "LeaPlusNav1", "Automation", LeaPlusLC["PageF"], "TOPLEFT", 16, -112, 112, 20)
LeaPlusLC["Page2"] = LeaPlusLC:MakePage("Page2", "Social", "LeaPlusNav2", "Social", LeaPlusLC["PageF"], "TOPLEFT", 16, -132, 112, 20)
LeaPlusLC["Page3"] = LeaPlusLC:MakePage("Page3", "Chat", "LeaPlusNav3", "Chat", LeaPlusLC["PageF"], "TOPLEFT", 16, -152, 112, 20)
LeaPlusLC["Page4"] = LeaPlusLC:MakePage("Page4", "Text", "LeaPlusNav4", "Text", LeaPlusLC["PageF"], "TOPLEFT", 16, -172, 112, 20)
LeaPlusLC["Page5"] = LeaPlusLC:MakePage("Page5", "Interface", "LeaPlusNav5", "Interface", LeaPlusLC["PageF"], "TOPLEFT", 16, -192, 112, 20)
LeaPlusLC["Page6"] = LeaPlusLC:MakePage("Page6", "Frames", "LeaPlusNav6", "Frames", LeaPlusLC["PageF"], "TOPLEFT", 16, -212, 112, 20)
LeaPlusLC["Page7"] = LeaPlusLC:MakePage("Page7", "System", "LeaPlusNav7", "System", LeaPlusLC["PageF"], "TOPLEFT", 16, -232, 112, 20)
LeaPlusLC["Page8"] = LeaPlusLC:MakePage("Page8", "Settings", "LeaPlusNav8", "Settings", LeaPlusLC["PageF"], "TOPLEFT", 16, -272, 112, 20)
LeaPlusLC["Page9"] = LeaPlusLC:MakePage("Page9", "Media", "LeaPlusNav9", "Media", LeaPlusLC["PageF"], "TOPLEFT", 16, -292, 112, 20)

-- Page navigation mechanism
for i = 0, LeaPlusLC["NumberOfPages"] do
    LeaPlusLC["LeaPlusNav" .. i]:SetScript("OnClick", function()
        LeaPlusLC:HideFrames()
        LeaPlusLC["PageF"]:Show();
        LeaPlusLC["Page" .. i]:Show();
        LeaPlusLC["LeaStartPage"] = i
    end)
end

-- Use a variable to contain the page number (makes it easier to move options around)
local pg;

----------------------------------------------------------------------
-- 	LC0: Welcome
----------------------------------------------------------------------

pg = "Page0";

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Welcome to Leatrix Plus.", 146, -72);
LeaPlusLC:MakeWD(LeaPlusLC[pg], "To begin, choose an options page.", 146, -92);

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Support", 146, -132);
LeaPlusLC:MakeWD(LeaPlusLC[pg], "|cff00ff00Feedback Discord:|r |cffadd8e6sattva108|r", 146, -152);
LeaPlusLC:MakeWD(LeaPlusLC[pg], "|cff00ff00Original Author:|r |cffadd8e6www.leatrix.com|r", 146, -172);

----------------------------------------------------------------------
-- 	LC1: Automation
----------------------------------------------------------------------

pg = "Page1";

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Character", 146, -72);
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutomateQuests", "Automate quests", 146, -92, false, "If checked, quests will be selected, accepted and turned-in automatically.|n|nQuests which have a gold requirement will not be turned-in automatically.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutomateGossip", "Automate gossip", 146, -112, false, "If checked, you can hold down the alt key while opening a gossip window to automatically select a single gossip item.|n|nIf the gossip item type is banker, taxi, trainer, vendor, battlemaster or stable master, gossip will be skipped without needing to hold the alt key.  You can hold the shift key down to prevent this.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoAcceptSummon", "Accept summon", 146, -132, false, "If checked, summon requests will be accepted automatically unless you are in combat.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoAcceptRes", "Accept resurrection", 146, -152, false, "If checked, resurrection requests will be accepted automatically.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoReleasePvP", "Release in PvP", 146, -172, false, "If checked, you will release automatically after you die in a battleground.|n|nYou will not release automatically if you have the ability to self-resurrect.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoSpiritRes", "Auto Spirit Res Confirm", 146, -192, false, "If checked, you will ressurect automatically after you talk to Spirit Healer.|n|nWarning: If you are higher than level 10, you will get ressurection sickness.")

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Vendors", 340, -72);
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoSellJunk", "Sell junk automatically", 340, -92, false, "If checked, all grey items in your bags will be sold automatically when you visit a merchant.|n|nYou can hold the shift key down when you talk to a merchant to override this setting.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoRepairGear", "Repair automatically", 340, -112, false, "If checked, your gear will be repaired automatically when you visit a suitable merchant.|n|nYou can hold the shift key down when you talk to a merchant to override this setting.")

LeaPlusLC:CfgBtn("AutomateQuestsBtn", LeaPlusCB["AutomateQuests"])
LeaPlusLC:CfgBtn("AutoAcceptResBtn", LeaPlusCB["AutoAcceptRes"])
LeaPlusLC:CfgBtn("AutoReleasePvPBtn", LeaPlusCB["AutoReleasePvP"])
LeaPlusLC:CfgBtn("AutoSellJunkBtn", LeaPlusCB["AutoSellJunk"])
LeaPlusLC:CfgBtn("AutoRepairBtn", LeaPlusCB["AutoRepairGear"])

----------------------------------------------------------------------
-- 	LC2: Social
----------------------------------------------------------------------

pg = "Page2";

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Blocks", 146, -72);
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoDuelRequests", "Block duels", 146, -92, false, "If checked, duel requests will be blocked unless the player requesting the duel is a friend.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoPartyInvites", "Block party invites", 146, -112, false, "If checked, party invitations will be blocked unless the player inviting you is a friend.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoGuildInvites", "Block guild invites", 146, -132, false, "If checked, guild invitations will be blocked unless the player inviting you is a friend")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoSharedQuests", "Block shared quests", 146, -152, false, "If checked, shared quests will be declined unless the player sharing the quest is a friend.")

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Groups", 340, -72);
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AcceptPartyFriends", "Party from friends", 340, -92, false, "If checked, party invitations from friends will be automatically accepted unless you are queued for a battleground.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "InviteFromWhisper", "Invite from whispers", 340, -112, false, L["If checked, a group invite will be sent to anyone who whispers you with a set keyword as long as you are ungrouped, group leader or raid assistant and not queued for a battleground.|n|nFriends who message the keyword using Battle.net will not be sent a group invite if they are appearing offline.  They need to either change their online status or use character whispers."] .. "|n|n" .. L["Keyword"] .. ": |cffffffff" .. "dummy" .. "|r")

LeaPlusLC:MakeFT(LeaPlusLC[pg], "For all of the social options above, you can treat guild members as friends too.", 146, 380)
LeaPlusLC:MakeCB(LeaPlusLC[pg], "FriendlyGuild", "Guild", 146, -282, false, "If checked, members of your guild will be treated as friends for all of the options on this page.")

if LeaPlusCB["FriendlyGuild"].f:GetStringWidth() > 90 then
    LeaPlusCB["FriendlyGuild"].f:SetWidth(90)
    LeaPlusCB["FriendlyGuild"]:SetHitRectInsets(0, -84, 0, 0)
end

LeaPlusLC:CfgBtn("InvWhisperBtn", LeaPlusCB["InviteFromWhisper"])

----------------------------------------------------------------------
-- 	LC3: Chat
----------------------------------------------------------------------

pg = "Page3";

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Chat Frame", 146, -72);
LeaPlusLC:MakeCB(LeaPlusLC[pg], "UseEasyChatResizing", "Use easy resizing", 146, -92, true, "If checked, dragging the General chat tab while the chat frame is locked will expand the chat frame upwards.|n|nIf the chat frame is unlocked, dragging the General chat tab will move the chat frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoCombatLogTab", "Hide the combat log", 146, -112, true, "If checked, the combat log will be hidden.|n|nThe combat log must be docked in order for this option to work.|n|nIf the combat log is undocked, you can dock it by dragging the tab (and reloading your UI) or by resetting the chat windows (from the chat menu).")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoChatButtons", "Hide chat buttons", 146, -132, true, "If checked, chat frame buttons will be hidden.|n|nClicking chat tabs will automatically show the latest messages.|n|nUse the mouse wheel to scroll through the chat history.  Hold down SHIFT for page jump or CTRL to jump to the top or bottom of the chat history.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "UnclampChat", "Unclamp chat frame", 146, -152, true, "If checked, you will be able to drag the chat frame to the edge of the screen.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "MoveChatEditBoxToTop", "Move editbox to top", 146, -172, true, "If checked, the editbox will be moved to the top of the chat frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "MoreFontSizes", "More font sizes", 146, -192, true, "If checked, additional font sizes will be available in the chat frame font size menu.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AltClickInv", "Alt click for Party Invite", 146, -212, true, "If checked, you will be able to invite to party by simply holding ALT key when clicking on chat name.")

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Mechanics", 340, -72);
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoStickyChat", "Disable sticky chat", 340, -92, true, "If checked, sticky chat will be disabled.|n|nNote that this does not apply to temporary chat windows.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "UseArrowKeysInChat", "Use arrow keys in chat", 340, -112, true, "If checked, you can press the arrow keys to move the insertion point left and right in the chat frame.|n|nIf unchecked, the arrow keys will use the default keybind setting.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoChatFade", "Disable chat fade", 340, -132, true, "If checked, chat text will not fade out after a time period.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "UnivGroupColor", "Universal group color", 340, -152, false, "If checked, raid chat will be colored blue (to match the default party chat color).")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ClassColorsInChat", "Use class colors in chat", 340, -172, true, "If checked, class colors will be used in the chat frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "RecentChatWindow", "Recent chat window", 340, -192, true, "If checked, you can hold down the control key and click a chat tab to view recent chat in a copy-friendly window.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "MaxChatHstory", "Increase chat history", 340, -212, true, "If checked, your chat history will increase to 4096 lines.  If unchecked, the default will be used (128 lines).|n|nEnabling this option may prevent some chat text from showing during login.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "FilterChatMessages", "Filter chat messages", 340, -232, true, "If checked, you can block spell links, drunken spam and duel spam.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "RestoreChatMessages", "Restore chat messages", 340, -252, true, "If checked, recent chat will be restored when you reload your interface.")

LeaPlusLC:CfgBtn("FilterChatMessagesBtn", LeaPlusCB["FilterChatMessages"])

----------------------------------------------------------------------
-- 	LC4: Text
----------------------------------------------------------------------

pg = "Page4";

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Visibility", 146, -72);
LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideErrorMessages", "Hide error messages", 146, -92, false, "If checked, most error messages (such as 'Not enough rage') will not be shown.  Some important errors are excluded.|n|nIf you have the minimap button enabled, you can hold down the alt key and click it to toggle error messages without affecting this setting.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoHitIndicators", "Hide portrait numbers", 146, -112, true, "If checked, damage and healing numbers in the player and pet portrait frames will be hidden.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideZoneText", "Hide zone text", 146, -132, true, "If checked, zone text will not be shown (eg. 'Ironforge').")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideKeybindText", "Hide keybind text", 146, -152, true, "If checked, keybind text will not be shown on action buttons.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideMacroText", "Hide macro text", 146, -172, true, "If checked, macro text will not be shown on action buttons.")

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Text Size", 340, -72);
LeaPlusLC:MakeCB(LeaPlusLC[pg], "MailFontChange", "Resize mail text", 340, -92, true, "If checked, you will be able to change the font size of standard mail text.|n|nThis does not affect mail created using templates (such as auction house invoices).")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "QuestFontChange", "Resize quest text", 340, -112, true, "If checked, you will be able to change the font size of quest text.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "BookFontChange", "Resize book text", 340, -132, true, "If checked, you will be able to change the font size of book text.")

LeaPlusLC:CfgBtn("MailTextBtn", LeaPlusCB["MailFontChange"])
LeaPlusLC:CfgBtn("QuestTextBtn", LeaPlusCB["QuestFontChange"])
LeaPlusLC:CfgBtn("BookTextBtn", LeaPlusCB["BookFontChange"])

----------------------------------------------------------------------
-- 	LC5: Interface
----------------------------------------------------------------------

pg = "Page5";

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Enhancements", 146, -72);
LeaPlusLC:MakeCB(LeaPlusLC[pg], "MinimapModder", "Enhance minimap", 146, -92, true, "If checked, you will be able to customise the minimap.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "TipModEnable", "Enhance tooltip", 146, -112, true, "If checked, the tooltip will be color coded and you will be able to modify the tooltip layout and scale.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceDressup", "Enhance dressup", 146, -132, true, "If checked, you will be able to pan (right-button) and zoom (mousewheel) in the character frame, dressup frame and inspect frame.|n|nA toggle stats button will be shown in the character frame.  You can also middle-click the character model to toggle stats.|n|nModel rotation controls will be hidden.  Buttons to toggle gear will be added to the dressup frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceQuestLog", "Enhance quest log", 146, -152, true, "If checked, you will be able to customise the quest log frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceProfessions", "Enhance professions", 146, -172, true, "If checked, the professions frame will be larger.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceTrainers", "Enhance trainers", 146, -192, true, "If checked, the skill trainer frame will be larger and feature a train all skills button.")

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Extras", 146, -232);
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowVolume", "Show volume slider", 146, -252, true, "If checked, a master volume slider will be shown in the character frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AhExtras", "Show auction controls", 146, -272, true, "If checked, additional functionality will be added to the auction house.|n|nBuyout only - create buyout auctions without filling in the starting price.|n|nGold only - set the copper and silver prices at 99 to speed up new auctions.|n|nFind item - search the auction house for the item you are selling.|n|nIn addition, the auction duration setting will be saved account-wide.", "New option: Tab Confirm.|nUse Tab instead of mouse to navigate and post items to AH - faster.")

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Extras", 340, -72);
-- LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowCooldowns"				, 	"Show cooldowns"				, 	340, -92, 	true,	"If checked, you will be able to place up to five beneficial cooldown icons above the target frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "DurabilityStatus", "Show durability status", 340, -112, true, "If checked, a button will be added to the character frame which will show your equipped item durability when you hover the pointer over it.|n|nIn addition, an overall percentage will be shown in the chat frame when you die.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowVanityControls", "Toggle helm / cloak", 340, -132, true, "If checked, helm and cloak toggle checkboxes will be shown in the character frame.|n|nYou can hold shift and right-click the checkboxes to switch layouts.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowBagSearchBox", "Show bag search box", 340, -152, true, "If checked, a bag search box will be shown in the backpack frame and the bank frame.")
-- LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowRaidToggle"			, 	"Show raid button"				,	340, -172, 	true,	"If checked, the button to toggle the raid container frame will be shown just above the raid management frame (left side of the screen) instead of in the raid management frame itself.|n|nThis allows you to toggle the raid container frame without needing to open the raid management frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowPlayerChain", "Show player chain", 340, -192, true, "If checked, you will be able to show a rare, elite or rare elite chain around the player frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowReadyTimer", "Show ready timer", 340, -212, true, "If checked, a timer will be shown under the PvP encounter ready frame so that you know how long you have left to click the enter button.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowWowheadLinks", "Show Wowhead links", 340, -232, true, "If checked, Wowhead links will be shown in the world map frame and the achievements frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowFlightTimes", "Show flight times", 340, -252, true, "If checked, flight times will be shown in the flight map and when you take a flight.")

LeaPlusLC:CfgBtn("ModMinimapBtn", LeaPlusCB["MinimapModder"])
LeaPlusLC:CfgBtn("MoveTooltipButton", LeaPlusCB["TipModEnable"])
-- LeaPlusLC:CfgBtn("EnhanceDressupBtn", LeaPlusCB["EnhanceDressup"])
LeaPlusLC:CfgBtn("EnhanceQuestLogBtn", LeaPlusCB["EnhanceQuestLog"])
LeaPlusLC:CfgBtn("EnhanceTrainersBtn", LeaPlusCB["EnhanceTrainers"])
-- LeaPlusLC:CfgBtn("CooldownsButton", LeaPlusCB["ShowCooldowns"])
LeaPlusLC:CfgBtn("ModPlayerChain", LeaPlusCB["ShowPlayerChain"])
LeaPlusLC:CfgBtn("ShowWowheadLinksBtn", LeaPlusCB["ShowWowheadLinks"])
LeaPlusLC:CfgBtn("ShowFlightTimesBtn", LeaPlusCB["ShowFlightTimes"])

----------------------------------------------------------------------
-- 	LC6: Frames
----------------------------------------------------------------------

pg = "Page6";

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Features", 146, -72);
LeaPlusLC:MakeCB(LeaPlusLC[pg], "FrmEnabled", "Manage frames", 146, -92, true, "If checked, you will be able to change the position and scale of the player frame and target frame.|n|nNote that enabling this option will prevent you from using the default UI to move the player and target frames.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageBuffs", "Manage buffs", 146, -112, true, "If checked, you will be able to change the position and scale of the buffs frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageWidget", "Manage widget", 146, -132, true, "If checked, you will be able to change the position and scale of the widget frame.|n|nThe widget frame is commonly used for showing PvP scores and tracking objectives.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageFocus", "Manage focus", 146, -152, true, "If checked, you will be able to change the position and scale of the focus frame.|n|nNote that enabling this option will prevent you from using the default UI to move the focus frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageTimer", "Manage timer", 146, -172, true, "If checked, you will be able to change the position and scale of the timer bar.|n|nThe timer bar is used for showing remaining breath when underwater as well as other things.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageDurability", "Manage durability", 146, -192, true, "If checked, you will be able to change the position and scale of the armored man durability frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageVehicle", "Manage vehicle", 146, -212, true, "If checked, you will be able to change the position and scale of the vehicle seat indicator frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ClassColFrames", "Class colored frames", 146, -232, true, "If checked, class coloring will be used in the player frame, target frame and focus frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageTracker", "Manage Quest Tracker", 146, -252, true, "If checked, you will be able to change the position and scale of the Quest Tracker frame (the one under minimap).")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageDeBuffs", "Manage Debuffs", 146, -272, true, "If checked, you will be able to change the position and scale of the debuffs frame.", "* Requires you to have some debuff in order to change position.")

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Visibility", 340, -72);
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoAlerts", "Hide alerts", 340, -92, true, "If checked, alert frames will not be shown.|n|nWhen you earn an achievement, a message will be shown in chat instead.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoGryphons", "Hide gryphons", 340, -112, true, "If checked, the main bar gryphons will not be shown.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoClassBar", "Hide stance bar", 340, -132, true, "If checked, the stance bar will not be shown.")

LeaPlusLC:CfgBtn("MoveFramesButton", LeaPlusCB["FrmEnabled"])
LeaPlusLC:CfgBtn("ManageBuffsButton", LeaPlusCB["ManageBuffs"])
LeaPlusLC:CfgBtn("ManageWidgetButton", LeaPlusCB["ManageWidget"])
LeaPlusLC:CfgBtn("ManageFocusButton", LeaPlusCB["ManageFocus"])
LeaPlusLC:CfgBtn("ManageTimerButton", LeaPlusCB["ManageTimer"])
LeaPlusLC:CfgBtn("ManageDurabilityButton", LeaPlusCB["ManageDurability"])
LeaPlusLC:CfgBtn("ManageVehicleButton", LeaPlusCB["ManageVehicle"])
LeaPlusLC:CfgBtn("ClassColFramesBtn", LeaPlusCB["ClassColFrames"])
LeaPlusLC:CfgBtn("ManageTrackerButton", LeaPlusCB["ManageTracker"])
LeaPlusLC:CfgBtn("ManageDeBuffsButton", LeaPlusCB["ManageDeBuffs"])


----------------------------------------------------------------------
-- 	LC7: System
----------------------------------------------------------------------

pg = "Page7";

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Graphics and Sound", 146, -72);
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoScreenGlow", "Disable screen glow", 146, -92, false, "If checked, the screen glow will be disabled.|n|nEnabling this option will also disable the drunken haze effect.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoScreenEffects", "Disable screen effects", 146, -112, false, "If checked, the grey screen of death and the netherworld effect will be disabled.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "SetWeatherDensity", "Set weather density", 146, -132, false, "If checked, you will be able to set the density of weather effects.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "MaxCameraZoom", "Max camera zoom", 146, -152, false, "If checked, you will be able to zoom out to a greater distance.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ViewPortEnable", "Enable viewport", 146, -172, true, "If checked, you will be able to create a viewport.  A viewport adds adjustable black borders around the game world.|n|nThe borders are placed on top of the game world but under the UI so you can place UI elements over them.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoRestedEmotes", "Silence rested emotes", 146, -192, true, "If checked, emote sounds will be silenced while your character is resting or at the Grim Guzzler.|n|nEmote sounds will be enabled at all other times.")
--LeaPlusLC:MakeCB(LeaPlusLC[pg], "MuteGameSounds"			, 	"Mute game sounds"				,	146, -212, 	false,	"If checked, you will be able to mute a selection of game sounds.")
--LeaPlusLC:MakeCB(LeaPlusLC[pg], "MuteCustomSounds"			, 	"Mute custom sounds"			,	146, -232, 	false,	"If checked, you will be able to mute your own choice of sounds.")

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Game Options", 340, -72);
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoBagAutomation", "Disable bag automation", 340, -92, true, "If checked, your bags will not be opened or closed automatically when you interact with a merchant, bank or mailbox.")
--LeaPlusLC:MakeCB(LeaPlusLC[pg], "CharAddonList"				, 	"Show character addons"			, 	340, -112, 	true,	"If checked, the addon list (accessible from the game menu) will show character based addons by default.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoConfirmLoot", "Disable loot warnings", 340, -132, false, "If checked, confirmations will no longer appear when you choose a loot roll option or attempt to sell or mail a tradable item.", "Also disables confirmation popup when you try to loot BOP item.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "FasterLooting", "Faster auto loot", 340, -152, true, "If checked, the amount of time it takes to auto loot creatures will be significantly reduced.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "FasterMovieSkip", "Faster movie skip", 340, -172, true, "If checked, you will be able to cancel cinematics without being prompted for confirmation.")
--LeaPlusLC:MakeCB(LeaPlusLC[pg], "StandAndDismount"			, 	"Dismount me"					,	340, -192, 	true,	"If checked, you will be able to set some additional rules for when your character is automatically dismounted.")
--LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowVendorPrice"			, 	"Show vendor price"				,	340, -212, 	true,	"If checked, the vendor price will be shown in item tooltips.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "CombatPlates", "Combat plates", 340, -232, true, "If checked, enemy nameplates will be shown during combat and hidden when combat ends.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "EasyItemDestroy", "Easy item destroy", 340, -252, true, "If checked, you will no longer need to type delete when destroying a superior quality item.|n|nIn addition, item links will be shown in all item destroy confirmation windows.")

LeaPlusLC:CfgBtn("SetWeatherDensityBtn", LeaPlusCB["SetWeatherDensity"])
LeaPlusLC:CfgBtn("ModViewportBtn", LeaPlusCB["ViewPortEnable"])
LeaPlusLC:CfgBtn("ModFasterLootingBtn", LeaPlusCB["FasterLooting"])
--LeaPlusLC:CfgBtn("MuteGameSoundsBtn", LeaPlusCB["MuteGameSounds"])
--LeaPlusLC:CfgBtn("MuteCustomSoundsBtn", LeaPlusCB["MuteCustomSounds"])
--LeaPlusLC:CfgBtn("DismountBtn", LeaPlusCB["StandAndDismount"])

----------------------------------------------------------------------
-- 	LC8: Settings
----------------------------------------------------------------------

pg = "Page8";

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Addon", 146, -72);
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowMinimapIcon", "Show minimap button", 146, -92, false, "If checked, a minimap button will be available.|n|nClick - Toggle options panel.|n|nRight-Click - Reload UI.")
-- todo: add more minimap button click functions
--LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowMinimapIcon"			, "Show minimap button"				, 146, -92,		false,	"If checked, a minimap button will be available.|n|nClick - Toggle options panel.|n|nSHIFT-click - Toggle music.|n|nALT-click - Toggle errors (if enabled).|n|nCTRL/SHIFT-click - Toggle Zygor (if installed).|n|nCTRL/ALT-click - Toggle windowed mode.")


LeaPlusLC:MakeTx(LeaPlusLC[pg], "Scale", 340, -72);
LeaPlusLC:MakeSL(LeaPlusLC[pg], "PlusPanelScale", "Drag to set the scale of the Leatrix Plus panel.", 1, 2, 0.1, 340, -92, "%.1f")

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Transparency", 340, -132);
LeaPlusLC:MakeSL(LeaPlusLC[pg], "PlusPanelAlpha", "Drag to set the transparency of the Leatrix Plus panel.", 0, 1, 0.1, 340, -152, "%.1f")
