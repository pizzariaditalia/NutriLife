import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  // Define que o projeto rodará na subpasta para podermos publicar no GitHub Pages de graça futuramente
  base: './', 
})
