<script lang="ts">
	import { getTimeContext, intentMap } from '$lib/utils/time-context';

	let open = $state(false);
	let timeCtx = $state(getTimeContext());

	let intents = $derived(intentMap[timeCtx.period] ?? []);

	$effect(() => {
		const interval = setInterval(() => {
			timeCtx = getTimeContext();
		}, 60_000);

		return () => clearInterval(interval);
	});

	function toggleDrawer() {
		open = !open;
	}
</script>

<div class="intent-drawer" class:open>
	<div
		class="handle-bar"
		onclick={toggleDrawer}
		onkeydown={(e) => { if (e.key === 'Enter' || e.key === ' ') toggleDrawer(); }}
		role="button"
		tabindex="0"
		aria-label="Toggle scene suggestions"
	>
		<div class="bar"></div>
	</div>

	<div class="drawer-body">
		<span class="time-label">{timeCtx.label}</span>

		<div class="intent-pills">
			{#each intents as intent (intent.name)}
				<button
					class="pill"
					class:primary={intent.primary}
					onclick={() => {/* local only */}}
				>
					<span class="pill-icon">{intent.icon}</span>
					<span class="pill-name">{intent.name}</span>
				</button>
			{/each}
		</div>
	</div>
</div>

<style>
	.intent-drawer {
		position: fixed;
		bottom: 0;
		left: 0;
		right: 0;
		z-index: 150;
		transform: translateY(calc(100% - 48px));
		transition: transform 0.5s cubic-bezier(0.23, 1, 0.32, 1);
	}

	.intent-drawer.open {
		transform: translateY(0);
	}

	.handle-bar {
		height: 48px;
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		background: var(--panel-bg);
		backdrop-filter: blur(40px);
		-webkit-backdrop-filter: blur(40px);
		border-top: 1px solid var(--card-border);
	}

	.bar {
		width: 40px;
		height: 4px;
		border-radius: 2px;
		background: var(--text-muted);
	}

	.drawer-body {
		background: var(--panel-bg);
		backdrop-filter: blur(40px);
		-webkit-backdrop-filter: blur(40px);
		border-top: 1px solid var(--card-border);
		padding: 20px 24px 32px;
	}

	.time-label {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		text-transform: uppercase;
		color: var(--text-tertiary);
		letter-spacing: 0.06em;
	}

	.intent-pills {
		display: flex;
		flex-wrap: wrap;
		gap: 10px;
		margin-top: 16px;
	}

	.pill {
		padding: 10px 18px;
		border-radius: 20px;
		background: var(--card-bg);
		border: 1px solid var(--card-border);
		color: var(--text-secondary);
		font-size: 12px;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 6px;
		transition: background 0.2s, border-color 0.2s;
	}

	.pill:hover {
		background: var(--card-hover);
		border-color: rgba(255, 255, 255, 0.15);
	}

	.pill.primary {
		background: rgba(255, 179, 71, 0.12);
		border-color: rgba(255, 179, 71, 0.3);
		color: rgb(255, 179, 71);
	}

	.pill.primary:hover {
		background: rgba(255, 179, 71, 0.2);
		border-color: rgba(255, 179, 71, 0.45);
	}

	.pill-icon {
		font-size: 14px;
	}

	.pill-name {
		font-weight: 500;
	}
</style>
