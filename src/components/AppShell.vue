<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { Button } from '@/components/ui/button'

const auth = useAuthStore()
const router = useRouter()

async function handleSignOut() {
  await auth.signOut()
  router.push('/login')
}
</script>

<template>
  <div class="min-h-svh bg-muted/30">
    <header class="border-b bg-background">
      <div class="mx-auto flex max-w-5xl items-center justify-between px-4 py-3">
        <RouterLink to="/dashboard" class="font-semibold">Trainer App</RouterLink>
        <div class="flex items-center gap-3 text-sm text-muted-foreground">
          <span v-if="auth.profile">{{ auth.profile.full_name }}</span>
          <Button variant="outline" size="sm" @click="handleSignOut">Wyloguj</Button>
        </div>
      </div>
    </header>
    <main class="mx-auto max-w-5xl px-4 py-6">
      <slot />
    </main>
  </div>
</template>
