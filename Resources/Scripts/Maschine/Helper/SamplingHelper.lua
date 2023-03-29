------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SamplingHelper = class( 'SamplingHelper' )

------------------------------------------------------------------------------------------------------------------------

SamplingHelper.EditFuncNames = {"TRUNCATE", "NORMALIZE", "REVERSE", "FADE IN", "FADE OUT", "FIX DC", "SILENCE",
    "CUT", "COPY", "PASTE", "DUPLICATE", "STRETCH", "AUTOLOOP"}
SamplingHelper.EditFuncNamesShort = {"TRUNC", "NORM", "REV", "FD IN", "FD OUT", "FIX DC", "SILENCE",
    "CUT", "COPY", "PASTE", "DUPL", "STRCH", "LOOP"}

SamplingHelper.EditFuncTruncate     = 1
SamplingHelper.EditFuncNormalize    = 2
SamplingHelper.EditFuncReverse      = 3
SamplingHelper.EditFuncFadeIn       = 4
SamplingHelper.EditFuncFadeOut      = 5
SamplingHelper.EditFuncFixDC        = 6
SamplingHelper.EditFuncSilence      = 7
SamplingHelper.EditFuncCut          = 8
SamplingHelper.EditFuncCopy         = 9
SamplingHelper.EditFuncPaste        = 10
SamplingHelper.EditFuncDuplicate    = 11
SamplingHelper.EditFuncStretch      = 12
SamplingHelper.EditFuncAutoLoop     = 13
SamplingHelper.NumEditFuncs         = SamplingHelper.EditFuncAutoLoop


SamplingScreenMode =
{
    RECORD  = 0,
    EDIT    = 1,
    SLICE   = 2,
    ZONE    = 3
}

SamplingHelper.SamplingTabNames = {"RECORD", "EDIT", "SLICE", "ZONE"}

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.isOnTabRecord()

    return NI.DATA.WORKSPACE.getSamplingTab(App) == SamplingScreenMode.RECORD

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.isOnTabEdit()

    return NI.DATA.WORKSPACE.getSamplingTab(App) == SamplingScreenMode.EDIT

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.isOnTabSlice()

    return NI.DATA.WORKSPACE.getSamplingTab(App) == SamplingScreenMode.SLICE

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.isOnTabZone()

    return NI.DATA.WORKSPACE.getSamplingTab(App) == SamplingScreenMode.ZONE

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.getFocusTake()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local Takes = Sound and NI.DATA.SoundAlgorithms.getTakes(Sound) or nil
    return Takes and Takes:getFocusObject() or nil

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.getFocusRecording()

    local Take = SamplingHelper.getFocusTake()
    return Take and Take:getTransactionSample() or nil

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.getFocusTakeIndex()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local Takes = Sound and NI.DATA.SoundAlgorithms.getTakes(Sound) or nil
    local FocusObject = Takes and Takes:getFocusObject()

    return FocusObject and Takes:calcIndex(FocusObject) or nil

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.removeFocusTake()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local Takes = Sound and NI.DATA.SoundAlgorithms.getTakes(Sound)
    local Take = Takes and Takes:getFocusObject()
    if not Take then
        return
    end

    NI.DATA.SoundAccess.removeTake(App, Sound, Take)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.getFocusSampleLengthAsText()

    return NI.DATA.StateHelper.getFocusSampleLengthAsString(App)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.startStopRecordingPreview(Start)

    local TransactionSample = SamplingHelper.getFocusRecording()
    local Preview = App:getPreview()

    if Sample and Preview then

        if Start and TransactionSample then
            Preview:load(TransactionSample:getFileLocation())
            Preview:play()
        else
            Preview:stop()
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.toggleRecording()

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)

    if Recorder then
        NI.DATA.RecorderAccess.toggleRecording(App, Recorder)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.requestCancelRecording()

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)

    if Recorder then
        NI.DATA.RecorderAccess.requestCancelRecording(App, Recorder)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.isRecorderWaitingOrRecording()

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)

    return Recorder and (Recorder:isWaiting() or Recorder:isRecording())

end


