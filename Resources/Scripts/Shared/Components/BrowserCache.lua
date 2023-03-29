------------------------------------------------------------------------------------------------------------------------

BrowserCache = {}

local CachedData =
{
    ProductIndex = NPOS,

    ParamCount = {},
    ParamIndex = {},
    ParamContent = {},
    ParamMulti = {},

    UserMode = false,
    FileType = {},
    FileTypeName = ""
}


local UpdateProductIndexCountdown = 0
local UpdateProductCategoryIndexCountdown = 0
local RefreshAllFlag = false

------------------------------------------------------------------------------------------------------------------------

function BrowserCache.getParamContentList(Param)

    return CachedData.ParamContent[Param] or nil

end

------------------------------------------------------------------------------------------------------------------------

function BrowserCache.getParamCount(Param)

    return CachedData.ParamCount[Param] or 0

end

------------------------------------------------------------------------------------------------------------------------

function BrowserCache.getParamIndex(Param)

    return CachedData.ParamIndex[Param] or 0

end

------------------------------------------------------------------------------------------------------------------------

function BrowserCache.getParamMulti(Param)

    return CachedData.ParamMulti[Param] or false

end

------------------------------------------------------------------------------------------------------------------------

function BrowserCache.getParamContent(Param, Index)

    return CachedData.ParamContent[Param] and CachedData.ParamContent[Param][Index+1] or ""

end

------------------------------------------------------------------------------------------------------------------------

function BrowserCache.getUserMode()

    return CachedData.UserMode

end

------------------------------------------------------------------------------------------------------------------------

function BrowserCache.toggleUserMode()

    CachedData.UserMode = not CachedData.UserMode
    RefreshAllFlag = true

end

------------------------------------------------------------------------------------------------------------------------

function BrowserCache.getFileType()

    return CachedData.FileType

end

------------------------------------------------------------------------------------------------------------------------

function BrowserCache.getFileTypeName()

    return CachedData.FileTypeName or ""

end

------------------------------------------------------------------------------------------------------------------------

function BrowserCache.setProductCategoryIndex(Index)

    UpdateProductCategoryIndexCountdown = 20
    CachedData.ParamIndex[PARAM_PRODUCT_GROUPS] = Index

end

------------------------------------------------------------------------------------------------------------------------

function BrowserCache.setProductIndex(Index)

    UpdateProductIndexCountdown = 15
    CachedData.ParamIndex[PARAM_BC1] = Index == -1 and NPOS or Index

end

------------------------------------------------------------------------------------------------------------------------

function BrowserCache.refreshParametersData()

    -- leave if we're already changed item
    if UpdateProductCategoryIndexCountdown > 0 then
        return
    end

    local BrowserModel = App:getDatabaseFrontend():getBrowserModel()
    local ProductModel = BrowserModel:getProductModel()

    CachedData.FileType     = BrowserModel:getSelectedFileType()
    CachedData.FileTypeName = BrowserModel:getFileTypeSelection()
    CachedData.UserMode     = BrowserModel:getUserMode()

    --................................................................................
    -- Product Categories

    -- count
    CachedData.ParamCount[PARAM_PRODUCT_GROUPS] = ProductModel:areProductsGrouped() and
                                                  ProductModel:getNumProductGroups() or 0

    -- index
    local Category = BrowserModel:getProductGroupSelection()
    local GroupIndex = ProductModel:getProductGroupIndexFromName(Category)
    if GroupIndex == NPOS then
        return
    end
    CachedData.ParamIndex[PARAM_PRODUCT_GROUPS] = GroupIndex

    -- content
    CachedData.ParamContent[PARAM_PRODUCT_GROUPS] = {}
    for Item = 1, CachedData.ParamCount[PARAM_PRODUCT_GROUPS] do
        CachedData.ParamContent[PARAM_PRODUCT_GROUPS][Item] = ProductModel:getProductGroupNameFromIndex(Item-1)
    end

    --................................................................................
    -- Products

    -- count
    CachedData.ParamCount[PARAM_BC1] = ProductModel:getProductGroupSize(Category)

    -- content
    CachedData.ParamContent[PARAM_BC1] = {}
    for ItemIndex = 1, CachedData.ParamCount[PARAM_BC1] do
        CachedData.ParamContent[PARAM_BC1][ItemIndex] = ProductModel:getProductVendorizedNameByIndex(ItemIndex - 1,
            GroupIndex)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowserCache.refreshFocusProductData()

    -- leave if we're already changed item
    if UpdateProductIndexCountdown > 0 then
        return
    end

    local DatabaseFrontend = App:getDatabaseFrontend()
    local BrowserModel = DatabaseFrontend:getBrowserModel()
    local BankChainModel = BrowserModel:getBankChainModel()
    local Attributes = DatabaseFrontend:getBrowserModel():getAttributesModel()

    CachedData.ParamIndex[PARAM_BC1] = BankChainModel:getSelectedSlotItem(0)

    for Index = PARAM_BC2, PARAM_ATTR3 do

        --................................................................................
        -- BC 2 + 3
        if Index <= PARAM_BC3 then

            -- count
            CachedData.ParamCount[Index] = BankChainModel:getSlotItemCount(Index - PARAM_BC1)

            -- index
            local FocusIndex = BankChainModel:getSelectedSlotItem(Index - PARAM_BC1)

            -- cannot select a sub bank if no bank is selected
            if  (Index == PARAM_BC3 and CachedData.ParamIndex[PARAM_BC2] == NPOS) or
                (Index == PARAM_BC2 and CachedData.ParamIndex[PARAM_BC1] == NPOS) then
                FocusIndex = NPOS
                CachedData.ParamCount[Index] = 0
            end

            CachedData.ParamIndex[Index] = FocusIndex

            -- content
            CachedData.ParamContent[Index] = {}

            if CachedData.ParamCount[Index] > 0 then
                for Item = 0, CachedData.ParamCount[Index] - 1 do
                    CachedData.ParamContent[Index][Item + 1] = BankChainModel:getSlotItemName(Index - PARAM_BC1, Item)
                end
            end

        --................................................................................
        -- Attributes
        else

            -- count
            CachedData.ParamCount[Index] = Attributes:getAttributeCount(Index - PARAM_ATTR1)

            -- index
            CachedData.ParamIndex[Index] = Attributes:getFocusAttribute(Index - PARAM_ATTR1)

            -- multi?
            CachedData.ParamMulti[Index] = Attributes:getAttributeSelectionCount(Index - PARAM_ATTR1) > 1

            -- content
            CachedData.ParamContent[Index] = {}


            local Item = CachedData.ParamIndex[Index]
            if Item ~= NPOS then
                CachedData.ParamContent[Index][Item + 1] = Attributes:getAttributeName(Index - PARAM_ATTR1, Item)
            end
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowserCache.refreshResultListData()

    local DatabaseFrontend = App:getDatabaseFrontend()
    local BrowserModel = DatabaseFrontend:getBrowserModel()
    local ResultList = BrowserModel:getResultListModel()

    -- count
    CachedData.ParamCount[PARAM_RESULTS] = ResultList:getItemCount()

    -- index
    CachedData.ParamIndex[PARAM_RESULTS] = ResultList:getFocusItem()

    -- content not cached!

