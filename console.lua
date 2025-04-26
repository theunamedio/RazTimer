--[[
	Author: TheUnamed (theunamedio)
	License: MIT License
]]

local _G = _G or getfenv(0);
local RazTimer = _G.RazTimer or {};

-- Handles the /rt command which gives access to some common features of RazTimer.
-- @param message: The message passed to the command.
local function handleRazTimerCommand(message)
	RazTimer:commandRazTimer(message);
end

-- Handles the /pull command to start a pull timer.
-- @param message: The message passed to the command.
local function handlePullCommand(message)
	RazTimer:commandPull("TimerComm+BigWigs", message);
end

-- Handles the /rpull command to start a pull timer using RazTimer.
-- @param message: The message passed to the command.
local function handleRazPullCommand(message)
	RazTimer:commandPull("TimerComm", message);
end

-- Handles the /bwpull command to start a pull timer using BigWigs.
-- @param message: The message passed to the command.
local function handleBigWigsPullCommand(message)
	RazTimer:commandPull("BigWigs", message);
end

-- Registration of the commands
SLASH_RT1 = "/rt";
SlashCmdList.RT = handleRazTimerCommand;

SLASH_PULL1 = "/pull";
SlashCmdList.PULL = handlePullCommand;

SLASH_RTPULL1 = "/rtpull";
SlashCmdList.RTPULL = handleRazPullCommand;

SLASH_BWPULL1 = "/bwpull";
SlashCmdList.BWPULL = handleBigWigsPullCommand;