------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.showTimeStretchSettings(bShow)

    local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)
    local Zone = Sampler and Sampler:getZones():getFocusObject() or nil

    if Zone then
        NI.DATA.SamplingParametersAccess.showTimeStretchSettings(App, Zone, bShow)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.toggleTimeStretchSettings()

    local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)
    local Zone = Sampler and Sampler:getZones():getFocusObject() or nil

    if Zone then
        local bVisible = Zone:getTimeStretchVisibleParameter():getValue()
        NI.DATA.SamplingParametersAccess.showTimeStretchSettings(App, Zone, not bVisible)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.timeStretchSettingsVisible()

    local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)
    local Zone = Sampler and Sampler:getZones():getFocusObject() or nil

    return Zone and Zone:getTimeStretchVisibleParameter():getValue()

end


------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.areTimeStretchParamsInRange()

    local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)
    local Zone = Sampler and Sampler:getZones():getFocusObject() or nil
    local Params = Zone and Zone:getTimeStretchParameters() or nil

    if Params==nil then
        return true -- default parameters (b/c not created yet), so they are in range
    else
        return Params:areParametersInRange()
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.hasSampler()

    return NI.DATA.StateHelper.getFocusSampler(App, nil) ~= nil

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.hasAudioModule()

    return NI.DATA.StateHelper.getFocusAudioModule(App) ~= nil

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.checkScreenMode(SamplingPage)

    local Mode = NI.DATA.WORKSPACE.getSamplingTab(App)

    if SamplingPage.ScreenMode ~= Mode then
        SamplingPage:setMode(Mode)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.getNumRecordingPages()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local Takes = Sound and NI.DATA.SoundAlgorithms.getTakes(Sound) or nil
    local NumObjects = Takes and Takes:size() or 0

    return math.floor((NumObjects+15) / 16)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.canPrevNextTake()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local Takes = Sound and NI.DATA.SoundAlgorithms.getTakes(Sound) or nil
    local NumObjects = Takes and Takes:size() or 0
    local FocusObject = NumObjects > 0 and Takes:getFocusObject() or nil

    if FocusObject then
        local FocusIndex = Takes:calcIndex(FocusObject)

        return FocusIndex > 0, FocusIndex < NumObjects-1
    elseif NumObjects > 0 then
        return true, true
    end

    return false, false

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.setFocusTake(Index, PreHear)

    local Sound = NI.DATA.StateHelper.getFocusSound(App)

    local Takes = Sound and NI.DATA.SoundAlgorithms.getTakes(Sound)
    local NumObjects = Takes and Takes:size() or 0

    if (Index > 0) and (Index <= NumObjects) then
        local NewFocusObject = Takes:at(Index - 1)

        if NewFocusObject then

            local FocusTake = SamplingHelper.getFocusTake()

            if FocusTake == nil or NewFocusObject:getName() ~= FocusTake:getName() then

                NI.DATA.SoundAccess.loadAndFocusTake(App, Sound, NewFocusObject)
            end

            if PreHear then
                NI.DATA.SamplePrehearAccess.playSample(App,
                    NewFocusObject:getTransactionSample():getFileLocation(), nil)
            end
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.onPrevNextTake(Increment)

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local Takes = Sound and NI.DATA.SoundAlgorithms.getTakes(Sound)
    local NumObjects = Takes and Takes:size() or 0
    local FocusObject = NumObjects > 0 and Takes:getFocusObject() or nil
    local NewIndex

    if FocusObject then

        local FocusIndex = Takes:calcIndex(FocusObject)
        local LastIndex = NumObjects - 1
        NewIndex = FocusIndex + Increment

    elseif NumObjects > 0 then

        if Increment > 0 then
            NewIndex = 0
        elseif Increment < 0 then
            NewIndex = NumObjects - 1
        end

    end

    if NewIndex ~= nil and NewIndex >= 0 and NewIndex < NumObjects then
        local NewFocusObject = Takes:at(NewIndex)
        if NewFocusObject then

            NI.DATA.SoundAccess.loadAndFocusTake(App, Sound, NewFocusObject)
        end
    end


