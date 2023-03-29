------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/BrowsePageBase"
require "Scripts/Shared/Pages/BrowsePage"
require "Scripts/Shared/Components/ScreenMaschineStudio"
require "Scripts/Shared/Components/InfoBar"
require "Scripts/Shared/Helpers/ResourceHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowsePageColorDisplayBase = class( 'BrowsePageColorDisplayBase', BrowsePageBase )

local STACK_RESULTS = 0
local STACK_TAGS = 1
local ATTR_ALL = NI.UTILS.Symbol("all")
local ATTR_FAVORITES_FILTER = NI.UTILS.Symbol("FavoritesFilter")
local ATTR_USE_BRACKETS = NI.UTILS.Symbol("UseBrackets")
local ATTR_SOUNDSDOTCOM = NI.UTILS.Symbol("soundsdotcom")

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:__init(Name, Controller, SamplingPage)

    BrowsePageBase.__init(self, Name, Controller, SamplingPage)

    self.FocusParam = PARAM_RESULTS -- result list is the default param

    self.UserIconPathSamples = ""
    self.UserIconPathFX = ""
    self.SoundsDotComIconPath = ""
    self.PostDB3Update = false

    self.GetParamAllCaption = {}
    self.GetParamAllCaption[PARAM_PRODUCT_GROUPS] = function()
        return BrowseHelper.getProductsSortOrder() == NI.DB3.ProductModel.BY_CATEGORY and "All Categories" or "All Vendors"
    end
    self.GetParamAllCaption[PARAM_BC1] = function() return "All Products" end
    self.GetParamAllCaption[PARAM_BC2] = function() return "All Banks" end
    self.GetParamAllCaption[PARAM_BC3] = function() return "All Sub-Banks" end
    self.GetParamAllCaption[PARAM_ATTR1] = function() return "All Types" end
    self.GetParamAllCaption[PARAM_ATTR2] = function() return "All Sub-Types" end
    self.GetParamAllCaption[PARAM_ATTR3] = function()
        local FileType = BrowseHelper.getFileType()
        if BrowseHelper.supportsModes(FileType) then
            return "All Characters"
        else
            return "All Sub-Types"
        end
    end
    self.GetParamAllCaption[PARAM_RESULTS] = function() return "" end

    self.GetParamNameFunctors = {}
    self.GetParamNameFunctors[PARAM_PRODUCT_GROUPS] = function()
        return BrowseHelper.getProductsSortOrder() == NI.DB3.ProductModel.BY_CATEGORY and "Category" or "Vendor"
    end
    self.GetParamNameFunctors[PARAM_BC1] = function() return "Product" end
    self.GetParamNameFunctors[PARAM_BC2] = function() return "Bank" end
    self.GetParamNameFunctors[PARAM_BC3] = function() return "SubBank" end
    self.GetParamNameFunctors[PARAM_ATTR1] = function() return "Type" end
    self.GetParamNameFunctors[PARAM_ATTR2] = function() return "Subtype" end
    self.GetParamNameFunctors[PARAM_ATTR3] = function() return "Character" end
    self.GetParamNameFunctors[PARAM_RESULTS] = function() return "Preset" end

    -- create screen
    self:setupScreen()
end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:setupScreen()

    -- setup screen
    self.Screen = ScreenMaschineStudio(self)

    self.Screen:styleScreen(self.Screen.ScreenLeft, {"<<", ">>", "LOCATE", "USER"}, "HeadButton", false, false)

    self.Screen.ScreenButton[3]:setStyle("BrowseIcon")

    if self.SamplingPage then
        self.Screen:styleScreen(self.Screen.ScreenRight, {"", "CANCEL", "", "LOAD"}, "HeadButton", false, false)
    else
        self.Screen:styleScreen(self.Screen.ScreenRight, {"<<", ">>", "", "LOAD"}, "HeadButton", false, false)

        self.Screen.ScreenButton[5]:style("PREVIOUS", "PreviousButton")
        self.Screen.ScreenButton[6]:style("NEXT", "NextButton")
    end

    self.ParamLabels = {}

    self.ParamBarLeft = ScreenHelper.createBarWithLabels(self.Screen.ScreenLeft, self.ParamLabels, {"", "", "", ""}, "BrowserParamBar", "BrowserParam")
    self.ParamBarRight = ScreenHelper.createBarWithLabels(self.Screen.ScreenRight, self.ParamLabels, {"", "", "", ""}, "BrowserParamBar", "BrowserParam")

    -- insert product list vector
    self.ProductList = NI.GUI.insertProductRowVector(self.Screen.ScreenLeft.DisplayBar, "ProductList")
    self.ProductList:style(false, '')
    self.Screen.ScreenLeft.DisplayBar:setFlex(self.ProductList)

    self.ProductList:getScrollbar():setAutohide(false)
    self.ProductList:getScrollbar():setShowIncDecButtons(false)

    self.ProductBG = NI.GUI.insertPictureBar(self.Screen.ScreenRight.DisplayBar, "ProductBG")
    self.ProductBG:style(NI.GUI.ALIGN_WIDGET_DOWN, "ProductBG")
    self.ProductBG:setNoAlign(true)

    self.ProductStack = NI.GUI.insertStack(self.Screen.ScreenRight.DisplayBar, "ProductStack")
    self.Screen.ScreenRight.DisplayBar:setFlex(self.ProductStack)

    -- Results............................................................................

    self.ResultsFrame = NI.GUI.insertBar(self.ProductStack, "ProductBar")
    self.ResultsFrame:style(NI.GUI.ALIGN_WIDGET_RIGHT, "ProductBG")

    -- insert big ass Logo (Text)
    self.ProductLogo = NI.GUI.insertMultilineTextEdit(self.ResultsFrame, "ProductLogo")
    self.ProductLogo:style("ProductLogo")

    -- insert result list vector
    self.ResultList = NI.GUI.insertResultListItemVector(self.ResultsFrame, "ResultList")
    self.ResultList:style(false, '')
    self.ResultsFrame:setFlex(self.ResultList)

    self.ResultList:getScrollbar():setAutohide(false)
    self.ResultList:getScrollbar():setShowIncDecButtons(false)

    self.IconBar = NI.GUI.insertBar(self.ResultsFrame, "IconBar")
    self.IconBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")

    -- insert prehear icon overlay
    self.PrehearWidget = NI.GUI.insertLabel(self.IconBar, "PrehearIcon")
    self.PrehearWidget:style("", "PrehearIcon")

    self.ScanWidget = NI.GUI.insertAnimation(self.IconBar, "ScanIcon")
    self.ScanWidget:style("")

    -- Capacitive Tags....................................................................

    self.CapacitiveTagBrowser = NI.GUI.insertTagBrowser(self.ProductStack, App, "TagBrowser")
    self.CapacitiveTagBrowser:style("TagBrowser", '')

    -- connect vector to functions
    NI.GUI.connectVector(self.ResultList,
        BrowseHelper.getResultListSize, BrowseHelper.setupResultItem, BrowseHelper.loadResultItem)

    NI.GUI.connectVector(self.ProductList,
        function() return BrowsePageColorDisplayBase.getProductListSize(self) end, BrowsePageColorDisplayBase.setupProductItem,
        function (Row,Index) BrowsePageColorDisplayBase.loadProductItem(self, Row, Index) end)

    self.ProductStack:setTop(self.ResultsFrame)

    for Index = 1, 8 do
        self.ParamLabels[Index]:setAttribute(ATTR_USE_BRACKETS, "true")
    end

