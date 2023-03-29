------------------------------------------------------------------------------------------------------------------------
-- BrowseHelper
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/BrowserCache"

require "Scripts/Shared/Helpers/ResourceHelper"

local class = require 'Scripts/Shared/Helpers/classy'
BrowseHelper = class( 'BrowseHelper' )

PARAM_PRODUCT_GROUPS = 1
PARAM_BC1 = 2
PARAM_BC2 = 3
PARAM_BC3 = 4
PARAM_ATTR1 = 5
PARAM_ATTR2 = 6
PARAM_ATTR3 = 7
PARAM_RESULTS = 8

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.isBusy()

    return App:getDatabaseFrontend():getBrowserController():hasJob()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.updateCacheTimer()

    BrowserCache.onTimer()

end

------------------------------------------------------------------------------------------------------------------------
-- this also filters out unwanted events from DB. Use returned updated variable
function BrowseHelper.updateCachedData(Model)

    return BrowserCache.updateCachedData(Model)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.forceCacheRefresh()

    BrowserCache.refreshParametersData()
    BrowserCache.refreshFocusProductData()
    BrowserCache.refreshResultListData()

end

------------------------------------------------------------------------------------------------------------------------
-- CAT / PROD / BC / ATTR / RESULTS Access
------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getParamIndex(Param)

    return BrowserCache.getParamIndex(Param)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getParamCount(Param)

    return BrowserCache.getParamCount(Param)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getParamMulti(Param)

    return BrowserCache.getParamMulti(Param)

end

