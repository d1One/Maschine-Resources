------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/BrowseHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Components/ScreenMixerStudio"
require "Scripts/Maschine/Components/MixerVector"
require "Scripts/Shared/Helpers/PadModeHelper"

local ATTR_IS_CLIPPING = NI.UTILS.Symbol("IsClipping")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MixerPageColorDisplayBase = class( 'MixerPageColorDisplayBase', PageMaschine )

MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_NONE = 0
MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_MUTE = 1
MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_SOLO = 2

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:__init(Name, Controller)

    PageMaschine.__init(self, Name, Controller)

    self.PageLEDs = { NI.HW.LED_MIX }

    -- setup screen
    self:setupScreen()
    self.EncoderMode = MixerVector.MODE_VOLUME

    self.LevelsRefresh = true
    self.ScreenButtonMode = MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_NONE
    self.Source = -1
    self.PlusSignInFocus = false
    self.ItemOffset = 0
    self.LastFocusIndex = self:getFocusIndex()

    -- accessibility
    self.RefreshAccessibleButtonInfoRequest = false

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:setupScreen()

    self.Screen = ScreenMixerStudio(self)

    self.EmptyFunc = function(MixerBar) end
    self.SoundSizeFunc = function() return 16 end

    self.GroupVector = MixerVector(self, "GroupVector", MixerPageColorDisplayBase.GroupSizeFunc, self.EmptyFunc, MixerPageColorDisplayBase.GroupItemStateFunc )
    self.SoundVector = MixerVector(self, "SoundVector", self.SoundSizeFunc, self.EmptyFunc, MixerPageColorDisplayBase.SoundItemStateFunc )

    self.Screen.RootBar:setFlex(self.GroupVector.Vector)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase.GroupSizeFunc()

    local NumGroupPages = MaschineHelper.getNumFocusSongGroupBanks(true)
    return NumGroupPages * 8

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:setPrevNextBank(Next)
    local Vector = self:getFocusVector()
    local Offset = Vector:getOffset() + (Next and 8 or -8)
    self.ItemOffset = math.max(Offset, 0)
    Vector:setOffset(self.ItemOffset)

    self:updateLevels(true)
end

------------------------------------------------------------------------------------------------------------------------

local function updateSlotsActiveState(State, Object)

    if Object then
        State.SlotActive = {}

        for Index = 0, 6 do
            if Index >= State.NumSlots then break end

            local Slot = Object:getChain():getSlots():at(Index)
            if Slot then
                State.SlotActive[Index] = Slot:getActiveParameter():getValue()
            end
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:GroupItemStateFunc(Index)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups()
    local Group = Groups and Groups:at(Index)

    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)

    local State = {}

    local IsShowingSounds = self:isShowingSounds()
    State.SeparatorColor = IsShowingSounds and FocusGroup and FocusGroup:getColorParameter():getValue()+1 or nil

    if Group then

        State.Visible = true
        State.ControlsVisible = true
        State.Color = Group:getColorParameter():getValue()+1
        State.NameShort = NI.DATA.Group.getLabel(Index)
        State.NameLong = Group:getDisplayName()
        State.Focused = Index == NI.DATA.StateHelper.getFocusGroupIndex(App) and not self.PlusSignInFocus
        State.Selected = (State.Focused or Groups:isInSelection(Group)) and not self.PlusSignInFocus
        State.Mode = self.EncoderMode
        State.Muted = Group:getMuteParameter():getValue()
        State.Cue = Group:getCueEnabledParameter():getValue()
        State.Volume = Group:getLevelParameter()
        State.Pan = Group:getPanParameter()
        State.Refresh = self.LevelsRefresh
        State.GeneratorType = MixerVector.GENERATOR_TYPE_EFFECT
        State.NumSlots = Group:getChain():getSlots():size()
        State.SoundsVisible = IsShowingSounds

        updateSlotsActiveState(State, Group)

    -- The + Button
    elseif Index == Groups:size() then

        State.Visible = true
        State.ControlsVisible = false
        State.Color = 0
        State.IsAdd = true
        State.NameShort = ""
        State.NameLong = ""
        State.Focused = self.PlusSignInFocus
        State.Selected = (FocusGroup == nil or self.PlusSignInFocus)

    else

        State.Visible = false
    end

    return State
