<script setup lang="ts">
import { ref, toRef } from 'vue'
import { toast } from 'vue-sonner'
import { useCreatePlanDay, usePlanDays, useTrainingPlan } from '@/composables/usePlans'
import AppShell from '@/components/AppShell.vue'
import PlanDayCard from '@/components/plans/PlanDayCard.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

const props = defineProps<{ clientId: string; planId: string }>()
const planId = toRef(props, 'planId')

const { data: plan } = useTrainingPlan(planId)
const { data: days, isLoading } = usePlanDays(planId)
const createDay = useCreatePlanDay(planId)

const newDayName = ref('')

async function handleAddDay() {
  if (!newDayName.value.trim()) {
    toast.error('Podaj nazwę dnia')
    return
  }
  try {
    await createDay.mutateAsync({ name: newDayName.value.trim(), position: days.value?.length ?? 0 })
    newDayName.value = ''
  } catch (err) {
    toast.error(err instanceof Error ? err.message : 'Nie udało się dodać dnia')
  }
}
</script>

<template>
  <AppShell>
    <div class="flex flex-col gap-6">
      <div>
        <RouterLink :to="`/clients/${clientId}`" class="text-sm text-muted-foreground hover:underline">
          ← Powrót do profilu podopiecznego
        </RouterLink>
        <h1 class="text-xl font-semibold">{{ plan?.name ?? '…' }}</h1>
      </div>

      <div v-if="isLoading">Ładowanie…</div>
      <PlanDayCard v-for="day in days" :key="day.id" :day="day" />

      <form class="flex items-end gap-2" @submit.prevent="handleAddDay">
        <div class="flex flex-1 flex-col gap-1">
          <label class="text-xs text-muted-foreground">Nowy dzień treningowy</label>
          <Input v-model="newDayName" placeholder="np. Dzień A — Push" />
        </div>
        <Button type="submit" :disabled="createDay.isPending.value">Dodaj dzień</Button>
      </form>
    </div>
  </AppShell>
</template>
