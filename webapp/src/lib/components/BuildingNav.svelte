<script lang="ts">
	import { homeStore } from '$lib/stores/home.svelte';
	import type { ZoneType } from '$lib/types/homekit';
	import FloorSlab from './FloorSlab.svelte';

	const buildingColors = ['#FF6FD8', '#C47AFF', '#FF8A65', '#AB47BC'];
	const floorColors = ['#89F7FE', '#4FC3F7', '#80DEEA', '#B2EBF2'];
	const zoneColors = ['#FFB347', '#00E676', '#FFEE58', '#A5D6A7'];

	let selectedIndex = $state(0);
	let showNewRoom = $state(false);
	let showNewBuilding = $state(false);
	let showNewFloor = $state(false);
	let showNewZone = $state(false);
	let newRoomName = $state('');
	let newBuildingName = $state('');
	let newFloorName = $state('');
	let newZoneName = $state('');

	let buildingSlabs = $derived(
		homeStore.buildings.map((z, i) => ({
			name: z.zoneName,
			color: buildingColors[i % buildingColors.length],
			roomCount: z.roomIds.length,
			zoneId: z.zoneId,
		}))
	);

	let floorSlabs = $derived(
		homeStore.floors.map((z, i) => ({
			name: z.zoneName,
			color: floorColors[i % floorColors.length],
			roomCount: z.roomIds.length,
			zoneId: z.zoneId,
		}))
	);

	let zoneSlabs = $derived(
		homeStore.generalZones.map((z, i) => ({
			name: z.zoneName,
			color: zoneColors[i % zoneColors.length],
			roomCount: z.roomIds.length,
			zoneId: z.zoneId,
		}))
	);

	function addRoom() {
		const name = newRoomName.trim();
		if (!name) return;
		homeStore.createRoom(name);
		newRoomName = '';
		showNewRoom = false;
	}

	function addTypedZone(name: string, type: ZoneType) {
		const trimmed = name.trim();
		if (!trimmed) return;
		homeStore.createZone(trimmed, type);
	}

	function addBuilding() {
		addTypedZone(newBuildingName, 'building');
		newBuildingName = '';
		showNewBuilding = false;
	}

	function addFloor() {
		addTypedZone(newFloorName, 'floor');
		newFloorName = '';
		showNewFloor = false;
	}

	function addZone() {
		addTypedZone(newZoneName, 'zone');
		newZoneName = '';
		showNewZone = false;
	}
</script>

