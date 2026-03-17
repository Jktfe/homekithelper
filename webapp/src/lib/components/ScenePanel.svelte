<script lang="ts">
	import { homeStore } from '$lib/stores/home.svelte';
	import { CHAR_TYPES } from '$lib/types/homekit';
	import type { SceneAction } from '$lib/types/changeset';

	let showCreate = $state(false);
	let newSceneName = $state('');
	let actions = $state<SceneAction[]>([]);

	// Action builder state
	let selectedAccessoryId = $state('');
	let selectedCharType = $state('');
	let targetValue = $state<string>('');

	let scenes = $derived(homeStore.scenes);
	let accessories = $derived(homeStore.accessories);

	// Writable characteristics for selected accessory
	let writableChars = $derived(() => {
		if (!selectedAccessoryId) return [];
		const acc = accessories.find(a => a.accessoryId === selectedAccessoryId);
		if (!acc) return [];
		const chars: { charType: string; label: string; serviceType: string }[] = [];
		for (const svc of acc.services) {
			for (const ch of svc.characteristics) {
				if (!ch.isWritable) continue;
				const label = getCharLabel(ch.characteristicType);
				if (label) {
					chars.push({
						charType: ch.characteristicType,
						label,
						serviceType: svc.serviceType,
					});
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

	function addAction() {
		if (!selectedAccessoryId || !selectedCharType || !targetValue) return;
		const charInfo = writableChars().find(c => c.charType === selectedCharType);
		if (!charInfo) return;

		let parsed: boolean | number | string = targetValue;
		if (targetValue === 'true' || targetValue === 'false') {
			parsed = targetValue === 'true';
		} else if (!isNaN(Number(targetValue))) {
			parsed = Number(targetValue);
		}

		actions = [...actions, {
			accessoryId: selectedAccessoryId,
			serviceType: charInfo.serviceType,
			characteristicType: selectedCharType,
			targetValue: parsed,
		}];

		// Reset for next action
		selectedCharType = '';
		targetValue = '';
	}

	function removeAction(index: number) {
		actions = actions.filter((_, i) => i !== index);
	}

	function createScene() {
		const name = newSceneName.trim();
		if (!name || actions.length === 0) return;
		homeStore.createScene(name, actions);
		resetCreate();
	}

	function resetCreate() {
		showCreate = false;
		newSceneName = '';
		actions = [];
		selectedAccessoryId = '';
		selectedCharType = '';
		targetValue = '';
	}

	function getAccessoryName(id: string): string {
		return accessories.find(a => a.accessoryId === id)?.name ?? id.slice(0, 8);
	}

	function handleClose() {
		homeStore.showScenePanel = false;
		resetCreate();
	}

	function handleBackdropClick(e: MouseEvent) {
		if (e.target === e.currentTarget) handleClose();
	}
</script>

{#if homeStore.showScenePanel}
	<!-- svelte-ignore a11y_click_events_have_key_events a11y_no_static_element_interactions -->
	<div class="overlay" role="dialog" aria-modal="true" tabindex="-1" onclick={handleBackdropClick} onkeydown={(e) => { if (e.key === 'Escape') handleClose(); }}>
		<div class="modal">
			<div class="modal-header">
				<div>
					<h2>Scenes</h2>
					<span class="header-meta">{scenes.length} scene{scenes.length !== 1 ? 's' : ''}</span>
				</div>
				<button class="close-btn" onclick={handleClose}>&times;</button>
			</div>

			<div class="scene-body">
				<!-- Existing scenes list -->
				<div class="scene-list">
					{#each scenes as scene (scene.sceneId)}
						<div class="scene-card">
							<div class="scene-info">
								<span class="scene-name">{scene.sceneName}</span>
								<span class="scene-meta">{scene.actionCount} action{scene.actionCount !== 1 ? 's' : ''}</span>
							</div>
							<button
								class="delete-scene-btn"
								onclick={() => homeStore.deleteScene(scene.sceneId)}
								title="Delete scene"
							>&times;</button>
						</div>
					{/each}

					{#if scenes.length === 0}
						<p class="empty-hint">No scenes configured</p>
					{/if}
				</div>

				<!-- Create scene form -->
				{#if showCreate}
					<div class="create-section">
						<h3 class="section-title">New Scene</h3>

						<input
							type="text"
							class="scene-name-input"
							placeholder="Scene name"
							bind:value={newSceneName}
						/>

						<!-- Action list -->
						{#if actions.length > 0}
							<div class="action-list">
								{#each actions as action, i}
									<div class="action-card">
										<span class="action-detail">
											{getAccessoryName(action.accessoryId)} &middot; {getCharLabel(action.characteristicType) ?? '?'} &rarr; {String(action.targetValue)}
										</span>
										<button class="action-remove" onclick={() => removeAction(i)}>&times;</button>
									</div>
								{/each}
							</div>
						{/if}

						<!-- Action builder -->
						<div class="action-builder">
							<select class="builder-select" bind:value={selectedAccessoryId}>
								<option value="">Select accessory</option>
								{#each accessories as acc}
									<option value={acc.accessoryId}>{acc.name}</option>
								{/each}
							</select>

							{#if selectedAccessoryId}
								<select class="builder-select" bind:value={selectedCharType}>
									<option value="">Select property</option>
									{#each writableChars() as ch}
										<option value={ch.charType}>{ch.label}</option>
									{/each}
								</select>
							{/if}

							{#if selectedCharType}
								{@const charInfo = writableChars().find(c => c.charType === selectedCharType)}
								{#if charInfo && (charInfo.label === 'Power' || charInfo.label === 'Active')}
									<select class="builder-select" bind:value={targetValue}>
										<option value="">Select value</option>
										<option value="true">On</option>
										<option value="false">Off</option>
									</select>
								{:else}
									<input
										type="number"
										class="builder-input"
										placeholder="Value"
										bind:value={targetValue}
									/>
								{/if}

								<button class="add-action-btn" onclick={addAction} disabled={!targetValue}>+</button>
							{/if}
						</div>

						<div class="create-actions">
							<button class="btn-ghost" onclick={resetCreate}>Cancel</button>
							<button
								class="btn-primary"
								onclick={createScene}
								disabled={!newSceneName.trim() || actions.length === 0}
							>
								Create Scene ({actions.length} action{actions.length !== 1 ? 's' : ''})
							</button>
						</div>
					</div>
				{:else}
					<button class="new-scene-btn" onclick={() => (showCreate = true)}>
						+ New Scene
					</button>
				{/if}
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
		max-width: 600px;
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

	.header-meta {
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

	.scene-body {
		flex: 1;
		overflow-y: auto;
		padding: 20px 28px;
		display: flex;
		flex-direction: column;
		gap: 16px;
	}

	.scene-list {
		display: flex;
		flex-direction: column;
		gap: 8px;
	}

	.scene-card {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 12px 16px;
		background: var(--card-bg);
		border: 1px solid var(--card-border);
		border-radius: 12px;
	}

	.scene-info {
		display: flex;
		flex-direction: column;
		gap: 2px;
	}

	.scene-name {
		font-size: 13px;
		font-weight: 500;
		color: var(--text-primary);
	}

	.scene-meta {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		color: var(--text-muted);
	}

	.delete-scene-btn {
		width: 28px;
		height: 28px;
		border-radius: 50%;
		border: 1px solid transparent;
		background: none;
		color: var(--text-muted);
		font-size: 16px;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: all 0.2s;
		opacity: 0;
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
		font-size: 10px;
		color: var(--text-muted);
		text-align: center;
		padding: 12px 0;
	}

	.new-scene-btn {
		padding: 14px;
		border-radius: 14px;
		border: 1px dashed var(--solar-amber);
		background: color-mix(in srgb, var(--solar-amber), transparent 94%);
		color: var(--solar-amber);
		font-family: 'DM Sans', sans-serif;
		font-size: 13px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
		text-align: center;
	}

	.new-scene-btn:hover {
		background: color-mix(in srgb, var(--solar-amber), transparent 88%);
	}

	.create-section {
		display: flex;
		flex-direction: column;
		gap: 12px;
		padding: 16px;
		background: var(--card-bg);
		border: 1px solid var(--card-border);
		border-radius: 14px;
	}

	.section-title {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		text-transform: uppercase;
		color: var(--text-tertiary);
		margin: 0;
		letter-spacing: 0.05em;
	}

	h3 { margin: 0; }

	.scene-name-input {
		font-family: 'DM Sans', sans-serif;
		font-size: 14px;
		padding: 10px 14px;
		border-radius: 10px;
		border: 1px solid var(--card-border);
		background: var(--card-bg);
		color: var(--text-primary);
		outline: none;
	}

	.scene-name-input:focus {
		border-color: var(--solar-amber);
	}

	.scene-name-input::placeholder {
		color: var(--text-muted);
	}

	.action-list {
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	.action-card {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 8px 12px;
		background: color-mix(in srgb, var(--solar-amber), transparent 94%);
		border: 1px solid color-mix(in srgb, var(--solar-amber), transparent 80%);
		border-radius: 8px;
	}

	.action-detail {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		color: var(--text-secondary);
	}

	.action-remove {
		width: 20px;
		height: 20px;
		border-radius: 50%;
		border: none;
		background: none;
		color: var(--text-muted);
		font-size: 14px;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.action-remove:hover {
		color: var(--siri-red);
	}

	.action-builder {
		display: flex;
		gap: 6px;
		flex-wrap: wrap;
		align-items: center;
	}

	.builder-select {
		font-family: 'DM Sans', sans-serif;
		font-size: 11px;
		padding: 6px 10px;
		border-radius: 8px;
		border: 1px solid var(--card-border);
		background: var(--card-bg);
		color: var(--text-primary);
		outline: none;
		cursor: pointer;
		flex: 1;
		min-width: 120px;
		appearance: none;
		-webkit-appearance: none;
		background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='8' height='5'%3E%3Cpath d='M0 0l4 5 4-5z' fill='%23888'/%3E%3C/svg%3E");
		background-repeat: no-repeat;
		background-position: right 8px center;
		padding-right: 22px;
	}

	.builder-select:focus {
		border-color: var(--solar-amber);
	}

	.builder-input {
		font-family: 'JetBrains Mono', monospace;
		font-size: 11px;
		padding: 6px 10px;
		border-radius: 8px;
		border: 1px solid var(--card-border);
		background: var(--card-bg);
		color: var(--text-primary);
		outline: none;
		width: 80px;
	}

	.builder-input:focus {
		border-color: var(--solar-amber);
	}

	.add-action-btn {
		width: 32px;
		height: 32px;
		border-radius: 8px;
		border: 1px solid var(--solar-amber);
		background: color-mix(in srgb, var(--solar-amber), transparent 90%);
		color: var(--solar-amber);
		font-size: 16px;
		font-weight: 700;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		flex-shrink: 0;
	}

	.add-action-btn:hover {
		background: color-mix(in srgb, var(--solar-amber), transparent 80%);
	}

	.add-action-btn:disabled {
		opacity: 0.3;
		cursor: not-allowed;
	}

	.create-actions {
		display: flex;
		justify-content: flex-end;
		gap: 8px;
		margin-top: 4px;
	}

	.btn-ghost {
		padding: 8px 16px;
		border-radius: 10px;
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
		padding: 8px 16px;
		border-radius: 10px;
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

	.btn-primary:disabled {
		opacity: 0.3;
		cursor: not-allowed;
	}
</style>
