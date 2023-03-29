------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Jam/Helper/Duplicate"
require "Scripts/Maschine/Jam/Helper/JamHelper"
require "Scripts/Maschine/Jam/Helper/JamArrangerHelper"
require "Scripts/Maschine/Jam/Helper/QuickArrange"
require "Scripts/Maschine/Jam/Helper/Jam16VelocityMode"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PageJam = class( 'PageJam' )

------------------------------------------------------------------------------------------------------------------------

function PageJam:__init(Name, Controller)

    self.Name = Name
    self.Controller = Controller
    self.Duplicate = Duplicate(Controller)
    self.QuickArrange = QuickArrange(Controller)

    self.IsPinned = false
    self.GroupBank = 0

    -- OSO type
    self.GetOSOTypeFn = function() return NI.HW.OSO_NONE end

    self.Is16VelocityModeEnabled = function() return false end

    self.CloseOSOOnPageLeaveFn = function()
        return JamHelper.isJamNonStaticOSOVisible()
            and not self.Controller:isButtonPressed(NI.HW.BUTTON_SWING)
            and not self.Controller:isButtonPressed(NI.HW.BUTTON_TUNE)
    end

    self.ActivateOSOOnShow = true

    -- LEDs related to this page
    self.PageLEDs = {}

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:onShow(Show)

    if Show then

        self:updateLEDs()
        self.GroupBank = MaschineHelper.getFocusGroupBank()

        -- Show OSO if this page has one
        local OSOType = self.ActivateOSOOnShow and self.GetOSOTypeFn() or NI.HW.OSO_NONE
        if OSOType ~= NI.HW.OSO_NONE and App:getJamParameterOverlay():getOSOType() ~= OSOType then
            self.Controller.ParameterHandler:showOSO(OSOType)
        else
            self.ActivateOSOOnShow = true -- reset to default
        end

        -- Deactivate Duplicate if we enter a page without duplicate mode
        if not self:hasDuplicateMode() then
            self:setDuplicateEnabled(false)
        end

    else

        -- Hide OSO on page leave if CloseOSOOnPageLeaveFn returns true
        if self.CloseOSOOnPageLeaveFn() then
            self.Controller.ParameterHandler:hideOSO()
        end

        -- Finish any transaction sequence started with scene buttons held down
        if JamArrangerHelper.getPressedSceneButtonsSize() > 0 then
            JamArrangerHelper.resetPressedSceneButtons()
            App:getTransactionManager():finishTransactionSequence()
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:hasDuplicateMode()

    return false

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:setDuplicateEnabled(Enabled)

    self.Duplicate:setEnabled(Enabled)

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:updateGroupLEDs(IncludeNewGroup)

    if IncludeNewGroup == nil then
        IncludeNewGroup = not self.Controller:isClearActive()    -- default value for parameter
    end

    if self.Duplicate:isEnabled() then
        self.Duplicate:updateGroupLEDs()
        return
    end

    LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS, JamHelper.getGroupOffset(),
            function (Index) return MaschineHelper.getLEDStatesGroupSelectedByIndex(Index, IncludeNewGroup, false) end,
            function (Index) return MaschineHelper.getGroupColorByIndex(Index, true) end,
            MaschineHelper.getFlashStateGroupsNoteOn)

    -- update pushed modifier button leds that are on the group buttons
    for Index, GroupButton in pairs(self.Controller.GROUP_BUTTONS) do
        if self.Controller:isSwitchModifierPairPressed(NI.HW.BUTTON_SHIFT, GroupButton) and
           self.Controller:isSwitchModifierPairHandlerActive(NI.HW.BUTTON_SHIFT, GroupButton) then
            LEDHelper.setLEDColorWithLUT(NI.HW.LED_GROUP_A + Index - 1, LEDColors.WHITE, LEDHelper.LS_BRIGHT)
        end
    end

end


------------------------------------------------------------------------------------------------------------------------

