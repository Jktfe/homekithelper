<script lang="ts">
	import type { PathMode } from '$lib/types/homekit';

	let { x1, y1, x2, y2, color, mode } = $props<{
		x1: number;
		y1: number;
		x2: number;
		y2: number;
		color: string;
		mode: PathMode;
	}>();

	let midX = $derived((x1 + x2) / 2);
	let midY = $derived((y1 + y2) / 2);
	let dx = $derived(x2 - x1);
	let dy = $derived(y2 - y1);
	let perpX = $derived(-dy * 0.15);
	let perpY = $derived(dx * 0.15);

	let d = $derived(`M ${x1} ${y1} Q ${midX + perpX} ${midY + perpY}, ${x2} ${y2}`);
	let dasharray = $derived(mode === 'guidance' ? '8 6' : 'none');
	let opacity = $derived(mode === 'guidance' ? 0.5 : 0.7);
</script>

<path
	{d}
	stroke={color}
	stroke-width="2"
	stroke-linecap="round"
	stroke-dasharray={dasharray}
	{opacity}
	fill="none"
/>
