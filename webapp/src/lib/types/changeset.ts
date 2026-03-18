/** Change set types mirroring concept/schema-import.json */

export interface SceneAction {
	accessoryId: string;
	serviceType: string;
	characteristicType: string;
	targetValue: boolean | number | string;
}

export interface RenameEntry {
	accessoryId: string;
	currentName: string;
	newName: string;
}

export interface RoomAssignmentEntry {
	accessoryId: string;
	newRoomId: string;
	newRoomName: string;
}

export interface NewRoomEntry {
	roomName: string;
	zone?: string;
}

export interface DeleteRoomEntry {
	roomId: string;
}

export interface NewSceneEntry {
	sceneName: string;
	actions: SceneAction[];
	people?: string[];
}

export interface DeleteSceneEntry {
	sceneId: string;
}

export interface UpdateSceneEntry {
	sceneId: string;
	newSceneName?: string;
	actions: SceneAction[];
}

export interface NewZoneEntry {
	zoneName: string;
}

export interface DeleteZoneEntry {
	zoneId: string;
}

export interface ZoneRoomAssignment {
	zoneName: string;
	roomId: string;
	action: 'add' | 'remove';
}

export interface ChangeSet {
	homeId: string;
	renames?: RenameEntry[];
	roomAssignments?: RoomAssignmentEntry[];
	newRooms?: NewRoomEntry[];
	deleteRooms?: DeleteRoomEntry[];
	newScenes?: NewSceneEntry[];
	deleteScenes?: DeleteSceneEntry[];
	updateScenes?: UpdateSceneEntry[];
	newZones?: NewZoneEntry[];
	deleteZones?: DeleteZoneEntry[];
	zoneRoomAssignments?: ZoneRoomAssignment[];
}
