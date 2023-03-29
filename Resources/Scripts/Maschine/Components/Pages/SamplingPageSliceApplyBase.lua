------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/PatternHelper"
require "Scripts/Maschine/Helper/SelectHelper"
require "Scripts/Maschine/MaschineStudio/Screens/ScreenWithGridStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SamplingPageSliceApplyBase = class( 'SamplingPageSliceApplyBase', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyBase:__init(Name, Controller, Parent)

    PageMaschine.__init(self, Name, Controller)

    -- setup screen
    self:setupScreen()
    self.Parent = Parent

    self.FocusSoundIndex = 0
    self.FocusGroupIndex = 0
    self.BlinkTick = 0
end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyBase:setupScreen()

    -- group buttons in left screen
    self.Screen:insertGroupButtons(true)

    -- set All Slices selected by default
    self.Screen.ScreenButton[5]:setSelected(false)

end

------------------------------------------------------------------------------------------------------------------------
--Functor: Visible, Enabled, Selected, Focused, Text

function SamplingPageSliceApplyBase:getButtonStateForGroup(Index)

    Index = Index - 1 -- make 0-indexed

    local StateCache  = App:getStateCache()
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil
    local Group = Groups and Groups:at(Index)

    if Group and self.FocusGroupIndex then

        local Focused = (Index == self.FocusGroupIndex-1)
        return true, true, false, Focused, Group:getDisplayName()

    elseif Groups and Index == Groups:size() then
        return true, true, false, Index == self.FocusGroupIndex-1, "+"
    elseif Group then
        return true, false, false, false, Group:getDisplayName()
    else
        return true, false, false, false, ""
    end


end

------------------------------------------------------------------------------------------------------------------------
--Functor: Visible, Enabled, Selected, Focused, Text

function SamplingPageSliceApplyBase:getButtonStateForSound(Index)

    Index = Index - 1 -- make 0-indexed

    if self.FocusGroupIndex == 0 then     -- no group selected
        return true, false, false, false, ""
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = Song and Song:getGroups():at(self.FocusGroupIndex - 1) or nil
    local Sounds = Group and Group:getSounds()
    local Sound = Sounds and Sounds:at(Index) or nil

    if Sound then

        local Focused = (Index == self.FocusSoundIndex-1)
        return true, true, false, Focused, Sound:getDisplayName()
    end

    return true, true, false, false, "Sound "..Index+1

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyBase:getPadLEDStates(SoundIndex) -- index >= 1

    local Focused = (SoundIndex == self.FocusSoundIndex) and ((self.BlinkTick % 8) < 4)
    return Focused, self.FocusGroupIndex ~= 0

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyBase:getGroupLEDStates(GroupIndex) -- index >= 1

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = Song and Song:getGroups():at(GroupIndex-1)

    if  Group or                                                    -- led for exsiting Group
        (Song and Song:getGroups():size() == GroupIndex - 1) then   -- led for new Group

        local Focused = (self.FocusSoundIndex == 0) and (GroupIndex == self.FocusGroupIndex)
                        and ((self.BlinkTick % 8) < 4)
        return Focused, true
    end

    return false, false

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyBase:updateScreens(ForceUpdate)

    local StateCache = App:getStateCache()

    -- Hide SliceApply sub page if we change sound
    if NI.DATA.StateHelper.getFocusSound(App) ~= self.FocusSound then
        self.FocusSound = NI.DATA.StateHelper.getFocusSound(App)
        self:onShow(false)
        self.Parent:onShow(true)
        return
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sounds = Group and Group:getSounds() or nil

    -- limit to max posible group banks, because max can always change
    self.Screen.GroupBank = math.min(self.Screen.GroupBank, MaschineHelper.getNumFocusSongGroupBanks(true) - 1)
    local BaseGroupIndex = self.Screen.GroupBank * 8

    self.Screen:updateGroupButtonsWithFunctor(
        function(Index)
            return SamplingPageSliceApplyBase.getButtonStateForGroup(self, Index + BaseGroupIndex)
        end)

    self.Screen:updatePadButtonsWithFunctor(
        function(Index)
            return SamplingPageSliceApplyBase.getButtonStateForSound(self, Index)
        end)

    self.Screen.ScreenButton[8]:setEnabled(self.FocusGroupIndex ~= 0 or self.FocusSoundIndex ~= 0)

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyBase:updatePadLEDs()

    self.BlinkTick = self.BlinkTick + 1

    LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_LEDS, 0,
        function(Index) return SamplingPageSliceApplyBase.getPadLEDStates(self, Index) end,
        function(Index) return MaschineHelper.getSoundColorByIndex(Index, self.FocusGroupIndex, true) or LEDColors.WHITE end)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyBase:updateGroupLEDs()

    -- update group leds with focus state
    LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS,
        self.Screen.GroupBank * 8,
        function(Index) return SamplingPageSliceApplyBase.getGroupLEDStates(self, Index) end,
        function(Index) return MaschineHelper.getGroupColorByIndex(Index, true) end)

