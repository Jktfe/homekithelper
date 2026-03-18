import type { AccessoryData, RoomData, RoomGlow } from '$lib/types/homekit';
import { SERVICE_TYPES } from '$lib/types/homekit';

/** Determine room glow colour based on device states */
export function getRoomGlow(room: RoomData, accessories: AccessoryData[]): RoomGlow {
	const accs = accessories.filter(a => a.roomId === room.roomId);

	// Child's room gets special pink
	if (/kid|child|nursery/i.test(room.roomName)) return { color: '#FF6FD8', cls: 'pink' };

	// Check for active motion sensors via serviceType UUID
	const hasMotion = accs.some(a =>
		a.services.some(s =>
			s.serviceType.startsWith(SERVICE_TYPES.MOTION_SENSOR) &&
			s.characteristics.some(c => c.description === 'Motion Detected' && c.value === '1')
		)
	);
	if (hasMotion) return { color: '#00F5A0', cls: 'emerald' };

	// Check if any lights are on via serviceType UUID
	const hasActiveLights = accs.some(a =>
		a.services.some(s =>
			s.serviceType.startsWith(SERVICE_TYPES.LIGHTBULB) &&
			s.characteristics.some(c => c.description === 'Power State' && c.value === '1')
		)
	);
	if (hasActiveLights) return { color: '#FFB347', cls: 'amber' };

	return { color: '#89F7FE', cls: 'azure' };
}
