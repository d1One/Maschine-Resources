------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/PatternHelper"
require "Scripts/Maschine/Helper/SelectHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SamplingPageSliceApplyMikro = class( 'SamplingPageSliceApplyMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyMikro:__init(Controller, Parent)

    PageMikro.__init(self, "SamplingPageSliceApplyMikro", Controller)

    -- setup screen
    self:setupScreen()

    -- some vars we need
    self.Parent = Parent
    self.FocusGroupIndex = 0
    self.FocusSoundIndex = 0
    self.GroupBank = 0
    self.BlinkTick = 0
    self.GroupMode = false

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyMikro:setupScreen()

    -- create screen
    self.Screen = ScreenMikro(self, ScreenMikro.SIMPLE_BAR)

    -- Buttons
    self.Screen.ScreenButtonBar = ScreenHelper.createBarWithButtons(
                                                    self.Screen.RootBar, self.Screen.ScreenButton,
                                                    {"SINGLE", "APPL.TO", "APPLY"}, "HeadButtonRow", "HeadButton")

    self.Screen.MikroScreenStack = NI.GUI.insertStack(self.Screen.RootBar, "MikroMidScreenStack")
    self.Screen.MikroScreenStack:style("TransportStack")

    -- InfoGroupBar: middle part of screen including title and transport bars
    self.Screen.InfoGroupBar = NI.GUI.insertBar(self.Screen.MikroScreenStack, "InfoGroupBar")
    self.Screen.InfoGroupBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

    -- Title
    self.Screen.Title = {}
    self.Screen.Title[1] = NI.GUI.insertLabel(self.Screen.InfoGroupBar, "Title")
    self.Screen.Title[1]:style("", "Title")
    NI.GUI.enableCropModeForLabel(self.Screen.Title[1])

    -- Wave Editor
    self.WaveEditor = NI.GUI.insertSliceWaveEditor(self.Screen.InfoGroupBar, App, "SliceWaveEditor")
    self.WaveEditor:showTimeline(false)
    self.WaveEditor:showScrollbar(false)
    self.WaveEditor:setStereo(false)

    -- Black line
    local Line = NI.GUI.insertLabel(self.Screen.InfoGroupBar, "Line")
    Line:style("", "BlackLine")

    -- Parameter bar and labels (bottom)
    self.Screen.ParameterBar = {}
    self.Screen.ParameterLabel = {}

    local Spacer = NI.GUI.insertLabel(self.Screen.InfoGroupBar, "Spacer")
    Spacer:style("", "Spacer6px")

    self.Screen.ParameterBar[1] = ScreenHelper.createBarWithLabels(self.Screen.InfoGroupBar, self.Screen.ParameterLabel,
        {"(SELECT PAD OR GROUP)"}, "ParameterBar", "ParameterValueSingle")

    -- set default screen stack top
    self.Screen.MikroScreenStack:setTop(self.Screen.InfoGroupBar)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyMikro:updateScreens(ForceUpdate)

    local StateCache = App:getStateCache()

    local Zone = NI.DATA.StateHelper.getFocusZone(App, nil)
    local TransactionSample = Zone and Zone:getTransactionSample()
    local Sample = Zone and Zone:getSample()

    if TransactionSample and Sample then
        self.Screen.Title[1]:setText(string.upper(Zone:getName()))
    else
        self.Screen.Title[1]:setText("NO SAMPLE LOADED")
    end


    -- Hide SliceApply sub page if we change sound
    local FocusSound = NI.DATA.StateHelper.getFocusSound(App)

    if FocusSound ~= self.FocusSound then
        self.FocusSound = FocusSound
        self:onShow(false)
        self.Parent:onShow(true)
        return
    end

    self.Screen.ScreenButton[2]:setSelected(true)

    -- call base class
    PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyMikro:updatePadLEDs()

    self.BlinkTick = self.BlinkTick + 1

    if self.GroupMode then
        LEDHelper.turnOffLEDs(self.Controller.PAD_LEDS)
    else
        LEDHelper.turnOffLEDs(self.Controller.GROUP_LEDS)
        LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_LEDS, 0,
            function(Index) return SamplingPageSliceApplyMikro.getPadLEDStates(self, Index) end,
            function(Index) return MaschineHelper.getSoundColorByIndex(Index, self.FocusGroupIndex, true) or LEDColors.WHITE end)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyMikro:updateGroupLEDs()

    if self.GroupMode then
        LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS, self.GroupBank,
            function(Index) return SamplingPageSliceApplyMikro.getPadLEDStates(self, Index) end,
            function(Index) return MaschineHelper.getGroupColorByIndex(Index, true) end)
    end

    LEDHelper.setLEDState(NI.HW.LED_GROUP, self.GroupMode and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM,
                          MaschineHelper.getGroupColorByIndex(self.FocusGroupIndex, true))

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyMikro:getPadLEDStates(Index) -- index >= 1

    local StateCache = App:getStateCache()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil


    if self.GroupMode then

        local GroupIndex = Index - 1 + self.GroupBank * 8

        if  Song:getGroups():at(GroupIndex) or        -- exsisting group
            GroupIndex == Groups:size()      then           -- new group

            local Focused = (Index == self.FocusGroupIndex) and ((self.BlinkTick % 8) < 4)
            return Focused, true

        end
        return false, false

    else
        local Focused = (Index == self.FocusSoundIndex) and ((self.BlinkTick % 8) < 4)

        local FocusedGroup = Song and Song:getGroups():at(self.FocusGroupIndex-1) or nil
        local Sound = FocusedGroup and FocusedGroup:getSounds():at(Index - 1)
        local Enabled = self.FocusGroupIndex ~= 0 and Sound and StateCache:getObjectCache():isSoundEnabled(Sound) or false

        return Focused,  Enabled
    end

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyMikro:onGroupButton(Pressed)

    if not Pressed then
        return
    end

    self.GroupMode = not self.GroupMode
    self:updateScreens()

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyMikro:onPadEvent(PadIndex, Trigger)

    if self.GroupMode then

        local GroupIndex = PageMikro.getGroupIndexFromPad(PadIndex)

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Groups = Song and Song:getGroups() or nil

        local SelectedIndex = GroupIndex + self.GroupBank * 8
        local SelectedGroup = Song and Song:getGroups():at(SelectedIndex-1)

        if SelectedGroup or
           SelectedIndex == Groups:size()+1 then   -- slice to new Group

            self.FocusGroupIndex = SelectedIndex
            self.FocusSoundIndex = 0
        end
    else
        self.FocusSoundIndex = self.FocusGroupIndex > 0 and PadIndex or 0
    end
    self:updateScreens()

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyMikro:onLeftRightButton(Right, Pressed)

    if Pressed then
        local NewGroupBank = self.GroupBank + (Right and 1 or -1)
        local MaxPageIndex = MaschineHelper.getNumFocusSongGroupBanks(true)

        if NewGroupBank >= 0 and NewGroupBank < MaxPageIndex then
            self.GroupBank = NewGroupBank
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyMikro:onScreenButton(ButtonIdx, Pressed)

    if Pressed then

        --Single Toggle
        if ButtonIdx == 1 then
            local SingleOn = self.Screen.ScreenButton[1]:isSelected()
            self.Screen.ScreenButton[1]:setSelected(not SingleOn)

        --Cancel
        elseif ButtonIdx == 2 then
            self.Screen.ScreenButton[2]:setSelected(false)
            self:onShow(false)
            self.Parent:onShow(true)

        --Apply
        elseif ButtonIdx == 3 then
            self:applySettings()

        end
    end

    -- call base class for update
    PageMikro.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyMikro:onShow(Show)

    -- synchronize local group bank with parameter
    if Show then
        self.DisplayGroup = 0
        self.GroupBank = 0
        self.FocusGroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App) + 1
        self.FocusSoundIndex = NI.DATA.StateHelper.getFocusSoundIndex(App) + 1
        self.GroupMode = false
    end

    LEDHelper.setLEDState(NI.HW.LED_GROUP, LEDHelper.LS_OFF)

    PageMikro.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageSliceApplyMikro:applySettings()

    if self.FocusGroupIndex == 0 then
        return
    end

    SamplingHelper.applySlicing(self.FocusGroupIndex, self.FocusSoundIndex, self.Screen.ScreenButton[1]:isSelected())

    self:onShow(false)
    self.Parent:onShow(true)

end

------------------------------------------------------------------------------------------------------------------------

