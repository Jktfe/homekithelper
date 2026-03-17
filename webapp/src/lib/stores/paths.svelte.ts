import type { PathMode, UserPath } from '$lib/types/homekit';

const familyMembers = [
	{ userId: 'james', userName: 'James', color: '#89F7FE', initials: 'JK' },
	{ userId: 'roxanne', userName: 'Roxanne', color: '#FFB347', initials: 'RK' },
	{ userId: 'fletcher', userName: 'Fletcher', color: '#00E676', initials: 'FK' },
	{ userId: 'viola', userName: 'Viola', color: '#FF6FD8', initials: 'VK' },
];

const samplePaths: Record<string, UserPath> = {
	james: {
		userId: 'james', userName: 'James', color: '#89F7FE',
		waypoints: [
			{ roomId: 'R-003', time: '06:30', action: 'Wake up' },
			{ roomId: 'R-002', time: '06:45', action: 'Coffee' },
			{ roomId: 'R-004', time: '07:15', action: 'Work start' },
			{ roomId: 'R-002', time: '12:30', action: 'Lunch' },
			{ roomId: 'R-004', time: '13:00', action: 'Afternoon work' },
			{ roomId: 'R-001', time: '18:00', action: 'Family time' },
		],
	},
	roxanne: {
		userId: 'roxanne', userName: 'Roxanne', color: '#FFB347',
		waypoints: [
			{ roomId: 'R-003', time: '06:45', action: 'Wake up' },
			{ roomId: 'R-005', time: '07:00', action: 'Wake Fletcher' },
			{ roomId: 'R-006', time: '07:10', action: 'Wake Viola' },
			{ roomId: 'R-002', time: '07:30', action: 'Breakfast' },
			{ roomId: 'R-001', time: '19:00', action: 'Evening' },
		],
	},
	fletcher: {
		userId: 'fletcher', userName: 'Fletcher', color: '#00E676',
		waypoints: [
			{ roomId: 'R-005', time: '07:00', action: 'Wake up' },
			{ roomId: 'R-002', time: '07:30', action: 'Breakfast' },
			{ roomId: 'R-001', time: '16:00', action: 'After school' },
			{ roomId: 'R-005', time: '20:00', action: 'Bedtime' },
		],
	},
	viola: {
		userId: 'viola', userName: 'Viola', color: '#FF6FD8',
		waypoints: [
			{ roomId: 'R-006', time: '07:10', action: 'Wake up' },
			{ roomId: 'R-002', time: '07:30', action: 'Breakfast' },
			{ roomId: 'R-001', time: '16:00', action: 'Playtime' },
			{ roomId: 'R-006', time: '19:00', action: 'Bedtime' },
		],
	},
};

class PathStore {
	pathModeActive = $state(false);
	pathMode = $state<PathMode>('guidance');
	selectedUserId = $state<string | null>(null);
	timeValue = $state(12);
	showSaveModal = $state(false);
	members = familyMembers;

	selectedUser = $derived(
		this.selectedUserId
			? familyMembers.find(m => m.userId === this.selectedUserId) ?? null
			: null
	);

	currentPath = $derived<UserPath | null>(
		this.selectedUserId ? samplePaths[this.selectedUserId] ?? null : null
	);

	togglePathMode() {
		this.pathModeActive = !this.pathModeActive;
		if (!this.pathModeActive) {
			this.selectedUserId = null;
		}
	}

	selectUser(userId: string) {
		this.selectedUserId = userId;
	}

	setPathMode(mode: PathMode) {
		this.pathMode = mode;
	}

	openSaveModal() {
		this.showSaveModal = true;
	}

	closeSaveModal() {
		this.showSaveModal = false;
	}
}

export const pathStore = new PathStore();
