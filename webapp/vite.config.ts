import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()],
	server: {
		watch: {
			ignored: ['**/node_modules/**', '**/.git/**', '**/data/**', '**/concept/**']
		},
		hmr: {
			overlay: false
		}
	},
	build: {
		sourcemap: false
	}
});
