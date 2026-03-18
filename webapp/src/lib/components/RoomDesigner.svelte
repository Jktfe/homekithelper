<script lang="ts">
	import { homeStore } from '$lib/stores/home.svelte';
	import { layoutStore, GRID_COLS, GRID_ROWS, CELL_SIZE } from '$lib/stores/layouts.svelte';
	import { pathStore } from '$lib/stores/paths.svelte';
	import { siriScore, siriColor, siriClass, siriLabel } from '$lib/utils/siri-score';
	import type { AccessoryData } from '$lib/types/homekit';
	import { SERVICE_TYPES, CHAR_TYPES } from '$lib/types/homekit';
	import type { SceneAction } from '$lib/types/changeset';

	const DEVICE_ICONS = [
		'💡', '🔌', '🌡', '👁', '🪟', '♨', '📷', '🔒',
		'🚪', '🔔', '💨', '🎵', '📺', '🧹', '🪴', '☀️',
		'🌙', '❄️', '🔥', '💧', '⚡', '🎮', '🖥', '🏠',
	];

	const ZONE_TYPE_COLORS: Record<string, string> = {
		building: '#89F7FE',
		floor: '#FFB347',
		zone: '#00E676',
	};

	let room = $derived(
		homeStore.designerRoomId
			? homeStore.rooms.find(r => r.roomId === homeStore.designerRoomId) ?? null
			: null
	);

	let accessories = $derived(
		homeStore.designerRoomId
			? homeStore.accessories.filter(a => a.roomId === homeStore.designerRoomId)
			: []
	);

	let roomAccIds = $derived(new Set(accessories.map(a => a.accessoryId)));

	// Zones for this room
	let roomZones = $derived(
		homeStore.designerRoomId ? homeStore.zonesForRoom(homeStore.designerRoomId) : []
	);

	// All scenes — mark which involve this room
	let allScenes = $derived(homeStore.scenes);
	let roomSceneIds = $derived(
		new Set(
			allScenes
				.filter(s => s.actions?.some(a => roomAccIds.has(a.accessoryId)))
				.map(s => s.sceneId)
		)
	);

	// Zone filter state
	let activeZoneFilter = $state<string | null>(null);
	let zoneFilteredAccIds = $derived.by<Set<string> | null>(() => {
		if (!activeZoneFilter) return null;
		const zone = homeStore.zones.find(z => z.zoneId === activeZoneFilter);
		if (!zone) return null;
		const roomIdsInZone = new Set(zone.roomIds);
		const accIds = new Set<string>();
		for (const acc of homeStore.accessories) {
			if (roomIdsInZone.has(acc.roomId)) accIds.add(acc.accessoryId);
		}
		return accIds;
	});

	function toggleZoneFilter(zoneId: string) {
		activeZoneFilter = activeZoneFilter === zoneId ? null : zoneId;
	}

	function isAccFiltered(accId: string): boolean {
		if (!zoneFilteredAccIds) return false;
		return !zoneFilteredAccIds.has(accId);
	}

	// Scene builder state
	let showSceneBuilder = $state(false);
	let newSceneName = $state('');
	let sceneActions = $state<SceneAction[]>([]);
	let scenePeople = $state<Set<string>>(new Set());
	let builderAccId = $state('');
	let builderCharType = $state('');
	let builderValue = $state('');

	let writableChars = $derived(() => {
		if (!builderAccId) return [];
		const acc = accessories.find(a => a.accessoryId === builderAccId);
		if (!acc) return [];
		const chars: { charType: string; label: string; serviceType: string }[] = [];
		for (const svc of acc.services) {
			for (const ch of svc.characteristics) {
				if (!ch.isWritable) continue;
				const label = getCharLabel(ch.characteristicType);
				if (label) {
					chars.push({ charType: ch.characteristicType, label, serviceType: svc.serviceType });
				}
			}
		}
		return chars;
	});

	function getCharLabel(type: string): string | null {
		if (type.startsWith(CHAR_TYPES.POWER_STATE)) return 'Power';
		if (type.startsWith(CHAR_TYPES.BRIGHTNESS)) return 'Brightness';
		if (type.startsWith(CHAR_TYPES.TARGET_POSITION)) return 'Position';
		if (type.startsWith(CHAR_TYPES.TARGET_TEMPERATURE)) return 'Temperature';
		if (type.startsWith(CHAR_TYPES.ACTIVE)) return 'Active';
		if (type.startsWith(CHAR_TYPES.HUE)) return 'Hue';
		if (type.startsWith(CHAR_TYPES.SATURATION)) return 'Saturation';
		if (type.startsWith(CHAR_TYPES.COLOR_TEMPERATURE)) return 'Colour Temp';
		return null;
	}

	function addSceneAction() {
		if (!builderAccId || !builderCharType || !builderValue) return;
		const charInfo = writableChars().find(c => c.charType === builderCharType);
		if (!charInfo) return;

		let parsed: boolean | number | string = builderValue;
		if (builderValue === 'true' || builderValue === 'false') {
			parsed = builderValue === 'true';
		} else if (!isNaN(Number(builderValue))) {
			parsed = Number(builderValue);
		}

		sceneActions = [...sceneActions, {
			accessoryId: builderAccId,
			serviceType: charInfo.serviceType,
			characteristicType: builderCharType,
			targetValue: parsed,
		}];
		builderCharType = '';
		builderValue = '';
	}

	function removeSceneAction(index: number) {
		sceneActions = sceneActions.filter((_, i) => i !== index);
	}

	function togglePerson(userId: string) {
		const next = new Set(scenePeople);
		if (next.has(userId)) next.delete(userId);
		else next.add(userId);
		scenePeople = next;
	}

	function createRoomScene() {
		const name = newSceneName.trim();
		if (!name || sceneActions.length === 0) return;
		homeStore.createScene(name, sceneActions, scenePeople.size > 0 ? [...scenePeople] : undefined);
		resetSceneBuilder();
	}

	function resetSceneBuilder() {
		showSceneBuilder = false;
		newSceneName = '';
		sceneActions = [];
		scenePeople = new Set();
		builderAccId = '';
		builderCharType = '';
		builderValue = '';
	}

	function getAccessoryName(id: string): string {
		return accessories.find(a => a.accessoryId === id)?.name ?? homeStore.accessories.find(a => a.accessoryId === id)?.name ?? id.slice(0, 8);
	}

	// Selected accessory for the detail panel
	let selectedAccId = $state<string | null>(null);
	let selectedAcc = $derived(
		selectedAccId ? accessories.find(a => a.accessoryId === selectedAccId) ?? null : null
	);

	// Editable fields for selected accessory
	let editName = $state('');
	let editDescription = $state('');
	let editIcon = $state('');
	let nameEdited = $state(false);

	$effect(() => {
		if (selectedAcc) {
			editName = selectedAcc.name;
			nameEdited = false;
			const meta = layoutStore.getMeta(selectedAcc.accessoryId);
			editDescription = meta.description ?? '';
			editIcon = meta.icon ?? getDeviceIcon(selectedAcc);
		}
	});

	function saveName() {
		if (selectedAccId && nameEdited && editName.trim()) {
			homeStore.renameAccessory(selectedAccId, editName.trim());
			nameEdited = false;
		}
	}

	function saveDescription() {
		if (selectedAccId) {
			layoutStore.setMeta(selectedAccId, { description: editDescription });
		}
	}

	function pickIcon(icon: string) {
		editIcon = icon;
		if (selectedAccId) {
			layoutStore.setMeta(selectedAccId, { icon });
		}
	}

	function closeDetail() {
		saveName();
		saveDescription();
		selectedAccId = null;
	}

	// Grid snapping
	function snapToGrid(clientX: number, clientY: number, accId: string): { col: number; row: number } {
		if (!gridEl) return { col: 0, row: 0 };
		const rect = gridEl.getBoundingClientRect();
		let col = Math.round((clientX - rect.left) / CELL_SIZE - 0.5);
		let row = Math.round((clientY - rect.top) / CELL_SIZE - 0.5);
		col = Math.max(0, Math.min(GRID_COLS - 1, col));
		row = Math.max(0, Math.min(GRID_ROWS - 1, row));

		const roomId = homeStore.designerRoomId ?? '';
		if (layoutStore.cellOccupied(roomId, col, row, accId, accessories)) {
			let best: { col: number; row: number } | null = null;
			let bestDist = Infinity;
			for (let r = 0; r < GRID_ROWS; r++) {
				for (let c = 0; c < GRID_COLS; c++) {
					if (!layoutStore.cellOccupied(roomId, c, r, accId, accessories)) {
						const d = Math.abs(c - col) + Math.abs(r - row);
						if (d < bestDist) {
							bestDist = d;
							best = { col: c, row: r };
						}
					}
				}
			}
			if (best) return best;
		}
		return { col, row };
	}

	// Drag state
	let dragAccId = $state<string | null>(null);
	let dragX = $state(0);
	let dragY = $state(0);
	let dragMoved = $state(false);
	let gridEl = $state<HTMLDivElement>(undefined as unknown as HTMLDivElement);

	function startDrag(accId: string, e: MouseEvent) {
		e.preventDefault();
		e.stopPropagation();
		dragAccId = accId;
		dragX = e.clientX;
		dragY = e.clientY;
		dragMoved = false;
	}

	function onMove(e: MouseEvent) {
		if (!dragAccId) return;
		const dx = Math.abs(e.clientX - dragX);
		const dy = Math.abs(e.clientY - dragY);
		if (dx > 4 || dy > 4) dragMoved = true;
		if (dragMoved) {
			dragX = e.clientX;
			dragY = e.clientY;
		}
	}

	function endDrag(e: MouseEvent) {
		if (!dragAccId) return;
		const accId = dragAccId;
		if (dragMoved && gridEl) {
			const snapped = snapToGrid(dragX, dragY, accId);
			const roomId = homeStore.designerRoomId;
			if (roomId) {
				layoutStore.setPos(roomId, accId, snapped);
			}
		} else {
			// Click — select for detail panel
			selectedAccId = accId === selectedAccId ? null : accId;
		}
		dragAccId = null;
		dragMoved = false;
	}

	function getDeviceIcon(acc: AccessoryData): string {
		// Check for custom icon first
		const meta = layoutStore.getMeta(acc.accessoryId);
		if (meta.icon) return meta.icon;
		const primary = acc.services.find(s => s.isPrimary);
		if (!primary) return '◯';
		const t = primary.serviceType;
		if (t.startsWith(SERVICE_TYPES.LIGHTBULB)) return '💡';
		if (t.startsWith(SERVICE_TYPES.MOTION_SENSOR)) return '👁';
		if (t.startsWith(SERVICE_TYPES.TEMPERATURE_SENSOR)) return '🌡';
		if (t.startsWith(SERVICE_TYPES.WINDOW_COVERING)) return '🪟';
		if (t.startsWith(SERVICE_TYPES.OUTLET)) return '🔌';
		if (t.startsWith(SERVICE_TYPES.HEATER_COOLER)) return '♨';
		if (t.startsWith(SERVICE_TYPES.CAMERA)) return '📷';
		return '◯';
	}

	function isOn(acc: AccessoryData): boolean {
		return acc.services.some(s =>
			s.characteristics.some(c =>
				(c.description === 'Power State' || c.description === 'Active') && c.value === '1'
			)
		);
	}

	// Siri score for detail panel
	let accScore = $derived(selectedAcc ? siriScore(editName) : 0);
	let accScoreClass = $derived(siriClass(accScore));
	let accScoreLabel = $derived(siriLabel(accScore));
