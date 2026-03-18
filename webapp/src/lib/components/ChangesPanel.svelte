<script lang="ts">
	import { changeStore } from '$lib/stores/changes.svelte';

	async function copyToClipboard() {
		const json = JSON.stringify(changeStore.toJSON(), null, 2);
		await navigator.clipboard.writeText(json);
		copied = true;
		setTimeout(() => (copied = false), 2000);
	}

	function downloadJSON() {
		const json = JSON.stringify(changeStore.toJSON(), null, 2);
		const blob = new Blob([json], { type: 'application/json' });
		const url = URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = `homekit-changes-${new Date().toISOString().slice(0, 10)}.json`;
		a.click();
		URL.revokeObjectURL(url);
	}

	function saveLocal() {
		changeStore.saveToLocal();
		saved = true;
		setTimeout(() => (saved = false), 2000);
	}

	function loadLocal() {
		const ok = changeStore.loadFromLocal();
		if (!ok) {
			loadMsg = 'No saved changes';
		} else {
			loadMsg = 'Restored!';
		}
		setTimeout(() => (loadMsg = ''), 2000);
	}

	let copied = $state(false);
	let saved = $state(false);
	let loadMsg = $state('');
</script>

<div class="changes-panel" class:open={changeStore.showPanel}>
	<div class="panel-header">
		<div class="header-text">
			<h2 class="panel-title">CHANGES</h2>
			<span class="panel-meta">{changeStore.pendingCount} pending</span>
		</div>
		<button class="close-btn" onclick={() => (changeStore.showPanel = false)}>
			<span class="close-circle">&times;</span>
		</button>
	</div>

	<div class="changes-list">
		{#if changeStore.isEmpty}
			<div class="empty-state">
				<p>No pending changes</p>
				<p class="empty-hint">Rename accessories, move them between rooms, or create rooms/zones to see changes here.</p>
			</div>
		{:else}
			{#if changeStore.renames.size > 0}
				<div class="section">
					<h3 class="section-title">Renames ({changeStore.renames.size})</h3>
					{#each [...changeStore.renames.values()] as entry (entry.accessoryId)}
						{@const original = changeStore.getOriginalName(entry.accessoryId) ?? '?'}
						<div class="change-card">
							<div class="change-detail">
								<span class="change-before">{original}</span>
								<span class="change-arrow">&rarr;</span>
								<span class="change-after">{entry.newName}</span>
							</div>
							<button class="undo-btn" onclick={() => changeStore.removeRename(entry.accessoryId)}>Undo</button>
						</div>
					{/each}
				</div>
			{/if}

			{#if changeStore.roomAssignments.size > 0}
				<div class="section">
					<h3 class="section-title">Room Moves ({changeStore.roomAssignments.size})</h3>
					{#each [...changeStore.roomAssignments.values()] as entry (entry.accessoryId)}
						<div class="change-card">
							<div class="change-detail">
								<span class="change-after">{entry.accessoryId.slice(0, 8)}... &rarr; {entry.newRoomName}</span>
							</div>
							<button class="undo-btn" onclick={() => changeStore.removeRoomAssignment(entry.accessoryId)}>Undo</button>
						</div>
					{/each}
				</div>
			{/if}

			{#if changeStore.newRooms.length > 0}
				<div class="section">
					<h3 class="section-title">New Rooms ({changeStore.newRooms.length})</h3>
					{#each changeStore.newRooms as entry (entry.roomName)}
						<div class="change-card">
							<div class="change-detail">
								<span class="change-add">+ {entry.roomName}</span>
								{#if entry.zone}
									<span class="change-meta">({entry.zone})</span>
								{/if}
							</div>
							<button class="undo-btn" onclick={() => changeStore.removeNewRoom(entry.roomName)}>Undo</button>
						</div>
					{/each}
				</div>
			{/if}

			{#if changeStore.deleteRooms.length > 0}
				<div class="section">
					<h3 class="section-title">Delete Rooms ({changeStore.deleteRooms.length})</h3>
					{#each changeStore.deleteRooms as entry (entry.roomId)}
						<div class="change-card">
							<div class="change-detail">
								<span class="change-remove">- {entry.roomId}</span>
							</div>
							<button class="undo-btn" onclick={() => changeStore.removeDeleteRoom(entry.roomId)}>Undo</button>
						</div>
					{/each}
				</div>
			{/if}

			{#if changeStore.newZones.length > 0}
				<div class="section">
					<h3 class="section-title">New Zones ({changeStore.newZones.length})</h3>
					{#each changeStore.newZones as entry (entry.zoneName)}
						<div class="change-card">
							<div class="change-detail">
								<span class="change-add">+ {entry.zoneName}</span>
							</div>
							<button class="undo-btn" onclick={() => changeStore.removeNewZone(entry.zoneName)}>Undo</button>
						</div>
					{/each}
				</div>
			{/if}

			{#if changeStore.deleteZones.length > 0}
				<div class="section">
					<h3 class="section-title">Delete Zones ({changeStore.deleteZones.length})</h3>
					{#each changeStore.deleteZones as entry (entry.zoneId)}
						<div class="change-card">
							<div class="change-detail">
								<span class="change-remove">- {entry.zoneId}</span>
							</div>
							<button class="undo-btn" onclick={() => changeStore.removeDeleteZone(entry.zoneId)}>Undo</button>
						</div>
					{/each}
				</div>
			{/if}

			{#if changeStore.zoneRoomAssignments.length > 0}
				<div class="section">
					<h3 class="section-title">Zone Assignments ({changeStore.zoneRoomAssignments.length})</h3>
					{#each changeStore.zoneRoomAssignments as entry, i (entry.zoneName + entry.roomId)}
						<div class="change-card">
							<div class="change-detail">
								{#if entry.action === 'add'}
									<span class="change-add">+ {entry.roomId.slice(0, 8)}...</span>
								{:else}
									<span class="change-remove">- {entry.roomId.slice(0, 8)}...</span>
								{/if}
								<span class="change-arrow">&rarr;</span>
								<span class="change-after">{entry.zoneName}</span>
							</div>
							<button class="undo-btn" onclick={() => changeStore.removeZoneRoomAssignment(entry.zoneName, entry.roomId)}>Undo</button>
						</div>
					{/each}
				</div>
			{/if}

			{#if changeStore.newScenes.length > 0}
				<div class="section">
					<h3 class="section-title">New Scenes ({changeStore.newScenes.length})</h3>
					{#each changeStore.newScenes as entry (entry.sceneName)}
						<div class="change-card">
							<div class="change-detail">
								<span class="change-add">+ {entry.sceneName}</span>
								<span class="change-meta">({entry.actions.length} action{entry.actions.length !== 1 ? 's' : ''})</span>
							</div>
							<button class="undo-btn" onclick={() => changeStore.removeNewScene(entry.sceneName)}>Undo</button>
						</div>
					{/each}
				</div>
			{/if}

			{#if changeStore.deleteScenes.length > 0}
				<div class="section">
					<h3 class="section-title">Delete Scenes ({changeStore.deleteScenes.length})</h3>
					{#each changeStore.deleteScenes as entry (entry.sceneId)}
						<div class="change-card">
							<div class="change-detail">
								<span class="change-remove">- {entry.sceneId}</span>
							</div>
							<button class="undo-btn" onclick={() => changeStore.removeDeleteScene(entry.sceneId)}>Undo</button>
						</div>
					{/each}
				</div>
			{/if}
		{/if}
	</div>

	<div class="panel-footer">
		{#if !changeStore.isEmpty}
			<button class="btn-ghost" onclick={() => { changeStore.clear(); changeStore.clearLocal(); }}>Clear All</button>
			<button class="btn-ghost" onclick={saveLocal}>{saved ? 'Saved!' : 'Save'}</button>
			<button class="btn-ghost" onclick={downloadJSON}>Download</button>
			<button class="btn-primary" onclick={copyToClipboard}>
				{copied ? 'Copied!' : 'Copy'}
			</button>
		{:else}
			<button class="btn-ghost" onclick={loadLocal}>{loadMsg || 'Load Saved'}</button>
		{/if}
	</div>
</div>

<style>
	.changes-panel {
		position: fixed;
		top: 0;
		right: 0;
		bottom: 0;
		width: 380px;
		z-index: 250;
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

	.changes-panel.open {
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
		letter-spacing: 0.08em;
	}

	.panel-meta {
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
		border: 1px solid var(--card-border);
		color: var(--text-secondary);
		font-size: 18px;
		transition: border-color 0.2s, color 0.2s;
	}

	.close-circle:hover {
		border-color: var(--text-tertiary);
		color: var(--text-primary);
	}

	.changes-list {
		flex: 1;
		overflow-y: auto;
		display: flex;
		flex-direction: column;
		gap: 16px;
		padding: 16px 24px;
	}

	.empty-state {
		text-align: center;
		padding: 40px 20px;
		color: var(--text-tertiary);
		font-size: 13px;
	}

	.empty-hint {
		font-size: 11px;
		color: var(--text-muted);
		margin-top: 8px;
	}

	.section-title {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		text-transform: uppercase;
		color: var(--text-tertiary);
		margin: 0 0 8px;
		letter-spacing: 0.05em;
	}

	.change-card {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 8px;
		background: var(--card-bg);
		border: 1px solid var(--card-border);
		border-radius: 10px;
		padding: 10px 14px;
		margin-bottom: 6px;
	}

	.change-detail {
		display: flex;
		align-items: center;
		gap: 6px;
		font-size: 12px;
		min-width: 0;
		overflow: hidden;
	}

	.change-before {
		color: var(--text-muted);
		text-decoration: line-through;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.change-arrow {
		color: var(--text-tertiary);
		flex-shrink: 0;
	}

	.change-after {
		color: var(--text-primary);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.change-add {
		color: var(--siri-green);
		font-weight: 500;
	}

	.change-remove {
		color: var(--siri-red);
		font-weight: 500;
	}

	.change-meta {
		color: var(--text-muted);
		font-size: 10px;
	}

	.undo-btn {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		padding: 4px 10px;
		border-radius: 8px;
		border: 1px solid var(--card-border);
		background: transparent;
		color: var(--text-tertiary);
		cursor: pointer;
		transition: all 0.2s;
		white-space: nowrap;
		flex-shrink: 0;
	}

	.undo-btn:hover {
		background: var(--card-hover);
		color: var(--siri-red);
		border-color: var(--siri-red);
	}

	.panel-footer {
		display: flex;
		justify-content: flex-end;
		gap: 10px;
		padding: 16px 24px;
		border-top: 1px solid var(--card-border);
		flex-shrink: 0;
	}

	.btn-ghost {
		padding: 10px 18px;
		border-radius: 12px;
		border: 1px solid var(--card-border);
		background: transparent;
		color: var(--text-tertiary);
		font-size: 12px;
		cursor: pointer;
		transition: all 0.2s;
		font-family: 'DM Sans', sans-serif;
	}

	.btn-ghost:hover {
		background: var(--card-hover);
		color: var(--text-secondary);
	}

	.btn-primary {
		padding: 10px 18px;
		border-radius: 12px;
		border: none;
		background: rgba(255, 179, 71, 0.9);
		color: #0F1115;
		font-size: 12px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
		font-family: 'DM Sans', sans-serif;
	}

	.btn-primary:hover {
		background: #FFB347;
	}
</style>
