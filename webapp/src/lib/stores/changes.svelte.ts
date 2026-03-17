import type {
	ChangeSet,
	RenameEntry,
	RoomAssignmentEntry,
	NewRoomEntry,
	DeleteRoomEntry,
	NewSceneEntry,
	DeleteSceneEntry,
	UpdateSceneEntry,
	NewZoneEntry,
	DeleteZoneEntry
} from '$lib/types/changeset';

function createChangeStore() {
	let homeId = $state('');
	let originalNames = $state<Map<string, string>>(new Map());

	let renames = $state<Map<string, RenameEntry>>(new Map());
	let roomAssignments = $state<Map<string, RoomAssignmentEntry>>(new Map());
	let newRooms = $state<NewRoomEntry[]>([]);
	let deleteRooms = $state<DeleteRoomEntry[]>([]);
	let newScenes = $state<NewSceneEntry[]>([]);
	let deleteScenes = $state<DeleteSceneEntry[]>([]);
	let updateScenes = $state<UpdateSceneEntry[]>([]);
	let newZones = $state<NewZoneEntry[]>([]);
	let deleteZones = $state<DeleteZoneEntry[]>([]);

	let showPanel = $state(false);

	const pendingCount = $derived(
		renames.size +
		roomAssignments.size +
		newRooms.length +
		deleteRooms.length +
		newScenes.length +
		deleteScenes.length +
		updateScenes.length +
		newZones.length +
		deleteZones.length
	);

	const isEmpty = $derived(pendingCount === 0);

	return {
		get showPanel() { return showPanel; },
		set showPanel(v: boolean) { showPanel = v; },

		get pendingCount() { return pendingCount; },
		get isEmpty() { return isEmpty; },

		get renames() { return renames; },
		get roomAssignments() { return roomAssignments; },
		get newRooms() { return newRooms; },
		get deleteRooms() { return deleteRooms; },

		init(id: string, accessories: { accessoryId: string; name: string }[]) {
			homeId = id;
			originalNames = new Map(accessories.map(a => [a.accessoryId, a.name]));
			this.clear();
		},

		clear() {
			renames = new Map();
			roomAssignments = new Map();
			newRooms = [];
			deleteRooms = [];
			newScenes = [];
			deleteScenes = [];
			updateScenes = [];
			newZones = [];
			deleteZones = [];
		},

		recordRename(accessoryId: string, newName: string) {
			const original = originalNames.get(accessoryId);
			if (original && newName === original) {
				renames.delete(accessoryId);
				renames = new Map(renames);
				return;
			}
			renames.set(accessoryId, { accessoryId, newName });
			renames = new Map(renames);
		},

		removeRename(accessoryId: string) {
			renames.delete(accessoryId);
			renames = new Map(renames);
		},

		recordRoomAssignment(accessoryId: string, newRoomId: string, newRoomName: string) {
			roomAssignments.set(accessoryId, { accessoryId, newRoomId, newRoomName });
			roomAssignments = new Map(roomAssignments);
		},

		removeRoomAssignment(accessoryId: string) {
			roomAssignments.delete(accessoryId);
			roomAssignments = new Map(roomAssignments);
		},

		getOriginalName(accessoryId: string): string | undefined {
			return originalNames.get(accessoryId);
		},

		// Room CRUD
		recordNewRoom(name: string, zone?: string) {
			if (newRooms.some(r => r.name === name)) return;
			newRooms = [...newRooms, { name, zone }];
		},

		removeNewRoom(name: string) {
			newRooms = newRooms.filter(r => r.name !== name);
		},

		recordDeleteRoom(roomId: string) {
			if (deleteRooms.some(r => r.roomId === roomId)) return;
			deleteRooms = [...deleteRooms, { roomId }];
		},

		removeDeleteRoom(roomId: string) {
			deleteRooms = deleteRooms.filter(r => r.roomId !== roomId);
		},

		// Zone CRUD
		recordNewZone(name: string) {
			if (newZones.some(z => z.name === name)) return;
			newZones = [...newZones, { name }];
		},

		removeNewZone(name: string) {
			newZones = newZones.filter(z => z.name !== name);
		},

		recordDeleteZone(zoneId: string) {
			if (deleteZones.some(z => z.zoneId === zoneId)) return;
			deleteZones = [...deleteZones, { zoneId }];
		},

		removeDeleteZone(zoneId: string) {
			deleteZones = deleteZones.filter(z => z.zoneId !== zoneId);
		},

		get newZones() { return newZones; },
		get deleteZones() { return deleteZones; },
		get newScenes() { return newScenes; },
		get deleteScenes() { return deleteScenes; },

		// Scene CRUD
		recordNewScene(name: string, actions: import('$lib/types/changeset').SceneAction[]) {
			if (newScenes.some(s => s.name === name)) return;
			newScenes = [...newScenes, { name, actions }];
		},

		removeNewScene(name: string) {
			newScenes = newScenes.filter(s => s.name !== name);
		},

		recordDeleteScene(sceneId: string) {
			if (deleteScenes.some(s => s.sceneId === sceneId)) return;
			deleteScenes = [...deleteScenes, { sceneId }];
		},

		removeDeleteScene(sceneId: string) {
			deleteScenes = deleteScenes.filter(s => s.sceneId !== sceneId);
		},

		toJSON(): ChangeSet {
			const result: ChangeSet = { homeId };

			if (renames.size > 0) result.renames = [...renames.values()];
			if (roomAssignments.size > 0) result.roomAssignments = [...roomAssignments.values()];
			if (newRooms.length > 0) result.newRooms = newRooms;
			if (deleteRooms.length > 0) result.deleteRooms = deleteRooms;
			if (newScenes.length > 0) result.newScenes = newScenes;
			if (deleteScenes.length > 0) result.deleteScenes = deleteScenes;
			if (updateScenes.length > 0) result.updateScenes = updateScenes;
			if (newZones.length > 0) result.newZones = newZones;
			if (deleteZones.length > 0) result.deleteZones = deleteZones;

			return result;
		}
	};
}

export const changeStore = createChangeStore();