end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.applyEditFunction(EditFunction)

    if EditFunction == SamplingHelper.EditFuncFadeIn then
        NI.DATA.FocusSampleAccess.fadeIn(App)
    elseif EditFunction == SamplingHelper.EditFuncFadeOut then
        NI.DATA.FocusSampleAccess.fadeOut(App)
    elseif EditFunction == SamplingHelper.EditFuncFixDC then
        NI.DATA.FocusSampleAccess.removeDC(App)
    elseif EditFunction == SamplingHelper.EditFuncSilence then
        NI.DATA.FocusSampleAccess.silence(App)
    elseif EditFunction == SamplingHelper.EditFuncCut then
        NI.DATA.FocusSampleAccess.cut(App)
    elseif EditFunction == SamplingHelper.EditFuncCopy then
        NI.DATA.FocusSampleAccess.copy(App)
    elseif EditFunction == SamplingHelper.EditFuncPaste then
        NI.DATA.FocusSampleAccess.paste(App)
    elseif EditFunction == SamplingHelper.EditFuncDuplicate then
        NI.DATA.FocusSampleAccess.duplicate(App)
    elseif EditFunction == SamplingHelper.EditFuncTruncate then
        NI.DATA.FocusSampleAccess.truncate(App)
    elseif EditFunction == SamplingHelper.EditFuncNormalize then
        NI.DATA.FocusSampleAccess.normalize(App)
    elseif EditFunction == SamplingHelper.EditFuncReverse then
        NI.DATA.FocusSampleAccess.reverse(App)
    elseif EditFunction == SamplingHelper.EditFuncStretch then
        NI.DATA.FocusSampleAccess.timestretch(App)
    elseif EditFunction == SamplingHelper.EditFuncAutoLoop then
        local Zone = NI.DATA.StateHelper.getFocusZone(App, nil)
        if Zone then
            NI.DATA.ZoneAccess.findAndSetLoopPoints(App, Zone)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.getNumEditFunctions()

    if NI.DATA.StateHelper.getFocusSampler(App, nil) then
        return SamplingHelper.NumEditFuncs
    elseif NI.DATA.StateHelper.getFocusAudioModule(App) then
        return SamplingHelper.NumEditFuncs - 2 -- Exclude Stretch and Auto loop
    else
        return 0
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Recorded sample item vector size
------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.getTakeListCount()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local Takes = Sound and NI.DATA.SoundAlgorithms.getTakes(Sound)

    return Takes and Takes:size() or 0

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.updateRecordPagePadLeds(LEDs, RecordingBank)

    local RecordLEDStateFunctor =
        function(Index)
            local Sound = NI.DATA.StateHelper.getFocusSound(App)
            local Takes = Sound and NI.DATA.SoundAlgorithms.getTakes(Sound)
            local NumObjects = Takes and Takes:size() or 0
            local FocusObject = Takes and Takes:getFocusObject() or nil
            local FocusIndex = FocusObject and Takes:calcIndex(FocusObject) or -1

            return Index == FocusIndex+1, Index <= NumObjects
        end

    local RecordLEDColorFunctor =
        function(Index)
            local Sound = NI.DATA.StateHelper.getFocusSound(App)
            return Sound and Sound:getColorParameter():getValue() or 0
        end

            -- update pad leds with focus state
    LEDHelper.updateLEDsWithFunctor(LEDs,
        RecordingBank * 16,
        RecordLEDStateFunctor,
        RecordLEDColorFunctor)

end

------------------------------------------------------------------------------------------------------------------------

local BlinkTick = 0

