local class = require 'Scripts/Shared/Helpers/classy'
SelectHelper = class( 'SelectHelper' )

------------------------------------------------------------------------------------------------------------------------
-- Functor: Visible, Enabled, Selected, Focused, Text

function SelectHelper.getSelectButtonStatesGroups(Index)

    Index = Index - 1 -- make 0-indexed


    local Song         = NI.DATA.StateHelper.getFocusSong(App)
    local Groups       = Song:getGroups()
    local Group        = Groups and Groups:at(Index) or nil

    if Group then

        local MultiSelect   = App:getWorkspace():getSelectMultiParameter():getValue()

        local Enabled       = false
        local Name = ""
        local HasFocus		= false

        Enabled = true --group is always 'enabled' even if none of the sounds contain anything
        Name = Group:getDisplayName()

        HasFocus = Group ==  NI.DATA.StateHelper.getFocusGroup(App)

        local HasSelection  = false

        if not HasFocus then
            HasSelection = Groups:isInSelection(Group)
        end

        return true, Enabled or HasFocus, HasSelection or HasFocus, HasFocus, Name

    end

    return true, false, false, false, ""

end

------------------------------------------------------------------------------------------------------------------------
-- Functor: Visible, Enabled, Selected, Focused, Text

function SelectHelper.getSelectButtonStatesSounds(Index)

    Index = Index - 1 -- make 0-indexed

    local StateCache   = App:getStateCache()
    local Song         = NI.DATA.StateHelper.getFocusSong(App)
    local Group        = NI.DATA.StateHelper.getFocusGroup(App)
    local Sounds       = Group and Group:getSounds() or nil
    local Sound        = Sounds and Sounds:at(Index) or nil

    if Sound then

        local MultiSelect   = App:getWorkspace():getSelectMultiParameter():getValue()

        local Enabled       = false
        local Name = ""
        local HasFocus		= false

        Enabled = StateCache:getObjectCache():isSoundEnabled(Sound)
        Name = Enabled and Sound:getDisplayName() or ""
        HasFocus = Sound == NI.DATA.StateHelper.getFocusSound(App)

        local HasSelection  = false

        if not HasFocus then
            HasSelection = Sounds:isInSelection(Sound)
        end

        return true, Enabled or HasFocus, HasSelection or HasFocus, HasFocus, Name
    end

    return true, false, false, false, ""

end

------------------------------------------------------------------------------------------------------------------------

function SelectHelper.updatePadLEDsSounds(LEDs, ErasePressed)

    if ErasePressed then
        LEDHelper.updateLEDsWithFunctor(LEDs,
                0,
                function(SoundIndex) return MaschineHelper.getLEDStatesSoundEventsByIndex(SoundIndex, true) end,
                MaschineHelper.getSoundColorByIndex)
    else
        LEDHelper.updateLEDsWithFunctor(LEDs,
                0,
                MaschineHelper.getLEDStatesSoundSelectedByIndex,
                MaschineHelper.getSoundColorByIndex,
                MaschineHelper.getFlashStateSoundsNoteOn)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SelectHelper.updateGroupLEDs(LEDs, GroupBank)

    -- update Group leds with focus & selected states
    LEDHelper.updateLEDsWithFunctor(LEDs,
        GroupBank * 8,
        function (Index) return MaschineHelper.getLEDStatesGroupSelectedByIndex(Index, false) end,
        function (Index) return MaschineHelper.getGroupColorByIndex(Index, true) end,
        MaschineHelper.getFlashStateGroupsNoteOn)

end

------------------------------------------------------------------------------------------------------------------------
