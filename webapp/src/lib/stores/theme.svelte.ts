import { browser } from '$app/environment';

const THEME_KEY = 'hkh-theme';

type Theme = 'dark' | 'light';

function loadTheme(): Theme {
	if (browser) {
		const saved = localStorage.getItem(THEME_KEY);
		if (saved === 'dark' || saved === 'light') return saved;
	}
	return 'light';
}

class ThemeStore {
	current = $state<Theme>(loadTheme());

	isDark = $derived(this.current === 'dark');

	toggle() {
		this.current = this.current === 'dark' ? 'light' : 'dark';
		if (browser) {
			localStorage.setItem(THEME_KEY, this.current);
			document.documentElement.setAttribute('data-theme', this.current);
		}
	}

	init() {
		if (browser) {
			document.documentElement.setAttribute('data-theme', this.current);
		}
	}
}

export const themeStore = new ThemeStore();
