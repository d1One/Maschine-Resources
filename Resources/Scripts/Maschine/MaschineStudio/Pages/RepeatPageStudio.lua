------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/EventsPageBase"
require "Scripts/Maschine/Shared/Helpers/RepeatPageHelpers"
require "Scripts/Shared/Components/ScreenMaschineStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
RepeatPageStudio = class( 'RepeatPageStudio', EventsPageBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function RepeatPageStudio:__init(Controller)

    EventsPageBase.__init(self, "RepeatPageStudio", Controller)

    self.PageLEDs = { NI.HW.LED_NOTE_REPEAT }

end

------------------------------------------------------------------------------------------------------------------------
-- setup
------------------------------------------------------------------------------------------------------------------------

function RepeatPageStudio:setupScreen()

    -- setup screen
    self.Screen = ScreenMaschineStudio(self)

    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"NOTE RPT", "LOCK", "HOLD", "GATE RESET"},
        {"HeadPin", "HeadButton", "HeadButton", "HeadButton"}, false)

    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton", false)

    EventsPageBase.setupScreen(self, true)

    self:setupSoundsVector()

    local RightParamBar = NI.GUI.insertBar(self.Screen.ScreenRight, "ParamBar")
    RightParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.Screen:addParameterBar(RightParamBar)

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPageStudio:setupSoundsVector()

    local Size  = function() return 16 end

    local Setup = function(Label) Label:style("", "SoundListItemSmall") end

    local Load  = function(Label, Index)
					Label:setText(tostring(Index+1))
                    ColorPaletteHelper.setSoundColor(Label, Index+1)
                    Label:setSelected(Index == NI.DATA.StateHelper.getFocusSoundIndex(App))
                 end

    NI.GUI.connectVector(self.SoundList, Size, Setup, Load)

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function RepeatPageStudio:onShow(Show)

    NHLController:setPadMode(Show and NI.HW.PAD_MODE_SOUND or NI.HW.PAD_MODE_PAGE_DEFAULT)

    EventsPageBase.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPageStudio:updateScreens(ForceUpdate)

    self.Controller.CapacitiveNavIcons:Enable(false)
    self.Arranger:setHWCompactVelocityLayout(false)

    local KeyboardOn = PadModeHelper.getKeyboardMode()
    local PageName = KeyboardOn and "ARP" or "NOTE RPT"

    local Arp = NI.DATA.getArpeggiator(App)
    local HoldOn = Arp and Arp:getHoldParameter():getValue()

    self.Screen.ScreenButton[1]:setText(PageName)
    self.Screen.ScreenButton[2]:setText("LOCK")
    self.Screen.ScreenButton[2]:setSelected(MaschineHelper.isArpRepeatLocked())
    self.Screen.ScreenButton[3]:setText("HOLD")
    self.Screen.ScreenButton[3]:setSelected(HoldOn)
    self.Screen.ScreenButton[4]:setText("GATE RESET")

    self:updateArpPresetButtons()

    -- call base class
    EventsPageBase.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPageStudio:updateLeftRightLEDs()

    RepeatPageHelpers.updateLeftRightLEDs(self)

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPageStudio:updateArpPresetButtons()

    local ArpPresetParameter = NI.DATA.getArpeggiatorPresetParameter(App)
    if not NI.DATA.getArpeggiator(App) then
        return
    end

    for Idx = 1,4 do
        local ButtonIdx = Idx + 4
        self.Screen.ScreenButton[ButtonIdx]:setEnabled(true)
        self.Screen.ScreenButton[ButtonIdx]:setVisible(true)
        self.Screen.ScreenButton[ButtonIdx]:setSelected(Idx == ArpPresetParameter:getValue())
        self.Screen.ScreenButton[ButtonIdx]:setText(ArpPresetParameter:getAsString(Idx))
    end

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPageStudio:updateParameters(ForceUpdate)

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

    self.Controller.CapacitiveList:assignParametersToCaps(Params)

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function RepeatPageStudio:onScreenButton(ButtonIdx, Pressed)

    if Pressed then

        local Arp = NI.DATA.getArpeggiator(App)
        local HoldParam = Arp:getHoldParameter()
        local GateParam = Arp:getGateParameter()
        local PresetParam = NI.DATA.getArpeggiatorPresetParameter(App)

        if Arp and HoldParam and GateParam and PresetParam then

            if ButtonIdx == 2 then

               MaschineHelper.toggleArpRepeatLockState()

            elseif ButtonIdx == 3 then

                local NewValue = not HoldParam:getValue()
                NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, HoldParam, NewValue)

            elseif ButtonIdx == 4 then

                NI.DATA.ParameterAccess.setFloatParameterNoUndo(App, GateParam, 1.0)

            elseif (5 <= ButtonIdx and ButtonIdx <= 8) then

                NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, PresetParam, ButtonIdx - 4)

            end
        end
    end

    -- call base class for update
    EventsPageBase.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPageStudio:onLeftRightButton(Right, Pressed)

    PageMaschine.onLeftRightButton(self, Right, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
