------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/ScreenMaschine"
require "Scripts/Shared/Helpers/BrowseHelper"
require "Scripts/Shared/Helpers/ControlHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/LevelButtonsHelper"


require "Scripts/Shared/Helpers/SnapshotsHelper"

local ATTR_IS_SHIFT_PLUGIN_MODE = NI.UTILS.Symbol("isShiftPluginMode")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ControlPageControl = class( 'ControlPageControl', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ControlPageControl:__init(ParentPage, Controller)

    -- init base class
    PageMaschine.__init(self, "ControlPageControl", Controller)

    self.ParentPage = ParentPage

    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_CONTROL }

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageControl:setupScreen()

    -- setup screen
    self.Screen = ScreenMaschine(self)

    -- insert left control bar
    self.Screen:addScreenButtonBar(self.Screen.ScreenLeft,
        {"MASTER", "GROUP", "SOUND", "LOCK"},
        {"HeadTab", "HeadTab", "HeadTabRight", "HeadButton"})
    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"CHANNEL", "PLUG-IN", "<<", ">>"}, "HeadButton")
    self.Screen.ScreenButton[4]:setEnabled(false)

    self.LevelButtons = LevelButtonsHelper(self.Screen.ScreenButton)

    -- insert left transport bar (focused item #. name, bpm, song position)
    self.Screen.InfoBar = InfoBar(self.Controller, self.Screen.ScreenLeft)

    -- insert focus object bar
    self.Screen.InfoBarRight = InfoBar(self.Controller, self.Screen.ScreenRight, "RightScreenPresets")

    -- Parameter page names
    self.Screen:addParameterBar(self.Screen.ScreenLeft)
    self.Screen:addParameterBar(self.Screen.ScreenRight)

    self.ParameterHandler.PrevNextPageFunc =
        function (Inc)
            NI.DATA.ParameterCache.advanceFocusPage(App, Inc > 0)
        end
end

------------------------------------------------------------------------------------------------------------------------

function ControlPageControl:onShow(Show)

    if Show == true then
        NHLController:setEncoderMode(NI.HW.ENC_MODE_CONTROL)
    else
        NHLController:setEncoderMode(NI.HW.ENC_MODE_NONE)
    end

    -- Call Base Class
    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageControl:updateScreens(ForceUpdate)

    ForceUpdate = ForceUpdate or App:getWorkspace():getModulesVisibleParameter():isChanged()

    -- update left and right InfoBar
    self.Screen.InfoBar:update(ForceUpdate)
    self.Screen.InfoBarRight:update(ForceUpdate)

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageControl:updateScreenButtons(ForceUpdate)

    self.LevelButtons:updateButtons()

    local ChannelMode = not App:getWorkspace():getModulesVisibleParameter():getValue()

    if ChannelMode or not self.Controller:getShiftPressed() then
        self:updateScreenButtonsDefault(ForceUpdate, ChannelMode)
    else
        self:updateScreenButtonsShiftPluginMode(ForceUpdate)
    end

    -- Call base
    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageControl:updateScreenButtonsDefault(ForceUpdate, ChannelMode)

    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)

    -- Buttons 1 to 3 -- Bring back after hiding in updateScreenButtonsShiftPluginMode
    self.Screen.ScreenButton[1]:setVisible(true)
    self.Screen.ScreenButton[1]:setEnabled(true)
    self.Screen.ScreenButton[2]:setVisible(FocusGroup ~= nil)
    self.Screen.ScreenButton[2]:setEnabled(FocusGroup ~= nil)
    self.Screen.ScreenButton[3]:setVisible(FocusGroup ~= nil)
    self.Screen.ScreenButton[3]:setEnabled(FocusGroup ~= nil)

    -- Buttons 2 and 3 -- Group and Sound
    self.Screen.ScreenButton[2]:setText("GROUP")
    self.Screen.ScreenButton[3]:style("SOUND", "HeadTabRight")
    self.Screen.ScreenButton[3]:setAttribute(ATTR_IS_SHIFT_PLUGIN_MODE, "false")

    -- Button 4 -- lock
    self.Screen.ScreenButton[4]:style(self.Controller:getShiftPressed() and "EXT LOCK" or "LOCK", "HeadButton")
    self.Screen.ScreenButton[4]:setVisible(true)
    self.Screen.ScreenButton[4]:setEnabled(true)
    self.Screen.ScreenButton[4]:setAttribute(ATTR_IS_SHIFT_PLUGIN_MODE, "false")
    self.Screen.ScreenButton[4]:setSelected(
            not self.Controller:getShiftPressed() and NI.DATA.ParameterSnapshotsAccess.isSnapshotActiveHW(App))

    -- Button 5 -- Channel
    self.Screen.ScreenButton[5]:setText("CHANNEL")
    self.Screen.ScreenButton[5]:setEnabled(true)
    self.Screen.ScreenButton[5]:setSelected(ChannelMode)

    -- Button 6 -- Plug-in
    self.Screen.ScreenButton[6]:setText("PLUG-IN")
    self.Screen.ScreenButton[6]:setEnabled(true)
    self.Screen.ScreenButton[6]:setSelected(not ChannelMode)

    if ChannelMode then

        local PageGroupParam = App:getWorkspace():getPageGroupParameter()
        self.Screen:setArrowText(1, PageGroupParam:getValueString())
        self.Screen.ScreenButton[7]:setEnabled(PageGroupParam:getValue() > 0)
        self.Screen.ScreenButton[8]:setEnabled(PageGroupParam:getValue() < 3)

    else

        local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
        local NumSlots = Slots and Slots:size() or 0
        local SlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App) or NumSlots

        self.Screen:setArrowText(1, MaschineHelper.getFocusSlotNameWithNumber())

        self.Screen.ScreenButton[7]:setEnabled(NumSlots > 0 and SlotIndex > 0)
        self.Screen.ScreenButton[8]:setEnabled(SlotIndex < NumSlots and SlotIndex >= 0)

    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageControl:updateScreenButtonsShiftPluginMode(ForceUpdate)

    local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
    local NumSlots = Slots and Slots:size() or 0
    local FocusSlot = NI.DATA.StateHelper.getFocusSlot(App)

    -- Buttons 1 to 2 -- hide
    for Index=1,2 do
        self.Screen.ScreenButton[Index]:setEnabled(false)
        self.Screen.ScreenButton[Index]:setVisible(false)
    end

    -- Button 3 -- INSERT
    self.Screen.ScreenButton[3]:setVisible(true)
    self.Screen.ScreenButton[3]:setEnabled(true)
    self.Screen.ScreenButton[3]:setSelected(false)
    self.Screen.ScreenButton[3]:style("INSERT", "HeadButton")
    self.Screen.ScreenButton[3]:setAttribute(ATTR_IS_SHIFT_PLUGIN_MODE, "true")

    -- Button 4 -- LOCK
    self.Screen.ScreenButton[4]:setVisible(true)
    self.Screen.ScreenButton[4]:setEnabled(true)
    self.Screen.ScreenButton[4]:setSelected(false)
    self.Screen.ScreenButton[4]:style("EXT LOCK", "HeadButton")
    self.Screen.ScreenButton[4]:setAttribute(ATTR_IS_SHIFT_PLUGIN_MODE, "true")

    -- Button 5 -- BYPASS
    self.Screen.ScreenButton[5]:setText("BYPASS")
    self.Screen.ScreenButton[5]:setEnabled(FocusSlot ~= nil)
    self.Screen.ScreenButton[5]:setSelected(FocusSlot ~= nil and not FocusSlot:getActiveParameter():getValue())

    -- Button 6 -- REMOVE
    self.Screen.ScreenButton[6]:setText("REMOVE")
    self.Screen.ScreenButton[6]:setEnabled(FocusSlot ~= nil)
    self.Screen.ScreenButton[6]:setSelected(false)

    -- Button 7 & 8 -- MOVE
    self.Screen:setArrowText(1, "MOVE")
    self.Screen.ScreenButton[7]:setEnabled(ControlHelper.canMoveFocusSlot(false))
    self.Screen.ScreenButton[8]:setEnabled(ControlHelper.canMoveFocusSlot(true))

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageControl:updateParameters(ForceUpdate)

    local ParamCache = App:getStateCache():getParameterCache()
    local Params = {}

    for Index = 1, 8 do
        Params[Index] = ParamCache:getGenericParameter(Index - 1, false)
    end

    self.ParameterHandler.NumPages = NI.DATA.ParameterCache.getNumPages(App)
    self.ParameterHandler.PageIndex = NI.DATA.ParameterCache.getFocusPage(App) + 1
    self.ParameterHandler:setParameters(Params, true)

    -- call base class
    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageControl:onLeftRightButton(Right, Pressed)

    PageMaschine.onLeftRightButton(self, Right, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageControl:onScreenEncoder(KnobIdx, EncoderInc)

    -- NOTE: Before Lua scripts receive events, encoder & wheel events are pushed to realtime thread on c++ side,
    -- so no need to call base class to handle these events.
    -- PageMaschine.onScreenEncoder(self, KnobIdx, EncoderInc)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageControl:onScreenButton(ButtonIdx, Pressed)

    if Pressed then

        local PluginMode = App:getWorkspace():getModulesVisibleParameter():getValue()

        if PluginMode and self.Controller:getShiftPressed() then
            self:onScreenButtonShiftPluginMode(ButtonIdx)
        else
            self:onScreenButtonDefault(ButtonIdx, PluginMode)
        end

    end

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageControl:onScreenButtonDefault(ButtonIdx, PluginMode)

    if ButtonIdx >= 1 and ButtonIdx <= 3 then -- MASTER, GROUP, SOUND

        MaschineHelper.setFocusLevelTab(ButtonIdx - 1)

    elseif ButtonIdx == 4 then -- LOCK

        if self.Controller:getShiftPressed() then
            NHLController:getPageStack():popToBottomPage()
            NHLController:getPageStack():pushPage(NI.HW.PAGE_SNAPSHOTS)
        else
            SnapshotsHelper.toggleLock()
        end

    elseif ButtonIdx == 5 then -- Toggle CHANNEL

        if PluginMode then
            ControlHelper.setPluginMode(false)
        end

    elseif ButtonIdx == 6 then -- Toggle PLUG-IN or EDIT

        if PluginMode then
            ControlHelper.togglePluginWindow()
        else
            ControlHelper.setPluginMode(true)
        end

    elseif ButtonIdx == 7 or ButtonIdx == 8 then -- Prev/Next Channel/Slot

       ControlHelper.onPrevNextSlot(ButtonIdx == 8, self.Controller:getShiftPressed())

    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageControl:onScreenButtonShiftPluginMode(ButtonIdx)

    if ButtonIdx == 3 then -- INSERT

        -- call base class to set LED states properly before page change
        PageMaschine.onScreenButton(self, ButtonIdx, true)

        BrowseHelper.setInsertMode(NI.DATA.INSERT_MODE_FRESH)
        BrowseHelper.setFileTypeToDefault()

        NHLController:getPageStack():popToBottomPage()
        NHLController:getPageStack():pushPage(NI.HW.PAGE_BROWSE)

    elseif ButtonIdx == 4 then

        NHLController:getPageStack():popToBottomPage()
        NHLController:getPageStack():pushPage(NI.HW.PAGE_SNAPSHOTS)

    end

    local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
    local FocusSlot = NI.DATA.StateHelper.getFocusSlot(App)

    if Slots == nil or FocusSlot == nil then
        return
    end

    if ButtonIdx == 5 then -- BYPASS

        NI.DATA.ParameterAccess.setBoolParameter(App,
            FocusSlot:getActiveParameter(), not FocusSlot:getActiveParameter():getValue())

    elseif ButtonIdx == 6 then -- REMOVE

        NI.DATA.ChainAccess.removeSlot(App, Slots, FocusSlot)

    elseif ButtonIdx == 7 or ButtonIdx == 8 then -- move plug-ins about

		if self.Screen.ScreenButton[ButtonIdx]:isEnabled() then
			ControlHelper.moveFocusSlot(ButtonIdx == 8)
		end

    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageControl:onShiftButton(Pressed)

    Page.onShiftButton(self, Pressed)
    self:updateScreens()

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageControl:onPageButton(Button, Page, Pressed)

    return false

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageControl:onPadEvent(PadIndex, Trigger, PadValue)

    PageMaschine.onPadEvent(self.ParentPage, PadIndex, Trigger, PadValue)

end

------------------------------------------------------------------------------------------------------------------------
