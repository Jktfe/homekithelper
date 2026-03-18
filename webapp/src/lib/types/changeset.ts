/** Change set types mirroring concept/schema-import.json */

export interface SceneAction {
	accessoryId: string;
	serviceType: string;
	characteristicType: string;
	targetValue: boolean | number | string;
}

export interface RenameEntry {
	accessoryId: string;
	newName: string;
}

export interface RoomAssignmentEntry {
	accessoryId: string;
	newRoomId: string;
	newRoomName: string;
}

export interface NewRoomEntry {
	name: string;
	zone?: string;
}

export interface DeleteRoomEntry {
	roomId: string;
}

export interface NewSceneEntry {
	name: string;
	actions: SceneAction[];
	people?: string[];
}

export interface DeleteSceneEntry {
	sceneId: string;
}

export interface UpdateSceneEntry {
	sceneId: string;
	actions: SceneAction[];
}

export interface NewZoneEntry {
	name: string;
}

export interface DeleteZoneEntry {
	zoneId: string;
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
}
