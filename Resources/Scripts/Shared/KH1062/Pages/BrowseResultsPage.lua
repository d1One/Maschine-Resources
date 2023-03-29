local FunctionChecker = require("Scripts/Shared/Components/FunctionChecker")

local AccessibilityTextHelper = require("Scripts/Shared/Helpers/AccessibilityTextHelper")

require "Scripts/Shared/KH1062/Pages/BrowsePageBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowseResultsPage = class( 'BrowseResultsPage', BrowsePageBase )

------------------------------------------------------------------------------------------------------------------------

function BrowseResultsPage:__init(PageName, Environment, Controller, OptionalNavigationTracker, Callbacks, ShiftStateCallbacks)

    self.SamplePrehearController = Environment.SamplePrehearController
    self.NavigationTracker = OptionalNavigationTracker
    self.AccessibilityController = Environment.AccessibilityController
    self.AccessibilityModel = Environment.AccessibilityModel
    self.Callbacks = Callbacks
    self:verifyCallbacks()

    BrowsePageBase.__init(self, PageName, Environment, Controller, Callbacks, ShiftStateCallbacks)

    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL, Shift = false, Pressed = true },
                                    function()
                                        if self.AccessibilityModel:isTrainingMode() then
                                            return
                                        end
                                        if Callbacks and Callbacks.onLoadActionTriggered then
                                            Callbacks.onLoadActionTriggered()
                                        end
                                        self:loadSelectedItem()
                                    end)

    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL, Shift = true, Pressed = true },
                                    function()
                                        if not self.AccessibilityModel:isTrainingMode() then
                                            self.BrowserController:toggleFocusItemFavoriteState()
                                        end
                                        local Fields = self:getResultListFocusItemFields()
                                        local Name = "Set favorite"
                                        self.AccessibilityController.say(
                                            AccessibilityTextHelper.getOnOffFieldText(
                                                Name,
                                                Fields.IsFavorite
                                            )
                                        )
                                    end)

    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_LEFT, Shift = false, Pressed = true },
                                       self.Callbacks.changeToLastFilter)

    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL_LEFT, Shift = true, Pressed = true },
                                       self.Callbacks.clearFilters)

    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_NAVIGATE_BROWSE, Shift = true, Pressed = true },
                                    function()
                                        if not self.AccessibilityModel:isTrainingMode() then
                                            self.BrowserController:toggleFavoritesFilter()
                                        end
                                        local Name = "Filter by favorites"
                                        self.AccessibilityController.say(
                                            AccessibilityTextHelper.getOnOffFieldText(
                                                Name,
                                                self.BrowserModel:isFavoritesFilterEnabled()
                                            )
                                        )
                                     end)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseResultsPage:verifyCallbacks()

    FunctionChecker.checkFunctionsExist(self.Callbacks, {
        "changeToPluginPage",
        "changeToLastFilter",
        "clearFilters"
    })

end

------------------------------------------------------------------------------------------------------------------------

function BrowseResultsPage:setupScreen()

    BrowsePageBase.setupScreen(self)
    self.Screen:setTopRowText("Results")
    self.StarIcon = NI.GUI.insertLabel(self.Screen.BottomBar, "StarIcon")
    self.StarIcon:style("", "star")

end

------------------------------------------------------------------------------------------------------------------------

function BrowseResultsPage:updateIcon()

    if self.BrowserModel:isFavoritesFilterEnabled() then
        self:setIconToFavorite()
    else
        self:setIconToCurrentFileType()
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseResultsPage:updateScreen()

    BrowsePageBase.updateScreen(self)
    self:updateIcon()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseResultsPage:changeListFocus(Delta)

    local FocusItem = self.BrowserModel:getResultListFocusItem()
    local NextItem = self.BrowserModel:getIndexForFocusItemChange(Delta)
    local HasFocusItemChanged = FocusItem ~= NextItem

    self.BrowserController:changeResultListFocus(NextItem - FocusItem)

    if self.BrowserModel.canPrehear() and HasFocusItemChanged then
        self.SamplePrehearController:playLastDatabaseBrowserSelection()
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseResultsPage:loadSelectedItem()

    if self.BrowserModel:getResultListSize() > 0 then
        self.BrowserController:loadSelectedResultListItem(false)
        self.Callbacks.changeToPluginPage()
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseResultsPage:onDB3ModelChanged(Model)

    BrowsePageBase.onDB3ModelChanged(self, Model)

    if Model == NI.DB3.MODEL_RESULTS then
        self:updateFocusedItem()
        self:updateLEDs()
    end

    self:updateIcon()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseResultsPage:getResultListFocusItemFields()

    Index = self.BrowserModel:getResultListFocusItem()
    return self.BrowserModel:getResultListItem(Index)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseResultsPage:updateFocusedItem()

    local Size = self.BrowserModel:getResultListSize()
    local Index = 0

    if Size > 0 then
        local Fields = self:getResultListFocusItemFields()
        self.Screen:setBottomRowText(Fields.Name)
        self:updateIcon()
        self.StarIcon:setActive(Fields.IsFavorite)
    else
        self.Screen:setBottomRowText(self.BrowserModel:isFavoritesFilterEnabled() and "No ★" or "No Results")
        self.StarIcon:setActive(false)
    end

    self:updateScrollbar(Size, Index)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseResultsPage:setIconToFavorite()

    self.Screen:setTopRowIcon("favorite", "")

end

------------------------------------------------------------------------------------------------------------------------

function BrowseResultsPage.getTextForFavoriteState(IsFavorite)

    return IsFavorite and "★" or ""

end

------------------------------------------------------------------------------------------------------------------------

function BrowseResultsPage:onShow(Show)

    if Show and self.NavigationTracker then
        self.NavigationTracker:setCurrentPageAndFilter(self.Name, nil)
    end
    BrowsePageBase.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseResultsPage:sayBrowserListChange()

    if self.AccessibilityModel:getAccessibilitySpeakPreset() then
        self.AccessibilityController.say(AccessibilityTextHelper.getPageTextOnly(self:getAccessibilityData()))
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseResultsPage:getAccessibleItemLine()

    local TextToSpeak = ""
    if self.AccessibilityModel:getAccessibilitySpeakPreset() then
        if self.BrowserModel:getResultListSize() == 0 then
            TextToSpeak = "No Results"
        else
            TextToSpeak = self.Screen.BottomCaption:getText()
        end
    end
    return TextToSpeak

end
