import { extendTheme } from "@chakra-ui/react";
import { theme } from "@chakra-ui/pro-theme";

import "@fontsource-variable/manrope";

const proTheme = extendTheme(theme);
const extenstion = {
	colors: {
		...proTheme.colors,
		mw_orange: "#E63D2D",
		secondary: "#731447",
		nav_bg: "#2d3748",
		nav_text: "#a0aec0",
		primary: "#EB524C",
		hyperlink: "#5383EC",
		black: "#171923",
		dark_gray: "#4b5563",
		border: "#E2E8F0",
		brand: {
			100: "#FFE8E6",
			200: "#FAC5C3",
			300: "#F5837F",
			400: "#F5433D",
			500: "#CC1C16",
			600: "#720D09",
		},
	},
	components: {
		Button: {
			variants: {
				solid: () => ({
					bg: "brand.400",
				}),
			},
		},
	},

	fonts: {
		heading: "'Manrope', -apple-system, system-ui, sans-serif",
		body: "'Manrope', -apple-system, system-ui, sans-serif",
	},
	styles: {
		h1: {
			fontSize: "60px",
			lineHeight: "72px",
			tracking: "-1%",
		},
	},
};

const mwTheme = extendTheme(extenstion, proTheme);

export default mwTheme;
