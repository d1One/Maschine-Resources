------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Shared/Helpers/PadModeHelper"
require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
RepeatPageMikro = class( 'RepeatPageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function RepeatPageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "RepeatPage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_NOTE_REPEAT }

    self.CachedFocusParamIndex = {}

    self.PresetOffset = false

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function RepeatPageMikro:setupScreen()

    -- setup screen
    self.Screen = ScreenMikro(self)

    -- Info Display
    ScreenHelper.setWidgetText(self.Screen.Title, {"RPT/ARP"})

    -- Screen Buttons
    self.Screen:styleScreenButtons({"1/8", "1/16", "LOCK"}, "HeadTabRow", "HeadTab")
    -- setup parameter handler
    self.ParameterHandler:setLabels(self.Screen.ParameterLabel[2], self.Screen.ParameterLabel[4])

    self.ParameterHandler:setParameterIndexChangedFunc(function (Index) RepeatPageMikro.onParameterIndexChanged(self, Index) end)
end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function RepeatPageMikro:updateScreens(ForceUpdate)

    -- update transport bar
    self.Screen.InfoBar:update(ForceUpdate)

    -- Info Display
    local KeyboardOn = PadModeHelper.getKeyboardMode()
    local PageName = KeyboardOn and "ARP" or "NOTE REPEAT"
    ScreenHelper.setWidgetText(self.Screen.Title, {PageName})

    local ShiftPressed = self.Controller:getShiftPressed()
    if ShiftPressed then
        self.Screen.ScreenButton[3]:setText(self.PresetOffset and "<<" or ">>")
        self.Screen.ScreenButton[3]:setSelected(false)
    else
        self.Screen.ScreenButton[3]:setText("LOCK")
        self.Screen.ScreenButton[3]:setSelected(MaschineHelper.isArpRepeatLocked())
    end

    local ArpPresetParameter = NI.DATA.getArpeggiatorPresetParameter(App)
    if ArpPresetParameter then
        local Offset = self.PresetOffset and 2 or 0
        for Idx = 1,2 do
            self.Screen.ScreenButton[Idx]:setText(ArpPresetParameter:getAsString(Idx + Offset))
            self.Screen.ScreenButton[Idx]:setSelected((Idx + Offset) == ArpPresetParameter:getValue())
        end
    end

    local KeyboardOn = PadModeHelper.getKeyboardMode()
    if KeyboardOn then
        ScreenHelper.setWidgetText(self.Screen.Title, {"ARP"})
    else
        ScreenHelper.setWidgetText(self.Screen.Title, {"NOTE REPEAT"})
    end

    -- call base class
    PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPageMikro:updateParameters(ForceUpdate)

    local Params = {}
    local CustomNames = {}
    local CustomValues = {}

    local KeyboardOn = PadModeHelper.getKeyboardMode()
    local Arpeggiator = NI.DATA.getArpeggiator(App)

    if PadModeHelper.getKeyboardMode() then
        Params[1] = Arpeggiator:getTypeParameter()
        Params[2] = NI.DATA.getArpeggiatorRateParameter(App)
        Params[3] = NI.DATA.getArpeggiatorRateUnitParameter(App)
        Params[4] = Arpeggiator:getSequenceParameter()
        Params[5] = Arpeggiator:getOctavesParameter()
        Params[6] = Arpeggiator:getDynamicParameter()
        Params[7] = Arpeggiator:getGateParameter()
        Params[8] = Arpeggiator:getHoldParameter()
        CustomNames[8] = "Hold"
    else
        Params[1] = NI.DATA.getArpeggiatorRateParameter(App)
        Params[2] = NI.DATA.getArpeggiatorRateUnitParameter(App)
        Params[3] = Arpeggiator:getGateParameter()
        Params[4] = Arpeggiator:getHoldParameter()
        CustomNames[4] = "Hold"
    end

    self.ParameterHandler:setParameters(Params, false, CustomValues, CustomNames)
    -- set cached Parameter index
    local SavedIndex = self.CachedFocusParamIndex[PadModeHelper.getKeyboardMode()]
    if SavedIndex then
        self.ParameterHandler:setParameterIndex(SavedIndex)
    end

    -- call base
    PageMikro.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function RepeatPageMikro:onScreenButton(ButtonIdx, Pressed)

    if Pressed then
        local ShiftPressed = self.Controller:getShiftPressed()
        if (1 <= ButtonIdx and ButtonIdx <= 2) then

            local PresetParam = NI.DATA.getArpeggiatorPresetParameter(App)
            local Offset = self.PresetOffset and 2 or 0
            NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, PresetParam, ButtonIdx + Offset)

        elseif ButtonIdx == 3 then

            if ShiftPressed then
                self.PresetOffset = not self.PresetOffset
            else
                MaschineHelper.toggleArpRepeatLockState()
            end

        end
    end

    -- call base class for update
    PageMikro.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPageMikro:onNoteRepeatButton(Pressed)

    if Pressed then
        NHLController:getPageStack():popPage()

        if NHLController:getPageStack():getTopPage() == NI.HW.PAGE_STEP then
            NHLController:getPageStack():popPage()
        end
    else
        PageMikro.onNoteRepeatButton(self, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function RepeatPageMikro:onParameterIndexChanged(Index)

    self.CachedFocusParamIndex[PadModeHelper.getKeyboardMode()] = Index

end

------------------------------------------------------------------------------------------------------------------------