------------------------------------------------------------------------------------------------------------------------
-- Param is 1 based, Index is 0 based
function BrowseHelper.getParamContent(Param, Index)

    return BrowserCache.getParamContent(Param, Index)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getBankChainSelectedSlotItem(Bank)

    return BrowserCache.getParamIndex(PARAM_BC1 + Bank)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getBankChainSlotItemCount(Bank)

    return BrowserCache.getParamCount(PARAM_BC1 + Bank)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getFocusAttribute(Attr)

    return BrowserCache.getParamIndex(PARAM_ATTR1 + Attr)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getAttributeCount(Attr)

    return BrowserCache.getParamCount(PARAM_ATTR1 + Attr)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getResultListSize()

    return App:getDatabaseFrontend():getBrowserModel():getResultListModel():getItemCount()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getResultListFocusItem()

    return App:getDatabaseFrontend():getBrowserModel():getResultListModel():getFocusItem()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getProductCount()

    return BrowserCache.getParamCount(PARAM_BC1)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getFocusProductIndex()

    return BrowserCache.getParamIndex(PARAM_BC1)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getProductName(Index)

    return BrowserCache.getParamContent(PARAM_BC1, Index)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.extractProductName(VendorizedName)

    if VendorizedName then
        local NotNIVendor = string.match(VendorizedName, "|")
        if NotNIVendor then
            -- For NKS plug-ins the name looks like "|Vendor|Name", So if this is not NI product get the rest of the
            -- string starting the pos after the second "|"

            local NamePos = string.find(VendorizedName, "|", 2)
            if NamePos then
                return string.sub(VendorizedName, NamePos + 1)
            end
        end
    end

    return VendorizedName

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getUserMode()

    return BrowserCache.getUserMode()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.toggleUserMode()

    BrowseHelper.setUserMode(not BrowseHelper.getUserMode())

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.setUserMode(UserMode)

    local BrowserControllerDeferredSearch = App:getBrowserControllerDeferredSearch()
    BrowserControllerDeferredSearch:setUserMode(UserMode)
    BrowserCache.toggleUserMode()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getFileType()

    return BrowserCache.getFileType()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getFileTypeName()

    return BrowserCache.getFileTypeName()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getVisibleFileTypeNames()

    return App:getDatabaseFrontend():getBrowserModel():getVisibleFileTypeNames()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.selectPrevOrNextVisibleFileType(Next)

    App:getBrowserControllerDeferredSearch():selectPrevOrNextVisibleFileType(Next)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.setFocusProductIndex(Index)

    BrowserCache.setProductIndex(Index)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.setBankChainIndex(Bank, Index)  -- 0-indexed

    if Bank == 0 then
        BrowserCache.setProductIndex(Index)
    else
        local BrowserControllerDeferredSearch = App:getBrowserControllerDeferredSearch()
        BrowserControllerDeferredSearch:setBankChainSelection(Bank, Index)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.offsetBankChain(Index, Increment)  -- 0-indexed

    local SlotItemCount = BrowseHelper.getBankChainSlotItemCount(Index)
    if SlotItemCount == 0 then
        return
    end


    local SelectedSlotItem  = BrowseHelper.getBankChainSelectedSlotItem(Index)
    if SelectedSlotItem >= SlotItemCount then
        SelectedSlotItem = -1
    end

    -- focus prev / next item
    Increment = Increment >= 0 and 1 or -1
    SelectedSlotItem = SelectedSlotItem + Increment

    if SelectedSlotItem < -1 then
        SelectedSlotItem = -1
    elseif SelectedSlotItem >= SlotItemCount then
        SelectedSlotItem = SlotItemCount - 1
    end

    BrowseHelper.setBankChainIndex(Index, SelectedSlotItem)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.setAttributeIndex(Attr, Index)  -- 0-indexed

    local BrowserControllerDeferredSearch = App:getBrowserControllerDeferredSearch()
    BrowserControllerDeferredSearch:setAttributeSingleSelection(Attr, Index)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.offsetAttribute(Attr, Increment)  -- 0-indexed

    local ItemCount = BrowseHelper.getAttributeCount(Attr)
    if ItemCount == 0 then
        return
    end

    local SelectedItem = BrowseHelper.getFocusAttribute(Attr)
    if SelectedItem >= ItemCount or SelectedItem < 0 then
        SelectedItem = -1
    end

    -- focus prev / next item
    Increment = Increment >= 0 and 1 or -1
    SelectedItem = SelectedItem + Increment

    if SelectedItem < -1 then
        SelectedItem = -1
    elseif SelectedItem >= ItemCount then
        SelectedItem = SelectedItem - 1
    end

    BrowseHelper.setAttributeIndex(Attr, SelectedItem)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.offsetResultListFocusBy(Increment, Prehear)

    local DatabaseFrontend = App:getDatabaseFrontend()
    local BrowserController = DatabaseFrontend:getBrowserController()
    local ResultListModel = DatabaseFrontend:getBrowserModel():getResultListModel()
    local FocusItem = ResultListModel:getFocusItem()
    local NumItems = ResultListModel:getItemCount()
    local NextItem = math.bound(FocusItem + Increment, 0, NumItems-1)
    local HasFocusItemChanged = FocusItem ~= NextItem

    -- set focus
    BrowserController:changeResultListFocus(NextItem - FocusItem, false, NI.DB3.BrowserController.SOURCE_DEFAULT, false)

    if Prehear and BrowseHelper.canPrehear() and (HasFocusItemChanged or NumItems == 1) then
        NI.DATA.SamplePrehearAccess.playLastDatabaseBrowserSelection(App)
    end

    return HasFocusItemChanged

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.setResultListFocusIndex(Index, Prehear)

    local DatabaseFrontend = App:getDatabaseFrontend()
    local BrowserController = DatabaseFrontend:getBrowserController()
    local ResultListModel = DatabaseFrontend:getBrowserModel():getResultListModel()
    local FocusItem = ResultListModel:getFocusItem()
    local NumItems = ResultListModel:getItemCount()
    local NextItem = math.bound(Index, 0, NumItems - 1)

    -- set focus
    BrowserController:changeResultListFocus(Index - FocusItem, false, NI.DB3.BrowserController.SOURCE_DEFAULT, false)

    if Prehear and BrowseHelper.canPrehear() then
        NI.DATA.SamplePrehearAccess.playLastDatabaseBrowserSelection(App)
    end

    return NextItem ~= FocusItem

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.setFocusProductCategoryIndex(Index)

    BrowserCache.setProductCategoryIndex(Index)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.clearAllFilters()

    BrowserCache.clearAllFilters()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getParamCachedList(Param)

    return BrowserCache.getParamContentList(Param)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.advanceIndex(FocusItem, Delta, ItemCount, CanDeselect)

    local LowerLimit = CanDeselect and -1 or 0
    return math.bound(FocusItem + Delta, LowerLimit, ItemCount - 1)

