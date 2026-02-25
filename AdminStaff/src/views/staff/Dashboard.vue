<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Tổng quan</h1>
        <p class="text-sm text-gray-500 mt-1">
          Xin chào, <span class="font-semibold text-blue-600">{{ dashboardData?.tenCanBo }}</span>
          · Quầy <span class="font-semibold">{{ dashboardData?.tenQuay }}</span>
          · {{ todayLabel }}
        </p>
      </div>
      <button
        @click="fetchData"
        :disabled="loading"
        class="flex items-center gap-2 px-4 py-2 text-sm bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors"
      >
        <RefreshCw :class="['h-4 w-4', loading ? 'animate-spin' : '']" />
        Làm mới
      </button>
    </div>

    <!-- Loading Skeleton -->
    <div v-if="loading" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <div v-for="i in 4" :key="i" class="bg-white p-6 rounded-xl shadow-sm border border-gray-100 animate-pulse">
        <div class="h-12 w-12 bg-gray-200 rounded-lg mb-4"></div>
        <div class="h-8 w-16 bg-gray-200 rounded mb-2"></div>
        <div class="h-4 w-24 bg-gray-200 rounded"></div>
      </div>
    </div>

    <!-- Stats Cards -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <div
        v-for="(stat, idx) in stats"
        :key="idx"
        class="bg-white p-6 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow"
      >
        <div class="flex justify-between items-start mb-4">
          <div :class="['p-3 rounded-lg', stat.color]">
            <component :is="stat.icon" class="h-6 w-6 text-white" />
          </div>
          <span
            :class="['flex items-center text-xs font-medium px-2 py-1 rounded-full',
              stat.trendPositive ? 'text-green-600 bg-green-50' : 'text-orange-600 bg-orange-50']"
          >
            <component :is="stat.trendPositive ? TrendingUp : TrendingDown" class="h-3 w-3 mr-1" />
            {{ stat.trend }}
          </span>
        </div>
        <h3 class="text-3xl font-bold text-gray-900 mb-1">{{ stat.value }}</h3>
        <p class="text-sm text-gray-500">{{ stat.label }}</p>
      </div>
    </div>

    <!-- Queue + Info -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Current Queue from API -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
        <h3 class="font-bold text-lg mb-4 flex items-center gap-2">
          <ListOrdered class="h-5 w-5 text-blue-600" />
          Hàng chờ hiện tại
          <span v-if="!loadingQueue" class="ml-auto text-xs text-gray-400 font-normal">
            {{ queueItems.length }} người chờ
          </span>
        </h3>

        <!-- Loading -->
        <div v-if="loadingQueue" class="space-y-3">
          <div v-for="i in 3" :key="i" class="h-14 bg-gray-100 rounded-lg animate-pulse"></div>
        </div>

        <!-- Empty -->
        <div v-else-if="queueItems.length === 0" class="text-center py-8 text-gray-400">
          <ListOrdered class="h-10 w-10 mx-auto mb-2 opacity-30" />
          <p class="text-sm">Hàng chờ trống</p>
        </div>

        <!-- Items -->
        <div v-else class="space-y-3 max-h-72 overflow-y-auto pr-1">
          <div
            v-for="item in queueItems"
            :key="item.id"
            class="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-blue-50 transition-colors"
          >
            <div class="flex items-center gap-3">
              <span class="font-mono font-bold text-base text-blue-600 min-w-[60px]">
                {{ item.queueDisplay || item.requestCode?.slice(-6) }}
              </span>
              <div>
                <p class="font-medium text-gray-900 text-sm">{{ item.studentName }}</p>
                <p class="text-xs text-gray-500">{{ item.serviceName }}</p>
              </div>
            </div>
            <span :class="['px-2 py-1 rounded text-xs font-medium whitespace-nowrap', item.statusClass]">
              {{ item.status }}
            </span>
          </div>
        </div>

        <router-link
          to="/staff/queue"
          class="mt-4 flex items-center justify-center gap-2 w-full py-2 text-sm text-blue-600 hover:bg-blue-50 rounded-lg transition-colors border border-blue-100"
        >
          <ExternalLink class="h-4 w-4" />
          Quản lý hàng chờ
        </router-link>
      </div>

      <!-- Hourly Chart -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
        <h3 class="font-bold text-lg mb-4 flex items-center gap-2">
          <BarChart3 class="h-5 w-5 text-blue-600" />
          Tóm tắt hôm nay
        </h3>
        <div class="space-y-4">
          <div
            v-for="item in summaryItems"
            :key="item.label"
            class="flex items-center gap-4"
          >
            <div :class="['p-2 rounded-lg', item.bg]">
              <component :is="item.icon" :class="['h-5 w-5', item.iconColor]" />
            </div>
            <div class="flex-1">
              <div class="flex justify-between items-center mb-1">
                <span class="text-sm font-medium text-gray-700">{{ item.label }}</span>
                <span class="text-lg font-bold text-gray-900">{{ item.value }}</span>
              </div>
              <div class="w-full bg-gray-100 rounded-full h-1.5">
                <div
                  :class="['h-1.5 rounded-full transition-all duration-700', item.barColor]"
                  :style="{ width: `${Math.min((item.value / Math.max(maxSummary, 1)) * 100, 100)}%` }"
                ></div>
              </div>
            </div>
          </div>
        </div>

        <!-- Error State -->
        <div v-if="error" class="mt-4 p-3 bg-red-50 rounded-lg text-sm text-red-600 flex items-center gap-2">
          <AlertCircle class="h-4 w-4 shrink-0" />
          {{ error }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import {
  Users,
  Clock,
  CheckCircle,
  TrendingUp,
  TrendingDown,
  ListOrdered,
  BarChart3,
  RefreshCw,
  ExternalLink,
  AlertCircle,
  XCircle,
  FileText
} from 'lucide-vue-next'
import { hoSoApi, queueApi } from '@/services/api'

// const router = useRouter() - removed to fix unused warning

// State
const loading = ref(true)
const loadingQueue = ref(true)
const error = ref('')
const dashboardData = ref<any>(null)
const queueData = ref<any>(null)

// Today label
const todayLabel = computed(() => {
  return new Date().toLocaleDateString('vi-VN', {
    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
  })
})

// Stats computed from API
const stats = computed(() => {
  const d = dashboardData.value
  if (!d) return []
  return [
    {
      label: 'Đã xử lý xong',
      value: d.hoanThanh ?? 0,
      icon: CheckCircle,
      color: 'bg-green-500',
      trend: d.hoanThanh > 0 ? `+${d.hoanThanh}` : '0',
      trendPositive: true
    },
    {
      label: 'Đang xử lý',
      value: d.dangXuLy ?? 0,
      icon: Clock,
      color: 'bg-blue-500',
      trend: 'Live',
      trendPositive: true
    },
    {
      label: 'Hồ sơ trễ hạn',
      value: d.treHan ?? 0,
      icon: XCircle,
      color: 'bg-red-500',
      trend: d.treHan > 0 ? 'Cần xử lý' : 'Tốt',
      trendPositive: d.treHan === 0
    },
    {
      label: 'Tổng chờ hôm nay',
      value: queueData.value?.totalWaiting ?? (d.choXuLy ?? 0),
      icon: Users,
      color: 'bg-purple-500',
      trend: 'Hôm nay',
      trendPositive: true
    }
  ]
})

// Queue items from API
const queueItems = computed(() => {
  const d = queueData.value
  if (!d) return []

  const items = []

  // Current processing
  if (d.currentProcessing) {
    items.push({
      ...d.currentProcessing,
      status: 'Đang xử lý',
      statusClass: 'bg-blue-100 text-blue-700'
    })
  }

  // Waiting list (max 5)
  const waiting = (d.waitingList ?? []).slice(0, 5)
  waiting.forEach((w: any) => {
    items.push({
      ...w,
      status: 'Chờ gọi',
      statusClass: 'bg-yellow-100 text-yellow-700'
    })
  })

  return items
})

// Summary bar items
const summaryItems = computed(() => {
  const d = dashboardData.value
  const q = queueData.value
  if (!d) return []

  return [
    {
      label: 'Đã xử lý xong',
      value: d.hoanThanh ?? 0,
      icon: CheckCircle,
      bg: 'bg-green-50',
      iconColor: 'text-green-600',
      barColor: 'bg-green-500'
    },
    {
      label: 'Đang xử lý',
      value: d.dangXuLy ?? 0,
      icon: Clock,
      bg: 'bg-blue-50',
      iconColor: 'text-blue-600',
      barColor: 'bg-blue-500'
    },
    {
      label: 'Đang chờ trong queue',
      value: q?.totalWaiting ?? 0,
      icon: Users,
      bg: 'bg-purple-50',
      iconColor: 'text-purple-600',
      barColor: 'bg-purple-500'
    },
    {
      label: 'Hồ sơ trễ hạn',
      value: d.treHan ?? 0,
      icon: FileText,
      bg: 'bg-red-50',
      iconColor: 'text-red-600',
      barColor: 'bg-red-500'
    }
  ]
})

const maxSummary = computed(() =>
  Math.max(...summaryItems.value.map(i => i.value), 1)
)

// Fetch data
async function fetchData() {
  loading.value = true
  loadingQueue.value = true
  error.value = ''

  try {
    const [dashRes, queueRes] = await Promise.all([
      hoSoApi.getDashboard(),
      queueApi.getDashboard()
    ])
    dashboardData.value = dashRes.data
    queueData.value = queueRes.data
  } catch (e: any) {
    error.value = e?.response?.data?.message || 'Không thể tải dữ liệu dashboard'
    console.error('Dashboard error:', e)
  } finally {
    loading.value = false
    loadingQueue.value = false
  }
}

onMounted(fetchData)
</script>
