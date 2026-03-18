<script lang="ts">
	import { homeStore } from '$lib/stores/home.svelte';
	import { siriScore, siriClass, siriLabel } from '$lib/utils/siri-score';

	import type { ZoneType } from '$lib/types/homekit';

	let roomName = $state('');
	let selectedBuildingId = $state<string | null>(null);
	let selectedFloorId = $state<string | null>(null);
	let selectedZoneIds = $state<Set<string>>(new Set());
	let nameEdited = $state(false);

	// Sync with currently editing room
	$effect(() => {
		const room = homeStore.editingRoom;
		if (room) {
			roomName = room.roomName;
			nameEdited = false;
			// Find which zone of each type this room is in
			const building = homeStore.buildings.find(z => z.roomIds.includes(room.roomId));
			selectedBuildingId = building?.zoneId ?? null;
			const floor = homeStore.floors.find(z => z.roomIds.includes(room.roomId));
			selectedFloorId = floor?.zoneId ?? null;
			// Zones: can be in multiple
			const zoneIds = homeStore.generalZones
				.filter(z => z.roomIds.includes(room.roomId))
				.map(z => z.zoneId);
			selectedZoneIds = new Set(zoneIds);
		}
	});

	function handleNameChange(e: Event) {
		roomName = (e.target as HTMLInputElement).value;
		nameEdited = true;
	}

	function saveName() {
		if (homeStore.editingRoomId && nameEdited) {
			homeStore.updateRoomName(homeStore.editingRoomId, roomName);
			nameEdited = false;
		}
	}

	function handleZoneChange(zoneId: string | null, zoneType: ZoneType) {
		if (zoneType === 'building') selectedBuildingId = zoneId;
		else if (zoneType === 'floor') selectedFloorId = zoneId;
		else if (zoneType === 'zone' && zoneId) {
			// Toggle: add or remove from set
			const next = new Set(selectedZoneIds);
			if (next.has(zoneId)) next.delete(zoneId);
			else next.add(zoneId);
			selectedZoneIds = next;
		}
		if (homeStore.editingRoomId) {
			homeStore.setRoomZone(homeStore.editingRoomId, zoneId, zoneType);
		}
	}

	function openDesigner() {
		if (homeStore.editingRoomId) {
			homeStore.openDesigner(homeStore.editingRoomId);
		}
	}

	let score = $derived(siriScore(roomName));
	let scoreClass = $derived(siriClass(score));
	let scoreLabel = $derived(siriLabel(score));
	let accs = $derived(homeStore.editingRoomAccessories);
</script>

