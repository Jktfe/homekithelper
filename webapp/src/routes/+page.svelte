<script lang="ts">
	import Canvas from '$lib/components/Canvas.svelte';
	import TopBar from '$lib/components/TopBar.svelte';
	import BottomBar from '$lib/components/BottomBar.svelte';
	import BuildingNav from '$lib/components/BuildingNav.svelte';
	import DevicePanel from '$lib/components/DevicePanel.svelte';
	import RoomEditPanel from '$lib/components/RoomEditPanel.svelte';
	import IntentDrawer from '$lib/components/IntentDrawer.svelte';
	import ImportModal from '$lib/components/ImportModal.svelte';
	import UserSelector from '$lib/components/UserSelector.svelte';
	import TimeScrubber from '$lib/components/TimeScrubber.svelte';
	import PathLegend from '$lib/components/PathLegend.svelte';
	import SaveAutomationModal from '$lib/components/SaveAutomationModal.svelte';
	import { pathStore } from '$lib/stores/paths.svelte';
</script>

<svelte:head>
	<title>HomeKit Helper — Dream Canvas</title>
</svelte:head>

<Canvas />
<TopBar />
<BuildingNav />
<DevicePanel />
<RoomEditPanel />
<IntentDrawer />
<BottomBar />
<ImportModal />

{#if pathStore.pathModeActive}
	<UserSelector />
	<TimeScrubber />
	{#if pathStore.currentPath}
		<PathLegend />
	{/if}
{/if}

<SaveAutomationModal />
