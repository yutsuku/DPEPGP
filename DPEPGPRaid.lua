-- On Load - Register for Drag
function DPEPGP_Raid_OnLoad()
	this:RegisterForDrag("LeftButton");
	DPEPGP_Raid_TitleText:SetText(raidTitleText);
	DPEPGP_Raid_DescText:SetText(raidDescText); 
	DPEPGPRaidFrame:Hide();
end

--
-- Lets put all our Main Functions at the TOP --
--

-- Full Raid Options

-- Add EP to all in the Raid at the current Zone
function DPEPGP_AddEPZone_OnClick()
--	DEFAULT_CHAT_FRAME:AddMessage("DPEPGP Add EP Zone On Click");
	local EP = tonumber(DPEPGP_RaidEP:GetText());
	local msg = DPEPGP_RaidOptionalMessage:GetText();
	if EP then
		DPEPGP_flushEPGP(); -- in Functions
		DPEPGP_AddGuild_OnClick(); -- in Functions
		DPEPGP_AddEPToAllOnlineInRaidAndZone(EP);
		local raidMsg = EP .. " EP added to everyone online in Raid and Zone! "..msg;
		DPEPGP_Broadcast(raidMsg,"R"); -- in Functions
		DPEPGP_RaidEP:SetText("");
		DPEPGP_RaidOptionalMessage:SetText("");
	else
		DPEPGP_Broadcast("EP for the Raid is not numeric","E"); -- in Functions
	end
end

-- Add EP to all in the Raid
function DPEPGP_AddEPRaid_OnClick()
--	DEFAULT_CHAT_FRAME:AddMessage("DPEPGP Add EP Raid On Click");
	local EP = tonumber(DPEPGP_RaidEP:GetText());
	local msg = DPEPGP_RaidOptionalMessage:GetText();
	if EP then
		DPEPGP_flushEPGP();
		DPEPGP_AddGuild_OnClick();
		DPEPGP_AddEPToAllOnlineInRaid(EP);
		local msg = EP .. " EP added to everyone online in Raid! "..msg;
		DPEPGP_Broadcast(msg,"R");
		DPEPGP_RaidEP:SetText("");
		DPEPGP_RaidOptionalMessage:SetText("");
	else
		DPEPGP_Broadcast("EP for the Raid is not numeric","E");
	end
end

function DPEPGP_AddEPToAllOnlineInRaid(amount)
--	DEFAULT_CHAT_FRAME:AddMessage("DPEPGP Add EP to all in Raid");
	local i=1;
	while i<=GetNumRaidMembers() do
		if DPEPGP_IsInGuild(GetUnitName("raid"..i)) then
			DPEPGP_AddEPTo(GetUnitName("raid"..i), amount);
		else 
			DPEPGP_Broadcast(GetUnitName("raid"..i).." is not in Guild, ignoring!","C");
		end
		i=i+1;
	end
	return;
end

function DPEPGP_AddEPToAllOnlineInRaidAndZone(amount)
	-- experimental
	local i=1;
	local leaderZone=GetZoneText();
	while i<=GetNumRaidMembers() do
		local name, rank, subgroup, level, class, fileName, zone= GetRaidRosterInfo(i);
		if name~=GetUnitName("raid"..i) then
			DPEPGP_Broadcast("WoW interface hates programmers! GetRaidRosterInfo uses different ID's than Raid ID's. EP might be screwed. Tell Falia, he'll know what's up!\n" .. name .. " seems to not be " .. GetUnitName("raid"..i),"C"); 
		end
		if zone==leaderZone and DPEPGP_IsInGuild(GetUnitName("raid"..i)) then
			DPEPGP_AddEPTo(GetRaidRosterInfo(i), amount);
		else 
			if zone==leaderZone then
				DPEPGP_Broadcast(GetUnitName("raid"..i).." is not in Guild, ignoring!","C");
			else 
				DPEPGP_Broadcast(GetUnitName("raid"..i).." is not in Zone, ignoring!","C");
			end
		end
		i=i+1;
	end
	return;
end

-- Single Player Options

function DPEPGP_AddEPSingle_OnClick(msg)
	DPEPGP_flushEPGP();
	DPEPGP_AddGuild_OnClick();
