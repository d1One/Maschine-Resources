require "Scripts/Shared/Helpers/BrowseHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowserModel = class( 'BrowserModel' )

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:__init()

    self.ResultListModel = self:getResultListModel()

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:getResultListModel()

    return App:getDatabaseFrontend():getBrowserModel():getResultListModel()

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:getResultListFocusItem()

    return self.ResultListModel:getFocusItem()

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:getResultListSize()

    return self.ResultListModel:getItemCount()

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:getIndexForFocusItemChange(Delta)

    local ItemCount = self.ResultListModel:getItemCount()
    local FocusItem = self.ResultListModel:getFocusItem()
    return BrowseHelper.advanceIndex(FocusItem, Delta, ItemCount, false)

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:canPrehear()

    return BrowseHelper.canPrehear()

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:getResultListItem(Index)

    return {
        Name = self.ResultListModel:getItemName(Index),
        IsSelected = self.ResultListModel:isItemSelected(Index),
        IsFavorite = self.ResultListModel:isItemFavorite(Index)
    }

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:isUserMode()

    return BrowseHelper.getUserMode()

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:getProductListSize()

    return BrowseHelper.getProductCount()

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:getProductItem(Index)

    local SelectedItemIndex = self:getProductListFocusIndex()
    local VendorAndName = BrowseHelper.getProductName(Index) or ""

    return {
        Name = BrowseHelper.extractProductName(VendorAndName),
        IsSelected = (Index == SelectedItemIndex),
        IsFavorite = false
    }

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:getProductListFocusIndex()

    return BrowseHelper.getFocusProductIndex()

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:getAttributeCount(ZeroBasedAttributeIndex)

    return BrowseHelper.getAttributeCount(ZeroBasedAttributeIndex)

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:getAttributeFocusIndex(ZeroBasedAttributeIndex)

    return BrowseHelper.getFocusAttribute(ZeroBasedAttributeIndex)

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:isAttributeMulti(ZeroBasedAttributeIndex)

    return BrowseHelper.getParamMulti(PARAM_ATTR1 + ZeroBasedAttributeIndex)

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:getAttributeItem(ZeroBasedAttributeIndex, ItemIndex)

    local SelectedItemIndex = self:getAttributeFocusIndex(ZeroBasedAttributeIndex)

    return {
        Name = BrowseHelper.getParamContent(PARAM_ATTR1 + ZeroBasedAttributeIndex, ItemIndex),
        IsSelected = (ItemIndex == SelectedItemIndex),
        IsFavorite = false
    }

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:isFavoritesFilterEnabled()

    return BrowseHelper.isFavoritesFilterEnabled()

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel.getFileTypeNameWithIndex(ZeroBasedIndex)

    return BrowseHelper.getVisibleFileTypeNames():at(ZeroBasedIndex)

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:getFileTypeListSize()

    return BrowseHelper.getVisibleFileTypeNames():size()

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:getFileTypeItem(ZeroBasedIndex)

    local SelectedItemIndex = self:getFileTypeFocusIndex()

    return {
        Name = self.getFileTypeNameWithIndex(ZeroBasedIndex) .. "s",
        IsSelected = (ZeroBasedIndex == SelectedItemIndex),
        IsFavorite = false
    }

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:getFileTypeFocusIndex()

    local FileTypeNames = BrowseHelper.getVisibleFileTypeNames()
    for Index = 0, FileTypeNames:size() - 1 do
        if FileTypeNames:at(Index) == BrowseHelper.getFileTypeName() then
            return Index
        end
    end
    return 0

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:getFileType()

    return BrowseHelper.getFileType()

end

------------------------------------------------------------------------------------------------------------------------

function BrowserModel:getFileTypeName()

    return BrowseHelper.getFileTypeName()

end