end

------------------------------------------------------------------------------------------------------------------------
-- Result list callbacks
------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.setupResultItem(ResultListItem)

    ResultListItem:style(NI.GUI.ALIGN_WIDGET_LEFT, "")
    ResultListItem:getTextLabel():style("", "")
    NI.GUI.enableCropModeForLabel(ResultListItem:getTextLabel())

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.loadResultItem(ResultListItem, Index)

    local ResultListModel = App:getDatabaseFrontend():getBrowserModel():getResultListModel()

    local Fields = {
        Name = ResultListModel:getItemName(Index),
        IsSelected = ResultListModel:isItemSelected(Index),
        IsFavorite = ResultListModel:isItemFavorite(Index)
    }

    BrowseHelper.loadResultItemFields(ResultListItem, Fields)
end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.loadResultItemFields(ResultListItem, Fields)

    ResultListItem:setText(Fields.Name)
    ResultListItem:setSelected(Fields.IsSelected)
    ResultListItem:setFavorite(Fields.IsFavorite)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.isSampleTab()

    local FileType = App:getDatabaseFrontend():getBrowserModel():getSelectedFileType()

    return FileType == NI.DB3.FILE_TYPE_LOOP_SAMPLE or
           FileType == NI.DB3.FILE_TYPE_ONESHOT_SAMPLE

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.isInstrumentsOrEffectsFileType()

    local FileType = App:getDatabaseFrontend():getBrowserModel():getSelectedFileType()

    return FileType == NI.DB3.FILE_TYPE_INSTRUMENT or
           FileType == NI.DB3.FILE_TYPE_EFFECT

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.supportsModes(FileType)

    return FileType == NI.DB3.FILE_TYPE_INSTRUMENT or
           FileType == NI.DB3.FILE_TYPE_EFFECT or
           FileType == NI.DB3.FILE_TYPE_LOOP_SAMPLE or
           FileType == NI.DB3.FILE_TYPE_ONESHOT_SAMPLE

end

------------------------------------------------------------------------------------------------------------------------
-- Prehear
------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.canPrehear()

    return NI.DATA.SamplePrehearAccess.isPrehearTypeSelected(App) and
           BrowseHelper.getResultListSize() > 0 and
           NI.DATA.SamplePrehearAccess.canPrehear(App)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.canPrehearViaPad(PadIndex)

    return NHLController:getPadMode() ~= NI.HW.PAD_MODE_STEP
        and BrowseHelper.getResultListSize() > 0
        and NI.DATA.SamplePrehearAccess.canPrehearViaPad(App, PadIndex - 1)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.prehearViaPad(PadIndex)

    if BrowseHelper.canPrehearViaPad(PadIndex) then
        NI.DATA.SamplePrehearAccess.prehearViaPad(App)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.togglePrehear()

    local PrehearEnabledParam = App:getWorkspace():getPrehearEnabledParameter()

    if NI.APP.FEATURE.UNDO_REDO then
        local NewValue = not PrehearEnabledParam:getValue()
        NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, PrehearEnabledParam, NewValue)
    else
        NI.DATA.ParameterAccess.toggleBoolParameter(App, PrehearEnabledParam)
    end

    if PrehearEnabledParam:getValue() == false then
        NI.DATA.SamplePrehearAccess.stop(App)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.isPrehearEnabled()

    return NI.DATA.SamplePrehearAccess.isPrehearTypeSelected(App) and
           App:getWorkspace():getPrehearEnabledParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.isPadPrehearEnabled()

    return NI.DATA.SamplePrehearAccess.isPadPrehearTypeSelected(App) and
           App:getWorkspace():getPrehearEnabledParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.changePrehearVolume(Increment)

    if NI.DATA.SamplePrehearAccess.isPrehearTypeSelected(App) then
        NI.DATA.SamplePrehearAccess.changeVolume(App, Increment)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Page helpers
------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.onLocate()

    NI.DATA.QuickBrowseAccess.restoreQuickBrowse(App)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.ConvertIncrementToDirectionStep(Increment)

    return Increment > 0 and 1 or -1

end

------------------------------------------------------------------------------------------------------------------------

