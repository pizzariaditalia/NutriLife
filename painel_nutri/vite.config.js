import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  // Ajuste cirúrgico para o GitHub Pages ler a rota exata do seu repositório
  base: '/NutriLife/', 
})
