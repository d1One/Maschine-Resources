------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/ScreenMaschine"
require "Scripts/Shared/Helpers/ControlHelper"
require "Scripts/Shared/Helpers/LedHelper"

------------------------------------------------------------------------------------------------------------------------
-- ScreenButton 1&2 steps through the Plug-in list, 3-8 are quickjumps to the PlugInPages in blocks of 6
-- Left/Right stepsthrough these blocks
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ControlPageEdit = class( 'ControlPageEdit', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ControlPageEdit:__init(ParentPage, Controller)

    -- create page
    PageMaschine.__init(self, "ControlPageEdit", Controller)

    self.ParentPage = ParentPage

    -- Since all pages are organized in Blocks of 6 we need to know at which Block we are.
    -- Every time the PlugIn changes, the Workspace Level Tab or the Site gets shown it has to be calculated again.
    self.BlockBeginning = 0
    self.NotResetBlockBeg = false

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_SAMPLE, NI.HW.LED_CONTROL }

end


------------------------------------------------------------------------------------------------------------------------

function ControlPageEdit:setupScreen()

    self.Screen = ScreenMaschine(self)
    self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"PREV", "NEXT", "", ""}, "HeadButton")
    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton")

    -- insert infobars bar (bpm .. position)
    self.Screen.InfoBar = InfoBar(self.Controller, self.Screen.ScreenLeft)
    self.Screen.InfoBarRight = InfoBar(self.Controller, self.Screen.ScreenRight, "RightScreenDefault")

    -- Parameter page names
    self.Screen:addParameterBar(self.Screen.ScreenLeft)
    self.Screen:addParameterBar(self.Screen.ScreenRight)

end


------------------------------------------------------------------------------------------------------------------------

function ControlPageEdit:onShow(Show)

    if Show == true then
        NHLController:setEncoderMode(NI.HW.ENC_MODE_CONTROL)
        self:resetBlockBeginning()
    else
        NHLController:setEncoderMode(NI.HW.ENC_MODE_NONE)
    end

    -- Call Base Class
    PageMaschine.onShow(self, Show)

end


------------------------------------------------------------------------------------------------------------------------

function ControlPageEdit:updateScreens(ForceUpdate)

    local ChannelMode = not App:getWorkspace():getModulesVisibleParameter():getValue()
    if ChannelMode then
        self.ParentPage:switchToDefaultSubPage()
        return
    end

    if self.NotResetBlockBeg == false then
        self:resetBlockBeginning()
    end

    self.NotResetBlockBeg = false

    -- update left and right transport bar
    self.Screen.InfoBar:update(ForceUpdate)
    self.Screen.InfoBarRight:update(ForceUpdate)

    -- call base class updateScreens
    PageMaschine.updateScreens(self, ForceUpdate)

end


------------------------------------------------------------------------------------------------------------------------

function ControlPageEdit:updateScreenButtons(ForceUpdate)

    ScreenHelper.updateButtonsWithFunctor(self.Screen.ScreenButton,
                             function(ButtonIdx)
                                return self:getPageNameAndStates(ButtonIdx)
                             end)

    local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
    local NewIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)

    local Button1Enabled = NewIndex > 0 and Slots:size() > 0
    self.Screen:updateScreenButton(1, NI.HW.BUTTON_SCREEN_1, Button1Enabled)

    local Button2Enabled = NewIndex < Slots:size() -1 and Slots:size() > 0
    self.Screen:updateScreenButton(2, NI.HW.BUTTON_SCREEN_2, Button2Enabled)


    -- call base class
    PageMaschine.updateScreenButtons(self, ForceUpdate)

end


------------------------------------------------------------------------------------------------------------------------

function ControlPageEdit:updateParameters(ForceUpdate)

    local ParamCache = App:getStateCache():getParameterCache()

    for Index = 1, 8 do
        local Parameter = ParamCache:getGenericParameter(Index - 1, false)
        self.ParameterHandler.Parameters[Index] = Parameter
    end

    -- call base class
    self.ParameterHandler:update(ForceUpdate)

end


