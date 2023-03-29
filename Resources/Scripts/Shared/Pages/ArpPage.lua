------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/ScreenMaschineStudio"
require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ArpPage = class( 'ArpPage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ArpPage:__init(Controller)

    PageMaschine.__init(self, "ArpPage", Controller)
    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function ArpPage:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft,
        {"ARP", "", "HOLD", "GATE RESET"}, "HeadButton", true)

    self.Screen.ScreenButton[1]:setStyle("PerformToggle")
    self.Screen.ScreenButton[1].Color = LEDColors.PERFORM_BLUE

    self.Screen:styleScreenWithParameters(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton", false, false)

end

------------------------------------------------------------------------------------------------------------------------

function ArpPage:onShow(Show)

    PageMaschine.onShow(self, Show)

    NHLController:setEncoderMode(Show and NI.HW.ENC_MODE_CONTROL or NI.HW.ENC_MODE_NONE)
    NHLController:setScreenButtonMode(Show and NI.HW.SCREENBUTTON_MODE_ARP_PRESETS or NI.HW.SCREENBUTTON_MODE_NONE)

end

------------------------------------------------------------------------------------------------------------------------

function ArpPage:updateScreens(ForceUpdate)

    local Arp = NI.DATA.getArpeggiator(App)
    local HoldOn = Arp and Arp:getHoldParameter():getValue() or false

    local ArpActive = NI.HW.getArpeggiatorActiveParameter(App)
    local ArpOn = ArpActive and ArpActive:getValue() or false

    self.Screen.ScreenButton[1]:setSelected(ArpOn)
    self.Screen.ScreenButton[3]:setSelected(HoldOn)

    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)
    self:updateArpPresetButtons()

    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ArpPage:updateArpPresetButtons()

    local ArpPresetParameter = NI.DATA.getArpeggiatorPresetParameter(App)

    if ArpPresetParameter then

        local TabStyles = {"HeadTabLeft", "HeadTabCenter", "HeadTabCenter", "HeadTabRight"}

        for Idx = 1,4 do

            local ButtonIdx = Idx + 4
            self.Screen.ScreenButton[ButtonIdx]:setEnabled(true)
            self.Screen.ScreenButton[ButtonIdx]:setVisible(true)
            self.Screen.ScreenButton[ButtonIdx]:setSelected(Idx == ArpPresetParameter:getValue())
            self.Screen.ScreenButton[ButtonIdx]:style(ArpPresetParameter:getAsString(Idx), TabStyles[Idx])
        end
    end
end

------------------------------------------------------------------------------------------------------------------------

function ArpPage:updateParameters(ForceUpdate)

    local Params = {}

    if self.SetupParametersFunc then
        Params = self.SetupParametersFunc(self.ParameterHandler)
    else
        for Index = 1, 8 do
            Params[Index] = NI.DATA.ParameterCache.getParameterByPosition(App, Index - 1)
        end

        self.ParameterHandler.NumPages = NI.DATA.ParameterCache.getNumPages(App)
        self.ParameterHandler.PageIndex = NI.DATA.ParameterCache.getFocusPage(App) + 1
        self.ParameterHandler.PrevNextPageFunc =
            function (Inc)
                NI.DATA.ParameterCache.advanceFocusPage(App, Inc > 0)
            end
    end

    self.ParameterHandler:setParameters(Params, false)
    self.Controller.CapacitiveList:assignParametersToCaps(self.ParameterHandler.Parameters)

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ArpPage:onScreenButton(ButtonIdx, Pressed)

    local Arp = NI.DATA.getArpeggiator(App)

    if Arp and Pressed then

        if ButtonIdx == 1 then
            local ArpParam = NI.HW.getArpeggiatorActiveParameter(App)
            NI.DATA.ParameterAccess.toggleBoolParameter(App, ArpParam)

        elseif ButtonIdx == 3 then
            local HoldParam = Arp:getHoldParameter()
            if NI.APP.FEATURE.UNDO_REDO then
                local NewValue = not HoldParam:getValue()
                NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, HoldParam, NewValue)
            else
                NI.DATA.ParameterAccess.toggleBoolParameter(App, HoldParam)
            end

        elseif ButtonIdx == 4 then

            local GateParam = Arp:getGateParameter()
            if NI.APP.FEATURE.UNDO_REDO then
                NI.DATA.ParameterAccess.setFloatParameterNoUndo(App, GateParam, 1.0)
            else
                NI.DATA.ParameterAccess.setFloatParameter(App, GateParam, 1.0)
            end

        elseif (5 <= ButtonIdx and ButtonIdx <= 8) then
            local PresetParam = NI.DATA.getArpeggiatorPresetParameter(App)
            if PresetParam then
                NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, PresetParam, ButtonIdx - 4)
            end
        end
    end

    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ArpPage:getScreenButtonInfo(Index)

    local Info = PageMaschine.getScreenButtonInfo(self, Index)

    if Info then
        if Index == 4 then
            Info.SpeechValue = ""
        elseif Index >= 5 and Index <= 8 then
            Info.SpeechValue = Info.SpeechName
            Info.SpeechName = "Arp Preset,"
            Info.SpeakNameInTrainingModeOnly = true
            Info.SpeakValueInTrainingModeOnly = true
        end
    end

    return Info

end

------------------------------------------------------------------------------------------------------------------------
