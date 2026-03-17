<script lang="ts">
	import { pathStore } from '$lib/stores/paths.svelte';
	import { homeStore } from '$lib/stores/home.svelte';

	let rightOffset = $derived(homeStore.panelOpen ? 400 : 24);
</script>

{#if pathStore.pathModeActive}
	<div class="user-selector" style:right="{rightOffset}px">
		{#each pathStore.members as member}
			{@const selected = pathStore.selectedUserId === member.userId}
			<button
				class="avatar-pill"
				class:selected
				style:--member-color={member.color}
				onclick={() => pathStore.selectUser(member.userId)}
			>
				<div
					class="avatar-circle"
					class:selected
				>
					{member.initials}
				</div>
				<span class="member-name">{member.userName}</span>
			</button>
		{/each}
	</div>
{/if}

<style>
	.user-selector {
		position: fixed;
		top: 80px;
		z-index: 180;
		display: flex;
		flex-direction: row;
		gap: 8px;
		padding: 12px;
		border-radius: 16px;
		background: var(--panel-bg);
		backdrop-filter: blur(20px);
		-webkit-backdrop-filter: blur(20px);
		border: 1px solid var(--card-border);
	}

	.avatar-pill {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 4px;
		background: none;
		border: none;
		cursor: pointer;
		padding: 4px;
	}

	.avatar-circle {
		width: 36px;
		height: 36px;
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		font-family: 'JetBrains Mono', monospace;
		font-size: 11px;
		font-weight: 500;
		color: var(--member-color);
		background: color-mix(in srgb, var(--member-color) 15%, transparent);
		border: 1.5px solid color-mix(in srgb, var(--member-color) 30%, transparent);
		transition: all 0.2s ease;
	}

	.avatar-circle.selected {
		background: color-mix(in srgb, var(--member-color) 30%, transparent);
		border-color: var(--member-color);
	}

	.member-name {
		font-size: 9px;
		font-family: 'DM Sans', sans-serif;
		color: var(--text-secondary);
	}
</style>
