import { extendTheme } from "@chakra-ui/react";
import { theme } from "@chakra-ui/pro-theme";

import "@fontsource-variable/manrope";

const proTheme = extendTheme(theme);
const extenstion = {
	colors: {
		...proTheme.colors,
		brand: proTheme.colors.teal,
		mw_orange: "#E63D2D",
		secondary: "#731447",
		nav_bg: "#2d3748",
		nav_text: "#a0aec0",
		primary: "#EB524C",
		hyperlink: "#5383EC",
		black: "#171923",
		dark_gray: "#4b5563",
		border: "#E2E8F0",
	},
	fonts: {
		heading: "'Manrope', -apple-system, system-ui, sans-serif",
		body: "'Manrope', -apple-system, system-ui, sans-serif",
	},
};

const mwTheme = extendTheme(extenstion, proTheme);

export default mwTheme