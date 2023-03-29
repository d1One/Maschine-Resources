------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

require "Scripts/Shared/Components/ScreenMaschine"
require "Scripts/Shared/Components/InfoBar"

require "Scripts/Shared/Helpers/ScreenHelper"
require "Scripts/Shared/Helpers/ControlHelper"
require "Scripts/Maschine/Helper/NavigationHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
NavigatePagePageNav = class( 'NavigatePagePageNav', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNav:__init(ParentPage, Controller)

    -- create page
    PageMaschine.__init(self, "NavigatePagePageNav", Controller)

    -- setup screen
    self:setupScreen()

    self.ParentPage = ParentPage

    -- define page leds
    self.PageLEDs = { NI.HW.LED_NAVIGATE }


end

------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNav:setupScreen()

    -- create screen
    self.Screen = ScreenMaschine(self)

    -- left screen
    self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"NAVIGATE", "", "<<", ">>"}, "ScreenButton", true)
    self.Screen.ScreenButton[1]:style("NAVIGATE", "HeadPin")
    self.Screen.ScreenButton[2]:setSelected(true)
    self.Screen.InfoBar = InfoBar(self.Controller, self.Screen.ScreenLeft)

    -- right screen
    ScreenHelper.createBarWithButtons(self.Screen.ScreenRight, self.Screen.ScreenButton,
                                      {"CHANNEL", "PLUG-IN", "PREV", "NEXT"}, "HeadRow", "HeadButton")

    -- grid
    self.Screen.ButtonPad = {}
    ScreenHelper.createBarWith16Buttons(self.Screen.ScreenRight, self.Screen.ButtonPad,
                                        {"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""})

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNav:onShow(Show)

    if Show == true then

        NHLController:setEncoderMode(NI.HW.ENC_MODE_NONE)

        LEDHelper.setLEDState(NI.HW.LED_LEFT, LEDHelper.LS_OFF)
        LEDHelper.setLEDState(NI.HW.LED_RIGHT, LEDHelper.LS_OFF)

    end

    -- Call Base Class
    PageMaschine.onShow(self, Show)

end


------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNav:updateScreens(ForceUpdate)

   -- Pin Button
   self.Screen.ScreenButton[1]:setSelected(self.ParentPage.IsPinned)

   local ChannelMode = not App:getWorkspace():getModulesVisibleParameter():getValue()

   ScreenHelper.setWidgetText(self.Screen.ScreenButton,
                              ChannelMode and {"NAVIGATE", "PAGE NAV", "<<", ">>", "CHANNEL", "PLUG-IN", "PREV", "NEXT"}
                                 or {"NAVIGATE", "PAGE NAV", "<<", ">>", "CHANNEL", "PLUG-IN", "PREV", "NEXT"})

   if ChannelMode then
      self.Screen:setArrowText(1, App:getWorkspace():getPageGroupParameter():getValueString())
   else
      self.Screen:setArrowText(1, MaschineHelper.getFocusSlotNameWithNumber())
   end

   ScreenHelper.updateButtonsWithFunctor(self.Screen.ButtonPad,
       function(Index)
           return NavigationHelper.getPageNameAndStates(Index)
       end)

    -- call base class updateScreens
    PageMaschine.updateScreens(self, ForceUpdate)

end


------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNav:updateScreenButtons(ForceUpdate)

    local Workspace = App:getWorkspace()
    local ChannelMode = not Workspace:getModulesVisibleParameter():getValue()

    if ChannelMode then

       local PageGroupParameterIndex = Workspace:getPageGroupParameter():getValue()

       self.Screen.ScreenButton[3]:setEnabled(PageGroupParameterIndex > 0)
       self.Screen.ScreenButton[4]:setEnabled(PageGroupParameterIndex < 3)

       self.Screen.ScreenButton[5]:setSelected(true)
       self.Screen.ScreenButton[6]:setSelected(false)

    else -- Plug-in Mode

       local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
       local NewIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)

       local NewButton3Enabled = NewIndex > 0 and Slots:size() > 0
       self.Screen.ScreenButton[3]:setEnabled(NewButton3Enabled)

       local NewButton4Enabled = NewIndex < Slots:size() and Slots:size() > 0
       self.Screen.ScreenButton[4]:setEnabled(NewButton4Enabled)

       self.Screen.ScreenButton[5]:setSelected(false)
       self.Screen.ScreenButton[6]:setSelected(true)

    end

    local HasPrevPageBank, HasNextPageBank = NavigationHelper.hasPrevNextPageBank()
    self.Screen.ScreenButton[7]:setEnabled(HasPrevPageBank)
    self.Screen.ScreenButton[8]:setEnabled(HasNextPageBank)

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end


------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNav:updateParameters(ForceUpdate)
end


------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNav:onScreenButton(ButtonIdx, Pressed)

    if not Pressed then
        PageMaschine.onScreenButton(self, ButtonIdx, Pressed)
        return
    end

    if ButtonIdx == 1 then
        self.ParentPage:togglePinState()

    elseif ButtonIdx == 2 then
        self.ParentPage:switchToPage(NavigatePage.VIEW)

    elseif ButtonIdx == 3 or ButtonIdx == 4 then
        ControlHelper.onPrevNextSlot(ButtonIdx == 4, false)

    elseif ButtonIdx == 5 or ButtonIdx == 6 then
        ControlHelper.setPluginMode(ButtonIdx == 6)

    elseif ButtonIdx == 7 or ButtonIdx == 8 then
        NavigationHelper.setPrevNextPageBank(ButtonIdx == 8)
    end

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end


------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNav:onScreenEncoder(KnobIdx, EncoderInc)

end


------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNav:onPadEvent(PadIndex, Trigger, PadValue)

    if Trigger then
        local ParamCache = App:getStateCache():getParameterCache()
        local NumPages = ParamCache:getNumPagesOfFocusParameterOwner()
        local PageIndex = NavigationHelper.getPageBankIndex() * 16 + PadIndex

        if PageIndex >= 1 and PageIndex <= NumPages then
            ControlHelper.setPageParameter(PageIndex)
        end
    end

end


------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNav:updatePadLEDs()

    NavigationHelper.updatePadLEDsForPageNav(self.Controller.PAD_LEDS, NavigationHelper.getPageBankIndex() * 16)

end


------------------------------------------------------------------------------------------------------------------------
