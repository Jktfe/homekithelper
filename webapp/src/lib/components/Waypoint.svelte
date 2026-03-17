<script lang="ts">
	let { x, y, index, color, time, action } = $props<{
		x: number;
		y: number;
		index: number;
		color: string;
		time: string;
		action: string | undefined;
	}>();
</script>

<g class="waypoint">
	<!-- Background circle -->
	<circle
		cx={x}
		cy={y}
		r={14}
		fill={color}
		fill-opacity="0.2"
		stroke={color}
		stroke-opacity="0.6"
		stroke-width="1.5"
	/>

	<!-- Index number -->
	<text
		x={x}
		y={y}
		text-anchor="middle"
		dominant-baseline="central"
		fill={color}
		font-family="'JetBrains Mono', monospace"
		font-size="10"
		font-weight="500"
	>
		{index + 1}
	</text>

	<!-- Time label -->
	<text
		x={x}
		y={y + 24}
		text-anchor="middle"
		dominant-baseline="central"
		fill="rgba(255,255,255,0.4)"
		font-family="'JetBrains Mono', monospace"
		font-size="8"
	>
		{time}
	</text>

	<!-- Action label -->
	{#if action}
		<text
			x={x}
			y={y + 34}
			text-anchor="middle"
			dominant-baseline="central"
			fill={color}
			fill-opacity="0.6"
			font-family="'DM Sans', sans-serif"
			font-size="8"
		>
			{action}
		</text>
	{/if}
</g>
