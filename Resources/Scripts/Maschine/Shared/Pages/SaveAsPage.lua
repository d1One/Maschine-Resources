require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Maschine/MaschineStudio/Screens/ScreenWithGridStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SaveAsPage = class( 'SaveAsPage', PageMaschine )

local BUTTON_INDEX_BANK_PREV = 3
local BUTTON_INDEX_BANK_NEXT = 4
local BUTTON_INDEX_CANCEL = 5
local BUTTON_INDEX_SAVE = 8
local ENCODER_INDEX_CONTENT_TYPE = 1
local ENCODER_INDEX_CONTENT_SELECTOR = 2
local ENCODER_INDEX_WITH_SAMPLES = 3
local ENCODER_INDEX_DELETE_UNUSED = 4

------------------------------------------------------------------------------------------------------------------------

function SaveAsPage:__init(Controller)

    PageMaschine.__init(self, "SaveAsPage", Controller)

    self.PageLEDs = { NI.HW.LED_FILE }
    self.CurrentLevelTab = NI.DATA.LEVEL_TAB_SONG

    self:setupScreen()

    self.SaveWithSamples = false
    self.DeleteUnused = false

end

------------------------------------------------------------------------------------------------------------------------

function SaveAsPage:setupScreen()

    local SaveAsText = NI.APP.isHeadless() and "SAVE AS" or "SAVE"
    self.Screen = ScreenWithGridStudio(self, { SaveAsText, "", "<<", ">>" }, { "CANCEL", "", "", SaveAsText })

    -- Param Bar (Left)
    local ParamBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "ParamBar")
    ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.Screen:addParameterBar(ParamBar)
    self.Screen:insertGroupButtons(true)
    self.Screen.ScreenButton[1]:setSelected(true)

    self.Screen.GroupBank = MaschineHelper.getFocusGroupBank()

end

------------------------------------------------------------------------------------------------------------------------

function SaveAsPage:onShow(Show)

    if Show then
        self.CurrentLevelTab = NI.DATA.LEVEL_TAB_SONG
        self.Screen.GroupBank = MaschineHelper.getFocusGroupBank()

    end
    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function SaveAsPage:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function SaveAsPage:updateParameters(ForceUpdate)

    self.ParameterHandler.NumPages = 1

    local IsSound = self.CurrentLevelTab == NI.DATA.LEVEL_TAB_SOUND
    local IsGroup = self.CurrentLevelTab == NI.DATA.LEVEL_TAB_GROUP
    local IsProject = self.CurrentLevelTab == NI.DATA.LEVEL_TAB_SONG

    local Lists = {}
    local Values = {}
    local FocusIndexes = {}
    local Names = {}
    local Sections = { "Content Selector" }
    local Colors = {}

    -- Content type
    Names[ENCODER_INDEX_CONTENT_TYPE] = "CONTENT TYPE"
    Values[ENCODER_INDEX_CONTENT_TYPE] = MaschineHelper.getLevelTabAsString(self.CurrentLevelTab)
    FocusIndexes[ENCODER_INDEX_CONTENT_TYPE] = MaschineHelper.getLevelTabAsString(self.CurrentLevelTab)
    Lists[ENCODER_INDEX_CONTENT_TYPE] =
    {
        MaschineHelper.getLevelTabAsString(NI.DATA.LEVEL_TAB_SONG),
        MaschineHelper.getLevelTabAsString(NI.DATA.LEVEL_TAB_GROUP),
        MaschineHelper.getLevelTabAsString(NI.DATA.LEVEL_TAB_SOUND)
    }

    -- Selector
    Names[ENCODER_INDEX_CONTENT_SELECTOR] = IsProject and "" or "SELECTED"

    if IsGroup or IsSound then
        local CurrentValue, CapListValues, CapListFocusIndex, CapListColors
        if IsGroup then
            CurrentValue, CapListValues, CapListFocusIndex, CapListColors = self:getGroupsParameterData()

        else
            CurrentValue, CapListValues, CapListFocusIndex, CapListColors = self:getSoundsParameterData()

        end

        Values[ENCODER_INDEX_CONTENT_SELECTOR] = CurrentValue
        FocusIndexes[ENCODER_INDEX_CONTENT_SELECTOR] = CapListFocusIndex
        Lists[ENCODER_INDEX_CONTENT_SELECTOR] = CapListValues
        Colors[ENCODER_INDEX_CONTENT_SELECTOR] = CapListColors

    end

    -- With samples / Delete unused
    if NI.APP.isHeadless() then
        Names[ENCODER_INDEX_WITH_SAMPLES] = "WITH SAMPLES"
        Values[ENCODER_INDEX_WITH_SAMPLES] = self.SaveWithSamples and "On" or "Off"

        Names[ENCODER_INDEX_DELETE_UNUSED] = "DELETE UNUSED"
        Values[ENCODER_INDEX_DELETE_UNUSED] = self.DeleteUnused and "On" or "Off"

    end

    self.ParameterHandler:setParameters({})
    self.ParameterHandler:setCustomSections(Sections)
    self.ParameterHandler:setCustomNames(Names)
    self.ParameterHandler:setCustomValues(Values)
    self.Controller.CapacitiveList:assignListsToCaps(Lists, FocusIndexes, Colors)

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SaveAsPage:getSoundsParameterData()

    local ListValues = {}
    local ListColors = {}

    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)
    local Sounds = FocusGroup and FocusGroup:getSounds() or nil
    local FocusSoundIndex = NI.DATA.StateHelper.getFocusSoundIndex(App)
    if Sounds then
        for Index = 0, Sounds:size()-1 do
            local Sound = Sounds:at(Index)
            local Enabled = Sound and App:getStateCache():getObjectCache():isSoundEnabled(Sound)
            ListValues[Index + 1] = Sound and Sound:getDisplayName() or "-"
            ListColors[Index + 1] = Enabled and Sound:getColorParameter():getValue()
        end
    end

    local FocusSound = NI.DATA.StateHelper.getFocusSound(App)
    return FocusSound and FocusSound:getDisplayName() or "", ListValues, FocusSoundIndex, ListColors