function SamplingHelper.updateSlicePagePadLeds(LEDs, SliceBank, IsPadSlicingEnabled)

    local SliceLEDStateFunctor =
        function(Index)
            local NumSlices, FocusSliceIndex =  SamplingHelper.getNumSlicesAndFocusSliceIndex()

            local IsSlicePlaying = NI.DATA.SamplePrehearAccess.isFocusedZonePlaying(App)
            local IsSlicerWaiting = IsPadSlicingEnabled and not IsSlicePlaying and NumSlices == 1 and Index == 1
            local IsSlicerPad = IsSlicePlaying and IsPadSlicingEnabled and FocusSliceIndex == NumSlices - 1 and Index == NumSlices+1


            -- blink?
            if IsSlicerPad or IsSlicerWaiting then
                BlinkTick = BlinkTick + 1
                if IsSlicerPad and (BlinkTick % 8 < 4) or IsSlicerWaiting and (BlinkTick % 64 < 32) then
                    return false, true
                else
                    return true, true
                end
            end

            local Selected = FocusSliceIndex ~= NPOS and Index == FocusSliceIndex+1
            local Enabled = NumSlices > 0 and Index <= NumSlices

            return Selected, Enabled
        end

    local SliceLEDColorFunctor =
        function(Index)
            local NumSlices, FocusSliceIndex =  SamplingHelper.getNumSlicesAndFocusSliceIndex()

            local Sound = NI.DATA.StateHelper.getFocusSound(App)
            local SoundColor = Sound and Sound:getColorParameter():getValue() or 0

            return SoundColor
        end

    -- update pad leds with focus state
    LEDHelper.updateLEDsWithFunctor(LEDs, SliceBank * 16, SliceLEDStateFunctor, SliceLEDColorFunctor)


end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.setFocusSlice(Index, PreHear)

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Slices = TransactionSample and TransactionSample:getSliceContainer()
    local NumSlices = Slices and Slices:getNumSlices() or 0

    if (Index > 0) and (Index <= NumSlices) then
        NI.DATA.TransactionSampleAccess.setFocusSliceByIndex(App, TransactionSample, Index-1, true)

        if PreHear then
            local SliceRange = Slices:getFocusSliceFrameRange()
            NI.DATA.SamplePrehearAccess.playSample(App,
                TransactionSample:getFileLocation(), SliceRange)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.preHearSlice(Index)

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Slices = TransactionSample and TransactionSample:getSliceContainer()
    local NumSlices = Slices and Slices:getNumSlices() or 0

    if (Index > 0) and (Index <= NumSlices) then
        local SliceRange = Slices:getFocusSliceFrameRange()
        NI.DATA.SamplePrehearAccess.playSample(App, TransactionSample:getFileLocation(), SliceRange)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.getSlicingMode()

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Slices = TransactionSample and TransactionSample:getSliceContainer()

    return Slices and Slices:getSliceModeParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.isFocusSliceChanged()

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Slices = TransactionSample and TransactionSample:getSliceContainer()
    return Slices and Slices:isFocusSliceChanged() or false

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.shiftFocusSliceIndex(Inc)

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Slices = TransactionSample and TransactionSample:getSliceContainer()
    local NumSlices = Slices and Slices:getNumSlices() or 0
    local FocusSliceIndex = Slices and Slices:getFocusSliceIndex() or NPOS

    if FocusSliceIndex == NPOS then
        FocusSliceIndex = Inc > 0 and 0 or NumSlices-1
    else
        FocusSliceIndex = math.bound(FocusSliceIndex + Inc, 0, NumSlices - 1)
    end

    SamplingHelper.setFocusSlice(FocusSliceIndex + 1, false)

end

------------------------------------------------------------------------------------------------------------------------
-- Calculate the slice page (aka bank) index for usage on 16 pads
function SamplingHelper.updateSlicePadPage(CurPadPage, ForceUpdate, IsPadSlicingEnabled)

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Slices = TransactionSample and TransactionSample:getSliceContainer()

    if Slices then
        -- Calc pad page based on focused slice index, or if that doesn't exist, the number of slices,
        if Slices:isFocusSliceChanged() or ForceUpdate then
            local IsSlicePlaying = NI.DATA.SamplePrehearAccess.isFocusedZonePlaying(App)
            local FocusOnSlicerPad = IsPadSlicingEnabled and IsSlicePlaying and SamplingHelper.isLastSliceFocused() and 1 or 0

            local RefSliceIndex = Slices:getFocusSliceIndex() ~= NPOS and Slices:getFocusSliceIndex()
                or math.max(Slices:getNumSlices()-1, 0)
            RefSliceIndex = RefSliceIndex + FocusOnSlicerPad
            CurPadPage = math.floor(RefSliceIndex/16)
        end
    end

    return CurPadPage

end

