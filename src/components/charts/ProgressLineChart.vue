<script setup lang="ts">
import { computed } from 'vue'
import {
  CategoryScale,
  Chart as ChartJS,
  Legend,
  LinearScale,
  LineElement,
  PointElement,
  Tooltip,
  type ChartData,
} from 'chart.js'
import { Line } from 'vue-chartjs'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Legend)

const props = defineProps<{
  labels: string[]
  datasets: { label: string; data: (number | null)[]; color?: string }[]
}>()

const palette = ['#2563eb', '#16a34a', '#d97706', '#dc2626', '#7c3aed']

const chartData = computed<ChartData<'line'>>(() => ({
  labels: props.labels,
  datasets: props.datasets.map((ds, index) => {
    const color = ds.color ?? palette[index % palette.length]
    return {
      label: ds.label,
      data: ds.data,
      borderColor: color,
      backgroundColor: color,
      tension: 0.3,
      spanGaps: true,
    }
  }),
}))

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { position: 'bottom' as const },
  },
}
</script>

<template>
  <div class="h-64">
    <Line :data="chartData" :options="chartOptions" />
  </div>
</template>