end


------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyBase:onGroupButton(ButtonIndex, Pressed)

    if not Pressed then
        return
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local GroupsSize = Song and Song:getGroups():size() or 0
    local NewIndex = ButtonIndex + self.Screen.GroupBank * 8

    if NewIndex == GroupsSize + 1                       -- new Group button
       or Song:getGroups():at(NewIndex- 1) then   -- button for exsisting Group

        self.FocusGroupIndex = NewIndex
        self.FocusSoundIndex = 0
        self.Screen.DisplayGroup = self.FocusGroupIndex
        self:updateScreens()
    end
end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyBase:onPadEvent(PadIndex, Trigger)

    self.FocusSoundIndex = self.FocusGroupIndex > 0 and PadIndex or 0
    self:updateScreens()

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyBase:onScreenButton(ButtonIdx, Pressed)


    if Pressed then
        if ButtonIdx == 3 or ButtonIdx == 4 then

            local NewGroupBank = self.Screen.GroupBank + (ButtonIdx == 3 and -1 or 1)
            local MaxPageIndex = MaschineHelper.getNumFocusSongGroupBanks(true)

            if NewGroupBank >= 0 and NewGroupBank < MaxPageIndex then
                self.Screen.GroupBank = NewGroupBank
            end

        -- Single Toggle
        elseif ButtonIdx == 5 then

            local NumSlices, FocusSliceIndex  = SamplingHelper.getNumSlicesAndFocusSliceIndex()
            if NumSlices ~= 1 then
                local SingleOn = self.Screen.ScreenButton[5]:isSelected()
                self.Screen.ScreenButton[5]:setSelected(not SingleOn)
            end

        --Cancel
        elseif ButtonIdx == 7 then
            self:onShow(false)
            self.Parent:onShow(true)

        --Apply
        elseif ButtonIdx == 8 then
            self:applySettings()

        end
    end

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyBase:onShow(Show)

    -- synchronize local group bank with parameter
    if Show then
        local FocusGroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)
        self.FocusGroupIndex = FocusGroupIndex == NPOS and 0 or (FocusGroupIndex+1)
        self.Screen.DisplayGroup = self.FocusGroupIndex
        self.Screen.GroupBank = MaschineHelper.getFocusGroupBank()
        self.FocusSoundIndex = NI.DATA.StateHelper.getFocusSoundIndex(App) + 1
    end

    PageMaschine.onShow(self, Show)
end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyBase:applySettings()

    if self.FocusGroupIndex == 0 then
        return
    end

    SamplingHelper.applySlicing(self.FocusGroupIndex, self.FocusSoundIndex, self.Screen.ScreenButton[5]:isSelected())

    self:onShow(false)
    self.Parent:onShow(true)

end

------------------------------------------------------------------------------------------------------------------------
