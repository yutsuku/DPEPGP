-- On Load - Register for Drag
function DPEPGP_Decay_OnLoad()
	this:RegisterForDrag("LeftButton");
	DPEPGP_Decay_TitleText:SetText(decayTitleText);
	DPEPGP_Decay_DescText:SetText(decayDescText); 
	DPEPGPDecayFrame:Hide();
end

--
-- Lets put all our Main Functions at the TOP --
--

function DPEPGP_DecayButton_OnClick()
-- Validate EP and GP percentages and then call Falia's functions
	local foundEP = false;
	local foundGP = false;
	local EP = DPEPGP_Decay_EPValue:GetText();
	if EP == "" then
		EP = 0;
	else
		EP = tonumber(EP);
		if not EP then
			DPEPGP_Broadcast("EP Decay is not numeric","E");
			return;
		else
			if (EP > 99) or (EP < -99) then
				DPEPGP_Broadcast("EP Decay is too large","E");
				return;
			else
				foundEP = true;
			end
		end
	end
	local GP = DPEPGP_Decay_GPValue:GetText();
	if GP == "" then
		GP = 0;
	else
		GP = tonumber(GP);
		if not GP then
			DPEPGP_Broadcast("GP Decay is not numeric","E");
			return;
		else
			if (GP > 99) or (GP < -99) then
				DPEPGP_Broadcast("GP Decay is too large","E");
				return;
			else
				foundGP = true;
			end
		end
	end
	if foundEP and foundGP then
		DPEPGP_Broadcast("Can not process EP and GP together","E");
		DPEPGP_Broadcast("Can not process EP and GP together","C");
	else
		if EP == 0 then
			DPEPGP_Broadcast("DPEPGP Decay - Skipping EP - zero","C");
		else
			DPEPGP_DecayEP_OnClick(EP);
			DPEPGP_Decay_EPValue:SetText("");
		end
		if GP == 0 then
			DPEPGP_Broadcast("DPEPGP Decay - Skipping GP - zero","C");
		else
			DPEPGP_DecayGP_OnClick(GP);
			DPEPGP_Decay_GPValue:SetText("");
		end
	end
end

--function DPEPGP_DecayEP_OnClick()
function DPEPGP_DecayEP_OnClick(decay)
	DPEPGP_flushEPGP();
	DPEPGP_AddGuild_OnClick();
--	local decay= DPEPGP_DecayInput:GetText();
	DPEPGP_DecayEP(decay);
	local msg = "All players' EP decayed by " .. decay .. "%!";
	DPEPGP_Broadcast(msg,"G");
end

--function DPEPGP_DecayGP_OnClick()
function DPEPGP_DecayGP_OnClick(decay)
	DPEPGP_flushEPGP();
	DPEPGP_AddGuild_OnClick();
--	local decay= DPEPGP_DecayInput:GetText();
	DPEPGP_DecayGP(decay);
	local msg = "All players' GP decayed by " .. decay .. "%!";
	DPEPGP_Broadcast(msg,"G");
end

function DPEPGP_DecayEP(percentage)
	-- percentage must be a value between 0 and 100 -- DANGER: hardcoded baseEP here and in DPEPGP_AddGuild()!
	local multiplier = percentage/100;
	local i=1;
	local name=nil;
	local baseEP=0;
	local newValue=0;
	while i <= GetNumGuildMembers() do
		name = GetGuildRosterInfo(i);
		newValue = (DPEPGP_GetEP(name)-baseEP)*multiplier;
		newValue = math.floor(newValue);
		DPEPGP_AddEPTo(name, -newValue);
		i=i+1;
	end
	return;
end

function DPEPGP_DecayGP(percentage)
	-- percentage must be a value between 0 and 100 -- DANGER: hardcoded baseEP here and in DPEPGP_AddGuild()!
	local multiplier = percentage/100;
	local i=1;
	local name=nil;
	local baseGP=400; --hardcoded
	local newValue=0;
	while i <= GetNumGuildMembers() do
		name = GetGuildRosterInfo(i);
		newValue = (DPEPGP_GetGP(name)-baseGP)*multiplier;
		newValue= math.floor(newValue);
		DPEPGP_AddGPTo(name, -newValue);
		i=i+1;
	end
	return;
end	
