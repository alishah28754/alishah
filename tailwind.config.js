/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        ink: '#0A0A0A',
        gold: {
          DEFAULT: '#D3AF64',
          dark: '#8A6B1F',
          soft: '#F4E4BC',
        },
        cream: '#FCF9F8',
        line: '#EAE7E7',
        muted: '#7E7576',
        mutedLight: '#CFC4C5',
        danger: '#F1414D',
      },
      fontFamily: {
        sans: ['Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'],
        display: ['"Fraunces"', 'ui-serif', 'Georgia', 'serif'],
      },
      boxShadow: {
        card: '0 1px 2px rgba(10,10,10,0.04), 0 1px 12px rgba(10,10,10,0.04)',
      },
    },
  },
  plugins: [],
};
