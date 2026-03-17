<script lang="ts">
	import type { RoomData } from '$lib/types/homekit';
	import { homeStore } from '$lib/stores/home.svelte';
	import { getRoomGlow } from '$lib/utils/room-colour';
	import { hash, blobPath, roomRadius } from '$lib/utils/blob';
	import DeviceDot from './DeviceDot.svelte';

	let { room, cx, cy, index }: { room: RoomData; cx: number; cy: number; index: number } =
		$props();

	let glow = $derived(getRoomGlow(room, homeStore.accessories));
	let seed = $derived(hash(room.roomName));
	let accs = $derived(homeStore.accessoriesForRoom(room.roomId));
	let baseR = $derived(roomRadius(accs.length));
	let pathD = $derived(blobPath(cx, cy, baseR, seed));

	let breatheClass = $derived(`breathe-${(index % 3) + 1}`);
	let breatheDuration = $derived(3.5 + (seed % 20) / 10);
	let enterDelay = $derived(0.8 + index * 0.12);
</script>

<g
	style="
		transform-origin: {cx}px {cy}px;
		animation:
			blob-enter 0.8s cubic-bezier(0.34, 1.56, 0.64, 1) {enterDelay}s both,
			{breatheClass} {breatheDuration}s ease-in-out {enterDelay + 0.8}s infinite;
	"
>
	<!-- Hit area (invisible) -->
	<circle {cx} {cy} r={baseR * 1.1} fill="transparent" style="cursor: pointer;" />

	<!-- Glow halo (blurred copy behind the blob) -->
	<path
		d={pathD}
		fill={glow.color}
		stroke={glow.color}
		stroke-width="8"
		filter="url(#soft-blur)"
		style="pointer-events: none; fill-opacity: var(--blob-halo-fill-opacity); stroke-opacity: var(--blob-halo-stroke-opacity);"
	/>

	<!-- Blob shape -->
	<path
		d={pathD}
		stroke={glow.color}
		stroke-width="1.5"
		style="fill: var(--blob-fill); stroke-opacity: var(--blob-stroke-opacity);"
	/>

	<!-- Room name label -->
	<text
		x={cx}
		y={cy - baseR - 14}
		text-anchor="middle"
		font-family="'DM Sans', sans-serif"
		font-size="11"
		font-weight="500"
		letter-spacing="0.08em"
		style="fill: var(--label-fill); text-transform: uppercase; pointer-events: none;"
	>
		{room.roomName}
	</text>

	<!-- Device count -->
	<text
		x={cx}
		y={cy + baseR + 22}
		text-anchor="middle"
		font-family="'JetBrains Mono', monospace"
		font-size="10"
		style="fill: var(--count-fill); pointer-events: none;"
	>
		{accs.length} device{accs.length !== 1 ? 's' : ''}
	</text>

	<!-- Device dots -->
	{#each accs as accessory, dotIndex}
		<DeviceDot
			{accessory}
			{cx}
			{cy}
			{dotIndex}
			totalDots={accs.length}
			roomRadius={baseR}
			glowColor={glow.color}
			{enterDelay}
		/>
	{/each}
</g>

<style>
	@keyframes blob-enter {
		from {
			opacity: 0;
			transform: scale(0);
		}
		to {
			opacity: 1;
			transform: scale(1);
		}
	}

	@keyframes breathe-1 {
		0%,
		100% {
			transform: scale(1);
		}
		50% {
			transform: scale(1.02);
		}
	}

	@keyframes breathe-2 {
		0%,
		100% {
			transform: scale(1);
		}
		50% {
			transform: scale(1.015);
		}
	}

	@keyframes breathe-3 {
		0%,
		100% {
			transform: scale(1);
		}
		50% {
			transform: scale(1.025);
		}
	}
</style>
