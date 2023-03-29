------------------------------------------------------------------------------------------------------------------------
-- Page that displays browser.
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/KompleteKontrolS/Pages/ParameterPageBase"
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BPU_Attribute"
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BPU_Bank"
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BPU_FavoritesFilter"
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BPU_FavoritesSetter"
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BPU_PrehearSetter"
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BPU_PrehearVolume"
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BPU_Preset"
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BPU_Product"
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BPU_ProductGroup"
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BPU_ProductSorting"
require "Scripts/Maschine/KompleteKontrolS/Pages/BrowsePage/Units/BPU_UserModeAndFileType"
require "Scripts/Shared/Helpers/BrowseHelper"

------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------

-- Common units
USER_MODE = 0
PRODUCT_GROUP = 1
PRODUCT = 2
BANK = 3
SUB_BANK = 4
TYPE = 5
SUB_TYPE = 6
MODE = 7
PRESET = 8

-- Shift Units
PRODUCT_SORTING = 1
FAVORITES_FILTER = 3
FAVORITES_SETTER = 4
PREHEAR_SETTER = 7
PREHEAR_VOLUME = 8

ATTRIBUTE_COLUMN_TYPE = NI.DB3.AttributesModel.ATTRIBUTE_COLUMN_TYPE
ATTRIBUTE_COLUMN_SUBTYPE = NI.DB3.AttributesModel.ATTRIBUTE_COLUMN_SUBTYPE
ATTRIBUTE_COLUMN_MODE = NI.DB3.AttributesModel.ATTRIBUTE_COLUMN_MODE

BANK_CHAIN_ENTRY_1 = NI.DB3.BankChainModel.BANK_CHAIN_ENTRY_1
BANK_CHAIN_ENTRY_2 = NI.DB3.BankChainModel.BANK_CHAIN_ENTRY_2
BANK_CHAIN_ENTRY_3 = NI.DB3.BankChainModel.BANK_CHAIN_ENTRY_3

------------------------------------------------------------------------------------------------------------------------
-- Page that displays a hardware browser.
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowsePage = class( 'BrowsePage', ParameterPageBase )

