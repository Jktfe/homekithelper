<script lang="ts">
	import { homeStore } from '$lib/stores/home.svelte';

	let jsonText = $state('');
	let error = $state('');

	function handleImport() {
		try {
			error = '';
			homeStore.loadExport(jsonText);
			homeStore.showImportModal = false;
			jsonText = '';
		} catch (e) {
			error = e instanceof Error ? e.message : 'Invalid JSON';
		}
	}

	function handleClose() {
		homeStore.showImportModal = false;
		jsonText = '';
		error = '';
	}

	function handleBackdropClick(e: MouseEvent) {
		if (e.target === e.currentTarget) handleClose();
	}
</script>

{#if homeStore.showImportModal}
	<!-- svelte-ignore a11y_click_events_have_key_events a11y_no_static_element_interactions -->
	<div class="overlay" onclick={handleBackdropClick}>
		<div class="modal">
			<h2>Import HomeKit Export</h2>
			<p class="subtitle">Paste your HomeKit Helper JSON export below</p>

			<textarea
				bind:value={jsonText}
				placeholder={'{"exportDate": "...", "homes": [...]}'}
				rows="12"
			></textarea>

			{#if error}
				<div class="error">{error}</div>
			{/if}

			<div class="actions">
				<button class="btn-ghost" onclick={handleClose}>Cancel</button>
				<button class="btn-primary" onclick={handleImport} disabled={!jsonText.trim()}>
					Import
				</button>
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
		background: rgba(15, 17, 21, 0.95);
		border: 1px solid rgba(255, 255, 255, 0.08);
		border-radius: 20px;
		padding: 28px;
		max-width: 560px;
		width: 90%;
		max-height: 80vh;
		display: flex;
		flex-direction: column;
		gap: 16px;
	}

	h2 {
		font-family: 'Syncopate', sans-serif;
		font-size: 16px;
		letter-spacing: 0.1em;
		text-transform: uppercase;
	}

	.subtitle {
		font-size: 12px;
		color: rgba(255, 255, 255, 0.4);
	}

	textarea {
		background: rgba(255, 255, 255, 0.03);
		border: 1px solid rgba(255, 255, 255, 0.08);
		border-radius: 12px;
		padding: 14px;
		color: #fff;
		font-family: 'JetBrains Mono', monospace;
		font-size: 11px;
		resize: vertical;
		outline: none;
		transition: border-color 0.2s;
	}

	textarea:focus {
		border-color: rgba(255, 179, 71, 0.3);
	}

	textarea::placeholder {
		color: rgba(255, 255, 255, 0.15);
	}

	.error {
		color: var(--siri-red);
		font-size: 12px;
		font-family: 'JetBrains Mono', monospace;
	}

	.actions {
		display: flex;
		justify-content: flex-end;
		gap: 10px;
	}

	.btn-ghost {
		padding: 10px 20px;
		border-radius: 12px;
		border: 1px solid rgba(255, 255, 255, 0.08);
		background: transparent;
		color: rgba(255, 255, 255, 0.5);
		font-size: 13px;
		cursor: pointer;
		transition: all 0.2s;
	}

	.btn-ghost:hover {
		background: rgba(255, 255, 255, 0.05);
		color: #fff;
	}

	.btn-primary {
		padding: 10px 20px;
		border-radius: 12px;
		border: none;
		background: rgba(255, 179, 71, 0.9);
		color: #0F1115;
		font-size: 13px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
	}

	.btn-primary:hover {
		background: #FFB347;
	}

	.btn-primary:disabled {
		opacity: 0.3;
		cursor: not-allowed;
	}
</style>
