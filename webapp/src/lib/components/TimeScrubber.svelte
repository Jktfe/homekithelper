<script lang="ts">
	import { pathStore } from '$lib/stores/paths.svelte';

	let formattedTime = $derived(() => {
		const hours = Math.floor(pathStore.timeValue);
		const mins = (pathStore.timeValue % 1) * 60;
		return `${String(hours).padStart(2, '0')}:${String(mins).padStart(2, '0')}`;
	});
</script>

{#if pathStore.pathModeActive}
	<div class="time-scrubber">
		<span class="label">TIME</span>
		<input
			type="range"
			min="6"
			max="22"
			step="0.5"
			value={pathStore.timeValue}
			oninput={(e) => { pathStore.timeValue = parseFloat(e.currentTarget.value); }}
			class="slider"
		/>
		<span class="time-display">{formattedTime()}</span>
	</div>
{/if}

<style>
	.time-scrubber {
		position: fixed;
		bottom: 60px;
		left: 50%;
		transform: translateX(-50%);
		z-index: 160;
		display: flex;
		align-items: center;
		gap: 12px;
		padding: 10px 20px;
		border-radius: 20px;
		background: var(--panel-bg);
		backdrop-filter: blur(20px);
		-webkit-backdrop-filter: blur(20px);
		border: 1px solid var(--card-border);
		width: 300px;
	}

	.label {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		text-transform: uppercase;
		color: var(--text-tertiary);
		letter-spacing: 0.08em;
		flex-shrink: 0;
	}

	.time-display {
		font-family: 'JetBrains Mono', monospace;
		font-size: 12px;
		color: var(--text-secondary);
		flex-shrink: 0;
		min-width: 40px;
		text-align: right;
	}

	.slider {
		flex: 1;
		-webkit-appearance: none;
		appearance: none;
		height: 4px;
		border-radius: 2px;
		background: var(--glass-border);
		outline: none;
	}

	.slider::-webkit-slider-thumb {
		-webkit-appearance: none;
		appearance: none;
		width: 14px;
		height: 14px;
		border-radius: 50%;
		background: var(--text-secondary);
		border: 2px solid var(--text-muted);
		cursor: pointer;
		transition: background 0.15s ease;
	}

	.slider::-webkit-slider-thumb:hover {
		background: var(--text-primary);
	}

	.slider::-moz-range-thumb {
		width: 14px;
		height: 14px;
		border-radius: 50%;
		background: var(--text-secondary);
		border: 2px solid var(--text-muted);
		cursor: pointer;
	}
</style>
