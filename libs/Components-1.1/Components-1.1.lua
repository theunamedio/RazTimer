--[[
    Name: Components-1.0
    Revision: 0 $
	Author: TheUnamed (theunamedio)
	License: MIT License
    Description: A library for creating and managing components for World of Warcraft addons.
    Dependencies: AceLibrary, AceEvent-2.0
]]

local vmajor, vminor = "Components-1.1", "$Revision: 20250510 $";
local pathMatchingPattern = "\\(.+)\\Components%-1%.1\\Components%-1%.1%.lua";

if not AceLibrary then error(vmajor .. " requires AceLibrary"); end
if not AceLibrary:IsNewVersion(vmajor, vminor) then return; end
if not AceLibrary:HasInstance("AceEvent-2.0") then error(vmajor .. " requires AceEvent-2.0") end

local AceEvent = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0");

-- consts --
local _, _, relativePath = string.find(debugstack(), pathMatchingPattern);
local libraryPath = "Interface\\AddOns\\" .. relativePath .. "\\" .. vmajor .. "\\";

-- factories --
local LabelFactory = {
    currentIndex = 0
};
local FrameFactory = {
    currentIndex = 0
};
local ButtonFactory = {
    currentIndex = 0
};
local ComboBoxFactory = {
    currentIndex = 0
};
local SimpleHtmlFactory = {
    currentIndex = 0
};

-- components
---> abstracts
local Component = {};

local FrameBased = {};
setmetatable(FrameBased, { __index = Component });

---> concrete 
local Label = {};
setmetatable(Label, { __index = Component });

local Frame = {};
setmetatable(Frame, { __index = FrameBased });

local Button = {};
setmetatable(Button, { __index = FrameBased });

local ComboBox = {};
setmetatable(ComboBox, { __index = FrameBased });

local SimpleHtml = {};
setmetatable(SimpleHtml, { __index = FrameBased });

-- library base --
local Components = {
    Label = LabelFactory,
    Frame = FrameFactory,
    Button = ButtonFactory,
    ComboBox = ComboBoxFactory,
    SimpleHtml = SimpleHtmlFactory
};

-------------------------------------
-----       Local Utilty        -----
-------------------------------------

local function debug(message)
	DEFAULT_CHAT_FRAME:AddMessage(message);
end

local function constructInstance(class, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9)
    
    if not class.__init__ then
        error("Class cannot be constructed because no constructor is defined");
    end

    local instance = setmetatable({}, { __index = class });
    class.__init__(instance, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);
    return instance;
end

local function safeWrappedComponent(componentOrUiObject)
    
    if not type(componentOrUiObject) == "table" then error("componentOrUiObject is not a table"); end
    if componentOrUiObject.wrappedComponent then return componentOrUiObject.wrappedComponent; end
    if componentOrUiObject.GetID then return componentOrUiObject; end
    if componentOrUiObject.GetStringWidth then return componentOrUiObject; end
    error("componentOrUiObject is not a valid component or UI object");
end

local function loadTexture(component, texturePath, layer, rightCut, bottomCut)
    
    local wrappedComponent = safeWrappedComponent(component.wrappedComponent);
    local texture = wrappedComponent:CreateTexture(nil, layer or "OVERLAY");
    texture:SetTexture(texturePath);
    texture:SetTexCoord(0, rightCut or 1, 0, bottomCut or 1);
    texture:SetAllPoints(wrappedComponent);
    return texture;
end

local function setComponentEventHandler(component, event, callback, parameterFunction)

    if callback then
        if parameterFunction then
            component.wrappedComponent:SetScript(event, function() callback(self, parameterFunction()); end);
        else
            component.wrappedComponent:SetScript(event, function() callback(self); end);
        end
    else
        component.wrappedComponent:SetScript(event, nil);
    end
end

local function getComponentsTexturePath(textureName)
    return libraryPath .. "textures\\" .. textureName;
end

-------------------------------------
-----    Local Event Handler    -----
-------------------------------------

