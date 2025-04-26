--[[
	Author: TheUnamed (theunamedio)
	License: MIT License
]]

local _G = _G or getfenv(0);
local RazTimer = _G.RazTimer or {};
local Components = AceLibrary("Components-1.0");
local Config = {};

RazTimer.config = Config;

-------------------------------------
-----     		 Local 		    -----
-------------------------------------

local function createConfigDialog(db)

	-- Generate Frame
	local configFrame = Components.Frame:newDialogBox(UIParent);
	configFrame:setPosition(db.left, db.top);
	-- configFrame:setRelativePosition("CENTER");
	configFrame:setSize(250, 250);
	configFrame:setMovable(true);

	configFrame:onHide(function ()
		Config:save();
	end);

	-- Generate Description
	local descriptionHtml = Components.SimpleHtml:new(configFrame);
	descriptionHtml:setContent([[
	<html>
		<body>
			<h1>]] .. RazTimer.name .. [[ Config</h1>
			<p>There are currently no options</p>
		</body>
	</html>]]);

	-- Generate Information Content
	local infoHtml = Components.SimpleHtml:new(configFrame);
	infoHtml:setRelativePosition("BOTTOMLEFT", configFrame, 10, 8);
	infoHtml:setSize(150, 24);
	infoHtml:setFontObject(GameFontNormalSmall);
	infoHtml:setContent([[
	<html>
		<body>
			<p>Version: ]] .. RazTimer.version .. [[</p>
			<p>Author: ]] .. RazTimer.author .. [[</p>
		</body>
	</html>]]);
	
	-- Generate Close Button
	local closeButton = Components.Button:newPanelButton(configFrame, "Save");
	closeButton:setRelativePosition("BOTTOMRIGHT", configFrame, -10, 10);
	closeButton:setSize(100, 25);
	closeButton:onClick(function ()
		Config:hide();
	end);

	return configFrame;
end

local function createSimpleAnchor(label, db)

	-- Generate Frame
	local anchorFrame = Components.Frame:newToolTip(UIParent);
	anchorFrame:setText(label);
	anchorFrame:setPosition(db.left, db.top);
	anchorFrame:setSize(db.width, db.height);
	anchorFrame:setMinSize(100, 25);
	anchorFrame:setMovable(true);
	anchorFrame:setResizable(true);

	return anchorFrame;
end

local function init()

	if not Config.configDialog then
		Config.configDialog = createConfigDialog(RazTimer.db.profile.dialogs.config);
	end
	if not Config.pullTimerMessage then
		Config.pullTimerMessage = createSimpleAnchor("Pulltimer Message", RazTimer.db.profile.anchors.pulltimermessage);
 	end
	if not Config.pullTimerBar then
		Config.pullTimerBar = createSimpleAnchor("Pulltimer Bar", RazTimer.db.profile.anchors.pulltimerbar);
	end
end

-------------------------------------
-----     		 API	        -----
-------------------------------------

function Config:show()

	init();

	Config.configDialog:show();
	Config.pullTimerMessage:show();
	Config.pullTimerBar:show();
end

function Config:hide()

	init();

	Config.configDialog:hide();
	Config.pullTimerMessage:hide();
	Config.pullTimerBar:hide();
end

function Config:toggleVisible()

	init();

	if Config.configDialog:isVisible() then
		Config:hide();
	else
		Config:show();
	end
end

function Config:save()

	init();

	local configDialogDb = RazTimer.db.profile.dialogs.config;
	configDialogDb.left, configDialogDb.top = self.configDialog:getPosition();

	RazTimer:debug("Saved config dialog (left:" .. configDialogDb.left .. ", top:" .. configDialogDb.top .. ")");

	local pullTimerMessageDb = RazTimer.db.profile.anchors.pulltimermessage;
	pullTimerMessageDb.left, pullTimerMessageDb.top = self.pullTimerMessage:getPosition();
	pullTimerMessageDb.width, pullTimerMessageDb.height = self.pullTimerMessage:getSize();

	RazTimer:debug("Saved pull timer message (left:" .. pullTimerMessageDb.left .. ", top:" .. pullTimerMessageDb.top .. ", width:" .. pullTimerMessageDb.width .. ", height:" .. pullTimerMessageDb.height .. ")");

	local pullTimerBarDb = RazTimer.db.profile.anchors.pulltimerbar;
	pullTimerBarDb.left, pullTimerBarDb.top = self.pullTimerBar:getPosition();
	pullTimerBarDb.width, pullTimerBarDb.height = self.pullTimerBar:getSize();

	RazTimer:debug("Saved pull timer bar (left:" .. pullTimerBarDb.left .. ", top:" .. pullTimerBarDb.top .. ", width:" .. pullTimerBarDb.width .. ", height:" .. pullTimerBarDb.height .. ")");
end

function Config:reset()
	-- TODO: to be implemented
end