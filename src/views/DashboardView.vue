<script setup lang="ts">
import { computed, ref } from 'vue'
import { toast } from 'vue-sonner'
import { useAuthStore } from '@/stores/auth'
import { useClients } from '@/composables/useClients'
import { useGenerateInviteLink } from '@/composables/useInvite'
import AppShell from '@/components/AppShell.vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Table,
  TableBody,
  TableCell,
  TableEmpty,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'

const auth = useAuthStore()
const trainerId = computed(() => auth.profile?.id)

const { data: clients, isLoading } = useClients(trainerId)
const generateInvite = useGenerateInviteLink()
const inviteLink = ref<string | null>(null)

async function handleGenerateInvite() {
  if (!trainerId.value) {
    toast.error('Nie znaleziono Twojego profilu trenera — zaloguj się ponownie lub skontaktuj z pomocą.')
    return
  }
  try {
    const url = await generateInvite.mutateAsync(trainerId.value)
    inviteLink.value = url
  } catch (err) {
    toast.error(err instanceof Error ? err.message : 'Nie udało się wygenerować linku')
  }
}

async function copyLink() {
  if (!inviteLink.value) return
  await navigator.clipboard.writeText(inviteLink.value)
  toast.success('Link skopiowany do schowka')
}
</script>

<template>
  <AppShell>
    <div class="flex flex-col gap-6">
      <Card>
        <CardHeader>
          <CardTitle>Zaproś podopiecznego</CardTitle>
          <CardDescription>
            Wygeneruj link zaproszenia i wyślij go podopiecznemu — po rejestracji zostanie automatycznie
            przypisany do Ciebie.
          </CardDescription>
        </CardHeader>
        <CardContent class="flex flex-col gap-3">
          <Button class="w-fit" :disabled="generateInvite.isPending.value" @click="handleGenerateInvite">
            {{ generateInvite.isPending.value ? 'Generowanie…' : 'Wygeneruj link zaproszenia' }}
          </Button>
          <div v-if="inviteLink" class="flex items-center gap-2 rounded-md border bg-muted/40 p-2 text-sm">
            <code class="flex-1 truncate">{{ inviteLink }}</code>
            <Button variant="outline" size="sm" @click="copyLink">Kopiuj</Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Podopieczni</CardTitle>
          <CardDescription>Lista osób, które trenujesz</CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Imię i nazwisko</TableHead>
                <TableHead>Dołączył(a)</TableHead>
                <TableHead class="text-right">Akcje</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              <TableRow v-if="isLoading">
                <TableCell colspan="3">Ładowanie…</TableCell>
              </TableRow>
              <TableEmpty v-else-if="!clients?.length" :colspan="3">
                Brak podopiecznych — wygeneruj link zaproszenia powyżej.
              </TableEmpty>
              <TableRow v-for="client in clients" :key="client.client_id">
                <TableCell>{{ client.full_name }}</TableCell>
                <TableCell>{{ new Date(client.created_at).toLocaleDateString('pl-PL') }}</TableCell>
                <TableCell class="text-right">
                  <RouterLink :to="`/clients/${client.client_id}`">
                    <Button variant="outline" size="sm">Otwórz profil</Button>
                  </RouterLink>
                </TableCell>
              </TableRow>
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  </AppShell>
</template>
