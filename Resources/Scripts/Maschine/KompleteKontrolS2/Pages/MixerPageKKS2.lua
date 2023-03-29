------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/MixerPageColorDisplayBase"


------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MixerPageKKS2 = class( 'MixerPageKKS2', MixerPageColorDisplayBase )

------------------------------------------------------------------------------------------------------------------------

function MixerPageKKS2:__init(Controller)

    MixerPageColorDisplayBase.__init(self, "MixerPageStudio", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageKKS2:updateWheelButtonLEDs()

    local HasGroup = NI.DATA.StateHelper.getFocusGroup(App)
    local CanGroup = HasGroup and self:isShowingSounds()
    local CanSound = not self:isShowingSounds() and not self.PlusSignInFocus
    local CanLeft, CanRight = self:canFocusPrevNextObject(true)

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.BUTTON_WHEEL_LEFT, CanLeft)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_RIGHT, NI.HW.BUTTON_WHEEL_RIGHT, CanRight)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_UP, NI.HW.BUTTON_WHEEL_UP, CanGroup)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_DOWN, NI.HW.BUTTON_WHEEL_DOWN, CanSound)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageKKS2:onWheel(Inc)

    local Fine = self.Controller:getShiftPressed()
    local Index = self:isShowingSounds() and NI.DATA.StateHelper.getFocusSoundIndex(App) + 1
        or NI.DATA.StateHelper.getFocusGroupIndex(App) + 1

    self:onLevelChange(Index, Inc, Fine, true)

    self.Controller.SpeechAssist:onEncoderEvent(Index, true)

    return true

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageKKS2:onWheelDirection(Pressed, Button)

    if Pressed then

        if Button == NI.HW.BUTTON_WHEEL_LEFT or Button == NI.HW.BUTTON_WHEEL_RIGHT then
            self:focusPrevNextObject(Button == NI.HW.BUTTON_WHEEL_RIGHT)

        elseif Button == NI.HW.BUTTON_WHEEL_UP then
            MaschineHelper.setGroupFocus()

        elseif not self:isShowingSounds() and not self.PlusSignInFocus then
            MaschineHelper.setSoundFocus()
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageKKS2:updateLEDs()

    LEDHelper.setLEDState(NI.HW.LED_CLEAR, LEDHelper.LS_OFF)

    MixerPageColorDisplayBase.updateLEDs(self)
end

------------------------------------------------------------------------------------------------------------------------

function MixerPageKKS2:updateScreenButtonLEDs()

    if self.Controller.ActiveOverlay and self.Controller.ActiveOverlay:isVisible() then
        return
    end

    MixerPageColorDisplayBase.updateScreenButtonLEDs(self)
end

------------------------------------------------------------------------------------------------------------------------

function MixerPageKKS2:onScreenButton(Index, Pressed)

    MixerPageColorDisplayBase.onScreenButton(self, Index, Pressed)
    self.Controller.SpeechAssist:onScreenButton(Index, self, false)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageKKS2:onScreenEncoder(Index, EncoderInc)

    if not self.Controller.SpeechAssist:isTrainingMode() then
        MixerPageColorDisplayBase.onScreenEncoder(self, Index, EncoderInc)
    end

    self.Controller.SpeechAssist:onEncoderEvent(Index, true)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageKKS2:getScreenButtonInfo(Index)

    local Info = {}
    Info.SpeechSectionName = ""
    Info.SpeechName = ""
    Info.SpeechValue = ""
    Info.SpeakNameInNormalMode = true
    Info.SpeakValueInNormalMode = true
    Info.SpeakNameInTrainingMode = true
    Info.SpeakValueInTrainingMode = true


    local Offset = self:getFocusVector():getOffset()
    local Objects = self:getFocusObjects()
    local ItemIndex = Offset + Index - 1
    -- No easy way to determine if we're on a + button
    local IsOnGroupAddButton = not self:isShowingSounds() and ItemIndex == Objects:size()

    if Objects then
        local Object = Objects:at(ItemIndex)
        if Object then
            if self:isShowingSounds() then
                Info.SpeechName = AccessibilityTextHelper.getSoundName(Object:getDisplayName())
            else
                Info.SpeechName = AccessibilityTextHelper.getGroupName(Object:getDisplayName())
            end
        elseif IsOnGroupAddButton then
             Info.SpeechName = "Create Group"
        end
    end

    if self.Controller.SwitchPressed[NI.HW.BUTTON_MUTE] then
        Info.SpeechName = "Mute " .. Info.SpeechName
    elseif self.Controller.SwitchPressed[NI.HW.BUTTON_SOLO] then
        Info.SpeechName = "Solo " .. Info.SpeechName
    end

    return Info
end

------------------------------------------------------------------------------------------------------------------------

