import type { HomeExport, RoomData, AccessoryData, RoomPosition } from '$lib/types/homekit';
import sampleData from '$lib/data/sample-export.json';
import { browser } from '$app/environment';

const POSITIONS_KEY = 'hkh-room-positions';

const defaultPositions: Record<string, RoomPosition> = {
	'R-001': { x: 420, y: 320 },
	'R-002': { x: 660, y: 260 },
	'R-004': { x: 540, y: 480 },
	'R-003': { x: 280, y: 140 },
	'R-005': { x: 520, y: 100 },
	'R-006': { x: 740, y: 120 },
	'R-007': { x: 850, y: 450 },
};

function loadPositions(roomIds: string[]): Record<string, RoomPosition> {
	if (browser) {
		try {
			const saved = localStorage.getItem(POSITIONS_KEY);
			if (saved) {
				const parsed = JSON.parse(saved);
				// Validate that saved positions match current room IDs
				const hasMatch = roomIds.some(id => id in parsed);
				if (hasMatch) return parsed;
				// Stale positions from a different dataset — discard
				localStorage.removeItem(POSITIONS_KEY);
			}
		} catch {}
	}
	return JSON.parse(JSON.stringify(defaultPositions));
}

function generatePositions(rooms: RoomData[]): Record<string, RoomPosition> {
	const positions: Record<string, RoomPosition> = {};
	const cols = Math.ceil(Math.sqrt(rooms.length));
	rooms.forEach((room, i) => {
		const col = i % cols;
		const row = Math.floor(i / cols);
		positions[room.roomId] = {
			x: 200 + col * 180,
			y: 150 + row * 160,
		};
	});
	return positions;
}

function createHomeStore() {
	let exportData = $state<HomeExport>(sampleData as HomeExport);
	let selectedRoomId = $state<string | null>(null);
	let panelOpen = $state(false);
	const sampleRoomIds = (sampleData as HomeExport).homes[0]?.rooms?.map(r => r.roomId) ?? [];
	let roomPositions = $state<Record<string, RoomPosition>>(loadPositions(sampleRoomIds));
	let showImportModal = $state(false);

	return {
		get exportData() { return exportData; },
		get home() { return exportData.homes[0]; },
		get rooms() { return exportData.homes[0]?.rooms ?? []; },
		get accessories() { return exportData.homes[0]?.accessories ?? []; },
		get scenes() { return exportData.homes[0]?.scenes ?? []; },
		get zones() { return exportData.homes[0]?.zones ?? []; },
		get roomCount() { return exportData.homes[0]?.rooms?.length ?? 0; },
		get deviceCount() { return exportData.homes[0]?.accessories?.length ?? 0; },
		get sceneCount() { return exportData.homes[0]?.scenes?.length ?? 0; },
		get homeName() { return exportData.homes[0]?.homeName ?? 'Home'; },
		get selectedRoomId() { return selectedRoomId; },
		get panelOpen() { return panelOpen; },
		set panelOpen(v: boolean) { panelOpen = v; },
		get roomPositions() { return roomPositions; },
		get showImportModal() { return showImportModal; },
		set showImportModal(v: boolean) { showImportModal = v; },
		get selectedRoom() {
			return (exportData.homes[0]?.rooms ?? []).find(r => r.roomId === selectedRoomId) ?? null;
		},
		get selectedRoomAccessories() {
			return selectedRoomId
				? (exportData.homes[0]?.accessories ?? []).filter(a => a.roomId === selectedRoomId)
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

		updateRoomPosition(roomId: string, x: number, y: number) {
			roomPositions[roomId] = { x, y };
		},

		savePositions() {
			if (browser) {
				localStorage.setItem(POSITIONS_KEY, JSON.stringify(roomPositions));
			}
		},

		resetPositions() {
			const rooms = exportData.homes[0]?.rooms ?? [];
			const isCustomData = !rooms.some(r => r.roomId === 'R-001');
			roomPositions = isCustomData
				? generatePositions(rooms)
				: JSON.parse(JSON.stringify(defaultPositions));
			if (browser) {
				localStorage.removeItem(POSITIONS_KEY);
			}
		},

		loadExport(json: string) {
			const parsed = JSON.parse(json) as HomeExport;
			if (!parsed.homes?.length) throw new Error('No homes found in export');
			exportData = parsed;
			roomPositions = generatePositions(parsed.homes[0].rooms);
			if (browser) {
				localStorage.setItem(POSITIONS_KEY, JSON.stringify(roomPositions));
			}
			panelOpen = false;
			selectedRoomId = null;
		},

		accessoriesForRoom(roomId: string): AccessoryData[] {
			return (exportData.homes[0]?.accessories ?? []).filter(a => a.roomId === roomId);
		},
	};
}

export const homeStore = createHomeStore();
