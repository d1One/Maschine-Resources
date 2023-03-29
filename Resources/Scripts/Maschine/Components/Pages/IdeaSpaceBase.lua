------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Maschine/Helper/PatternHelper"
require "Scripts/Maschine/KompleteKontrolS2/Helper/ScenePatternHelper"

local ATTR_IDEA_SPACE = NI.UTILS.Symbol("IdeaSpace")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
IdeaSpaceBase = class( 'IdeaSpaceBase', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceBase:__init(Name, Controller)

    PageMaschine.__init(self, Name, Controller)

    self.GroupBank = 0
    self.NumSceneBanks = 0
    self.ShiftFunctionsDiscard = false

    self.Screen = ScreenMaschineStudio(self)

    self.IdeaSpace = NI.GUI.insertIdeaSpace(self.Screen.RootBar, App, "IdeaSpace")
    self.IdeaSpace:setNoAlign(true)
    self.IdeaSpace:setHardwareMode()

    self.ScreenButtonsBar = NI.GUI.insertBar(self.Screen.RootBar, "IdeaSpaceScreenButtons")
    self.ScreenButtonsBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "StudioDisplay")
    self.ScreenButtonsBar:setNoAlign(true)

    self:setup()

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceBase:setup()

    self.Screen:addScreenButtonBar(self.ScreenButtonsBar, {"IDEAS", "SONG", "CLEAR", "DUPLICATE"}, {"HeadTabLeft", "HeadTabRight", "HeadButton", "HeadButton"}, false)
    self.Screen:addScreenButtonBar(self.ScreenButtonsBar, {"CREATE", "DELETE", "<<", ">>"}, "HeadButton", false)

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceBase:onShiftButton(Pressed)

    NHLController:setScreenButtonMode(Pressed and NI.HW.SCREENBUTTON_MODE_NONE or NI.HW.SCREENBUTTON_MODE_SCENES)

    PageMaschine.onShiftButton(self, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceBase:onShow(Show)

    PageMaschine.onShow(self, Show)

    NHLController:setScreenButtonMode(Show and not self.Controller:getShiftPressed() and NI.HW.SCREENBUTTON_MODE_SCENES or NI.HW.SCREENBUTTON_MODE_NONE)

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceBase:updateScreens(ForceUpdate)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song == nil then
        return
    end

    self.NumSceneBanks = math.ceil((Song:getScenes():size() + 1) / 8)

    if ForceUpdate or (NI.DATA.ParameterCache.isValid(App) and
        (Song:getArrangerState():isFocusChanged() or Song:getArrangerState():isViewChanged())) then
        self.IdeaSpace:setAttribute(ATTR_IDEA_SPACE, ScenePatternHelper.isIdeaSpace() and "true" or "false")
    end

    local FocusScene = ScenePatternHelper.isIdeaSpace() and Song:getScenes():getFocusObject() or nil
    if ForceUpdate
        or (NI.DATA.ParameterCache.isValid(App)
            and (App:getStateCache():isFocusSceneChanged() or Song:getScenes():isSortOrderChanged())) then

        local SceneBank = ForceUpdate and 0 or (FocusScene and math.floor(Song:getScenes():calcIndex(FocusScene) / 8) or 0)

        self:setSceneBank(SceneBank)
        self.IdeaSpace:setSceneOffset(SceneBank * 8)
    end

    if ForceUpdate or App:getStateCache():isFocusGroupChanged() then
        self.GroupBank = math.floor(NI.DATA.StateHelper.getFocusGroupIndex(App) / 8)
        self.IdeaSpace:setGroupOffset(self.GroupBank * 8)
    end

    if self.Controller:getShiftPressed() and not self.ShiftFunctionsDiscard then
        NHLController:setScreenButtonMode(NI.HW.SCREENBUTTON_MODE_NONE)
        self.ScreenButtonsBar:setVisible(true)

        for ButtonIndex = 1, 8 do
            self.Screen.ScreenButton[ButtonIndex]:setVisible(true)
            self.Screen.ScreenButton[ButtonIndex]:setSelected(false)
            self.Screen.ScreenButton[ButtonIndex].Color = nil
        end

        self:updateArrangerToggleButtons()

        self.Screen.ScreenButton[3]:setEnabled(ScenePatternHelper.isIdeaSpace() and not PatternHelper.isFocusSceneEmpty())

        self.Screen.ScreenButton[4]:setEnabled(FocusScene ~= nil)
        self.Screen.ScreenButton[5]:setEnabled(ScenePatternHelper.isIdeaSpace())
        self.Screen.ScreenButton[6]:setEnabled(FocusScene ~= nil)

        self:updateSceneBankButtons()
        self:updateRetriggerButton()

    else
        if self.ScreenButtonsBar:isVisible() then
            NHLController:setScreenButtonMode(NI.HW.SCREENBUTTON_MODE_SCENES)
            self.ScreenButtonsBar:setVisible(false)
        end

        for ButtonIndex = 1, 8 do

            local SceneIndex = ButtonIndex + self:getSceneBank() * 8 - 1
            local Scene = Song:getScenes():at(SceneIndex)

            local ShowPlus = SceneIndex == Song:getScenes():size()

            self.Screen.ScreenButton[ButtonIndex]:setVisible(Scene ~= nil or ShowPlus)
            self.Screen.ScreenButton[ButtonIndex]:setEnabled(Scene ~= nil or ShowPlus)
            self.Screen.ScreenButton[ButtonIndex]:setSelected(not ShowPlus and Scene == FocusScene)
            self.Screen.ScreenButton[ButtonIndex].Color = Scene and Scene:getColorParameter():getValue() or nil

        end
    end

    if not self.Controller:getShiftPressed() then
        self.ShiftFunctionsDiscard = false
    end

    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceBase:updateLEDs()

    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local HasEvents = Pattern and not Pattern:isEmpty()

    local SceneBank = self:getSceneBank()

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_LEFT, NI.HW.BUTTON_LEFT, SceneBank > 0)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_RIGHT, NI.HW.BUTTON_RIGHT, SceneBank < self.NumSceneBanks - 1)

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceBase:onCapTouched(EncoderID, Touched)

    if Touched then
        MaschineHelper.setFocusGroup(self.GroupBank * 8 + EncoderID, false)
    end

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceBase:onScreenEncoder(Idx, Inc)

    if not ScenePatternHelper.isIdeaSpace() or MaschineHelper.onScreenEncoderSmoother(Idx, Inc, .1) == 0 then
        return
    end

    local NewGroupIndex = self.GroupBank * 8 + Idx
    if MaschineHelper.getGroupAtIndex(NewGroupIndex - 1) == nil then
        return
    end

    MaschineHelper.setFocusGroup(NewGroupIndex, false)

    local Forward = 0 < Inc and true or false
    PatternHelper.focusPrevNextPattern(Forward, true)

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceBase:onScreenButton(ButtonIdx, Pressed)

    if Pressed then
        local Song = NI.DATA.StateHelper.getFocusSong(App)

        if Song and self.Controller:getShiftPressed() and not self.ShiftFunctionsDiscard then
            local FocusScene = ScenePatternHelper.isIdeaSpace() and Song:getScenes():getFocusObject() or nil

            if ButtonIdx == 1 then
                NI.DATA.SongAccess.focusIdeas(App, Song)

            elseif ButtonIdx == 2 then
                NI.DATA.SongAccess.focusSongTimeline(App, Song)

            elseif ButtonIdx == 3 and ScenePatternHelper.isIdeaSpace() then
                NI.DATA.SceneAccess.clearScene(App, Song, FocusScene)

            elseif ButtonIdx == 4 and FocusScene then
                NI.DATA.IdeaSpaceAccess.duplicateScene(App, Song, FocusScene)
                self.ShiftFunctionsDiscard = true

            elseif ButtonIdx == 5 and FocusScene then
                NI.DATA.IdeaSpaceAccess.insertSceneAfterFocusScene(App, Song)
                self.ShiftFunctionsDiscard = true

            elseif ButtonIdx == 6 and FocusScene then
                ArrangerHelper.removeFocusedSceneOrBank(false)
                self.ShiftFunctionsDiscard = true

            elseif ButtonIdx == 7 or ButtonIdx == 8 then

                self:shiftFocusSceneBank(ButtonIdx == 8)
            end
        end

    end

    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceBase:shiftFocusSceneBank(Right)

    local SceneBank = self:getSceneBank()
    if (not Right) and SceneBank > 0 or Right and SceneBank < self.NumSceneBanks - 1 then
        SceneBank = SceneBank + (Right and 1 or -1)

        self:setSceneBank(SceneBank)
        self.IdeaSpace:setSceneOffset(SceneBank * 8)
    end
