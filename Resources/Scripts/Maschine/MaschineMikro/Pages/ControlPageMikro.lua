------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/ControlHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Maschine/MaschineMikro/ControlScreenMikro"
require "Scripts/Maschine/MaschineMikro/ParameterHandlerMikro"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ControlPageMikro = class( 'ControlPageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- static defines
------------------------------------------------------------------------------------------------------------------------

ControlPageMikro.PAGE_GROUP     = 1
ControlPageMikro.PAGE           = 2
ControlPageMikro.PARAMETER      = 3
ControlPageMikro.PARAMETER_VALUE= 4

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ControlPageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "ControlPage", Controller)

    -- setup screen
    self:setupScreen()

    self.IsPinned = true

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function ControlPageMikro:setupScreen()

    -- setup screen
    self.Screen = ControlScreenMikro(self)

    -- setup parameter handler
    self.ParameterHandler:setLabels(self.Screen.ParameterLabel[2], self.Screen.ParameterLabel[4])

    -- define page leds
    -- MikroMK1 uses the ENTER button which is mapped to the Control Button (together with the LED)
    self.PageLEDs = { NI.HW.LED_CONTROL }

    self.Screen:setNavMode(false)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMikro:onShow(Show)

    -- set EncoderMode
    if Show == true then
        PageMikro:updateGroupPageButtonLED(LEDHelper.LS_OFF, true)  -- make sure the group button is off
        NHLController:setEncoderMode(NI.HW.ENC_MODE_CONTROL)
    else
        self.Screen:setNavMode(false)
        NHLController:setEncoderMode(NI.HW.ENC_MODE_NONE)
    end

    PageMikro.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMikro:updateScreens(ForceUpdate)

    -- call base
	PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMikro:updateParameters(ForceUpdate)

    local StateCache = App:getStateCache()

    -- PageName
    local ParameterCache = StateCache:getParameterCache()

    -- Parameter Stuff
    local Parameters = {}

    for Index = 0,7 do
        local Parameter = ParameterCache:getGenericParameter(Index, false)
        if Parameter then
            Parameters[#Parameters + 1] = Parameter
        end
    end

    -- update parameter in handler
    self.ParameterHandler:setParameters(Parameters, true)

    self.ParameterHandler:syncParameterIndex()

    -- call base
    PageMikro.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMikro:updatePadLEDs()

    local NavMode = self.Screen:getNavMode()

    if NavMode == 0 then

        -- call base class
        PageMikro.updatePadLEDs(self)

    else

        local StateCache     = App:getStateCache()
        local MixingLayer    = NI.DATA.StateHelper.getFocusMixingLayer(App)
        local ColorParameter = MixingLayer and MixingLayer:getColorParameter() or nil

        LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_LEDS, 0,
            function(Index) return ControlPageMikro.getPadLEDStatesNavMode(Index, self.Controller:getShiftPressed(), NavMode) end,
            function() return ColorParameter and ColorParameter:getValue() or 16 end)

    end

end

------------------------------------------------------------------------------------------------------------------------
-- Event Handling
------------------------------------------------------------------------------------------------------------------------