end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:SoundItemStateFunc(Index)

    local StateCache = App:getStateCache()
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sounds = Group and Group:getSounds()
    local Sound = Sounds and Sounds:at(Index)

    if not Sound then
        return
    end

    local IsSoundEnabled = StateCache:getObjectCache():isSoundEnabled(Sound)

    local State = {}

    State.Visible = true
    State.ControlsVisible = true
    State.Color = Sound:getColorParameter():getValue()+1
    State.NameShort = tostring(Index+1)
    State.NameLong = IsSoundEnabled and Sound:getDisplayName() or ""
    State.Focused = Index == NI.DATA.StateHelper.getFocusSoundIndex(App) and MaschineHelper.hasSoundFocus()
    State.Selected = State.Focused or Sounds:isInSelection(Sound)
    State.Mode = self.EncoderMode
    State.Muted = Sound:getMuteParameter():getValue()
    State.Cue = Sound:getCueEnabledParameter():getValue()
    State.Volume = Sound:getLevelParameter()
    State.Pan = Sound:getPanParameter()
    State.Refresh = self.LevelsRefresh
    State.GeneratorType = MixerPageColorDisplayBase.getGeneratorType(Sound)
    State.NumSlots = Sound:getChain():getSlots():size()
    State.SoundsVisible = self:isShowingSounds()

    updateSlotsActiveState(State, Sound)

    return State

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:onShow(Show)

    -- call base class
    PageMaschine.onShow(self, Show)

    if Show then
        self.Controller:setTimer(self, 1)
        self.ScreenButtonMode = MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_NONE
        self.Source = -1
        self.PlusSignInFocus = false
    else
        -- reset all used LEDs
        LEDHelper.resetButtonLED(NI.HW.LED_MUTE)
        LEDHelper.resetButtonLED(NI.HW.LED_SOLO)
        LEDHelper.resetButtonLED(NI.HW.LED_LEFT)
        LEDHelper.resetButtonLED(NI.HW.LED_RIGHT)
        LEDHelper.resetButtonLED(NI.HW.LED_LEFT)
        LEDHelper.resetButtonLED(NI.HW.LED_RIGHT)
    end