local function adjustIncrementForFastScrolling(Increment, ShiftPressed, Multiplier)

    local IncrementStep = BrowseHelper.ConvertIncrementToDirectionStep(Increment)

    if ShiftPressed then
        IncrementStep = IncrementStep * Multiplier
    end

    return IncrementStep

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getIncrementStep(Increment, ShiftPressed)

    return adjustIncrementForFastScrolling(Increment, ShiftPressed, 20)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getIncrementStepMikroMK3(Increment, ShiftPressed)

    return adjustIncrementForFastScrolling(Increment, ShiftPressed, 7)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.toggleLoadGroupWithSoundRouting()

    local param = App:getWorkspace():getLoadGroupWithSoundRoutingParameter()
    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, param, not param:getValue())

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.toggleLoadGroupWithPattern()

    local param = App:getWorkspace():getLoadGroupWithPatternParameter()
    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, param, not param:getValue())

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.deleteFocusItems()
    if BrowseHelper.getUserMode() then
        local DatabaseFrontend = App:getDatabaseFrontend()
        local BrowserController = DatabaseFrontend:getBrowserController()
        BrowserController:deleteResultListSelectionItems(false)

    end

end

------------------------------------------------------------------------------------------------------------------------
-- Load
------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.loadFocusItem()

    local DatabaseFrontend = App:getDatabaseFrontend()
    local BrowserController = DatabaseFrontend:getBrowserController()
    BrowserController:loadSelectedResultListItem(App, false)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.loadFocusItemInsertMode()

    local MixingLayer = NI.DATA.StateHelper.getFocusMixingLayer(App)

    if MixingLayer then
        local Slot = NI.DATA.StateHelper.getFocusSlot(App)
        local SlotIndex = Slot and NI.DATA.StateHelper.getFocusSlotIndex(App) + 1 or MixingLayer:getChain():getSlots():size()

        NI.DATA.FileAccess.loadSlotInsertMode(App, MixingLayer, SlotIndex)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.closeInsertMode()

    BrowseHelper.setInsertMode(NI.DATA.INSERT_MODE_OFF)

    -- close browse page and go back to control page
    if NHLController.getPageStack then
        NHLController:getPageStack():popToBottomPage()
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Filter helpers
------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.updateBankChain(Labels)

    for Index = 3, 1, -1 do

        BrowseHelper.updateBankChainSingleLabel(Labels[Index], Index - 1)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.updateBankChainSingleLabel(Label, Index)  -- 0-indexed

    local Name, ShortName = BrowseHelper.getBankChainEntry(Index)

    Label:setText(string.upper(ShortName or Name))

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getBankChainEntry(Index)  -- 0-indexed

    if Index == 0 or BrowseHelper.getBankChainSlotItemCount(Index) > 0 then

        local SelectedSlotItem = BrowseHelper.getBankChainSelectedSlotItem(Index)

        if SelectedSlotItem == NPOS then
            return "ALL"
        else

            local ShortNamePath = ""
            for BCIndex = 0, Index do

                local SelectedIndex = BrowseHelper.getBankChainSelectedSlotItem(BCIndex)

                ShortNamePath = ShortNamePath .. BrowseHelper.getParamContent(PARAM_BC1 + BCIndex, SelectedIndex)

                if BCIndex < Index then
                    ShortNamePath = ShortNamePath .. "|"
                end
            end

            local Name = BrowseHelper.getParamContent(PARAM_BC1 + Index, SelectedSlotItem)
            local FallbackName = BrowseHelper.extractProductName(Name)
            local ShortName = ResourceHelper.getShortName(ShortNamePath, FallbackName)

            return Name, ShortName
        end
    else
        return ""
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.updateAttributes(Labels)

    for Index = 1, 3 do
        BrowseHelper.updateAttributesSingleLabel(Labels[Index], Index - 1)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.updateAttributesSingleLabel(Label, Index)  -- 0-indexed

    local DatabaseFrontend = App:getDatabaseFrontend()
    local BrowserModel     = DatabaseFrontend:getBrowserModel()
    local Attributes       = BrowserModel:getAttributesModel()

    Label:setText(string.upper(BrowseHelper.getAttributesEntry(Index)))

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getAttributesEntry(Index)  -- 0-indexed

    if BrowseHelper.getParamMulti(PARAM_ATTR1 + Index) then
        return "MULTI"
    end

    local Count = BrowseHelper.getAttributeCount(Index)

    if Count == 0 then

        return ""
    else
        local FocusItem = BrowseHelper.getFocusAttribute(Index)

        if FocusItem == NPOS then

            return "-"
        end

        return BrowseHelper.getParamContent(PARAM_ATTR1 + Index, FocusItem)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.updateAttributesHeader(AttributesHeader)

    local Text = "TYPES"

    if  BrowseHelper.supportsModes(BrowseHelper.getFileType()) then
        Text = Text.." / CHARACTERS"
    end

    AttributesHeader:setText(Text)