local function handleComponentFadeOut(eventId, component, startAlpha, startTime, fadeDuration)

    local timeSinceStart = GetTime() - startTime;
    if timeSinceStart <= 0 then
        return;
    end

    local percentage = 1 - (timeSinceStart / fadeDuration);
    local alpha = startAlpha * percentage;

    if alpha <= 0 then
        component:hide();
        component:setAlpha(1);

        AceEvent:CancelScheduledEvent(component.currentEventFadeOut);
        component.currentEventFadeOut = nil;

        if AceEvent:IsEventRegistered(eventId) then
            AceEvent:UnregisterEvent(eventId);
        end
    else
        component:setAlpha(alpha);
    end
end

-------------------------------------
-----         Component         -----
-------------------------------------

function Component:__component__(id, wrappedComponent)

    self.id = id;
    self.wrappedComponent = wrappedComponent;
end

function Component:getId()

    return self.id;
end

function Component:getPosition()

    local parent = self.wrappedComponent:GetParent();
    if parent then
        return self.wrappedComponent:GetLeft() - parent:GetLeft(), self.wrappedComponent:GetBottom() - parent:GetBottom();
    else
        return self.wrappedComponent:GetLeft(), self.wrappedComponent:GetBottom();
    end
end

function Component:getSize()

    return self.wrappedComponent:GetWidth(), self.wrappedComponent:GetHeight();
end

function Component:getWidth()

    return self.wrappedComponent:GetWidth();
end

function Component:getHeight()

    return self.wrappedComponent:GetHeight();
end

function Component:getAlpha()

    return self.wrappedComponent:GetAlpha();
end

function Component:isVisible()

    return self.wrappedComponent:IsVisible();
end

function Component:setPosition(left, bottom)

    self:setPoint("BOTTOMLEFT", nil, "BOTTOMLEFT", left, bottom);
end

function Component:setRelativePosition(point, relativeTo, offsetX, offsetY)

    self:setPoint(point, relativeTo, point, offsetX, offsetY);
end

function Component:setPoint(point, relativeTo, relativePoint, offsetX, offsetY)

    local relativeFrame;
    if relativeTo then
        relativeFrame = safeWrappedComponent(relativeTo);
    else 
        relativeFrame = self.wrappedComponent:GetParent() or UIParent;
    end

    self.wrappedComponent:ClearAllPoints();
    self.wrappedComponent:SetPoint(point, relativeFrame, relativePoint, offsetX, offsetY);
end

function Component:setSize(width, height)

    self:setWidth(width);
    self:setHeight(height);
end

function Component:setWidth(width)

    self.wrappedComponent:SetWidth(width);
end

function Component:setHeight(height)

    self.wrappedComponent:SetHeight(height);
end

function Component:setAlpha(alpha)

    self.wrappedComponent:SetAlpha(alpha);
end

function Component:show()

    self.wrappedComponent:Show();
end

function Component:hide()

    self.wrappedComponent:Hide();
end

function Component:fadeOut(fadeDuration, delay)

    fadeDuration = fadeDuration or 0;
    delay = delay or 0;
    if (fadeDuration + delay) <= 0 then
        self:hide();
        return;
    end

    local eventId = self.id .. "#FadeOut";
    if not AceEvent:IsEventRegistered(eventId) then
        AceEvent:RegisterEvent(eventId, handleComponentFadeOut);
    end

    if self.currentEventFadeOut then
        AceEvent:CancelScheduledEvent(self.currentEventFadeOut);
    end

    self.currentEventFadeOut = AceEvent:ScheduleRepeatingEvent(eventId, 0.1, eventId, self, self:getAlpha(), GetTime() + delay, fadeDuration);
end

-------------------------------------
-----         FrameBased        -----
-------------------------------------

function FrameBased:__framebased__(id, wrappedComponent)

    self:__component__(id, wrappedComponent);
end

function FrameBased:setBackground(background)

    self.wrappedComponent:SetBackdrop(background);
end

function FrameBased:setBackgroundColor(red, green, blue)

    self.wrappedComponent:SetBackdropColor(red, green, blue);
end

function FrameBased:setBorderColor(red, green, blue)

    self.wrappedComponent:SetBackdropBorderColor(red, green, blue);
end

