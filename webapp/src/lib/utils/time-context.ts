import type { TimeContext, IntentItem } from '$lib/types/homekit';

export function getTimeContext(): TimeContext {
	const h = new Date().getHours();
	if (h >= 6 && h < 10) return { period: 'morning', label: 'Morning · 06:00–10:00' };
	if (h >= 10 && h < 16) return { period: 'day', label: 'Daytime · 10:00–16:00' };
	if (h >= 16 && h < 21) return { period: 'evening', label: 'Evening · 16:00–21:00' };
	return { period: 'night', label: 'Night · 21:00–06:00' };
}

export const intentMap: Record<string, IntentItem[]> = {
	morning: [
		{ name: 'Morning Routine', primary: true, icon: '☀️' },
		{ name: 'Bright', primary: false, icon: '💡' },
		{ name: 'Open Blinds', primary: false, icon: '🪟' },
		{ name: 'Kids Wake Up', primary: false, icon: '🧒' },
		{ name: 'Coffee Mode', primary: false, icon: '☕' },
	],
	day: [
		{ name: 'Focus Mode', primary: true, icon: '🎯' },
		{ name: 'Bright', primary: false, icon: '💡' },
		{ name: 'Natural Light', primary: false, icon: '🌤️' },
		{ name: 'Away', primary: false, icon: '🔒' },
	],
	evening: [
		{ name: 'Movie Night', primary: true, icon: '🎬' },
		{ name: 'Relax', primary: false, icon: '🌙' },
		{ name: 'Kids Bedtime', primary: false, icon: '🛏️' },
		{ name: 'Dinner Ambience', primary: false, icon: '🕯️' },
		{ name: 'Family Time', primary: false, icon: '👨‍👩‍👧‍👦' },
	],
	night: [
		{ name: 'Kids Bedtime', primary: true, icon: '🌙' },
		{ name: 'Night Path', primary: false, icon: '🔦' },
		{ name: 'Away', primary: false, icon: '🔒' },
		{ name: 'Sleep Timer', primary: false, icon: '⏱️' },
		{ name: 'Safe Mode', primary: false, icon: '🛡️' },
	],
};
