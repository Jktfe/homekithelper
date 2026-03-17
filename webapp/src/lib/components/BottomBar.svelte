<script lang="ts">
	import { homeStore } from '$lib/stores/home.svelte';

	let homeName = $derived(homeStore.home?.name ?? 'Home');
	let roomCount = $derived(homeStore.roomCount);
	let deviceCount = $derived(homeStore.deviceCount);
	let sceneCount = $derived(homeStore.sceneCount);
</script>

<footer class="bottombar">
	<span class="breadcrumb">Home &gt; {homeName}</span>
	<span class="stats">{roomCount} rooms &middot; {deviceCount} devices &middot; {sceneCount} scenes</span>
</footer>

<style>
	.bottombar {
		position: fixed;
		bottom: 0;
		left: 0;
		right: 0;
		z-index: 50;
		display: flex;
		flex-direction: row;
		justify-content: space-between;
		align-items: center;
		padding: 16px 32px;
		background: linear-gradient(0deg, var(--surface) 0%, transparent 100%);
		pointer-events: none;
	}

	.breadcrumb {
		font-family: 'DM Sans', sans-serif;
		font-size: 11px;
		color: var(--text-tertiary);
	}

	.stats {
		font-family: 'JetBrains Mono', monospace;
		font-size: 10px;
		color: var(--text-muted);
	}
</style>