end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:updateScreens(ForceUpdate)

    local StateCache = App:getStateCache()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups()
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sounds = Group and Group:getSounds()
    local Sound = Sounds and Sounds:getFocusObject()

    if not Song then
        return
    end

    if NI.DATA.ParameterCache.isValid(App)
        and (StateCache:isFocusGroupChanged()
        or StateCache:isGroupsChanged()) then
        self.PlusSignInFocus = false
    end

    -- levels update check
    if ForceUpdate or NI.DATA.ParameterCache.isValid(App)
        and (StateCache:isFocusGroupChanged()
        or StateCache:isGroupsChanged()
        or Song:getSoundsVisibleMixerParameter():isChanged()
        or StateCache:isFocusSoundChanged()
        or StateCache:isMixingLayerChanged()) then

        self.SoundVector.Vector:setActive(self:isShowingSounds())
        self:updateVectorsFocusPage()
        self:updateLevels(true)

    else
        self.LevelsRefresh = false
    end

    -- check groups mute and color state
    local ParamChanged = false
    for Index = 0, Groups:size() do
        local Group = Groups:at(Index) or nil

        if Group and (
            Group:getMuteParameter():isChanged()
            or Group:getColorParameter():isChanged()) then
            ParamChanged = true
            break
        end
    end

    -- check focus objects state
    local Objects = self:getFocusObjects()
    local NumObjects = Objects and Objects:size() or 0

    for Index = 0, NumObjects do
        local Object = Objects and Objects:at(Index) or nil
        local Slot1 = Object and Object:getChain():getSlots():at(0)

        if not ParamChanged and Object and (Object:getPanParameter():isChanged()
            or Object:getNameParameter():isChanged()
            or Object:getColorParameter():isChanged()
            or Object:getLevelParameter():isChanged()
            or Object:getCueEnabledParameter():isChanged()
            or Object:getMuteParameter():isChanged()
            or Object:getChain():isChanged()
            or Object:getChain():isAnySlotChanged()
            or (Slot1 and Slot1:isModuleChanged())) then
            ParamChanged = true
            break
        end

    end

    -- final check if vectors refresh is needed
    local FocusPattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local FocusSound = FocusPattern and NI.DATA.StateHelper.getFocusSound(App)
    local NeedsAlign = FocusSound and FocusPattern:isSoundSequenceChanged(FocusSound)
                        or (FocusSound and FocusSound:getSequences():isSizeChanged())

    if ForceUpdate or StateCache:isMixingLayerChanged()
        or StateCache:isFocusGroupChanged()
        or StateCache:isFocusSoundChanged()
        or (Group and Group:getNameParameter():isChanged())
        or (Groups and Groups:isSelectionChanged())
        or (Sounds and Sounds:isSelectionChanged())
        or NeedsAlign
        or ParamChanged then

        self.GroupVector:setAlign()
        self.SoundVector:setAlign()
    end

    -- accessibility
    self:refreshAccessibleButtonInfo()
    self:refreshAccessibleEncoderInfo()

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:updateGroupLEDs()

    if self.ScreenButtonMode == MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_MUTE or
       self.ScreenButtonMode == MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_SOLO then

        LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS,
            self.Screen.GroupBank * 8,
            MuteSoloHelper.getGroupMuteByIndexLEDStates,
            MaschineHelper.getGroupColorByIndex)

    else

        PageMaschine.updateGroupLEDs(self)

    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:updatePadLEDs()

    if self.ScreenButtonMode == MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_MUTE or
       self.ScreenButtonMode == MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_SOLO then

    -- update sound leds with focus state
    LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_LEDS, 0,
        function(Index) return MuteSoloHelper.getSoundMuteByIndexLEDStates(Index, false) end,
        MaschineHelper.getSoundColorByIndex,
        MaschineHelper.getFlashStateSoundsNoteOn)

    else

        PageMaschine.updatePadLEDs(self)

    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:onTimer()

    if not self.IsVisible then
        return
    end

    self:updateLevels()

    self:updateLEDs()
    self:updateHWLevelSource()

    -- updates the group leds status
    self.Screen.GroupBank = math.floor(self.GroupVector.Vector:getItemOffset() / 8)

    self.Controller:setTimer(self, 1)

    if self.RefreshAccessibleButtonInfoRequest and not self:getFocusVector():isMoving() then
        self.RefreshAccessibleButtonInfoRequest = false
        self:refreshAccessibleButtonInfo()
        self:refreshAccessibleEncoderInfo()
    end

    PageMaschine.onTimer(self)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:updateLevels(ForceReset)

    local Objects = self:getFocusObjects()
    local Vector = self:getFocusVector()
    local Offset = Vector:getOffset()

    for Index = 1, 8 do

        local Object = Objects and Objects:at(Index + Offset - 1) or nil
        local MixerBar = Vector:getAt(Index + Offset - 1)

        if MixerBar and MixerBar:getHeader():isVisible() then

            if Object then

                if ForceReset or Vector:isMoving() then

                    MixerBar:getLeftMeter():resetPeak()
                    MixerBar:getRightMeter():resetPeak()
                    MixerBar:getLeftMeter():setValue(0)
                    MixerBar:getRightMeter():setValue(0)
                else
                    -- LevelMeterRange -60dB .. 10dB
                    local Left = NI.UTILS.LevelScale.amplitudeScaling2LevelApprox(Object:getLevel(0), .001)
                    local Right = NI.UTILS.LevelScale.amplitudeScaling2LevelApprox(Object:getLevel(1), .001)
                    MixerBar:getLeftMeter():setValue(math.max(Left, 0) * 1000)
                    MixerBar:getRightMeter():setValue(math.max(Right, 0) * 1000)
                end

                local HeadroomIndB = NI.UTILS.LevelScale.convertLevelTodB(Object:getHeadRoom(), -60, 10)
                MixerBar:getHeadRoom():setText(NI.UTILS.LevelScale.dBValueToString(HeadroomIndB, -60))

                local IsClipping = HeadroomIndB > 0
                if IsClipping ~= MixerBar:getIsClipping() then
                    MixerBar:setAttribute(ATTR_IS_CLIPPING, IsClipping and "true" or "false")
                    MixerBar:setIsClipping(IsClipping)
                end
            end
        end
    end