</script>

{#if homeStore.designerRoomId && room}
	<!-- svelte-ignore a11y_no_static_element_interactions -->
	<div
		class="designer-overlay"
		onmousemove={onMove}
		onmouseup={endDrag}
	>
		<div class="designer-header">
			<button class="back-btn" onclick={() => homeStore.closeDesigner()}>
				← Back to Canvas
			</button>
			<h2 class="designer-title">{room.roomName}</h2>
			<span class="device-count">{accessories.length} device{accessories.length !== 1 ? 's' : ''}</span>
		</div>

		<div class="designer-body">
			<!-- Left Panel: Zones, Scenes, Scene Builder -->
			<div class="left-panel">
				<div class="left-panel-scroll">
					<!-- Zone tags -->
					{#if roomZones.length > 0}
						<div class="lp-section">
							<span class="lp-label">Zones</span>
							<div class="zone-tags">
								{#each roomZones as zone}
									<button
										class="zone-tag"
										class:active={activeZoneFilter === zone.zoneId}
										style="--zone-color: {ZONE_TYPE_COLORS[zone.zoneType] ?? '#888'};"
										onclick={() => toggleZoneFilter(zone.zoneId)}
									>
										<span class="zone-type-dot"></span>
										{zone.zoneName}
									</button>
								{/each}
							</div>
						</div>
					{/if}

					<!-- Scene list -->
					<div class="lp-section">
						<span class="lp-label">Scenes <span class="lp-count">{allScenes.length}</span></span>
						<div class="scene-list">
							{#each allScenes as scene (scene.sceneId)}
								{@const isRoomScene = roomSceneIds.has(scene.sceneId)}
								{@const isImported = !scene.actions}
								<div
									class="scene-card"
									class:room-scene={isRoomScene}
									class:imported={isImported}
								>
									<div class="scene-info">
										<span class="scene-name">{scene.sceneName}</span>
										<span class="scene-meta">
											{scene.actionCount} action{scene.actionCount !== 1 ? 's' : ''}
											{#if isImported}
												<span class="imported-badge">imported</span>
											{/if}
										</span>
										{#if scene.people?.length}
											<div class="scene-people">
												{#each scene.people as userId}
													{@const member = pathStore.members.find(m => m.userId === userId)}
													{#if member}
														<span class="person-chip-sm" style="--person-color: {member.color};">{member.userName}</span>
													{/if}
												{/each}
											</div>
										{/if}
									</div>
									{#if !isImported}
										<button
											class="delete-scene-btn"
											onclick={() => homeStore.deleteScene(scene.sceneId)}
											title="Delete scene"
										>&times;</button>
									{/if}
								</div>
							{/each}

							{#if allScenes.length === 0}
								<p class="empty-hint">No scenes configured</p>
							{/if}
						</div>
					</div>

					<!-- Scene builder -->
					{#if showSceneBuilder}
						<div class="lp-section builder-section">
							<span class="lp-label">New Room Scene</span>

							<input
								type="text"
								class="builder-name-input"
								placeholder="Scene name"
								bind:value={newSceneName}
							/>

							<!-- Actions list -->
							{#if sceneActions.length > 0}
								<div class="action-chips">
									{#each sceneActions as action, i}
										<div class="action-chip">
											<span class="action-text">
												{getAccessoryName(action.accessoryId)} · {getCharLabel(action.characteristicType) ?? '?'} → {String(action.targetValue)}
											</span>
											<button class="chip-remove" onclick={() => removeSceneAction(i)}>&times;</button>
										</div>
									{/each}
								</div>
							{/if}

							<!-- Action builder -->
							<div class="action-builder">
								<select class="builder-select" bind:value={builderAccId}>
									<option value="">Select accessory</option>
									{#each accessories as acc}
										<option value={acc.accessoryId}>{acc.name}</option>
									{/each}
								</select>

								{#if builderAccId}
									<select class="builder-select" bind:value={builderCharType}>
										<option value="">Select property</option>
										{#each writableChars() as ch}
											<option value={ch.charType}>{ch.label}</option>
										{/each}
									</select>
								{/if}

								{#if builderCharType}
									{@const charInfo = writableChars().find(c => c.charType === builderCharType)}
									{#if charInfo && (charInfo.label === 'Power' || charInfo.label === 'Active')}
										<select class="builder-select" bind:value={builderValue}>
											<option value="">Select value</option>
											<option value="true">On</option>
											<option value="false">Off</option>
										</select>
									{:else}
										<input
											type="number"
											class="builder-input"
											placeholder="Value"
											bind:value={builderValue}
										/>
									{/if}

									<button class="add-action-btn" onclick={addSceneAction} disabled={!builderValue}>+</button>
								{/if}
							</div>

							<!-- People toggles -->
							<div class="people-section">
								<span class="lp-sublabel">People</span>
								<div class="people-toggles">
									{#each pathStore.members as member}
										<button
											class="person-chip"
											class:active={scenePeople.has(member.userId)}
											style="--person-color: {member.color};"
											onclick={() => togglePerson(member.userId)}
										>{member.userName}</button>
									{/each}
								</div>
							</div>

							<div class="builder-actions">
								<button class="btn-ghost" onclick={resetSceneBuilder}>Cancel</button>
								<button
									class="btn-primary"
									onclick={createRoomScene}
									disabled={!newSceneName.trim() || sceneActions.length === 0}
								>
									Create ({sceneActions.length} action{sceneActions.length !== 1 ? 's' : ''})
								</button>
							</div>
						</div>
					{:else}
						<button class="new-scene-btn" onclick={() => (showSceneBuilder = true)}>
							+ New Room Scene
						</button>
					{/if}
				</div>
			</div>

			<!-- Grid area -->
			<div class="designer-scroll">
				<div
					class="designer-grid"
					bind:this={gridEl}
					style="
						grid-template-columns: repeat({GRID_COLS}, {CELL_SIZE}px);
						grid-template-rows: repeat({GRID_ROWS}, {CELL_SIZE}px);
					"
				>
					<!-- Grid cells -->
					{#each Array(GRID_ROWS) as _, r}
						{#each Array(GRID_COLS) as _, c}
							<div class="grid-cell" style="grid-column: {c + 1}; grid-row: {r + 1};"></div>
						{/each}
					{/each}

					<!-- Accessories -->
					{#each accessories as acc, i}
						{@const roomId = homeStore.designerRoomId ?? ''}
						{@const pos = layoutStore.getPos(roomId, acc.accessoryId, i)}
						{@const score = siriScore(acc.name)}
						{@const sColor = siriColor(score)}
						{@const on = isOn(acc)}
						{@const icon = getDeviceIcon(acc)}
						{@const isDragging = dragAccId === acc.accessoryId && dragMoved}
						{@const isSelected = selectedAccId === acc.accessoryId}
						{@const filtered = isAccFiltered(acc.accessoryId)}
						<!-- svelte-ignore a11y_no_static_element_interactions -->
						<div
							class="acc-tile"
							class:on
							class:dragging={isDragging}
							class:selected={isSelected}
							class:zone-filtered={filtered}
							style="
								grid-column: {pos.col + 1};
								grid-row: {pos.row + 1};
								--acc-color: {sColor};
								{isDragging ? `position: fixed; left: ${dragX}px; top: ${dragY}px; transform: translate(-50%, -50%); z-index: 100;` : ''}
							"
							onmousedown={(e) => startDrag(acc.accessoryId, e)}
						>
							<span class="tile-icon">{icon}</span>
							<span class="tile-name">{acc.name}</span>
							<span class="tile-score" style="color: {sColor};">{score}</span>
							{#if on}
								<div class="tile-glow"></div>
							{/if}
						</div>
					{/each}
				</div>
			</div>

			<!-- Accessory Detail Panel -->
			<div class="detail-panel" class:open={selectedAcc !== null}>
				{#if selectedAcc}
					<div class="detail-header">
						<h3 class="detail-title">Accessory</h3>
						<button class="detail-close" onclick={closeDetail}>&times;</button>
					</div>

					<div class="detail-body">
						<!-- Current icon + picker -->
						<div class="detail-section">
							<span class="detail-label">Icon</span>
							<div class="icon-current">{editIcon}</div>
							<div class="icon-grid">
								{#each DEVICE_ICONS as ico}
									<button
										class="icon-btn"
										class:active={editIcon === ico}
										onclick={() => pickIcon(ico)}
									>{ico}</button>
								{/each}
							</div>
						</div>

						<!-- Description -->
						<div class="detail-section">
							<label class="detail-label" for="acc-desc">Description</label>
							<textarea
								id="acc-desc"
								class="detail-textarea"
								placeholder="What is this device? Where is it? What does it control?"
								bind:value={editDescription}
								onblur={saveDescription}
								rows="3"
							></textarea>
						</div>

						<!-- Rename -->
						<div class="detail-section">
							<label class="detail-label" for="acc-rename">Name</label>
							<div class="name-row">
								<input
									id="acc-rename"
									type="text"
									class="detail-input"
									value={editName}
									oninput={(e) => { editName = (e.target as HTMLInputElement).value; nameEdited = true; }}
									onblur={saveName}
									onkeydown={(e) => { if (e.key === 'Enter') saveName(); }}
								/>
								<span class="siri-badge {accScoreClass}">{accScore}</span>
							</div>
							<div class="siri-bar">
								<div class="siri-fill {accScoreClass}" style="width: {accScore}%;"></div>
							</div>
							<span class="siri-text">{accScoreLabel}</span>
						</div>

						<!-- Device info (read-only) -->
						<div class="detail-section">
							<span class="detail-label">Device Info</span>
							<div class="info-row">
								<span class="info-key">Manufacturer</span>
								<span class="info-val">{selectedAcc.manufacturer}</span>
							</div>
							<div class="info-row">
								<span class="info-key">Model</span>
								<span class="info-val">{selectedAcc.model}</span>
							</div>
							<div class="info-row">
								<span class="info-key">Category</span>
								<span class="info-val">{selectedAcc.category}</span>
							</div>
							<div class="info-row">
								<span class="info-key">Firmware</span>
								<span class="info-val">{selectedAcc.firmwareVersion}</span>
							</div>
							<div class="info-row">
								<span class="info-key">Reachable</span>
								<span class="info-val">{selectedAcc.isReachable ? 'Yes' : 'No'}</span>
							</div>
						</div>
					</div>
				{/if}
			</div>
		</div>

		<div class="designer-footer">
			<p class="hint">Drag to rearrange · Click to inspect and rename</p>
		</div>
	</div>
{/if}

<style>
	.designer-overlay {
		position: fixed;
		inset: 0;
		z-index: 250;
		background: var(--surface);
		display: flex;
		flex-direction: column;
	}

	.designer-header {
		display: flex;
		align-items: center;
		gap: 16px;
		padding: 20px 28px;
		border-bottom: 1px solid var(--card-border);
		flex-shrink: 0;
	}

	.back-btn {
		font-family: 'DM Sans', sans-serif;
		font-size: 12px;
		padding: 6px 14px;
		border-radius: 16px;
		border: 1px solid var(--card-border);
		background: var(--card-bg);
		color: var(--text-secondary);
		cursor: pointer;
		transition: all 0.2s;
	}

	.back-btn:hover {
		background: var(--card-hover);
		color: var(--text-primary);
	}

	.designer-title {
		font-family: 'Syncopate', sans-serif;
		font-size: 16px;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: var(--text-primary);
		margin: 0;
	}

	.device-count {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		color: var(--text-tertiary);
		background: var(--card-bg);
		padding: 4px 10px;
		border-radius: 10px;
		border: 1px solid var(--card-border);
	}

	.designer-body {
		flex: 1;
		display: flex;
		overflow: hidden;
	}

	/* ── Left Panel ── */
	.left-panel {
		width: 260px;
		border-right: 1px solid var(--card-border);
		background: var(--panel-bg);
		backdrop-filter: blur(40px);
		-webkit-backdrop-filter: blur(40px);
		flex-shrink: 0;
		display: flex;
		flex-direction: column;
		overflow: hidden;
	}

	.left-panel-scroll {
		flex: 1;
		overflow-y: auto;
		padding: 16px;
		display: flex;
		flex-direction: column;
		gap: 16px;
	}

	.lp-section {
		display: flex;
		flex-direction: column;
		gap: 8px;
	}

	.lp-label {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: var(--text-tertiary);
		display: flex;
		align-items: center;
		gap: 6px;
	}

	.lp-sublabel {
		font-family: 'JetBrains Mono', monospace;
		font-size: 8px;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: var(--text-muted);
	}

	.lp-count {
		font-size: 8px;
		background: var(--card-bg);
		padding: 1px 5px;
		border-radius: 6px;
		border: 1px solid var(--card-border);
	}

	/* Zone tags */
	.zone-tags {
		display: flex;
		flex-wrap: wrap;
		gap: 4px;
	}

	.zone-tag {
		font-family: 'DM Sans', sans-serif;
		font-size: 10px;
		font-weight: 500;
		padding: 4px 10px;
		border-radius: 12px;
		border: 1px solid color-mix(in srgb, var(--zone-color), transparent 70%);
		background: color-mix(in srgb, var(--zone-color), transparent 92%);
		color: var(--zone-color);
		cursor: pointer;
		transition: all 0.2s;
		display: flex;
		align-items: center;
		gap: 4px;
	}

	.zone-tag:hover {
		background: color-mix(in srgb, var(--zone-color), transparent 85%);
	}

	.zone-tag.active {
		background: color-mix(in srgb, var(--zone-color), transparent 75%);
		border-color: var(--zone-color);
		box-shadow: 0 0 8px color-mix(in srgb, var(--zone-color), transparent 70%);
	}

	.zone-type-dot {
		width: 5px;
		height: 5px;
		border-radius: 50%;
		background: var(--zone-color);
	}

	/* Scene list */
	.scene-list {
		display: flex;
		flex-direction: column;
		gap: 4px;
	}

	.scene-card {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 8px 10px;
		background: var(--card-bg);
		border: 1px solid var(--card-border);
		border-radius: 10px;
		transition: border-color 0.2s;
	}

	.scene-card.room-scene {
		border-color: color-mix(in srgb, var(--solar-amber), transparent 50%);
		background: color-mix(in srgb, var(--solar-amber), transparent 95%);
	}

	.scene-card.imported {
		opacity: 0.5;
	}

	.scene-info {
		display: flex;
		flex-direction: column;
		gap: 2px;
		min-width: 0;
	}

	.scene-name {
		font-family: 'DM Sans', sans-serif;
		font-size: 11px;
		font-weight: 500;
		color: var(--text-primary);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.scene-meta {
		font-family: 'JetBrains Mono', monospace;
		font-size: 8px;
		color: var(--text-muted);
		display: flex;
		align-items: center;
		gap: 4px;
	}

	.imported-badge {
		font-size: 7px;
		padding: 1px 4px;
		border-radius: 4px;
		background: var(--card-border);
		color: var(--text-muted);
	}

	.scene-people {
		display: flex;
		flex-wrap: wrap;
		gap: 3px;
		margin-top: 2px;
	}

	.person-chip-sm {
		font-family: 'JetBrains Mono', monospace;
		font-size: 7px;
		padding: 1px 5px;
		border-radius: 6px;
		background: color-mix(in srgb, var(--person-color), transparent 85%);
		color: var(--person-color);
		border: 1px solid color-mix(in srgb, var(--person-color), transparent 70%);
	}

	.delete-scene-btn {
		width: 22px;
		height: 22px;
		border-radius: 50%;
		border: 1px solid transparent;
		background: none;
		color: var(--text-muted);
		font-size: 14px;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: all 0.2s;
		opacity: 0;
		flex-shrink: 0;
	}

	.scene-card:hover .delete-scene-btn {
		opacity: 1;
	}

	.delete-scene-btn:hover {
		color: var(--siri-red);
		border-color: var(--siri-red);
	}

	.empty-hint {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		color: var(--text-muted);
		text-align: center;
		padding: 8px 0;
		margin: 0;
	}

	/* Scene builder */
	.builder-section {
		background: var(--card-bg);
		border: 1px solid var(--card-border);
		border-radius: 12px;
		padding: 12px;
	}

	.builder-name-input {
		font-family: 'DM Sans', sans-serif;
		font-size: 12px;
		padding: 8px 10px;
		border-radius: 8px;
		border: 1px solid var(--card-border);
		background: var(--surface);
		color: var(--text-primary);
		outline: none;
		width: 100%;
		box-sizing: border-box;
	}

	.builder-name-input:focus {
		border-color: var(--solar-amber);
	}

	.builder-name-input::placeholder {
		color: var(--text-muted);
	}

	.action-chips {
		display: flex;
		flex-direction: column;
		gap: 4px;
	}

	.action-chip {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 5px 8px;
		background: color-mix(in srgb, var(--solar-amber), transparent 94%);
		border: 1px solid color-mix(in srgb, var(--solar-amber), transparent 80%);
		border-radius: 6px;
	}

	.action-text {
		font-family: 'JetBrains Mono', monospace;
		font-size: 8px;
		color: var(--text-secondary);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.chip-remove {
		width: 16px;
		height: 16px;
		border-radius: 50%;
		border: none;
		background: none;
		color: var(--text-muted);
		font-size: 12px;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		flex-shrink: 0;
	}

	.chip-remove:hover {
		color: var(--siri-red);
	}

	.action-builder {
		display: flex;
		flex-direction: column;
		gap: 4px;
	}

	.builder-select {
		font-family: 'DM Sans', sans-serif;
		font-size: 10px;
		padding: 6px 8px;
		border-radius: 6px;
		border: 1px solid var(--card-border);
		background: var(--surface);
		color: var(--text-primary);
		outline: none;
		cursor: pointer;
		width: 100%;
		box-sizing: border-box;
		appearance: none;
		-webkit-appearance: none;
		background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='8' height='5'%3E%3Cpath d='M0 0l4 5 4-5z' fill='%23888'/%3E%3C/svg%3E");
		background-repeat: no-repeat;
		background-position: right 6px center;
		padding-right: 18px;
	}

	.builder-select:focus {
		border-color: var(--solar-amber);
	}

	.builder-input {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		padding: 6px 8px;
		border-radius: 6px;
		border: 1px solid var(--card-border);
		background: var(--surface);
		color: var(--text-primary);
		outline: none;
		width: 100%;
		box-sizing: border-box;
	}

	.builder-input:focus {
		border-color: var(--solar-amber);
	}

	.add-action-btn {
		width: 100%;
		padding: 6px;
		border-radius: 6px;
		border: 1px solid var(--solar-amber);
		background: color-mix(in srgb, var(--solar-amber), transparent 90%);
		color: var(--solar-amber);
		font-size: 14px;
		font-weight: 700;
		cursor: pointer;
		transition: all 0.15s;
	}

	.add-action-btn:hover {
		background: color-mix(in srgb, var(--solar-amber), transparent 80%);
	}

	.add-action-btn:disabled {
		opacity: 0.3;
		cursor: not-allowed;
	}

	/* People toggles */
	.people-section {
		display: flex;
		flex-direction: column;
		gap: 4px;
	}

	.people-toggles {
		display: flex;
		flex-wrap: wrap;
		gap: 4px;
	}

	.person-chip {
		font-family: 'DM Sans', sans-serif;
		font-size: 10px;
		font-weight: 500;
		padding: 4px 10px;
		border-radius: 10px;
		border: 1px solid color-mix(in srgb, var(--person-color), transparent 70%);
		background: transparent;
		color: var(--person-color);
		cursor: pointer;
		transition: all 0.2s;
		opacity: 0.5;
	}

	.person-chip:hover {
		opacity: 0.8;
	}

	.person-chip.active {
		opacity: 1;
		background: color-mix(in srgb, var(--person-color), transparent 85%);
		border-color: var(--person-color);
	}

	.builder-actions {
		display: flex;
		justify-content: flex-end;
		gap: 6px;
		margin-top: 4px;
	}

	.btn-ghost {
		padding: 6px 12px;
		border-radius: 8px;
		border: 1px solid var(--card-border);
		background: transparent;
		color: var(--text-tertiary);
		font-size: 10px;
		cursor: pointer;
		transition: all 0.2s;
		font-family: 'DM Sans', sans-serif;
	}

	.btn-ghost:hover {
		background: var(--card-hover);
		color: var(--text-secondary);
	}

	.btn-primary {
		padding: 6px 12px;
		border-radius: 8px;
		border: none;
		background: rgba(255, 179, 71, 0.9);
		color: #0F1115;
		font-size: 10px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
		font-family: 'DM Sans', sans-serif;
	}

	.btn-primary:hover {
		background: #FFB347;
	}

	.btn-primary:disabled {
		opacity: 0.3;
		cursor: not-allowed;
	}

	.new-scene-btn {
		padding: 10px;
		border-radius: 10px;
		border: 1px dashed var(--solar-amber);
		background: color-mix(in srgb, var(--solar-amber), transparent 94%);
		color: var(--solar-amber);
		font-family: 'DM Sans', sans-serif;
		font-size: 11px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
		text-align: center;
	}

	.new-scene-btn:hover {
		background: color-mix(in srgb, var(--solar-amber), transparent 88%);
	}

	/* ── Grid area ── */
	.designer-scroll {
		flex: 1;
		overflow: auto;
		display: flex;
		justify-content: center;
		align-items: flex-start;
		padding: 32px;
	}

	.designer-grid {
		display: grid;
		gap: 0;
		position: relative;
	}

	.grid-cell {
		border: 1px solid var(--card-border);
		border-radius: 4px;
		opacity: 0.4;
	}

	.acc-tile {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 2px;
		border-radius: 12px;
		border: 1.5px solid var(--card-border);
		background: var(--card-bg);
		cursor: grab;
		user-select: none;
		position: relative;
		transition: border-color 0.2s, box-shadow 0.2s, opacity 0.3s;
		z-index: 2;
	}

	.acc-tile:hover {
		border-color: var(--text-tertiary);
		z-index: 10;
	}

	.acc-tile.on {
		border-color: var(--acc-color, var(--solar-amber));
		box-shadow: 0 0 12px color-mix(in srgb, var(--acc-color, var(--solar-amber)), transparent 80%);
	}

	.acc-tile.selected {
		border-color: var(--solar-amber);
		background: color-mix(in srgb, var(--solar-amber), transparent 92%);
		z-index: 11;
	}

	.acc-tile.dragging {
		cursor: grabbing;
		border-color: var(--solar-amber);
		box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
		opacity: 0.9;
	}

	.acc-tile.zone-filtered {
		opacity: 0.15;
		pointer-events: none;
	}

	.tile-icon { font-size: 22px; line-height: 1; }
	.tile-name {
		font-family: 'DM Sans', sans-serif;
		font-size: 8px;
		font-weight: 500;
		color: var(--text-secondary);
		text-align: center;
		max-width: 72px;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
		line-height: 1.2;
	}
	.tile-score {
		font-family: 'JetBrains Mono', monospace;
		font-size: 7px;
		font-weight: 500;
	}
	.tile-glow {
		position: absolute;
		inset: -4px;
		border-radius: 14px;
		background: var(--acc-color, var(--solar-amber));
		opacity: 0.05;
		pointer-events: none;
	}

	/* ── Detail Panel ── */
	.detail-panel {
		width: 320px;
		border-left: 1px solid var(--card-border);
		background: var(--panel-bg);
		backdrop-filter: blur(40px);
		-webkit-backdrop-filter: blur(40px);
		display: flex;
		flex-direction: column;
		transform: translateX(100%);
		transition: transform 0.4s cubic-bezier(0.23, 1, 0.32, 1);
		overflow: hidden;
		flex-shrink: 0;
	}

	.detail-panel.open {
		transform: translateX(0);
	}

	.detail-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 20px;
		border-bottom: 1px solid var(--card-border);
	}

	.detail-title {
		font-family: 'Syncopate', sans-serif;
		font-size: 12px;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: var(--text-primary);
		margin: 0;
	}

	.detail-close {
		width: 28px;
		height: 28px;
		border-radius: 50%;
		border: 1px solid var(--card-border);
		background: none;
		color: var(--text-secondary);
		font-size: 16px;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: all 0.2s;
	}

	.detail-close:hover {
		border-color: var(--text-tertiary);
		color: var(--text-primary);
	}

	.detail-body {
		flex: 1;
		overflow-y: auto;
		padding: 16px 20px;
		display: flex;
		flex-direction: column;
		gap: 20px;
	}

	.detail-section {
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	.detail-label {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: var(--text-tertiary);
	}

	.icon-current {
		font-size: 36px;
		text-align: center;
		padding: 8px 0;
	}

	.icon-grid {
		display: flex;
		flex-wrap: wrap;
		gap: 4px;
	}

	.icon-btn {
		width: 32px;
		height: 32px;
		border-radius: 8px;
		border: 1px solid var(--card-border);
		background: var(--card-bg);
		font-size: 16px;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: all 0.15s;
	}

	.icon-btn:hover {
		background: var(--card-hover);
	}

	.icon-btn.active {
		border-color: var(--solar-amber);
		background: color-mix(in srgb, var(--solar-amber), transparent 88%);
	}

	.detail-textarea {
		font-family: 'DM Sans', sans-serif;
		font-size: 12px;
		padding: 10px 12px;
		border-radius: 10px;
		border: 1px solid var(--card-border);
		background: var(--card-bg);
		color: var(--text-primary);
		resize: vertical;
		outline: none;
		transition: border-color 0.2s;
	}

	.detail-textarea:focus {
		border-color: var(--solar-amber);
	}

	.detail-textarea::placeholder {
		color: var(--text-muted);
		font-size: 11px;
	}

	.name-row {
		display: flex;
		align-items: center;
		gap: 8px;
	}

	.detail-input {
		flex: 1;
		font-family: 'DM Sans', sans-serif;
		font-size: 13px;
		font-weight: 500;
		padding: 10px 12px;
		border-radius: 10px;
		border: 1px solid var(--card-border);
		background: var(--card-bg);
		color: var(--text-primary);
		outline: none;
		transition: border-color 0.2s;
	}

	.detail-input:focus {
		border-color: var(--solar-amber);
	}

	.siri-badge {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		font-weight: 700;
		padding: 4px 8px;
		border-radius: 8px;
		white-space: nowrap;
	}

	.siri-bar {
		height: 4px;
		border-radius: 2px;
		background: var(--card-border);
		overflow: hidden;
	}

	.siri-fill {
		height: 100%;
		border-radius: 2px;
		transition: width 0.3s ease;
	}

	.siri-text {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		color: var(--text-muted);
	}

	.info-row {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 4px 0;
	}

	.info-key {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		color: var(--text-muted);
	}

	.info-val {
		font-family: 'DM Sans', sans-serif;
		font-size: 11px;
		color: var(--text-secondary);
		text-align: right;
		max-width: 160px;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.designer-footer {
		padding: 12px 28px;
		border-top: 1px solid var(--card-border);
		flex-shrink: 0;
	}

	.hint {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		color: var(--text-muted);
		text-align: center;
		margin: 0;
	}
</style>