end

------------------------------------------------------------------------------------------------------------------------
-- ProductList vector callbacks
------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getProductListSize()

    local NumProducts = BrowseHelper.getProductCount()

    if NumProducts then
        return math.floor((NumProducts + 5) / 6) * 2 --Entire Pages of 6 Product Icons
    end

    return 0

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase.setupProductItem(ProductRow)
    NI.GUI.enableCropModeForLabel(ProductRow:getLabel(0))
    NI.GUI.enableCropModeForLabel(ProductRow:getLabel(1))
    NI.GUI.enableCropModeForLabel(ProductRow:getLabel(2))
end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:loadProductItem(ProductRow, RowIndex)

    local NumProducts = BrowseHelper.getProductCount()
    local SelectedItem = BrowseHelper.getFocusProductIndex()

    for Column = 0, 2 do

        local Bar = ProductRow:getBar(Column)
        local Label = ProductRow:getLabel(Column)
        local Icon = ProductRow:getIcon(Column)
        local ProductIndex = RowIndex * 3 + Column
        local Name = BrowseHelper.getProductName(ProductIndex)

        if ProductIndex < NumProducts and Name then

            local Selected = SelectedItem ~= NPOS and ProductIndex == SelectedItem
            local FallbackName = self:getProductDisplayName(Name)
            local ShortName = ResourceHelper.getVBShortName(Name, FallbackName)

            -- label
            Label:setVisible(true)
            Label:setSelected(Selected)
            Label:setText(ShortName or Name)

            -- Bar
            Bar:setSelected(Selected)
            Bar:setVisible(true)

            -- Icon
            Icon:setVisible(true)

            local Picture = self:getProductPicture(Name)
            if Picture then
                Icon:setPicture(Picture)
            else
                Icon:resetPicture()
            end
        else

            Bar:setVisible(false)

        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getProductPicture(Name)

    local IconPath = ResourceHelper.getBrowserIcon(Name)
    local Picture = IconPath and NI.UTILS.PictureManager.getPictureOrLoadFromDisk(IconPath, false)

    if Picture then
        return Picture
    end

    -- sounds.com content matched on name or vendor
    if string.match(Name, "Sounds.com") then

        IconPath = self.SoundsDotComIconPath

    elseif BrowseHelper.getUserMode() then

        IconPath = self:getFallbackProductPicturePathForUserMode()

    end

    Picture = IconPath and IconPath ~= "" and NI.UTILS.PictureManager.getPictureOrLoadFromDisk(IconPath, true)

    return Picture