function MixerPageKKS2:getSoundOrGroup(Index)
    local Offset = self:getFocusVector():getOffset()
    local ItemIndex = Offset + Index - 1

    local FocusedItem = nil

    if self:isShowingSounds() then
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        if Group then
            FocusedItem = Group:getSounds():at(ItemIndex) or nil
        end
    else
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        if Song then
            FocusedItem = Song:getGroups():at(ItemIndex) or nil
        end
    end

    return FocusedItem
end

------------------------------------------------------------------------------------------------------------------------

function MixerPageKKS2:getScreenEncoderInfo(Index)

    local Info = {}
    Info.SpeechSectionName = ""
    Info.SpeechName = ""
    Info.SpeechValue = ""
    Info.SpeakNameInNormalMode = false
    Info.SpeakValueInNormalMode = true
    Info.SpeakNameInTrainingMode = true
    Info.SpeakValueInTrainingMode = true

    local Offset = self:getFocusVector():getOffset()
    local ItemIndex = Offset + Index - 1

    local FocusedItem = self:getSoundOrGroup(Index)

    if FocusedItem then
        if  self:isShowingSounds() then
            Info.SpeechName = AccessibilityTextHelper.getSoundName(FocusedItem:getDisplayName())
        else
            Info.SpeechName = AccessibilityTextHelper.getGroupName(FocusedItem:getDisplayName())
        end

        Info.SpeechName = Info.SpeechName
                            .. " " .. (self.EncoderMode == MixerVector.MODE_VOLUME and "Volume" or "Pan")

        if self.EncoderMode == MixerVector.MODE_VOLUME then
            Info.SpeechValue = NI.UTILS.LevelScale.level2ValueString(FocusedItem:getLevelParameter():getValue())
        else
            Info.SpeechValue = FocusedItem:getPanParameter():getAsString(FocusedItem:getPanParameter():getValue()):lower()
            Info.SpeechValue = AccessibilityTextHelper.replaceWord(Info.SpeechValue, "L", "Left")
            Info.SpeechValue = AccessibilityTextHelper.replaceWord(Info.SpeechValue, "R", "Right")
            Info.SpeechValue = AccessibilityTextHelper.replaceWord(Info.SpeechValue, "C", "Center")
        end
    end

    return Info

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageKKS2:getMsgForItem(Index)
    local ItemIndex = self.ItemOffset + Index
    local Msg = nil

    if self:isShowingSounds() then
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        if Group then
            local Sound = Group:getSounds():at(ItemIndex) or nil
            if Sound then
                Msg = Sound:getDisplayName()
            end
        end
    else
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        if Song then
            local Group = Song:getGroups():at(ItemIndex) or nil
            if Group then
                Msg = Group:getDisplayName()
            end
        end
    end

    return Msg
end

------------------------------------------------------------------------------------------------------------------------

function MixerPageKKS2:getCurrentPageSpeechAssistanceMessage(Right)

    return  Right and "Page Right" or "Page Left"

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageKKS2:focusedItemInfo()
    local Info = {}
    Info.SpeechSectionName = ""
    Info.SpeechName = ""
    Info.SpeechValue = ""
    Info.SpeakNameInNormalMode = false
    Info.SpeakValueInNormalMode = true
    Info.SpeakNameInTrainingMode = true
    Info.SpeakValueInTrainingMode = true

    Info.SpeechName = self:getMsgForItem(self.LastFocusIndex - 1)

    return Info
end

------------------------------------------------------------------------------------------------------------------------

function MixerPageKKS2:getWheelDirectionInfo(Direction)

    local DirectionNames = {
        [NI.HW.BUTTON_WHEEL_UP] = "Group Mode",
        [NI.HW.BUTTON_WHEEL_DOWN] = "Sound Mode",
        [NI.HW.BUTTON_WHEEL_LEFT] = "Previous Slot",
        [NI.HW.BUTTON_WHEEL_RIGHT] = "Next Slot"
    }
    local Msg = DirectionNames[Direction]

    local Info = {}
    Info.TrainingMode = Msg
    Info.NormalMode = Msg
    return Info

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageKKS2:getWheelPushInfoString()

    return self.EncoderMode == MixerVector.MODE_VOLUME and "Volume" or "Pan"

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageKKS2:updateScreens(ForceUpdate)

    MixerPageColorDisplayBase.updateScreens(self, ForceUpdate)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Msg = ""
    if self:isShowingSounds() then
        local Sounds = Group and Group:getSounds()
        if Sounds and Sounds:isSelectionChanged() then
            local Sound = Sounds:getFocusObject()
            Msg = AccessibilityTextHelper.getSoundName(Sound:getDisplayName())
        end
    else
        local Groups = Song and Song:getGroups()
        if Groups and Groups:isSelectionChanged() then
            Msg = AccessibilityTextHelper.getGroupName(Group:getDisplayName())
        end
    end
    self.Controller.SpeechAssist:scheduleMessage(Msg, "")

end