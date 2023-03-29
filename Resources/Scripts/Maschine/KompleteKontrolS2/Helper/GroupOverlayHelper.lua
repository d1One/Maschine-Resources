require "Scripts/Shared/Helpers/MaschineHelper"

local class = require 'Scripts/Shared/Helpers/classy'
GroupOverlayHelper = class( 'GroupOverlayHelper' )

local GroupBank = 0

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper.onSetup(Page)

    Page.GroupVector = NI.GUI.insertMixerBarVector(Page.ParametersOverlay, "GroupVector")
    Page.GroupVector:style(true, '')

    NI.GUI.connectVector(Page.GroupVector,
        GroupOverlayHelper.GroupSizeFunc,
        function(MixerBar) end,
        GroupOverlayHelper.GroupItemStateFunc)

    Page.GroupVector:getScrollbar():setAutohide(false)
    Page.GroupVector:getScrollbar():setActive(false)

    Page.GroupVector:setNoAlign(true)

end

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper.GroupSizeFunc()

    local NumGroupPages = MaschineHelper.getNumFocusSongGroupBanks(true)
    return NumGroupPages * 8
end

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper.GroupItemStateFunc(Mixerbar, Index)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups()
    local Group = Groups and Groups:at(Index)

    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)

    local State = {}

    State.Visible = true
    State.ControlsVisible = false

    if Group then

        State.Color = Group:getColorParameter():getValue()+1
        State.NameShort = NI.DATA.Group.getLabel(Index)
        State.NameLong = Group:getDisplayName()
        State.Focused = Index == NI.DATA.StateHelper.getFocusGroupIndex(App)
        State.Selected = State.Focused or Groups:isInSelection(Group)
        State.Muted = Group:getMuteParameter():getValue()
        State.SoundsVisible = false

    -- The + Button
    elseif Groups and Index == Groups:size() then

        State.Color = 0
        State.IsAdd = true
        State.NameShort = ""
        State.NameLong = ""
        State.Focused = false
        State.Selected = FocusGroup == nil and true or false

    else

        State.Visible = false
    end

    MixerVector.loadItem(Mixerbar, State)

end

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper.onShow(Show)

    local FocusGroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)
    GroupBank = FocusGroupIndex == NPOS and 0 or math.floor(FocusGroupIndex / 8)
end

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper.getParameterData(Index)

    local Data = {}
    local CapListValues = {}
    local CapListColors = {}
    if Index == 1 then
        Data.GroupName = "Sound"

        local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)
        local Sounds = FocusGroup and FocusGroup:getSounds() or nil
        local SoundIndex = NI.DATA.StateHelper.getFocusSoundIndex(App)
        if Sounds then
            for Index = 0, Sounds:size()-1 do
                local Sound = Sounds:at(Index)
                local Enabled = Sound and App:getStateCache():getObjectCache():isSoundEnabled(Sound)
                CapListValues[Index + 1] = Sound and Sound:getDisplayName() or "-"
                CapListColors[Index + 1] = Enabled and Sound:getColorParameter():getValue()
            end
        end

        local FocusSound = NI.DATA.StateHelper.getFocusSound(App)
        Data.Name = FocusSound and "SELECT" or ""
        Data.Value = FocusSound and FocusSound:getDisplayName() or ""
        Data.CapListIndex  = SoundIndex
        Data.CapListValues = CapListValues
        Data.CapListColors = CapListColors

    end

    return Data
end

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper.onClear(Pressed)

    if Pressed then
        MaschineHelper.removeFocusGroup()
    end
end

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper.onWheel(Value)

    GroupOverlayHelper.onScreenEncoder(1, Value)

end

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper.onWheelDirection(Pressed, Button)

    if not Pressed then
        return
    end

    local GroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)
    if (Button == NI.HW.BUTTON_WHEEL_LEFT or Button == NI.HW.BUTTON_WHEEL_RIGHT) and GroupIndex ~= NPOS then
        MaschineHelper.setFocusGroup((GroupIndex + 1) + (Button == NI.HW.BUTTON_WHEEL_LEFT and -1 or 1))
    end
end

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper.onScreenEncoder(Index, EncoderInc)

    if MaschineHelper.onScreenEncoderSmoother(Index, EncoderInc, .1) ~= 0 then
        local Value = EncoderInc > 0 and 1 or -1
        if Index == 1 then
            local Group = NI.DATA.StateHelper.getFocusGroup(App)
            if Group then
                NI.DATA.GroupAccess.shiftSoundFocus(App, Group, Value, false, false)
            end
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper.onUpdate(Page)

    local StateCache = App:getStateCache()
    if NI.DATA.ParameterCache.isValid(App) and (StateCache:isFocusGroupChanged() or StateCache:isGroupsChanged()) then
        GroupBank = math.floor(NI.DATA.StateHelper.getFocusGroupIndex(App) / 8)
    end

    Page.GroupVector:setItemOffset(GroupBank * 8)
    Page.GroupVector:setAlign()
