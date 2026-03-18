<script lang="ts">
	import { homeStore } from '$lib/stores/home.svelte';
	import { pathStore } from '$lib/stores/paths.svelte';
	import RoomBlob from './RoomBlob.svelte';
	import DeviceDot from './DeviceDot.svelte';
	import UserPaths from './UserPaths.svelte';
	import { getRoomGlow } from '$lib/utils/room-colour';
	import { hash, blobPath, roomRadius } from '$lib/utils/blob';
	import { siriScore, siriColor } from '$lib/utils/siri-score';

	// drag state
	let dragState = $state<{
		roomId: string;
		startX: number;
		startY: number;
		origX: number;
		origY: number;
	} | null>(null);
	let hasDragged = $state(false);
	let svgEl: SVGSVGElement;

	function svgPoint(clientX: number, clientY: number): { x: number; y: number } {
		const pt = svgEl.createSVGPoint();
		pt.x = clientX;
		pt.y = clientY;
		const ctm = svgEl.getScreenCTM();
		if (!ctm) return { x: 0, y: 0 };
		const svgPt = pt.matrixTransform(ctm.inverse());
		return { x: svgPt.x, y: svgPt.y };
	}

	function hitTestRoom(sx: number, sy: number): string | null {
		for (const room of homeStore.rooms) {
			const pos = homeStore.roomPositions[room.roomId];
			if (!pos) continue;
			const accs = homeStore.accessoriesForRoom(room.roomId);
			const r = roomRadius(accs.length) * 1.1;
			const dx = sx - pos.x;
			const dy = sy - pos.y;
			if (dx * dx + dy * dy < r * r) return room.roomId;
		}
		return null;
	}

	function handlePointerDown(e: MouseEvent | TouchEvent) {
		const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
		const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;
		const pt = svgPoint(clientX, clientY);
		const roomId = hitTestRoom(pt.x, pt.y);
		if (roomId) {
			const pos = homeStore.roomPositions[roomId];
			if (pos) {
				dragState = {
					roomId,
					startX: pt.x,
					startY: pt.y,
					origX: pos.x,
					origY: pos.y,
				};
				hasDragged = false;
			}
		}
	}

	function handlePointerMove(e: MouseEvent | TouchEvent) {
		if (!dragState) return;
		const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
		const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;
		const pt = svgPoint(clientX, clientY);
		const dx = pt.x - dragState.startX;
		const dy = pt.y - dragState.startY;

		if (!hasDragged && Math.sqrt(dx * dx + dy * dy) > 3) {
			hasDragged = true;
		}

		if (hasDragged) {
			const newX = Math.min(1440, Math.max(60, dragState.origX + dx));
			const newY = Math.min(940, Math.max(60, dragState.origY + dy));
			homeStore.updateRoomPosition(dragState.roomId, newX, newY);
		}
	}

	function handlePointerUp(e: MouseEvent | TouchEvent) {
		if (dragState) {
			if (!hasDragged) {
				homeStore.openRoom(dragState.roomId);
			} else {
				homeStore.savePositions();
			}
			dragState = null;
			return;
		}
		// Click on empty canvas area -- close panel
		if (!hasDragged) {
			homeStore.closePanel();
		}
	}

	function handleKeydown(e: KeyboardEvent) {
		if (e.key === 'Escape') {
			homeStore.closePanel();
		}
	}

	// Zone line colours
	function zoneColor(zoneName: string): string {
		if (/upstairs/i.test(zoneName)) return '#89F7FE';
		if (/outside/i.test(zoneName)) return '#00F5A0';
		return '#FFB347';
	}
</script>

<svelte:window onkeydown={handleKeydown} />

<!-- svelte-ignore a11y_no_static_element_interactions -->
<svg
	bind:this={svgEl}
	viewBox="0 0 1500 1000"
	width="100%"
	height="100%"
	style="display:block; background:transparent;"
	onmousedown={handlePointerDown}
	ontouchstart={handlePointerDown}
	onmousemove={handlePointerMove}
	ontouchmove={handlePointerMove}
	onmouseup={handlePointerUp}
	ontouchend={handlePointerUp}