end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getFallbackProductPicturePathForUserMode()

    local FileType = BrowseHelper.getFileType()

    if FileType == NI.DB3.FILE_TYPE_LOOP_SAMPLE then
        return self.UserIconPathLoops
    elseif FileType == NI.DB3.FILE_TYPE_ONESHOT_SAMPLE then
        return self.UserIconPathSamples
    elseif FileType == NI.DB3.FILE_TYPE_INSTRUMENT or FileType == NI.DB3.FILE_TYPE_EFFECT then
        return self.UserIconPathFX
    else
        return ""
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getProductDisplayName(VendorizedName)

    return BrowseHelper.extractProductName(VendorizedName)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:onShow(Show)

    if Show then
        self.Controller.CapacitiveList:setStyle("CapacitiveOverlayBrowser")
        self:showTagBrowser(false)

        local CustomCapEnabledFunc = function(Cap) return BrowsePageColorDisplayBase.isCustomCapEnabled(self, Cap) end
        self.Controller.CapacitiveList:setCustomCapEnabledFunc(CustomCapEnabledFunc)

        local ShowTagBrowserFunc = function(Show, FocusCap) BrowsePageColorDisplayBase.showTagBrowser(self, Show, FocusCap) end
        self.Controller.CapacitiveList:setCustomShowListFunc(ShowTagBrowserFunc)
    end

    BrowsePageBase.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:updateScreens(ForceUpdate)

    if BrowseHelper.isBusy() and not ForceUpdate then
        return
    end

    if ForceUpdate then

        BrowseHelper.forceCacheRefresh()

        self:refreshCapacitiveList(PARAM_PRODUCT_GROUPS)
        self:refreshCapacitiveList(PARAM_BC2)
        self:refreshCapacitiveList(PARAM_BC3)

        self.ResultList:forceAlign() --necessary
        self.ProductList:forceAlign() --necessary

        self:updateProductCategories()
        self:updateBankParams(true)
        self:updateTypeParams()
        self:updateResultList()

        self:checkFocusParamValidity()

        self.UserIconPathSamples = self.ProductList:getStringProperty("user-icon-path-samples", "")
        self.UserIconPathLoops = self.ProductList:getStringProperty("user-icon-path-loops", "")
        self.UserIconPathFX = self.ProductList:getStringProperty("user-icon-path-fx", "")
        self.SoundsDotComIconPath = self.ProductList:getStringProperty("soundsdotcom-icon-path", "")
    end

    -- insert mode: force file type according to insert slot
    if NI.APP.FEATURE.EFFECTS_CHAIN and BrowseHelper.getInsertMode() == NI.DATA.INSERT_MODE_FRESH then
        if not BrowseHelper.isCurrentFileTypeInsertModeValid() then
            BrowseHelper.closeInsertMode()
        end
    end

    -- update Sample Browse Mode
    if self.SamplingPage then
        self:updateSampleBrowser(ForceUpdate)
    end

    -- update prehear icon
    self:updatePrehear(ForceUpdate)

    self.ScanWidget:setActive(App:getWorkspace():getDatabaseScanInProgressParameter():getValue())

    -- update Focus Param
    for Index = 1, 8 do
        self.ParamLabels[Index]:setSelected(Index == self.FocusParam)
    end

    self:updateLeftRightButtonLEDs()

    -- base class
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:updateScreenButtons(ForceUpdate)

    if BrowseHelper.isBusy() then
        return
    end

    if self.Controller:getShiftPressed() then

        if NI.APP.isNativeOS() then
            self:updateRescanButton()
        else
            self:updateScreenButtonCategoryAndVendor()
        end
        self:updateScreenButtonRouting()

        if BrowseHelper.getFileType() == NI.DB3.FILE_TYPE_GROUP then
            self:updateScreenButtonPattern()
        elseif NI.APP.FEATURE.ACCESSIBILITY or NHLController:isExternalAccessibilityRunning() then
            self:updateScreenButtonSpeakPreset()
        end

        self:updateScreenButtonFavouritesFilter()
        self:updateScreenButtonPrehear(PARAM_RESULTS)

    end

    BrowsePageBase.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:updateRescanButton()

    local RescanButtonID = 1

    local ArrowId = 1
    self.Screen:unsetArrowText(ArrowId, "RESCAN", "")
    self.Screen.ScreenButton[RescanButtonID]:setVisible(true)
    self.Screen.ScreenButton[RescanButtonID]:setEnabled(not App:getWorkspace():getDatabaseScanInProgressParameter():getValue())

    self.Screen.ScreenButton[RescanButtonID + 1]:setVisible(false) -- required for this "arrow" style, otherwise
                                                                   -- screen button #2 is visible

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:updateScreenButtonCategoryAndVendor()

    local ArrowId = 1
    local CategoryButtonId = 1
    local VendorButtonId = 2
    local isCategory = BrowseHelper.getProductsSortOrder() == NI.DB3.ProductModel.BY_CATEGORY
    local isInstrumentsOrEffects = BrowseHelper.isInstrumentsOrEffectsFileType()

    self.Screen:unsetArrowText(ArrowId, "CATEGORIES", "VENDORS")
    self.Screen.ScreenButton[CategoryButtonId]:setVisible(isInstrumentsOrEffects)
    self.Screen.ScreenButton[VendorButtonId]:setVisible(isInstrumentsOrEffects)
    self.Screen.ScreenButton[CategoryButtonId]:setEnabled(isInstrumentsOrEffects)
    self.Screen.ScreenButton[VendorButtonId]:setEnabled(isInstrumentsOrEffects)

    self.Screen.ScreenButton[CategoryButtonId]:setSelected(isCategory)
    self.Screen.ScreenButton[VendorButtonId]:setSelected(not isCategory)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:updateScreenButtonPrevNextSlot()

    local ArrowId = 2
    local PrevButtonId = 5
    local NextButtonId = 6

    if self.SamplingPage then
        self.Screen:unsetArrowText(ArrowId)
    else
        self.Screen:setArrowText(ArrowId, MaschineHelper.getFocusPluginSlotName())
    end

    self.Screen.ScreenButton[PrevButtonId]:setVisible(self.SamplingPage == nil)
    self.Screen.ScreenButton[PrevButtonId]:setEnabled(self.SamplingPage == nil and BrowseHelper.hasPrevNextPluginSlot(false))
    self.Screen.ScreenButton[PrevButtonId]:setSelected(false)

    self.Screen.ScreenButton[NextButtonId]:setVisible(true)
    self.Screen.ScreenButton[NextButtonId]:setEnabled(self.SamplingPage ~= nil or BrowseHelper.hasPrevNextPluginSlot(true))
    self.Screen.ScreenButton[NextButtonId]:setSelected(false)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:updateScreenButtonSpeakPreset()

    local ButtonId = 4
    local AccessibilityEnabled = App:getSpeechSynthesizer():getEnabled() or NHLController:isExternalAccessibilityRunning()
    local SpeakPresetEnabled = NI.DATA.WORKSPACE.getAccessibilitySpeakPreset(App)

    self.Screen.ScreenButton[ButtonId]:setEnabled(AccessibilityEnabled)
    self.Screen.ScreenButton[ButtonId]:setSelected(AccessibilityEnabled and SpeakPresetEnabled)
    self.Screen.ScreenButton[ButtonId]:setVisible(AccessibilityEnabled)
    self.Screen.ScreenButton[ButtonId]:setText("SPEAK PRESET")

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:updateScreenButtonFavouritesFilter()

    local ButtonId = 7

    self.Screen.ScreenButton[ButtonId]:setText("SET ★")
    self.Screen.ScreenButton[ButtonId]:setVisible(true)
    self.Screen.ScreenButton[ButtonId]:setEnabled(BrowseHelper.getResultListSize() > 0)
    self.Screen.ScreenButton[ButtonId]:setSelected(false)
    self.Screen.ScreenButton[ButtonId]:setAttribute(ATTR_FAVORITES_FILTER, "false")

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:updatePresetButtonLEDs()

    local CanPreset = BrowseHelper.getResultListSize() > 0

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_NAVIGATE_PRESET_UP, NI.HW.BUTTON_NAVIGATE_PRESET_UP, CanPreset)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_NAVIGATE_PRESET_DOWN, NI.HW.BUTTON_NAVIGATE_PRESET_DOWN, CanPreset)

