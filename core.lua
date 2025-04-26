--[[
	Author: TheUnamed (theunamedio)
	License: MIT License
]]

local RazTimer = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceDB-2.0", "AceModuleCore-2.0");
RazTimer.name = "RazTimer";
RazTimer.title = GetAddOnMetadata(RazTimer.name, "Title");
RazTimer.version = GetAddOnMetadata(RazTimer.name, "Version");
RazTimer.author = "TheUnamed";

local Components = AceLibrary("Components-1.0");
local Compost = AceLibrary("Compost-2.0");
local CandyBar = AceLibrary("CandyBar-2.0");

-- intern
local currentPull = nil;
local debugEnabled = true;
local displayMessageLabel = nil;
local bigWigsSkip = nil;

local defaults = {
	anchors = {
		pulltimermessage = {
			left = 0,
			top = 0,
			width = 170,
			height = 75
		},
		pulltimerbar = {
			left = 0,
			top = 0,
			width = 170,
			height = 75
		}
	},
	dialogs = {
		config = {
			left = 687.5,
			top = 332
		}
	}
};

-------------------------------------
-----       Local Utilty        -----
-------------------------------------

local function trim(s)

	return string.match(s, "^%s*(.-)%s*$");
end

-------------------------------------
-----      Initialization       -----
-------------------------------------

function RazTimer:initialize()

	self:RegisterDB("RazTimerDB");
	self:RegisterDefaults("profile", defaults);

	self:RegisterEvent("CHAT_MSG_ADDON", function(prefix, message, type, sender)
		RazTimer:CHAT_MSG_ADDON(prefix, message, type, sender);
	end);
	self:RegisterEvent("RPT_DISPLAY_MESSAGE", function(message, color)
		RazTimer:RPT_DISPLAY_MESSAGE(message, color);
	end);

	self:print("Loaded. Type /pull <duration> <title> to start a pull timer.");
end

-------------------------------------
-----      Event Handlers       -----
-------------------------------------

function RazTimer:CHAT_MSG_ADDON(prefix, message, type, sender)
	
	if type ~= "RAID" or not message then
		return
	end

	local _, sync, duration, title, hint = nil, nil, nil, nil, nil;
	if prefix == "TimerComm" then
		_, _, sync, duration, title, hint = string.find(message, "(%S+)#(%d+)#(.*)#(.*)$");
	elseif prefix == "BigWigs" then
		_, _, sync, duration = string.find(message, "(%S+)%s*(%d*)$");
	else
		return
	end

	if (prefix == "TimerComm" and hint == "rtIbw") then
		bigWigsSkip = duration;
	elseif (prefix == "BigWigs" and bigWigsSkip) then
		if (bigWigsSkip == duration) then
			bigWigsSkip = nil;
			return;
		end
		bigWigsSkip = nil;
	end

	duration = tonumber(duration);
	if (not duration) then
		return;
	end

	if sync == "StartTimer" or sync == "PulltimerSync" then
		self:displayPullTimer(duration, sender, title);
	--[[ elseif (sync == "PulltimerBroadcastSync") then
		self:displayPullTimer(duration, sender, title); ]]
	end
end

function RazTimer:RPT_DISPLAY_MESSAGE(message, color)

	local fullMessage;
	if (color) then
		if (message) then
			fullMessage = "|c" .. color .. message .. "|r";
		end
	elseif (message) then
		fullMessage = message;
	end

	if not displayMessageLabel then
		displayMessageLabel = Components.Label:new(UIParent);

		local font, _, flags = GameFontNormalLarge:GetFont();
		displayMessageLabel:setFont(font, 20, flags);
	end

	local messageConfig = RazTimer.db.profile.anchors.pulltimermessage;

	displayMessageLabel:setText(fullMessage);
	displayMessageLabel:setPosition(messageConfig.left, messageConfig.top);
	displayMessageLabel:setSize(messageConfig.width, messageConfig.height);
	displayMessageLabel:setAlpha(1);
	displayMessageLabel:show();
	displayMessageLabel:fadeOut(3, 3);
end

-------------------------------------
-----     Command Execution     -----
-------------------------------------

function RazTimer:commandRazTimer(message)

	local trimmedMessage = trim(message);
	if not trimmedMessage then
		self:print("Usage: /rt config");
		return;
	end

	if message == "config" then
		RazTimer.config:toggleVisible();
	elseif message == "reset" then
		RazTimer.config:reset();
	else
		RazTimer:print("Usage: /rt <config / reset>");
	end
end

function RazTimer:commandPull(mode, message)
	
	if (not(IsRaidLeader() or IsRaidOfficer())) then
		self:print("You have to be the raid leader or an assistant to trigger a pull timer");
		return;
	end

 	self:broadcastPullTimer(mode, self:parsePullCommand(message));