function PageJam:onCustomProcess(ForceUpdate)

    if App:getStateCache():isCurrentProjectChanged() then
        self:setDuplicateEnabled(false)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:onTimer()
end

------------------------------------------------------------------------------------------------------------------------

function PageJam:onSongButton(Pressed)

    if Pressed then
        self.QuickArrange:setTimer()
    else
        self.QuickArrange:resetTimer()
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:onGroupCreate(GroupIndex, Pressed, Song)

    NI.DATA.SongAccess.createGroup(App, Song, false)

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:onGroupButton(Index, Pressed)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups()
    local GroupIndex = Index + JamHelper.getGroupOffset()

    if not Pressed then
        return
    end

    local GroupIndex = Index + JamHelper.getGroupOffset()

    -- First check for clear mode,
    if self.Controller:isClearActive() then
        MaschineHelper.removeGroup(GroupIndex)

    -- then check for duplicate mode,
    elseif self.Duplicate:isEnabled() and self.Duplicate:canDuplicateGroup() then
        -- (duplicate handles Group button indices)
        self.Duplicate:onGroupDuplicate(Index - 1)

    -- and only then (if we are not in the process of duplicating a group to the first empty group slot)
    elseif Groups and not self.Duplicate:hasSource(Duplicate.MODE_PATTERN) then

        -- check whether the first empty group slot was selected
        if GroupIndex == Groups:size() + 1 then
            -- and call onGroupCreate (pressed case) then
            self:onGroupCreate(GroupIndex, Pressed, Song)
        else
            local Group = Groups:at(GroupIndex - 1)
            if Group then
                -- or forward to default focus handling otherwise.
                NI.DATA.SongAccess.setFocusGroup(App, Song, Group, false)
            end
        end
    else
        self:onGroupCreate(GroupIndex, Pressed, Song)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:onPadButton(Column, Row, Pressed)

    if self.Is16VelocityModeEnabled() then
        Jam16VelocityMode.onPadButton(Column, Row, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:selectSectionBank(Index)

    if Index <= JamArrangerHelper.getNumSectionBanks(true) then

        JamArrangerHelper.resetPressedSceneButtons()

        NI.DATA.ParameterAccess.setSizeTParameter(App,
            NHLController:getContext():getSectionBankParameter(), Index-1)

    end

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:selectSceneBank(Index)

    if Index <= JamArrangerHelper.getNumSceneBanks(true) then

        local BankParam = NHLController:getContext():getSceneBankParameter()
        NI.DATA.ParameterAccess.setSizeTParameter(App, BankParam, Index-1)

    end

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:onSceneButton(Index, Pressed)

    local SceneBankSelecting = self.Controller:isShiftPressed()
    local Arranging = self.QuickArrange:isActive()
    local Duplicating = self.Duplicate:isEnabled()
    local Clearing = self.Controller:isClearActive()
    local IdeaSpaceView = ArrangerHelper.isIdeaSpaceFocused()

    if SceneBankSelecting then

        if Pressed then
            self:selectSceneOrSectionBank(Index)
        end

    elseif Duplicating then

        if Pressed then
            self:duplicateSceneOrSection(Index)
        end

    elseif Clearing then

        if Pressed then
            self:removeSceneOrSection(Index)
        end

    elseif Arranging then

        if Pressed then
            self:quickArrangeScene(Index)
        end

    else -- focus or create

        NHLController:setSceneButtonMode(NI.HW.SCENE_BUTTON_MODE_DEFAULT)

        if not Pressed then
            local SongPos = JamArrangerHelper.getPositionBySceneButton(Index) -- 0-indexed and absolute
            JamArrangerHelper.updatePressedSceneButtons(Index, SongPos, false)
        end

        if Pressed then
            self:focusOrCreateSceneOrSection(Index)
        elseif not IdeaSpaceView and JamArrangerHelper.getPressedSceneButtonsSize() == 0 then
            App:getTransactionManager():finishTransactionSequence()
        end

    end

    if not Pressed then
        JamArrangerHelper.PressedSectionKeys[Index] = nil
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:focusOrCreateSceneOrSection(Index)

    if ArrangerHelper.isIdeaSpaceFocused() then
        self:focusOrCreateScene(Index)
    else
        self:focusOrCreateSection(Index)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:focusOrCreateSection(Index)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        return
    end

    local SongPos = JamArrangerHelper.getPositionBySceneButton(Index) -- 0-indexed and absolute
    local HasSceneAtSongPos = NI.DATA.SongAlgorithms.getSectionFromSectionPosition(Song, SongPos) ~= nil
    JamArrangerHelper.updatePressedSceneButtons(Index, SongPos, HasSceneAtSongPos)

    local Section = NI.DATA.SongAlgorithms.getSectionFromSectionPosition(Song, SongPos)

    if not Section then

        -- Create Section
        local LastSongPos = Song:getSections():size()
        if SongPos == LastSongPos and not JamArrangerHelper.isActiveSceneButtonPressed() then
            NI.DATA.SongAccess.createEmptySection(App, Song, -1)

            if NI.DATA.SongAlgorithms.getSectionFromSectionPosition(Song, SongPos) then
                JamArrangerHelper.updatePressedSceneButtons(Index, SongPos, true)
            end
        end

    else

        -- Set Section loop
        if NI.DATA.TransportAccess.isSectionLoopActive(App)
            and JamArrangerHelper.getPressedSceneButtonsSize() > 0 then

            local Min, Max = JamArrangerHelper.getMinMaxSceneIndexFromPressedSceneButtons()
            local MinKey = NI.DATA.SongAlgorithms.getSectionKeyFromSectionPosition(Song, Min)
            local MaxKey = NI.DATA.SongAlgorithms.getSectionKeyFromSectionPosition(Song, Max)
            local SectionKey = NI.DATA.SongAlgorithms.getSectionKeyFromSectionPosition(Song, SongPos)

            if SectionKey ~= nil and MinKey ~= nil and MaxKey ~= nil then
                NI.DATA.ArrangerAccess.focusSectionAndSetLoop(App, SectionKey, MinKey, MaxKey)
            end
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:focusOrCreateScene(Index)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        return
    end

    local SongPos = JamArrangerHelper.getPositionBySceneButton(Index, false)
    if SongPos > Song:getScenes():size() then
        return
    end

    local Scene = Song:getScenes():at(SongPos)
    ArrangerHelper.focusScene(Scene)

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:quickArrangeScene(Index)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        return
    end

    local SongPos = JamArrangerHelper.getPositionBySceneButton(Index, true)
    if SongPos > Song:getScenes():size() then
        return
    end

    local Scene = Song:getScenes():at(SongPos)
    if Scene then
        NI.DATA.SongAccess.createSectionWithScene(App, Song, -1, Scene, false)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:selectSceneOrSectionBank(Index)

    if ArrangerHelper.isIdeaSpaceFocused() or self.QuickArrange:isActive() then
        self:selectSceneBank(Index)
    else
        self:selectSectionBank(Index)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:duplicateSceneOrSection(Index)

    if ArrangerHelper.isIdeaSpaceFocused() then
        self.Duplicate:onSceneDuplicate(Index)
    else
        self.Duplicate:onSectionDuplicate(Index)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:removeSceneOrSection(Index)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local SongPos = JamArrangerHelper.getPositionBySceneButton(Index)

    if ArrangerHelper.isIdeaSpaceFocused() then

        local Scene = Song and Song:getScenes():at(SongPos)
        if Scene then
            NI.DATA.IdeaSpaceAccess.removeScene(App, Song, Scene)
        end

    else

        local Section = Song and NI.DATA.SongAlgorithms.getSectionFromSectionPosition(Song, SongPos)
        if Section then
            NI.DATA.SongAccess.removeSection(App, Song, Section)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:onLevelSourceButton(Pressed, Button)

    return false

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:updateSceneButtonLEDs()

    local ShiftPressed = self.Controller:isShiftPressed()
    local Arranging = self.QuickArrange:isActive()
    local ShowNewSection = not self.Controller:isClearActive()
        and (ArrangerHelper.isIdeaSpaceFocused() or not JamArrangerHelper.isActiveSceneButtonPressed())

    if self.Duplicate:isEnabled() and not ShiftPressed then
        self.Duplicate:updateSceneLEDs()
        return
    else

        LEDHelper.updateLEDsWithFunctor(self.Controller.SCENE_LEDS, 0,
            function (Index) return
                JamArrangerHelper.getSceneLEDState(Index, ShiftPressed, ShowNewSection, false, Arranging) end,
            function (Index) return
                JamArrangerHelper.getSceneLEDColorByIndex(Index, ShiftPressed, Arranging) end)

        -- update pressed Scene button in Arrange mode
        if Arranging then
            for Index, LedID in ipairs (self.Controller.SCENE_LEDS) do
                if self.Controller:isButtonPressed(LedID) then
                    LEDHelper.updateLedState(LedID, true, true,
                        JamArrangerHelper.getSceneLEDColorByIndex(Index, ShiftPressed, Arranging))
                end
            end
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:onDPadButton(Button, Pressed)

    if not Pressed then
        return
    end

    if (Button == NI.HW.BUTTON_DPAD_LEFT or Button == NI.HW.BUTTON_DPAD_RIGHT) then

        local GroupOffset = JamHelper.getGroupOffset()
        local ShiftPressed = self.Controller:isShiftPressed()

        local NewGroupOffset = Button == NI.HW.BUTTON_DPAD_LEFT
            and JamHelper.decreaseOffset(GroupOffset, 0, ShiftPressed)
            or  JamHelper.increaseGroupOffset(GroupOffset, MaschineHelper.getFocusSongGroupCount(), ShiftPressed)

        JamHelper.setGroupOffset(NewGroupOffset)

    end

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:onPinButton(Pressed)

    if self.Controller:isButtonPressed(NI.HW.BUTTON_DUPLICATE) then
        return self.Duplicate:onPinButton(Pressed)
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:onDuplicateButton(Pressed)

    self.Duplicate:onDuplicateButton(Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:onWheelEvent(Inc)

    return false

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:onWheelButton(Pressed)

    -- return "handled" if controller is set to change the Section Loop
    return JamArrangerHelper.canSectionLoopChange(self.Controller)
        or JamArrangerHelper.canShiftSceneOfSection(self.Controller)

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:onWheelTouch(Touched)

    -- return "handled" if controller is set to change the Section Loop
    return Touched and (JamArrangerHelper.canSectionLoopChange(self.Controller)
                        or JamArrangerHelper.canShiftSceneOfSection(self.Controller))

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:onTouchEvent(TouchID, TouchType, Value)

    return false

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:updatePageLEDs(LEDState)

    -- Turn on/off page LEDs
    for Index, LedID in ipairs (self.PageLEDs) do
        LEDHelper.setLEDState(LedID, LEDState)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:onPageButton(Button, PageID, Pressed)

    return false

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:updateLEDs()

    self:updateDPadLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:updateDPadLEDs()

    local NumGroups = MaschineHelper.getFocusSongGroupCount()
    local GroupOffset = JamHelper.getGroupOffset()

    local LeftOn = GroupOffset > 0
    local RightOn = GroupOffset < math.floor(NumGroups / 8) * 8

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_LEFT, NI.HW.BUTTON_DPAD_LEFT, LeftOn)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_RIGHT, NI.HW.BUTTON_DPAD_RIGHT, RightOn)

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:onLockButton()

    return false

end

------------------------------------------------------------------------------------------------------------------------

function PageJam:updatePadLEDs()

    if self.Is16VelocityModeEnabled() then
        Jam16VelocityMode.updatePadLEDs(self.Controller)
    end

    if self.Duplicate:isEnabled() then
        self.Duplicate:updateSoundLEDs()
    end

end

------------------------------------------------------------------------------------------------------------------------
