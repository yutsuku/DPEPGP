-- In theory anything put here shoud be able to be called by any of the other DPEPGP LUA files

-- Globals
DPEPGP_Global_Welcome = "Welcome to "..DPEPGP_Guild_Name.."' EPGP!";

-- Titles and Descriptions
raidDescText = "Use this form to adjust the EP for the whole Raid (On Time, Boss Kills etc)";
raidDescText = raidDescText.." or for a single Raid Member (Loot Gain, Alt in raid etc)"
--
lootDescText = "Use this form to calculate who has the highest EP/GP ratio. ";
lootDescText = lootDescText.."\nNames are validated prior to broadcast and Guild Ranks are added for clarity. ";
lootDescText = lootDescText.."\nAuto Name Input should be available soon. if the Code Monkey can stay awake";
--
decayDescText = "Weekly decay of EP & GP \n- nominally 15%";
--
badNamesText = "BadName1 \nBadName2 \nBadName3 \nBadName4 \nBadName5 \nBadName6 \nBadName7 \nBadName8";
preNamesText = "Whitez-Warrior - 2142/493 - 4.344828";
preNamesText = preNamesText.."\nKarmus-Rogue - 1291/352 - 3.667614";
preNamesText = preNamesText.."\nGiskard-Warrior - 2241/633 - 3.540284";
preNamesText = preNamesText.."\nAymz-(alt)-Hunter - 180/340 - 0.529412";

--
checkForLootRolls = false; -- Defines when we look at System Messages for loot rolls
playerLootRolls = {}; -- Holds the names of everyone who rolled

-- Functions called by Mutiple LUA's or Multiple Times
function DPEPGP_flushEPGP()
--should be called on every single call (but not on sub-calls)
	SetGuildRosterShowOffline();
	GuildRoster();	--prevents changes in guild member indices during the call
end

function DPEPGP_Error(msg)
	UIErrorsFrame:AddMessage(msg, 0.1, 1.0, 0.1, 1.0, 10)
end

function DPEPGP_Broadcast(msg,lvl)
-- Transparency is our friend so default is to tell the Raid
-- If lvl = "C" Then Default Chat Frame - Multiple messages or Dubugs
-- If lvl = "G" Then Guild Chat Only - Decay or Out Of Raid changes
-- if lvl = "t" Then Raid Chat or Default
-- if lvl = "R" Then Raid Chat if in Raid - or Guild Chat - or Default
-- if lvl = "E" Then Error Message
	if lvl == "R" then -- Raid > Guild > Chat
		if GetNumRaidMembers() > 0  then
			SendChatMessage(msg, "RAID", nil, nil);
		elseif DPEPGP_Player_Rank < 99 then
			SendChatMessage(msg, "GUILD",nil,nil);
		else
			DEFAULT_CHAT_FRAME:AddMessage(msg);
		end
	elseif lvl == "T" then -- Raid > Chat
		if GetNumRaidMembers() > 0  then
			SendChatMessage(msg, "RAID", nil, nil);
		else
			DEFAULT_CHAT_FRAME:AddMessage(msg);
		end
	elseif lvl == "G" then -- Guild > Chat
		if DPEPGP_Player_Rank < 99 then
			SendChatMessage(msg, "GUILD",nil,nil);
		else
			DEFAULT_CHAT_FRAME:AddMessage(msg);
		end
	elseif lvl == "C" then -- Chat
		DEFAULT_CHAT_FRAME:AddMessage(msg);
	elseif lvl == "E" then -- Error
		UIErrorsFrame:AddMessage(msg, 0.1, 1.0, 0.1, 1.0, 10);
	else -- Unknown
		UIErrorsFrame:AddMessage("EP/GP Broadcast Unknow - "..lvl, 0.1, 1.0, 0.1, 1.0, 10);
	end
end

function DPEPGP_AddGuild_OnClick() --DANGER! matching hardcoded values here and in Decay methods!
	local baseEP= 0;
	local baseGP= 400;
	DPEPGP_AddGuild(baseEP, baseGP);
end

function DPEPGP_AddGuild ( baseEP, baseGP)
	local i=1;
	while i <= GetNumGuildMembers() do
		DPEPGP_Add(GetGuildRosterInfo(i), baseEP, baseGP);
		i=i+1;
	end
end

function DPEPGP_Add(playerName, baseEP, baseGP)
	local id= DPEPGP_GetPlayerID(playerName);
	local minus= -1;
	local name,rank,rankIndex,level,class,location,ginfo,officerInfo=GetGuildRosterInfo(id);
	local slash = string.find(officerInfo,"/",1);
	if (slash==nil or string.find(officerInfo,"\n",slash)==nil) then
		GuildRosterSetOfficerNote(id, baseEP .. "/" .. baseGP .."\n" .. officerInfo);
		local msg = playerName .. " was added to the system with " .. baseEP .. "/" .. baseGP .. " EP/GP!";
		 DPEPGP_Broadcast(msg,"D");
	end
end

function DPEPGP_Capitalise(name)
-- Capitalise
	local upperPart = string.upper(string.sub(name,1,1));
	local lowerPart = string.lower(string.sub(name,2));
	local Caps = upperPart..lowerPart;
	return Caps;
end

