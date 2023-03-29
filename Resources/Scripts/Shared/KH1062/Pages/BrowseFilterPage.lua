local FunctionChecker = require("Scripts/Shared/Components/FunctionChecker")

local AccessibilityTextHelper = require("Scripts/Shared/Helpers/AccessibilityTextHelper")

require "Scripts/Shared/KH1062/Pages/BrowsePageBase"
require "Scripts/Shared/Helpers/BrowseHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowseFilterPage = class( 'BrowseFilterPage', BrowsePageBase )

BrowseFilterPage.FileTypeFilter = "filetypes"

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:__init(PageName, Environment, Controller, AvailableFilters, OptionalNavigationTracker, Callbacks, ShiftStateCallbacks)

    self.AvailableFilters = AvailableFilters
    self.CurrentFilterIndex = 1
    self.NavigationTracker = OptionalNavigationTracker

    FunctionChecker.checkFunctionsExist(Callbacks, {"changeToResultPage"})
    self.Callbacks = Callbacks
    self.AccessibilityController = Environment.AccessibilityController

    self:setupFilters()

    BrowsePageBase.__init(self, PageName, Environment, Controller, Callbacks, ShiftStateCallbacks)

    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL, Shift = false, Pressed = true },
                                     function() self:shiftToNextPopulatedFilterOrResults() end)
    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_LEFT, Shift = false, Pressed = true },
                                     function() self:shiftToPreviousPopulatedFilterOrResults() end)
    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_LEFT, Shift = true, Pressed = true },
                                     function()
                                        self:clearFilters()
                                        self:shiftToFirstFilterOrResults()
                                        self.AccessibilityController.say(AccessibilityTextHelper.getPageSubtitleAndText(self:getAccessibilityData()))
                                     end)
    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_RIGHT, Pressed = true },
                                     function() self:shiftToNextPopulatedFilterOrResults() end)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:setupFilters()

    local GetFieldsForListWithAll = function(IsMultiItemSelected, GetRealItem, Index, ResultCount)
        if ResultCount() == 0 then
            return { Name = "", IsSelected = true, IsFavorite = false }
        end
        if IsMultiItemSelected() then
            return { Name = "*", IsSelected = true, IsFavorite = false }
        elseif Index == 0 then
            return { Name = "All", IsSelected = true, IsFavorite = false }
        else
            return GetRealItem(Index - 1)
        end
    end

    local function CreateAttributeFilterDefinition(ZeroBasedAttributeIndex, GetSectionName)

        return {

            GetSectionName = GetSectionName,

            GetListSize = function()
                return self.BrowserModel:getAttributeCount(ZeroBasedAttributeIndex)
            end,

            UpdateResult = function(IndexIncludingAll)
                local Fields = GetFieldsForListWithAll(
                    function()
                        return self.BrowserModel:isAttributeMulti(ZeroBasedAttributeIndex)
                    end,
                    function(Index)
                        return self.BrowserModel:getAttributeItem(ZeroBasedAttributeIndex, Index)
                    end,
                    IndexIncludingAll,
                    function()
                        return self.BrowserModel:getAttributeCount(ZeroBasedAttributeIndex)
                    end)
                self.Screen:setBottomRowText(Fields and Fields.Name or "")
            end,

            IsMultiSelection = function()
                return self.BrowserModel:isAttributeMulti(ZeroBasedAttributeIndex)
            end,

            GetFocusIndex = function()
                return self.BrowserModel:getAttributeFocusIndex(ZeroBasedAttributeIndex)
            end,

            SetFocusIndex = function(Index)
                self.BrowserController:setFocusAttributeIndex(ZeroBasedAttributeIndex, Index)
            end,

            HasAllOption = true
        }

    end

    self.FilterDefinitions = {
        [BrowseFilterPage.FileTypeFilter] = {

            GetSectionName = function()
                return "File Types"
            end,

            GetListSize = function()
                return self.BrowserModel:getFileTypeListSize()
            end,

            UpdateResult = function(IndexIncludingAll)
                local Fields = self.BrowserModel:getFileTypeItem(IndexIncludingAll)
                self.Screen:setBottomRowText(Fields and Fields.Name or "")
            end,

            IsMultiSelection = function() return false end,

            GetFocusIndex = function()
                return self.BrowserModel:getFileTypeFocusIndex()
            end,

            SetFocusIndex = function(Index)
                self.BrowserController:setFileTypeSelection(self.BrowserModel.getFileTypeNameWithIndex(Index))
            end,

            HasAllOption = false
        },

        [PARAM_BC1] = {

            GetSectionName = function()
                return "Products"
            end,

            GetListSize = function()
                return self.BrowserModel:getProductListSize()
            end,

            UpdateResult = function(IndexIncludingAll)
                local Fields = GetFieldsForListWithAll(
                    function() return false end,
                    function(Index)
                        return self.BrowserModel:getProductItem(Index)
                    end,
                    IndexIncludingAll,
                    function()
                        return self.BrowserModel:getProductListSize()
                    end)
                self.Screen:setBottomRowText(Fields and Fields.Name or "")
            end,

            IsMultiSelection = function() return false end,

            GetFocusIndex = function()
                return self.BrowserModel:getProductListFocusIndex()
            end,

            SetFocusIndex = function(Index)
                self.BrowserController:setFocusProductIndex(Index)
            end,

            HasAllOption = true
        },

        [PARAM_BC2] = {
            GetFocusIndex = function()
                return self.BrowserModel:getFocusBankchainIndex(1)
            end,
            SetFocusIndex = function(Index)
                self.BrowserController:setFocusBankchainIndex(1, Index)
            end,
            HasAllOption = true
        },

        [PARAM_BC3] = {
            GetFocusIndex = function()
                return self.BrowserModel:getFocusBankchainIndex(2)
            end,
            SetFocusIndex = function(Index)
                self.BrowserController:setFocusBankchainIndex(2, Index)
            end,
            HasAllOption = true
        },

        [PARAM_ATTR1] = CreateAttributeFilterDefinition(
            0,
            function() return "Types" end
        ),

        [PARAM_ATTR2] = CreateAttributeFilterDefinition(
            1,
            function() return "Sub-Types" end
        ),

        [PARAM_ATTR3] = CreateAttributeFilterDefinition(
            2,
            function ()
                return BrowseHelper.supportsModes(self.BrowserModel:getFileType()) and "Characters" or "Sub-Types 2"
            end
        )
    }

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:setAvailableFilters(Filters)

    self.AvailableFilters = Filters
    self:setFilterIndex(1)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:setupScreen()

    BrowsePageBase.setupScreen(self)
    self:updateSectionName()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:updateScreen()

    BrowsePageBase.updateScreen(self)
    BrowsePageBase.setIconToCurrentFileType(self)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:isOnLastFilter()

    return self.CurrentFilterIndex == #self.AvailableFilters

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:isCurrentFilterEmpty()

    return self:getCurrentFilter().GetListSize() == 0

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:shiftToNextPopulatedFilterOrResults()

    local ResultsShown = false
    repeat
        if self:isOnLastFilter() or self:isShiftPressed() then
            self.Callbacks.changeToResultPage()
            ResultsShown = true
            break
        else
            self:shiftFilterIndex(1)
        end
    until not self:isCurrentFilterEmpty()
    if not ResultsShown then
        self.AccessibilityController.say(AccessibilityTextHelper.getPageSubtitleAndText(self:getAccessibilityData()))
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:changeToResultsPageIfCurrentFilterEmpty()

    if self:isCurrentFilterEmpty() then
        self.Callbacks.changeToResultPage()
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:shiftToPreviousPopulatedFilterOrResults()

    repeat
        self:shiftFilterIndex(-1)
    until not self:isCurrentFilterEmpty() or self.CurrentFilterIndex == 1

    self:changeToResultsPageIfCurrentFilterEmpty()
    self.AccessibilityController.say(AccessibilityTextHelper.getPageSubtitleAndText(self:getAccessibilityData()))

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:shiftToFirstFilterOrResults()

    self:setFilterIndex(1)
    self:changeToResultsPageIfCurrentFilterEmpty()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:shiftToPreviousPopulatedFilterOrResultsIfCurrentFilterEmpty()

    if self.CurrentFilterIndex == 1 then
        self:changeToResultsPageIfCurrentFilterEmpty()
    elseif self:isCurrentFilterEmpty() then
        self:shiftToPreviousPopulatedFilterOrResults()
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:shiftToLastPopulatedFilterOrResults()

    self:setFilterIndex(#self.AvailableFilters)
    self:shiftToPreviousPopulatedFilterOrResultsIfCurrentFilterEmpty()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:setFilterIndex(Index)

    self.CurrentFilterIndex = math.max(1, math.min(Index, #self.AvailableFilters))
    self:updateFocusedItem()
    self:updateSectionName()
    if self.NavigationTracker then
        local FilterType = self:getCurrentFilterType()
        self.NavigationTracker:setCurrentPageAndFilter(self.Name, FilterType)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:shiftFilterIndex(Delta)

    self:setFilterIndex(self.CurrentFilterIndex + Delta)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:getCurrentFilterType()

    return self.AvailableFilters[self.CurrentFilterIndex]

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:getCurrentFilter()

    return self.FilterDefinitions[self:getCurrentFilterType()]

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage.getIndexForFocusItemChange(CurrentIndex, Size, Delta, HasAllOption)

    if Size == 0 then
        return NPOS
    end

    local ListIndex = CurrentIndex == NPOS and -1 or CurrentIndex

    local NewIndex = ListIndex + Delta
    if HasAllOption and NewIndex < 0 then
        return NPOS
    end

    return BrowseHelper.advanceIndex(ListIndex, Delta, Size, false)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:changeListFocus(Delta)

    if Delta == 0 then
        return
    end

    local HasFocusIndexChanged = false
    local NextIndex = NPOS

    if self:getCurrentFilter().IsMultiSelection() then

        HasFocusIndexChanged = true

    else

        local FocusIndex = self:getCurrentFilter().GetFocusIndex()
        local ListSize = self:getCurrentFilter().GetListSize()
        local HasAllOption = self:getCurrentFilter().HasAllOption
        NextIndex = BrowseFilterPage.getIndexForFocusItemChange(FocusIndex, ListSize, Delta, HasAllOption)
        HasFocusIndexChanged = FocusIndex ~= NextIndex

    end

    if HasFocusIndexChanged then
        local SetFocusIndex = self:getCurrentFilter().SetFocusIndex
        SetFocusIndex(NextIndex)
        self:updateFocusedItem() -- immediate feedback before deferred search executes
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:onShow(Show)

    BrowsePageBase.onShow(self, Show)
    if Show then
        self:shiftToPreviousPopulatedFilterOrResultsIfCurrentFilterEmpty()
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:onDB3ModelChanged(Model)

    BrowsePageBase.onDB3ModelChanged(self, Model)

    local shiftToPreviousPopulatedNonFileTypeFilterOrResults = function ()
        self:shiftToPreviousPopulatedFilterOrResults()
        if self:getCurrentFilterType() == BrowseFilterPage.FileTypeFilter then
            self.Callbacks.changeToResultPage()
        end
    end

    if Model == NI.DB3.MODEL_BANKCHAIN then

        self:updateFocusedItem()
        self:updateLEDs()

    elseif Model == NI.DB3.MODEL_PRODUCTS or Model == NI.DB3.MODEL_ATTRIBUTES then

        if self:isCurrentFilterEmpty() then
            shiftToPreviousPopulatedNonFileTypeFilterOrResults()
        end
        self:updateSectionName()
        self:updateFocusedItem()

    elseif Model == NI.DB3.MODEL_BROWSER then

        if self:isCurrentFilterEmpty() then
            shiftToPreviousPopulatedNonFileTypeFilterOrResults()
        end

    end

    BrowsePageBase.setIconToCurrentFileType(self)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:updateSectionName()

    local GetSectionName = self:getCurrentFilter().GetSectionName
    self.Screen:setTopRowText(GetSectionName())

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:updateFocusedItem()

    local ListItemIndex = 0
    local AllFilterIndexIncrement = self:getCurrentFilter().HasAllOption and 1 or 0
    if not self:getCurrentFilter().IsMultiSelection() then
        local FocusItemIndex = self:getCurrentFilter().GetFocusIndex()
        ListItemIndex = (FocusItemIndex == NPOS and -1 or FocusItemIndex) + AllFilterIndexIncrement
    end

    self:getCurrentFilter().UpdateResult(ListItemIndex)

    local Size = self:getCurrentFilter():GetListSize() + AllFilterIndexIncrement
    self:updateScrollbar(Size, ListItemIndex)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:clearFilters()

    self.BrowserController:clearAllFilters()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseFilterPage:sayBrowserListChange()

    self.AccessibilityController.say(AccessibilityTextHelper.getPageTextOnly(self:getAccessibilityData()))

end
