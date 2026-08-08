<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { toTypedSchema } from '@vee-validate/zod'
import { useForm } from 'vee-validate'
import { z } from 'zod'
import { toast } from 'vue-sonner'
import { supabase } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

const route = useRoute()
const token = (route.query.token as string) ?? ''

type TokenState = 'checking' | 'valid' | 'invalid'
const tokenState = ref<TokenState>('checking')
const accepted = ref(false)

onMounted(async () => {
  if (!token) {
    tokenState.value = 'invalid'
    return
  }
  const { data, error } = await supabase.rpc('validate_invite_token', { p_token: token })
  const result = data?.[0]
  tokenState.value = !error && result?.is_valid ? 'valid' : 'invalid'
})

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

const submitting = ref(false)

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true
  try {
    const { data, error } = await supabase.auth.signUp({
      email: values.email,
      password: values.password,
      options: { data: { role: 'client', full_name: values.fullName } },
    })
    if (error) throw error
    if (!data.user) throw new Error('Rejestracja nie powiodła się')
    if (!data.session) {
      throw new Error(
        'Konto zostało utworzone, ale wymaga potwierdzenia e-maila zanim będzie można dołączyć do trenera — potwierdź adres e-mail i spróbuj ponownie.',
      )
    }

    const { error: acceptError } = await supabase.rpc('accept_invite', { p_token: token })
    if (acceptError) throw acceptError

    accepted.value = true
  } catch (err) {
    toast.error(err instanceof Error ? err.message : 'Nie udało się dokończyć rejestracji')
  } finally {
    submitting.value = false
  }
})
</script>

<template>
  <div class="flex min-h-svh items-center justify-center bg-muted/30 p-4">
    <Card class="w-full max-w-sm">
      <template v-if="tokenState === 'checking'">
        <CardHeader>
          <CardTitle>Sprawdzanie zaproszenia…</CardTitle>
        </CardHeader>
      </template>

      <template v-else-if="tokenState === 'invalid'">
        <CardHeader>
          <CardTitle>Nieprawidłowy link</CardTitle>
          <CardDescription>
            Ten link zaproszenia jest nieprawidłowy, wygasł lub został już wykorzystany. Poproś trenera o
            nowy link.
          </CardDescription>
        </CardHeader>
      </template>

      <template v-else-if="accepted">
        <CardHeader>
          <CardTitle>Gotowe!</CardTitle>
          <CardDescription>
            Twoje konto zostało utworzone i połączone z trenerem. Możesz teraz zamknąć tę stronę — panel
            podopiecznego pojawi się w kolejnej wersji aplikacji.
          </CardDescription>
        </CardHeader>
      </template>

      <template v-else>
        <CardHeader>
          <CardTitle>Dołącz do trenera</CardTitle>
          <CardDescription>Utwórz konto, aby zostać przypisanym do swojego trenera</CardDescription>
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
              {{ submitting ? 'Tworzenie konta…' : 'Dołącz' }}
            </Button>
          </form>
        </CardContent>
      </template>
    </Card>
  </div>
</template>