end

------------------------------------------------------------------------------------------------------------------------

function SaveAsPage:getGroupsParameterData()

    local ListValues = {}
    local ListColors = {}

    local FocusSong = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = FocusSong and FocusSong:getGroups() or nil
    local FocusGroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)
    if Groups then
        for Index = 0, Groups:size()-1 do
            local Group = Groups:at(Index)
            ListValues[Index + 1] = Group and Group:getDisplayName() or "-"
            ListColors[Index + 1] = Group:getColorParameter():getValue()
        end
    end

    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)
    return FocusGroup and FocusGroup:getDisplayName() or "", ListValues, FocusGroupIndex, ListColors

end

------------------------------------------------------------------------------------------------------------------------

function SaveAsPage:updateScreens(ForceUpdate)

    -- make sure GroupBank is not pointing to some outdated value after groups updates
    self.Screen:updateGroupBank(self)

    local BaseGroupIndex = MaschineHelper.getFocusGroupBank(self) * 8

    self.Screen:updateGroupButtonsWithFunctor(
        function(Index)
            local IsGroup = self.CurrentLevelTab == NI.DATA.LEVEL_TAB_GROUP
            local Visible, Enabled, Selected, Focused, Text =
                SelectHelper.getSelectButtonStatesGroups(Index + BaseGroupIndex)

            return Visible, Enabled, IsGroup and Selected, IsGroup and Focused, Text
        end)

    self.Screen:updatePadButtonsWithFunctor(
        function(Index)
            local IsSound = self.CurrentLevelTab == NI.DATA.LEVEL_TAB_SOUND
            local Visible, Enabled, Selected, Focused, Text =
               PadModeHelper.getScreenPadButtonState(Index)

            return Visible, Enabled, IsSound and Selected, IsSound and Focused, Text
        end)

    -- multi button
    self.Screen.ScreenButton[8]:setSelected(App:getWorkspace():getSelectMultiParameter():getValue())

    if self.CurrentLevelTab == NI.DATA.LEVEL_TAB_SONG then
        self.Screen.ScreenLeft.InfoBar:setMode("FilePageProjectName")

    elseif self.CurrentLevelTab == NI.DATA.LEVEL_TAB_GROUP then
        self.Screen.ScreenLeft.InfoBar:setMode("Group")

    elseif self.CurrentLevelTab == NI.DATA.LEVEL_TAB_SOUND then
        self.Screen.ScreenLeft.InfoBar:setMode("Sound")

    end

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SaveAsPage:onScreenButton(Index, Pressed)

    if Pressed and Index == BUTTON_INDEX_CANCEL then
        NHLController:getPageStack():popPage()


    elseif Pressed and Index == BUTTON_INDEX_BANK_PREV then
            MaschineHelper.incrementFocusGroupBank(self, -1, false, true)

    elseif Pressed and Index == BUTTON_INDEX_BANK_NEXT then
            MaschineHelper.incrementFocusGroupBank(self, 1, false, true)

    elseif Pressed and Index == BUTTON_INDEX_SAVE then
        local IsSound = self.CurrentLevelTab == NI.DATA.LEVEL_TAB_SOUND
        local IsGroup = self.CurrentLevelTab == NI.DATA.LEVEL_TAB_GROUP
        local IsProject = self.CurrentLevelTab == NI.DATA.LEVEL_TAB_SONG

        if IsSound then
            if NI.APP.isHeadless() and self.SaveWithSamples then
                NI.GUI.GroupFileCommands.saveFocusSoundAsWithSamples(App, self.DeleteUnused)

            elseif NI.APP.isHeadless() then
                NI.GUI.GroupFileCommands.saveFocusSoundAs(App)

            else
                NI.GUI.GroupFileCommands.saveFocusSoundWithCurrentName(App)

            end

            NHLController:getPageStack():popPage()

        elseif IsGroup then
            if NI.APP.isHeadless() and self.SaveWithSamples then
                NI.GUI.SongFileCommands.saveFocusGroupAsWithSamples(App, self.DeleteUnused)

            elseif NI.APP.isHeadless() then
                NI.GUI.SongFileCommands.saveFocusGroupAs(App)

            else
                NI.GUI.SongFileCommands.saveFocusGroupWithCurrentName(App)

            end

            NHLController:getPageStack():popPage()

        elseif IsProject then
            if NI.APP.isHeadless() and self.SaveWithSamples then
                NI.GUI.ProjectFileCommands.saveProjectAsWithSamples(App, self.DeleteUnused)

            elseif NI.APP.isHeadless() then
                NI.GUI.ProjectFileCommands.saveProjectAs(App)

            else
                NI.GUI.ProjectFileCommands.saveProjectWithCurrentName(App)

            end

            NHLController:getPageStack():popPage()

        end

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SaveAsPage:onScreenEncoder(Index, Value)

    local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) ~= 0
    local Page = self.ParameterHandler.PageIndex
    local Next = Value > 0
    local Increment = Next and 1 or -1

    local IsSound = self.CurrentLevelTab == NI.DATA.LEVEL_TAB_SOUND
    local IsGroup = self.CurrentLevelTab == NI.DATA.LEVEL_TAB_GROUP
    local IsProject = self.CurrentLevelTab == NI.DATA.LEVEL_TAB_SONG

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if EncoderSmoothed and Index == ENCODER_INDEX_CONTENT_TYPE then
        if (Next and not IsSound) or (not Next and not IsProject) then
            self.CurrentLevelTab = self.CurrentLevelTab + Increment
            self:updateScreens(false)

        end

    elseif EncoderSmoothed and Index == ENCODER_INDEX_CONTENT_SELECTOR then
        if IsSound and Group then
            NI.DATA.GroupAccess.shiftSoundFocus(App, Group, Increment, false, false)

        elseif IsGroup and Song then
            NI.DATA.SongAccess.shiftGroupFocus(App, Song, Increment, false)

        end

    elseif EncoderSmoothed and Index == ENCODER_INDEX_WITH_SAMPLES then
        self.SaveWithSamples = Next
        self:updateParameters(false)

    elseif EncoderSmoothed and Index == ENCODER_INDEX_DELETE_UNUSED then
        self.DeleteUnused = Next
        self:updateParameters(false)

    end

    PageMaschine.onScreenEncoder(self, Index, Value)