end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:onLeftRightButton(Right, Pressed)

    self:updateLEDs()

    if Pressed then
        self:setPrevNextBank(Right)
    end

    -- accessibility
    self.RefreshAccessibleButtonInfoRequest = true

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:onPrevNextButton(Pressed, Right)

    if Pressed then
        self.EncoderMode = self.EncoderMode == MixerVector.MODE_VOLUME and MixerVector.MODE_PAN or MixerVector.MODE_VOLUME
        self:getFocusVector():setAlign()

        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:onWheel(Inc)

    return false

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:onLevelChange(Index, EncoderInc, Fine, ViaWheel)

    local Param = self:getLevelParameter(Index)

    if Param and not self.PlusSignInFocus then
        if ViaWheel then
            NI.DATA.ParameterAccess.addLevelPanWheelDelta(App, Param, EncoderInc, Fine, NHLController:getControllerModel())
        else
            NI.DATA.ParameterAccess.addLevelPanEncoderDelta(App, Param, EncoderInc, Fine)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:onWheelButton(Pressed)

    if not Pressed then
        return
    end

    if not self.PlusSignInFocus then
        self:toggleMixerEncoderMode()
        self:getFocusVector():setAlign()
    else
        self:createAndFocusGroup()
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:onScreenEncoder(Index, EncoderInc)

    local Vector = self:getFocusVector()

    local Fine = self.Controller:getShiftPressed()
	self:onLevelChange(Index + Vector:getOffset(), EncoderInc, Fine)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:toggleMixerEncoderMode()

    self.PlusSignInFocus = false
    self.EncoderMode = self.EncoderMode == MixerVector.MODE_VOLUME and MixerVector.MODE_PAN or MixerVector.MODE_VOLUME
    NHLController:addAccessibilityControlData(NI.HW.ZONE_SCREENINFO, 0, NI.HW.LAYER_SHIFTED, 0, 0,
                                              self.EncoderMode == MixerVector.MODE_VOLUME and "Volume" or "Pan")
    NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_SCREENINFO, 0)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:createAndFocusGroup()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil

    if Groups then
        self.PlusSignInFocus = false
        MaschineHelper.setFocusGroup(Groups:size() + 1, true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:focusObjectAtIndex(Index, IncludeNewGroup) -- 1-indexed
    self.LastFocusIndex = Index

    if self:isShowingSounds() then
        MaschineHelper.setFocusSound(Index)
        if not MaschineHelper.hasSoundFocus() then
            MaschineHelper.setSoundFocus()
        end
    else
        MaschineHelper.setFocusGroup(Index, IncludeNewGroup)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:canFocusPrevNextObject(FocusNewGroup)

    local Objects = self:getFocusObjects()
    local Object = Objects and Objects:getFocusObject()

    if not Object then
        return false, false
    end

    local Index = Objects:calcIndex(Object)
    local CanLeft = Index > 0 or self.PlusSignInFocus

    local ObjectSizeDelta = (self:isShowingSounds() or not FocusNewGroup or self.PlusSignInFocus) and 1 or 0
    local CanRight = Index < (Objects:size() - ObjectSizeDelta)

    return CanLeft, CanRight

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:getFocusIndex()
    local Index = nil
    local Objects = self:getFocusObjects()
    local Object = Objects and Objects:getFocusObject()

    if Object then
        Index = Objects:calcIndex(Object)
    end

    return Index
end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:focusPrevNextObject(Next)
    local Index = self:getFocusIndex()
    if Index then
        Index = Index + (Next and 1 or -1) + 1

        if not self.PlusSignInFocus then
            self:focusObjectAtIndex(Index, false)
        end

        local Objects = self:getFocusObjects()
        self.PlusSignInFocus = not self:isShowingSounds() and Index == Objects and Objects:size()+1

        self:updateScreens(true)
    end
end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:focusGroupOrSound(FocusGroup)

    if not self.PlusSignInFocus then
        if FocusGroup then
            MaschineHelper.setGroupFocus()
        elseif not self:isShowingSounds() then
            MaschineHelper.setSoundFocus()
        end
        NHLController:addAccessibilityControlData(NI.HW.ZONE_SCREENINFO, 0, 0, 0, 0,
                                                  FocusGroup and "Groups focused" or "Sounds focused");
        NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_SCREENINFO, 0);
    end
    self.LastFocusIndex = self:getFocusIndex()

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:onScreenButton(Index, Pressed)

    if not Pressed then
        return
    end

    self.PlusSignInFocus = false

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    local Objects = self:getFocusObjects()
    local Vector = self:getFocusVector()

    Index = Index + Vector:getOffset()
    local Object = Objects and Objects:at(Index-1)

    if self.ScreenButtonMode == MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_NONE then

        local ObjectsCount = Objects and Objects:size()+1 or 1

        -- the + Button
        if not self:isShowingSounds() and Song and Index == ObjectsCount then
            NI.DATA.SongAccess.createGroup(App, Song, false)
            return
        end

        if Object then
            self:focusObjectAtIndex(Index, true)
        end

    elseif Object and self.ScreenButtonMode == MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_MUTE then
        NI.DATA.ParameterAccess.setBoolParameter(App, Object:getMuteParameter(),
            not Object:getMuteParameter():getValue())

    elseif Object and self.ScreenButtonMode == MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_SOLO then
        if self:isShowingSounds() then
            MuteSoloHelper.toggleSoundSoloState(Index)
        else
            MuteSoloHelper.toggleGroupSoloState(Index)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:isShowingSounds()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local GroupValid = NI.DATA.StateHelper.getFocusGroup(App) ~= nil

    return (MaschineHelper.hasSoundFocus() or Song:getSoundsVisibleMixerParameter():getValue()) and GroupValid

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:updateVectorsFocusPage()

    local Index = NI.DATA.StateHelper.getFocusGroupIndex(App) + (self.PlusSignInFocus and 1 or 0)
    self.LevelsRefresh = self.GroupVector:focusOnItem(Index)

    if self:isShowingSounds() then
        self.LevelsRefresh = self.SoundVector:focusOnItem(NI.DATA.StateHelper.getFocusSoundIndex(App)) or self.LevelsRefresh
    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:updateLEDs()

    self:updateScreenButtonLEDs()

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_MUTE, NI.HW.BUTTON_MUTE, true)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_SOLO, NI.HW.BUTTON_SOLO, true)

    local Page = math.floor(self:getFocusVector():getOffset() / 8)
    local NumPages = math.floor(self:getFocusVector().SizeFunc() / 8)

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_LEFT, NI.HW.BUTTON_LEFT, Page > 0)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_RIGHT, NI.HW.BUTTON_RIGHT, Page < NumPages-1)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:updateScreenButtonLEDs()

    local Objects = self:getFocusObjects()
    local Vector = self:getFocusVector()
    local Offset = Vector:getOffset()

    for Index = 1, 8 do

        local Object = Objects and Objects:at(Index + Offset - 1) or nil
        local FocusObject = Objects:getFocusObject()
        local MixerBar = Vector:getAt(Index + Offset - 1)
        local AddGroup = not self:isShowingSounds() and (Index + Offset == Objects:size() + 1)

        if Object or AddGroup then
            local ColorIndex = Object and Object:getColorParameter():getValue()
            local Selected = false

            if self.ScreenButtonMode == MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_NONE then
                Selected = FocusObject == Object or self.Controller.SwitchPressed[self.Controller.SCREEN_BUTTONS[Index]]
            elseif Object then
                Selected = not Object:getMuteParameter():getValue()
            end

            LEDHelper.setLEDState(self.Controller.SCREEN_BUTTON_LEDS[Index], Selected and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM, ColorIndex)
        else
            LEDHelper.setLEDState(self.Controller.SCREEN_BUTTON_LEDS[Index], LEDHelper.LS_OFF)
        end
    end
