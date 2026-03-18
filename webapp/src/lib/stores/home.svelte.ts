import type { HomeExport, RoomData, AccessoryData, RoomPosition, ZoneType } from '$lib/types/homekit';
import sampleData from '$lib/data/sample-export.json';
import { browser } from '$app/environment';
import { changeStore } from '$lib/stores/changes.svelte';

const POSITIONS_KEY = 'hkh-room-positions';

function loadPositions(roomIds: string[]): Record<string, RoomPosition> {
	if (browser) {
		try {
			const saved = localStorage.getItem(POSITIONS_KEY);
			if (saved) {
				const parsed = JSON.parse(saved);
				const hasMatch = roomIds.some(id => id in parsed);
				if (hasMatch) return parsed;
				localStorage.removeItem(POSITIONS_KEY);
			}
		} catch {}
	}
	return {};
}

function generatePositions(rooms: RoomData[], accessories: AccessoryData[]): Record<string, RoomPosition> {
	const positions: Record<string, RoomPosition> = {};

	// Sort rooms by accessory count descending (largest placed first)
	const sorted = [...rooms].sort((a, b) => {
		const countA = accessories.filter(ac => ac.roomId === a.roomId).length;
		const countB = accessories.filter(ac => ac.roomId === b.roomId).length;
		return countB - countA;
	});

	const usableW = 1400;
	const usableH = 900;
	const offsetX = 50;
	const offsetY = 50;

	// Determine grid dimensions
	const cols = Math.max(1, Math.ceil(Math.sqrt(sorted.length * (usableW / usableH))));
	const rows = Math.ceil(sorted.length / cols);

	// Calculate per-cell size
	const cellW = usableW / cols;
	const cellH = usableH / rows;

	sorted.forEach((room, i) => {
		const col = i % cols;
		const row = Math.floor(i / cols);
		positions[room.roomId] = {
			x: offsetX + col * cellW + cellW / 2,
			y: offsetY + row * cellH + cellH / 2,
		};
	});
	return positions;
}

