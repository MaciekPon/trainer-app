import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  // BASE_URL odzwierciedla `base` z vite.config.ts — na GitHub Pages
  // to /trainer-app/, lokalnie /.
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', redirect: '/dashboard' },
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/auth/LoginView.vue'),
      meta: { public: true },
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('@/views/auth/RegisterView.vue'),
      meta: { public: true },
    },
    {
      path: '/accept-invite',
      name: 'accept-invite',
      component: () => import('@/views/auth/AcceptInviteView.vue'),
      meta: { public: true },
    },
    {
      path: '/dashboard',
      name: 'dashboard',
      component: () => import('@/views/DashboardView.vue'),
    },
    {
      path: '/clients/:clientId',
      name: 'client-detail',
      component: () => import('@/views/clients/ClientDetailView.vue'),
      props: true,
    },
    {
      path: '/clients/:clientId/plans/:planId',
      name: 'plan-editor',
      component: () => import('@/views/plans/PlanEditorView.vue'),
      props: true,
    },
    {
      path: '/clients/:clientId/progress',
      name: 'client-progress',
      component: () => import('@/views/progress/ProgressView.vue'),
      props: true,
    },
  ],
})

router.beforeEach(async (to) => {
  const auth = useAuthStore()
  await auth.init()

  if (to.meta.public) {
    return true
  }

  if (!auth.session) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }

  return true
})

export default router
