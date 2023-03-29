require "Scripts/Maschine/KH1062/ArrangerModel"
require "Scripts/Maschine/KH1062/IdeaSpaceModel"
require "Scripts/Maschine/KH1062/ParameterCacheModel"

require "Scripts/Maschine/Helper/GridHelper"

local ChainAccessHelper = require("Scripts/Shared/KH1062/ChainAccessHelper")
require "Scripts/Shared/KH1062/ScaleArpDataModel"

require "Scripts/Shared/MikroMK3ASeries/QuickEditMikroMK3ASeries"

require "Scripts/Shared/Helpers/ActionHelper"
require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/ModuleHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
DataModel = class( 'DataModel' )

------------------------------------------------------------------------------------------------------------------------

function DataModel:__init()

    self.ChainModel = ChainAccessHelper.createChainModel({
        getFocusChainSlots = ChainAccessHelper.getFocusSoundSlots,
        canToggleFocusSlotActive = function ()
            return MaschineHelper.getFocusedSoundSlot() ~= nil
        end,
        canRemoveFocusSlot = function()
            return true
        end
    })

    self.ArrangerModel = ArrangerModel()
    self.IdeaSpaceModel = IdeaSpaceModel()
    self.ParameterCacheModel = ParameterCacheModel(function ()
        return self:isFocusGroupDrumKitModeEnabled()
    end)
    self.ScaleArpDataModel = ScaleArpDataModel()

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:isFocusGroupIndexValid()

    return NI.DATA.StateHelper.getFocusGroupIndex(App) ~= NPOS

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:getOneBasedFocusGroupIndex()

    return NI.DATA.StateHelper.getFocusGroupIndex(App) + 1

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:getOneBasedFocusSoundIndex()

    return NI.DATA.StateHelper.getFocusSoundIndex(App) + 1

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:getFocusGroupData()

    local OneBasedFocusGroupIndex = self:getOneBasedFocusGroupIndex()
    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)

    return
    {
        OneBasedIndex = OneBasedFocusGroupIndex,
        DisplayName = FocusGroup and FocusGroup:getDisplayName() or "",
        GroupLabel = FocusGroup and NI.DATA.Group.getLabel(OneBasedFocusGroupIndex - 1) or "",
        IsMuted = FocusGroup and FocusGroup:getMuteParameter():getValue() or false
    }

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:getFocusSoundData()

    local OneBasedFocusSoundIndex = self:getOneBasedFocusSoundIndex(App)
    local FocusSound = NI.DATA.StateHelper.getFocusSound(App)

    return
    {
        OneBasedIndex = OneBasedFocusSoundIndex,
        DisplayName = FocusSound and FocusSound:getDisplayName() or "Sound " .. OneBasedFocusSoundIndex,
        IsMuted = FocusSound and FocusSound:getMuteParameter():getValue()
    }

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:isFocusSoundMuted()

    local FocusSound = NI.DATA.StateHelper.getFocusSound(App)
    return FocusSound and FocusSound:getMuteParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:isFocusSoundSoloed()

    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)
    local FocusSound = NI.DATA.StateHelper.getFocusSound(App)
    return FocusGroup and FocusSound and NI.DATA.GroupAccess.isMuteExclusive(FocusGroup, FocusSound)

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:isFocusGroupMuted()

    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)
    return FocusGroup and FocusGroup:getMuteParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:isFocusGroupSoloed()

    local FocusSong = NI.DATA.StateHelper.getFocusSong(App)
    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)
    return FocusSong and FocusGroup and NI.DATA.SongAccess.isMuteExclusive(FocusSong, FocusGroup)

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:isOnLastGroup()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups()
    return self:getOneBasedFocusGroupIndex() == Groups:size()

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:getFocusSongGroupCount()

    return MaschineHelper.getFocusSongGroupCount()

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:isQuantizeAvailable()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local IsIdeaSpace = Song and Song:getArrangerState():isViewInIdeaSpace() and ArrangerHelper.isIdeaSpaceFocused()
    local HasEvents = IsIdeaSpace
        and (MaschineHelper.isDrumkitMode() and ActionHelper.hasGroupEvents() or ActionHelper.hasSoundEvents())
    return HasEvents and GridHelper.isSnapEnabled(GridHelper.STEP)

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:isUndoAvailable()

    return App:getTransactionManager():canUndoMarker()

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:isRedoAvailable()

    return App:getTransactionManager():canRedoMarker()

end

------------------------------------------------------------------------------------------------------------------------

function DataModel.isFocusSlotValid()

    return NI.DATA.StateHelper.getFocusSlot(App) ~= nil

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:isRecordAutoEnabled()

    return NI.DATA.WORKSPACE.isAutoWriteEnabledFromKompleteKontrol(App)

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:isFocusGroupDrumKitModeEnabled()

    return MaschineHelper.isDrumkitMode()

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:getCurrentProjectDisplayName()

    return App:getProject():getCurrentProjectDisplayName()

end

------------------------------------------------------------------------------------------------------------------------

local function getModuleType(Slot)

    if ModuleHelper.isSlotMissing(Slot) then
        return
    end

    return ModuleHelper.isSlotFX(Slot) and NI.DATA.ModuleInfo.TYPE_EFFECT or
                                           NI.DATA.ModuleInfo.TYPE_INSTRUMENT

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:getFocusedChainInfo()

    local Slot = MaschineHelper.getFocusedSoundSlot()

    return {
        FocusSound = self:getFocusSoundData(),
        FocusSlot = Slot and {
            ModuleType = getModuleType(Slot),
            DisplayName = NI.DATA.SlotAlgorithms.getDisplayName(Slot),
            IsActive = Slot:getActiveParameter():getValue()
        } or nil,
        ChainSize = self.ChainModel.getFocusedChainSize()
    }

end

------------------------------------------------------------------------------------------------------------------------

function DataModel:getSongTempoString()

    return QuickEditMikroMK3ASeries.getSongTempoString()

end
