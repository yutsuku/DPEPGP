lootWhores = {}; -- Roll Names after comma seperation
rollCount = 0; -- Count of good names
goodNames = {}; -- Validated Roll Names
newNameList = ""; -- used to redisplay all names in Input Line
goodNameList = ""; -- used to get ratios for broadcast
badNameList = ""; -- used to show bad names

-- On Load - Register for Drag
function DPEPGP_Loot_OnLoad()
	this:RegisterForDrag("LeftButton");
	DPEPGP_Loot_TitleText:SetText(lootTitleText);
	DPEPGP_Loot_DescText:SetText(lootDescText); 
	DPEPGP_AutoRoll_Warning:Hide();
	DPEPGPLootFrame:Hide();
end

--
-- Lets put all our Main Functions at the TOP --
--

function DPEPGP_AutoRoll_OnClick()
-- Hide buttons Validate and Broadcast
	DPEPGP_Validate_Button:Disable();
	DPEPGP_Broadcast_Button:Disable();
-- Show "Auto Loot On"
	DPEPGP_AutoRoll_Warning:Show();
	DPEPGP_PlayerLootNames:SetText("");
	checkForLootRolls = true;
	playerLootRolls = {};
	DPEPGP_Broadcast("DPEPGPL Loot Checking for /ROLL","C");
end

function DPEPGP_ThreeTwoOne_OnClick()
	checkForLootRolls = false;
	DPEPGP_Broadcast("DPEPGPL Loot /ROLL is now OFF","C");
	local playerRollCount = table.getn(playerLootRolls);
	DPEPGP_Broadcast(playerRollCount.." people rolled","C");
-- All players who rolled will be in the table {playerLootRolls}
-- However there may be duplicates
	local singleLootRolls = {};
	local singleName = "";
	local singleLootCount=0;
	for i = 1,playerRollCount do
		singleName = playerLootRolls[i];
		-- Use name as key to insert in {singleLootRolls}
		singleLootRolls[singleName] = "Rolled";
	end
	for k,v in pairs(singleLootRolls) do
		singleLootCount = singleLootCount + 1;
	end
--	DEFAULT_CHAT_FRAME:AddMessage("DPEPGPL Loot Name Count "..singleLootCount);
	if singleLootCount == playerRollCount then -- No duplicate rolls
		DPEPGP_Broadcast("DPEPGPL Loot  - No Duplicate Names","C");
		-- Do Nothing
	else
		playerLootRolls = {};
		for k,v in pairs(singleLootRolls) do
			table.insert(playerLootRolls,k);
		end
	end
	DPEPGP_PlayerLootNames:SetText("");
	local rollList="";
	playerRollCount = table.getn(playerLootRolls);
	for i = 1,playerRollCount do
		rollList = rollList..playerLootRolls[i];
		if i < playerRollCount then
			rollList = rollList ..","
		end
	end
	DPEPGP_PlayerLootNames:SetText(rollList);
-- Show buttons Validate and Broadcast
	DPEPGP_Validate_Button:Enable();
	DPEPGP_Broadcast_Button:Enable();
-- Hide "Auto Loot On"
	DPEPGP_AutoRoll_Warning:Hide();
end

function DPEPGP_Loot_OnEvent(event)
-- arg1=chat message
-- arg2=author
-- arg3=language
-- arg4=channel name with number ex: "1. General - Stormwind City" zone is always current zone even if not the same as the channel name
-- arg5=target second player name when two users are passed for a CHANNEL_NOTICE_USER (E.G. x kicked y)
-- arg6=AFK/DND/GM "CHAT_FLAG_"..arg6 flags
-- arg7=zone ID used for generic system channels (1 for General, 2 for Trade, 22 for LocalDefense, 23 for WorldDefense and 26 for LFG)
--     not used for custom channels or if you joined an Out-Of-Zone channel ex: "General - Stormwind City"
-- arg8=channel number
-- arg9=channel name without number (this is _sometimes_ in lowercase)
--     zone is always current zone even if not the same as the channel name
-- arg11=Chat lineID used for reporting the chat message.
-- arg12=Sender GUID
end