end

function RazTimer:parsePullCommand(message)

	-- split command
	local _, _, durationPart, titlePart = string.find(message, "^(%S+)%s*(%S*)$");
	titlePart = titlePart or "";

	--  allow placeholders in title
	titlePart = string.gsub(titlePart, "%%t", UnitName("target") or "");

	-- parse duration if given 
	if durationPart then

		-- simple number in seconds
		local duration = tonumber(durationPart);
		if duration then
			return duration, titlePart;
		end

		-- parse a string like "10s" or "2m 30s"
		local _, _, minutes = string.find(durationPart, "(%d+)m");
		local _, _, seconds = string.find(durationPart, "(%d+)s");

		minutes = tonumber(minutes) or 0;
		seconds = tonumber(seconds) or 0;

		duration = math.min(minutes * 60 + seconds, 3600);
		if (duration > 0) then
			return duration, titlePart;
		end
	end

	-- default to 6 seconds if no valid input is given
	return 6, titlePart;
end

function RazTimer:broadcastPullTimer(mode, duration, title)

	if (mode == "TimerComm") then
		local message = "StartTimer#" .. duration .. "#" .. title .. "#rt";
		SendAddonMessage("TimerComm", message, "RAID");
	elseif (mode == "BigWigs") then
		local message = "PulltimerSync " .. duration;
		SendAddonMessage("BigWigs", message, "RAID");
	else
		local messageRpt = "StartTimer#" .. duration .. "#" .. title .. "#rtIbw";
		local messageBw = "PulltimerSync " .. duration;
		SendAddonMessage("TimerComm", messageRpt, "RAID");
		SendAddonMessage("BigWigs", messageBw, "RAID");
	end

	-- SendAddonMessage("BigWigs", "PulltimerBroadcastSync " .. duration, "RAID");
	-- self:CHAT_MSG_ADDON(target, message, "RAID", "you");
end

-------------------------------------
-----     Pull Timer Display    -----
-------------------------------------

function RazTimer:displayPullTimer(duration, sender, title)

	local pullTimerId = "PT/" .. sender .. "/" .. duration;
	local fullTitle = title;
	if not fullTitle or (trim(fullTitle) == "") then
		fullTitle = "Pull";
	end

	self:debug(string.format("%s: Pull timer of %d seconds was started by %s", fullTitle, duration, sender));

	if currentPull and (currentPull.endTime > GetTime()) then

		self:stopPullTimerBar(currentPull.id);
		Compost:Reclaim(currentPull);
		currentPull = nil;
	end

	currentPull = Compost:GetTable();
	currentPull.id = pullTimerId;
	currentPull.endTime = GetTime() + duration;

	self:startPullTimerBar(pullTimerId, duration, fullTitle, "Interface\\Icons\\Ability_DualWield", "FF00FF00");

	self:queueMessage("Pull in 5", duration - 5, "FFFF4500");
	self:queueMessage("Pull in 4", duration - 4, "FFFF4500");
	self:queueMessage("Pull in 3", duration - 3, "FFFF4500");
	self:queueMessage("Pull in 2", duration - 2, "FFFF4500");
	self:queueMessage("Pull in 1", duration - 1, "FFFF4500");
	self:queueMessage("Pull now!", duration, "FF00FF00");
end

function RazTimer:queueMessage(message, delay, color)

	self:ScheduleEvent("RPT_DISPLAY_MESSAGE", delay, message, color);
end

function RazTimer:startPullTimerBar(name, duration, text, icon, color)

	local bar = self.db.profile.anchors.pulltimerbar
	if CandyBar:Register(name, duration, text, icon, color) then
		
		CandyBar:SetPoint(name, "BOTTOMLEFT", UIParent, "BOTTOMLEFT", bar.left + bar.height - 2, bar.top);
		CandyBar:SetWidth(name, bar.width - bar.height - 8);
		CandyBar:SetHeight(name, bar.height - 10);
		CandyBar:SetTexture(name, "Interface\\AddOns\\RazTimer\\textures\\bar");

		CandyBar:Start(name, true);
	end
end

function RazTimer:stopPullTimerBar(name)

	CandyBar:Stop(name);
end

function RazTimer:print(message)

	DEFAULT_CHAT_FRAME:AddMessage(RazTimer.title .. ": " .. message);
end

function RazTimer:debug(message)

	if debugEnabled then DEFAULT_CHAT_FRAME:AddMessage(RazTimer.title .. " [DEBUG]: " .. message); end
end

-------------------------------------
-----          Static           -----
-------------------------------------

-- initialize
RazTimer:initialize();

-- publish into global namespace
local _G = _G or getfenv(0);
_G.RazTimer = RazTimer;