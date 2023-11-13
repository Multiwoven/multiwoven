/** @type {import('tailwindcss').Config} */
// tailwind.config.js
module.exports = {
  purge: ['./src/**/*.{js,jsx,ts,tsx}', './public/index.html'],
  darkMode: false,
  theme: {
    extend: {
      colors: {
        "multiwoven": 
        {
          50: "#FDF4F3",
          100: "#FADEDC",
          200: "#F8C9C4",
          300: "#F5B3AD",
          400: "#F29E96",
          500: "#EF887E",
          600: "#EC7267",
          700: "#EA5D50",
          800: "#E74738",
          900: "#e63d2d"
      }
      }
    },
  },
  variants: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
}