end

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper.updateLEDs()

    LEDHelper.updateButtonLED(ControllerScriptInterface, NI.HW.LED_LEFT, NI.HW.BUTTON_LEFT, GroupBank > 0)
    LEDHelper.updateButtonLED(ControllerScriptInterface, NI.HW.LED_RIGHT, NI.HW.BUTTON_RIGHT,
        GroupBank < MaschineHelper.getNumFocusSongGroupBanks(true) - 1)

    LEDHelper.updateButtonLED(ControllerScriptInterface, NI.HW.LED_CLEAR, NI.HW.BUTTON_CLEAR,
        NI.DATA.StateHelper.getFocusGroup(App) ~= nil)

    local FocusGroup = ScenePatternHelper.isIdeaSpace() and NI.DATA.StateHelper.getFocusGroup(App) or nil

    local GroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App) + 1
    local CanLeft = GroupIndex > 1
    local CanRight = GroupIndex < MaschineHelper.getFocusSongGroupCount()

    LEDHelper.updateButtonLED(ControllerScriptInterface, NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.BUTTON_WHEEL_LEFT, CanLeft)
    LEDHelper.updateButtonLED(ControllerScriptInterface, NI.HW.LED_WHEEL_BUTTON_RIGHT, NI.HW.BUTTON_WHEEL_RIGHT, CanRight)

end

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper.getButtonData(Index)

    local Data = {}
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil
    local FocusGroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)
    local GroupIndex = Index + GroupBank * 8

    local Group = Groups and Groups:at(GroupIndex - 1)

    Data.Color = Group and Group:getColorParameter():getValue() or nil

    Data.Enabled = true
    Data.Visible = Group ~= nil or GroupIndex == Groups:size() + 1
    Data.Selected = GroupIndex == (FocusGroupIndex + 1)

    return Data

end

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper.onLeftRightButton(Right, Pressed)

    if Pressed then
        GroupBank = math.bound(GroupBank + (Right and 1 or -1), 0, MaschineHelper.getNumFocusSongGroupBanks(true) - 1)
    end
end

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper.onScreenButton(Index, Pressed)

    MaschineHelper.setFocusGroup(GroupBank * 8 + Index, true)

end

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper.getScreenEncoderInfo(Index)

    local Info = {}
    Info.SpeechSectionName = ""
    Info.SpeechName = ""
    Info.SpeechValue = ""
    Info.SpeakNameInNormalMode = true
    Info.SpeakValueInNormalMode = true
    Info.SpeakNameInTrainingMode = true
    Info.SpeakValueInTrainingMode = true

    if Index == 1 then
        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        if Sound then
            Info.SpeechSectionName = "Sound,"
            Info.SpeechName = "Select"
            Info.SpeechValue = Sound:getDisplayName()
        end
    end

    return Info

end

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper.getScreenButtonInfo(Index)
    local Info = {}

    Info.SpeechSectionName = ""
    Info.SpeechName = ""
    Info.SpeechValue = ""
    Info.SpeakNameInNormalMode = true
    Info.SpeakValueInNormalMode = false
    Info.SpeakNameInTrainingMode = true
    Info.SpeakValueInTrainingMode = true

    local GroupIndex = GroupBank * 8 + Index - 1
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups()
    local Group = Groups and Groups:at(GroupIndex)

    if Group then
        Info.SpeechName = AccessibilityTextHelper.getGroupName(Group:getDisplayName())
        Info.SpeechValue = (Index == NI.DATA.StateHelper.getFocusGroupIndex(App) + 1) and "On" or "Off"
    elseif GroupIndex == Groups:size() then
        Info.SpeechName = "Create Group"
        Info.SpeechValue = nil
    end

    return Info

end

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper.getCurrentPageSpeechAssistanceMessage(Right)
    local DirectionString = Right and "Right" or "Left"
    local Msg = DirectionString

    local GroupIndex = GroupBank * 8
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups()
    local Group = Groups and Groups:at(GroupIndex)

    if Group then
        Msg = Msg .. " to " .. AccessibilityTextHelper.getGroupName(Group:getDisplayName())
    end

    return Msg
end

------------------------------------------------------------------------------------------------------------------------

function GroupOverlayHelper:getWheelDirectionInfo(Direction)

    local DirectionNames = {
        [NI.HW.BUTTON_WHEEL_UP] = nil,
        [NI.HW.BUTTON_WHEEL_DOWN] = nil,
        [NI.HW.BUTTON_WHEEL_LEFT] = "Previus Group",
        [NI.HW.BUTTON_WHEEL_RIGHT] = "Next Group"
    }

    local Info = {}
    Info.TrainingMode = DirectionNames[Direction]

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups()
    local GroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)
    local Group = Groups and Groups:at(GroupIndex)
    Info.NormalMode =  Groups and AccessibilityTextHelper.getGroupName(Group:getDisplayName()) or ""
    return Info

end