function DPEPGP_Validate_OnClick()
--	DEFAULT_CHAT_FRAME:AddMessage("DPEPGPL Loot Validate Names");
-- The following will parse out all the names from the list removing commas and blank spaces
	lootWhores = {} -- Table to hold parsed names from Input Line. Clear out the table
	local lootNames = DPEPGP_PlayerLootNames:GetText(); -- Get Input Line
	local nameCount = 0; -- 
	local foundName=""; -- a single name from Line Input
	local nextNames=""; -- remaining names from Line Input
	local loopCount = 0; -- safety loop to stop server crash
	if string.len(lootNames) == 0 then
		DPEPGP_Error("No names found to validate");
		return;
	end
	local foundComma = string.find(lootNames,",");
	local lootNamesLength = string.len(lootNames)
	if foundComma then -- "a,b,c" or "d," or "," or ",e"
	 	while foundComma  and lootNamesLength > 0 and loopCount < 41 do -- Possible more names
			loopCount = loopCount +1;
			foundName = string.sub(lootNames,1,foundComma-1); -- get the 1st name
			foundName = string.gsub(foundName, " ", "") -- Remove all spaces
			if string.len(foundName) > 0 then -- we actually have a name
				table.insert(lootWhores,DPEPGP_Capitalise(foundName)); -- put name in table
			end
			nextNames = string.sub(lootNames,foundComma+1); --- get the rest of Line INput
			lootNames = nextNames; -- 
			if string.len(lootNames) > 0 then -- more
				foundComma = string.find(lootNames,",");
			else
				foundComma = false;
			end
		end
-- No more "," found
		lootNames = string.gsub(lootNames, " ", "") -- Remove all spaces
		if string.len(lootNames) > 0 then -- last name
			table.insert(lootWhores,DPEPGP_Capitalise(lootNames));
		end
	else -- no "," found at start
		-- Possible last name or blank or only name
		lootNames = string.gsub(lootNames, " ", "") -- Remove all spaces
		if string.len(lootNames) > 0 then
			table.insert(lootWhores,DPEPGP_Capitalise(lootNames));
		end
--  All names have now been taken from Input Line and are in the table
	end
	rollCount = table.getn(lootWhores); -- count of names that rolled - may contain duplicates
	if rollCount == 0 then
		DPEPGP_Broadcast("No names found to validate","E");
		return;
	end
-- Now we need to check each name to see if they are in the guild
-- Good Names go in {goodNames} + Guild Level + EP/GP also put them back in DPEPGP_PlayerLootNames 
-- Bad Names go to DPEPGP_BadNames_Text
	DPEPGP_flushEPGP(); -- In Functions
	DPEPGP_Broadcast("Validating names","C");
	newNameList = ""; -- used to redisplay all names in Input Line
	goodNameList = ""; -- used to get ratios for broadcast
	badNameList = ""; -- used to show bad names
	for i = 1,rollCount do
		local nameFound = false;
		local searchName = lootWhores[i]; -- get a name from the table
		DPEPGP_Broadcast("Validating "..searchName,"C");
		if string.len(newNameList) == 0 then
			newNameList = searchName; -- First valid name
		else
			newNameList = newNameList..","..searchName -- Subsequent names need to be delimmited by a comma
		end
		for j = 1,GetNumGuildMembers() do -- search all of Guild Roster for this name
			local name,rank,rankIndex,level,class,location,ginfo,officerInfo=GetGuildRosterInfo(j);
			if name == searchName then -- Found in Guild
				local playerLevel = DPEPGP_Convert_Rank(rankIndex); -- M/C/A/@
				if string.len(goodNameList) == 0 then
					goodNameList = searchName; -- First valid name
				else
					goodNameList = goodNameList..","..searchName -- Subsequent names need to be delimmited by a comma
				end
				nameFound = true;
			end
			if nameFound then -- found the player no need to continue the loop
				break;
			end
		end
		if nameFound then
			DPEPGP_PlayerLootNames:SetText(newNameList);
		else
			badNameList = badNameList..searchName.."\n"
			DPEPGP_BadNames_Text:SetText(badNameList);
		end	
	end
	DPEPGP_PlayerLootNames:SetText(newNameList); -- This will clear Name List when only one and it is bad
	DPEPGP_BadNames_Text:SetText(badNameList); -- This will clear bad names when none found
-- OK. At this point Good Names should be back in the Edit Box
-- Bad Names should be in Frame 3
--
-- Sort {goodRatios} by highest and put the results {goodNames}{goodRatios} into DPEPGP_Preview_Text
	if string.len(goodNameList) > 0 then -- we found good names in the list now get ratios
		DPEPGP_flushEPGP(); -- In Functions
		local displayNames = DPEPGP_GetBestRatio(goodNameList);
		DPEPGP_Preview_Text:SetText(displayNames);
	end
end

function DPEPGP_Convert_Rank(level)
-- Current Rank Levels 
-- 0/Guild Leader(M)
-- 1/Officer(M)
-- 2/Manager(M)
-- 3/Alter(M) 
-- 4/Member(V)
-- 5/Social(M)
-- 6/Alt(C)
	if level == 6 then 
		return "-(alt)";
	elseif level == 5 then
		return "";
	elseif level == 4 then
		return "";
	elseif level == 3 then
		return "-(alt)";
	elseif level == 2 then
		return "";
	else
		return "";
	end