function DPEPGP_IsInGuild(playerName)
	local i=0;
	while i <= GetNumGuildMembers() and playerName ~=GetGuildRosterInfo(i) do
		i=i+1;
	end
	return playerName==GetGuildRosterInfo(i);
end

function DPEPGP_AddEPTo(playerName, amount)
	local oldEP = DPEPGP_GetEP(playerName);
	local newEP = oldEP + amount;
	local i=0;
	while i <= GetNumGuildMembers() and playerName ~= GetGuildRosterInfo(i) do
		i=i+1;
	end
	local name,rank,rankIndex,level,class,location,ginfo,officerInfo=GetGuildRosterInfo(i);
	local start = 1;
	local to=  string.find(officerInfo,"/",start);
	-- rebuild officer note with new EP value
	local newEPGP = newEP .. "" .. string.sub(officerInfo,to);
	GuildRosterSetOfficerNote(i, newEPGP);
end

function DPEPGP_AddGPTo(playerName, amount)
	local amount = DPEPGP_GetGP(playerName)+ amount;
	local i=0;
	while i <= GetNumGuildMembers() and playerName ~= GetGuildRosterInfo(i) do
		i=i+1;
	end
	local name,rank,rankIndex,level,class,location,ginfo,officerInfo=GetGuildRosterInfo(i);
	local start = string.find(officerInfo,"/",1);
	local to=  string.find(officerInfo,"\n",start);
	local new = string.sub(officerInfo,1,start).. "" .. amount .. "" .. string.sub(officerInfo,to);
	GuildRosterSetOfficerNote(i, new);
end

function DPEPGP_GetPlayerID(playerName)
	local i=0;
	while i <= GetNumGuildMembers() and playerName ~= GetGuildRosterInfo(i) do
		i=i+1;
	end
	return i;
end

function DPEPGP_GetGP(playerName)
	local i=1;
	while i <= GetNumGuildMembers() and playerName ~= GetGuildRosterInfo(i) do
		i=i+1;
	end
	if (i > GetNumGuildMembers()) then
		error ("Can't find " .. playerName .. " in Guild!");
	end
	local name,rank,rankIndex,level,class,location,ginfo,officerInfo=GetGuildRosterInfo(i);
	local start = string.find(officerInfo,"/",1);
	local to=  string.find(officerInfo,"\n",start);
	return string.sub(officerInfo,start+1,to-1);
end

function DPEPGP_GetEP(playerName)
	local i=0;
	while i <= GetNumGuildMembers() and playerName ~= GetGuildRosterInfo(i) do
		i=i+1;
	end
	local name,rank,rankIndex,level,class,location,ginfo,officerInfo=GetGuildRosterInfo(i);
	local start = 1;
	local to =  string.find(officerInfo,"/",start);
	return string.sub(officerInfo,start,to-1);
end



function DPEPGP_GetRatio(playerName)
	return DPEPGP_GetEP(playerName)/DPEPGP_GetGP(playerName);
end

	
function DPEPGP_Reset(playerName, baseEP, baseGP)
	local id= DPEPGP_GetPlayerID(playerName);
	local minus= -1;
	local name,rank,rankIndex,level,class,location,ginfo,officerInfo=GetGuildRosterInfo(id);
	local start = string.find(officerInfo,"/",1);
	local to = string.find(officerInfo,"\n",start);
	if (start==nil or to==nil) then
		GuildRosterSetOfficerNote(id, baseEP .. "/" .. baseGP .."\n" .. officerInfo);
	else
		GuildRosterSetOfficerNote(id, baseEP .. "/" .. baseGP .. string.sub(officerInfo, to));
	end
end

function DPEPGP_AddPlayers( baseEP, baseGP)
	local i=1;
	while i <= GetNumRaidMembers() do
		DPEPGP_Add(GetRaidRosterInfo(i), baseEP, baseGP);
		i=i+1;
	end
end

function DPEPGP_GetEP_OnClick()
	DPEPGP_flushEPGP();
	local name = DPEPGP_GetEPInput:GetText();
	if name == nil then DEFAULT_CHAT_FRAME:AddMessage("ERROR, type in player name!"); end;
	local msg = GetEP(name);
	if msg ~= nil then
		DEFAULT_CHAT_FRAME:AddMessage(name .. " has " .. msg .. " EP.");
	else 
		DEFAULT_CHAT_FRAME:AddMessage("ERROR, can't extract EP or GP, check officer notes!");
	end
end

function DPEPGP_GetGP_OnClick()
	DPEPGP_flushEPGP();
	local name = DPEPGP_GetGPInput:GetText();
	if name == nil then DEFAULT_CHAT_FRAME:AddMessage("ERROR, type in player name!"); end;
	local msg = GetGP(name);
	if msg ~= nil then
		DEFAULT_CHAT_FRAME:AddMessage(name .. " has " .. msg .. " GP.");
	else
		DEFAULT_CHAT_FRAME:AddMessage("ERROR, can't extract EP or GP, check officer notes!");
	end
end

function DPEPGP_AddEveryone_OnClick()
	local baseEP= DPEPGP_AddPlayersInput1:GetText();
	local baseGP= DPEPGP_AddPlayersInput2:GetText();
	DPEPGP_AddPlayers(baseEP,baseGP);
end