end


------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:onNavPresetButton(Pressed, Previous)

    if not Pressed or BrowseHelper.getResultListSize() == 0 then
        return
    end

    BrowseHelper.offsetResultListFocusBy(Previous and -1 or 1)

    self:loadFocusItem(true)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:onScreenButton(ButtonIdx, Pressed)

    if Pressed and self.Controller:getShiftPressed() then

        if NI.APP.isNativeOS() and ButtonIdx == 1 then

            NI.DATA.DB3Access.rescanAllContentPaths(App)

        elseif ButtonIdx == 3 then

            self:toggleRoutingOption()

        elseif ButtonIdx == 4 then

            if BrowseHelper.getFileType() == NI.DB3.FILE_TYPE_GROUP then
                self:togglePatternOption()
            elseif NI.APP.FEATURE.ACCESSIBILITY or NHLController:isExternalAccessibilityRunning() then
                local SpeakPresetEnabled = NI.DATA.WORKSPACE.getAccessibilitySpeakPreset(App)
                NI.DATA.WORKSPACE.setAccessibilitySpeakPreset(App, not SpeakPresetEnabled)
            end

        elseif ButtonIdx == 6 then

            if self.SamplingPage then   -- CANCEL
                self:onShow(false)
                self.SamplingPage:onShow(true)
            end

        elseif ButtonIdx == 7 then

            BrowseHelper.toggleFocusItemFavoriteState()

        elseif ButtonIdx == 8 then

            self:togglePrehearOption()

        end

    end

    BrowsePageBase.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:refreshCapacitiveList(ParamIndex)

    local List = BrowseHelper.getParamCachedList(ParamIndex)
    local FocusIndex = BrowseHelper.getParamIndex(ParamIndex)

    self.Controller.CapacitiveList:assignListToCap(ParamIndex, List)
    self.Controller.CapacitiveList:setListFocusItem(ParamIndex, FocusIndex)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:updateProductCategories()

    local GroupName = BrowseHelper.getParamContent(PARAM_PRODUCT_GROUPS, BrowseHelper.getParamIndex(PARAM_PRODUCT_GROUPS))
    local isCategory = BrowseHelper.getProductsSortOrder() == NI.DB3.ProductModel.BY_CATEGORY
    local ShortNameKey = isCategory and "NIProductCategory" or "ProductVendor"

    if BrowseHelper.getParamCount(PARAM_PRODUCT_GROUPS) == 0 then
        self.ParamLabels[PARAM_PRODUCT_GROUPS]:setText("")
    elseif GroupName and GroupName ~= "All..." then
        local ShortName = ResourceHelper.getShortName(ShortNameKey.."|"..GroupName, GroupName)
        -- Special shortname for NI
        self.ParamLabels[PARAM_PRODUCT_GROUPS]:setText(GroupName == "Native Instruments" and "NI" or ShortName)
        self.ParamLabels[PARAM_PRODUCT_GROUPS]:setAttribute(ATTR_ALL, "false")
    else
        self.ParamLabels[PARAM_PRODUCT_GROUPS]:setText(self.GetParamAllCaption[PARAM_PRODUCT_GROUPS]())
        self.ParamLabels[PARAM_PRODUCT_GROUPS]:setAttribute(ATTR_ALL, "true")
    end

    if self:isShowingTagBrowser() then
        self.Controller.CapacitiveList:reset(false)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:updateBankParams(ForceUpdate)

    self.ProductList:getScrollbar():setVisible(BrowseHelper.getProductCount() > 6)
    self.ProductList:setAlign()

    --....................................................................................
    -- BC1 (Products)
    local BC1Index = BrowseHelper.getFocusProductIndex()
    BC1Index = BC1Index == NPOS and NPOS or (BC1Index + 1)

    local VendorAndName = BrowseHelper.getProductName(BC1Index-1) or ""
    local ProductName = self:getProductDisplayName(VendorAndName)

    if BrowseHelper.getProductCount() == 0 then
        self.ParamLabels[PARAM_BC1]:setText("")
        self.ProductLogo:setText("")
        self.ParamLabels[PARAM_BC1]:setEnabled(false)
        self.ParamLabels[PARAM_BC1]:setAttribute(ATTR_ALL, "false")

    else
        local Name = BC1Index == NPOS and self.GetParamAllCaption[PARAM_BC1]() or ProductName
        local ShortName = ResourceHelper.getShortName(Name)

        self.ParamLabels[PARAM_BC1]:setText(ShortName)
        self.ParamLabels[PARAM_BC1]:setEnabled(true)
        self.ParamLabels[PARAM_BC1]:setAttribute(ATTR_ALL, BC1Index == NPOS and "true" or "false")

        local Logo = ResourceHelper.getLogo(VendorAndName)
        if Logo and Logo ~= "" then

            local Picture = NI.UTILS.PictureManager.getPictureOrLoadFromDisk(Logo, false)
            self.ProductBG:setPicture(Picture)
            self.ProductLogo:setText("")
        else
            self.ProductBG:resetPicture()
            self.ProductLogo:setText(BC1Index == NPOS and "" or Name)
        end

        self.ProductBG:setAttribute(ATTR_SOUNDSDOTCOM, "false")
        local BGColor = ResourceHelper.getColor(VendorAndName)
        if BGColor and BGColor ~= "" then
            self.ProductBG:setBGColor(BGColor)
        else
            local Vendor = VendorAndName:match("|(.+)|")
            if Vendor and Vendor:find("Sounds.com") then
                self.ProductBG:setAttribute(ATTR_SOUNDSDOTCOM, "true")
            end
            self.ProductBG:resetBGColor()
        end

        self.ProductBG:setAlign()

        local VectorOffset = BC1Index == NPOS and 0 or (math.floor((BC1Index-1) / 6)) * 2

        if ForceUpdate then
            self.ProductList:setItemOffset(VectorOffset, 0, 0)
        else
            self.ProductList:setItemOffset(VectorOffset)
        end
    end

    --....................................................................................
    -- BC2
    local BC2Index = BrowseHelper.getParamIndex(PARAM_BC2)
    local BC2Name = BrowseHelper.getParamContent(PARAM_BC2, BC2Index)

    if BrowseHelper.getParamCount(PARAM_BC2) == 0 or BC1Index == NPOS then
        self.ParamLabels[PARAM_BC2]:setText("")
    else
        local Name = BC2Index == NPOS and self.GetParamAllCaption[PARAM_BC2]() or
            ResourceHelper.getShortName(VendorAndName.."|"..BC2Name, BC2Name)

        self.ParamLabels[PARAM_BC2]:setText(Name)
        self.ParamLabels[PARAM_BC2]:setAttribute(ATTR_ALL, BC2Index == NPOS and "true" or "false")
    end

    --....................................................................................
    -- BC3
    local BC3Index = BrowseHelper.getParamIndex(PARAM_BC3)
    local BC3Name = BrowseHelper.getParamContent(PARAM_BC3, BC3Index)

    if BrowseHelper.getParamCount(PARAM_BC3) == 0 or BC1Index == NPOS or BC2Index == NPOS then
        self.ParamLabels[PARAM_BC3]:setText("")
    else

        local Name = BC3Index == NPOS and self.GetParamAllCaption[PARAM_BC3]() or
            ResourceHelper.getShortName(VendorAndName.."|"..BC2Name.."|"..BC3Name, BC3Name)

        self.ParamLabels[PARAM_BC3]:setText(Name)
        self.ParamLabels[PARAM_BC3]:setAttribute(ATTR_ALL, BC3Index == NPOS and "true" or "false")
    end

    if self:isShowingTagBrowser() then
        self.Controller.CapacitiveList:reset(false)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:updateTypeParams()

    for Index = 0, 2 do

        local ItemCount = BrowseHelper.getParamCount(PARAM_ATTR1 + Index)
        local Multi = BrowseHelper.getParamMulti(PARAM_ATTR1 + Index)
        local ParamLabel = self.ParamLabels[PARAM_ATTR1 + Index]

        -- check if we need to close the tagbrowser
        if self:isShowingTagBrowser() and self.Controller.CapacitiveList:getFocusCap() == Index + 5 and ItemCount == 0 then
            self.Controller.CapacitiveList:reset(false)
        end

        if ItemCount == 0 then
            ParamLabel:setText("")
            ParamLabel:setAttribute(ATTR_ALL, "false")
        elseif Multi then
            ParamLabel:setText("*")
            ParamLabel:setAttribute(ATTR_ALL, "false")
        else
            local SelectedItem = BrowseHelper.getParamIndex(PARAM_ATTR1 + Index)

            ParamLabel:setText(SelectedItem == NPOS
                and self.GetParamAllCaption[PARAM_ATTR1 + Index]()
                or BrowseHelper.getParamContent(PARAM_ATTR1 + Index, SelectedItem))

            ParamLabel:setAttribute(ATTR_ALL, SelectedItem == NPOS and "true" or "false")

        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:updateResultList()

    local NumItems = BrowseHelper.getResultListSize()
    local Text = ""

    if BrowseHelper.isFavoritesFilterEnabled() then
        Text = NumItems > 0 and NumItems.." ★" or "No ★"
    else
        Text = NumItems > 0
            and NumItems.." Result"..(NumItems > 1 and "s" or "")
            or  "No Results"
    end

    self.ParamLabels[PARAM_RESULTS]:setText(Text)

    self.ResultList:getScrollbar():setVisible(NumItems > 7)

    BrowsePageBase.updateResultList(self)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:shiftProductCategory(Inc)

    local CurrentIndex = BrowseHelper.getParamIndex(PARAM_PRODUCT_GROUPS)

    local NewIndex = CurrentIndex + Inc
    if NewIndex < 0 or NewIndex >= BrowseHelper.getParamCount(PARAM_PRODUCT_GROUPS) then
        return
    end

    BrowseHelper.setFocusProductCategoryIndex(NewIndex)
    self:updateProductCategories()

    self.Controller.CapacitiveList:setListFocusItem(1, NewIndex)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:shiftProductItem(Inc)

    local Index = BrowseHelper.getFocusProductIndex()

    if Index == NPOS then
        Index = -1
    end

    if Index + Inc >= -1 and Index + Inc < BrowseHelper.getProductCount() then

        Index = Index + Inc + (Index == -1 and self.ProductList:getItemOffset() * 3 or 0)
    end

    BrowseHelper.setFocusProductIndex(Index)
    self:updateBankParams()

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:updateParameters()

    self:refreshAccessibleEncoderInfo()

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getPrevNextButtonStates()
    return self.FocusParam ~= self:getNextFocusParam(false), self.FocusParam < 8
