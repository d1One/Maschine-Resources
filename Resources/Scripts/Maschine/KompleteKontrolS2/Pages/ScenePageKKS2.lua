------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Maschine/Helper/PatternHelper"
require "Scripts/Maschine/KompleteKontrolS2/Helper/ScenePatternHelper"
require "Scripts/Maschine/Components/Pages/IdeaSpaceBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScenePageKKS2 = class( 'ScenePageKKS2', IdeaSpaceBase )

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:__init(Controller)

    IdeaSpaceBase.__init(self, "ScenePage", Controller)

    self.PageLEDs = {NI.HW.LED_SONG}

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:setup()

    self.Screen:addScreenButtonBar(self.ScreenButtonsBar, {"", "", "CLEAR", "DUPLICATE"}, {"HeadTabLeft", "HeadTabRight", "HeadButton", "HeadButton"}, false)
    self.Screen:addScreenButtonBar(self.ScreenButtonsBar, {"CREATE", "DELETE", "", "RETRIGGER"}, "HeadButton", false)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:updateWheelButtonLEDs()

    ScenePatternHelper.updateWheelButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:updateArrangerToggleButtons()

    self.Screen.ScreenButton[1]:setVisible(false)
    self.Screen.ScreenButton[2]:setVisible(false)

    self.Screen.ScreenButton[1]:setSelected(false)
    self.Screen.ScreenButton[2]:setSelected(false)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:updateScreens(ForceUpdate)

    IdeaSpaceBase.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:updateSceneBankButtons()
    -- no scene bank buttons
end

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:updateRetriggerButton()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    self.Screen.ScreenButton[7]:setVisible(false)
    self.Screen.ScreenButton[8]:setEnabled(true)
    self.Screen.ScreenButton[8]:setSelected(Song:getPerformRetrigParameter():getValue())

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:getSceneBank()

    return NHLController:getFocus8SceneBankIndex()

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:setSceneBank(Bank)

    NHLController:setFocus8SceneBankIndex(Bank)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:updateLEDs()

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_CLEAR, NI.HW.BUTTON_CLEAR,
        ScenePatternHelper.isIdeaSpace() and not PatternHelper.isFocusSceneEmpty())

    IdeaSpaceBase.updateLEDs(self)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:onWheel(Value)

    ScenePatternHelper.onWheel(Value)

    local Index = NI.DATA.StateHelper.getFocusGroupIndex(App) + 1
    self.Controller.SpeechAssist:onEncoderEvent(Index, true)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:onClear(Pressed)

    if Pressed and ScenePatternHelper.isIdeaSpace() then
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Scene = NI.DATA.StateHelper.getFocusScene(App)
        NI.DATA.SceneAccess.clearScene(App, Song, Scene)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:onScreenButton(ButtonIdx, Pressed)

    local isButtonDisabled = not self.Screen.ScreenButton[ButtonIdx]:isEnabled()
    -- The SpeechAssist call has to be done before the shift state is closed by the action
    self.Controller.SpeechAssist:onScreenButton(ButtonIdx, self, isButtonDisabled)

    if not self.Controller.SpeechAssist:isTrainingMode() then
        -- retrigger toggle
        if Pressed and ButtonIdx == 8 and self.Controller:getShiftPressed() and not self.ShiftFunctionsDiscard then
            local Song = NI.DATA.StateHelper.getFocusSong(App)
            if Song then
                local Param = Song:getPerformRetrigParameter()
                NI.DATA.ParameterAccess.setBoolParameter(App, Param, not Param:getValue())
            end

            PageMaschine.onScreenButton(self, ButtonIdx, Pressed)
        end

        IdeaSpaceBase.onScreenButton(self, ButtonIdx, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:onScreenEncoder(Idx, Inc)

    if not self.Controller.SpeechAssist:isTrainingMode() then
        IdeaSpaceBase.onScreenEncoder(self, Idx, Inc)
    end

    self.Controller.SpeechAssist:onEncoderEvent(Idx, true)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:getScreenEncoderInfo(Index)
    local Info = {
        SpeechSectionName = "",
        SpeechName = "",
        SpeechValue = ""
    }

    local GroupIndex = (self.GroupBank) * 8 + Index
    local Group = MaschineHelper.getGroupAtIndex(GroupIndex - 1) or nil

    if Group then
        Info.SpeechName = AccessibilityTextHelper.getGroupName(Group:getDisplayName())

        local Pattern = Group:getPatterns():getFocusObject()
        if Pattern then
            Info.SpeechValue = AccessibilityTextHelper.getPatternName(Pattern:getNameParameter():getValue())
        else
            Info.SpeechValue = "No Pattern"
        end
    end

    return Info
end

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:getScreenButtonInfo(Index)

    local Info = IdeaSpaceBase.getScreenButtonInfo(self, Index)
    if Info == nil then return end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if self.Controller:getShiftPressed() then
        -- Action buttons should have an object, e.g. "Insert Scene"
        Info.SpeechName = Info.SpeechName .. " Scene"
        Info.SpeakValueInNormalMode = (Index == 8)
        Info.SpeakValueInTrainingMode = false
        if Index == 8 then
            local Retrigger = Song:getPerformRetrigParameter():getValue()
            Info.SpeechValue = Retrigger and "On" or "Off"
        end
    else
        local SceneIndex = Index + self:getSceneBank() * 8 - 1
        local Scene = ScenePatternHelper.isIdeaSpace() and Song:getScenes():at(SceneIndex) or nil

        if Scene then
            Info.SpeechName = AccessibilityTextHelper.getSceneName(Scene:getNameParameter():getValueString())
        else
            -- @HACK: We can't get the text for the "+" soft button in this case - however it's the only button
            -- that is active and has info but isn't associated with a scene, so by deduction...
            Info.SpeechName = "Create Scene"
            Info.SpeechValue = nil
        end
    end

    return Info

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:getCurrentPageSpeechAssistanceMessage(Right)
    local DirectionString = Right and "Right" or "Left"
    local Msg = DirectionString

    local ItemIndex = 0
    local Info = self:getScreenButtonInfo(1)
    local FirstItem = Info.SpeechName

    if FirstItem and FirstItem ~= "" then
        Msg = Msg .. " to " .. FirstItem
    end

    return Msg
end

------------------------------------------------------------------------------------------------------------------------

function ScenePageKKS2:getWheelDirectionInfo(Direction)

    local DirectionNames = {
        [NI.HW.BUTTON_WHEEL_UP] = "Previous Pattern",
        [NI.HW.BUTTON_WHEEL_DOWN] = "Next Pattern",
        [NI.HW.BUTTON_WHEEL_LEFT] = "Previus Scene",
        [NI.HW.BUTTON_WHEEL_RIGHT] = "Next Scene"
    }
    local Msg = DirectionNames[Direction]

    local Info = {}
    Info.TrainingMode = Msg
    local GroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)
    local Group = MaschineHelper.getGroupAtIndex(GroupIndex) or nil

    if Group then
        Info.NormalMode = AccessibilityTextHelper.getGroupName(Group:getDisplayName())

        local Pattern = Group:getPatterns():getFocusObject()
        if Pattern then
            Info.NormalMode = Info.NormalMode .. " " .. AccessibilityTextHelper.getPatternName(Pattern:getNameParameter():getValue())
        else
            Info.NormalMode = Info.NormalMode .. " No Pattern"
        end
    end

    return Info

end

------------------------------------------------------------------------------------------------------------------------