end

------------------------------------------------------------------------------------------------------------------------
-- Helper for the control page insert mode
------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getInsertMode()

    return App:getWorkspace():getHWInsertModeParameter():getValue()
end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.setInsertMode(State)

    local InsertModeParameter = App:getWorkspace():getHWInsertModeParameter()
    NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, InsertModeParameter, State)
end

------------------------------------------------------------------------------------------------------------------------
-- forces the file type to INSTRUMENT, EFFECT or SAMPLE
------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.isFileTypeInsertModeValid(FileType)

    return FileType == NI.DB3.FILE_TYPE_EFFECT or
        (BrowseHelper.isInstrumentSlot() and
            (FileType == NI.DB3.FILE_TYPE_INSTRUMENT or
             FileType == NI.DB3.FILE_TYPE_LOOP_SAMPLE or
             FileType == NI.DB3.FILE_TYPE_ONESHOT_SAMPLE))
end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.isCurrentFileTypeInsertModeValid()

    local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)

    if not Slots or BrowseHelper.getInsertMode() ~= NI.DATA.INSERT_MODE_FRESH then
        return true
    end

    local FileType = App:getDatabaseFrontend():getBrowserModel():getSelectedFileType()

    return BrowseHelper.isFileTypeInsertModeValid(FileType)
end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.setFileType(FileType)

    local CurrentFileType = App:getDatabaseFrontend():getBrowserModel():getSelectedFileType()

    if CurrentFileType ~= FileType then
        local DeferredSearch = App:getBrowserControllerDeferredSearch()
        DeferredSearch:setFileTypeSelection(NI.DB3.filetypes.getFileTypeName(FileType))
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.setFileTypeToDefault()

    local DefaultType = BrowseHelper.isInstrumentSlot() and NI.DB3.FILE_TYPE_INSTRUMENT or NI.DB3.FILE_TYPE_EFFECT
    BrowseHelper.setFileType(DefaultType)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.hasPrevNextFileType(SamplingPage)

    local BrowserModel = App:getDatabaseFrontend():getBrowserModel()
    local FileType = BrowserModel:getSelectedFileType()

    if SamplingPage then
        return FileType == NI.DB3.FILE_TYPE_ONESHOT_SAMPLE, FileType == NI.DB3.FILE_TYPE_LOOP_SAMPLE
    end

    local HasPrev, HasNext = BrowserModel:hasPreviousVisibleFileType(), BrowserModel:hasNextVisibleFileType()

    -- KK does not have InsertMode, yet.
    if App:getWorkspace().getHWInsertModeParameter and BrowseHelper.getInsertMode() ~= NI.DATA.INSERT_MODE_OFF then
        if not BrowseHelper.isInstrumentSlot() then
            return false, false
        end

        return HasPrev and FileType > NI.DB3.FILE_TYPE_INSTRUMENT, HasNext
    end

    return HasPrev, HasNext

end

------------------------------------------------------------------------------------------------------------------------
-- Slot helpers
------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.isInstrumentSlot()

    -- using StateHelper here, as StateCache causes update problems

    local Song           = NI.DATA.StateHelper.getFocusSong(App)
    local LevelTab       = Song and Song:getLevelTab() or NI.DATA.LEVEL_TAB_SONG

    local Slots          = NI.DATA.StateHelper.getFocusChainSlots(App)
    local IsFirstSlot    = false

    if BrowseHelper.getInsertMode() ~= NI.DATA.INSERT_MODE_OFF then
        IsFirstSlot          = Slots and Slots:size() == 0 or false
    else
        local Slot           = NI.DATA.StateHelper.getFocusSlot(App)

        local FocusSlotIndex = (Slots and Slot) and Slots:calcIndex(Slot) or NPOS
        IsFirstSlot          = (Slots and Slots:size() == 0) or FocusSlotIndex == 0
    end

    return (LevelTab == NI.DATA.LEVEL_TAB_SOUND and IsFirstSlot)

