local StateButtonMap_Down = {}
local StateButtonMap_Up = {}
local StatePadMap_Down = {}
local StatePadMap_Up = {}
local StateEncoderMap_Left = {}
local StateEncoderMap_Right = {}
local StateWheelMap_Left = {}
local StateWheelMap_Right = {}

Frame = 0

-- Constants
OFF = 1
DIM = 2
DIM_FLASH = 3
ON = 4
FLASH = 5
local LEDLevels = {0, 0.15, 0.5, 0.95, 1}

RED = 0
ORANGE = 1
LIGHT_ORANGE = 2
WARM_YELLOW = 3
YELLOW = 4
LIME = 5
GREEN = 6
MINT = 7
CYAN = 8
TURQUOISE = 9
BLUE = 10
PLUM = 11
VIOLET = 12
PURPLE = 13
MAGENTA = 14
FUCHSIA = 15
WHITE = 16

LEDColors = {}
LEDColors[0] = { {32,0,0},  {127,0,0}}
LEDColors[1] = { {32,8,0},  {127,12,0}}
LEDColors[2] = { {42,16,0}, {127,48,0}}
LEDColors[3] = { {32,24,0}, {127,74,0}}
LEDColors[4] = { {32,32,0}, {127,110,0}}
LEDColors[5] = { {16,32,0}, {38,127,0}}
LEDColors[6] = { {0,32,0},  {0,127,0}}
LEDColors[7] = { {0,32,09}, {0,127,32}}
LEDColors[8] = { {0,32,28}, {0,127,120}}
LEDColors[9] = { {0,16,32}, {0,60,127} }
LEDColors[10] ={ {0,0,32},  {0,0,127}  }
LEDColors[11] ={ {12,0,32}, {38,0,127} }
LEDColors[12] ={ {22,0,32}, {86,0,127} }
LEDColors[13] ={ {32,0,20}, {127,0,62} }
LEDColors[14] ={ {32,0,10}, {127,0,30} }
LEDColors[15] ={ {32,0,4},  {127,0,10} }
LEDColors[16] ={ {32,32,32},{127,127,127} }


------------------------------------------------------------------------------------------------------------------------
-- API
------------------------------------------------------------------------------------------------------------------------

function IsClassic()
	local Model = NHLController:getControllerAcronym()
	return Model == "M1" or Model == "M2"
end

function IsMikro()
	local Model = NHLController:getControllerAcronym()
	return Model == "MM1" or Model == "MM2"
end

function IsStudio()
	local Model = NHLController:getControllerAcronym()
	return Model == "MS1"
end

function IsJam()
	local Model = NHLController:getControllerAcronym()
	return Model == "MJ1"
end

function IsKK()
	local Model = NHLController:getControllerAcronym()
	return Model == "KK25" or Model == "KK49" or Model == "KK61" or Model == "KK88" or Model == "KKS2"
end

HW = NI.HW


------------------------------------------------------------------------------------------------------------------------

function Screen(Path)

	if ControllerScriptInterface.Screen then
		Path = NHLController:getLoadingPath()..Path

	    local Picture = NI.UTILS.PictureManager.getPictureOrLoadFromDisk(Path, false)
	    if Picture then
			ControllerScriptInterface.Screen:setPicture(Picture)
		else
			print("! Could not load "..Path)
		end
	end
end

------------------------------------------------------------------------------------------------------------------------

function OSO(Path)

	Path = NHLController:getLoadingPath()..Path

    local Picture = NI.UTILS.PictureManager.getPictureOrLoadFromDisk(Path, false)
    if Picture then

		App:getScriptableOverlay():show(true)
		App:getScriptableOverlay():setPicture(Picture)

	else
		print("! Could not load "..Path)
	end
end

------------------------------------------------------------------------------------------------------------------------

function OSO_Close()

    App:getScriptableOverlay():show(false)

end

------------------------------------------------------------------------------------------------------------------------

function LED_Reset()

	NHLController:resetAllLEDs()
	NHLController:updateLEDs(false)
end

