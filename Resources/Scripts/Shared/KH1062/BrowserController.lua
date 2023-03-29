require "Scripts/Shared/Components/BrowserCache"
require "Scripts/Shared/Helpers/BrowseHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowserController = class( 'BrowserController' )

------------------------------------------------------------------------------------------------------------------------

function BrowserController:__init()

    self.AppBrowserController = App:getDatabaseFrontend():getBrowserController()

end

------------------------------------------------------------------------------------------------------------------------

function BrowserController:changeResultListFocus(DeltaItems)

    self.AppBrowserController:changeResultListFocus(DeltaItems, false, NI.DB3.BrowserController.SOURCE_DEFAULT, false)

end

------------------------------------------------------------------------------------------------------------------------

function BrowserController:setUserMode(IsUserMode)

    BrowseHelper.setUserMode(IsUserMode)

end

------------------------------------------------------------------------------------------------------------------------

function BrowserController:loadSelectedResultListItem(FromJob)

    self.AppBrowserController:loadSelectedResultListItem(App, FromJob)

end

------------------------------------------------------------------------------------------------------------------------

function BrowserController:setFocusProductIndex(ProductIndex)

    BrowseHelper.setFocusProductIndex(ProductIndex)

end

------------------------------------------------------------------------------------------------------------------------

function BrowserController:setFileTypeSelection(FileTypeName)

    self.AppBrowserController:setFileTypeSelection(FileTypeName, true, false)

end

------------------------------------------------------------------------------------------------------------------------

function BrowserController:processDelayedSearches()

    BrowserCache.onTimer()

end

------------------------------------------------------------------------------------------------------------------------

function BrowserController:setFocusBankchainIndex(ZeroBasedBankChainIndex, ItemIndex)

    BrowseHelper.setBankChainIndex(ZeroBasedBankChainIndex, ItemIndex == NPOS and -1 or ItemIndex)

end

------------------------------------------------------------------------------------------------------------------------

function BrowserController:setFocusAttributeIndex(ZeroBasedAttributeIndex, ItemIndex)

    BrowseHelper.setAttributeIndex(ZeroBasedAttributeIndex, ItemIndex == NPOS and -1 or ItemIndex)

end

------------------------------------------------------------------------------------------------------------------------

function BrowserController:forceCacheRefresh()

    BrowseHelper.forceCacheRefresh()

end

------------------------------------------------------------------------------------------------------------------------

function BrowserController:updateCachedData(Model)

    return BrowseHelper.updateCachedData(Model)

end

------------------------------------------------------------------------------------------------------------------------

function BrowserController:toggleFavoritesFilter()

    return BrowseHelper.toggleFavoritesFilter()

end

------------------------------------------------------------------------------------------------------------------------

function BrowserController:toggleFocusItemFavoriteState()

    BrowseHelper.toggleFocusItemFavoriteState()

end

------------------------------------------------------------------------------------------------------------------------

function BrowserController:clearAllFilters()

    BrowseHelper.clearAllFilters()

end