end

function DPEPGP_Broadcast_OnClick()
--	DEFAULT_CHAT_FRAME:AddMessage("DPEPGPL Loot Broadcast");
--  goodNameList will contain all valid guild members
--  Just call Falia's code using this
	DPEPGP_BestRatio_OnClick(goodNameList);
	DPEPGP_PlayerLootNames:SetText(""); -- clear Name List
end

--function DPEPGP_BestRatio_OnClick()
function DPEPGP_BestRatio_OnClick(list)
	DPEPGP_flushEPGP(); -- In Functions
	local players = list;
--	local ratioString = GetBestRatio(players);
	local ratioString = DPEPGP_GetBestRatio(players);
-- the string ratioString can get too big to display and may cause confusion
	if rollCount > 5 then
		local rollCountFive = "";
		local foundSlashN = 0;
		local start = 1;
		for i = 1,6 do -- find 1st six occurance of "\n"
			foundSlashN = string.find(ratioString,"\n");
			rollCountFive = rollCountFive..string.sub(ratioString,start,foundSlashN);
			if i == 1 then
				rollCountFive = rollCountFive.." "..rollCount.." rolled. Displaying top five".."\n";
			else
--				rollCountFive = rollCountFive.."\n";
			end
			local NextBit = string.sub(ratioString,foundSlashN + 1); -- remove the bit just processed
			ratioString = NextBit
		end
		ratioString = rollCountFive;
	end
	DPEPGP_Broadcast(ratioString,"T");
end

function DPEPGP_GetBestRatio(playerNames)
	local start = 1;
	local endp = string.find(playerNames, ",",start);
	if endp==nil then
		return "Only "..playerNames.." rolled: "..DPEPGP_GetEP(playerNames).."/"..DPEPGP_GetGP(playerNames).." = "..string.format("%.6f",DPEPGP_GetEP(playerNames)/DPEPGP_GetGP(playerNames));
	end;
	local playerList ={};
	local returnString = "EP, GP, Ratios:";
	local i=1; -- useless counter for safety reasons
	while endp~=nil do
		if i>40 then 
			DPEPGP_Broadcast("endless loop in GetBestRatio!" .. endp,"E"); 
		else-- to ensure we don't end up in an endless loop (and crash the server)
			table.insert(playerList, string.sub(playerNames,start,endp-1));
			i=i+1;
			start = endp+1;
			endp = string.find(playerNames,",",start);
		end
	end
	table.insert(playerList, string.sub(playerNames,start));
	local i=1;
	local playerRank = "X";
	local playerClass = "Noob";
	while i < table.getn(playerList) do
		j=i+1;
		while j <= table.getn(playerList) do
			
			if DPEPGP_GetRatio(playerList[i]) < DPEPGP_GetRatio(playerList[j])
			 or (DPEPGP_GetRatio(playerList[i]) == DPEPGP_GetRatio (playerList[j]) and DPEPGP_GetEP(playerList[i]) < DPEPGP_GetEP(playerList[j])) then
				playerList[i],playerList[j]=playerList[j],playerList[i];
			end
			j=j+1;
		end
		playerRank,playerClass = DPEPGP_GetRank(playerList[i]);
		returnString = returnString.."\n"..playerList[i]..playerRank.."-"..playerClass..": "..DPEPGP_GetEP(playerList[i]).."/"..DPEPGP_GetGP(playerList[i]).." = "..string.format("%.6f",DPEPGP_GetRatio(playerList[i]));
		i=i+1;
	end
	playerRank,playerClass = DPEPGP_GetRank(playerList[i]);
	returnString = returnString.."\n"..playerList[i]..playerRank.."-"..playerClass..": "..DPEPGP_GetEP(playerList[i]).."/"..DPEPGP_GetGP(playerList[i]).." = "..string.format("%.6f",DPEPGP_GetRatio(playerList[i]));
	return returnString;
end

function DPEPGP_GetRank(searchName)
--	DEFAULT_CHAT_FRAME:AddMessage("get Rank for "..searchName);
	for j = 1,GetNumGuildMembers() do
		local name,rank,rankIndex,level,class,location,ginfo,officerInfo=GetGuildRosterInfo(j);
		if name == searchName then -- Found in Guild
			local playerLevel = DPEPGP_Convert_Rank(rankIndex); -- M/C/A/@
--			DEFAULT_CHAT_FRAME:AddMessage("Rank "..playerLevel);
			return playerLevel,class;
		end
	end
	return "(X)","Noob";	
end