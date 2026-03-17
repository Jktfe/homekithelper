/** Calculate Siri name quality score (0-100) */
export function siriScore(name: string): number {
	let score = 100;
	const words = name.trim().split(/\s+/);
	if (words.length > 3) score -= 25;
	if (words.length > 4) score -= 20;
	if (/[^a-zA-Z0-9\s']/.test(name)) score -= 15;
	if (name.length > 20) score -= 10;
	if (/\d{3,}/.test(name)) score -= 20;
	if (/^(the|my|a)\s/i.test(name)) score -= 10;
	return Math.max(0, Math.min(100, score));
}

export function siriClass(score: number): string {
	if (score >= 80) return 'siri-good';
	if (score >= 50) return 'siri-ok';
	return 'siri-bad';
}

export function siriLabel(score: number): string {
	if (score >= 80) return 'Siri ✓';
	if (score >= 50) return 'Siri ~';
	return 'Siri ✗';
}

export function siriColor(score: number): string {
	if (score >= 80) return '#00E676';
	if (score >= 50) return '#FFD740';
	return '#FF5252';
}