end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:onLeftRightButton(Right, Pressed)

    if Pressed then

        local ProductIndex = BrowseHelper.getFocusProductIndex()

        if ProductIndex == NPOS then
            local ProductListOffset = self.ProductList:getItemOffset()
            ProductListOffset = math.bound(ProductListOffset + (Right and 2 or -2), 0, self:getProductListSize() - 2)
            self.ProductList:setItemOffset(ProductListOffset)

        else

            local NewProductIndex = math.bound(ProductIndex + (Right and 6 or -6), -1, BrowseHelper.getProductCount() - 1)

            BrowseHelper.setFocusProductIndex(NewProductIndex == -1 and NPOS or NewProductIndex)
            self:updateBankParams()

            self.ProductList:setAlign()
        end
    end

    self:updateLeftRightButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:onTimer()

    self:updateLeftRightButtonLEDs()

    if self.IsVisible then
        self.Controller:setTimer(self, 1)
    end

    if self.ProductList:isMoving() then
        return
    end

    BrowseHelper.updateCacheTimer()

    if self.PostDB3Update then
        self.PostDB3Update = false
        self:updateScreens(false)
    end

    -- call base class
    PageMaschine.onTimer(self)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getLeftRightButtonStates()

    local ProductIndex = BrowseHelper.getFocusProductIndex()
    local ProductCount = BrowseHelper.getProductCount()

    local ProductListOffset = self.ProductList:getItemOffset()
    local ProductListSize = self:getProductListSize()

    local CanPrev = ProductListOffset ~= 0 or ProductIndex ~= NPOS
    local CanNext = (ProductIndex ~= ProductCount - 1 and (ProductIndex ~= NPOS or ProductListOffset ~= ProductListSize-2))

    return CanPrev, CanNext

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:updateLeftRightButtonLEDs()

    local CanPrev, CanNext = self:getLeftRightButtonStates()

    BrowsePageBase.updateLeftRightButtonLEDs(self, CanPrev, CanNext)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:onWheel(Inc)

    if self.FocusParam == PARAM_RESULTS and self:isShowingTagBrowser() then
        self.Controller.CapacitiveList:reset(false)
    end
    self:onScreenEncoder(self.FocusParam, Inc)
    self:updateScreens(false)
    NHLController:addAccessibilityControlData(NI.HW.ZONE_ERPS, self.FocusParam, 0, 0, 0,
                                              self:getAccessibleParamDescriptionByIndex(self.FocusParam))
    NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_ERPS, self.FocusParam)
    return true

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:onWheelButton(Pressed)

    -- Manual handling of the capacitive overlay - controlled from the JW
    self.Controller.CapacitiveList:setManualMode(Pressed)
    local Show = Pressed and self.FocusParam ~= 2 and self.FocusParam ~= PARAM_RESULTS
    self.Controller.CapacitiveList:setFocusCap(Show and self.FocusParam)
    if CapacitiveHelper.getFocusCap() ~= self.FocusParam then
        self.Controller.CapacitiveList:setVisible(Show)
    end

    if Pressed and self.FocusParam == PARAM_RESULTS then
        local SoftButtonEquivalent = 8
        if self.Controller:getShiftPressed() then
            SoftButtonEquivalent = 7
            BrowseHelper.toggleFocusItemFavoriteState()
        else
            self:loadFocusItem()
        end
        local Layer = self.Controller:getShiftPressed() and NI.HW.LAYER_SHIFTED or NI.HW.LAYER_UNSHIFTED
        NHLController:addAccessibilityControlData(NI.HW.ZONE_SOFTBUTTONS, SoftButtonEquivalent - 1, Layer, 0, 0,
                                                  self:getAccessibleTextByButtonIndex(SoftButtonEquivalent))
        NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_SOFTBUTTONS, SoftButtonEquivalent - 1)
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:onScreenEncoder(KnobIdx, Increment)
    
    -- all encoders are smoothed
    if MaschineHelper.onScreenEncoderSmoother(KnobIdx, Increment, .1) == 0 then
        return
    end

    local Offset = Increment > 0 and 1 or -1

    -- Browse Categories
    if KnobIdx == PARAM_PRODUCT_GROUPS then
        self:shiftProductCategory(Offset)

    elseif KnobIdx == PARAM_BC1 then
        self:shiftProductItem(Offset)

    -- Browse Banks (incl. Products)
    elseif KnobIdx == PARAM_BC2 or KnobIdx == PARAM_BC3 then
        BrowseHelper.offsetBankChain(KnobIdx - PARAM_BC1, Offset)

    -- Browse Types (incl. Modes)
    elseif KnobIdx >= PARAM_ATTR1 and KnobIdx <= PARAM_ATTR3 then
        BrowseHelper.offsetAttribute(KnobIdx - PARAM_ATTR1, Offset)

    -- Browse Results
    elseif KnobIdx == PARAM_RESULTS then
        local IncrementStep = BrowseHelper.getIncrementStep(Increment, self.Controller:getShiftPressed())
        BrowseHelper.offsetResultListFocusBy(IncrementStep, true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:checkFocusParamValidity()

    if self.FocusParam ~= PARAM_RESULTS and BrowseHelper.getParamCount(self.FocusParam) == 0 then

        --check left
        self.FocusParam = self:getNextFocusParam(false)

        if BrowseHelper.getParamCount(self.FocusParam) == 0 then

            -- check right
            self.FocusParam = self:getNextFocusParam(true)

        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:onPrevNextButton(Pressed, Right)

    if not Pressed then
        return false
    end

    local WheelDown = self.Controller.SwitchPressed[NI.HW.BUTTON_WHEEL]

    self.FocusParam = self:getNextFocusParam(Right)

    if self.Controller.CapacitiveList:isInManualMode() then
        self.Controller.CapacitiveList:setFocusCap(self.FocusParam)
        self.Controller.CapacitiveList:setVisible(Pressed and self.FocusParam ~= 2 and self.FocusParam ~= PARAM_RESULTS)
    end

    self:updateScreens(false)
    PageMaschine.refreshAccessibleEncoderInfo(self)

    NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_ERPS, self.FocusParam)

    return true

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:onEraseButton(Pressed)

    if not self.Controller:getShiftPressed() and Pressed then
        BrowseHelper.deleteFocusItems()
        return true

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getNextFocusParam(Right)

    local NewFocusParam = math.bound(self.FocusParam + (Right and 1 or -1), 1, 8)

    while BrowseHelper.getParamCount(NewFocusParam) == 0 do

        if NewFocusParam == PARAM_PRODUCT_GROUPS then
            return self.FocusParam

        elseif NewFocusParam == PARAM_RESULTS then
            return PARAM_RESULTS
        else
            NewFocusParam = math.bound(NewFocusParam + (Right and 1 or -1), 1, 8)
        end

    end

    return NewFocusParam

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:onDB3ModelChanged(Model)

    -- if we're choosing a sample and the file type changes, leave
    if self.SamplingPage and not BrowseHelper.isSampleTab() then
        self:onShow(false)
        self.SamplingPage:onShow(true)
        return
    end

    Model = BrowseHelper.updateCachedData(Model)

    -- refresh ALL
    if Model == NI.DB3.MODEL_BROWSER then

        self:refreshCapacitiveList(PARAM_PRODUCT_GROUPS)
        self:refreshCapacitiveList(PARAM_BC2)
        self:refreshCapacitiveList(PARAM_BC3)

        self:updateProductCategories()
        self:updateBankParams()
        self:updateTypeParams()
        self:checkFocusParamValidity()

    elseif Model == NI.DB3.MODEL_BANKCHAIN then

        self:refreshCapacitiveList(PARAM_BC2)
        self:refreshCapacitiveList(PARAM_BC3)

        self:updateBankParams()
        self:updateTypeParams()
        self:checkFocusParamValidity()

    elseif Model == NI.DB3.MODEL_ATTRIBUTES then

        if self:isShowingTagBrowser() then
            self.CapacitiveTagBrowser:refresh()
        end

        self:updateTypeParams()
        self:checkFocusParamValidity()

    elseif Model == NI.DB3.MODEL_RESULTS then

        self:updateResultList()

    elseif Model == NI.DB3.MODEL_PRODUCTS then

        self:updateProductCategories()
        self:refreshCapacitiveList(PARAM_PRODUCT_GROUPS)

    else
        return
    end

    if not BrowseHelper.isBusy() then
        self.PostDB3Update = true
    end