function FrameBased:onClick(onClickFunction)

    setComponentEventHandler(self, "OnClick", onClickFunction, function ()
        return arg1;
    end);
end

function FrameBased:onEnter(onEnterFunction)

    setComponentEventHandler(self, "OnEnter", onEnterFunction);
end

function FrameBased:onLeave(onLeaveFunction)

    setComponentEventHandler(self, "OnLeave", onLeaveFunction);
end

function FrameBased:onMouseDown(onMouseDownFunction)

    setComponentEventHandler(self, "OnMouseDown", onMouseDownFunction, function ()
        return arg1;
    end);
end

function FrameBased:onMouseUp(onMouseUpFunction)

    setComponentEventHandler(self, "OnMouseUp", onMouseUpFunction, function ()
        return arg1;
    end);
end

function FrameBased:onShow(onShowFunction)
    
    setComponentEventHandler(self, "OnShow", onShowFunction);
end

function FrameBased:onHide(onHideFunction)

    setComponentEventHandler(self, "OnHide", onHideFunction);
end

-------------------------------------
-----       Label Factory       -----
-------------------------------------

function LabelFactory:new(parent, layer, template)
    
    local id = "Label" .. LabelFactory.currentIndex;
    LabelFactory.currentIndex = LabelFactory.currentIndex + 1;

    local wrappedComponent = safeWrappedComponent(parent);
    if not wrappedComponent.CreateFontString then
        error("Label cannot be created because the parent component does not support font strings: " .. (parent.id or parent:GetName() or "unnamed component"));
    end

    return constructInstance(Label, id, wrappedComponent:CreateFontString(id, layer or "OVERLAY", template or "GameFontNormal"));
end

-------------------------------------
-----           Label           -----
-------------------------------------

function Label:__init__(id, wrappedComponent)

    self:__component__(id, wrappedComponent);
end

function Label:setText(text)

    self.wrappedComponent:SetText(text);
end

function Label:setFont(font, size, flags)

    self.wrappedComponent:SetFont(font, size, flags);
end

function Label:setFontObject(fontObject)

    self.wrappedComponent:SetFontObject(fontObject);
end

-------------------------------------
-----       Frame Factory       -----
-------------------------------------

function FrameFactory:new(parent)
    
    local id = "Frame" .. FrameFactory.currentIndex;
    FrameFactory.currentIndex = FrameFactory.currentIndex + 1;
    return constructInstance(Frame, id, CreateFrame("Frame", id, safeWrappedComponent(parent)));
end

function FrameFactory:newDialogBox(parent)

    local frame = self:new(parent);
    frame:setBackground({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        tile = true,
        tileSize = 16,
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    });
    frame:setBackgroundColor(0, 0, 0);
    frame:setBorderColor(.5, .5, .5);
    return frame;
end

function FrameFactory:newToolTip(parent)

    local frame = self:new(parent);
    frame:setBackground({
        bgFile = "Interface\\Tooltips\\CHATBUBBLE-BACKGROUND",
        tile = true,
        tileSize = 16,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    });
    frame:setBackgroundColor(0, 0, 0);
    frame:setBorderColor(.5, .5, .5);
    return frame;
end

-------------------------------------
-----           Frame           -----
-------------------------------------

function Frame:__init__(id, wrappedComponent)
   
    self:__framebased__(id, wrappedComponent);
    
    self.wrappedComponent:Hide();
    self.wrappedComponent:RegisterForDrag("LeftButton");
    self.wrappedComponent:SetScript("OnDragStart", function() this:StartMoving(); end);
    self.wrappedComponent:SetScript("OnDragStop", function() this:StopMovingOrSizing(); end);
end

function Frame:setText(text, position)

    local label = LabelFactory:new(self.wrappedComponent);
    label:setText(text);
    label:setRelativePosition(position or "CENTER");
end

function Frame:setMinSize(width, height)

    self.wrappedComponent:SetMinResize(width, height);
end

function Frame:setMovable(movable)

    if movable then
        self.wrappedComponent:EnableMouse(true);
        self.wrappedComponent:SetMovable(true);
    else
        self.wrappedComponent:SetMovable(false);
        self.wrappedComponent:EnableMouse(self.wrappedComponent:isMoveable() or self.wrappedComponent:IsResizable());
    end
