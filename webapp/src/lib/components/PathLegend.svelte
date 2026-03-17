<script lang="ts">
	import { pathStore } from '$lib/stores/paths.svelte';
	import { homeStore } from '$lib/stores/home.svelte';

	let path = $derived(pathStore.currentPath);

	function roomName(roomId: string): string {
		const room = homeStore.rooms.find((r) => r.roomId === roomId);
		return room?.roomName ?? roomId;
	}
</script>

{#if path && path.waypoints.length > 0}
	<div class="path-legend" style:--path-color={path.color}>
		<h4 class="title">{path.userName}'s Route</h4>
		<ol class="steps">
			{#each path.waypoints as wp, i}
				<li class="step">
					<span class="step-number">{i + 1}</span>
					<span class="step-time">{wp.time}</span>
					<span class="step-detail">
						<span class="step-room">{roomName(wp.roomId)}</span>
						{#if wp.action}
							<span class="step-action">{wp.action}</span>
						{/if}
					</span>
				</li>
			{/each}
		</ol>
	</div>
{/if}

<style>
	.path-legend {
		position: fixed;
		bottom: 100px;
		right: 24px;
		z-index: 160;
		padding: 16px;
		border-radius: 14px;
		max-width: 240px;
		background: var(--panel-bg);
		backdrop-filter: blur(20px);
		-webkit-backdrop-filter: blur(20px);
		border: 1px solid var(--card-border);
	}

	.title {
		font-family: 'DM Sans', sans-serif;
		font-size: 12px;
		font-weight: 500;
		color: var(--path-color);
		margin: 0 0 12px 0;
	}

	.steps {
		list-style: none;
		margin: 0;
		padding: 0;
		display: flex;
		flex-direction: column;
		gap: 8px;
	}

	.step {
		display: flex;
		align-items: flex-start;
		gap: 8px;
	}

	.step-number {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		color: var(--path-color);
		opacity: 0.6;
		min-width: 12px;
		flex-shrink: 0;
	}

	.step-time {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		color: var(--text-tertiary);
		min-width: 36px;
		flex-shrink: 0;
	}

	.step-detail {
		display: flex;
		flex-direction: column;
		gap: 1px;
	}

	.step-room {
		font-family: 'DM Sans', sans-serif;
		font-size: 11px;
		color: var(--text-secondary);
	}

	.step-action {
		font-family: 'DM Sans', sans-serif;
		font-size: 9px;
		color: var(--path-color);
		opacity: 0.5;
	}
</style>