end

------------------------------------------------------------------------------------------------------------------------
-- reset functions
------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase.resetFocusProductCategory()

    BrowseHelper.setFocusProductCategoryIndex(0)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase.resetFocusProductIndex()

    BrowseHelper.setFocusProductIndex(-1)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase.resetBankChain(Bank)

    BrowseHelper.setBankChainIndex(Bank, -1)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase.resetTypeItems(Type)

    BrowseHelper.setAttributeIndex(Type, -1)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase.resetResultList(Prehear)

    BrowseHelper.setResultListFocusIndex(0, Prehear)

end

------------------------------------------------------------------------------------------------------------------------
-- Tag Browser
------------------------------------------------------------------------------------------------------------------------

local Cap8Touched = false

function BrowsePageColorDisplayBase:onCapTouched(Cap, Touched)

    if Cap == PARAM_RESULTS then
        Cap8Touched = Touched
        self.Controller.CapacitiveList:reset(false)
    end
end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:isCustomCapEnabled(Cap)

    if Cap8Touched or Cap < 5 or Cap == PARAM_RESULTS then
        return false
    end

    return BrowseHelper.getParamCount(Cap) > 0

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:showTagBrowser(Show, FocusCap)

    self.ProductBG:showPicture(not Show)

    self.ProductStack:setTop(Show and self.CapacitiveTagBrowser or self.ResultsFrame)

    if Show then

        local FileType = BrowseHelper.getFileType()
        local Type3 = FileType ~= NI.DB3.FILE_TYPE_INSTRUMENT and
            FileType ~= NI.DB3.FILE_TYPE_EFFECT

        self.CapacitiveTagBrowser:setShowModes(FocusCap == 7 and not Type3)
        self.CapacitiveTagBrowser:refresh()
        self.CapacitiveTagBrowser:setFocusAttribute(FocusCap - 5)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:isShowingTagBrowser()

    return self.ProductStack:getTopIndex() == STACK_TAGS

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getScreenEncoderInfo(Index)

    if Index >= 1 and Index <= 8
        and (self.ParamLabels[Index]:isEnabled() and self.ParamLabels[Index]:getText() ~= "") then

        local Info = {}
        Info.SpeechSectionName = ""
        Info.SpeechName = self:getEncoderParameterSpeechName(Index)
        Info.SpeechValue = self:getEncoderParameterSpeechValue(Index)

        if Index == PARAM_PRODUCT_GROUPS then
            Info.Value = BrowseHelper.getParamIndex(PARAM_PRODUCT_GROUPS)
        elseif Index == PARAM_BC1 then
            Info.Value = BrowseHelper.getFocusProductIndex()
        elseif Index == PARAM_BC2 or Index == PARAM_BC3 then
            Info.Value  = BrowseHelper.getBankChainSelectedSlotItem(Index - PARAM_BC1)
        elseif Index >= PARAM_ATTR1 and Index <= PARAM_ATTR3 then
            Info.Value = BrowseHelper.getFocusAttribute(Index - PARAM_ATTR1)
        elseif Index == PARAM_RESULTS then
            Info.Value = App:getDatabaseFrontend():getBrowserModel():getResultListModel():getFocusItem()
            if self.Controller:getShiftPressed() then
                Info.SpeechName = Info.SpeechName .. " Jump By Twenty"
            end
        end

        return Info
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getEncoderParameterSpeechName(EncoderIndex)

    return self.GetParamNameFunctors[EncoderIndex] and self.GetParamNameFunctors[EncoderIndex]() or ""

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getEncoderParameterSpeechValue(EncoderIndex)

    if BrowseHelper.getParamMulti(EncoderIndex) then

        return "Multiple Selected"

    else

        if EncoderIndex == PARAM_PRODUCT_GROUPS then
            return self:getProductGroupParameterSpeechValue()
        elseif EncoderIndex == PARAM_RESULTS then
            return self:getPresetParameterSpeechValue()
        else
            local Index = BrowseHelper.getParamIndex(EncoderIndex)
            if Index == NPOS then
                return self.GetParamAllCaption[EncoderIndex]()
            else
                local Value = BrowseHelper.getParamContent(EncoderIndex, BrowseHelper.getParamIndex(EncoderIndex))
                if EncoderIndex == PARAM_BC1 then
                    Value = self:getProductDisplayName(Value)
                end
                return Value
            end
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getProductGroupParameterSpeechValue()

    local Index = BrowseHelper.getParamIndex(PARAM_PRODUCT_GROUPS)

    if Index == 0 then
        return self.GetParamAllCaption[PARAM_PRODUCT_GROUPS]()
    else
        return BrowseHelper.getParamContent(PARAM_PRODUCT_GROUPS, BrowseHelper.getParamIndex(PARAM_PRODUCT_GROUPS))
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getPresetParameterSpeechValue()

    local PresetName = "NO RESULTS"
    local ResultList = App:getDatabaseFrontend():getBrowserModel():getResultListModel()

    if ResultList:getItemCount() > 0 then
        PresetName = ResultList:getItemName(ResultList:getFocusItem())
    end

    return PresetName

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getWheelDirectionInfo()

    local EncoderInfo = self:getScreenEncoderInfo(self.FocusParam)
    local Info = {}
    Info.TrainingMode = EncoderInfo.SpeechName
    Info.NormalMode = EncoderInfo.SpeechValue
    return Info

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getScreenButtonInfo(Index)

    local Info = PageMaschine.getScreenButtonInfo(self, Index)
    if not Info then
        return
    end

    if self.Controller:getShiftPressed() then

        if Index == 1 or Index == 2 then
            Info.SpeechName = "Sort by " .. self.Screen.ScreenButton[Index]:getText()
            Info.SpeechValue = ""

        elseif Index == 7 then
            Info.SpeechName = "Set Favourite,"
            Info.SpeechValue = BrowseHelper.isFocusItemFavorite() and "ON" or "OFF"

        elseif Index == 8 then
            Info.SpeechName = "Pre Hear,"
        end

    else

        if Index == 1 or Index == 2 then
            Info.SpeechName = (Index == 1 and "Previous" or "Next") .. " Content Type"
            Info.SpeechValue = App:getDatabaseFrontend():getBrowserModel():getFileTypeSelection() .. "s"
            Info.SpeakNameInNormalMode = false
            Info.SpeakValueInTrainingMode = false

        elseif Index == 3 then
            Info.SpeechName = "Quick Browse"
            Info.SpeechValue = ""

        elseif Index == 4 then
            Info.SpeechName = "Preset Collection,"
            Info.SpeechValue = App:getDatabaseFrontend():getBrowserModel():getUserMode() and "USER" or "FACTORY"
            Info.SpeakNameInNormalMode = false

        elseif Index == 5 or Index == 6 then
            Info.SpeechName = (Index == 5 and "Previous" or "Next") .. " Plug-in"
            Info.SpeechValue = AccessibilityTextHelper.getFocusPluginMessage()
            Info.SpeakNameInNormalMode = false
            Info.SpeakValueInTrainingMode = false

        elseif Index == 7 then
            Info.SpeechName = "Filter by Favourites,"
            Info.SpeechValue = BrowseHelper.isFavoritesFilterEnabled() and "ON" or "OFF"

        elseif Index == 8 then
            Info.SpeechName = "Load Preset"
            Info.SpeechValue = ""
            Info.SpeakNameInNormalMode = false
        end

    end

    return Info

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getCurrentPageSpeechAssistanceMessage()
    Msg = ""
    local ProductIndex = BrowseHelper.getFocusProductIndex()

    if ProductIndex ~= BrowseHelper.getProductCount() then
        if ProductIndex ~= NPOS then
            Msg = Msg .. BrowseHelper.getParamContent(PARAM_BC1, BrowseHelper.getParamIndex(PARAM_BC1))
        else
            Msg = Msg .."All Products"
        end
    end

    return Msg