end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:onPageButton(Button, PageID, Pressed)

    if Button == NI.HW.BUTTON_MUTE or Button == NI.HW.BUTTON_SOLO then
        if Pressed then
            if not (Button == NI.HW.BUTTON_MUTE and self.Controller:getShiftPressed()) then  -- not CHOKE
                self.ScreenButtonMode = Button == NI.HW.BUTTON_MUTE
                    and MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_MUTE
                    or MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_SOLO
                self:refreshAccessibleButtonInfo()
                return true
            end
        else
            self.ScreenButtonMode = MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_NONE
        end

        self:refreshAccessibleButtonInfo()
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:onPadEvent(PadIndex, Trigger, PadValue)

    if self.ScreenButtonMode == MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_NONE then

	    -- covers a case where the view is not updated when hitting the focus sound
	    if Trigger and self:isShowingSounds() then

	    	if PadIndex == NI.DATA.StateHelper.getFocusSoundIndex(App) + 1 then
			    self:updateVectorsFocusPage()
			end

		    if not MaschineHelper.hasSoundFocus() then
	            MaschineHelper.setSoundFocus()
	        end
		end

        return PageMaschine.onPadEvent(self, PadIndex, Trigger, PadValue)
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sound = Group and Group:getSounds():at(PadIndex-1)

    if Trigger and Sound then
        if self.ScreenButtonMode == MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_MUTE then
            NI.DATA.ParameterAccess.setBoolParameter(App, Sound:getMuteParameter(),
                not Sound:getMuteParameter():getValue())

        elseif self.ScreenButtonMode == MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_SOLO then
            MuteSoloHelper.toggleSoundSoloState(PadIndex)

        end
    end