------------------------------------------------------------------------------------------------------------------------
-- per design, moves the start point with the previous slice's end point and snaps to it if disconnected
--	  or      moves the end point, always disconnects from the next slice's start point.
function SamplingHelper.moveFocusSlice(Start, Inc, Fine, SnapAmount)

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Slices = TransactionSample and TransactionSample:getSliceContainer()
    local FocusSliceIndex = Slices and Slices:getFocusSliceIndex() or NPOS

    if FocusSliceIndex == NPOS then
        return
    end

    local FocusZone = NI.DATA.StateHelper.getFocusZone(App, nil)
    local Zoom = FocusZone and FocusZone:getZoomFactorParameter():getValue() or 1
    local NumFrames = SamplingHelper.getFocusSampleLength()
    local Delta = Fine and math.sgn(Inc) or (Inc / Zoom / 2) * NumFrames

    local SliceRange = Slices:getFocusSliceFrameRange()

    if Start then
        NI.DATA.TransactionSampleAccess.moveSliceStart(App, TransactionSample,
            FocusSliceIndex, math.max(SliceRange:getMin() + Delta, 0), true, SnapAmount or 10)
    else
        local NewEndFrame = math.max(SliceRange:getMax() + Delta, SliceRange:getMin())
        NI.DATA.TransactionSampleAccess.moveSliceEnd(App, TransactionSample,
            FocusSliceIndex, NewEndFrame, false, 0)
    end

end


------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.isLastSliceFocused()

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Slices = TransactionSample and TransactionSample:getSliceContainer()

    return Slices and Slices:getFocusSliceIndex()+1 == Slices:getNumSlices() or false
end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.getNumSlicePages(IsPadSlicingEnabled)

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Slices = TransactionSample and TransactionSample:getSliceContainer()

    local IsSlicePlaying = NI.DATA.SamplePrehearAccess.isFocusedZonePlaying(App)
    local ShowSlicerPad = IsPadSlicingEnabled and IsSlicePlaying and SamplingHelper.isLastSliceFocused()

    local NumSlices = Slices and (Slices:getNumSlices() + (ShowSlicerPad and 1 or 0)) or 0

    return math.floor((NumSlices+15) / 16)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.sliceFocusSlice()

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Slices = TransactionSample and TransactionSample:getSliceContainer()
    local FocusSliceIndex = Slices and Slices:getFocusSliceIndex() or NPOS

    if FocusSliceIndex ~= NPOS then
        NI.DATA.TransactionSampleAccess.splitSlice(App, TransactionSample, FocusSliceIndex)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.removeFocusSlice()

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Slices = TransactionSample and TransactionSample:getSliceContainer()
    local FocusSliceIndex = Slices and Slices:getFocusSliceIndex() or NPOS

    if FocusSliceIndex ~= NPOS then
        NI.DATA.TransactionSampleAccess.removeSliceMarker(App, TransactionSample, FocusSliceIndex)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.removeAllSlices()

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    NI.DATA.TransactionSampleAccess.removeAllSlices(App, TransactionSample)

end


------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.getNumSlicesAndFocusSliceIndex()
    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Slices = TransactionSample and TransactionSample:getSliceContainer()
    local NumSlices = Slices and Slices:getNumSlices() or 0
    local FocusSliceIndex = Slices and Slices:getFocusSliceIndex() or NPOS

    return NumSlices, FocusSliceIndex

end