end

------------------------------------------------------------------------------------------------------------------------

function SaveAsPage:onGroupButton(ButtonIndex, Pressed)

    if not Pressed then
        return

    end

    local GroupIndex = ButtonIndex + (self.Screen.GroupBank * 8) - 1

    self.CurrentLevelTab = NI.DATA.LEVEL_TAB_GROUP
    MaschineHelper.selectGroupByIndex(GroupIndex)

    self:updateScreens(false)

end

------------------------------------------------------------------------------------------------------------------------

function SaveAsPage:onPadEvent(PadIndex, Trigger)

    if not Trigger then
        return

    end

    self.CurrentLevelTab = NI.DATA.LEVEL_TAB_SOUND
    MaschineHelper.selectSoundByPadIndex(PadIndex, Trigger)

    self:updateScreens(false)

end

------------------------------------------------------------------------------------------------------------------------

function SaveAsPage:updatePadLEDs()

    LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_LEDS,
        0,
        function(SoundIndex)
            local IsSound = self.CurrentLevelTab == NI.DATA.LEVEL_TAB_SOUND
            local Selected, Enabled = MaschineHelper.getLEDStatesSoundSelectedByIndex(SoundIndex)
            return Selected and IsSound, Enabled
        end,
        MaschineHelper.getSoundColorByIndex,
        function()
            return false
        end)

end

------------------------------------------------------------------------------------------------------------------------

function SaveAsPage:updateGroupLEDs()

    LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS, self.Screen.GroupBank * 8,
        function (Index)
            local IsGroup = self.CurrentLevelTab == NI.DATA.LEVEL_TAB_GROUP
            local Selected, Enabled = MaschineHelper.getLEDStatesGroupSelectedByIndex(Index, false)
            return Selected and IsGroup, Enabled
        end,
        function (Index) return MaschineHelper.getGroupColorByIndex(Index, true) end,
        function()
            return false
        end)

end

------------------------------------------------------------------------------------------------------------------------

function SaveAsPage:getAccessiblePageInfo()

    return "Save"

end

------------------------------------------------------------------------------------------------------------------------