end


------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:onGroupButton(Index, Pressed)

    if self.ScreenButtonMode == MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_NONE then

        local ForceUpdate = self.PlusSignInFocus or self.Controller:getShiftPressed()
        self.PlusSignInFocus = false

        PageMaschine.onGroupButton(self, Index, Pressed)
       	if Pressed then
		    self:updateScreens(ForceUpdate)
		end
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = Song and Song:getGroups():at(Index-1 + self.GroupVector:getOffset())

    if Pressed and Group then
        if self.ScreenButtonMode == MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_MUTE then
            NI.DATA.ParameterAccess.setBoolParameter(App, Group:getMuteParameter(),
                not Group:getMuteParameter():getValue())

        elseif self.ScreenButtonMode == MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_SOLO then
            MuteSoloHelper.toggleGroupSoloState(Index + self.GroupVector:getOffset())

        end
    end

end


------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:onEnterButton(Pressed)

    self:updateLEDs()

    if Pressed and not self:isShowingSounds() then
        MaschineHelper.setSoundFocus()
    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:onBackButton(Pressed)

    self:updateLEDs()

    if Pressed then
        MaschineHelper.setGroupFocus()
    end
end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:getFocusObjects()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    return self:isShowingSounds() and (Group and Group:getSounds() or nil) or (Song and Song:getGroups() or nil)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:getName(Index)

    local Objects = self:getFocusObjects()
    local Object = Objects and Objects:at(Index - 1) or nil

    if not Object then
        return ""
    end

    return Object:getDisplayName()

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:getLevelParameter(Index)

    local Objects = self:getFocusObjects()
    local Object = Objects and Objects:at(Index - 1) or nil

    if not Object then
        return nil
    end

    return self.EncoderMode == MixerVector.MODE_VOLUME and Object:getLevelParameter() or Object:getPanParameter()

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:getFocusVector()

    return self:isShowingSounds() and self.SoundVector or self.GroupVector