------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function ControlPageEdit:onScreenButton(ButtonIdx, Pressed)

    if Pressed then

        if ButtonIdx == 1 or ButtonIdx == 2 then

            self:onNextPrev(ButtonIdx == 2)

        elseif ButtonIdx >= 3 and ButtonIdx <= 8 then

            -- activate corresponding page
            self:jumpToParameterPage(ButtonIdx - 2)

        end

    end

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end


------------------------------------------------------------------------------------------------------------------------

function ControlPageEdit:onScreenEncoder(KnobIdx, EncoderInc)

	-- NOTE: Before Lua scripts receive events, encoder & wheel events are pushed to realtime thread on c++ side,
    -- so no need to call base class to handle these events.
    -- PageMaschine.onScreenEncoder(self, KnobIdx, EncoderInc)

end


------------------------------------------------------------------------------------------------------------------------

function ControlPageEdit:onNextPrev(DoNext)

    local Slots    = NI.DATA.StateHelper.getFocusChainSlots(App)
    local NewIndex = NI.DATA.StateHelper.getFocusSlotIndex(App) + (DoNext and 1 or -1)
    local Slot     = Slots:at(NewIndex)

    if Slot then
        NI.DATA.ChainAccess.setFocusSlot(App, Slots, Slot, false)
    end

end


------------------------------------------------------------------------------------------------------------------------
--Functor: Visible, Enabled, Selected, Focused, Text
function ControlPageEdit:getPageNameAndStates(ButtonIdx)

    if ButtonIdx == 1 then
        return true, self.Controller.SwitchPressed[NI.HW.BUTTON_SCREEN_1] == true, true, false, "PREV"
    elseif ButtonIdx == 2 then
        return true, self.Controller.SwitchPressed[NI.HW.BUTTON_SCREEN_2] == true, true, false, "NEXT"

    else
        ButtonIdx = ButtonIdx - 2

        local ParamCache = App:getStateCache():getParameterCache()
        local CurrentPage = ParamCache:getValidPageParameterValue()
        local NumPages = ParamCache:getNumPagesOfFocusParameterOwner()

        local Slot = NI.DATA.StateHelper.getFocusSlot(App)
        if Slot then

            local Module = Slot:getModule()
            if Module then

                if ButtonIdx + self.BlockBeginning <= NumPages  then

                    local PageName = Module:getPageDisplayName(0, self.BlockBeginning + ButtonIdx-1)
                    return true, (ButtonIdx + self.BlockBeginning == 1 + CurrentPage), true, true, PageName

                end

            end

        end

    end

    -- Selected, Enabled, Text
    return false, false, false, false, ""

end


------------------------------------------------------------------------------------------------------------------------

function ControlPageEdit:jumpToParameterPage(Index)

    local ParamCache = App:getStateCache():getParameterCache()
    local NumPages = ParamCache:getNumPagesOfFocusParameterOwner()

    if Index + self.BlockBeginning <= NumPages then

        ControlHelper.setPageParameter(Index + self.BlockBeginning)

    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageEdit:resetBlockBeginning()

    local ParamCache = App:getStateCache():getParameterCache()
    local CurrentPage = ParamCache:getValidPageParameterValue()

    self.BlockBeginning = CurrentPage - (CurrentPage % 6)

end


------------------------------------------------------------------------------------------------------------------------

function ControlPageEdit:onPageButton(Button, Page, Pressed)

    if Pressed then

        if Page == NI.HW.PAGE_SAMPLING and self.Controller:getShiftPressed() then

            self.ParentPage:switchToDefaultSubPage()
            return true
        end
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------


function ControlPageEdit:onLeftRightButton(Right, Pressed)

	if Pressed then

        local ParamCache = App:getStateCache():getParameterCache()
        local NumPages = ParamCache:getNumPagesOfFocusParameterOwner()

		self.BlockBeginning = self.BlockBeginning + (Right and 1 or -1) * 6

		if self.BlockBeginning < 0 then
			self.BlockBeginning = 0
		elseif self.BlockBeginning == NumPages then
			self.BlockBeginning = self.BlockBeginning - 6
		elseif self.BlockBeginning > (NumPages - NumPages % 6) then
			self.BlockBeginning = (NumPages - NumPages % 6)
		end

		self.NotResetBlockBeg = true
		self:updateScreens()

	end

end

------------------------------------------------------------------------------------------------------------------------
