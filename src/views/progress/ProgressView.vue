<script setup lang="ts">
import { computed, ref, toRef } from 'vue'
import { toast } from 'vue-sonner'
import { useClientProfile } from '@/composables/useClients'
import {
  useCreateMeasurement,
  useMeasurements,
  useVolumeTrend,
  useWorkoutSessions,
} from '@/composables/useProgress'
import AppShell from '@/components/AppShell.vue'
import ProgressLineChart from '@/components/charts/ProgressLineChart.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'
import {
  Table,
  TableBody,
  TableCell,
  TableEmpty,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'

const props = defineProps<{ clientId: string }>()
const clientId = toRef(props, 'clientId')

const { data: clientProfile } = useClientProfile(clientId)

const { data: measurements } = useMeasurements(clientId)
const createMeasurement = useCreateMeasurement(clientId)

const measurementForm = ref({ weight: '', waist: '', hips: '', chest: '', arm: '', thigh: '' })
const measurementDialogOpen = ref(false)

const dateLabel = (iso: string) => new Date(iso).toLocaleDateString('pl-PL')

const weightChart = computed(() => ({
  labels: (measurements.value ?? []).map((m) => dateLabel(m.measured_at)),
  datasets: [{ label: 'Waga (kg)', data: (measurements.value ?? []).map((m) => m.weight) }],
}))

const circumferenceChart = computed(() => ({
  labels: (measurements.value ?? []).map((m) => dateLabel(m.measured_at)),
  datasets: [
    { label: 'Pas (cm)', data: (measurements.value ?? []).map((m) => m.waist) },
    { label: 'Biodra (cm)', data: (measurements.value ?? []).map((m) => m.hips) },
    { label: 'Klatka (cm)', data: (measurements.value ?? []).map((m) => m.chest) },
  ],
}))

async function handleAddMeasurement() {
  try {
    await createMeasurement.mutateAsync({
      weight: measurementForm.value.weight ? Number(measurementForm.value.weight) : null,
      waist: measurementForm.value.waist ? Number(measurementForm.value.waist) : null,
      hips: measurementForm.value.hips ? Number(measurementForm.value.hips) : null,
      chest: measurementForm.value.chest ? Number(measurementForm.value.chest) : null,
      arm: measurementForm.value.arm ? Number(measurementForm.value.arm) : null,
      thigh: measurementForm.value.thigh ? Number(measurementForm.value.thigh) : null,
    })
    measurementForm.value = { weight: '', waist: '', hips: '', chest: '', arm: '', thigh: '' }
    measurementDialogOpen.value = false
    toast.success('Pomiar zapisany')
  } catch (err) {
    toast.error(err instanceof Error ? err.message : 'Nie udało się zapisać pomiaru')
  }
}

const { data: sessions } = useWorkoutSessions(clientId)
const volumeTrend = useVolumeTrend(sessions)

const volumeChart = computed(() => ({
  labels: volumeTrend.value.map((entry) => dateLabel(entry.session.performed_at)),
  datasets: [{ label: 'Objętość treningowa (kg × powt.)', data: volumeTrend.value.map((entry) => entry.volume) }],
}))
</script>

<template>
  <AppShell>
    <div class="flex flex-col gap-6">
      <div>
        <RouterLink :to="`/clients/${clientId}`" class="text-sm text-muted-foreground hover:underline">
          ← Powrót do profilu podopiecznego
        </RouterLink>
        <h1 class="text-xl font-semibold">Postępy — {{ clientProfile?.full_name ?? '…' }}</h1>
      </div>

      <Card>
        <CardHeader class="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Waga i obwody</CardTitle>
            <CardDescription>Historia pomiarów ciała</CardDescription>
          </div>
          <Dialog v-model:open="measurementDialogOpen">
            <DialogTrigger as-child>
              <Button size="sm">Dodaj pomiar</Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Nowy pomiar</DialogTitle>
              </DialogHeader>
              <div class="grid grid-cols-2 gap-3">
                <div class="flex flex-col gap-1.5">
                  <Label for="weight">Waga (kg)</Label>
                  <Input id="weight" type="number" step="0.1" v-model="measurementForm.weight" />
                </div>
                <div class="flex flex-col gap-1.5">
                  <Label for="waist">Pas (cm)</Label>
                  <Input id="waist" type="number" step="0.1" v-model="measurementForm.waist" />
                </div>
                <div class="flex flex-col gap-1.5">
                  <Label for="hips">Biodra (cm)</Label>
                  <Input id="hips" type="number" step="0.1" v-model="measurementForm.hips" />
                </div>
                <div class="flex flex-col gap-1.5">
                  <Label for="chest">Klatka (cm)</Label>
                  <Input id="chest" type="number" step="0.1" v-model="measurementForm.chest" />
                </div>
                <div class="flex flex-col gap-1.5">
                  <Label for="arm">Ramię (cm)</Label>
                  <Input id="arm" type="number" step="0.1" v-model="measurementForm.arm" />
                </div>
                <div class="flex flex-col gap-1.5">
                  <Label for="thigh">Udo (cm)</Label>
                  <Input id="thigh" type="number" step="0.1" v-model="measurementForm.thigh" />
                </div>
              </div>
              <DialogFooter>
                <Button :disabled="createMeasurement.isPending.value" @click="handleAddMeasurement">
                  Zapisz
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </CardHeader>
        <CardContent class="flex flex-col gap-6">
          <p v-if="!measurements?.length" class="text-sm text-muted-foreground">
            Brak zapisanych pomiarów.
          </p>
          <template v-else>
            <ProgressLineChart :labels="weightChart.labels" :datasets="weightChart.datasets" />
            <ProgressLineChart :labels="circumferenceChart.labels" :datasets="circumferenceChart.datasets" />
          </template>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Objętość treningowa</CardTitle>
          <CardDescription>
            Suma ciężar × powtórzenia we wszystkich seriach sesji — trend względem poprzedniej sesji tego
            samego dnia planu
          </CardDescription>
        </CardHeader>
        <CardContent class="flex flex-col gap-6">
          <p v-if="!sessions?.length" class="text-sm text-muted-foreground">
            Brak zarejestrowanych sesji treningowych.
          </p>
          <template v-else>
            <ProgressLineChart :labels="volumeChart.labels" :datasets="volumeChart.datasets" />
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Data</TableHead>
                  <TableHead>Objętość</TableHead>
                  <TableHead>Zmiana vs. poprzednia (ten sam dzień planu)</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                <TableEmpty v-if="!volumeTrend.length" :colspan="3">Brak danych.</TableEmpty>
                <TableRow v-for="entry in volumeTrend" :key="entry.session.id">
                  <TableCell>{{ dateLabel(entry.session.performed_at) }}</TableCell>
                  <TableCell>{{ entry.volume.toFixed(0) }}</TableCell>
                  <TableCell>
                    <span
                      v-if="entry.deltaPct !== null"
                      :class="entry.deltaPct >= 0 ? 'text-green-600' : 'text-red-600'"
                    >
                      {{ entry.deltaPct >= 0 ? '+' : '' }}{{ entry.deltaPct.toFixed(1) }}%
                    </span>
                    <span v-else class="text-muted-foreground">—</span>
                  </TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </template>
        </CardContent>
      </Card>
    </div>
  </AppShell>
</template>
