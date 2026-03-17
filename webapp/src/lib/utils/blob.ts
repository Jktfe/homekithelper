/** Deterministic hash from string — used to seed blob shapes */
export function hash(str: string): number {
	let h = 0;
	for (let i = 0; i < str.length; i++) {
		h = ((h << 5) - h + str.charCodeAt(i)) | 0;
	}
	return Math.abs(h);
}

/** Generate an organic blob path (8-point octagon with wobble) */
export function blobPath(cx: number, cy: number, baseR: number, seed: number): string {
	const points = 8;
	const pts: { x: number; y: number }[] = [];

	for (let i = 0; i < points; i++) {
		const angle = (Math.PI * 2 / points) * i - Math.PI / 2;
		const wobble = 0.8 + ((seed >> (i * 3)) % 40) / 100;
		const r = baseR * wobble;
		const x = cx + Math.cos(angle) * r;
		const y = cy + Math.sin(angle) * r;
		pts.push({ x, y });
	}

	// Smooth cubic bezier closed path
	let d = `M ${pts[0].x} ${pts[0].y}`;
	for (let i = 0; i < points; i++) {
		const curr = pts[i];
		const next = pts[(i + 1) % points];
		const prev = pts[(i - 1 + points) % points];
		const nextNext = pts[(i + 2) % points];
		const cp1x = curr.x + (next.x - prev.x) * 0.25;
		const cp1y = curr.y + (next.y - prev.y) * 0.25;
		const cp2x = next.x - (nextNext.x - curr.x) * 0.25;
		const cp2y = next.y - (nextNext.y - curr.y) * 0.25;
		d += ` C ${cp1x} ${cp1y}, ${cp2x} ${cp2y}, ${next.x} ${next.y}`;
	}
	d += ' Z';
	return d;
}

/** Calculate room blob radius based on accessory count */
export function roomRadius(accessoryCount: number): number {
	return 55 + accessoryCount * 10;
}