end

------------------------------------------------------------------------------------------------------------------------

function BrowserCache.onTimer()

    local BrowserControllerDeferredSearch = App:getBrowserControllerDeferredSearch()

    if UpdateProductCategoryIndexCountdown > 0 then
        UpdateProductCategoryIndexCountdown = UpdateProductCategoryIndexCountdown - 1
        if UpdateProductCategoryIndexCountdown == 0 then

            UpdateProductIndexCountdown = 0

            -- set product category
            local Index = BrowserCache.getParamIndex(PARAM_PRODUCT_GROUPS)

            local DatabaseFrontend = App:getDatabaseFrontend()
            local ProductModel = DatabaseFrontend:getBrowserModel():getProductModel()
            local Category = ProductModel:getProductGroupNameFromIndex(Index)
            BrowserControllerDeferredSearch:setProductGroupSelection(Category)

            RefreshAllFlag = true
        end
    end

    if UpdateProductIndexCountdown > 0 then
        UpdateProductIndexCountdown = UpdateProductIndexCountdown - 1
        if UpdateProductIndexCountdown == 0 then

            UpdateProductCategoryIndexCountdown = 0

            local Index = BrowserCache.getParamIndex(PARAM_BC1)

            BrowserControllerDeferredSearch:setBankChainSelection(0, Index == NPOS and -1 or Index)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------
-- returns 'filtered' browser item also
function BrowserCache.updateCachedData(Model)

    -- ignore all browsers stuff
    if Model == NI.DB3.MODEL_BROWSER then
        return nil
    end

    if Model == NI.DB3.MODEL_BANKCHAIN then
        local DatabaseFrontend = App:getDatabaseFrontend()
        local BrowserModel = DatabaseFrontend:getBrowserModel()
        local ProductModel = BrowserModel:getProductModel()
        local Category = BrowserModel:getProductGroupSelection()

        -- FileType, File Category, UserMode -> refresh all
        if BrowserCache.getFileType() ~= BrowserModel:getSelectedFileType() or
            BrowserCache.getParamIndex(PARAM_PRODUCT_GROUPS) ~= ProductModel:getProductGroupIndexFromName(Category) or
            BrowserCache.getUserMode() ~= BrowserModel:getUserMode() then
            RefreshAllFlag = true
        else

            BrowserCache.refreshFocusProductData()
            return NI.DB3.MODEL_BANKCHAIN
        end

    elseif Model == NI.DB3.MODEL_ATTRIBUTES then

        if RefreshAllFlag then
            RefreshAllFlag = false

            BrowserCache.refreshParametersData()
            BrowserCache.refreshFocusProductData()
            BrowserCache.refreshResultListData()

            return NI.DB3.MODEL_BROWSER --i.e. ALL
        else
            -- refresh BC2, BC3, All Attributes
            BrowserCache.refreshFocusProductData()
            return NI.DB3.MODEL_ATTRIBUTES
        end

    elseif Model == NI.DB3.MODEL_RESULTS then

        BrowserCache.refreshResultListData()
        return NI.DB3.MODEL_RESULTS

    elseif Model == NI.DB3.MODEL_PRODUCTS then

        BrowserCache.refreshParametersData()
        return NI.DB3.MODEL_PRODUCTS

    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowserCache.clearAllFilters()

    local DatabaseFrontend = App:getDatabaseFrontend()
    local ProductModel = DatabaseFrontend:getBrowserModel():getProductModel()
    local Category = ProductModel:getProductGroupNameFromIndex(0)
    local BrowserControllerDeferredSearch = App:getBrowserControllerDeferredSearch()
    BrowserControllerDeferredSearch:setProductGroupSelection(Category)
    for BankChainIndex = 0, 2 do
        BrowserControllerDeferredSearch:setBankChainSelection(BankChainIndex, -1)
    end
    for AttributeIndex = 0, 2 do
        BrowserControllerDeferredSearch:setAttributeSingleSelection(AttributeIndex, -1)
    end
    RefreshAllFlag = true

end
