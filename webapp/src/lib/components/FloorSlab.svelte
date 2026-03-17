<script lang="ts">
	let { name, selected, color, roomCount, onclick } = $props<{
		name: string;
		selected: boolean;
		color: string;
		roomCount: number;
		onclick: () => void;
	}>();
</script>

<button class="slab" class:selected onclick={onclick} style:--slab-color={color}>
	<div class="inner">
		<span class="name">{name}</span>
		<span class="count">{roomCount}</span>
	</div>
</button>

<style>
	.slab {
		display: flex;
		align-items: center;
		height: 48px;
		min-width: 120px;
		margin-bottom: 8px;
		padding: 0 14px;
		border-radius: 8px;
		border: 1px solid var(--card-border);
		background: var(--card-bg);
		cursor: pointer;
		transform: skewX(-20deg);
		transition: all 0.3s ease;
		color: var(--text-secondary);
	}

	.slab:hover {
		background: var(--card-hover);
		border-color: rgba(255, 255, 255, 0.12);
	}

	.slab.selected {
		border-color: var(--slab-color, #d4a053);
		background: color-mix(in srgb, var(--slab-color, #d4a053) 8%, transparent);
		color: var(--slab-color, #d4a053);
	}

	.inner {
		display: flex;
		align-items: center;
		justify-content: space-between;
		width: 100%;
		gap: 10px;
		transform: skewX(20deg);
	}

	.name {
		font-family: 'DM Sans', sans-serif;
		font-size: 11px;
		font-weight: 500;
		text-transform: uppercase;
		letter-spacing: 0.04em;
	}

	.count {
		font-family: 'JetBrains Mono', monospace;
		font-size: 9px;
		font-weight: 500;
		opacity: 0.8;
		background: var(--card-hover);
		padding: 2px 6px;
		border-radius: 8px;
	}
</style>
