<script lang="ts">
	import { homeStore } from '$lib/stores/home.svelte';
	import { siriScore, siriClass, siriColor } from '$lib/utils/siri-score';

	let sortByScore = $state(true);
	let findText = $state('');
	let replaceText = $state('');
	let editValues = $state<Record<string, string>>({});

	let accessories = $derived(homeStore.accessories);

	let sorted = $derived(() => {
		const list = accessories.map(a => ({
			...a,
			editName: editValues[a.accessoryId] ?? a.name,
			score: siriScore(editValues[a.accessoryId] ?? a.name),
			originalScore: siriScore(a.name),
		}));
		if (sortByScore) {
			return list.sort((a, b) => a.score - b.score);
		}
		return list;
	});

	let changeCount = $derived(() => {
		return accessories.filter(a => {
			const edit = editValues[a.accessoryId];
			return edit !== undefined && edit !== a.name;
		}).length;
	});

	let avgScoreChange = $derived(() => {
		const items = sorted();
		if (items.length === 0) return 0;
		const totalOld = items.reduce((sum, i) => sum + siriScore(i.name), 0);
		const totalNew = items.reduce((sum, i) => sum + i.score, 0);
		return Math.round((totalNew - totalOld) / items.length);
	});

	function applyRename(accessoryId: string, newName: string) {
		editValues[accessoryId] = newName;
		homeStore.renameAccessory(accessoryId, newName);
	}

	function commitEdit(accessoryId: string) {
		const val = editValues[accessoryId];
		if (val !== undefined) {
			homeStore.renameAccessory(accessoryId, val);
		}
	}

	function stripRoomPrefixes() {
		for (const acc of accessories) {
			const room = homeStore.rooms.find(r => r.roomId === acc.roomId);
			if (room && acc.name.startsWith(room.roomName)) {
				const stripped = acc.name.slice(room.roomName.length).replace(/^[\s\-_]+/, '');
				if (stripped.length > 0) {
					editValues[acc.accessoryId] = stripped;
					homeStore.renameAccessory(acc.accessoryId, stripped);
				}
			}
		}
	}

	function removeSpecialChars() {
		for (const acc of accessories) {
			const current = editValues[acc.accessoryId] ?? acc.name;
			const cleaned = current.replace(/[^a-zA-Z0-9\s']/g, '').replace(/\s+/g, ' ').trim();
			if (cleaned !== current && cleaned.length > 0) {
				editValues[acc.accessoryId] = cleaned;
				homeStore.renameAccessory(acc.accessoryId, cleaned);
			}
		}
	}

	function findAndReplace() {
		if (!findText) return;
		for (const acc of accessories) {
			const current = editValues[acc.accessoryId] ?? acc.name;
			if (current.includes(findText)) {
				const updated = current.replaceAll(findText, replaceText);
				if (updated.length > 0) {
					editValues[acc.accessoryId] = updated;
					homeStore.renameAccessory(acc.accessoryId, updated);
				}
			}
		}
	}

	function handleClose() {
		homeStore.showBulkRename = false;
		editValues = {};
	}

	function handleBackdropClick(e: MouseEvent) {
		if (e.target === e.currentTarget) handleClose();
	}
</script>

{#if homeStore.showBulkRename}
	<!-- svelte-ignore a11y_click_events_have_key_events a11y_no_static_element_interactions -->
	<div class="overlay" role="dialog" aria-modal="true" tabindex="-1" onclick={handleBackdropClick} onkeydown={(e) => { if (e.key === 'Escape') handleClose(); }}>
		<div class="modal">
			<div class="modal-header">
				<div>
					<h2>Bulk Rename</h2>
					<span class="header-stats">{changeCount()} changes &middot; avg score {avgScoreChange() >= 0 ? '+' : ''}{avgScoreChange()}</span>
				</div>
				<button class="close-btn" onclick={handleClose}>&times;</button>
			</div>

			<div class="toolbar">
				<button class="tool-btn" onclick={stripRoomPrefixes}>Strip room prefix</button>
				<button class="tool-btn" onclick={removeSpecialChars}>Remove special chars</button>
				<div class="find-replace">
					<input type="text" placeholder="Find" bind:value={findText} class="tool-input" />
					<input type="text" placeholder="Replace" bind:value={replaceText} class="tool-input" />
					<button class="tool-btn" onclick={findAndReplace}>Apply</button>
				</div>
				<label class="sort-toggle">
					<input type="checkbox" bind:checked={sortByScore} />
					<span>Sort by worst score</span>
				</label>
			</div>

			<div class="table-wrap">
				<table>
					<thead>
						<tr>
							<th>Current Name</th>
							<th class="score-col">Score</th>
							<th>New Name</th>
							<th class="score-col">New Score</th>
						</tr>
					</thead>
					<tbody>
						{#each sorted() as item (item.accessoryId)}
							{@const newScore = siriScore(editValues[item.accessoryId] ?? item.name)}
							<tr>
								<td class="name-cell">{item.name}</td>
								<td class="score-cell">
									<span class="siri-badge {siriClass(item.originalScore)}" style="background: {siriColor(item.originalScore)}20; color: {siriColor(item.originalScore)}">
										{item.originalScore}
									</span>
								</td>
								<td class="edit-cell">
									<input
										type="text"
										class="rename-input"
										value={editValues[item.accessoryId] ?? item.name}
										oninput={(e) => { editValues[item.accessoryId] = e.currentTarget.value; }}
										onblur={() => commitEdit(item.accessoryId)}
										onkeydown={(e) => { if (e.key === 'Enter') commitEdit(item.accessoryId); }}
									/>
								</td>
								<td class="score-cell">
									<span class="siri-badge {siriClass(newScore)}" style="background: {siriColor(newScore)}20; color: {siriColor(newScore)}">
										{newScore}
									</span>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</div>
	</div>
{/if}

<style>
	.overlay {
		position: fixed;
		inset: 0;
		background: rgba(0, 0, 0, 0.6);
		backdrop-filter: blur(8px);
		-webkit-backdrop-filter: blur(8px);
		z-index: 300;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.modal {
		background: var(--panel-bg);
		border: 1px solid var(--card-border);
		border-radius: 20px;
		max-width: 900px;
		width: 95%;
		max-height: 85vh;
		display: flex;
		flex-direction: column;
		overflow: hidden;
	}

	.modal-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		padding: 24px 28px 16px;
		border-bottom: 1px solid var(--card-border);
		flex-shrink: 0;
	}

	h2 {
		font-family: 'Syncopate', sans-serif;
		font-size: 16px;
		letter-spacing: 0.1em;
		text-transform: uppercase;
		margin: 0;
		color: var(--text-primary);
	}

	.header-stats {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		color: var(--text-tertiary);
	}

	.close-btn {
		width: 32px;
		height: 32px;
		border-radius: 50%;
		border: 1px solid var(--card-border);
		background: transparent;
		color: var(--text-secondary);
		font-size: 18px;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: all 0.2s;
	}

	.close-btn:hover {
		border-color: var(--text-tertiary);
		color: var(--text-primary);
	}

	.toolbar {
		display: flex;
		gap: 8px;
		padding: 12px 28px;
		border-bottom: 1px solid var(--card-border);
		align-items: center;
		flex-wrap: wrap;
		flex-shrink: 0;
	}

	.tool-btn {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		padding: 6px 12px;
		border-radius: 8px;
		border: 1px solid var(--card-border);
		background: var(--card-bg);
		color: var(--text-tertiary);
		cursor: pointer;
		transition: all 0.2s;
		white-space: nowrap;
	}

	.tool-btn:hover {
		background: var(--card-hover);
		color: var(--text-secondary);
	}

	.tool-input {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		padding: 6px 10px;
		border-radius: 8px;
		border: 1px solid var(--card-border);
		background: var(--card-bg);
		color: var(--text-primary);
		width: 100px;
		outline: none;
	}

	.tool-input:focus {
		border-color: var(--solar-amber);
	}

	.tool-input::placeholder {
		color: var(--text-muted);
	}

	.find-replace {
		display: flex;
		gap: 4px;
		align-items: center;
	}

	.sort-toggle {
		display: flex;
		align-items: center;
		gap: 6px;
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		color: var(--text-tertiary);
		cursor: pointer;
		margin-left: auto;
	}

	.sort-toggle input {
		accent-color: var(--solar-amber);
	}

	.table-wrap {
		flex: 1;
		overflow-y: auto;
		padding: 0 28px 20px;
	}

	table {
		width: 100%;
		border-collapse: collapse;
	}

	th {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		text-transform: uppercase;
		color: var(--text-tertiary);
		text-align: left;
		padding: 12px 8px 8px;
		position: sticky;
		top: 0;
		background: var(--panel-bg);
		letter-spacing: 0.05em;
	}

	td {
		padding: 6px 8px;
		border-top: 1px solid var(--card-border);
		vertical-align: middle;
	}

	.name-cell {
		font-size: 12px;
		color: var(--text-secondary);
		max-width: 200px;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.score-col {
		width: 60px;
		text-align: center;
	}

	.score-cell {
		text-align: center;
	}

	.siri-badge {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		padding: 2px 8px;
		border-radius: 6px;
		display: inline-block;
	}

	.edit-cell {
		min-width: 200px;
	}

	.rename-input {
		width: 100%;
		font-family: 'DM Sans', sans-serif;
		font-size: 12px;
		padding: 6px 10px;
		border-radius: 8px;
		border: 1px solid var(--card-border);
		background: var(--card-bg);
		color: var(--text-primary);
		outline: none;
		transition: border-color 0.2s;
	}

	.rename-input:focus {
		border-color: var(--solar-amber);
	}
</style>
