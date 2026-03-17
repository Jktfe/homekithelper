<script>
	import '../app.css';
	import { themeStore } from '$lib/stores/theme.svelte';

	let { children } = $props();

	$effect(() => {
		themeStore.init();
	});
</script>

{@render children()}
