------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

require "Scripts/Shared/Components/ScreenMaschine"
require "Scripts/Shared/Components/InfoBar"

require "Scripts/Shared/Helpers/ScreenHelper"
require "Scripts/Maschine/Helper/NavigationHelper"
require "Scripts/Maschine/Helper/ViewHelper"
require "Scripts/Maschine/Helper/SamplingHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
NavigatePageView = class( 'NavigatePageView', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function NavigatePageView:__init(ParentPage, Controller, PageName, NavPage)

    -- create page
    PageMaschine.__init(self, PageName or "NavigatePageView", Controller)

    -- setup screen
    self:setupScreen()

    self.ParentPage = ParentPage
    self.NavPage = NavPage or NavigatePage.PAGE_NAV

    -- define page leds
    self.PageLEDs = { NI.HW.LED_NAVIGATE }

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageView:setupScreen()

    -- create screen
    self.Screen = ScreenMaschine(self)

    -- Left screen
    self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"NAVIGATE", "IDEAS", "SONG", "MIXER"}, "ScreenButton", true)
    self.Screen.ScreenButton[1]:style("NAVIGATE", "HeadPin")
    self.Screen.ScreenButton[2]:style("IDEAS", "HeadTabLeft")
    self.Screen.ScreenButton[3]:style("SONG", "HeadTabRight")

    self.Screen.InfoBar = InfoBar(self.Controller, self.Screen.ScreenLeft)
    self.Screen:addParameterBar(self.Screen.ScreenLeft)

    -- Right screen
    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"BROWSER", "EXPANDED", "MOD", "FOLLOW"}, "HeadButton")

    self.Screen.InfoBarRight = InfoBar(self.Controller, self.Screen.ScreenRight, "RightScreenDefault")
    self.Screen:addParameterBar(self.Screen.ScreenRight)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageView:onShow(Show)

    if Show == true then

        NHLController:setEncoderMode(NI.HW.ENC_MODE_NONE)

        LEDHelper.setLEDState(NI.HW.LED_LEFT, LEDHelper.LS_OFF)
        LEDHelper.setLEDState(NI.HW.LED_RIGHT, LEDHelper.LS_OFF)
    else
        NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)
    end

    -- Call Base Class
    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageView:updateScreenButtons(ForceUpdate)

    -- Pin Button
    self.Screen.ScreenButton[1]:setSelected(self.ParentPage.IsPinned)

    if self.Controller:getShiftPressed() then
        -- hide buttons from 3 - 8
        for Id = 3,8 do
            self.Screen.ScreenButton[Id]:setVisible(false)
        end

        self.Screen.ScreenButton[2]:setText("PAGE NAV")
        self.Screen.ScreenButton[2]:style("PAGE NAV", "HeadButton")
        self.Screen.ScreenButton[2]:setSelected(false)
    else
        -- show buttons from 3 - 8
        for Id = 3,8 do
            self.Screen.ScreenButton[Id]:setVisible(true)
        end

        -- Shift could have changed the IDEAS button so we need to reset it
        self.Screen.ScreenButton[2]:setText("IDEAS")
        self.Screen.ScreenButton[2]:style("IDEAS", "HeadTabLeft")
        self.Screen.ScreenButton[2]:setSelected(NavigationHelper.isIdeasVisible())
        self.Screen.ScreenButton[3]:setSelected(NavigationHelper.isArrangerVisible())
        self.Screen.ScreenButton[4]:setSelected(NavigationHelper.isMixerVisible())

        -- update right screen buttons
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local BrowserVisible = App:getWorkspace():getBrowserVisibleParameter():getValue()
        local SamplingVisible = Group and Group:getSamplingVisibleParameter():getValue()

        self.Screen.ScreenButton[5]:setSelected(BrowserVisible)

        if NavigationHelper.isMixerVisible() then
            local Song = NI.DATA.StateHelper.getFocusSong(App)
            local IdeaSpaceVisible = ArrangerHelper.isIdeaSpaceFocused()
            self.Screen.ScreenButton[2]:setSelected(IdeaSpaceVisible)
            self.Screen.ScreenButton[3]:setSelected(not IdeaSpaceVisible)
            self.Screen.ScreenButton[6]:setText("EXPANDED")
            self.Screen.ScreenButton[6]:setVisible(true)
            self.Screen.ScreenButton[6]:setSelected(NavigationHelper.isMixerExpanded())
            self.Screen.ScreenButton[7]:setVisible(false)
        else
            self.Screen.ScreenButton[6]:setVisible(false)
            self.Screen.ScreenButton[7]:setVisible(not SamplingVisible)
            self.Screen.ScreenButton[7]:setText("MOD")
            self.Screen.ScreenButton[7]:setSelected(NavigationHelper.isModulationVisible())
        end

        local FollowModeOn = App:getWorkspace():getFollowPlayPositionParameter():getValue()
        self.Screen.ScreenButton[8]:setSelected(FollowModeOn)

    end

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageView:updateParameters(ForceUpdate)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local SamplingVisible = Group and Group:getSamplingVisibleParameter():getValue()
    local SamplingTab = NI.DATA.WORKSPACE.getSamplingTab(App)
    local IsZoneWaveVisible = App:getWorkspace():getZoneWaveVisibleParameter():getValue()
    local IsZoneMapVisible = SamplingTab == 3 and not IsZoneWaveVisible

    -- Retrieve the parameters and group names and set them
    local Sections = {}
    local Parameters = {}
    local Values = {}
    local Names = {}
    Parameters, Sections[1], Sections[5] = self:getParametersAndGroupNames()

    for Index = 1, 6 do

        local Parameter = Parameters[Index]

        if Parameter then
            local ParamName = Parameter:getParameterInterface():getName()
            Names[Index] = string.upper(ParamName)
            Values[Index] = string.format("%.1f %%", Parameter:getNormalizedValue() * 100)
        end

    end

    -- Adjust parameters for piano roll
    if NavigationHelper.isIdeasVisible() or NavigationHelper.isArrangerVisible() then
        local IsPianoScrollEnabled = Group and Group:getKeyboardModeEnabledParameter():getValue() or false
        local IsPianoScrollVisible = IsPianoScrollEnabled and not SamplingVisible

        -- SCROLL X
        if (IsPianoScrollVisible and Parameters[8]) or (SamplingVisible and IsZoneMapVisible and Parameters[8] ~= nil) then

            local ParamName = Parameters[8] and Parameters[8]:getParameterInterface():getName() or ""
            local ParamValue = Parameters[8] and (Parameters[8]:getNormalizedValue() * 100) or 0
            Names[8] = string.upper(ParamName)
            Values[8] = string.format("%.1f %%", ParamValue)
        end
    end

    self.ParameterHandler:setParameters(Parameters, true)
    self.ParameterHandler:setCustomSections(Sections)
    self.ParameterHandler:setCustomNames(Names)
    self.ParameterHandler:setCustomValues(Values)

    PageMaschine.updateParameters(self, ForceUpdate)

    -- Suppress "NO PARAMETERS" section text automatic generated by the ParameterHndler
    if next(Parameters) == nil then
        self.ParameterHandler.SectionWidgets[1]:setText("")
    end

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageView:getParametersAndGroupNames()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local SamplingVisible = Group and Group:getSamplingVisibleParameter():getValue()
    local SamplingTab = NI.DATA.WORKSPACE.getSamplingTab(App)
    local IsZoneWaveVisible = App:getWorkspace():getZoneWaveVisibleParameter():getValue()
    local IsZoneMapVisible = SamplingTab == 3 and not IsZoneWaveVisible

    local Parameters = {}
    local ParameterGroupNameLeft = ""
    local ParameterGroupNameRight = ""

    if NavigationHelper.isIdeasVisible() or NavigationHelper.isArrangerVisible() then

        if NavigationHelper.isArrangerVisible() then
            Parameters[1] = Song and Song:getArrangerZoomParameter() or nil
            Parameters[2] = Song and Song:getArrangerOffsetParameter() or nil
            ParameterGroupNameLeft = "Timeline"
        end

        if SamplingVisible then
            local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)
            if IsZoneMapVisible then
                Parameters[5] = Sampler and Sampler:getZoneEditorZoomXParameter() or nil
                Parameters[6] = Sampler and Sampler:getZoneEditorScrollXParameter() or nil
                Parameters[7] = nil
                Parameters[8] = Sampler and Sampler:getZoneEditorScrollYParameter() or nil
                ParameterGroupNameRight = "Zone"
            else
                local View = SamplingHelper.makeFocusSampleOwnerView(NI.DATA.WORKSPACE.getSamplingTab(App) == 0)
                Parameters[5] = View and View:waveZoomParameter() or nil
                Parameters[6] = View and View:waveOffsetParameter() or nil
                Parameters[7] = nil
                ParameterGroupNameRight = "Wave"
            end
        else
            local ZoomX, ScrollX, ZoomY, ScrollY = nil, nil, nil, nil
            if NavigationHelper.isPatternEditorVisible() then
                ZoomX, ScrollX, ZoomY, ScrollY = ViewHelper.getPatternEditorViewParameters()
            elseif NavigationHelper.isClipEditorVisible() then
                ZoomX, ScrollX, ZoomY, ScrollY = ViewHelper.getClipEditorViewParameters()
            end

            Parameters[5] = ZoomX
            Parameters[6] = ScrollX
            Parameters[7] = ZoomY
            Parameters[8] = ScrollY

            ParameterGroupNameRight = NavigationHelper.isClipEditorVisible() and (ZoomX and "Clip" or "") or "Pattern"
        end
    end

    return Parameters, ParameterGroupNameLeft, ParameterGroupNameRight

