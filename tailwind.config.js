module.exports = {
  content: [
    './app/views/**/*.{erb,html}',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        'primary-green': 'var(--color-primary-green)',
        'primary-text': 'var(--color-primary-text)',
        'secondary-text': 'var(--color-secondary-text)',
      },
      fontFamily: {
        sans: 'var(--font-family-sans)',
        mono: 'var(--font-family-mono)'
      },
      spacing: {
        'base': 'var(--spacing-base)',
        'sm': 'var(--spacing-sm)',
        'md': 'var(--spacing-md)',
        'lg': 'var(--spacing-lg)',
        'xl': 'var(--spacing-xl)',
      }
    },
  },
  plugins: [],
} 