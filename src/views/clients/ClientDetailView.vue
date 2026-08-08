<script setup lang="ts">
import { computed, ref, toRef } from 'vue'
import { toast } from 'vue-sonner'
import { useAuthStore } from '@/stores/auth'
import { useClientProfile } from '@/composables/useClients'
import { useCreateTrainingPlan, useTrainingPlans } from '@/composables/usePlans'
import { useCreateNutritionTarget, useNutritionTargets } from '@/composables/useNutrition'
import AppShell from '@/components/AppShell.vue'
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

const auth = useAuthStore()
const trainerId = computed(() => auth.profile?.id)

const { data: clientProfile } = useClientProfile(clientId)
const { data: plans, isLoading: plansLoading } = useTrainingPlans(clientId)
const createPlan = useCreateTrainingPlan()

const newPlanName = ref('')
const planDialogOpen = ref(false)

async function handleCreatePlan() {
  if (!trainerId.value || !newPlanName.value.trim()) return
  try {
    await createPlan.mutateAsync({
      clientId: clientId.value,
      trainerId: trainerId.value,
      name: newPlanName.value.trim(),
    })
    newPlanName.value = ''
    planDialogOpen.value = false
    toast.success('Plan utworzony')
  } catch (err) {
    toast.error(err instanceof Error ? err.message : 'Nie udało się utworzyć planu')
  }
}

const { data: nutritionTargets } = useNutritionTargets(clientId)
const createNutritionTarget = useCreateNutritionTarget(clientId)
const nutritionForm = ref({ calories: '', protein_g: '', carbs_g: '', fat_g: '' })
const nutritionDialogOpen = ref(false)

async function handleCreateNutritionTarget() {
  const calories = Number(nutritionForm.value.calories)
  if (!calories) {
    toast.error('Podaj liczbę kalorii')
    return
  }
  try {
    await createNutritionTarget.mutateAsync({
      calories,
      protein_g: nutritionForm.value.protein_g ? Number(nutritionForm.value.protein_g) : null,
      carbs_g: nutritionForm.value.carbs_g ? Number(nutritionForm.value.carbs_g) : null,
      fat_g: nutritionForm.value.fat_g ? Number(nutritionForm.value.fat_g) : null,
    })
    nutritionForm.value = { calories: '', protein_g: '', carbs_g: '', fat_g: '' }
    nutritionDialogOpen.value = false
    toast.success('Cel kaloryczny zapisany')
  } catch (err) {
    toast.error(err instanceof Error ? err.message : 'Nie udało się zapisać celu')
  }
}
</script>

<template>
  <AppShell>
    <div class="flex flex-col gap-6">
      <div class="flex items-center justify-between">
        <div>
          <RouterLink to="/dashboard" class="text-sm text-muted-foreground hover:underline">
            ← Powrót do listy
          </RouterLink>
          <h1 class="text-xl font-semibold">{{ clientProfile?.full_name ?? '…' }}</h1>
        </div>
        <RouterLink :to="`/clients/${clientId}/progress`">
          <Button variant="outline">Zobacz postępy</Button>
        </RouterLink>
      </div>

      <Card>
        <CardHeader class="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Plany treningowe</CardTitle>
            <CardDescription>Programy przypisane do podopiecznego</CardDescription>
          </div>
          <Dialog v-model:open="planDialogOpen">
            <DialogTrigger as-child>
              <Button size="sm">Nowy plan</Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Nowy plan treningowy</DialogTitle>
              </DialogHeader>
              <div class="flex flex-col gap-1.5">
                <Label for="planName">Nazwa planu</Label>
                <Input id="planName" v-model="newPlanName" placeholder="np. Siła — cykl 1" />
              </div>
              <DialogFooter>
                <Button :disabled="createPlan.isPending.value" @click="handleCreatePlan">
                  Utwórz
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Nazwa</TableHead>
                <TableHead>Utworzono</TableHead>
                <TableHead class="text-right">Akcje</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              <TableRow v-if="plansLoading">
                <TableCell colspan="3">Ładowanie…</TableCell>
              </TableRow>
              <TableEmpty v-else-if="!plans?.length" :colspan="3">Brak planów — dodaj pierwszy.</TableEmpty>
              <TableRow v-for="plan in plans" :key="plan.id">
                <TableCell>{{ plan.name }}</TableCell>
                <TableCell>{{ new Date(plan.created_at).toLocaleDateString('pl-PL') }}</TableCell>
                <TableCell class="text-right">
                  <RouterLink :to="`/clients/${clientId}/plans/${plan.id}`">
                    <Button variant="outline" size="sm">Edytuj</Button>
                  </RouterLink>
                </TableCell>
              </TableRow>
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <Card>
        <CardHeader class="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Cele kaloryczne</CardTitle>
            <CardDescription>Historia ustawionych celów żywieniowych</CardDescription>
          </div>
          <Dialog v-model:open="nutritionDialogOpen">
            <DialogTrigger as-child>
              <Button size="sm">Nowy cel</Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Nowy cel kaloryczny</DialogTitle>
              </DialogHeader>
              <div class="grid grid-cols-2 gap-3">
                <div class="flex flex-col gap-1.5">
                  <Label for="calories">Kalorie (kcal)</Label>
                  <Input id="calories" type="number" v-model="nutritionForm.calories" />
                </div>
                <div class="flex flex-col gap-1.5">
                  <Label for="protein">Białko (g)</Label>
                  <Input id="protein" type="number" v-model="nutritionForm.protein_g" />
                </div>
                <div class="flex flex-col gap-1.5">
                  <Label for="carbs">Węglowodany (g)</Label>
                  <Input id="carbs" type="number" v-model="nutritionForm.carbs_g" />
                </div>
                <div class="flex flex-col gap-1.5">
                  <Label for="fat">Tłuszcz (g)</Label>
                  <Input id="fat" type="number" v-model="nutritionForm.fat_g" />
                </div>
              </div>
              <DialogFooter>
                <Button :disabled="createNutritionTarget.isPending.value" @click="handleCreateNutritionTarget">
                  Zapisz
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Obowiązuje od</TableHead>
                <TableHead>Kalorie</TableHead>
                <TableHead>Białko</TableHead>
                <TableHead>Węgle</TableHead>
                <TableHead>Tłuszcz</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              <TableEmpty v-if="!nutritionTargets?.length" :colspan="5">Brak ustawionych celów.</TableEmpty>
              <TableRow v-for="target in nutritionTargets" :key="target.id">
                <TableCell>{{ new Date(target.valid_from).toLocaleDateString('pl-PL') }}</TableCell>
                <TableCell>{{ target.calories }} kcal</TableCell>
                <TableCell>{{ target.protein_g ?? '—' }} g</TableCell>
                <TableCell>{{ target.carbs_g ?? '—' }} g</TableCell>
                <TableCell>{{ target.fat_g ?? '—' }} g</TableCell>
              </TableRow>
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  </AppShell>
</template>
