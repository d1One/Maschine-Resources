------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Maschine/MaschineMikro/Helper/NavigationHelperMikro"
require "Scripts/Maschine/Helper/NavigationHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/PadModeHelper"
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Maschine/Helper/SamplingHelper"
require "Scripts/Maschine/Helper/ViewHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ViewPageMikro = class( 'ViewPageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- static defines
------------------------------------------------------------------------------------------------------------------------

ViewPageMikro.TIMELINE      = 1
ViewPageMikro.PATTERN_WAVE  = 2


------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ViewPageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "ViewPage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_NAVIGATE }

    self.Mode = ViewPageMikro.TIMELINE

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function ViewPageMikro:setupScreen()

    -- setup screenmikro
    self.Screen = ScreenMikro(self)

    -- Info Display
    ScreenHelper.setWidgetText(self.Screen.Title, {"VIEW"})

    -- info bar
    self.Screen.InfoBar:setMode("View")

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function ViewPageMikro:onShow(Show)

    PageMikro.onShow(self, Show)

    if Show then
        local StateCache = App:getStateCache()
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local SamplingVisible =  Group and Group:getSamplingVisibleParameter():getValue() == true or false

        -- go to Wave Tab if sampling is open, else leave self.Mode as it is
        self.Mode = (SamplingVisible or NavigationHelper.isIdeasVisible()) and ViewPageMikro.PATTERN_WAVE or self.Mode
    end

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function ViewPageMikro:updateScreens(ForceUpdate)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local StateCache = App:getStateCache()
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local InPatternMode =  Group and not Group:getSamplingVisibleParameter():getValue()

    local SamplingVisible = Group and Group:getSamplingVisibleParameter():getValue() or false
    local SamplingTab = NI.DATA.WORKSPACE.getSamplingTab(App)
    local IsZoneWaveVisible = App:getWorkspace():getZoneWaveVisibleParameter():getValue()
    local IsZoneMapVisible = SamplingTab == 3 and not IsZoneWaveVisible

    if not self:isNavPressed() then

        self.Mode = NavigationHelper.isIdeasVisible() and ViewPageMikro.PATTERN_WAVE or self.Mode

        local ScreenButtonTwoText = SamplingVisible and (IsZoneMapVisible and "ZONE" or "WAVE") or
                                    (NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) and "CLIP" or "PAT")

        if NavigationHelper.isIdeasVisible() then

            self.Screen:styleScreenButtons({"TIMEL", "PAT", "FOLLOW"}, "HeadButtonRow", "HeadButton")
            self.Screen.ScreenButton[1]:setVisible(false)
            self.Screen.ScreenButton[2]:setText(ScreenButtonTwoText)
            self.Screen.ScreenButton[2]:setSelected(self.Mode == ViewPageMikro.PATTERN_WAVE)

        elseif NavigationHelper.isArrangerVisible() then

            self.Screen:styleScreenButtons({"TIMEL", "PAT", "FOLLOW"}, "HeadTabRow", "HeadTab")
            self.Screen.ScreenButton[3]:style("FOLLOW", "HeadButton")
            self.Screen.ScreenButton[1]:setVisible(true)
            self.Screen.ScreenButton[1]:setSelected(self.Mode == ViewPageMikro.TIMELINE)
            self.Screen.ScreenButton[2]:setText(ScreenButtonTwoText)
            self.Screen.ScreenButton[2]:setSelected(self.Mode == ViewPageMikro.PATTERN_WAVE)

        else -- Mixer

            self.Screen:styleScreenButtons({"TIMEL", "PAT", "FOLLOW"}, "HeadButtonRow", "HeadButton")
            self.Screen.ScreenButton[1]:setVisible(false)
            self.Screen.ScreenButton[2]:setVisible(false)

        end

        local FollowModeOn = App:getWorkspace():getFollowPlayPositionParameter():getValue()
        self.Screen.ScreenButton[3]:setSelected(FollowModeOn)

        -- setup parameter handler
        self.ParameterHandler:setLabels(self.Screen.ParameterLabel[2], self.Screen.ParameterLabel[4])

    else -- if not self:isNavPressed()

        self.Screen:styleScreenButtons({"IDEAS", "SONG", "MIXER"}, "HeadTabRow", "HeadTab")
        self.Screen.ScreenButton[3]:style("MIXER", "HeadButton")

        local IdeaSpaceActive = ArrangerHelper.isIdeaSpaceFocused()
        self.Screen.ScreenButton[1]:setSelected(IdeaSpaceActive)
        self.Screen.ScreenButton[2]:setSelected(not IdeaSpaceActive)
        self.Screen.ScreenButton[3]:setSelected(NavigationHelper.isMixerVisible())

    end

    -- call base class
    PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ViewPageMikro:updateParameters(ForceUpdate)

    local StateCache = App:getStateCache()
    local Song = NI.DATA.StateHelper.getFocusSong(App)

    -- Parameter Stuff
    local Parameters = {}

    local DisplayZoomValue
    local CustomValues = {}

    if not self:isNavPressed() then

        if NavigationHelper.isArrangerVisible() or NavigationHelper.isIdeasVisible() then

            if self.Mode == ViewPageMikro.TIMELINE then
                if Song then
                    Parameters[1] = Song:getArrangerZoomParameter()
                    Parameters[2] = Song:getArrangerOffsetParameter()
                end
            else
                local Group = NI.DATA.StateHelper.getFocusGroup(App)

                if Song and Group then

                    if ViewHelper.isSamplingVisible() then
                        -- WAVE
                        local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)
                        local Zone = Sampler and Sampler:getZones():getFocusObject() or nil

                        local SamplingTab = NI.DATA.WORKSPACE.getSamplingTab(App)
                        local IsZoneWaveVisible = App:getWorkspace():getZoneWaveVisibleParameter():getValue()
                        local IsZoneMapVisible = SamplingTab == 3 and not IsZoneWaveVisible

                        if IsZoneMapVisible then
                            Parameters[1] = Sampler and Sampler:getZoneEditorZoomXParameter() or nil
                            Parameters[2] = Sampler and Sampler:getZoneEditorScrollXParameter() or nil
                        else
                            Parameters[1] = Zone and Zone:getZoomFactorParameter() or nil
                            Parameters[2] = Zone and Zone:getOffsetParameter() or nil
                            DisplayZoomValue = Parameters[1] and SamplingHelper.getDisplayZoomValueWaveForm(Parameters[1]) or nil
                        end
                    else
                        local ZoomX, ScrollX, ZoomY, ScrollY = nil, nil, nil, nil
                        if NavigationHelper.isPatternEditorVisible() then
                            ZoomX, ScrollX, ZoomY, ScrollY = ViewHelper.getPatternEditorViewParameters()
                        elseif NavigationHelper.isClipEditorVisible() then
                            ZoomX, ScrollX, ZoomY, ScrollY = ViewHelper.getClipEditorViewParameters()
                        end

                        Parameters[1] = ZoomX
                        Parameters[2] = ScrollX
                        Parameters[3] = ViewHelper.isPianorollVisible() and ScrollY or ZoomY

                        CustomValues[3] = ZoomY and ZoomY:getValueString() or nil
                    end

                end
            end -- if self.Mode == ViewPageMikro.TIMELINE

        end -- NavigationHelper.isArrangerVisible() or NavigationHelper.isIdeasVisible()

     end -- if not self:isNavPressed()

    -- update parameter in handler
    self.ParameterHandler:setParameters(Parameters, true)

    local NumParameters = #Parameters
    local ParamIndex = math.bound(self.ParameterHandler.ParameterIndex, 1, NumParameters)
    self.ParameterHandler.ParameterIndex = ParamIndex
    local Parameter = self.ParameterHandler.Parameters[ParamIndex]
    local Name = Parameter and
                  (ParamIndex .. "/" .. NumParameters .. ": " .. Parameter:getParameterInterface():getName())
                  or ""
    local Value
    if CustomValues[ParamIndex] then
        Value = CustomValues[ParamIndex]

    elseif ParamIndex == 1 and DisplayZoomValue then
        Value = string.format("%.1f %%", DisplayZoomValue)

    else
        Value = Parameter and string.format("%.1f %%", Parameter:getNormalizedValue() * 100) or ""

    end

    self.Screen.ParameterLabel[2]:setText(Name)
    self.Screen.ParameterLabel[4]:setText(Value)

    self.Screen.ParameterLabel[1]:setVisible(self.ParameterHandler.ParameterIndex > 1)
    self.Screen.ParameterLabel[3]:setVisible(self.ParameterHandler.ParameterIndex < #self.ParameterHandler.Parameters)

end

------------------------------------------------------------------------------------------------------------------------

function ViewPageMikro:updatePageLEDs(LEDState)

    -- call base class
    -- bypass PageMikro implementation, as it defines a contradicting logic for the Nav button LED
    Page.updatePageLEDs(self, LEDState)

    LEDHelper.setLEDState(NI.HW.LED_NAV, self:isNavPressed() and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)

end

------------------------------------------------------------------------------------------------------------------------

function ViewPageMikro:updatePadLEDs()

    if not self:isNavPressed() then

        local StateCache = App:getStateCache()
        local Workspace = App:getWorkspace()
        local Song = NI.DATA.StateHelper.getFocusSong(App)

        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local InPatternMode = Group and Group:getSamplingVisibleParameter():getValue() == false or false
        local IsZoneWaveVisible = App:getWorkspace():getZoneWaveVisibleParameter():getValue()

        local LedState = LEDHelper.LS_OFF


        for Index, LedID in ipairs (self.Controller.PAD_LEDS) do

            LedState = LEDHelper.LS_OFF

            local Param

            if NavigationHelper.isArrangerVisible() or NavigationHelper.isIdeasVisible() then

                if Index == 1 or Index == 3 then

                    if self.Mode == ViewPageMikro.TIMELINE then
                        Param = Song and Song:getArrangerOffsetParameter() or nil
                    else
                        if InPatternMode then
                            Param = NI.DATA.StateHelper.getPatternEditorOffsetParameter(App, false)
                        else
                            local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)

                            if NI.DATA.WORKSPACE.getSamplingTab(App) ~= 3 or IsZoneWaveVisible then
                                local Zone = Sampler and Sampler:getZones():getFocusObject() or nil
                                Param = Zone and Zone:getOffsetParameter() or nil
                            else
                                Param = Sampler and Sampler:getZoneEditorScrollXParameter() or nil
                            end
                        end
                    end

                    if Index == 3 then
                        LedState = Param and Param:getValue() < Param:getMax() and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
                    else
                        LedState = Param and Param:getValue() > 0 and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
                    end

                elseif Index == 2 or Index == 6 then

                    if self.Mode == ViewPageMikro.TIMELINE then
                        Param = Song and Song:getArrangerZoomParameter() or nil
                    else

                        if InPatternMode then
                            Param = NI.DATA.StateHelper.getPatternEditorZoomParameter(App, false)
                        else
                            local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)

                            if NI.DATA.WORKSPACE.getSamplingTab(App) ~= 3 or IsZoneWaveVisible then
                                local Zone = Sampler and Sampler:getZones():getFocusObject() or nil
                                Param = Zone and Zone:getZoomFactorParameter() or nil
                            else
                                Param = Sampler and Sampler:getZoneEditorZoomXParameter() or nil
                            end
                        end
                    end

                    if Index == 6 then
                        LedState = Param and Param:getValue() < Param:getMax() and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
                    else
                        LedState = Param and Param:getValue() > Param:getMin() and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
                    end

                elseif Index == 4 or Index == 8 then

                    if self.Mode == ViewPageMikro.PATTERN_WAVE then

                        local Param

                        if InPatternMode and PadModeHelper.getKeyboardMode() then
                            local Sound = NI.DATA.StateHelper.getFocusSound(App)
                            Param = Sound and Sound:getPianorollOffsetYParameter() or nil
                        elseif not InPatternMode and NI.DATA.WORKSPACE.getSamplingTab(App) == 3 and not IsZoneWaveVisible then
                            local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)
                            Param = Sampler and Sampler:getZoneEditorScrollYParameter() or nil
                        end

                        if not Param then
                            LedState = LEDHelper.LS_OFF
                        elseif Index == 4 then
                             LedState = Param and Param:getValue() < Param:getMax() and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
                        else
                            LedState = Param and Param:getValue() > 0 and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
                        end

                    end

                end

            end -- NavigationHelper.isArrangerVisible() or NavigationHelper.isIdeasVisible()

            if Index == 13 then

                LedState = NavigationHelper.isBrowserVisible() and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM

            elseif Index == 14 then

                if NavigationHelper.isMixerVisible() then
                    LedState = NavigationHelper.isMixerExpanded() and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
                elseif NavigationHelper.isArrangerVisible() then
                    LedState = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
                else
                    LedState = LEDHelper.LS_OFF
                end

            elseif Index == 15 then

                if not NavigationHelper.isSamplingVisible() and not NavigationHelper.isMixerVisible() then
                    LedState = NavigationHelper.isModulationVisible() and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
                else
                    LedState = LEDHelper.LS_OFF
                end

            end

            LEDHelper.setLEDState(LedID, LedState)

        end -- for Index, LedID in ipairs (self.Controller.PAD_LEDS) do
    else

        for Index, LedID in ipairs (self.Controller.PAD_LEDS) do
            LedState = LEDHelper.LS_OFF
            LEDHelper.setLEDState(LedID, LedState)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function ViewPageMikro:onScreenButton(Idx, Pressed)

    if Pressed then
        if not self:isNavPressed() then

            if Idx == 1 and NavigationHelper.isArrangerVisible() then
                self.Mode = ViewPageMikro.TIMELINE
            elseif Idx == 2 and NavigationHelper.isArrangerVisible() then
                self.Mode = ViewPageMikro.PATTERN_WAVE
            elseif Idx == 3 then
                ArrangerHelper.toggleFollowMode()
            end

        else

            if Idx == 1 then
                NavigationHelper.activateIdeasTab()
                self.Mode = ViewPageMikro.PATTERN_WAVE
            elseif Idx == 2 then
                NavigationHelper.activateArrangerTab()
            elseif Idx == 3 then
                NavigationHelper.toggleMixer()
            end

        end
    end

    -- call base class for update
    PageMikro.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ViewPageMikro:onPadEvent(PadIndex, Trigger)

    if not Trigger then
        return
    end

    if not self:isNavPressed() then

        if PadIndex == 13 then
            NavigationHelper.toggleBrowser()
            return
        elseif PadIndex == 14 then

            if not NavigationHelper.isIdeasVisible() then

                if NavigationHelper.isArrangerVisible() then
                    NI.DATA.ArrangerAccess.toggleSongFocusEntity(App)
                else
                    NavigationHelper.toggleMixerExpanded()
                end

            end

            return

        elseif PadIndex == 15 then

            if not NavigationHelper:isSamplingVisible() then
                NavigationHelper.toggleModulation()
            end

            return

        end

        local Direction = 1
        if PadIndex == 1 or PadIndex == 2 or PadIndex == 8 then
            Direction = -1
        end

        if NavigationHelper.isArrangerVisible() or NavigationHelper.isIdeasVisible() then

            if PadIndex == 1 or PadIndex == 3 then
                NavigationHelperMikro.scrollHorizontally(self.Controller:getWheelButtonPressed(),
                                                         Direction,
                                                         (self.Mode == ViewPageMikro.TIMELINE),
                                                         2,
                                                         self.ParameterHandler)

            elseif PadIndex == 2 or PadIndex == 6 then
                NavigationHelperMikro.zoomHorizontally(self.Controller:getWheelButtonPressed(),
                                                       Direction,
                                                       (self.Mode == ViewPageMikro.TIMELINE),
                                                       1,
                                                       self.ParameterHandler)

            elseif (PadIndex == 4 or PadIndex == 8) and self.Mode == ViewPageMikro.PATTERN_WAVE then
                -- scroll up and down if in keyboard-mode
                NavigationHelperMikro.scrollVertically(self.Controller:getWheelButtonPressed(), Direction)
            end

        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ViewPageMikro:onWheel(Inc)

    if not self:isNavPressed() then

        if NavigationHelper.isArrangerVisible() or NavigationHelper.isIdeasVisible() then
            if self.ParameterHandler.ParameterIndex == 1 then
                NavigationHelperMikro.zoomHorizontally(self.Controller:getWheelButtonPressed(),
                                                       Inc,
                                                       (self.Mode == ViewPageMikro.TIMELINE),
                                                       1,
                                                       self.ParameterHandler)

            elseif self.ParameterHandler.ParameterIndex == 2 then
                NavigationHelperMikro.scrollHorizontally(self.Controller:getWheelButtonPressed(),
                                                         Inc,
                                                         (self.Mode == ViewPageMikro.TIMELINE),
                                                         2,
                                                         self.ParameterHandler)

            elseif self.ParameterHandler.ParameterIndex == 3 and self.Mode == ViewPageMikro.PATTERN_WAVE then

                if ViewHelper.isPianorollVisible() then
                    NavigationHelperMikro.scrollVertically(self.Controller:getWheelButtonPressed(), Inc)

                else
                    NavigationHelper.incrementEnumParameter(self.ParameterHandler.Parameters[3], Inc)

                end

            end
        end
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function ViewPageMikro:onNavButton(Pressed)

    self:updateScreens()
    LEDHelper.setLEDState(NI.HW.LED_NAV, Pressed and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)

end

------------------------------------------------------------------------------------------------------------------------

function ViewPageMikro:isNavPressed()

    return self.Controller:getNavPressed()

end

------------------------------------------------------------------------------------------------------------------------