end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:updateHWLevelSource()

    local SourceParameter = App:getWorkspace():getHWLevelMeterSourceParameter()
    local Source = self:isShowingSounds() and NI.DATA.LEVEL_SOURCE_GROUP or NI.DATA.LEVEL_SOURCE_MASTERCUE

    if Source ~= self.Source then
        self.Source = Source
        NI.DATA.ParameterAccess.setSizeTParameter(App, SourceParameter, Source)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:updateJogwheel()
end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase.getGeneratorType(Sound)

    local Slot1 = Sound and Sound:getChain():getSlots():at(0)
    local Module = Slot1 and Slot1:getModule()
    local ModuleInfo = Module and Module:getInfo()

    if ModuleInfo and ModuleInfo:getType() == NI.DATA.ModuleInfo.TYPE_INSTRUMENT then
        return ModuleInfo:getId() == NI.DATA.ModuleInfo.ID_AUDIO
            and MixerVector.GENERATOR_TYPE_AUDIO
            or MixerVector.GENERATOR_TYPE_INSTRUMENT
    else
        return MixerVector.GENERATOR_TYPE_EFFECT
    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:getAccessibleTextByButtonIndex(ButtonIdx)

    if not self.Controller:getShiftPressed() then
        local Objects = self:getFocusObjects()
        local Vector = self:getFocusVector()
    
        ObjectIndex = ButtonIdx + Vector:getOffset()
        local Object = Objects and Objects:at(ObjectIndex - 1)

        if self.ScreenButtonMode == MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_NONE then
            -- the + Button
            if not self:isShowingSounds() and ObjectIndex == Objects:size() + 1 then
                return "Create Group"
            end
    
            return self:getName(ObjectIndex)

        elseif Object and self.ScreenButtonMode == MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_MUTE then
            local AlreadyMuted = Object:getMuteParameter():getValue()
            return (AlreadyMuted and "Unmute " or "Mute ")..self:getName(ObjectIndex)
            
        elseif Object and self.ScreenButtonMode == MixerPageColorDisplayBase.SCREEN_BUTTONS_MODE_SOLO then
            return "Solo "..self:getName(ObjectIndex)          
    
        end

        return ""
    end

    return PageMaschine.getAccessibleTextByButtonIndex(self, ButtonIdx)

end

------------------------------------------------------------------------------------------------------------------------

function MixerPageColorDisplayBase:getAccessibleParamDescriptionByIndex(EncoderIdx)

    local Vector = self:getFocusVector()
    local SoundIndex = Vector:getOffset() + EncoderIdx
    local LevelParam = self:getLevelParameter(SoundIndex)
    if not LevelParam then
        return "", "", "", ""
    end

    local ObjectName = self:getName(SoundIndex)
    local ParameterName = NI.GUI.ParameterWidgetHelper.getParameterName(LevelParam)
    local Value, Unit = NI.GUI.ParameterWidgetHelper.getValueUnitPair(
        NI.GUI.ParameterWidgetHelper.getValueString(LevelParam, MaschineHelper.isAutoWriting()))

    return ObjectName, ParameterName, Value, Unit

end

------------------------------------------------------------------------------------------------------------------------