<div class="edit-panel" class:open={homeStore.editPanelOpen}>
	{#if homeStore.editingRoom}
		<div class="panel-header">
			<div class="header-text">
				<h2 class="panel-title">Edit Room</h2>
				<p class="panel-subtitle">{accs.length} device{accs.length !== 1 ? 's' : ''}</p>
			</div>
			<button class="close-btn" onclick={() => homeStore.closeEditPanel()}>
				<span class="close-circle">&times;</span>
			</button>
		</div>

		<div class="panel-body">
			<!-- Room Name -->
			<div class="field-group">
				<label class="field-label" for="room-name-input">Room Name</label>
				<div class="name-row">
					<input
						id="room-name-input"
						type="text"
						class="name-input"
						value={roomName}
						oninput={handleNameChange}
						onblur={saveName}
						onkeydown={(e) => { if (e.key === 'Enter') saveName(); }}
					/>
					<span class="siri-badge {scoreClass}">{scoreLabel} {score}</span>
				</div>
				{#if score < 80}
					<p class="siri-tip">Shorter, simpler names work best with Siri</p>
				{/if}
			</div>

			<!-- Building -->
			<div class="field-group">
				<span class="field-label">Building</span>
				<div class="zone-options">
					<button
						class="zone-pill"
						class:active={selectedBuildingId === null}
						onclick={() => handleZoneChange(null, 'building')}
					>
						Unassigned
					</button>
					{#each homeStore.buildings as bldg}
						<button
							class="zone-pill"
							class:active={selectedBuildingId === bldg.zoneId}
							onclick={() => handleZoneChange(bldg.zoneId, 'building')}
						>
							{bldg.zoneName}
						</button>
					{/each}
				</div>
			</div>

			<!-- Floor -->
			<div class="field-group">
				<span class="field-label">Floor</span>
				<div class="zone-options">
					<button
						class="zone-pill"
						class:active={selectedFloorId === null}
						onclick={() => handleZoneChange(null, 'floor')}
					>
						Unassigned
					</button>
					{#each homeStore.floors as fl}
						<button
							class="zone-pill"
							class:active={selectedFloorId === fl.zoneId}
							onclick={() => handleZoneChange(fl.zoneId, 'floor')}
						>
							{fl.zoneName}
						</button>
					{/each}
				</div>
			</div>

			<!-- Zone (multi-select) -->
			<div class="field-group">
				<span class="field-label">Zone <span class="field-hint">(select multiple)</span></span>
				<div class="zone-options">
					{#each homeStore.generalZones as zone}
						<button
							class="zone-pill"
							class:active={selectedZoneIds.has(zone.zoneId)}
							onclick={() => handleZoneChange(zone.zoneId, 'zone')}
						>
							{zone.zoneName}
						</button>
					{/each}
					{#if homeStore.generalZones.length === 0}
						<span class="empty-pill-hint">No zones — add from sidebar</span>
					{/if}
				</div>
			</div>

			<!-- Accessories list -->
			<div class="field-group">
				<span class="field-label">Accessories ({accs.length})</span>
				<div class="acc-list">
					{#each accs as acc}
						<div class="acc-item">
							<span class="acc-name">{acc.name}</span>
							<span class="acc-mfr">{acc.manufacturer}</span>
						</div>
					{/each}
				</div>
			</div>

			<!-- Design Room button -->
			<button class="design-btn" onclick={openDesigner}>
				<span class="design-icon">⬡</span>
				Design Room Layout
			</button>

			<!-- Delete Room -->
			{#if accs.length === 0}
				<button class="delete-btn" onclick={() => { if (homeStore.editingRoomId) homeStore.deleteRoom(homeStore.editingRoomId); }}>
					Delete Empty Room
				</button>
			{:else}
				<p class="delete-hint">Remove all {accs.length} device{accs.length !== 1 ? 's' : ''} to delete this room</p>
			{/if}
		</div>
	{/if}
</div>

<style>
	.edit-panel {
		position: fixed;
		top: 0;
		right: 0;
		bottom: 0;
		width: 380px;
		z-index: 200;
		background: var(--panel-bg);
		backdrop-filter: blur(40px);
		-webkit-backdrop-filter: blur(40px);
		border-left: 1px solid var(--card-border);
		transform: translateX(100%);
		transition: transform 0.5s cubic-bezier(0.23, 1, 0.32, 1);
		display: flex;
		flex-direction: column;
		overflow: hidden;
	}

	.edit-panel.open {
		transform: translateX(0);
	}

	.panel-header {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
		padding: 28px 24px 20px;
		border-bottom: 1px solid var(--card-border);
		flex-shrink: 0;
	}

	.header-text {
		display: flex;
		flex-direction: column;
		gap: 4px;
	}

	.panel-title {
		font-family: 'Syncopate', sans-serif;
		font-size: 14px;
		font-weight: 700;
		text-transform: uppercase;
		color: var(--text-primary);
		margin: 0;
		letter-spacing: 0.06em;
	}

	.panel-subtitle {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		color: var(--text-tertiary);
		margin: 0;
	}

	.close-btn {
		background: none;
		border: none;
		cursor: pointer;
		padding: 0;
	}

	.close-circle {
		display: flex;
		align-items: center;
		justify-content: center;
		width: 32px;
		height: 32px;
		border-radius: 50%;
		border: 1px solid var(--card-border);
		color: var(--text-secondary);
		font-size: 18px;
		transition: border-color 0.2s, color 0.2s;
	}

	.close-circle:hover {
		border-color: var(--text-tertiary);
		color: var(--text-primary);
	}

	.panel-body {
		flex: 1;
		overflow-y: auto;
		padding: 20px 24px;
		display: flex;
		flex-direction: column;
		gap: 24px;
	}

	.field-group {
		display: flex;
		flex-direction: column;
		gap: 8px;
	}

	.field-label {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: var(--text-tertiary);
	}

	.name-row {
		display: flex;
		align-items: center;
		gap: 10px;
	}

	.name-input {
		flex: 1;
		background: var(--card-bg);
		border: 1px solid var(--card-border);
		border-radius: 10px;
		padding: 10px 14px;
		font-family: 'DM Sans', sans-serif;
		font-size: 14px;
		font-weight: 500;
		color: var(--text-primary);
		outline: none;
		transition: border-color 0.2s;
	}

	.name-input:focus {
		border-color: var(--solar-amber);
	}

	.siri-badge {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		padding: 4px 8px;
		border-radius: 8px;
		white-space: nowrap;
	}

	.siri-tip {
		font-size: 11px;
		color: var(--text-muted);
		font-style: italic;
		margin: 0;
	}

	.zone-options {
		display: flex;
		flex-wrap: wrap;
		gap: 6px;
	}

	.zone-pill {
		font-family: 'DM Sans', sans-serif;
		font-size: 11px;
		padding: 6px 14px;
		border-radius: 16px;
		border: 1px solid var(--card-border);
		background: var(--card-bg);
		color: var(--text-secondary);
		cursor: pointer;
		transition: all 0.2s ease;
	}

	.zone-pill:hover {
		background: var(--card-hover);
	}

	.zone-pill.active {
		border-color: var(--solar-amber);
		background: color-mix(in srgb, var(--solar-amber), transparent 88%);
		color: var(--solar-amber);
	}

	.field-hint {
		font-weight: 400;
		opacity: 0.5;
		font-size: 8px;
	}

	.empty-pill-hint {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		color: var(--text-muted);
	}

	.acc-list {
		display: flex;
		flex-direction: column;
		gap: 6px;
		max-height: 200px;
		overflow-y: auto;
	}

	.acc-item {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 8px 12px;
		border-radius: 10px;
		background: var(--card-bg);
		border: 1px solid var(--card-border);
	}

	.acc-name {
		font-size: 12px;
		font-weight: 500;
		color: var(--text-primary);
	}

	.acc-mfr {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		color: var(--text-muted);
	}

	.design-btn {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 8px;
		padding: 14px;
		border-radius: 14px;
		border: 1px dashed var(--solar-amber);
		background: color-mix(in srgb, var(--solar-amber), transparent 94%);
		color: var(--solar-amber);
		font-family: 'DM Sans', sans-serif;
		font-size: 13px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s ease;
	}

	.design-btn:hover {
		background: color-mix(in srgb, var(--solar-amber), transparent 88%);
	}

	.design-icon {
		font-size: 16px;
	}

	.delete-btn {
		padding: 12px;
		border-radius: 12px;
		border: 1px solid var(--siri-red);
		background: color-mix(in srgb, var(--siri-red), transparent 92%);
		color: var(--siri-red);
		font-family: 'DM Sans', sans-serif;
		font-size: 12px;
		font-weight: 500;
		cursor: pointer;
		transition: all 0.2s;
		text-align: center;
	}

	.delete-btn:hover {
		background: color-mix(in srgb, var(--siri-red), transparent 85%);
	}

	.delete-hint {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		color: var(--text-muted);
		text-align: center;
		margin: 0;
	}
</style>
