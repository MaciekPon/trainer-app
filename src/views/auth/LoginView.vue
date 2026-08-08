<script setup lang="ts">
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
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
    email: z.string().email('Podaj poprawny adres e-mail'),
    password: z.string().min(6, 'Hasło musi mieć min. 6 znaków'),
  }),
)

const { defineField, handleSubmit, errors } = useForm({ validationSchema: schema })
const [email, emailAttrs] = defineField('email')
const [password, passwordAttrs] = defineField('password')

const auth = useAuthStore()
const router = useRouter()
const route = useRoute()
const submitting = ref(false)

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true
  try {
    await auth.signIn(values.email, values.password)
    const redirect = (route.query.redirect as string) || '/dashboard'
    router.push(redirect)
  } catch (err) {
    toast.error(err instanceof Error ? err.message : 'Nie udało się zalogować')
  } finally {
    submitting.value = false
  }
})
</script>

<template>
  <div class="flex min-h-svh items-center justify-center bg-muted/30 p-4">
    <Card class="w-full max-w-sm">
      <CardHeader>
        <CardTitle>Logowanie trenera</CardTitle>
        <CardDescription>Zaloguj się do panelu trenera</CardDescription>
      </CardHeader>
      <CardContent>
        <form class="flex flex-col gap-4" @submit="onSubmit">
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
            {{ submitting ? 'Logowanie…' : 'Zaloguj się' }}
          </Button>
        </form>
        <p class="mt-4 text-center text-xs text-muted-foreground">
          Nie masz konta?
          <RouterLink to="/register" class="text-primary underline-offset-4 hover:underline">
            Zarejestruj się jako trener
          </RouterLink>
        </p>
      </CardContent>
    </Card>
  </div>
</template>
