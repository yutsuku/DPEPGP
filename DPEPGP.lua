-- All Sub functions should be available from DPEPGPFunctions.lua

DPEPGP_Main_Show = false;
DPEPGP_Player_Name = "Unknown";
DPEPGP_Guild_Name = "Unknown";
DPEPGP_Player_Rank = 7;

function DPEPGP_OnLoad()
    DEFAULT_CHAT_FRAME:AddMessage(DPEPGP_Global_Welcome)
	this:RegisterForDrag("LeftButton");
	this:RegisterEvent("VARIABLES_LOADED");
--	this:RegisterEvent("CHAT_MSG_CHANNEL");
--	this:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE");
--	this:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE_USER");
--	this:RegisterEvent("CHAT_MSG_YELL");
--	this:RegisterEvent("CHAT_MSG_LOOT");
	this:RegisterEvent("CHAT_MSG_SYSTEM");
--	this:RegisterEvent("LOOT_OPENED");
	SlashCmdList["DPEPGP"] = DPEPGP_Slash;
	SLASH_DPEPGP1 = "/epgp";
	DPEPGPFrame:Hide();
	DPEPGP_Main_Show = false;
end

function DPEPGP_Slash(msg)
	DPEPGP_Get_Player_Guild_Info();
    DEFAULT_CHAT_FRAME:AddMessage("DPEPGP: "..DPEPGP_Player_Name.."-"..DPEPGP_Guild_Name.."-"..DPEPGP_Player_Rank)
    local playerRank = tonumber(DPEPGP_Player_Rank);
	if (playerRank == 0 or playerRank == 2) then -- Guild Leader or Officer
		DPEPGP_Raid:Enable();
		DPEPGP_Loot:Enable();
		DPEPGP_Decay:Enable();
	elseif playerRank == 2 then -- Manager or Alter
		DPEPGP_Raid:Enable();
		DPEPGP_Loot:Enable();
		DPEPGP_Decay:Disable();
	elseif (playerRank == 3 or playerRank == 4) then -- Member or Social
		DPEPGP_Raid:Enable();
		DPEPGP_Loot:Enable();
		DPEPGP_Decay:Disable();
	else -- Alt(6)
		DPEPGP_Raid:Disable();
		DPEPGP_Loot:Disable();
		DPEPGP_Decay:Disable();
	end		
	if msg == "" then
		if DPEPGP_Main_Show == false then
			DPEPGPFrame:Show();
			DPEPGP_Main_Show = true;		
		else
			DPEPGPFrame:Hide();
			DPEPGP_Main_Show = false;
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("usage: /epgp - to show/hide main form")
    end
end

function DPEPGP_OnEvent(event)
	if event == "VARIABLES_LOADED" then
--		DEFAULT_CHAT_FRAME:AddMessage("DPEPGP Variables Loaded");
	elseif (event == "CHAT_MSG_YELL") then
--		DEFAULT_CHAT_FRAME:AddMessage("DPEPGP Yell");
	elseif (event == "CHAT_MSG_CHANNEL") then
--		DEFAULT_CHAT_FRAME:AddMessage("DPEPGP Channel");
	elseif (event == "CHAT_MSG_CHANNEL_NOTICE") then
--		DEFAULT_CHAT_FRAME:AddMessage("DPEPGP Channel Notice");
	elseif (event == "CHAT_MSG_CHANNEL_NOTICE_USER") then
--		DEFAULT_CHAT_FRAME:AddMessage("DPEPGP Channel Notice User");
	elseif (event == "CHAT_MSG_LOOT") then
--		DEFAULT_CHAT_FRAME:AddMessage("DPEPGP Loot");
	elseif (event == "CHAT_MSG_SYSTEM") then -- This should be in DPEPGPLoot but bugged at the moment
		if checkForLootRolls then
--			SendChatMessage("System Bug", "SAY", nil, nil);
			local msg = arg1;
			if string.find(msg,"rolls") then
				local plr = string.sub(msg,1,string.find(msg,"rolls")-2);
--				DEFAULT_CHAT_FRAME:AddMessage("DPEPGP System "..msg.."/"..plr);
				table.insert(playerLootRolls,plr);
			end
		end
	elseif (event == "LOOT_OPENED") then
		DEFAULT_CHAT_FRAME:AddMessage("DPEPGP Loot Opened");
	end
end

function DPEPGP_Raid_OnClick()
-- Clear out all of our edit boxes
	DPEPGP_RaidEP:SetText(""); -- EP for the Raid
	DPEPGP_RaidOptionalMessage:SetText(""); -- Message
	DPEPGP_PlayerName:SetText(""); -- Single Player Name
	DPEPGP_PlayerEP:SetText(""); -- Single Player EP
	DPEPGP_PlayerGP:SetText(""); -- Single Player GP
	DPEPGP_Get_Player_Guild_Info();
-- Show the frame
	DPEPGPRaidFrame:Show();
end

function DPEPGP_Loot_OnClick()
	DPEPGP_PlayerLootNames:SetText(""); -- Names List
	DPEPGP_BadNames_Text:SetText(badNamesText); -- 
	DPEPGP_Preview_Text:SetText(preNamesText);
	DPEPGP_Get_Player_Guild_Info();
	DPEPGPLootFrame:Show();
end

function DPEPGP_Decay_OnClick()
	DPEPGP_Get_Player_Guild_Info();
	DPEPGP_Decay_EPValue:SetText(""); -- Ep Decay %
	DPEPGP_Decay_GPValue:SetText(""); -- GP Decay %
	DPEPGPDecayFrame:Show();
end

function DPEPGP_Get_Player_Guild_Info()
-- Doing this on every form open because it didnt work in "variables Loaded" - sigh
-- Get Player information
	DPEPGP_Player_Name = UnitName("player");
	if IsInGuild() then
		DPEPGP_Guild_Name,_,DPEPGP_Player_Rank = GetGuildInfo("player");
	else
		DPEPGP_Guild_Name = "No Guild";
		DPEPGP_Player_Rank = 99;
	end
-- Set Frame Titles with Guild Name
	raidTitleText = DPEPGP_Guild_Name.." EP/GP Raid Interface";
	DPEPGP_Raid_TitleText:SetText(raidTitleText);
	lootTitleText = DPEPGP_Guild_Name.." EP/GP Loot Interface";
	DPEPGP_Loot_TitleText:SetText(lootTitleText);
	decayTitleText = DPEPGP_Guild_Name.." EP/GP";
	decayTitleText = decayTitleText.."\nWeekly Decay";
	DPEPGP_Decay_TitleText:SetText(decayTitleText);
end