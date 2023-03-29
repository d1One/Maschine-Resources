require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/ScreenMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
AudioExportPageMK3 = class( 'AudioExportPageMK3', PageMaschine )

local TITLE_BUTTON = 1

------------------------------------------------------------------------------------------------------------------------

function AudioExportPageMK3:__init(Controller)

    PageMaschine.__init(self, "AudioExportPage", Controller)

    self.PageLEDs = { NI.HW.LED_FILE }

    self:setupScreen()
    self:setPinned()

end

------------------------------------------------------------------------------------------------------------------------

function AudioExportPageMK3:setupScreen()

    self.Screen = ScreenMaschine(self)

    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"EXPORT AUDIO", "", "", ""}, "HeadButton")
    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"", "", "CANCEL", "EXPORT"}, "HeadButton")

    self.LeftLabel = NI.GUI.insertLabel(self.Screen.ScreenLeft, "LabelLeft")
    self.LeftLabel:style("", "DialogTitle")
    self.Screen.ScreenLeft:setFlex(self.LeftLabel)

    self.RightLabel = NI.GUI.insertMultilineTextEdit(self.Screen.ScreenRight, "LabelRight")
    self.RightLabel:style("")
    self.Screen.ScreenRight:setFlex(self.RightLabel)

    self.Screen:addParameterBar(self.Screen.ScreenLeft)
    self.Screen:addParameterBar(self.Screen.ScreenRight)

end

------------------------------------------------------------------------------------------------------------------------

function AudioExportPageMK3:onShow(Show)

    PageMaschine.onShow(self, Show)

    if Show then

        self.Controller:turnOffAllPageLEDs()
        self:updateParameters(true)
        self:updateScreens(true)

    end

end

------------------------------------------------------------------------------------------------------------------------

function AudioExportPageMK3:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function AudioExportPageMK3:updateScreens(ForceUpdate)

    if ForceUpdate then

        local IdeaSpaceFocused = NI.DATA.StateHelper.isIdeaSpaceFocused(App)
        self.LeftLabel:setText(IdeaSpaceFocused and "Export Ideas as Audio" or "Export Song as Audio")

    end

    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function AudioExportPageMK3:updateScreenButtons(ForceUpdate)

    if self.Screen.ScreenButton == nil then
        return
    end

    self.Screen.ScreenButton[TITLE_BUTTON]:setSelected(true)
    self.Screen.ScreenButton[TITLE_BUTTON]:setEnabled(true)

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function AudioExportPageMK3:updateParameters(ForceUpdate)

    local IdeaSpaceFocused = NI.DATA.StateHelper.isIdeaSpaceFocused(App)
    local Options = App:getAudioExportOptions()

    local Parameters = {
        Options:getOutputSourceParameter(),
        IdeaSpaceFocused and Options:getSceneScopeParameter() or Options:getOutputRangeParameter(),
        Options:getSamplerateParameter(),
        Options:getFileTypeParameter(),
        Options:getBitDepthParameter(),
        Options:getLoopOptimizeParameter(),
        Options:getNormalizeParameter(),
        not IdeaSpaceFocused and Options:getSplitBySectionParameter() or nil,
    }

    self.ParameterHandler:setParameters(Parameters, false)
    self.Controller.CapacitiveList:assignParametersToCaps(Parameters)

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function AudioExportPageMK3:onScreenButton(Idx, Pressed)

    if Pressed and self.Screen.ScreenButton[Idx]:isEnabled() and Idx == 7 then

        App:getHardwareInputManager():onButton(NI.HW.HWDIALOG_RESULT_CANCEL)

    elseif Pressed and self.Screen.ScreenButton[Idx]:isEnabled() and Idx == 8 then

        App:getHardwareInputManager():onButton(NI.HW.HWDIALOG_RESULT_OK)

    end

    PageMaschine.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function AudioExportPageMK3:getAccessiblePageInfo()

    return "Audio Export"

end

------------------------------------------------------------------------------------------------------------------------
