<script lang="ts">
	import { homeStore } from '$lib/stores/home.svelte';
	import { pathStore } from '$lib/stores/paths.svelte';
	import { themeStore } from '$lib/stores/theme.svelte';

	const buildings = ['Building 1', 'Building 2', 'Outdoors'];
	let selectedBuilding = $state(0);

	let now = $state(new Date());

	$effect(() => {
		const interval = setInterval(() => {
			now = new Date();
		}, 30_000);
		return () => clearInterval(interval);
	});

	let clock = $derived(
		now.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', hour12: false })
	);

	let homeName = $derived(homeStore.home?.homeName ?? 'Home');
	let roomCount = $derived(homeStore.roomCount);
	let deviceCount = $derived(homeStore.deviceCount);
</script>

<header class="topbar">
	<div class="left">
		<h1 class="title">HOMEKIT HELPER</h1>
		<p class="subtitle">{homeName} &middot; {roomCount} Rooms &middot; {deviceCount} Devices</p>
	</div>

	<div class="centre">
		{#each buildings as bld, i}
			<button
				class="glass-btn"
				class:active={selectedBuilding === i}
				onclick={() => (selectedBuilding = i)}
			>
				{bld}
			</button>
		{/each}
	</div>

	<div class="right">
		<button class="glass-btn" onclick={() => (homeStore.showImportModal = true)}>
			Import
		</button>
		<button
			class="glass-btn"
			class:active={pathStore.pathModeActive}
			onclick={() => pathStore.togglePathMode()}
		>
			Paths
		</button>
		<button
			class="theme-btn"
			onclick={() => themeStore.toggle()}
			title={themeStore.isDark ? 'Switch to light mode' : 'Switch to dark mode'}
		>
			{themeStore.isDark ? '☀️' : '🌙'}
		</button>
		<span class="clock">{clock}</span>
	</div>
</header>

<style>
	.topbar {
		position: fixed;
		top: 0;
		left: 0;
		right: 0;
		z-index: 100;
		display: flex;
		flex-direction: row;
		justify-content: space-between;
		align-items: center;
		padding: 24px 32px;
		background: linear-gradient(180deg, var(--surface) 0%, transparent 100%);
		pointer-events: none;
	}

	.left,
	.centre,
	.right {
		pointer-events: auto;
	}

	.left {
		display: flex;
		flex-direction: column;
		gap: 4px;
	}

	.title {
		font-family: 'Syncopate', sans-serif;
		font-size: 14px;
		letter-spacing: 0.15em;
		text-transform: uppercase;
		color: var(--text-secondary);
		margin: 0;
		font-weight: 400;
	}

	.subtitle {
		font-family: 'DM Sans', sans-serif;
		font-size: 11px;
		font-weight: 300;
		color: var(--text-tertiary);
		letter-spacing: 0.05em;
		margin: 0;
	}

	.centre {
		display: flex;
		gap: 6px;
	}

	.glass-btn {
		font-family: 'DM Sans', sans-serif;
		font-size: 11px;
		padding: 6px 14px;
		border-radius: 20px;
		border: 1px solid var(--card-border);
		background: var(--card-bg);
		color: var(--text-tertiary);
		cursor: pointer;
		transition: all 0.25s ease;
	}

	.glass-btn:hover {
		background: var(--card-hover);
		color: var(--text-secondary);
	}

	.glass-btn.active {
		border-color: color-mix(in srgb, var(--solar-amber), transparent 60%);
		background: color-mix(in srgb, var(--solar-amber), transparent 90%);
		color: var(--solar-amber);
	}

	.theme-btn {
		width: 32px;
		height: 32px;
		border-radius: 50%;
		border: 1px solid var(--card-border);
		background: var(--card-bg);
		font-size: 14px;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: all 0.25s ease;
		line-height: 1;
	}

	.theme-btn:hover {
		background: var(--card-hover);
	}

	.right {
		display: flex;
		align-items: center;
		gap: 8px;
	}

	.clock {
		font-family: 'JetBrains Mono', monospace;
		font-size: 11px;
		color: var(--text-tertiary);
		background: var(--card-bg);
		border: 1px solid var(--card-border);
		padding: 6px 14px;
		border-radius: 20px;
	}
</style>