end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceBase:onLeftRightButton(Right, Pressed)

    if Pressed then
        self:shiftFocusSceneBank(Right)
        self:updateScreens()
    end
end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceBase:onWheelButton(Pressed)

    ScenePatternHelper.onWheelButton(Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceBase:onWheelDirection(Pressed, Button)

    ScenePatternHelper.onWheelDirection(Pressed, Button)
end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceBase:onWheel(Value)

    if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_DEFAULT and not self.Controller:getShiftPressed() then
        ScenePatternHelper.onWheel(Value)
        return true
    end
end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceBase:getAccessibleTextByButtonIndex(ButtonIdx)

    if not self.Controller:getShiftPressed() or self.ShiftFunctionsDiscard then
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        if Song then
            local SceneIndex = ButtonIdx + self:getSceneBank() * 8 - 1
            if SceneIndex < Song:getScenes():size() then
                local Scene = Song:getScenes():at(SceneIndex)
                return Scene:getNameParameter():getValue()
            elseif SceneIndex == Song:getScenes():size() then
                return "Create Scene"
            end
        end
        
        return ""
    end

    return PageMaschine.getAccessibleTextByButtonIndex(self, ButtonIdx)

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceBase:getAccessibleParamDescriptionByIndex(EncoderIdx)

    local GroupIndex = self.GroupBank * 8 + EncoderIdx
    if not MaschineHelper.getGroupAtIndex(GroupIndex - 1) then
        return "", "", "", ""
    end

    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local PatternName = Pattern and Pattern:getNameParameter():getValue() or "No Pattern"
    return PatternName, "", "", ""

end

------------------------------------------------------------------------------------------------------------------------
