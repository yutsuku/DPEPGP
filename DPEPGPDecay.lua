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
	this:Disable();
	getglobal('DPEPGP_Decay_EPValue'):ClearFocus()
	getglobal('DPEPGP_Decay_QueryLimit'):SetTextColor(0.5, 0.5, 0.5)
	getglobal('DPEPGP_Decay_QueryLimit'):ClearFocus()
	getglobal('DPEPGP_Decay_QueryLimit'):EnableMouse(false)
	getglobal('DPEPGP_Decay_QueryInvertal'):SetTextColor(0.5, 0.5, 0.5)
	getglobal('DPEPGP_Decay_QueryInvertal'):ClearFocus()
	getglobal('DPEPGP_Decay_QueryInvertal'):EnableMouse(false)

	DPEPGP_flushEPGP();
	DPEPGP_AddGuild_OnClick();
	DPEPGP_DecayEP(decay);
end

--function DPEPGP_DecayGP_OnClick()
function DPEPGP_DecayGP_OnClick(decay)
	this:Disable();
	getglobal('DPEPGP_Decay_GPValue'):ClearFocus()
	getglobal('DPEPGP_Decay_QueryLimit'):SetTextColor(0.5, 0.5, 0.5)
	getglobal('DPEPGP_Decay_QueryLimit'):ClearFocus()
	getglobal('DPEPGP_Decay_QueryLimit'):EnableMouse(false)
	getglobal('DPEPGP_Decay_QueryInvertal'):SetTextColor(0.5, 0.5, 0.5)
	getglobal('DPEPGP_Decay_QueryInvertal'):ClearFocus()
	getglobal('DPEPGP_Decay_QueryInvertal'):EnableMouse(false)
	
	DPEPGP_flushEPGP();
	DPEPGP_AddGuild_OnClick();
	DPEPGP_DecayGP(decay);
end

local epgp_frame = CreateFrame('Frame')

epgp_frame:Hide()
epgp_frame.elapsed = 0
epgp_frame.invertal = 1
epgp_frame.execLimit = 50
epgp_frame.TYPE_EP = 0
epgp_frame.TYPE_GP = 1
epgp_frame.operationType = -1
epgp_frame.pct = 0
epgp_frame.newData = {}

function epgp_frame:push(t)
	if getn(self.newData) > 0 then
		error('Update is still processing. Aborting')
		return
	end
	
	self.newData = t
end

function epgp_frame:setType(newType, percentage)
	if getn(self.newData) > 0 then
		error('Update is still processing. Aborting')
		return
	end
	
	if newType == self.TYPE_GP then
		self.operationType = self.TYPE_GP
		self.pct = tonumber(percentage) or 0
	elseif newType == self.TYPE_EP then
		self.operationType = self.TYPE_EP
		self.pct = tonumber(percentage) or 0
	else
		error('Unknown Decay type')
	end
end

function epgp_frame:next()
	if getn(self.newData) <= 0 then
		ChatFrame1:AddMessage('Decay finished - wait for guild message to confirm.')
		
		if self.operationType == self.TYPE_EP then
			DPEPGP_Broadcast("All players' EP decayed by " .. self.pct .. "%!", "G");
		elseif self.operationType == self.TYPE_GP then
			DPEPGP_Broadcast("All players' GP decayed by " .. self.pct .. "%!", "G")
		end

		self.elapsed = 0
		this:Hide()
		DPEPGP_DecayButton:Enable()
		DPEPGP_Decay_QueryLimit:SetTextColor(1,1,1)
		DPEPGP_Decay_QueryLimit:EnableMouse(true)
		DPEPGP_Decay_QueryInvertal:SetTextColor(1,1,1)
		DPEPGP_Decay_QueryInvertal:EnableMouse(true)
	end
	
	
	if self.operationType == self.TYPE_EP then
		-- EP decay
		local rows = 1
		for i = getn(self.newData), 1, -1 do
			if rows >= DPEPGP_QueryOptions.limit then
				return
			end
			
			DPEPGP_AddEPTo(self.newData[i].name, self.newData[i].value)
			self.newData[i] = nil
			
			rows = rows + 1
		end
	elseif self.operationType == self.TYPE_GP then
		-- GP decay
		local rows = 1
		for i = getn(self.newData), 1, -1 do
			if rows >= DPEPGP_QueryOptions.limit then
				return
			end
			
			DPEPGP_AddGPTo(self.newData[i].name, self.newData[i].value)
			self.newData[i] = nil
			
			rows = rows + 1
		end
	end
end

epgp_frame:SetScript('OnUpdate', function()
	this.elapsed = this.elapsed + arg1
	if this.elapsed >= DPEPGP_QueryOptions.invertal then
		this.elapsed = 0
		this:next()
	end
end)

epgp_frame:RegisterEvent('ADDON_LOADED')
epgp_frame:SetScript('OnEvent', function()
	if event == 'ADDON_LOADED' and arg1 == 'DPEPGP' then
		if not DPEPGP_QueryOptions then
			DPEPGP_QueryOptions = {}
			DPEPGP_QueryOptions.invertal = 1
			DPEPGP_QueryOptions.limit = 50
		end
		
		getglobal('DPEPGP_Decay_QueryLimit'):SetText(DPEPGP_QueryOptions.limit)
		getglobal('DPEPGP_Decay_QueryInvertal'):SetText(DPEPGP_QueryOptions.invertal)
	end
end)

function DPEPGP_DecayEP(percentage)
	-- percentage must be a value between 0 and 100 -- DANGER: hardcoded baseEP here and in DPEPGP_AddGuild()!
	local multiplier = percentage/100;
	local i=1;
	local name=nil;
	local baseEP=0;
	local newValue=0;
	local newData = {}
	while i <= GetNumGuildMembers() do
		name = GetGuildRosterInfo(i);
		newValue = (DPEPGP_GetEP(name)-baseEP)*multiplier;
		newValue = math.floor(newValue);
		--DPEPGP_AddEPTo(name, -newValue);
		newData[i] = {}
		newData[i].name = name;
		newData[i].value = -newValue;
		i=i+1;
	end
	ChatFrame1:AddMessage(format('EP Decay will be done in about %ds.', ceil(GetNumGuildMembers()/epgp_frame.execLimit*epgp_frame.invertal) ))
	epgp_frame:setType(epgp_frame.TYPE_EP, percentage);
	epgp_frame:push(newData);
	epgp_frame:Show();
	return;
end

function DPEPGP_DecayGP(percentage)
	-- percentage must be a value between 0 and 100 -- DANGER: hardcoded baseEP here and in DPEPGP_AddGuild()!
	local multiplier = percentage/100;
	local i=1;
	local name=nil;
	local baseGP=400; --hardcoded
	local newValue=0;
	local newData = {}
	while i <= GetNumGuildMembers() do
		name = GetGuildRosterInfo(i);
		newValue = (DPEPGP_GetGP(name)-baseGP)*multiplier;
		newValue= math.floor(newValue);
		--DPEPGP_AddGPTo(name, -newValue);
		newData[i] = {}
		newData[i].name = name;
		newData[i].value = -newValue;
		i=i+1;
	end
	ChatFrame1:AddMessage(format('GP Decay will be done in about %ds.', ceil(GetNumGuildMembers()/epgp_frame.execLimit*epgp_frame.invertal) ))
	epgp_frame:setType(epgp_frame.TYPE_GP, percentage);
	epgp_frame:push(newData);
	epgp_frame:Show();
	return;
end	
