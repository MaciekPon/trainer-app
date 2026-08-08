<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { toTypedSchema } from '@vee-validate/zod'
import { useForm } from 'vee-validate'
import { z } from 'zod'
import { toast } from 'vue-sonner'
import { useAuthStore } from '@/stores/auth'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

const schema = toTypedSchema(
  z.object({
    fullName: z.string().min(2, 'Podaj imię i nazwisko'),
    email: z.string().email('Podaj poprawny adres e-mail'),
    password: z.string().min(6, 'Hasło musi mieć min. 6 znaków'),
  }),
)

const { defineField, handleSubmit, errors } = useForm({ validationSchema: schema })
const [fullName, fullNameAttrs] = defineField('fullName')
const [email, emailAttrs] = defineField('email')
const [password, passwordAttrs] = defineField('password')

const auth = useAuthStore()
const router = useRouter()
const submitting = ref(false)

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true
  try {
    await auth.signUpTrainer(values.email, values.password, values.fullName)
    toast.success('Konto utworzone')
    router.push('/dashboard')
  } catch (err) {
    toast.error(err instanceof Error ? err.message : 'Nie udało się zarejestrować')
  } finally {
    submitting.value = false
  }
})
</script>

<template>
  <div class="flex min-h-svh items-center justify-center bg-muted/30 p-4">
    <Card class="w-full max-w-sm">
      <CardHeader>
        <CardTitle>Rejestracja trenera</CardTitle>
        <CardDescription>Załóż konto, aby zarządzać podopiecznymi</CardDescription>
      </CardHeader>
      <CardContent>
        <form class="flex flex-col gap-4" @submit="onSubmit">
          <div class="flex flex-col gap-1.5">
            <Label for="fullName">Imię i nazwisko</Label>
            <Input id="fullName" v-model="fullName" v-bind="fullNameAttrs" />
            <p v-if="errors.fullName" class="text-xs text-destructive">{{ errors.fullName }}</p>
          </div>
          <div class="flex flex-col gap-1.5">
            <Label for="email">E-mail</Label>
            <Input id="email" type="email" v-model="email" v-bind="emailAttrs" />
            <p v-if="errors.email" class="text-xs text-destructive">{{ errors.email }}</p>
          </div>
          <div class="flex flex-col gap-1.5">
            <Label for="password">Hasło</Label>
            <Input id="password" type="password" v-model="password" v-bind="passwordAttrs" />
            <p v-if="errors.password" class="text-xs text-destructive">{{ errors.password }}</p>
          </div>
          <Button type="submit" :disabled="submitting">
            {{ submitting ? 'Tworzenie konta…' : 'Zarejestruj się' }}
          </Button>
        </form>
        <p class="mt-4 text-center text-xs text-muted-foreground">
          Masz już konto?
          <RouterLink to="/login" class="text-primary underline-offset-4 hover:underline">
            Zaloguj się
          </RouterLink>
        </p>
      </CardContent>
    </Card>
  </div>
</template>