------------------------------------------------------------------------------------------------------------------------
-- Intensity = ON by default, Color = optional
function LED(ID, Intensity, Color)

	Intensity = Intensity or ON

	if Color and Intensity ~= OFF then

		if IsJam() then

			NHLController:setLEDColor(ID, Color, Intensity)

		elseif not IsKK() and ((ID >= HW.LED_GROUP_A and ID <= HW.LED_GROUP_H) or (ID >= HW.LED_PAD_1 and ID <= HW.LED_PAD_16)) then
			local RGB = Intensity == ON and LEDColors[Color][2] or LEDColors[Color][1]

			NHLController:setLEDColor(ID, RGB[1], RGB[2], RGB[3])
		else
			print("! LED is not RGB")
		end
	else
		NHLController:setLEDLevel(ID, LEDLevels[Intensity])
	end

	NHLController:updateLEDs(false)
end

------------------------------------------------------------------------------------------------------------------------

function Button_Down(ID, State)

	StateButtonMap_Down[ID] = State
end

------------------------------------------------------------------------------------------------------------------------

function Button_Up(ID, State)

	StateButtonMap_Up[ID] = State
end

------------------------------------------------------------------------------------------------------------------------

function Pad_Down(ID, State)

	StatePadMap_Down[ID] = State
end

------------------------------------------------------------------------------------------------------------------------

function Pad_Up(ID, State)

	StatePadMap_Up[ID] = State
end

------------------------------------------------------------------------------------------------------------------------

function Encoder_Left(ID, State)

	StateEncoderMap_Left[ID] = State
end

------------------------------------------------------------------------------------------------------------------------

function Encoder_Right(ID, State)

	StateEncoderMap_Right[ID] = State
end

------------------------------------------------------------------------------------------------------------------------

function Wheel_Left(ID, State)

	StateWheelMap_Left[ID] = State
end

------------------------------------------------------------------------------------------------------------------------

function Wheel_Right(ID, State)

	StateWheelMap_Right[ID] = State
end

------------------------------------------------------------------------------------------------------------------------
-- Controller
------------------------------------------------------------------------------------------------------------------------

local function callState(State)

	Frame = 0
	print("Calling State #"..State)
	if _VERSION == "Lua 5.1" then
		loadstring("State_"..State.."()")()
	else
		load("State_"..State.."()")()
	end
end

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
Controller = class( 'Controller' )

------------------------------------------------------------------------------------------------------------------------

function Controller:__init()

	NHLController:resetAllLEDs()
    NI.UTILS.PictureManager.clearCache()

    if NHLController.getHardwareDisplay then
    	local Root = NHLController:getHardwareDisplay():getPageStack()
		self.Screen = NI.GUI.insertPictureBar(Root, "Screen")

		Root:setTop(self.Screen)

		self.Screen:setWidth(Root:getWidth())
		self.Screen:setHeight(Root:getHeight())

		self.Screen:setVisible(true)

		self.Screen:setBGColor(0, 0, 0, 255)
		self.Screen:resetPicture()
	end

	OSO_Close()

end

------------------------------------------------------------------------------------------------------------------------

function Controller:onSwitchEvent(SwitchID, Pressed)

	local State

	if Pressed then
		State = StateButtonMap_Down[SwitchID]
		print("Pushed Button #"..SwitchID)
	else
		State = StateButtonMap_Up[SwitchID]
		print("Released Button #"..SwitchID)
	end

	if State then
		callState(State)
	end

end

------------------------------------------------------------------------------------------------------------------------

function Controller:onEncoderEvent(Encoder, Value)

	local State

	if Value < 0 then
		State = StateEncoderMap_Left[Encoder]
		print("Moved Encoder #"..Encoder.." Left")
	else
		State = StateEncoderMap_Right[Encoder]
		print("Moved Encoder #"..Encoder.." Right")
	end

	if State then
		callState(State)
	end

end

------------------------------------------------------------------------------------------------------------------------

function Controller:onWheelEvent(Wheel, Value)

	local State

	if Value < 0 then
		State = StateWheelMap_Left[Wheel]
		print("Moved Wheel #"..Wheel.." Left")
	else
		State = StateWheelMap_Right[Wheel]
		print("Moved Wheel #"..Wheel.." Right")
	end

	if State then
		callState(State)
	end
