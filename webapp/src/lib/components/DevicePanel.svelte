<script lang="ts">
	import { homeStore } from '$lib/stores/home.svelte';
	import { siriScore, siriClass, siriLabel, siriColor } from '$lib/utils/siri-score';
	import { CHAR_TYPES } from '$lib/types/homekit';
	import type { AccessoryData, CharacteristicData } from '$lib/types/homekit';

	// Local control state keyed by characteristicId
	let controlState = $state<Record<string, number | boolean>>({});
	let editingId = $state<string | null>(null);
	let editName = $state('');

	let room = $derived(homeStore.selectedRoom);
	let devices = $derived(homeStore.selectedRoomAccessories);

	let zone = $derived(() => {
		if (!room) return '';
		const z = homeStore.zones.find(z => z.roomIds.includes(room!.roomId));
		return z?.zoneName ?? '';
	});

	function getControlValue(char: CharacteristicData): number | boolean {
		if (char.characteristicId in controlState) {
			return controlState[char.characteristicId];
		}
		// Initialise from data
		const type = char.characteristicType;
		if (type.startsWith(CHAR_TYPES.POWER_STATE) || type.startsWith(CHAR_TYPES.ACTIVE)) {
			const val = char.value === '1' || char.value === 'true';
			controlState[char.characteristicId] = val;
			return val;
		}
		const num = parseFloat(char.value ?? '0');
		controlState[char.characteristicId] = isNaN(num) ? 0 : num;
		return controlState[char.characteristicId];
	}

	function togglePower(charId: string) {
		controlState[charId] = !controlState[charId];
	}

	function setSlider(charId: string, value: number) {
		controlState[charId] = value;
	}

	function matchesType(char: CharacteristicData, typePrefix: string): boolean {
		return char.characteristicType.startsWith(typePrefix);
	}

	function startEdit(device: AccessoryData) {
		editingId = device.accessoryId;
		editName = device.name;
	}

	function commitEdit() {
		if (editingId && editName.trim()) {
			homeStore.renameAccessory(editingId, editName.trim());
		}
		editingId = null;
	}
</script>