end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getResultFocusItemName()

    local ResultList = App:getDatabaseFrontend():getBrowserModel():getResultListModel()
    return ResultList:getItemName(ResultList:getFocusItem())

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getAccessibleTextByButtonIndex(ButtonIdx)

    if ButtonIdx == 7 then
        if self.Controller:getShiftPressed() then
            return (BrowseHelper.isFocusItemFavorite() and "Set" or "Unset").." Favorite"
        else
            return "Favorites"
        end
    end

    return PageMaschine.getAccessibleTextByButtonIndex(self, ButtonIdx)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getAccessibleParamDescriptionByIndex(EncoderIdx)

    if EncoderIdx == 8 and not NI.DATA.WORKSPACE.getAccessibilitySpeakPreset(App) then
        return "", "", "", ""
    end
    local Name = self.GetParamNameFunctors[EncoderIdx]()
    local Value = (EncoderIdx == 8) and self:getResultFocusItemName() or self.ParamLabels[EncoderIdx]:getText()
    return Name, Value, "", ""

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:refreshAccessibleEncoderInfo()

    if not NHLController:isExternalAccessibilityRunning() then
        return
    end
    PageMaschine.refreshAccessibleEncoderInfo(self)
    if not NI.DATA.WORKSPACE.getAccessibilitySpeakPreset(App) then
        NHLController:setAccessibilityControlState(NI.HW.ZONE_ERPS, 8, 0, NI.HW.CNTRL_NO_STATE)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageColorDisplayBase:getAccessibleLeftRightButtonText()

    return "File type page up", "File type page down"

end

------------------------------------------------------------------------------------------------------------------------