<nav class="building-nav">
	<!-- Buildings -->
	<h2 class="heading">BUILDINGS</h2>
	{#each buildingSlabs as bldg}
		<div class="zone-row">
			<button class="zone-slab-wrap" onclick={() => {}}>
				<FloorSlab
					name={bldg.name}
					selected={false}
					color={bldg.color}
					roomCount={bldg.roomCount}
				/>
			</button>
			<button
				class="zone-delete"
				title="Delete building"
				onclick={() => homeStore.deleteZone(bldg.zoneId)}
			>&times;</button>
		</div>
	{/each}
	{#if buildingSlabs.length === 0}
		<p class="empty-hint">No buildings yet</p>
	{/if}
	{#if showNewBuilding}
		<div class="inline-form">
			<!-- svelte-ignore a11y_autofocus -- focus follows explicit user click -->
			<input
				type="text"
				class="inline-input"
				placeholder="Building name"
				bind:value={newBuildingName}
				onkeydown={(e) => { if (e.key === 'Enter') addBuilding(); if (e.key === 'Escape') showNewBuilding = false; }}
				autofocus
			/>
			<button class="inline-ok" onclick={addBuilding}>+</button>
		</div>
	{:else}
		<button class="add-btn" onclick={() => (showNewBuilding = true)}>+ Building</button>
	{/if}

	<div class="divider"></div>

	<!-- Floors -->
	<h2 class="heading">FLOORS</h2>
	{#each floorSlabs as fl}
		<div class="zone-row">
			<button class="zone-slab-wrap" onclick={() => {}}>
				<FloorSlab
					name={fl.name}
					selected={false}
					color={fl.color}
					roomCount={fl.roomCount}
				/>
			</button>
			<button
				class="zone-delete"
				title="Delete floor"
				onclick={() => homeStore.deleteZone(fl.zoneId)}
			>&times;</button>
		</div>
	{/each}
	{#if floorSlabs.length === 0}
		<p class="empty-hint">No floors yet</p>
	{/if}
	{#if showNewFloor}
		<div class="inline-form">
			<!-- svelte-ignore a11y_autofocus -- focus follows explicit user click -->
			<input
				type="text"
				class="inline-input"
				placeholder="Floor name"
				bind:value={newFloorName}
				onkeydown={(e) => { if (e.key === 'Enter') addFloor(); if (e.key === 'Escape') showNewFloor = false; }}
				autofocus
			/>
			<button class="inline-ok" onclick={addFloor}>+</button>
		</div>
	{:else}
		<button class="add-btn" onclick={() => (showNewFloor = true)}>+ Floor</button>
	{/if}

	<div class="divider"></div>

	<!-- Zones -->
	<h2 class="heading">ZONES</h2>
	{#each zoneSlabs as zone, i}
		<div class="zone-row">
			<button class="zone-slab-wrap" onclick={() => (selectedIndex = i)}>
				<FloorSlab
					name={zone.name}
					selected={selectedIndex === i}
					color={zone.color}
					roomCount={zone.roomCount}
				/>
			</button>
			<button
				class="zone-delete"
				title="Delete zone"
				onclick={() => homeStore.deleteZone(zone.zoneId)}
			>&times;</button>
		</div>
	{/each}
	{#if zoneSlabs.length === 0}
		<p class="empty-hint">No zones yet</p>
	{/if}
	{#if showNewZone}
		<div class="inline-form">
			<!-- svelte-ignore a11y_autofocus -- focus follows explicit user click on "+ Zone" button -->
			<input
				type="text"
				class="inline-input"
				placeholder="Zone name"
				bind:value={newZoneName}
				onkeydown={(e) => { if (e.key === 'Enter') addZone(); if (e.key === 'Escape') showNewZone = false; }}
				autofocus
			/>
			<button class="inline-ok" onclick={addZone}>+</button>
		</div>
	{:else}
		<button class="add-btn" onclick={() => (showNewZone = true)}>+ Zone</button>
	{/if}

	<div class="divider"></div>

	<!-- Rooms -->
	<h2 class="heading">ROOMS</h2>
	<p class="room-count">{homeStore.roomCount} rooms</p>
	{#if showNewRoom}
		<div class="inline-form">
			<!-- svelte-ignore a11y_autofocus -- focus follows explicit user click on "+ Room" button -->
			<input
				type="text"
				class="inline-input"
				placeholder="Room name"
				bind:value={newRoomName}
				onkeydown={(e) => { if (e.key === 'Enter') addRoom(); if (e.key === 'Escape') showNewRoom = false; }}
				autofocus
			/>
			<button class="inline-ok" onclick={addRoom}>+</button>
		</div>
	{:else}
		<button class="add-btn" onclick={() => (showNewRoom = true)}>+ Room</button>
	{/if}
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
		min-width: 140px;
	}

	.heading {
		font-family: 'Syncopate', sans-serif;
		font-size: 10px;
		text-transform: uppercase;
		color: var(--text-tertiary);
		letter-spacing: 0.12em;
		margin: 0 0 8px 0;
		font-weight: 400;
	}

	.zone-row {
		display: flex;
		align-items: center;
		gap: 4px;
	}

	.zone-slab-wrap {
		flex: 1;
		cursor: pointer;
		background: none;
		border: none;
		padding: 0;
		text-align: left;
	}

	.zone-delete {
		width: 20px;
		height: 20px;
		border-radius: 50%;
		border: 1px solid transparent;
		background: none;
		color: var(--text-muted);
		font-size: 14px;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		opacity: 0;
		transition: all 0.2s;
		flex-shrink: 0;
	}

	.zone-row:hover .zone-delete {
		opacity: 1;
	}

	.zone-delete:hover {
		color: var(--siri-red);
		border-color: var(--siri-red);
	}

	.empty-hint {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		color: var(--text-muted);
		margin: 4px 0;
	}

	.divider {
		height: 1px;
		background: var(--card-border);
		margin: 12px 0;
	}

	.room-count {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		color: var(--text-tertiary);
		margin: 0 0 8px 0;
	}

	.add-btn {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		color: var(--text-tertiary);
		background: none;
		border: 1px dashed var(--card-border);
		border-radius: 8px;
		padding: 6px 12px;
		cursor: pointer;
		width: 100%;
		text-align: center;
		transition: all 0.2s;
		margin-top: 4px;
	}

	.add-btn:hover {
		color: var(--solar-amber);
		border-color: var(--solar-amber);
	}

	.inline-form {
		display: flex;
		gap: 4px;
		margin-top: 4px;
	}

	.inline-input {
		flex: 1;
		font-family: 'DM Sans', sans-serif;
		font-size: 11px;
		padding: 5px 8px;
		border-radius: 8px;
		border: 1px solid var(--solar-amber);
		background: var(--card-bg);
		color: var(--text-primary);
		outline: none;
		min-width: 0;
	}

	.inline-ok {
		width: 28px;
		height: 28px;
		border-radius: 8px;
		border: 1px solid var(--solar-amber);
		background: color-mix(in srgb, var(--solar-amber), transparent 90%);
		color: var(--solar-amber);
		font-size: 14px;
		font-weight: 700;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		flex-shrink: 0;
	}

	.inline-ok:hover {
		background: color-mix(in srgb, var(--solar-amber), transparent 80%);
	}
</style>
