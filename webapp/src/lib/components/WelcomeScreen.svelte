<script lang="ts">
	import { homeStore } from '$lib/stores/home.svelte';
</script>

<div class="welcome-backdrop">
	<div class="welcome-card glass">
		<h1 class="welcome-title">HOMEKIT HELPER</h1>
		<p class="welcome-desc">Visualise, rename, and reorganise your HomeKit accessories. Import your data to get started.</p>

		<div class="welcome-actions">
			<button class="btn-primary" onclick={() => (homeStore.showImportModal = true)}>
				Import HomeKit Data
			</button>
			<button class="btn-ghost" onclick={() => homeStore.loadSampleData()}>
				Load Demo
			</button>
		</div>
	</div>
</div>

<style>
	.welcome-backdrop {
		position: fixed;
		inset: 0;
		display: flex;
		align-items: center;
		justify-content: center;
		background: var(--surface);
		z-index: 50;
	}

	.welcome-card {
		max-width: 440px;
		width: 90%;
		padding: 40px 36px;
		border-radius: 24px;
		text-align: center;
		display: flex;
		flex-direction: column;
		gap: 20px;
	}

	.welcome-title {
		font-family: 'Syncopate', sans-serif;
		font-size: 20px;
		letter-spacing: 0.15em;
		text-transform: uppercase;
		color: var(--text-primary);
		margin: 0;
		font-weight: 700;
	}

	.welcome-desc {
		font-family: 'DM Sans', sans-serif;
		font-size: 13px;
		color: var(--text-tertiary);
		line-height: 1.6;
		margin: 0;
	}

	.welcome-actions {
		display: flex;
		flex-direction: column;
		gap: 10px;
		margin-top: 8px;
	}

	.btn-primary {
		padding: 12px 24px;
		border-radius: 14px;
		border: none;
		background: rgba(255, 179, 71, 0.9);
		color: #0F1115;
		font-size: 13px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
		font-family: 'DM Sans', sans-serif;
	}

	.btn-primary:hover {
		background: #FFB347;
	}

	.btn-ghost {
		padding: 12px 24px;
		border-radius: 14px;
		border: 1px solid var(--card-border);
		background: transparent;
		color: var(--text-tertiary);
		font-size: 13px;
		cursor: pointer;
		transition: all 0.2s;
		font-family: 'DM Sans', sans-serif;
	}

	.btn-ghost:hover {
		background: var(--card-hover);
		color: var(--text-secondary);
	}
</style>