-- Validate Player Name
	local playerName = DPEPGP_PlayerName:GetText();
	local capsName = "";
	if playerName == "" then
		DPEPGP_Broadcast("Player name is blank","E");
		return;
	else
		capsName = DPEPGP_Capitalise(playerName)
		DPEPGP_PlayerName:SetText(capsName);
		local i=1;
		while i <= GetNumGuildMembers() and capsName ~= GetGuildRosterInfo(i) do
			i=i+1;
		end
		if (i > GetNumGuildMembers()) then
			DPEPGP_Broadcast("Can't find " .. capsName .. " in Guild!","E");
			return;
		end
	end
-- Validate EP - Zero if Blank
	local EP = DPEPGP_PlayerEP:GetText();
	if EP == "" then
		EP = 0;
	else
		EP = tonumber(EP);
		if not EP then
			DPEPGP_Broadcast("Player EP is not numeric","E");
			return;
		end
	end
--Validate GP - Zero if Blank
	local GP = DPEPGP_PlayerGP:GetText();
	if GP == "" then
		GP = 0;
	else
		GP = tonumber(GP);
		if not GP then
			DPEPGP_Broadcast("Player GP is not numeric","E");
			return;
		end
	end
--
--	DEFAULT_CHAT_FRAME:AddMessage("DPEPGP Single Player Option "..msg.." "..EP.."/"..GP);
	if msg == "Add" then -- Add Ep and/or GP
-- Call DPEPGP_AddEPTo_OnClick
		if EP == 0 then
			DPEPGP_Broadcast("DPEPGP Single Player EP Zero","C");
		else
			DPEPGP_AddEPTo_OnClick(capsName, EP)
		end
-- Call DPEPGP_AddGPTo_OnClick
		if GP == 0 then
			DPEPGP_Broadcast("DPEPGP Single Player GP Zero","C");
		else
			DPEPGP_AddGPTo_OnClick(capsName, GP)
		end
	else -- Set EP and GP
		if GP < 100 then
			DPEPGP_Broadcast("DPEPGP can not set GP below 100","E");
		else
			DPEPGP_ResetPlayer_OnClick(capsName, EP, GP);
		end
	end
	DPEPGP_PlayerName:SetText("");
	DPEPGP_PlayerEP:SetText("");
	DPEPGP_PlayerGP:SetText("");
	DPEPGP_PlayerMessage:SetText("");
end

function DPEPGP_AddEPTo_OnClick(name, EP)
--	DEFAULT_CHAT_FRAME:AddMessage("DPEPGP Add EP to "..name.." "..EP);
	DPEPGP_flushEPGP();
	local optMsg = DPEPGP_PlayerMessage:GetText();
--	if name == nil then DEFAULT_CHAT_FRAME:AddMessage("ERROR, type in player name!"); end;
--	local EP = DPEPGP_AddEPInput2:GetText();
	local oldEP = DPEPGP_GetEP(name);
	DPEPGP_AddEPTo (name, EP);
	local msg = name .. " had " .. oldEP .. " EP. Now it's " .. oldEP +EP .. " EP. "..optMsg;
	DPEPGP_Broadcast(msg,"R");
end
	
function DPEPGP_AddGPTo_OnClick(name, GP)
--	DEFAULT_CHAT_FRAME:AddMessage("DPEPGP Add GP to"..name.." "..GP);
	DPEPGP_flushEPGP();
	local optMsg = DPEPGP_PlayerMessage:GetText();
--	local GP = DPEPGP_AddGPInput2:GetText();
	local oldGP = DPEPGP_GetGP(name);
	DPEPGP_AddGPTo (name, GP);
	local msg = name .. " had " .. oldGP .. " GP. Now it's " .. oldGP +GP .. " GP. "..optMsg;
	DPEPGP_Broadcast(msg,"R");
end

function DPEPGP_ResetPlayer_OnClick(player, baseEP, baseGP)
--	local player= DPEPGP_ResetInput1:GetText();
--	local baseEP= DPEPGP_ResetInput2:GetText();
	local optMsg = DPEPGP_PlayerMessage:GetText();
	DPEPGP_Reset(player, baseEP, baseGP);
	local msg = player .. " has been reset. " .. player .. " now has " .. baseEP .. "/" .. baseGP .. " EP/GP"
	msg = msg ..", and his/her ratio is " .. baseEP/baseGP.." "..optMsg;
	DPEPGP_Broadcast(msg,"R");
end