end

------------------------------------------------------------------------------------------------------------------------

function Controller:onPadEvent(Pad, Pressed, Velocity)

	local State

	if Pressed then
		State = StatePadMap_Down[Pad]
		print("Pushed Pad #"..Pad.." ("..Velocity..")")
	else
		State = StatePadMap_Up[Pad]
		print("Released Pad #"..Pad)
	end

	if State then
		callState(State)
	end

end

------------------------------------------------------------------------------------------------------------------------

function Controller:onControllerTimer()

	Frame = Frame + 1
	--print("Frame", Frame)
	loadstring("if OnTimer then OnTimer() end")()

	if _VERSION == "Lua 5.1" then
		loadstring("if OnTimer then OnTimer() end")()
	else
		load("if OnTimer then OnTimer() end")()
	end

end

------------------------------------------------------------------------------------------------------------------------

function Controller:onStateFlagsChanged()

	--print("Maschine State Changed")
end

------------------------------------------------------------------------------------------------------------------------
-- Create Instance
------------------------------------------------------------------------------------------------------------------------

ControllerScriptInterface = Controller()
loadControllerScripts = function() end
OnTimer = function() end

--[[
------------------------------------------------------------------------------------------------------------------------
REFERENCE - LEDs
------------------------------------------------------------------------------------------------------------------------


LED_TRANSPORT_LOOP,
LED_TRANSPORT_PREV,
LED_TRANSPORT_NEXT,
LED_TRANSPORT_GRID,
LED_TRANSPORT_PLAY,
LED_TRANSPORT_RECORD,
LED_TRANSPORT_ERASE,
LED_SHIFT,
LED_TRANSPORT_EVENTS, //!< Studio Only
LED_TRANSPORT_METRO, //!< Studio Only

LED_F1,     //!< MaschineMikro only
LED_F2,     //!< MaschineMikro only
LED_F3,     //!< MaschineMikro only
LED_MAIN,   //!< MaschineMikro only
LED_NAV,    //!< MaschineMikro only
LED_GROUP,  //!< MaschineMikro only

LED_CHANNEL,  //!< Studio Only
LED_PLUGIN,   //!< Studio Only

LED_SCENE,
LED_PATTERN,
LED_PAD_MODE,
LED_NAVIGATE,
LED_DUPLICATE,
LED_SELECT,
LED_SOLO,
LED_MUTE,

LED_VOLUME,         //!< MaschineMK2 only
LED_SWING,          //!< MaschineMK2 only
LED_TEMPO,          //!< MaschineMK2 only
LED_MASTER_LEFT,    //!< MaschineMK2 only
LED_MASTER_RIGHT,   //!< MaschineMK2 only
LED_TAP,            //!< MaschineStudio only
LED_ENTER,          //!< MaschineMK2 and MaschineMikroMK1 only
LED_BACK,           //!< Studio Only
LED_MACRO,          //!< Studio Only
LED_NOTE_REPEAT,

LED_CONTROL,    //!< MaschineMK1, MaschineMK2 and MaschineMikroMK2 only
LED_STEP,       //!< MaschineMK1 and MaschineMK2 only
LED_BROWSE,
LED_SAMPLE,
LED_LEFT,
LED_RIGHT,
LED_SNAP,       //!< MaschineMK1 and Studio only
LED_ALL,       //!< MaschineMK2 and Studio only
LED_AUTO_WRITE, //!< MaschineMK1 and MaschineMK2 only
LED_ARRANGE,    //!< Studio Only
LED_MIX,        //!< Studio Only

LED_GROUP_A,
LED_GROUP_B,
LED_GROUP_C,
LED_GROUP_D,
LED_GROUP_E,
LED_GROUP_F,
LED_GROUP_G,
LED_GROUP_H,

LED_PAD_1,
LED_PAD_2,
LED_PAD_3,
LED_PAD_4,
LED_PAD_5,
LED_PAD_6,
LED_PAD_7,
LED_PAD_8,
LED_PAD_9,
LED_PAD_10,
LED_PAD_11,
LED_PAD_12,
LED_PAD_13,
LED_PAD_14,
LED_PAD_15,
LED_PAD_16,

LED_JOGWHEEL_RING_1,//!< Studio Only
LED_JOGWHEEL_RING_2,//!< Studio Only
LED_JOGWHEEL_RING_3,//!< Studio Only
LED_JOGWHEEL_RING_4,//!< Studio Only
LED_JOGWHEEL_RING_5,//!< Studio Only
LED_JOGWHEEL_RING_6,//!< Studio Only
LED_JOGWHEEL_RING_7,//!< Studio Only
LED_JOGWHEEL_RING_8,//!< Studio Only
LED_JOGWHEEL_RING_9,//!< Studio Only
LED_JOGWHEEL_RING_10,//!< Studio Only
LED_JOGWHEEL_RING_11,//!< Studio Only
LED_JOGWHEEL_RING_12,//!< Studio Only
LED_JOGWHEEL_RING_13,//!< Studio Only
LED_JOGWHEEL_RING_14,//!< Studio Only
LED_JOGWHEEL_RING_15,//!< Studio Only

LED_JOGWHEEL_EDIT,//!< Studio Only
LED_JOGWHEEL_CHANNEL,//!< Studio Only
LED_JOGWHEEL_BROWSE,//!< Studio Only
LED_JOGWHEEL_TUNE,//!< Studio Only
LED_JOGWHEEL_SWING,//!< Studio Only
LED_JOGWHEEL_VOLUME,//!< Studio Only

LED_LEVEL_MIDI_IN,    //!< Studio Only
LED_LEVEL_MIDI_OUT1,   //!< Studio Only
LED_LEVEL_MIDI_OUT2,   //!< Studio Only
LED_LEVEL_MIDI_OUT3,   //!< Studio Only

LED_LEVEL_LEFT_1,   //!< Studio Only
LED_LEVEL_LEFT_2,   //!< Studio Only
LED_LEVEL_LEFT_3,   //!< Studio Only
LED_LEVEL_LEFT_4,   //!< Studio Only
LED_LEVEL_LEFT_5,   //!< Studio Only
LED_LEVEL_LEFT_6,   //!< Studio Only
LED_LEVEL_LEFT_7,   //!< Studio Only
LED_LEVEL_LEFT_8,   //!< Studio Only
LED_LEVEL_LEFT_9,   //!< Studio Only
LED_LEVEL_LEFT_10,   //!< Studio Only
LED_LEVEL_LEFT_11,   //!< Studio Only
LED_LEVEL_LEFT_12,   //!< Studio Only
LED_LEVEL_LEFT_13,   //!< Studio Only
LED_LEVEL_LEFT_14,   //!< Studio Only
LED_LEVEL_LEFT_15,   //!< Studio Only
LED_LEVEL_LEFT_16,   //!< Studio Only

LED_LEVEL_RIGHT_1,   //!< Studio Only
LED_LEVEL_RIGHT_2,   //!< Studio Only
LED_LEVEL_RIGHT_3,   //!< Studio Only
LED_LEVEL_RIGHT_4,   //!< Studio Only
LED_LEVEL_RIGHT_5,   //!< Studio Only
LED_LEVEL_RIGHT_6,   //!< Studio Only
LED_LEVEL_RIGHT_7,   //!< Studio Only
LED_LEVEL_RIGHT_8,   //!< Studio Only
LED_LEVEL_RIGHT_9,   //!< Studio Only
LED_LEVEL_RIGHT_10,   //!< Studio Only
LED_LEVEL_RIGHT_11,   //!< Studio Only
LED_LEVEL_RIGHT_12,   //!< Studio Only
LED_LEVEL_RIGHT_13,   //!< Studio Only
LED_LEVEL_RIGHT_14,   //!< Studio Only
LED_LEVEL_RIGHT_15,   //!< Studio Only
LED_LEVEL_RIGHT_16,   //!< Studio Only

LED_LEVEL_COLOR,   //!< Studio Only

LED_LEVEL_IN1,   //!< Studio Only
LED_LEVEL_IN2,   //!< Studio Only
LED_LEVEL_IN3,   //!< Studio Only
LED_LEVEL_IN4,   //!< Studio Only

LED_LEVEL_MASTER,   //!< Studio Only
LED_LEVEL_GROUP,   //!< Studio Only
LED_LEVEL_SOUND,   //!< Studio Only
LED_LEVEL_CUE,   //!< Studio Only

LED_EDIT_COPY,     //!< Studio Only
LED_EDIT_PASTE,    //!< Studio Only
LED_EDIT_NOTE,     //!< Studio Only
LED_EDIT_NUDGE,    //!< Studio Only
LED_EDIT_UNDO,     //!< Studio Only
LED_EDIT_REDO,     //!< Studio Only
LED_EDIT_QUANTIZE, //!< Studio Only
LED_EDIT_CLEAR,    //!< Studio Only

LED_SCREEN_BUTTON_1,
LED_SCREEN_BUTTON_2,
LED_SCREEN_BUTTON_3,
LED_SCREEN_BUTTON_4,
LED_SCREEN_BUTTON_5,
LED_SCREEN_BUTTON_6,
LED_SCREEN_BUTTON_7,
LED_SCREEN_BUTTON_8,


------------------------------------------------------------------------------------------------------------------------
REFERENCE - MASCHINE Buttons
------------------------------------------------------------------------------------------------------------------------

BUTTON_F1,      //!< MaschineMikro only
BUTTON_F2,      //!< MaschineMikro only
BUTTON_F3,      //!< MaschineMikro only
BUTTON_MAIN,    //!< MaschineMikro only
BUTTON_NAV,     //!< MaschineMikro only
BUTTON_GROUP,   //!< MaschineMikro only

BUTTON_CHANNEL, //!< MaschineStudio only
BUTTON_PLUGIN,  //!< MaschineStudio only

BUTTON_CONTROL, //!< MaschineMK1, MaschineMK2 and MaschineMikroMK2 only
BUTTON_STEP,    //!< MaschineMK1 and MaschineMK2 only
BUTTON_BROWSE,
BUTTON_SAMPLE,
BUTTON_LEFT,
BUTTON_RIGHT,
BUTTON_ALL,        //!< MaschineMK2 and MaschineStudio only
BUTTON_SNAP,        //!< MaschineMK1 and MaschineStudio only
BUTTON_AUTO_WRITE,  //!< MaschineMK1 and MaschineMK2 only
BUTTON_ARRANGE,     //!< MaschineStudio only
BUTTON_MIX,     //!< MaschineStudio only

BUTTON_VOLUME,      //!< MaschineMK2 only
BUTTON_SWING,       //!< MaschineMK2 only
BUTTON_TEMPO,       //!< MaschineMK2 only
BUTTON_MASTER_LEFT, //!< MaschineMK2 only
BUTTON_MASTER_RIGHT,//!< MaschineMK2 only
BUTTON_ENTER,       //!< MaschineMK2 and MaschineMikroMK1 only
BUTTON_WHEEL,       //!< MaschineMK2 and MaschineMikro only
BUTTON_BACK,        //!< MaschineStudio only

BUTTON_TAP,         //!< MaschineStudio only
BUTTON_MACRO,
BUTTON_NOTE_REPEAT, //!< MaschineStudio only

BUTTON_TRANSPORT_LOOP,
BUTTON_TRANSPORT_METRO,
BUTTON_TRANSPORT_PREV,
BUTTON_TRANSPORT_NEXT,
BUTTON_TRANSPORT_GRID,
BUTTON_TRANSPORT_PLAY,
BUTTON_TRANSPORT_RECORD,
BUTTON_TRANSPORT_ERASE,
BUTTON_TRANSPORT_EVENTS,
BUTTON_SHIFT,

BUTTON_SCENE,
BUTTON_PATTERN,
BUTTON_PAD_MODE,
BUTTON_NAVIGATE,
BUTTON_DUPLICATE,
BUTTON_SELECT,
BUTTON_SOLO,
BUTTON_MUTE,

BUTTON_GROUP_A, //!< MaschineMK1 and MaschineMK2 only
BUTTON_GROUP_B, //!< MaschineMK1 and MaschineMK2 only
BUTTON_GROUP_C, //!< MaschineMK1 and MaschineMK2 only
BUTTON_GROUP_D, //!< MaschineMK1 and MaschineMK2 only
BUTTON_GROUP_E, //!< MaschineMK1 and MaschineMK2 only
BUTTON_GROUP_F, //!< MaschineMK1 and MaschineMK2 only
BUTTON_GROUP_G, //!< MaschineMK1 and MaschineMK2 only
BUTTON_GROUP_H, //!< MaschineMK1 and MaschineMK2 only

BUTTON_SCREEN_1, //!< MaschineMK1 and MaschineMK2 only
BUTTON_SCREEN_2, //!< MaschineMK1 and MaschineMK2 only
BUTTON_SCREEN_3, //!< MaschineMK1 and MaschineMK2 only
BUTTON_SCREEN_4, //!< MaschineMK1 and MaschineMK2 only
BUTTON_SCREEN_5, //!< MaschineMK1 and MaschineMK2 only
BUTTON_SCREEN_6, //!< MaschineMK1 and MaschineMK2 only
BUTTON_SCREEN_7, //!< MaschineMK1 and MaschineMK2 only
BUTTON_SCREEN_8, //!< MaschineMK1 and MaschineMK2 only

BUTTON_CAP_1, //!< MaschineStudio Only
BUTTON_CAP_2, //!< MaschineStudio Only
BUTTON_CAP_3, //!< MaschineStudio Only
BUTTON_CAP_4, //!< MaschineStudio Only
BUTTON_CAP_5, //!< MaschineStudio Only
BUTTON_CAP_6, //!< MaschineStudio Only
BUTTON_CAP_7, //!< MaschineStudio Only
BUTTON_CAP_8, //!< MaschineStudio Only

BUTTON_LEVEL_IN1,     //!< MaschineStudio Only
BUTTON_LEVEL_IN2,     //!< MaschineStudio Only
BUTTON_LEVEL_IN3,     //!< MaschineStudio Only
BUTTON_LEVEL_IN4,     //!< MaschineStudio Only
BUTTON_LEVEL_MASTER,  //!< MaschineStudio Only
BUTTON_LEVEL_GROUP,   //!< MaschineStudio Only
BUTTON_LEVEL_SOUND,   //!< MaschineStudio Only
BUTTON_LEVEL_CUE,     //!< MaschineStudio Only

BUTTON_EDIT_COPY,     //!< MaschineStudio Only
BUTTON_EDIT_PASTE,    //!< MaschineStudio Only
BUTTON_EDIT_NOTE,     //!< MaschineStudio Only
BUTTON_EDIT_NUDGE,    //!< MaschineStudio Only
BUTTON_EDIT_UNDO,     //!< MaschineStudio Only
BUTTON_EDIT_REDO,     //!< MaschineStudio Only
BUTTON_EDIT_QUANTIZE, //!< MaschineStudio Only
BUTTON_EDIT_CLEAR,    //!< MaschineStudio Only

BUTTON_FOOT1_DETECT,  //!< MaschineStudio Only
BUTTON_FOOT1_TIP,     //!< MaschineStudio Only
BUTTON_FOOT1_RING,    //!< MaschineStudio Only
BUTTON_FOOT2_DETECT,  //!< MaschineStudio Only
BUTTON_FOOT2_TIP,     //!< MaschineStudio Only
BUTTON_FOOT2_RING,    //!< MaschineStudio Only

------------------------------------------------------------------------------------------------------------------------
REFERENCE - JAM Buttons
------------------------------------------------------------------------------------------------------------------------

BUTTON_SONG,
BUTTON_SCENE_1,
BUTTON_SCENE_2,
BUTTON_SCENE_3,
BUTTON_SCENE_4,
BUTTON_SCENE_5,
BUTTON_SCENE_6,
BUTTON_SCENE_7,
BUTTON_SCENE_8,
BUTTON_A1,
BUTTON_B1,
BUTTON_C1,
BUTTON_D1,
BUTTON_E1,
BUTTON_F1,
BUTTON_G1,
BUTTON_H1,
BUTTON_A2,
BUTTON_B2,
BUTTON_C2,
BUTTON_D2,
BUTTON_E2,
BUTTON_F2,
BUTTON_G2,
BUTTON_H2,
BUTTON_A3,
BUTTON_B3,
BUTTON_C3,
BUTTON_D3,
BUTTON_E3,
BUTTON_F3,
BUTTON_G3,
BUTTON_H3,
BUTTON_A4,
BUTTON_B4,
BUTTON_C4,
BUTTON_D4,
BUTTON_E4,
BUTTON_F4,
BUTTON_G4,
BUTTON_H4,
BUTTON_A5,
BUTTON_B5,
BUTTON_C5,
BUTTON_D5,
BUTTON_E5,
BUTTON_F5,
BUTTON_G5,
BUTTON_H5,
BUTTON_A6,
BUTTON_B6,
BUTTON_C6,
BUTTON_D6,
BUTTON_E6,
BUTTON_F6,
BUTTON_G6,
BUTTON_H6,
BUTTON_A7,
BUTTON_B7,
BUTTON_C7,
BUTTON_D7,
BUTTON_E7,
BUTTON_F7,
BUTTON_G7,
BUTTON_H7,
BUTTON_A8,
BUTTON_B8,
BUTTON_C8,
BUTTON_D8,
BUTTON_E8,
BUTTON_F8,
BUTTON_G8,
BUTTON_H8,
BUTTON_GROUP_A,
BUTTON_GROUP_B,
BUTTON_GROUP_C,
BUTTON_GROUP_D,
BUTTON_GROUP_E,
BUTTON_GROUP_F,
BUTTON_GROUP_G,
BUTTON_GROUP_H,
BUTTON_STEP,
BUTTON_PAD_MODE,
BUTTON_CLEAR,
BUTTON_DUPLICATE,
BUTTON_DPAD_1,
BUTTON_DPAD_4,
BUTTON_DPAD_2,
BUTTON_DPAD_3,
BUTTON_ARP_REPEAT,
BUTTON_MST,
BUTTON_GRP,
BUTTON_IN1,
BUTTON_CUE,
ENCODER_BROWSE,
TOUCH_BROWSE,
BUTTON_WHEEL,
BUTTON_BROWSE,
BUTTON_MACRO,
BUTTON_LEVEL,
BUTTON_AUX,
BUTTON_CONTROL,
BUTTON_AUTO,
BUTTON_PERFORM,
BUTTON_NOTES,
BUTTON_LOCK,
BUTTON_TUNE,
BUTTON_SWING,
BUTTON_SHIFT,
BUTTON_PLAY,
BUTTON_RECORD,
BUTTON_ARROW_LEFT,
BUTTON_ARROW_RIGHT,
BUTTON_TEMPO,
BUTTON_GRID,
BUTTON_SOLO,
BUTTON_MUTE,
BUTTON_SELECT,
FOOT_TIP,
FOOT_RING


------------------------------------------------------------------------------------------------------------------------
REFERENCE - JAM LEDs
------------------------------------------------------------------------------------------------------------------------

LED_SCENE_1,
LED_SCENE_2,
LED_SCENE_3,
LED_SCENE_4,
LED_SCENE_5,
LED_SCENE_6,
LED_SCENE_7,
LED_SCENE_8,

LED_A1,
LED_B1,
LED_C1,
LED_D1,
LED_E1,
LED_F1,
LED_G1,
LED_H1,
LED_A2,
LED_B2,
LED_C2,
LED_D2,
LED_E2,
LED_F2,
LED_G2,
LED_H2,
LED_A3,
LED_B3,
LED_C3,
LED_D3,
LED_E3,
LED_F3,
LED_G3,
LED_H3,
LED_A4,
LED_B4,
LED_C4,
LED_D4,
LED_E4,
LED_F4,
LED_G4,
LED_H4,
LED_A5,
LED_B5,
LED_C5,
LED_D5,
LED_E5,
LED_F5,
LED_G5,
LED_H5,
LED_A6,
LED_B6,
LED_C6,
LED_D6,
LED_E6,
LED_F6,
LED_G6,
LED_H6,
LED_A7,
LED_B7,
LED_C7,
LED_D7,
LED_E7,
LED_F7,
LED_G7,
LED_H7,
LED_A8,
LED_B8,
LED_C8,
LED_D8,
LED_E8,
LED_F8,
LED_G8,
LED_H8,

LED_GROUP_A,
LED_GROUP_B,
LED_GROUP_C,
LED_GROUP_D,
LED_GROUP_E,
LED_GROUP_F,
LED_GROUP_G,
LED_GROUP_H,

LED_STEP,
LED_PAD_MODE,
LED_CLEAR,
LED_DUPLICATE,
LED_DPAD_1,
LED_DPAD_4,
LED_DPAD_2,
LED_DPAD_3,
LED_SELECT,

LED_BROWSE,
LED_MACRO,
LED_LEVEL,
LED_AUX,
LED_CONTROL,
LED_AUTO,
LED_PERFORM,
LED_NOTES,
LED_LOCK,
LED_TUNE,
LED_SWING,

LED_SHIFT,
LED_PLAY,
LED_RECORD,
LED_ARROW_LEFT,
LED_ARROW_RIGHT,
LED_TEMPO,
LED_GRID,
LED_SOLO,
LED_MUTE,
LED_ARP_REPEAT,

LED_METER1_01,
LED_METER1_02,
LED_METER1_03,
LED_METER1_04,
LED_METER1_05,
LED_METER1_06,
LED_METER1_07,
LED_METER1_08,
LED_METER2_01,
LED_METER2_02,
LED_METER2_03,
LED_METER2_04,
LED_METER2_05,
LED_METER2_06,
LED_METER2_07,
LED_METER2_08,

LED_MST,
LED_GRP,
LED_IN1,
LED_CUE,

LED_TS_A01,
LED_TS_A02,
LED_TS_A03,
LED_TS_A04,
LED_TS_A05,
LED_TS_A06,
LED_TS_A07,
LED_TS_A08,
LED_TS_A09,
LED_TS_A10,
LED_TS_A11,
LED_TS_B01,
LED_TS_B02,
LED_TS_B03,
LED_TS_B04,
LED_TS_B05,
LED_TS_B06,
LED_TS_B07,
LED_TS_B08,
LED_TS_B09,
LED_TS_B10,
LED_TS_B11,
LED_TS_C01,
LED_TS_C02,
LED_TS_C03,
LED_TS_C04,
LED_TS_C05,
LED_TS_C06,
LED_TS_C07,
LED_TS_C08,
LED_TS_C09,
LED_TS_C10,
LED_TS_C11,
LED_TS_D01,
LED_TS_D02,
LED_TS_D03,
LED_TS_D04,
LED_TS_D05,
LED_TS_D06,
LED_TS_D07,
LED_TS_D08,
LED_TS_D09,
LED_TS_D10,
LED_TS_D11,
LED_TS_E01,
LED_TS_E02,
LED_TS_E03,
LED_TS_E04,
LED_TS_E05,
LED_TS_E06,
LED_TS_E07,
LED_TS_E08,
LED_TS_E09,
LED_TS_E10,
LED_TS_E11,
LED_TS_F01,
LED_TS_F02,
LED_TS_F03,
LED_TS_F04,
LED_TS_F05,
LED_TS_F06,
LED_TS_F07,
LED_TS_F08,
LED_TS_F09,
LED_TS_F10,
LED_TS_F11,
LED_TS_G01,
LED_TS_G02,
LED_TS_G03,
LED_TS_G04,
LED_TS_G05,
LED_TS_G06,
LED_TS_G07,
LED_TS_G08,
LED_TS_G09,
LED_TS_G10,
LED_TS_G11,
LED_TS_H01,
LED_TS_H02,
LED_TS_H03,
LED_TS_H04,
LED_TS_H05,
LED_TS_H06,
LED_TS_H07,
LED_TS_H08,
LED_TS_H09,
LED_TS_H10,
LED_TS_H11,

]]