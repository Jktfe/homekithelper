<script lang="ts">
	import type { AccessoryData } from '$lib/types/homekit';
	import { siriScore, siriColor } from '$lib/utils/siri-score';

	let {
		accessory,
		cx,
		cy,
		dotIndex,
		totalDots,
		roomRadius,
		glowColor,
		enterDelay,
	}: {
		accessory: AccessoryData;
		cx: number;
		cy: number;
		dotIndex: number;
		totalDots: number;
		roomRadius: number;
		glowColor: string;
		enterDelay: number;
	} = $props();

	// Orbital position
	let angle = $derived((2 * Math.PI / Math.max(totalDots, 1)) * dotIndex - Math.PI / 2);
	let dotR = $derived(roomRadius * 0.5 * (0.4 + (totalDots > 2 ? 0.6 : 0.3)));
	let dx = $derived(cx + Math.cos(angle) * dotR);
	let dy = $derived(cy + Math.sin(angle) * dotR + 8);

	// Check if device is on
	let isOn = $derived(
		accessory.services.some((s) =>
			s.characteristics.some(
				(c) =>
					(c.description === 'Power State' || c.description === 'Active') && c.value === '1'
			)
		)
	);

	// Siri score
	let score = $derived(siriScore(accessory.name));
	let sColor = $derived(siriColor(score));

	// Staggered ignite delay
	let igniteDelay = $derived(enterDelay + 0.6 + dotIndex * 0.06);

	// Truncated label
	let label = $derived(
		accessory.name.length > 12 ? accessory.name.slice(0, 12) + '\u2026' : accessory.name
	);
</script>

<g>
	<!-- Siri quality ring -->
	<circle
		cx={dx}
		cy={dy}
		r={9}
		fill="none"
		stroke={sColor}
		stroke-opacity="0.25"
		stroke-width="1.5"
		style="animation: dot-ignite 0.5s ease-out {igniteDelay}s both;"
	/>

	<!-- Dot -->
	<circle
		cx={dx}
		cy={dy}
		r={5}
		fill={isOn ? glowColor : 'gray'}
		style="animation: dot-ignite 0.5s ease-out {igniteDelay}s both;"
	/>

	<!-- Glow pulse if on -->
	{#if isOn}
		<circle
			cx={dx}
			cy={dy}
			r={12}
			fill={glowColor}
			opacity="0.12"
			filter="url(#soft-blur)"
			style="animation: glow-pulse 3s ease-in-out {igniteDelay + 0.5}s infinite;"
		/>
	{/if}

	<!-- Label -->
	<text
		x={dx}
		y={dy + 18}
		text-anchor="middle"
		font-family="'JetBrains Mono', monospace"
		font-size="7"
		letter-spacing="0.05em"
		style="fill: var(--dot-label-fill); text-transform: uppercase; pointer-events: none; animation: dot-ignite 0.5s ease-out {igniteDelay}s both;"
	>
		{label}
	</text>
</g>

<style>
	@keyframes dot-ignite {
		from {
			opacity: 0;
			transform: scale(0);
		}
		to {
			opacity: 1;
			transform: scale(1);
		}
	}

	@keyframes glow-pulse {
		0%,
		100% {
			opacity: 0.12;
		}
		50% {
			opacity: 0.25;
		}
	}
</style>