end

------------------------------------------------------------------------------------------------------------------------
-- LED
------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getLEDStatesSlotSelectedByIndex(PadIndex, ShiftPressed) -- PadIndex >= 1

    local StateCache = App:getStateCache()
    local Slots      = NI.DATA.StateHelper.getFocusChainSlots(App)

    local Selected, Enabled = false, false

    if Slots then
        if ShiftPressed then

            local Slot = Slots:at(PadIndex - 1)

            Enabled  = Slot ~= nil
            Selected = Slot and Slot:getActiveParameter():getValue() or false

        else

            local FocusSlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)

            Enabled  = PadIndex <= Slots:size() + 1
            Selected = (PadIndex == Slots:size() + 1 and FocusSlotIndex == -1) or PadIndex - 1 == FocusSlotIndex

        end
    end

    return Selected, Enabled

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.hasPrevNextPluginSlot(Next)

    local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)

    if Slots then

        local FocusSlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)

        if Next then
            return FocusSlotIndex < Slots:size() and FocusSlotIndex >= 0
        else
            return Slots:size() > 0 and FocusSlotIndex ~= 0
        end

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.onPrevNextPluginSlot(Next)

    if BrowseHelper.hasPrevNextPluginSlot(Next) then

        local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)

        if Slots then
            NI.DATA.ChainAccess.shiftSlotFocus(App, Slots, Next and 1 or -1)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------
-- Favorites
------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.isFavoritesFilterEnabled()

    local BrowserModel = App:getDatabaseFrontend():getBrowserModel()
    return BrowserModel:isFavoritesFilterEnabled()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.toggleFavoritesFilter()

    local BrowserController = App:getDatabaseFrontend():getBrowserController()
    BrowserController:toggleFavoritesFilter(true, false)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.isFocusItemFavorite()

    local ResultListModel = App:getDatabaseFrontend():getBrowserModel():getResultListModel()
    local FocusItem = ResultListModel:getFocusItem()

	if FocusItem ~= NPOS then
		return ResultListModel:isItemFavorite(FocusItem)
	end

	return NPOS

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.toggleFocusItemFavoriteState()

    local BrowserController = App:getDatabaseFrontend():getBrowserController()
    local ResultListModel = App:getDatabaseFrontend():getBrowserModel():getResultListModel()
    local FocusItem = ResultListModel:getFocusItem()

    BrowserController:toggleFavorite(FocusItem)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.getProductsSortOrder()

    return App:getDatabaseFrontend():getBrowserModel():getProductModel():getSortOrder()

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.setProductsSortOrder(SortOrder)

    App:getDatabaseFrontend():getBrowserController():setProductsOrder(SortOrder, false)

end

------------------------------------------------------------------------------------------------------------------------
-- Set JogWheelMode to Mode or if it's already set to Mode the to JOGWHEEL_MODE_CUSTOM.
-- Save the old mode to the Page's OldJogWheelMode variable so it can be restored when leaving the page.
function BrowseHelper.toggleAndStoreJogWheelMode(Page, Mode)

    local NewMode = NHLController:getJogWheelMode() == Mode and NI.HW.JOGWHEEL_MODE_CUSTOM or Mode

    NHLController:setJogWheelMode(NewMode)
    Page.OldJogWheelMode = NewMode

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.hasPreviousPreset()

    local FocusItem = BrowseHelper.getResultListFocusItem()
    local NumItems = BrowseHelper.getResultListSize()

    return FocusItem > 0 and NumItems > 0 and FocusItem ~= NPOS

end

------------------------------------------------------------------------------------------------------------------------

function BrowseHelper.hasNextPreset()

    local FocusItem = BrowseHelper.getResultListFocusItem()
    local NumItems = BrowseHelper.getResultListSize()

    return NumItems > 0 and (FocusItem < NumItems - 1 or FocusItem == NPOS)

end

------------------------------------------------------------------------------------------------------------------------
