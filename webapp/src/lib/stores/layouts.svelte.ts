import { browser } from '$app/environment';

const LAYOUT_KEY = 'hkh-room-layouts';
const META_KEY = 'hkh-acc-meta';
export const GRID_COLS = 8;
export const GRID_ROWS = 8;
export const CELL_SIZE = 80; // px in the designer

export type GridPos = { col: number; row: number };
export type AccMeta = { icon?: string; description?: string };

function loadFromStorage(): Record<string, Record<string, GridPos>> {
	if (browser) {
		try {
			const saved = localStorage.getItem(LAYOUT_KEY);
			if (saved) return JSON.parse(saved);
		} catch {}
	}
	return {};
}

function loadMeta(): Record<string, AccMeta> {
	if (browser) {
		try {
			const saved = localStorage.getItem(META_KEY);
			if (saved) return JSON.parse(saved);
		} catch {}
	}
	return {};
}

function createLayoutStore() {
	let layouts = $state<Record<string, Record<string, GridPos>>>(loadFromStorage());
	let meta = $state<Record<string, AccMeta>>(loadMeta());

	return {
		get layouts() { return layouts; },

		getPos(roomId: string, accId: string, index: number): GridPos {
			if (layouts[roomId]?.[accId]) {
				return layouts[roomId][accId];
			}
			return { col: index % GRID_COLS, row: Math.floor(index / GRID_COLS) };
		},

		setPos(roomId: string, accId: string, pos: GridPos) {
			if (!layouts[roomId]) layouts[roomId] = {};
			layouts[roomId][accId] = pos;
			layouts = { ...layouts };
			this.save();
		},

		cellOccupied(roomId: string, col: number, row: number, excludeId: string, accessories: { accessoryId: string }[]): boolean {
			return accessories.some((acc, i) => {
				if (acc.accessoryId === excludeId) return false;
				const pos = this.getPos(roomId, acc.accessoryId, i);
				return pos.col === col && pos.row === row;
			});
		},

		getMeta(accId: string): AccMeta {
			return meta[accId] ?? {};
		},

		setMeta(accId: string, updates: Partial<AccMeta>) {
			meta[accId] = { ...(meta[accId] ?? {}), ...updates };
			meta = { ...meta };
			this.saveMeta();
		},

		save() {
			if (browser) {
				localStorage.setItem(LAYOUT_KEY, JSON.stringify(layouts));
			}
		},

		saveMeta() {
			if (browser) {
				localStorage.setItem(META_KEY, JSON.stringify(meta));
			}
		},
	};
}

export const layoutStore = createLayoutStore();
