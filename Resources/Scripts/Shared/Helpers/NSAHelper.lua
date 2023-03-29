------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
NSAHelper = class( 'NSAHelper' )

local NSA = App:getNSA()

local PendingAudioChannelMappings = {[true] = {}, [false] = {}} -- 2 lists for Inputs and Outputs

------------------------------------------------------------------------------------------------------------------------
-- Drivers
------------------------------------------------------------------------------------------------------------------------

function NSAHelper.getDriverList()

	local Drivers = {}

	for Index = 0, NSA:getDriverCount() - 1 do
		table.insert(Drivers, NSA:getDriverName(Index))
	end

	return Drivers, NSA:getCurrentDriver()

end

------------------------------------------------------------------------------------------------------------------------

function NSAHelper.selectPrevNextDriver(Next)

	local Drivers, Current = NSAHelper.getDriverList()
	local Index = table.findKey(Drivers, Current)

	Index = math.bound(Index + (Next and 1 or -1), 1, #Drivers)
	NSA:setDriver(Drivers[Index])

end

------------------------------------------------------------------------------------------------------------------------
-- Devices
------------------------------------------------------------------------------------------------------------------------

function NSAHelper.getCurrentDevice()

	return NSA:getCurrentDevice()

end

------------------------------------------------------------------------------------------------------------------------

function NSAHelper.getDeviceList()

	local Devices = {}

	for Index = 0, NSA:getDeviceCount() - 1 do
		table.insert(Devices, NSA:getDeviceName(Index))
	end

	return Devices, NSA:getCurrentDevice()

end

------------------------------------------------------------------------------------------------------------------------

function NSAHelper.selectPrevNextDevice(Next)

    local Devices, Current = NSAHelper.getDeviceList()
    local Index = table.findKey(Devices, Current)

    if Index then
        Index = math.bound(Index + (Next and 1 or -1), 1, #Devices)
        NSA:setDevice(Devices[Index])
    elseif NSA:getDeviceCount() > 0 then
        NSA:setDevice(NSA:getDeviceName(0))
    end

    if NI.APP.isNativeOS() then
        NSA:setBufferSize(128)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Sample Rate
------------------------------------------------------------------------------------------------------------------------

function NSAHelper.getSampleRateList()

	local SampleRates = {}

	for Index = 0, NSA:getSamplerateCount() - 1 do
		table.insert(SampleRates, tostring(NSA:getSamplerateValue(Index)))
	end

	return SampleRates, tostring(NSA:getCurrentSamplerate())

end

------------------------------------------------------------------------------------------------------------------------

function NSAHelper.selectPrevNextSampleRate(Next)

	local SampleRates, Current = NSAHelper.getSampleRateList()
	local Index = table.findKey(SampleRates, Current)

	Index = math.bound(Index + (Next and 1 or -1), 1, #SampleRates)
	NSA:setSamplerate(tonumber(SampleRates[Index]))

end

------------------------------------------------------------------------------------------------------------------------
-- Buffer Size
------------------------------------------------------------------------------------------------------------------------

function NSAHelper.getBufferSize()

	return tostring(NSA:getCurrentBufferSizeValue())

end

------------------------------------------------------------------------------------------------------------------------

function NSAHelper.selectPrevNextBufferSize(Next)

	local Current = NSA:getCurrentBufferSizeIndex()
	NSA:setBufferSizeIndex(Current + (Next and 1 or -1))

end

------------------------------------------------------------------------------------------------------------------------
-- Audio Routings
------------------------------------------------------------------------------------------------------------------------

function NSAHelper.getAudioChannelList(Input)

	local Channels = {}

	for Index = 0, NSA:getPhysicalChannelsCount(Input) - 1 do
		table.insert(Channels, NSA:getPhysicalChannelString(Index, Input))
	end

	return Channels

end

------------------------------------------------------------------------------------------------------------------------

function NSAHelper.getAudioChannel(Index, Input)

	-- check pending mappings first
	if PendingAudioChannelMappings[Input][Index] then
		local AudioChannels = NSAHelper.getAudioChannelList(Input)
		return AudioChannels[PendingAudioChannelMappings[Input][Index] + 1]
	end

	return NSA:getMappedChannel(Index - 1, Input)

end

------------------------------------------------------------------------------------------------------------------------
-- only effected after calling NSAHelper.commitAudioChannelMappings
function NSAHelper.requestPrevNextAudioChannel(Index, Next, Input)

	local Current = NSAHelper.getAudioChannel(Index, Input)
	local AudioChannels = NSAHelper.getAudioChannelList(Input)

	local Key = table.findKey(AudioChannels, Current)
	Key = math.bound(Key + (Next and 1 or -1), 1, #AudioChannels) - 1

	PendingAudioChannelMappings[Input][Index] = Key

end

------------------------------------------------------------------------------------------------------------------------

function NSAHelper.commitAudioChannelMappings()

	local CheckPendingAudioChannelMappings =
		function(Input)
			for Index, Channel in pairs(PendingAudioChannelMappings[Input]) do

				NSA:setMappedChannel(Index - 1, Channel, Input)
				PendingAudioChannelMappings[Input][Index] = nil
			end
		end

	CheckPendingAudioChannelMappings(true)
	CheckPendingAudioChannelMappings(false)

end

------------------------------------------------------------------------------------------------------------------------
-- MIDI Sync
------------------------------------------------------------------------------------------------------------------------

function NSAHelper.getMIDISyncStatus()

	return NSA:getMidiSyncStatus()

end

------------------------------------------------------------------------------------------------------------------------

function NSAHelper.getMIDISyncList(LinkEnabled)

	local List = LinkEnabled and {"Off", "Send Clock"} or {"Off", "Send Clock", "Receive Clock"}
	local AbbreviatedList = LinkEnabled and {"Off", "Send"} or {"Off", "Send", "Receive"}
	return List, List[NSA:getMidiSyncStatus() + 1], AbbreviatedList[NSA:getMidiSyncStatus() + 1]

end

------------------------------------------------------------------------------------------------------------------------

function NSAHelper.selectPrevNextMIDISync(Next, LinkEnabled)

    local Status = math.bound(NSA:getMidiSyncStatus() + (Next and 1 or -1), 0, LinkEnabled and 1 or 2)
    NSA:setMidiSyncStatus(Status)

end

------------------------------------------------------------------------------------------------------------------------
-- MIDI Clock Master Offset
------------------------------------------------------------------------------------------------------------------------

function NSAHelper.getMidiClockMasterSyncOffset()

	local SyncStatus = NSA:getMidiSyncStatus()
	local Offset = NSA:getCurrentClockOffset()

	-- from 0 -> 200 to 0 -> -200
	return Offset == 0 and "0" or tostring(Offset * -1) -- tostring(0 * -1) => "-0"

end

------------------------------------------------------------------------------------------------------------------------

function NSAHelper.selectPrevNextClockMasterOffset(Next)

	local Offset = math.bound(NSA:getCurrentClockOffset() + (Next and 1 or -1), 0, 200)
	NSA:setClockOffset(Offset)

end

------------------------------------------------------------------------------------------------------------------------
-- MIDI Devices
------------------------------------------------------------------------------------------------------------------------

function NSAHelper.getMIDIDevicesListSize(Input)

	return NSA:getMidiDevicesCount(Input)
end

------------------------------------------------------------------------------------------------------------------------
function NSAHelper.getMIDIDevicesList(Input)

	local List = {}

	for Index = 1, NSA:getMidiDevicesCount(Input) do
		table.insert(List, NSA:getMidiDeviceString(Index - 1, Input))
	end

	return List

end

------------------------------------------------------------------------------------------------------------------------

function NSAHelper.getMIDIDeviceState(Index, Input)

    local Count = NSA:getMidiDevicesCount(Input)
    if Count > 0 and Index <= Count then
        return NSA:getMidiDeviceState(Index - 1, Input) and "On" or "Off"
    end

    return "-"

end

------------------------------------------------------------------------------------------------------------------------

function NSAHelper.selectPrevNextMIDIDeviceStatus(Next, Index, Input)

    local Enabled = NSA:getMidiDeviceState(Index - 1, Input)

    -- Enabled -> Disabled
    if (Next and not Enabled) or (not Next and Enabled) then
        NSA:toggleMidiDevice(Index - 1, Input)
        App:updateMidiDevices()
    end
end

------------------------------------------------------------------------------------------------------------------------
-- Audio Status Labels
------------------------------------------------------------------------------------------------------------------------

function NSAHelper.getAudioStatusCaption()

	return "Device Status: "..(NSA:isDeviceRunning() and "Running" or "Missing")

end

------------------------------------------------------------------------------------------------------------------------

function NSAHelper.getAudioLatencyCaptions()

	local SampleRate = NSA:getCurrentSamplerate()
	local Input = math.round((NSA:getLatency(true) * 1000) / SampleRate * 10) / 10
	local Process = math.round((NSA:getCurrentBufferSizeValue() * 1000) / SampleRate * 10) / 10
	local Output = math.round(NSA:getLatency(false) * 1000 / SampleRate * 10) / 10
	local Total = Input + Process + Output

    return "Input: "..Input.."ms\nProcessing: "..Process.."ms\nOutput: "..Output.."ms",
		"Total Latency: "..Total.."ms"
end

------------------------------------------------------------------------------------------------------------------------

function NSAHelper.storeSetup()

    NSA:storeSetup()

end

------------------------------------------------------------------------------------------------------------------------
