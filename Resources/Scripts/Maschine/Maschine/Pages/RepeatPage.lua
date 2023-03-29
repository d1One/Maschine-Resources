------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Shared/Helpers/RepeatPageHelpers"

require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/PadModeHelper"
require "Scripts/Shared/Helpers/ScreenHelper"
require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/InfoBar"
require "Scripts/Shared/Components/ScreenMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
RepeatPage = class( 'RepeatPage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function RepeatPage:__init(Controller)

    PageMaschine.__init(self, "RepeatPage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_NOTE_REPEAT }

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function RepeatPage:setupScreen()

    -- create screen
    self.Screen = ScreenMaschine(self)

    self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"RPT/ARP", "LOCK", "HOLD", "GATE RST"}, "HeadButton", true)
    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {" ", " ", " ", " "}, "HeadButton")
    self.Screen.ScreenButton[1]:style("RPT/ARP", "HeadPin")

    self.Screen.InfoBar = InfoBar(self.Controller, self.Screen.ScreenLeft)
    self.Screen.InfoBarRight = InfoBar(self.Controller, self.Screen.ScreenRight, "RightScreenDefault")

    self.Screen:addParameterBar(self.Screen.ScreenLeft)
    self.Screen:addParameterBar(self.Screen.ScreenRight)

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function RepeatPage:updateScreens(ForceUpdate)

    -- update left and right transport bar
    self.Screen.InfoBar:update(ForceUpdate)
    self.Screen.InfoBarRight:update(ForceUpdate)

    local KeyboardOn = PadModeHelper.getKeyboardMode()
    local PageName = KeyboardOn and "ARP" or "NOTE RPT"

    local Arp = NI.DATA.getArpeggiator(App)
    local HoldOn = Arp and Arp:getHoldParameter():getValue()

    self.Screen.ScreenButton[1]:style(PageName, "HeadPin");
    self.Screen.ScreenButton[2]:setSelected(MaschineHelper.isArpRepeatLocked())
    self.Screen.ScreenButton[3]:setSelected(HoldOn)
    self:updateArpPresetButtons()

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPage:updateLeftRightLEDs()

    RepeatPageHelpers.updateLeftRightLEDs(self)

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPage:updateArpPresetButtons()

    local ArpPresetParameter = NI.DATA.getArpeggiatorPresetParameter(App)

    if ArpPresetParameter then

        for Idx = 1,4 do
            local ButtonIdx = Idx + 4
            self.Screen.ScreenButton[ButtonIdx]:setEnabled(true)
            self.Screen.ScreenButton[ButtonIdx]:setVisible(true)
            self.Screen.ScreenButton[ButtonIdx]:setSelected(Idx == ArpPresetParameter:getValue())
            self.Screen.ScreenButton[ButtonIdx]:setText(ArpPresetParameter:getAsString(Idx))
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPage:updateParameters(ForceUpdate)

    local Params = {}
    local Sections = {}
    local Arpeggiator = NI.DATA.getArpeggiator(App)

    if not Arpeggiator then
        return
    end

    if PadModeHelper.getKeyboardMode() then
        self.ParameterHandler.NumPages = 2

        if self.ParameterHandler.PageIndex == RepeatPageHelpers.PARAM_BANK_BASIC then

            -- Group names
            Sections[2] = "Main"
            Sections[3] = "Rhythm"
            Sections[6] = "Other"

            -- Parameters
            Params[2] = Arpeggiator:getTypeParameter()
            Params[3] = NI.DATA.getArpeggiatorRateParameter(App)
            Params[4] = NI.DATA.getArpeggiatorRateUnitParameter(App)
            Params[5] = Arpeggiator:getSequenceParameter()
            Params[6] = Arpeggiator:getOctavesParameter()
            Params[7] = Arpeggiator:getDynamicParameter()
            Params[8] = Arpeggiator:getGateParameter()
        else
            -- Group names
            Sections[1] = "Advanced"
            Sections[5] = "Range"

            -- Parameters
            Params[1] = Arpeggiator:getRetriggerParameter()
            Params[2] = Arpeggiator:getRepeatParameter()
            Params[3] = Arpeggiator:getOffsetParameter()
            Params[4] = Arpeggiator:getInversionParameter()
            Params[5] = Arpeggiator:getMinKeyParameter()
            Params[6] = Arpeggiator:getMaxKeyParameter()
        end

    else
        self.ParameterHandler.NumPages = 1

        -- Group names
        Sections[3] = "Rhythm"
        Sections[8] = "Other"

        -- Parameters
        Params[3] = NI.DATA.getArpeggiatorRateParameter(App)
        Params[4] = NI.DATA.getArpeggiatorRateUnitParameter(App)
        Params[8] = Arpeggiator:getGateParameter()

    end

    self.ParameterHandler:setParameters(Params, false)
    self.ParameterHandler:setCustomSections(Sections)

	-- call base
	PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function RepeatPage:onScreenButton(ButtonIdx, Pressed)

    local Arp = NI.DATA.getArpeggiator(App)
    local PresetParam = NI.DATA.getArpeggiatorPresetParameter(App)

    if Arp and PresetParam and Pressed then
        if ButtonIdx == 2 then
            MaschineHelper.toggleArpRepeatLockState()

        elseif ButtonIdx == 3 then

            local HoldParam = Arp:getHoldParameter()
            local NewValue = not HoldParam:getValue()
            NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, HoldParam, NewValue)

        elseif ButtonIdx == 4 then

            local NoteRepeatGateParam = Arp:getGateParameter()
            NI.DATA.ParameterAccess.setFloatParameterNoUndo(App, NoteRepeatGateParam, 1.0)

        elseif (5 <= ButtonIdx and ButtonIdx <= 8) then

            NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, PresetParam, ButtonIdx - 4)
        end
    end

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPage:onLeftRightButton(Right, Pressed)

    PageMaschine.onLeftRightButton(self, Right, Pressed)

end