------------------------------------------------------------------------------------------------------------------------
-- Apply Slicing to target Group / Sound. All parameters can be nil
------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.applySlicing(GroupIndex, SoundIndex, Single)

    local FocusZone = NI.DATA.StateHelper.getFocusZone(App, nil)
    local TransactionSample = FocusZone and FocusZone:getTransactionSample() or nil

    local SliceID = Single and TransactionSample and TransactionSample:getSliceContainer()
        and TransactionSample:getSliceContainer():getFocusSliceIndex() or NPOS

    -- Apply to Group
    if GroupIndex ~= nil and GroupIndex ~= 0 and (SoundIndex == nil or SoundIndex == 0) then

        if TransactionSample then
            if SliceID ~= NPOS then
                NI.DATA.SamplerAccess.applySingleSliceToSound(App, TransactionSample, GroupIndex -1, 0, SliceID)
            else
                NI.DATA.SamplerAccess.applySlicingToGroup(App, TransactionSample, GroupIndex - 1)
            end
        end

    -- Apply to Sound
    else

        GroupIndex = (GroupIndex == nil or GroupIndex == 0) and NI.DATA.StateHelper.getFocusGroupIndex(App) or GroupIndex - 1
        SoundIndex = (SoundIndex == nil or SoundIndex == 0) and NI.DATA.StateHelper.getFocusSoundIndex(App) or SoundIndex - 1

        if TransactionSample then
            if SliceID ~= NPOS then
                NI.DATA.SamplerAccess.applySingleSliceToSound(App, TransactionSample, GroupIndex, SoundIndex, SliceID)
            else
                NI.DATA.SamplerAccess.applySlicingToSound(App, TransactionSample, GroupIndex, SoundIndex)
            end
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.removeFocusZone()

    local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)
    local FocusZone = Sampler and Sampler:getZones():getFocusObject()

    if Sampler and FocusZone then
        NI.DATA.SamplerAccess.removeZone(App, Sampler, FocusZone)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.createNewZone()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)

    if Sound then
        NI.DATA.SoundAccess.createZone(App, Sound)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.getNumZones()

    local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)
    local Zones = Sampler and Sampler:getZones()

    if Zones then
        return Zones:size()
    end

    return 0

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.getFocusZoneIndex()

    local StateCache = App:getStateCache()
    local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)
    local Zones = Sampler and Sampler:getZones()
    local FocusZone = Zones and Zones:getFocusObject()

    if FocusZone then
        return Zones:calcIndex(FocusZone)
    end

    return 0

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.canPrevNextZone()

    local Index = SamplingHelper.getFocusZoneIndex()
    local NumZones = SamplingHelper.getNumZones()

    return Index ~= NPOS and Index > 0, Index < NumZones - 1

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.selectPrevNextZone(Next)

    local CanPrev, CanNext = SamplingHelper.canPrevNextZone()

    local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)

    if Sampler then
        if (Next and CanNext) or (not Next and CanPrev) then
            NI.DATA.SamplerAccess.cycleZoneSelection(App, Sampler, Next)
            return true
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.getFocusSampleLength()

    return NI.DATA.StateHelper.getFocusSampleLength(App)

end

------------------------------------------------------------------------------------------------------------------------
-- Zooms on waveform
function SamplingHelper.zoomWaveForm(EncoderInc, Fine, RecordTab)

    EncoderInc = EncoderInc * (Fine and 0.1 or 1)

    local View = SamplingHelper.makeFocusSampleOwnerView(RecordTab)

    local SampleLength = SamplingHelper.getFocusSampleLength()

    if not View or SampleLength == 0 then
        return
    end

    local OffsetParam = View:waveOffsetParameter()
    local ZoomParam = View:waveZoomParameter()
    local FocusFrameParam = View:waveFocusFrameParameter()

    local Delta
    if _VERSION == "Lua 5.1" then
        Delta = math.pow(1.06, EncoderInc * 100.0 )
    else
        Delta = 1.06 ^ (EncoderInc * 100.0)
    end
    local Zoom  = math.bound(ZoomParam:getValue() * Delta, 1, ZoomParam:getMax());

    -- calc appropriate offset according to new zoom and focus tick
    local OldFocusFrame = FocusFrameParam:getValue()
    local ViewLength = SampleLength / Zoom
    local Offset = math.bound(OldFocusFrame - (ViewLength / 2), 0, SampleLength - ViewLength)

    NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, OffsetParam, Offset)
    NI.DATA.ParameterAccess.setDoubleParameterNoUndo(App, ZoomParam, Zoom)
    NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, FocusFrameParam, OldFocusFrame)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.resetSliceStartOrEnd(EditSliceStart)

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Slices = TransactionSample and TransactionSample:getSliceContainer()
    local FocusSliceIndex = Slices and Slices:getFocusSliceIndex() or NPOS
    local NumSlices = Slices and Slices:getNumSlices() or 0

    if FocusSliceIndex == NPOS then
        return
    end

    if Slices then

        if EditSliceStart then

            local NewStartFrame = 0
            if FocusSliceIndex > 0 then
                local PrevSlice = Slices:getSliceByIndex(FocusSliceIndex - 1)
                NewStartFrame = PrevSlice:getEndFrame()
            end
            NI.DATA.TransactionSampleAccess.moveSliceStart(App, TransactionSample,
                                                                    FocusSliceIndex, NewStartFrame, false, 0)
        else

            local NumFrames = NI.DATA.StateHelper.getFocusSampleLength(App)
            local NewEndFrame = NumFrames
            if FocusSliceIndex < NumSlices - 1 then
                local NextSlice = Slices:getSliceByIndex(FocusSliceIndex + 1)
                NewEndFrame = NextSlice:getStartFrame()
            end
            NI.DATA.TransactionSampleAccess.moveSliceEnd(App, TransactionSample,
                                                                  FocusSliceIndex, NewEndFrame, false, 0)
        end

    end