end

function Frame:setResizable(resizable)

    if resizable then
        if not self.resizeButton then
            self.resizeButton = ButtonFactory:new(self);
            self.resizeButton:setRelativePosition("BOTTOMRIGHT", self, -3, 3);
            self.resizeButton:setSize(16, 16);
            self.resizeButton:setNormalTextureByPath(getComponentsTexturePath("cmpsChangeSize.tga"));
            self.resizeButton:setPushedTextureByPath(getComponentsTexturePath("cmpsChangeSizePushed.tga"));
            self.resizeButton:setHighlightTextureByPath(getComponentsTexturePath("cmpsChangeSizeHighlight.tga"));

            self.resizeButton:onEnter(function()
                SetCursor("Interface\\Cursor\\Cast");
            end);
            self.resizeButton:onLeave(function()
                SetCursor(nil);
            end);
            self.resizeButton:onMouseDown(function(_, button)
                if button == "LeftButton" then
                    self.wrappedComponent:StartSizing("BOTTOMRIGHT");
                    self.wrappedComponent:SetUserPlaced(true);
                end
            end);
            self.resizeButton:onMouseUp(function() self.wrappedComponent:StopMovingOrSizing(); end);
        end

        self.wrappedComponent:EnableMouse(true);
        self.wrappedComponent:SetResizable(true);
        self.resizeButton:show();
    else
        self.resizeButton:hide();
        self.wrappedComponent:SetResizable(false);
        self.wrappedComponent:EnableMouse(self.wrappedComponent:isMoveable() or self.wrappedComponent:IsResizable());
    end
end

-------------------------------------
-----       Button Factory      -----
-------------------------------------

function ButtonFactory:new(parent, template)
    
    local id = "Button" .. ButtonFactory.currentIndex;
    ButtonFactory.currentIndex = ButtonFactory.currentIndex + 1;
    local button = constructInstance(Button, id, CreateFrame("Button", id, safeWrappedComponent(parent), template));
    button:setRelativePosition("CENTER");
    button:setSize(100, 25);
    return button;
end

function ButtonFactory:newPanelButton(parent, text)

    local button = self:new(parent, "UIPanelButtonTemplate");
    		
    button:setText(text or "");
    button:setNormalTextureByPath("Interface\\Buttons\\UI-Panel-Button-Up", 0.625, 0.6875);
    button:setPushedTextureByPath("Interface\\Buttons\\UI-Panel-Button-Down", 0.625, 0.6875);
    button:setHighlightTextureByPath("Interface\\Buttons\\UI-Panel-Button-Highlight", 0.625, 0.6875);

    return button;
end

-------------------------------------
-----          Button           -----
-------------------------------------

function Button:__init__(id, wrappedComponent)

    self:__framebased__(id, wrappedComponent);
end

function Button:setText(text)

    self.wrappedComponent:SetText(text);
end

function Button:setFont(font, size, flags)

    self.wrappedComponent:SetFont(font, size, flags);
end

function Button:setFontObject(fontObject)

    self.wrappedComponent:SetFontObject(fontObject);
end

function Button:setNormalTextureByPath(texturePath, rightCut, bottomCut)

    local texture = loadTexture(self, texturePath, "OVERLAY", rightCut, bottomCut);
    self.wrappedComponent:SetNormalTexture(texture);
end

function Button:setPushedTextureByPath(texturePath, rightCut, bottomCut)

    local texture = loadTexture(self, texturePath, "BACKGROUND", rightCut, bottomCut);
    self.wrappedComponent:SetPushedTexture(texture);
end

function Button:setHighlightTextureByPath(texturePath, rightCut, bottomCut)

    local texture = loadTexture(self, texturePath, "OVERLAY", rightCut, bottomCut);
    texture:SetBlendMode("ADD");
    self.wrappedComponent:SetHighlightTexture(texture);
end

-------------------------------------
-----     ComboxBox Factory     -----
-------------------------------------