end


------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function NavigatePageView:onScreenButton(ButtonIdx, Pressed)

    if Pressed then

        if ButtonIdx == 1 then
            self.ParentPage:togglePinState()
            return true
        end

        if self.Controller:getShiftPressed() then
            if ButtonIdx == 2 then
                self.ParentPage:switchToPage(self.NavPage)
            end
            return true
        end

        if ButtonIdx == 2 then
            NavigationHelper.activateIdeasTab()
            return true
        elseif ButtonIdx == 3 then
            NavigationHelper.activateArrangerTab()
            return true
        elseif ButtonIdx == 4 then
            NavigationHelper.toggleMixer()
            return true
        elseif ButtonIdx == 5 then
            NavigationHelper.toggleBrowser()
            return true
        elseif ButtonIdx == 8 then
            ArrangerHelper.toggleFollowMode()
            return true
        end

        -- Active Tab dependent presses
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local SamplingVisible = Group and Group:getSamplingVisibleParameter():getValue()

        if NavigationHelper.isIdeasVisible() and ButtonIdx == 7 and not SamplingVisible then
            NavigationHelper.toggleModulation()
            return true
        end

        if NavigationHelper.isArrangerVisible() then
            if ButtonIdx == 7 and not SamplingVisible then
                NavigationHelper.toggleModulation()
                return true
            end
        end

        if NavigationHelper.isMixerVisible() and ButtonIdx == 6 then
            NavigationHelper.toggleMixerExpanded()
            return true
        end

    end -- if Pressed

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageView:onScreenEncoder(KnobIdx, EncoderInc)

    if NavigationHelper.isMixerVisible() then
        return
    end

    local Fine = self.Controller:getShiftPressed()

    if NavigationHelper.isArrangerVisible() then

        if KnobIdx == 1 then
            ViewHelper.zoomArranger(EncoderInc, Fine)
        elseif KnobIdx == 2 then
            ViewHelper.scrollArranger(EncoderInc, Fine)
        end

    end

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local SamplingVisible = Group and Group:getSamplingVisibleParameter():getValue() or false
    local IsZoneWaveVisible = App:getWorkspace():getZoneWaveVisibleParameter():getValue()
    local IsZoneMapVisible = NI.DATA.WORKSPACE.getSamplingTab(App) == 3 and not IsZoneWaveVisible
    local Sampler = NI.DATA.StateHelper.getFocusSampler(App, NI.DATA.StateHelper.getFocusSound(App))

    if KnobIdx == 5 then

        if SamplingVisible then
            if IsZoneMapVisible then
                if Sampler then
                    self.ParameterHandler:onScreenEncoder(KnobIdx, EncoderInc, Fine)
                end
            else
                SamplingHelper.zoomWaveForm(EncoderInc, Fine, NI.DATA.WORKSPACE.getSamplingTab(App) == 0)
            end
        else
            if NavigationHelper.isClipEditorVisible() then
                ViewHelper.zoomClipEditor(EncoderInc, Fine)
            end

            if NavigationHelper.isPatternEditorVisible() then
                ViewHelper.zoomPatternEditor(EncoderInc, Fine)
            end
        end

    elseif KnobIdx == 6 then

        if SamplingVisible then
            if IsZoneMapVisible then
                if Sampler then
                    self.ParameterHandler:onScreenEncoder(KnobIdx, EncoderInc, Fine)
                end
            else
                SamplingHelper.scrollWaveForm(EncoderInc, Fine, NI.DATA.WORKSPACE.getSamplingTab(App) == 0)
            end
        else
            if NavigationHelper.isClipEditorVisible() then
                ViewHelper.scrollClipEditor(EncoderInc, Fine)
            end

            if NavigationHelper.isPatternEditorVisible() then
                ViewHelper.scrollPatternEditor(EncoderInc, Fine)
            end
        end

    elseif KnobIdx == 7 then

       if not SamplingVisible and Group then
            self.ParameterHandler:onScreenEncoder(KnobIdx, EncoderInc, Fine)
       end

    elseif KnobIdx == 8 then

       if SamplingVisible then
          if IsZoneMapVisible then
              if Sampler then
                  self.ParameterHandler:onScreenEncoder(KnobIdx, EncoderInc, Fine)
              end
          end
       else
          if Group and Group:getKeyboardModeEnabledParameter():getValue() then
             local Sound = NI.DATA.StateHelper.getFocusSound(App)
             if Sound then
                 self.ParameterHandler:onScreenEncoder(KnobIdx, EncoderInc, Fine)
             end
          end
       end

    end

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageView:onPadEvent(PadIndex, Trigger)

    if not Trigger then
       return true
    end

    local UseFineResolution = self.Controller:getWheelButtonPressed()
    NavigationHelper.triggerPad(PadIndex, UseFineResolution)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageView:updatePadLEDs()

    NavigationHelper.updatePadLEDsForPageView(self.Controller.PAD_LEDS)

end

------------------------------------------------------------------------------------------------------------------------
