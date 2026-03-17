<script lang="ts">
	import { homeStore } from '$lib/stores/home.svelte';
	import { siriScore, siriColor } from '$lib/utils/siri-score';
	import { browser } from '$app/environment';
	import type { AccessoryData } from '$lib/types/homekit';
	import { SERVICE_TYPES } from '$lib/types/homekit';

	const LAYOUT_KEY = 'hkh-room-layouts';

	// Accessory positions within a room (relative 0-1 coordinates)
	let layouts = $state<Record<string, Record<string, { x: number; y: number }>>>(loadLayouts());

	function loadLayouts() {
		if (browser) {
			try {
				const saved = localStorage.getItem(LAYOUT_KEY);
				if (saved) return JSON.parse(saved);
			} catch {}
		}
		return {};
	}

	function saveLayouts() {
		if (browser) {
			localStorage.setItem(LAYOUT_KEY, JSON.stringify(layouts));
		}
	}

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

	// Get or generate positions for accessories in this room
	function getAccPos(accId: string, index: number, total: number): { x: number; y: number } {
		const roomId = homeStore.designerRoomId;
		if (roomId && layouts[roomId]?.[accId]) {
			return layouts[roomId][accId];
		}
		// Default: spread in a circle
		const angle = (2 * Math.PI / Math.max(total, 1)) * index - Math.PI / 2;
		const radius = 0.28;
		return {
			x: 0.5 + Math.cos(angle) * radius,
			y: 0.5 + Math.sin(angle) * radius + 0.02,
		};
	}

	// Drag state
	let dragAccId = $state<string | null>(null);
	let dragStartX = $state(0);
	let dragStartY = $state(0);
	let dragOrigX = $state(0);
	let dragOrigY = $state(0);

	let designerEl: HTMLDivElement;

	function toRelative(clientX: number, clientY: number): { x: number; y: number } {
		if (!designerEl) return { x: 0.5, y: 0.5 };
		const rect = designerEl.getBoundingClientRect();
		return {
			x: Math.max(0.05, Math.min(0.95, (clientX - rect.left) / rect.width)),
			y: Math.max(0.05, Math.min(0.95, (clientY - rect.top) / rect.height)),
		};
	}

	function startDrag(accId: string, e: MouseEvent) {
		e.preventDefault();
		e.stopPropagation();
		const pos = getAccPos(accId, 0, 0);
		dragAccId = accId;
		dragStartX = e.clientX;
		dragStartY = e.clientY;
		dragOrigX = pos.x;
		dragOrigY = pos.y;
	}

	function onMove(e: MouseEvent) {
		if (!dragAccId || !designerEl) return;
		const rect = designerEl.getBoundingClientRect();
		const dx = (e.clientX - dragStartX) / rect.width;
		const dy = (e.clientY - dragStartY) / rect.height;
		const newX = Math.max(0.05, Math.min(0.95, dragOrigX + dx));
		const newY = Math.max(0.05, Math.min(0.95, dragOrigY + dy));

		const roomId = homeStore.designerRoomId;
		if (roomId) {
			if (!layouts[roomId]) layouts[roomId] = {};
			layouts[roomId][dragAccId] = { x: newX, y: newY };
		}
	}

	function endDrag() {
		if (dragAccId) {
			saveLayouts();
			dragAccId = null;
		}
	}

	function getDeviceIcon(acc: AccessoryData): string {
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

		<div class="designer-canvas" bind:this={designerEl}>
			<!-- Room boundary (rounded rectangle) -->
			<div class="room-boundary"></div>

			<!-- Grid dots for visual reference -->
			{#each Array(5) as _, row}
				{#each Array(7) as _, col}
					<div
						class="grid-dot"
						style="left: {(col + 1) * 12.5}%; top: {(row + 1) * 16.66}%;"
					></div>
				{/each}
			{/each}

			<!-- Accessories -->
			{#each accessories as acc, i}
				{@const pos = getAccPos(acc.accessoryId, i, accessories.length)}
				{@const score = siriScore(acc.name)}
				{@const sColor = siriColor(score)}
				{@const on = isOn(acc)}
				{@const icon = getDeviceIcon(acc)}
				<!-- svelte-ignore a11y_no_static_element_interactions -->
				<div
					class="acc-node"
					class:on
					class:dragging={dragAccId === acc.accessoryId}
					style="left: {pos.x * 100}%; top: {pos.y * 100}%; --acc-color: {sColor};"
					onmousedown={(e) => startDrag(acc.accessoryId, e)}
				>
					<div class="acc-icon">{icon}</div>
					<div class="acc-ring" style="border-color: {sColor};"></div>
					{#if on}
						<div class="acc-glow"></div>
					{/if}
					<div class="acc-label">{acc.name}</div>
					<div class="acc-score" style="color: {sColor};">{score}</div>
				</div>
			{/each}
		</div>

		<div class="designer-footer">
			<p class="hint">Drag accessories to arrange them in the room</p>
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

	.designer-canvas {
		flex: 1;
		position: relative;
		margin: 24px;
		overflow: hidden;
	}

	.room-boundary {
		position: absolute;
		inset: 5%;
		border: 2px dashed var(--card-border);
		border-radius: 24px;
		pointer-events: none;
	}

	.grid-dot {
		position: absolute;
		width: 3px;
		height: 3px;
		border-radius: 50%;
		background: var(--card-border);
		transform: translate(-50%, -50%);
		pointer-events: none;
	}

	.acc-node {
		position: absolute;
		transform: translate(-50%, -50%);
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 4px;
		cursor: grab;
		user-select: none;
		transition: transform 0.05s ease;
		z-index: 1;
	}

	.acc-node:hover {
		z-index: 10;
	}

	.acc-node.dragging {
		cursor: grabbing;
		z-index: 20;
		transform: translate(-50%, -50%) scale(1.1);
	}

	.acc-icon {
		width: 48px;
		height: 48px;
		border-radius: 50%;
		background: var(--card-bg);
		border: 2px solid var(--card-border);
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 20px;
		transition: all 0.2s;
		position: relative;
		z-index: 2;
	}

	.acc-node:hover .acc-icon {
		border-color: var(--text-tertiary);
	}

	.acc-node.on .acc-icon {
		border-color: var(--acc-color, var(--solar-amber));
		background: color-mix(in srgb, var(--acc-color, var(--solar-amber)), transparent 92%);
	}

	.acc-ring {
		position: absolute;
		top: 0;
		left: 50%;
		transform: translateX(-50%);
		width: 56px;
		height: 56px;
		border-radius: 50%;
		border: 1.5px solid transparent;
		pointer-events: none;
		transition: border-color 0.3s;
	}

	.acc-node:hover .acc-ring {
		border-color: var(--acc-color, var(--text-muted));
		opacity: 0.4;
	}

	.acc-glow {
		position: absolute;
		top: 0;
		left: 50%;
		transform: translateX(-50%);
		width: 64px;
		height: 64px;
		border-radius: 50%;
		background: var(--acc-color, var(--solar-amber));
		opacity: 0.06;
		filter: blur(12px);
		pointer-events: none;
	}

	.acc-label {
		font-family: 'DM Sans', sans-serif;
		font-size: 10px;
		font-weight: 500;
		color: var(--text-secondary);
		text-align: center;
		max-width: 80px;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.acc-score {
		font-family: 'JetBrains Mono', monospace;
		font-size: 8px;
		font-weight: 500;
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
