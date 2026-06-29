/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        verdeApp: '#4C924F',
        verdeOscuro: '#306339',
        fondoApp: '#FBFFFB',
      }
    },
  },
  plugins: [],
  darkMode: 'class',
}

module.exports = {
  darkMode: 'class', // <--- ESTO ES VITAL
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}