export interface HomeExport {
	exportDate: string;
	appVersion: string;
	homes: HomeData[];
}

export interface HomeData {
	homeId: string;
	homeName: string;
	rooms: RoomData[];
	accessories: AccessoryData[];
	scenes: SceneData[];
	zones?: ZoneData[];
}

export interface RoomData {
	roomId: string;
	roomName: string;
	accessoryCount: number;
}

export interface AccessoryData {
	accessoryId: string;
	name: string;
	roomId: string;
	roomName: string;
	category: string;
	manufacturer: string;
	model: string;
	firmwareVersion: string;
	isReachable: boolean;
	isBridged: boolean;
	services: ServiceData[];
}

export interface ServiceData {
	serviceId: string;
	name: string;
	serviceType: string;
	isPrimary: boolean;
	characteristics: CharacteristicData[];
}

export interface CharacteristicData {
	characteristicId: string;
	description: string;
	characteristicType: string;
	value?: string;
	isReadable: boolean;
	isWritable: boolean;
}

export interface SceneData {
	sceneId: string;
	sceneName: string;
	actionCount: number;
	isExecuting: boolean;
	actions?: import('$lib/types/changeset').SceneAction[];
	people?: string[];
}

export type ZoneType = 'building' | 'floor' | 'zone';

export interface ZoneData {
	zoneId: string;
	zoneName: string;
	zoneType: ZoneType;
	roomIds: string[];
}

export interface RoomPosition {
	x: number;
	y: number;
}

export interface RoomGlow {
	color: string;
	cls: string;
}

export interface TimeContext {
	period: 'morning' | 'day' | 'evening' | 'night';
	label: string;
}

export interface IntentItem {
	name: string;
	primary: boolean;
	icon: string;
}

/** Known HomeKit service type UUID prefixes */
export const SERVICE_TYPES = {
	LIGHTBULB: '00000043',
	MOTION_SENSOR: '00000085',
	TEMPERATURE_SENSOR: '0000008A',
	WINDOW_COVERING: '0000008C',
	OUTLET: '00000047',
	HEATER_COOLER: '000000BC',
	CAMERA: '00000110',
	ACCESSORY_INFO: '0000003E',
} as const;

/** Known HomeKit characteristic type UUID prefixes */
export const CHAR_TYPES = {
	POWER_STATE: '00000025',
	BRIGHTNESS: '00000008',
	ACTIVE: '000000B0',
	MOTION_DETECTED: '00000022',
	CURRENT_TEMPERATURE: '00000011',
	TARGET_POSITION: '0000007C',
	TARGET_TEMPERATURE: '00000035',
	COLOR_TEMPERATURE: '000000CE',
	HUE: '00000013',
	SATURATION: '0000002F',
} as const;

export interface UserPath {
	userId: string;
	userName: string;
	color: string;
	waypoints: Waypoint[];
}

export interface Waypoint {
	roomId: string;
	time: string;
	action?: string;
}

export type PathMode = 'guidance' | 'triggers';