>
	<defs>
		<!-- Glow filters — tight blur to avoid visible bounding box -->
		<filter id="glow-amber" x="-80%" y="-80%" width="260%" height="260%">
			<feGaussianBlur in="SourceGraphic" stdDeviation="12" result="blur" />
			<feFlood flood-color="#FFB347" flood-opacity="0.15" result="color" />
			<feComposite in="color" in2="blur" operator="in" result="shadow" />
			<feMerge>
				<feMergeNode in="shadow" />
				<feMergeNode in="SourceGraphic" />
			</feMerge>
		</filter>
		<filter id="glow-azure" x="-80%" y="-80%" width="260%" height="260%">
			<feGaussianBlur in="SourceGraphic" stdDeviation="12" result="blur" />
			<feFlood flood-color="#89F7FE" flood-opacity="0.15" result="color" />
			<feComposite in="color" in2="blur" operator="in" result="shadow" />
			<feMerge>
				<feMergeNode in="shadow" />
				<feMergeNode in="SourceGraphic" />
			</feMerge>
		</filter>
		<filter id="glow-emerald" x="-80%" y="-80%" width="260%" height="260%">
			<feGaussianBlur in="SourceGraphic" stdDeviation="12" result="blur" />
			<feFlood flood-color="#00F5A0" flood-opacity="0.15" result="color" />
			<feComposite in="color" in2="blur" operator="in" result="shadow" />
			<feMerge>
				<feMergeNode in="shadow" />
				<feMergeNode in="SourceGraphic" />
			</feMerge>
		</filter>
		<filter id="glow-pink" x="-80%" y="-80%" width="260%" height="260%">
			<feGaussianBlur in="SourceGraphic" stdDeviation="12" result="blur" />
			<feFlood flood-color="#FF6FD8" flood-opacity="0.15" result="color" />
			<feComposite in="color" in2="blur" operator="in" result="shadow" />
			<feMerge>
				<feMergeNode in="shadow" />
				<feMergeNode in="SourceGraphic" />
			</feMerge>
		</filter>
		<filter id="soft-blur" x="-100%" y="-100%" width="300%" height="300%">
			<feGaussianBlur in="SourceGraphic" stdDeviation="20" />
		</filter>
		<filter id="atmosphere-blur" x="-200%" y="-200%" width="500%" height="500%">
			<feGaussianBlur in="SourceGraphic" stdDeviation="60" />
		</filter>
	</defs>

	<!-- Zone halos: dashed lines between rooms in the same zone -->
	{#each homeStore.zones as zone}
		{@const color = zoneColor(zone.zoneName)}
		{#each zone.roomIds as roomIdA, ia}
			{#each zone.roomIds as roomIdB, ib}
				{#if ib > ia}
					{@const posA = homeStore.roomPositions[roomIdA]}
					{@const posB = homeStore.roomPositions[roomIdB]}
					{#if posA && posB}
						<line
							x1={posA.x}
							y1={posA.y}
							x2={posB.x}
							y2={posB.y}
							stroke={color}
							stroke-opacity="0.08"
							stroke-width="1"
							stroke-dasharray="6 8"
						/>
					{/if}
				{/if}
			{/each}
		{/each}
	{/each}

	<!-- Atmosphere circles behind each room -->
	{#each homeStore.rooms as room, i}
		{@const pos = homeStore.roomPositions[room.roomId]}
		{@const glow = getRoomGlow(room, homeStore.accessories)}
		{@const accs = homeStore.accessoriesForRoom(room.roomId)}
		{@const baseR = roomRadius(accs.length)}
		{@const filtered = homeStore.filteredRoomIds}
		{@const dimmed = filtered !== null && !filtered.has(room.roomId)}
		{#if pos}
			<circle
				cx={pos.x}
				cy={pos.y}
				r={80}
				fill={glow.color}
				opacity="0"
				filter="url(#atmosphere-blur)"
				style="animation: atmosphere-in 1.5s ease {2.0 + i * 0.08}s forwards; {dimmed ? 'opacity: 0.08;' : ''}"
			/>
		{/if}
	{/each}

	<!-- Room blobs -->
	{#each homeStore.rooms as room, i}
		{@const pos = homeStore.roomPositions[room.roomId]}
		{@const filtered = homeStore.filteredRoomIds}
		{@const dimmed = filtered !== null && !filtered.has(room.roomId)}
		{#if pos}
			<g style="opacity: {dimmed ? 0.15 : 1}; transition: opacity 0.4s ease; {dimmed ? 'pointer-events: none;' : ''}">
				<RoomBlob {room} cx={pos.x} cy={pos.y} index={i} />
			</g>
		{/if}
	{/each}

	<!-- Singularity flash -->
	<circle
		cx={750}
		cy={500}
		r={3}
		fill="white"
		opacity="0"
		style="animation: singularity 1.5s ease-out 0.2s both;"
	/>

	<!-- User paths overlay -->
	{#if pathStore.pathModeActive && pathStore.currentPath}
		<UserPaths />
	{/if}
</svg>

<style>
	@keyframes atmosphere-in {
		from {
			opacity: 0;
		}
		to {
			opacity: 0.08;
		}
	}

	@keyframes singularity {
		0% {
			opacity: 0.8;
			r: 2;
		}
		50% {
			opacity: 0.4;
			r: 120;
		}
		100% {
			opacity: 0;
			r: 300;
		}
	}
</style>