function BrowsePage:__init(Controller)

    ParameterPageBase.__init(self, Controller)

    self.CommonUnits = {}
    self.CommonUnits[USER_MODE]     = BPU_UserModeAndFileType (USER_MODE,     self)
    self.CommonUnits[PRODUCT_GROUP] = BPU_ProductGroup        (PRODUCT_GROUP, self)
    self.CommonUnits[PRODUCT]       = BPU_Product             (PRODUCT,       self)
    self.CommonUnits[BANK]          = BPU_Bank                (BANK,          self, BANK_CHAIN_ENTRY_2, "Banks")
    self.CommonUnits[SUB_BANK]      = BPU_Bank                (SUB_BANK,      self, BANK_CHAIN_ENTRY_3, "Subbanks")
    self.CommonUnits[TYPE]          = BPU_Attribute           (TYPE,          self, ATTRIBUTE_COLUMN_TYPE, "Types")
    self.CommonUnits[SUB_TYPE]      = BPU_Attribute           (SUB_TYPE,      self, ATTRIBUTE_COLUMN_SUBTYPE, "Subtypes")
    self.CommonUnits[MODE]          = BPU_Attribute           (MODE,          self, ATTRIBUTE_COLUMN_MODE, "Characters")
    self.CommonUnits[PRESET]        = BPU_Preset              (PRESET,        self)

    self.ShiftUnits = {}
    self.ShiftUnits[USER_MODE]        = BPU_UserModeAndFileType   (USER_MODE,    self)
    self.ShiftUnits[PRODUCT_SORTING]  = BPU_ProductSorting    (PRODUCT_SORTING,  self)
    self.ShiftUnits[FAVORITES_FILTER] = BPU_FavoritesFilter   (FAVORITES_FILTER, self)
    self.ShiftUnits[FAVORITES_SETTER] = BPU_FavoritesSetter   (FAVORITES_SETTER, self)

    self.ShiftUnits[PREHEAR_SETTER]   = BPU_PrehearSetter (PREHEAR_SETTER,   self)
    self.ShiftUnits[PREHEAR_VOLUME]   = BPU_PrehearVolume (PREHEAR_VOLUME,   self)

    self.Units = self.CommonUnits

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onActivate()

    NHLController:setEncoderMode(NI.HW.ENC_MODE_NONE)
    self.Units = self.CommonUnits

    HELPERS.acquireEncoderControl(App)

    self:updateScreen()

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onDeactivate()

    HELPERS.releaseEncoderControl(App)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onEncoderEvent(EncoderID, Value)

    if self.Units[EncoderID + 1] then
        self.Units[EncoderID + 1]:onEncoderChanged(Value)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onShiftButton(Pressed)

    if Pressed then
        self.Units = self.ShiftUnits
    else
        self.Units = self.CommonUnits
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onPageButton(Pressed, Next)

    if self.Units[USER_MODE] then
        self.Units[USER_MODE]:onPageButton(Pressed, Next)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onWheelEvent(Delta)

    local isInstancesVisible = App:getOnScreenOverlay():isInstancesVisible()

    if isInstancesVisible then
        ParameterPageBase.onWheelEvent(self, Delta)
    elseif not self.Controller:isShiftPressed() then
        self:advanceResultListFocus(Delta)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:advanceResultListFocus(Delta)

    local DatabaseFrontend = App:getDatabaseFrontend()
    local BrowserController = DatabaseFrontend:getBrowserController()
    local ResultListModel = DatabaseFrontend:getBrowserModel():getResultListModel()

    local ItemCount = ResultListModel:getItemCount()
    local FocusItem = ResultListModel:getFocusItem()
    local NextItem = BrowseUtils.advanceIndex(FocusItem, Delta, ItemCount, false)
    local HasFocusItemChanged = FocusItem ~= NextItem

    BrowserController:changeResultListFocus(NextItem - FocusItem, false, NI.DB3.BrowserController.SOURCE_DEFAULT, false)

    if BrowseHelper.canPrehear() and HasFocusItemChanged then
        NI.DATA.SamplePrehearAccess.playLastDatabaseBrowserSelection(App)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onWheelButton(Pushed)

    if App:getOnScreenOverlay():isInstancesVisible() then

        ParameterPageBase.onWheelButton(self, Pushed)

    elseif self.Controller:isShiftPressed() and Pushed then

        BrowseHelper.toggleFocusItemFavoriteState()

    else

        self:onNavEnterButton(Pushed)

    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:onNavEnterButton(Pressed)

    local ResultListModel = App:getDatabaseFrontend():getBrowserModel():getResultListModel()

    if App:getOnScreenOverlay():isInstancesVisible() then

        ParameterPageBase.onNavEnterButton(self, Pressed)

    elseif ResultListModel:getItemCount() > 0 and Pressed then

        local BrowserController = App:getDatabaseFrontend():getBrowserController()
        BrowserController:loadSelectedResultListItem(App, false)

        local PageParameter = App:getWorkspace():getKKPerformPageParameter()
        NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, PageParameter, HW.PAGE_PLUGIN)

        self.Controller:popToBottomPage()

    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:updateScreen()

    self:clearScreen()

    ----- Unit 0 -----

    -- check if display mode is supported on browse page
    local DisplayMode = self.Controller:getDisplayMode()
    if DisplayMode == DISPLAY_MODE_OCTAVE or
       DisplayMode == DISPLAY_MODE_GROUPSOUND_NAV then

        ParameterPageBase.updatePagePresetDisplay(self)

    elseif self.Units[USER_MODE] then

        self.Units[USER_MODE]:draw()

    end

    ----- Other units -----

    for Unit = 1, NI.HW.NUM_SECTIONS - 1 do

        if self.Units[Unit] then
            self.Units[Unit]:draw()
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePage:updateLEDs()

    ParameterPageBase.updateLEDs(self)

    LEDHelper.updateButtonLED(self.Controller, HW.BUTTON_NAVIGATE_BACK, HW.BUTTON_NAVIGATE_BACK, true)
    LEDHelper.updateButtonLED(self.Controller, HW.LED_NAVIGATE_ENTER, HW.BUTTON_NAVIGATE_ENTER, true)
    LEDHelper.setLEDState(HW.LED_NAVIGATE_BROWSE, LEDHelper.LS_BRIGHT)

    if self.Units[USER_MODE] then
        self.Units[USER_MODE]:updateLEDs()
    end

end
