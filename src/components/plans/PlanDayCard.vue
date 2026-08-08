<script setup lang="ts">
import { ref, toRef } from 'vue'
import { toast } from 'vue-sonner'
import {
  useCreatePlanExercise,
  useDeletePlanDay,
  useDeletePlanExercise,
  usePlanExercises,
} from '@/composables/usePlans'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Table,
  TableBody,
  TableCell,
  TableEmpty,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'

const props = defineProps<{
  day: { id: string; plan_id: string; name: string; position: number }
}>()

const dayId = toRef(props.day, 'id')
const planId = toRef(props.day, 'plan_id')

const { data: exercises, isLoading } = usePlanExercises(dayId)
const createExercise = useCreatePlanExercise(dayId)
const deleteExercise = useDeletePlanExercise(dayId)
const deleteDay = useDeletePlanDay(planId)

const form = ref({ exerciseName: '', targetSets: '3', targetReps: '10', notes: '' })

async function handleAddExercise() {
  if (!form.value.exerciseName.trim()) {
    toast.error('Podaj nazwę ćwiczenia')
    return
  }
  try {
    await createExercise.mutateAsync({
      exercise_name: form.value.exerciseName.trim(),
      target_sets: Number(form.value.targetSets) || 1,
      target_reps: Number(form.value.targetReps) || 1,
      notes: form.value.notes.trim() || null,
      position: exercises.value?.length ?? 0,
    })
    form.value = { exerciseName: '', targetSets: '3', targetReps: '10', notes: '' }
  } catch (err) {
    toast.error(err instanceof Error ? err.message : 'Nie udało się dodać ćwiczenia')
  }
}

async function handleDeleteExercise(id: string) {
  try {
    await deleteExercise.mutateAsync(id)
  } catch (err) {
    toast.error(err instanceof Error ? err.message : 'Nie udało się usunąć ćwiczenia')
  }
}

async function handleDeleteDay() {
  try {
    await deleteDay.mutateAsync(props.day.id)
  } catch (err) {
    toast.error(err instanceof Error ? err.message : 'Nie udało się usunąć dnia')
  }
}
</script>

<template>
  <Card>
    <CardHeader class="flex flex-row items-center justify-between">
      <CardTitle>{{ day.name }}</CardTitle>
      <Button variant="ghost" size="sm" @click="handleDeleteDay">Usuń dzień</Button>
    </CardHeader>
    <CardContent class="flex flex-col gap-4">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Ćwiczenie</TableHead>
            <TableHead>Serie</TableHead>
            <TableHead>Powt.</TableHead>
            <TableHead>Notatki</TableHead>
            <TableHead class="text-right">Akcje</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          <TableRow v-if="isLoading">
            <TableCell colspan="5">Ładowanie…</TableCell>
          </TableRow>
          <TableEmpty v-else-if="!exercises?.length" :colspan="5">Brak ćwiczeń w tym dniu.</TableEmpty>
          <TableRow v-for="exercise in exercises" :key="exercise.id">
            <TableCell>{{ exercise.exercise_name }}</TableCell>
            <TableCell>{{ exercise.target_sets }}</TableCell>
            <TableCell>{{ exercise.target_reps }}</TableCell>
            <TableCell class="text-muted-foreground">{{ exercise.notes ?? '—' }}</TableCell>
            <TableCell class="text-right">
              <Button variant="ghost" size="sm" @click="handleDeleteExercise(exercise.id)">Usuń</Button>
            </TableCell>
          </TableRow>
        </TableBody>
      </Table>

      <form class="grid grid-cols-[2fr_1fr_1fr_2fr_auto] items-end gap-2" @submit.prevent="handleAddExercise">
        <div class="flex flex-col gap-1">
          <label class="text-xs text-muted-foreground">Ćwiczenie</label>
          <Input v-model="form.exerciseName" placeholder="np. Przysiad ze sztangą" />
        </div>
        <div class="flex flex-col gap-1">
          <label class="text-xs text-muted-foreground">Serie</label>
          <Input v-model="form.targetSets" type="number" min="1" />
        </div>
        <div class="flex flex-col gap-1">
          <label class="text-xs text-muted-foreground">Powt.</label>
          <Input v-model="form.targetReps" type="number" min="1" />
        </div>
        <div class="flex flex-col gap-1">
          <label class="text-xs text-muted-foreground">Notatki</label>
          <Input v-model="form.notes" placeholder="opcjonalnie" />
        </div>
        <Button type="submit" :disabled="createExercise.isPending.value">Dodaj</Button>
      </form>
    </CardContent>
  </Card>
</template>
