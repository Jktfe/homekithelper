<script lang="ts">
	import { homeStore } from '$lib/stores/home.svelte';
	import FloorSlab from './FloorSlab.svelte';

	const defaultFloors = [
		{ name: 'Ground Floor', color: '#89F7FE', roomCount: 7 },
		{ name: 'First Floor', color: '#d4a053', roomCount: 0 },
		{ name: 'Garden', color: '#00E676', roomCount: 0 },
	];

	const zoneColors = ['#FFB347', '#89F7FE', '#00E676', '#FF6FD8'];

	let selectedIndex = $state(0);

	let floors = $derived(
		homeStore.zones.length > 0
			? homeStore.zones.map((z, i) => ({
					name: z.zoneName,
					color: zoneColors[i % zoneColors.length],
					roomCount: z.roomIds.length,
				}))
			: defaultFloors
	);
</script>

<nav class="building-nav">
	<h2 class="heading">FLOORS</h2>
	{#each floors as floor, i}
		<FloorSlab
			name={floor.name}
			selected={selectedIndex === i}
			color={floor.color}
			roomCount={floor.roomCount}
			onclick={() => (selectedIndex = i)}
		/>
	{/each}
</nav>

<style>
	.building-nav {
		position: fixed;
		top: 80px;
		left: 24px;
		z-index: 90;
		padding: 16px;
		border-radius: 16px;
		background: var(--glass-bg);
		border: 1px solid var(--card-border);
		backdrop-filter: blur(20px);
		-webkit-backdrop-filter: blur(20px);
	}

	.heading {
		font-family: 'Syncopate', sans-serif;
		font-size: 10px;
		text-transform: uppercase;
		color: var(--text-tertiary);
		letter-spacing: 0.12em;
		margin: 0 0 12px 0;
		font-weight: 400;
	}
</style>