function ComboBoxFactory:new(parent, values)

    if not values or (type(values) ~= "table") then
        error("ComboBox cannot be created because no value table was passed to the method");
    end

    local id = "ComboBox" .. ComboBoxFactory.currentIndex;
    ComboBoxFactory.currentIndex = ComboBoxFactory.currentIndex + 1;
    local comboBox = constructInstance(ComboBox, id, CreateFrame("Frame", id, safeWrappedComponent(parent), "UIDropDownMenuTemplate"));
    comboBox:setRelativePosition("CENTER");
    comboBox:setSize(100, 25);

    UIDropDownMenu_Initialize(comboBox.wrappedComponent, function()

        local info = {};
        for k, v in pairs(values) do

            info.value = k;
            info.text = v;
            info.owner = comboBox.wrappedComponent;
            info.checked = nil;
            info.func = function()

                local id = this:GetID();
                comboBox.selectedValue = this.value;
                UIDropDownMenu_SetSelectedID(comboBox.wrappedComponent, id);
                if comboBox.onSelectFunction then
                    comboBox.onSelectFunction(comboBox, this.value, id);
                end
            end

            UIDropDownMenu_AddButton(info);
        end
    end);

    getglobal(id.."Button"):SetScript("OnClick", function()
        comboBox:toggle();
    end);

    return comboBox;
end

-------------------------------------
-----         ComboxBox         -----
-------------------------------------

function ComboBox:__init__(id, wrappedComponent)

    self:__framebased__(id, wrappedComponent);

    self.initialized = false;
    self.selectedValue = nil;
    self.onSelectFunction = nil;
end

function ComboBox:getSelectedValue()

    return self.selectedValue;
end

function ComboBox:setWidth(width)

    UIDropDownMenu_SetWidth(width, self.wrappedComponent);
end

function ComboBox:setSelectedValue(value)

    self.selectedValue = value;
    UIDropDownMenu_SetSelectedValue(self.wrappedComponent, value);
end

function ComboBox:toggle()

    if self.initialized then
        ToggleDropDownMenu(1, nil, self.wrappedComponent);
    else
        -- hack against the growing of the dropdown menu and the repositioning of the button
        local left, bottom = self:getPosition();
        local _, heightBefore = self:getSize();

        ToggleDropDownMenu(1, nil, self.wrappedComponent);

        local _, heightAfter = self:getSize();

        if heightAfter > heightBefore then
            self:setPosition(left, bottom - (heightAfter - heightBefore));
            self.initialized = true;
        end
    end
end;

function ComboBox:onSelect(onSelectFunction)

    self.onSelectFunction = onSelectFunction;
end

-------------------------------------
-----     SimpleHtml Factory    -----
-------------------------------------

function SimpleHtmlFactory:new(parent)
    
    local id = "SimpleHtml" .. SimpleHtmlFactory.currentIndex;
    SimpleHtmlFactory.currentIndex = SimpleHtmlFactory.currentIndex + 1;
    
    local wrappedComponent = safeWrappedComponent(parent);
    local simpleHtml = constructInstance(SimpleHtml, id, CreateFrame("SimpleHTML", id, wrappedComponent));
    simpleHtml:setRelativePosition("CENTER");
    simpleHtml:setSize(wrappedComponent:GetWidth() - 20, wrappedComponent:GetHeight() - 20);
    simpleHtml:setFontObject(GameFontNormal);
    simpleHtml:setFontObject(GameFontHighlightLarge, "H1");
    return simpleHtml;
end

-------------------------------------
-----         SimpleHtml        -----
-------------------------------------

function SimpleHtml:__init__(id, wrappedComponent)

    self:__framebased__(id, wrappedComponent);
end

function SimpleHtml:setContent(content)

    self.wrappedComponent:SetText(content);
end

function SimpleHtml:setFont(font, size, flags)

    self.wrappedComponent:SetFont(font, size, flags);
end

function SimpleHtml:setFontObject(fontObject, element)

    if element then
        self.wrappedComponent:SetFontObject(element, fontObject);
        return;
    else
        self.wrappedComponent:SetFontObject(fontObject);
    end
end

-------------------------------------
-----          Static           -----
-------------------------------------

AceLibrary:Register(Components, vmajor, vminor, nil, nil, nil);