function createHomeStore() {
	let exportData = $state<HomeExport | null>(null);
	let selectedRoomId = $state<string | null>(null);
	let panelOpen = $state(false);
	let editingRoomId = $state<string | null>(null);
	let editPanelOpen = $state(false);
	let designerRoomId = $state<string | null>(null);
	let roomPositions = $state<Record<string, RoomPosition>>({});
	let showImportModal = $state(false);
	let showBulkRename = $state(false);
	let showScenePanel = $state(false);
	let filterBuildingIds = $state<Set<string>>(new Set());

	return {
		get exportData() { return exportData; },
		get isLoaded() { return exportData !== null; },
		get home() { return exportData?.homes[0] ?? null; },
		get rooms() { return exportData?.homes[0]?.rooms ?? []; },
		get accessories() { return exportData?.homes[0]?.accessories ?? []; },
		get scenes() { return exportData?.homes[0]?.scenes ?? []; },
		get zones() { return exportData?.homes[0]?.zones ?? []; },
		get buildings() { return (exportData?.homes[0]?.zones ?? []).filter(z => z.zoneType === 'building'); },
		get floors() { return (exportData?.homes[0]?.zones ?? []).filter(z => z.zoneType === 'floor'); },
		get generalZones() { return (exportData?.homes[0]?.zones ?? []).filter(z => (z.zoneType ?? 'zone') === 'zone'); },
		get filterBuildingIds() { return filterBuildingIds; },
		toggleBuildingFilter(zoneId: string) {
			const next = new Set(filterBuildingIds);
			if (next.has(zoneId)) next.delete(zoneId);
			else next.add(zoneId);
			filterBuildingIds = next;
		},
		clearBuildingFilter() {
			filterBuildingIds = new Set();
		},
		get filteredRoomIds(): Set<string> | null {
			if (filterBuildingIds.size === 0) return null; // no filter = show all
			const zones = exportData?.homes[0]?.zones ?? [];
			const ids = new Set<string>();
			for (const z of zones) {
				if (filterBuildingIds.has(z.zoneId)) {
					z.roomIds.forEach(id => ids.add(id));
				}
			}
			return ids;
		},
		get roomCount() { return exportData?.homes[0]?.rooms?.length ?? 0; },
		get deviceCount() { return exportData?.homes[0]?.accessories?.length ?? 0; },
		get sceneCount() { return exportData?.homes[0]?.scenes?.length ?? 0; },
		get homeName() { return exportData?.homes[0]?.homeName ?? 'Home'; },
		get selectedRoomId() { return selectedRoomId; },
		get panelOpen() { return panelOpen; },
		set panelOpen(v: boolean) { panelOpen = v; },
		get roomPositions() { return roomPositions; },
		get showImportModal() { return showImportModal; },
		set showImportModal(v: boolean) { showImportModal = v; },
		get showBulkRename() { return showBulkRename; },
		set showBulkRename(v: boolean) { showBulkRename = v; },
		get showScenePanel() { return showScenePanel; },
		set showScenePanel(v: boolean) { showScenePanel = v; },
		get selectedRoom() {
			return (exportData?.homes[0]?.rooms ?? []).find(r => r.roomId === selectedRoomId) ?? null;
		},
		get selectedRoomAccessories() {
			return selectedRoomId
				? (exportData?.homes[0]?.accessories ?? []).filter(a => a.roomId === selectedRoomId)
				: [];
		},
		get editingRoomId() { return editingRoomId; },
		get editPanelOpen() { return editPanelOpen; },
		get designerRoomId() { return designerRoomId; },
		get editingRoom() {
			return (exportData?.homes[0]?.rooms ?? []).find(r => r.roomId === editingRoomId) ?? null;
		},
		get editingRoomAccessories() {
			return editingRoomId
				? (exportData?.homes[0]?.accessories ?? []).filter(a => a.roomId === editingRoomId)
				: [];
		},

		openRoom(roomId: string) {
			selectedRoomId = roomId;
			panelOpen = true;
		},

		closePanel() {
			panelOpen = false;
			selectedRoomId = null;
		},

		editRoom(roomId: string) {
			editingRoomId = roomId;
			editPanelOpen = true;
			panelOpen = false;
			selectedRoomId = null;
		},

		closeEditPanel() {
			editPanelOpen = false;
			editingRoomId = null;
		},

		openDesigner(roomId: string) {
			designerRoomId = roomId;
			editPanelOpen = false;
		},

		closeDesigner() {
			designerRoomId = null;
		},

		updateRoomName(roomId: string, newName: string) {
			const home = exportData?.homes[0];
			if (!home) return;
			const room = home.rooms.find(r => r.roomId === roomId);
			if (room) room.roomName = newName;
			home.accessories.forEach(a => {
				if (a.roomId === roomId) a.roomName = newName;
			});
		},

		setRoomZone(roomId: string, zoneId: string | null, zoneType: ZoneType = 'zone') {
			const home = exportData?.homes[0];
			if (!home || !home.zones) return;
			// Building & floor: single-select — remove from all of same type
			// Zone: multi-select — only toggle the specific zone
			if (zoneType === 'building' || zoneType === 'floor') {
				home.zones.forEach(z => {
					if ((z.zoneType ?? 'zone') === zoneType) {
						z.roomIds = z.roomIds.filter(id => id !== roomId);
					}
				});
				if (zoneId) {
					const zone = home.zones.find(z => z.zoneId === zoneId);
					if (zone) zone.roomIds.push(roomId);
				}
			} else {
				// Toggle: add if not present, remove if already present
				if (zoneId) {
					const zone = home.zones.find(z => z.zoneId === zoneId);
					if (zone) {
						if (zone.roomIds.includes(roomId)) {
							zone.roomIds = zone.roomIds.filter(id => id !== roomId);
						} else {
							zone.roomIds.push(roomId);
						}
					}
				}
			}
		},

		renameAccessory(accessoryId: string, newName: string) {
			const home = exportData?.homes[0];
			if (!home) return;
			const acc = home.accessories.find(a => a.accessoryId === accessoryId);
			if (acc) {
				acc.name = newName;
				changeStore.recordRename(accessoryId, newName);
			}
		},

		moveAccessoryToRoom(accessoryId: string, newRoomId: string) {
			const home = exportData?.homes[0];
			if (!home) return;
			const acc = home.accessories.find(a => a.accessoryId === accessoryId);
			if (!acc) return;
			const newRoom = home.rooms.find(r => r.roomId === newRoomId);
			if (!newRoom) return;
			acc.roomId = newRoomId;
			acc.roomName = newRoom.roomName;
			changeStore.recordRoomAssignment(accessoryId, newRoomId, newRoom.roomName);
		},

		createRoom(name: string, zone?: string) {
			const home = exportData?.homes[0];
			if (!home) return;
			const roomId = `R-${Date.now()}`;
			home.rooms = [...home.rooms, {
				roomId,
				roomName: name,
				accessoryCount: 0,
			} as any];
			// Place new room on canvas
			const accs = home.accessories ?? [];
			roomPositions = generatePositions(home.rooms, accs);
			changeStore.recordNewRoom(name, zone);
		},

		deleteRoom(roomId: string) {
			const home = exportData?.homes[0];
			if (!home) return;
			// Only allow if no accessories in room
			const hasAccessories = home.accessories.some(a => a.roomId === roomId);
			if (hasAccessories) return;
			home.rooms = home.rooms.filter(r => r.roomId !== roomId);
			// Remove from zones
			home.zones?.forEach(z => {
				z.roomIds = z.roomIds.filter(id => id !== roomId);
			});
			// Remove position
			delete roomPositions[roomId];
			roomPositions = { ...roomPositions };
			changeStore.recordDeleteRoom(roomId);
			// Close panel if editing this room
			if (editingRoomId === roomId) {
				editPanelOpen = false;
				editingRoomId = null;
			}
		},

		createZone(name: string, zoneType: ZoneType = 'zone') {
			const home = exportData?.homes[0];
			if (!home) return;
			if (!home.zones) home.zones = [];
			const zoneId = `Z-${Date.now()}`;
			home.zones = [...home.zones, {
				zoneId,
				zoneName: name,
				zoneType,
				roomIds: [],
			}];
			changeStore.recordNewZone(name);
		},

		deleteZone(zoneId: string) {
			const home = exportData?.homes[0];
			if (!home || !home.zones) return;
			home.zones = home.zones.filter(z => z.zoneId !== zoneId);
			changeStore.recordDeleteZone(zoneId);
		},

		createScene(name: string, actions: import('$lib/types/changeset').SceneAction[], people?: string[]) {
			const home = exportData?.homes[0];
			if (!home) return;
			if (!home.scenes) home.scenes = [];
			const sceneId = `SC-${Date.now()}`;
			home.scenes = [...home.scenes, {
				sceneId,
				sceneName: name,
				actionCount: actions.length,
				isExecuting: false,
				actions,
				people: people?.length ? people : undefined,
			}];
			changeStore.recordNewScene(name, actions, people);
		},

		deleteScene(sceneId: string) {
			const home = exportData?.homes[0];
			if (!home || !home.scenes) return;
			home.scenes = home.scenes.filter(s => s.sceneId !== sceneId);
			changeStore.recordDeleteScene(sceneId);
		},

		updateRoomPosition(roomId: string, x: number, y: number) {
			roomPositions[roomId] = { x, y };
		},

		savePositions() {
			if (browser) {
				localStorage.setItem(POSITIONS_KEY, JSON.stringify(roomPositions));
			}
		},

		resetPositions() {
			const rooms = exportData?.homes[0]?.rooms ?? [];
			const accs = exportData?.homes[0]?.accessories ?? [];
			roomPositions = generatePositions(rooms, accs);
			if (browser) {
				localStorage.removeItem(POSITIONS_KEY);
			}
		},

		loadSampleData() {
			const data = sampleData as HomeExport;
			exportData = JSON.parse(JSON.stringify(data));
			const home = exportData!.homes[0];
			const roomIds = home.rooms.map(r => r.roomId);
			const saved = loadPositions(roomIds);
			roomPositions = Object.keys(saved).length > 0
				? saved
				: generatePositions(home.rooms, home.accessories);
			changeStore.init(home.homeId ?? '', home.accessories);
			panelOpen = false;
			selectedRoomId = null;
		},

		loadExport(json: string) {
			const parsed = JSON.parse(json) as HomeExport;
			if (!parsed.homes?.length) throw new Error('No homes found in export');
			exportData = parsed;
			const home = parsed.homes[0];
			const roomIds = home.rooms.map(r => r.roomId);
			const saved = loadPositions(roomIds);
			roomPositions = Object.keys(saved).length > 0
				? saved
				: generatePositions(home.rooms, home.accessories);
			if (browser) {
				localStorage.setItem(POSITIONS_KEY, JSON.stringify(roomPositions));
			}
			changeStore.init(home.homeId ?? '', home.accessories);
			panelOpen = false;
			selectedRoomId = null;
		},

		scenesForRoom(roomId: string) {
			const home = exportData?.homes[0];
			if (!home) return [];
			const roomAccIds = new Set(
				(home.accessories ?? []).filter(a => a.roomId === roomId).map(a => a.accessoryId)
			);
			return (home.scenes ?? []).filter(s =>
				s.actions?.some(a => roomAccIds.has(a.accessoryId))
			);
		},

		zonesForRoom(roomId: string) {
			return (exportData?.homes[0]?.zones ?? []).filter(z => z.roomIds.includes(roomId));
		},

		accessoriesForRoom(roomId: string): AccessoryData[] {
			return (exportData?.homes[0]?.accessories ?? []).filter(a => a.roomId === roomId);
		},
	};
}

export const homeStore = createHomeStore();