end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.getDisplayZoomValueWaveForm(ZoomParam)

    local SampleLength = SamplingHelper.getFocusSampleLength()

    local Zoom = ZoomParam:getValue()
    local ViewLength = SampleLength / Zoom
    local MinZoom = SampleLength / ZoomParam:getMax()
    local ZoomFactor = ViewLength / SampleLength

    return math.ceil((1 - (ViewLength / (SampleLength - (MinZoom * (1 - ZoomFactor))))) * 1000) / 10.0

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.makeFocusSampleOwnerView(RecordTab)

    if RecordTab then
        return NI.DATA.SampleOwnerViewHelper.makeFocusTakeView(App)
    else
        return NI.DATA.SampleOwnerViewHelper.makeFocusView(App)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Scrolls waveform
function SamplingHelper.scrollWaveForm(EncoderInc, Fine, RecordTab)

    EncoderInc = EncoderInc * (Fine and 0.1 or 1)

    local View = SamplingHelper.makeFocusSampleOwnerView(RecordTab)

    local SampleLength = SamplingHelper.getFocusSampleLength()

    if not View or SampleLength == 0 then
        return
    end

    local Zoom = View:waveZoomParameter():getValue()
    local ViewLength = SampleLength / Zoom
    local OldFocusFrame = View:waveFocusFrameParameter():getValue()
    local Delta = EncoderInc * ViewLength * 2
    local OldOffset = View:waveOffsetParameter():getValue()
    local Offset = math.bound(OldOffset + Delta, 0, SampleLength - ViewLength + 1)

    if OldOffset == Offset then
        return
    end

    local NewFocusFrame = Offset + ViewLength / 2

    NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, View:waveOffsetParameter(), Offset)
    NI.DATA.ParameterAccess.setDoubleParameterNoUndo(App, View:waveZoomParameter(), Zoom)
    NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, View:waveFocusFrameParameter(), NewFocusFrame)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.onLeftRightButton(SamplPage, Right)

    NI.DATA.SamplingParametersAccess.focusPageOffset(App, SamplPage.ScreenMode, Right and 1 or -1)

end


------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.sliceNoUndo()

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    if TransactionSample then
        NI.DATA.TransactionSampleAccess.sliceNoUndo(App, TransactionSample)
    end
end


------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.getAnalysisState()

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    local Slices = TransactionSample and TransactionSample:getSliceContainer()
    return Slices and Slices:getAnalysisState()
end


------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.refreshAnalysisProgress()

    local TransactionSample = NI.DATA.StateHelper.getFocusTransactionSample(App)
    if TransactionSample then
        NI.DATA.TransactionSampleAccess.updateAnalysisProgress(App, TransactionSample)
    end
end


------------------------------------------------------------------------------------------------------------------------

function SamplingHelper.isLoopArmed()

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)

    if not Recorder then
        return false
    end

    local LoopMode = Recorder:getRecordingModeParameter():getValue() == NI.DATA.MODE_LOOP
    local HasSampler = NI.DATA.StateHelper.getFocusSampler(App, nil) ~= nil
    local HasAudioModule = NI.DATA.StateHelper.getFocusAudioModule(App) ~= nil

    return not HasSampler and (HasAudioModule or LoopMode)

end

------------------------------------------------------------------------------------------------------------------------
