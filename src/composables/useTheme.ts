import { ref, watchEffect } from 'vue'

const STORAGE_KEY = 'trainer-app-theme'
type Theme = 'light' | 'dark'

// Ta sama logika co inline-script w index.html (który już ustawił klasę .dark
// przed pierwszym renderem) — tu tylko odczytujemy ten stan do reaktywnego refa.
const theme = ref<Theme>(document.documentElement.classList.contains('dark') ? 'dark' : 'light')

watchEffect(() => {
  document.documentElement.classList.toggle('dark', theme.value === 'dark')
  localStorage.setItem(STORAGE_KEY, theme.value)
})

export function useTheme() {
  function toggleTheme() {
    theme.value = theme.value === 'dark' ? 'light' : 'dark'
  }

  return { theme, toggleTheme }
}