function ControlPageMikro:onPadEvent(PadIndex, Trigger, PadValue)

    if self.Screen:getNavMode() > 0 then
        self:onPadEventNav(PadIndex, Trigger)
    else
        -- call base
        PageMikro.onPadEvent(self, PadIndex, Trigger, PadValue)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMikro:onPadEventNav(PadIndex, Trigger, PadValue)

    if Trigger then

        local SlotIndex = -1

        -- Chnl. mode
        if self.Screen:getNavMode() == 1 then

            SlotIndex = PadIndex - 13
            if SlotIndex >= 0 and SlotIndex < 4 then
                local PageGroupParameter = App:getWorkspace():getPageGroupParameter()
                NI.DATA.ParameterAccess.setEnumParameter(App, PageGroupParameter, SlotIndex)
            end

        elseif self.Screen:getNavMode() == 2 then

            local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)

            if Slots then
                if self.Controller:getShiftPressed() then

                    local Slot = Slots:at(PadIndex - 1)
                    if Slot then
                        local ActiveParameter = Slot:getActiveParameter()
                        NI.DATA.ParameterAccess.setBoolParameter(App, ActiveParameter, not ActiveParameter:getValue())
                    end

                else

                    if PadIndex <= Slots:size() then
                        NI.DATA.ChainAccess.setFocusSlot(App, Slots, Slots:at(PadIndex - 1), false)

                        local FocusSlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)
                        if PadIndex - 1 == FocusSlotIndex then
                            ControlHelper.togglePluginWindow()
                        end
                    elseif PadIndex == Slots:size() + 1 then
                        NI.DATA.ChainAccess.setFocusSlot(App, Slots, nil, false)
                    end

                end
            end

         end

    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMikro:onNavButton(Pressed)

    if Pressed then
        NHLController:setEncoderMode(NI.HW.ENC_MODE_NONE)
    else
        NHLController:setEncoderMode(NI.HW.ENC_MODE_CONTROL)
    end

    PageMikro.onNavButton(self, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMikro:onScreenButton(Idx, Pressed)

    if Pressed then

		if self.Screen:getNavMode() == 0 then
			MaschineHelper.setFocusLevelTab(Idx - 1)

		elseif Idx == 2 or Idx == 3 then
			ControlHelper.setPluginMode(Idx == 3)
		end
	end

    -- call base class for update
    PageMikro.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMikro:onShiftButton(Pressed)

    -- toggle auto write
    PageMikro.onShiftButton(self, Pressed)

    -- adjust encoder mode
    NHLController:setEncoderMode(NI.HW.ENC_MODE_CONTROL)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMikro:onWheel(Inc)

    local NavMode = self.Screen:getNavMode()

    if NavMode == 1 then

        self.increasePageGroup(Inc)

    elseif NavMode == 2 then

        self.increaseSlotIndex(Inc)

	end

	return true

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMikro:onLeftRightButton(Right, Pressed)

    if not Pressed then
		return
	end

    local NavMode = self.Screen:getNavMode()

    if NavMode == 0 then
        self.ParameterHandler:increaseParameter(Right and 1 or -1)
        self.ParameterHandler:syncFocusParameter()
    else
        self:increasePage(Right and 1 or -1)
    end

    self:updateParameters()

end

------------------------------------------------------------------------------------------------------------------------
-- LED state functor for slot navigation
------------------------------------------------------------------------------------------------------------------------

function ControlPageMikro.getPadLEDStatesNavMode(PadIndex, ShiftPressed, NavMode)

    local StateCache = App:getStateCache()
    local Slots      = NI.DATA.StateHelper.getFocusChainSlots(App)

    local Selected, Enabled = false, false

    if Slots then
        if ShiftPressed then

            local Slot = Slots:at(PadIndex - 1)

            Enabled  = Slot ~= nil
            Selected = Slot and Slot:getActiveParameter():getValue() or false

        elseif NavMode == 1 then

            local PageIndex          = PageMikro.getGroupIndexFromPad(PadIndex) - 1
            local PageGroupParameter = App:getWorkspace():getPageGroupParameter()
            local PageGroupIndex     = PageGroupParameter:getValue()

            Enabled  = PageIndex >= 0 and PageIndex < 4
            Selected = PageIndex == PageGroupIndex

        else

            local FocusSlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)

            Enabled  = PadIndex <= Slots:size() + 1
            Selected = (PadIndex == Slots:size() + 1 and FocusSlotIndex == NPOS) or PadIndex - 1 == FocusSlotIndex

        end
    end

    return Selected, Enabled

end

------------------------------------------------------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------------------------------------------------------

function ControlPageMikro.increasePageGroup(Increment)

    local PageGroupParameter = App:getWorkspace():getPageGroupParameter()

    if PageGroupParameter then
        local OldValue = PageGroupParameter:getValue()
        local NewValue = math.bound(OldValue + Increment, PageGroupParameter:getMin(), PageGroupParameter:getMax())
        NI.DATA.ParameterAccess.setEnumParameter(App, PageGroupParameter, NewValue)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMikro:increasePage(Increment)

    local ParamCache = App:getStateCache():getParameterCache()
    local NumPages   = ParamCache:getNumPagesOfFocusParameterOwner()
    local NewValue   = math.bound(ParamCache:getValidPageParameterValue() + Increment, 0, NumPages - 1)

    NI.DATA.ParameterPageAccess.setPageAndFocusParameterIndex(App, NewValue, 0)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMikro.increaseSlotIndex(Increment)

    local FocusChain    = NI.DATA.StateHelper.getFocusChainSlots(App)
    NI.DATA.ChainAccess.shiftSlotFocus(App, FocusChain, Increment)

end

------------------------------------------------------------------------------------------------------------------------