<div class="device-panel" class:open={homeStore.panelOpen}>
	{#if room}
		<div class="panel-header">
			<div class="header-text">
				<h2 class="room-name">{room.roomName}</h2>
				<span class="room-meta">{devices.length} device{devices.length !== 1 ? 's' : ''}{zone() ? ` · ${zone()}` : ''}</span>
			</div>
			<button class="close-btn" onclick={() => homeStore.closePanel()}>
				<span class="close-circle">×</span>
			</button>
		</div>

		<div class="device-list">
			{#each devices as device (device.accessoryId)}
				{@const score = siriScore(device.name)}
				<div class="device-card">
					<div class="card-top">
						{#if editingId === device.accessoryId}
							<!-- svelte-ignore a11y_autofocus -- focus follows explicit user click on device name -->
							<input
								class="name-input"
								type="text"
								bind:value={editName}
								onblur={commitEdit}
								onkeydown={(e) => { if (e.key === 'Enter') commitEdit(); if (e.key === 'Escape') { editingId = null; } }}
								autofocus
							/>
						{:else}
							<button class="device-name-btn" onclick={() => startEdit(device)}>
								{device.name}
							</button>
						{/if}
						<span class="siri-badge {siriClass(score)}" style="color: {siriColor(score)}">{siriLabel(score)}</span>
					</div>

					{#each device.services as service}
						{#if service.isPrimary}
							<span class="service-type">{service.serviceType}</span>
						{/if}
					{/each}

					<div class="manufacturer">
						{device.manufacturer}{device.model ? ` · ${device.model}` : ''}
					</div>

					<div class="move-row">
						<span class="move-label">Room</span>
						<select
							class="room-select"
							value={device.roomId}
							onchange={(e) => homeStore.moveAccessoryToRoom(device.accessoryId, e.currentTarget.value)}
						>
							{#each homeStore.rooms as r}
								<option value={r.roomId}>{r.roomName}</option>
							{/each}
						</select>
					</div>

					<div class="controls">
						{#each device.services as service}
							{#each service.characteristics as char}
								{#if matchesType(char, CHAR_TYPES.POWER_STATE) && char.isWritable}
									{@const on = getControlValue(char)}
									<div
										class="toggle"
										class:on={on}
										onclick={() => togglePower(char.characteristicId)}
										onkeydown={(e) => { if (e.key === 'Enter' || e.key === ' ') togglePower(char.characteristicId); }}
										role="switch"
										aria-checked={!!on}
										tabindex="0"
									>
										<div class="knob"></div>
									</div>
								{:else if matchesType(char, CHAR_TYPES.BRIGHTNESS) && char.isWritable}
									{@const val = Number(getControlValue(char))}
									<div class="slider-row">
										<span class="slider-label">Brightness</span>
										<div class="slider-track">
											<div class="slider-fill" style="width: {val}%"></div>
											<input
												type="range"
												min="0"
												max="100"
												value={val}
												oninput={(e) => setSlider(char.characteristicId, Number(e.currentTarget.value))}
											/>
										</div>
										<span class="slider-value">{val}%</span>
									</div>
								{:else if matchesType(char, CHAR_TYPES.TARGET_POSITION) && char.isWritable}
									{@const val = Number(getControlValue(char))}
									<div class="slider-row">
										<span class="slider-label">Position</span>
										<div class="slider-track">
											<div class="slider-fill" style="width: {val}%"></div>
											<input
												type="range"
												min="0"
												max="100"
												value={val}
												oninput={(e) => setSlider(char.characteristicId, Number(e.currentTarget.value))}
											/>
										</div>
										<span class="slider-value">{val}%</span>
									</div>
								{:else if matchesType(char, CHAR_TYPES.TARGET_TEMPERATURE) && char.isWritable}
									{@const val = Number(getControlValue(char))}
									<div class="slider-row">
										<span class="slider-label">Temperature</span>
										<div class="slider-track">
											<div class="slider-fill" style="width: {Math.min(100, ((val - 10) / 20) * 100)}%"></div>
											<input
												type="range"
												min="10"
												max="30"
												step="0.5"
												value={val}
												oninput={(e) => setSlider(char.characteristicId, Number(e.currentTarget.value))}
											/>
										</div>
										<span class="slider-value">{val}°C</span>
									</div>
								{:else if matchesType(char, CHAR_TYPES.CURRENT_TEMPERATURE) && !char.isWritable}
									<div class="read-only-row">
										<span class="read-label">Temperature</span>
										<span class="read-value">{char.value ?? '—'}°C</span>
									</div>
								{:else if matchesType(char, CHAR_TYPES.ACTIVE) && !char.isWritable}
									<div class="read-only-row">
										<span class="read-label">Active</span>
										<span class="status-indicator" class:active={char.value === '1'}></span>
									</div>
								{/if}
							{/each}
						{/each}
					</div>
				</div>
			{/each}
		</div>
	{/if}
</div>

<style>
	.device-panel {
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

	.device-panel.open {
		transform: translateX(0);
	}

	.panel-header {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
		padding: 28px 24px 20px;
		border-bottom: 1px solid rgba(255, 255, 255, 0.06);
		flex-shrink: 0;
	}

	.header-text {
		display: flex;
		flex-direction: column;
		gap: 4px;
	}

	.room-name {
		font-family: 'Syncopate', sans-serif;
		font-size: 16px;
		font-weight: 700;
		text-transform: uppercase;
		color: var(--text-primary);
		margin: 0;
		letter-spacing: 0.04em;
	}

	.room-meta {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		color: var(--text-tertiary);
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
		border: 1px solid rgba(255, 255, 255, 0.12);
		color: var(--text-secondary);
		font-size: 18px;
		transition: border-color 0.2s, color 0.2s;
	}

	.close-circle:hover {
		border-color: var(--text-tertiary);
		color: var(--text-primary);
	}

	.device-list {
		flex: 1;
		overflow-y: auto;
		display: flex;
		flex-direction: column;
		gap: 12px;
		padding: 16px 24px;
	}

	.device-card {
		background: var(--card-bg);
		border: 1px solid var(--card-border);
		border-radius: 14px;
		padding: 16px 18px;
	}

	.card-top {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 8px;
	}

	.device-name-btn {
		font-size: 13px;
		font-weight: 500;
		color: var(--text-primary);
		background: none;
		border: none;
		padding: 0;
		cursor: pointer;
		text-align: left;
		font-family: inherit;
		transition: color 0.2s;
	}

	.device-name-btn:hover {
		color: var(--solar-amber);
	}

	.name-input {
		font-size: 13px;
		font-weight: 500;
		color: var(--text-primary);
		background: var(--card-bg);
		border: 1px solid var(--solar-amber);
		border-radius: 6px;
		padding: 2px 6px;
		outline: none;
		font-family: inherit;
		flex: 1;
		min-width: 0;
	}

	.siri-badge {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		padding: 2px 8px;
		border-radius: 8px;
		white-space: nowrap;
	}

	.siri-badge.siri-good {
		background: rgba(0, 230, 118, 0.12);
		color: #00E676;
		border: 1px solid rgba(0, 230, 118, 0.25);
	}

	.siri-badge.siri-ok {
		background: rgba(255, 215, 64, 0.12);
		color: #FFD740;
		border: 1px solid rgba(255, 215, 64, 0.25);
	}

	.siri-badge.siri-bad {
		background: rgba(255, 82, 82, 0.12);
		color: #FF5252;
		border: 1px solid rgba(255, 82, 82, 0.25);
	}

	.service-type {
		display: block;
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		text-transform: uppercase;
		color: var(--text-tertiary);
		margin-top: 4px;
	}

	.manufacturer {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		color: var(--text-muted);
		margin-top: 2px;
	}

	.controls {
		display: flex;
		flex-direction: column;
		gap: 10px;
		margin-top: 12px;
	}

	/* Toggle switch */
	.toggle {
		width: 44px;
		height: 24px;
		border-radius: 12px;
		background: rgba(255, 255, 255, 0.1);
		cursor: pointer;
		position: relative;
		transition: background 0.25s;
	}

	.toggle.on {
		background: rgba(0, 230, 118, 0.6);
	}

	.toggle .knob {
		position: absolute;
		top: 2px;
		left: 2px;
		width: 20px;
		height: 20px;
		border-radius: 50%;
		background: #fff;
		transition: transform 0.25s;
	}

	.toggle.on .knob {
		transform: translateX(20px);
	}

	/* Slider row */
	.slider-row {
		display: flex;
		align-items: center;
		gap: 10px;
	}

	.slider-label {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		color: var(--text-tertiary);
		min-width: 72px;
		text-transform: uppercase;
	}

	.slider-track {
		flex: 1;
		height: 4px;
		background: rgba(255, 255, 255, 0.08);
		border-radius: 2px;
		position: relative;
		overflow: hidden;
	}

	.slider-fill {
		position: absolute;
		top: 0;
		left: 0;
		height: 100%;
		background: rgba(255, 179, 71, 0.6);
		border-radius: 2px;
		pointer-events: none;
	}

	.slider-track input[type='range'] {
		position: absolute;
		top: -8px;
		left: 0;
		width: 100%;
		height: 20px;
		opacity: 0;
		cursor: pointer;
		margin: 0;
	}

	.slider-value {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		color: var(--text-secondary);
		min-width: 36px;
		text-align: right;
	}

	/* Read-only rows */
	.read-only-row {
		display: flex;
		align-items: center;
		justify-content: space-between;
	}

	.read-label {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		color: var(--text-tertiary);
		text-transform: uppercase;
	}

	.read-value {
		font-family: 'JetBrains Mono', monospace;
		font-size: 11px;
		color: rgba(255, 255, 255, 0.6);
	}

	.status-indicator {
		width: 8px;
		height: 8px;
		border-radius: 50%;
		background: rgba(255, 255, 255, 0.15);
	}

	.status-indicator.active {
		background: #00E676;
		box-shadow: 0 0 6px rgba(0, 230, 118, 0.4);
	}

	.move-row {
		display: flex;
		align-items: center;
		gap: 8px;
		margin-top: 8px;
		padding-top: 8px;
		border-top: 1px solid var(--card-border);
	}

	.move-label {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		color: var(--text-tertiary);
		text-transform: uppercase;
		min-width: 36px;
	}

	.room-select {
		flex: 1;
		font-family: 'DM Sans', sans-serif;
		font-size: 11px;
		padding: 5px 8px;
		border-radius: 8px;
		border: 1px solid var(--card-border);
		background: var(--card-bg);
		color: var(--text-primary);
		cursor: pointer;
		outline: none;
		appearance: none;
		-webkit-appearance: none;
		background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='8' height='5'%3E%3Cpath d='M0 0l4 5 4-5z' fill='%23888'/%3E%3C/svg%3E");
		background-repeat: no-repeat;
		background-position: right 8px center;
		padding-right: 22px;
	}

	.room-select:focus {
		border-color: var(--solar-amber);
	}
</style>
