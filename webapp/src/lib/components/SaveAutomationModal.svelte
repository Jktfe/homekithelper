<script lang="ts">
	import { pathStore } from '$lib/stores/paths.svelte';

	let selectedOption = $state<'path' | 'time' | 'both'>('both');

	let path = $derived(pathStore.currentPath);
	let subtitle = $derived(
		path ? `${path.userName} — ${path.waypoints.length} rooms` : ''
	);

	function handleBackdropClick(e: MouseEvent) {
		if (e.target === e.currentTarget) {
			pathStore.closeSaveModal();
		}
	}

	function handleCreate() {
		// v1: just close the modal
		pathStore.closeSaveModal();
	}
</script>

{#if pathStore.showSaveModal}
	<!-- svelte-ignore a11y_click_events_have_key_events -->
	<!-- svelte-ignore a11y_no_static_element_interactions -->
	<div class="overlay" onclick={handleBackdropClick}>
		<div class="modal">
			<h2 class="title">Create Automation</h2>
			<p class="subtitle">{subtitle}</p>

			<div class="options">
				<button
					class="option-pill"
					class:selected={selectedOption === 'path'}
					onclick={() => (selectedOption = 'path')}
				>
					Path-based
				</button>
				<button
					class="option-pill"
					class:selected={selectedOption === 'time'}
					onclick={() => (selectedOption = 'time')}
				>
					Time-based
				</button>
				<button
					class="option-pill"
					class:selected={selectedOption === 'both'}
					onclick={() => (selectedOption = 'both')}
				>
					Both
				</button>
			</div>

			<div class="actions">
				<button class="btn-ghost" onclick={() => pathStore.closeSaveModal()}>
					Cancel
				</button>
				<button class="btn-primary" onclick={handleCreate}>
					Create Automation
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
		max-width: 480px;
		width: 90%;
		background: var(--panel-bg);
		border: 1px solid var(--card-border);
		border-radius: 20px;
		padding: 28px;
	}

	.title {
		font-family: 'Syncopate', sans-serif;
		font-size: 16px;
		font-weight: 700;
		color: var(--text-primary);
		margin: 0 0 6px 0;
		text-transform: uppercase;
	}

	.subtitle {
		font-family: 'DM Sans', sans-serif;
		font-size: 12px;
		color: var(--text-tertiary);
		margin: 0 0 24px 0;
	}

	.options {
		display: flex;
		gap: 8px;
		margin-bottom: 28px;
	}

	.option-pill {
		flex: 1;
		padding: 10px 14px;
		border-radius: 12px;
		border: 1px solid var(--card-border);
		background: var(--card-bg);
		color: var(--text-secondary);
		font-family: 'DM Sans', sans-serif;
		font-size: 12px;
		font-weight: 500;
		cursor: pointer;
		transition: all 0.2s ease;
	}

	.option-pill:hover {
		background: var(--card-hover);
		border-color: rgba(255, 255, 255, 0.12);
	}

	.option-pill.selected {
		background: rgba(255, 179, 71, 0.15);
		border-color: rgba(255, 179, 71, 0.4);
		color: var(--solar-amber);
	}

	.actions {
		display: flex;
		justify-content: flex-end;
		gap: 10px;
	}

	.btn-ghost {
		padding: 10px 18px;
		border-radius: 10px;
		border: 1px solid var(--card-border);
		background: transparent;
		color: var(--text-secondary);
		font-family: 'DM Sans', sans-serif;
		font-size: 12px;
		font-weight: 500;
		cursor: pointer;
		transition: all 0.15s ease;
	}

	.btn-ghost:hover {
		background: var(--card-border);
		color: var(--text-secondary);
	}

	.btn-primary {
		padding: 10px 18px;
		border-radius: 10px;
		border: none;
		background: var(--solar-amber);
		color: var(--surface);
		font-family: 'DM Sans', sans-serif;
		font-size: 12px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.15s ease;
	}

	.btn-primary:hover {
		background: #ffc46b;
	}
</style>
