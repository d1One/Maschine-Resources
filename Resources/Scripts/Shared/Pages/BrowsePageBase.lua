------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/BrowseHelper"

local ATTR_FAVORITES_FILTER = NI.UTILS.Symbol("FavoritesFilter")
local ATTR_OVERRIDDEN = NI.UTILS.Symbol("Overridden")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowsePageBase = class( 'BrowsePageBase', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:__init(Page, Controller, SamplingPage)

    PageMaschine.__init(self, Page, Controller)

    self.IsPinned = true

    -- define page leds
    self.PageLEDs = { NI.HW.LED_BROWSE }

    self.BankMode = true
    self.SamplingPage = SamplingPage

    -- create screen
    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:onShow(Show)

    -- call base class
    PageMaschine.onShow(self, Show)

    if Show then

        if NI.HW.FEATURE.JOGWHEEL then
            -- remember old jog-wheel state
            self.OldJogWheelMode = NHLController:getJogWheelMode()
            NHLController:setJogWheelMode(NI.HW.JOGWHEEL_MODE_CUSTOM)
        end

        self.Controller:setTimer(self, 2)

    elseif self.OldJogWheelMode then
        NHLController:setJogWheelMode(self.OldJogWheelMode)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:updateSampleBrowser(ForceUpdate)

    if ForceUpdate then
        BrowseHelper.setFileType(NI.DB3.FILE_TYPE_ONESHOT_SAMPLE)
    end

    -- Hide Browse sub page if we change sound
    local FocusSound = NI.DATA.StateHelper.getFocusSound(App)

    if FocusSound ~= self.FocusSound then
        self.FocusSound = FocusSound
        self:onShow(false)
        self.SamplingPage:onShow(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:updateResultList()

    self.ResultList:setAlign()

    WidgetHelper.VectorCenterOnItem(self.ResultList, BrowseHelper.getResultListFocusItem())

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:isQuickBrowseVisible()

    return not NI.APP.FEATURE.EFFECTS_CHAIN
           or (BrowseHelper.getInsertMode() == NI.DATA.INSERT_MODE_OFF and not self.SamplingPage)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:isQuickBrowseEnabled()

    return self:isQuickBrowseVisible()

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:updateScreenButtons(ForceUpdate)

    if not self.Controller:getShiftPressed() then

        -- update locate button
        self.Screen.ScreenButton[3]:setVisible(self:isQuickBrowseVisible())
        self.Screen.ScreenButton[3]:setEnabled(self:isQuickBrowseEnabled())
        self.Screen.ScreenButton[3]:setSelected(false)
        self.Screen.ScreenButton[3]:setAttribute(ATTR_OVERRIDDEN, "false")
        self.Screen.ScreenButton[3]:setText("LOCATE")

        -- update user button
        self.Screen.ScreenButton[4]:setVisible(true)
        self.Screen.ScreenButton[4]:setEnabled(true)
        self.Screen.ScreenButton[4]:setText("USER")
        self.Screen.ScreenButton[4]:setSelected(BrowseHelper.getUserMode())

        -- update button 7
        self.Screen.ScreenButton[7]:setText(NI.HW.FEATURE.SCREEN_TYPE_STUDIO and "" or "FAVORITES")
        self.Screen.ScreenButton[7]:setVisible(true)
        self.Screen.ScreenButton[7]:setEnabled(true)
        self.Screen.ScreenButton[7]:setSelected(BrowseHelper.isFavoritesFilterEnabled())
        self.Screen.ScreenButton[7]:setAttribute(ATTR_FAVORITES_FILTER, "true")

        -- update load button

        local NumItems = BrowseHelper.getResultListSize()

        self.Screen.ScreenButton[8]:setText("LOAD")
        self.Screen.ScreenButton[8]:setVisible(true)
        self.Screen.ScreenButton[8]:setEnabled(NumItems > 0)
        self.Screen.ScreenButton[8]:setSelected(false)

    end

    -- base class
    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:updateScreenButtonPrevNextFileType()

    local ArrowIdx = 1
    local PrevButtonIdx = 1
    local NextButtonIdx = 2

    self.Screen:setArrowText(ArrowIdx, string.upper(BrowseHelper.getFileTypeName()).."S")

    local HasPrev, HasNext = BrowseHelper.hasPrevNextFileType(self.SamplingPage)

    self.Screen.ScreenButton[PrevButtonIdx]:setVisible(true)
    self.Screen.ScreenButton[NextButtonIdx]:setVisible(true)
    self.Screen.ScreenButton[PrevButtonIdx]:setEnabled(HasPrev)
    self.Screen.ScreenButton[NextButtonIdx]:setEnabled(HasNext)
    self.Screen.ScreenButton[PrevButtonIdx]:setSelected(false)
    self.Screen.ScreenButton[NextButtonIdx]:setSelected(false)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:updateScreenButtonPrevNextPreset()

    local ArrowIdx = 2
    local PrevButtonIdx = 5
    local NextButtonIdx = 6

    self.Screen:unsetArrowText(ArrowIdx)

    local FocusItem = BrowseHelper.getResultListFocusItem()
    local NumItems = BrowseHelper.getResultListSize()

    self.Screen.ScreenButton[PrevButtonIdx]:setText(NI.HW.FEATURE.SCREEN_TYPE_STUDIO and "PREVIOUS" or "PREV")
    self.Screen.ScreenButton[PrevButtonIdx]:setVisible(self.SamplingPage == nil)
    self.Screen.ScreenButton[PrevButtonIdx]:setSelected(false)
    self.Screen.ScreenButton[PrevButtonIdx]:setEnabled(FocusItem > 0 and NumItems > 0 and not self.SamplingPage)

    self.Screen.ScreenButton[NextButtonIdx]:setText(self.SamplingPage and "CANCEL" or "NEXT")
    self.Screen.ScreenButton[NextButtonIdx]:setVisible(true)
    self.Screen.ScreenButton[NextButtonIdx]:setSelected(false)
    self.Screen.ScreenButton[NextButtonIdx]:setEnabled((FocusItem < NumItems - 1 and NumItems > 0)
                                                       or (self.SamplingPage ~= nil))

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:updateScreenButtonRouting()

    local ButtonId = 3
    local FileType = BrowseHelper.getFileType()

    if FileType == NI.DB3.FILE_TYPE_GROUP then

        local Workspace = App:getWorkspace()
        self.Screen.ScreenButton[ButtonId]:setAttribute(ATTR_OVERRIDDEN, "true")
        self.Screen.ScreenButton[ButtonId]:setText("+ ROUTING")
        self.Screen.ScreenButton[ButtonId]:setVisible(true)
        self.Screen.ScreenButton[ButtonId]:setEnabled(true)
        self.Screen.ScreenButton[ButtonId]:setSelected(Workspace:getLoadGroupWithSoundRoutingParameter():getValue())

    else

        self.Screen.ScreenButton[ButtonId]:setVisible(false)
        self.Screen.ScreenButton[ButtonId]:setEnabled(false)

    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:updateScreenButtonPattern()

    local ButtonId = 4
    local FileType = BrowseHelper.getFileType()

    if FileType == NI.DB3.FILE_TYPE_GROUP then

        local Workspace = App:getWorkspace()
        self.Screen.ScreenButton[ButtonId]:setText(NI.HW.FEATURE.SCREEN_TYPE_STUDIO and "+ PATTERNS" or "+ PAT")
        self.Screen.ScreenButton[ButtonId]:setVisible(true)
        self.Screen.ScreenButton[ButtonId]:setEnabled(true)
        self.Screen.ScreenButton[ButtonId]:setSelected(Workspace:getLoadGroupWithPatternParameter():getValue())

    else

        self.Screen.ScreenButton[ButtonId]:setVisible(false)
        self.Screen.ScreenButton[ButtonId]:setEnabled(false)

    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:updateScreenButtonPrehear(ButtonId)

    if NI.DATA.SamplePrehearAccess.shouldShowPrehearWidget(App) then

        local Workspace = App:getWorkspace()
        self.Screen.ScreenButton[ButtonId]:setText("PREHEAR")
        self.Screen.ScreenButton[ButtonId]:setVisible(true)
        self.Screen.ScreenButton[ButtonId]:setEnabled(true)
        self.Screen.ScreenButton[ButtonId]:setSelected(Workspace:getPrehearEnabledParameter():getValue())

    else

        self.Screen.ScreenButton[ButtonId]:setVisible(false)
        self.Screen.ScreenButton[ButtonId]:setEnabled(false)

    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:updatePrehear(ForceUpdate)

    local Workspace = App:getWorkspace()
    if self.PrehearWidget then
        self.PrehearWidget:setActive(NI.DATA.SamplePrehearAccess.shouldShowPrehearWidget(App) and
                                      Workspace:getPrehearEnabledParameter():getValue())
    end

    if self.PrehearLabel then

        local PrehearEnabledParam = Workspace:getPrehearEnabledParameter()
        local PrehearVolumeParam = Workspace:getPrehearLevelParameter()

        if (PrehearEnabledParam:isChanged() or
            PrehearVolumeParam:isChanged() or
            ForceUpdate) then

            if PrehearEnabledParam:getValue() == false then
                self.PrehearLabel:setText("OFF")
            else
                local Volume = math.floor(PrehearVolumeParam:getValue() * 100.0 + 0.5)
                self.PrehearLabel:setText(""..Volume.."%")
            end

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:updateLeftRightButtonLEDs(CanLeft, CanRight)

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_LEFT, NI.HW.BUTTON_LEFT, CanLeft == nil and true or CanLeft)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_RIGHT, NI.HW.BUTTON_RIGHT, CanRight == nil and true or CanRight)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:toggleRoutingOption()

    local FileType = BrowseHelper.getFileType()

    if FileType == NI.DB3.FILE_TYPE_GROUP then
        BrowseHelper.toggleLoadGroupWithSoundRouting()
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:togglePatternOption()

    local FileType = BrowseHelper.getFileType()

    if FileType == NI.DB3.FILE_TYPE_GROUP then
        BrowseHelper.toggleLoadGroupWithPattern()
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:togglePrehearOption()

    if NI.DATA.SamplePrehearAccess.isPrehearTypeSelected(App) then
        BrowseHelper.togglePrehear()
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:loadFocusItemFromScreenButton(ButtonIdx)

    if BrowseHelper.getResultListSize() > 0 then
        -- call base class here already,
        -- to properly set LED states before page change
        PageMaschine.onScreenButton(self, ButtonIdx, true)

        -- load item
        self:loadFocusItem(false)
        self:updateScreens()
        return
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:loadFocusItem(KeepBrowsing)

    if self.SamplingPage then

        local ResultList     = App:getDatabaseFrontend():getBrowserModel():getResultListModel()
        local FocusItemIndex = ResultList:getFocusItem()

        NI.DATA.SamplerAccess.loadIntoNewZone(App, ResultList:getItemPath(FocusItemIndex))

        self:onShow(false)
        self.SamplingPage:onShow(true)

    elseif NI.APP.FEATURE.EFFECTS_CHAIN and BrowseHelper.getInsertMode() ~= NI.DATA.INSERT_MODE_OFF then

        if BrowseHelper.getInsertMode() == NI.DATA.INSERT_MODE_FRESH then
          BrowseHelper.setInsertMode(NI.DATA.INSERT_MODE_BROWSING)
          BrowseHelper.loadFocusItemInsertMode()
        else
          BrowseHelper.loadFocusItem()
        end

        if not KeepBrowsing then
          BrowseHelper.closeInsertMode()
        end

    else

        BrowseHelper.loadFocusItem()

    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:onScreenButton(ButtonIdx, Pressed)

    if BrowseHelper.isBusy() then
        return
    end

    if Pressed then

        if self.Controller:getShiftPressed() then

            if ButtonIdx == 1 or ButtonIdx == 2 then

                BrowseHelper.setProductsSortOrder(ButtonIdx == 1
                    and NI.DB3.ProductModel.BY_CATEGORY
                    or  NI.DB3.ProductModel.BY_VENDOR)

            end

        else

            if ButtonIdx == 3 then

                if self:isQuickBrowseEnabled() then
                    BrowseHelper.onLocate()
                end

            elseif ButtonIdx == 4 then

                BrowseHelper.toggleUserMode()

            elseif ButtonIdx == 7 then

                BrowseHelper.toggleFavoritesFilter()

            elseif ButtonIdx == 8 then

                self:loadFocusItemFromScreenButton(ButtonIdx)

            end

        end

    end

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:onScreenButtonPrevNextFileType(ButtonIdx)

    local PrevButtonIdx = 1
    local NextButtonIdx = 2

    if ButtonIdx ~= PrevButtonIdx and ButtonIdx ~= NextButtonIdx then
        return
    end

    local HasPrev, HasNext = BrowseHelper.hasPrevNextFileType(self.SamplingPage)
    if (ButtonIdx == PrevButtonIdx and HasPrev) or (ButtonIdx == NextButtonIdx and HasNext) then

        -- call base class first, since selectPrevOrNextVisibleFileType unfortunately calls an immediate update
        PageMaschine.onScreenButton(self, ButtonIdx, true)

        BrowseHelper.selectPrevOrNextVisibleFileType(ButtonIdx == NextButtonIdx)
        self:updateScreens()

    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:onScreenButtonPrevNextPreset(ButtonIdx)

    local PrevButtonIdx = 5
    local NextButtonIdx = 6

    if ButtonIdx ~= PrevButtonIdx and ButtonIdx ~= NextButtonIdx then
        return
    end

    if self.SamplingPage then

        if ButtonIdx == NextButtonIdx then  -- CANCEL
            self:onShow(false)
            self.SamplingPage:onShow(true)
        end

    else

        BrowseHelper.offsetResultListFocusBy(ButtonIdx == PrevButtonIdx and -1 or 1)

        if BrowseHelper.canPrehear() then
            NI.DATA.SamplePrehearAccess.playLastDatabaseBrowserSelection(App)
        else
            self:loadFocusItem(true)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:onPageButton(Button, PageID, Pressed)

    local ShiftPressed        = self.Controller:getShiftPressed()
    local EnterModulePage     = Pressed and Button == NI.HW.BUTTON_BROWSE and ShiftPressed
    local ReleaseOnBrowsePage = not Pressed and Button == NI.HW.BUTTON_BROWSE

    if NI.APP.FEATURE.EFFECTS_CHAIN and not (EnterModulePage or ReleaseOnBrowsePage) then
        BrowseHelper.setInsertMode(NI.DATA.INSERT_MODE_OFF)
    end

    -- call base class
    return PageMaschine.onPageButton(self, Button, PageID, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:onPadEvent(PadIndex, Trigger, PadValue)

    if Trigger then
        BrowseHelper.prehearViaPad(PadIndex)
    end

    PageMaschine.onPadEvent(self, PadIndex, Trigger, PadValue)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:canFocusSoundOnPadTrigger()

    return Page.canFocusSoundOnPadTrigger(self) and not BrowseHelper.isPadPrehearEnabled()

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageBase:canDeleteFiles()

    return false

end

------------------------------------------------------------------------------------------------------------------------
