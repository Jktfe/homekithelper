<script lang="ts">
	import { pathStore } from '$lib/stores/paths.svelte';
	import { homeStore } from '$lib/stores/home.svelte';
	import PathLine from './PathLine.svelte';
	import Waypoint from './Waypoint.svelte';

	let path = $derived(pathStore.currentPath);
	let positions = $derived(homeStore.roomPositions);
	let mode = $derived(pathStore.pathMode);
</script>

{#if path}
	<g class="user-paths">
		<!-- Lines between consecutive waypoints -->
		{#each path.waypoints as wp, i}
			{#if i > 0}
				{@const prevPos = positions[path.waypoints[i - 1].roomId]}
				{@const currPos = positions[wp.roomId]}
				{#if prevPos && currPos}
					<PathLine
						x1={prevPos.x}
						y1={prevPos.y}
						x2={currPos.x}
						y2={currPos.y}
						color={path.color}
						{mode}
					/>
				{/if}
			{/if}
		{/each}

		<!-- Waypoint markers -->
		{#each path.waypoints as wp, i}
			{@const pos = positions[wp.roomId]}
			{#if pos}
				<Waypoint
					x={pos.x}
					y={pos.y}
					index={i}
					color={path.color}
					time={wp.time}
					action={wp.action}
				/>
			{/if}
		{/each}
	</g>
{/if}
