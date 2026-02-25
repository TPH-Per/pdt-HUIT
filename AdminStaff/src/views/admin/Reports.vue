<template>
  <div class="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500 max-w-[1600px] mx-auto pb-10">
    
    <!-- Header Section with Stats -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
      <!-- Main Title Card -->
      <div class="md:col-span-4 lg:col-span-1 rounded-xl bg-gradient-to-br from-indigo-600 to-violet-600 p-6 text-white shadow-lg flex flex-col justify-between">
        <div>
          <h1 class="text-2xl font-bold tracking-tight">Quản lý Phản ánh</h1>
          <p class="text-indigo-100 mt-1 text-sm">Tiếp nhận và xử lý ý kiến sinh viên</p>
        </div>
        <div class="mt-4 flex items-center gap-2">
           <div class="p-2 bg-white/20 backdrop-blur-sm rounded-lg">
             <MessageSquare class="h-6 w-6 text-white" />
           </div>
           <div class="text-3xl font-bold">{{ feedbacks.length }}</div>
           <span class="text-sm text-indigo-200">Tổng số phản ánh</span>
        </div>
      </div>

      <!-- Quick Stats -->
      <div class="bg-white rounded-xl p-4 shadow-sm border border-indigo-50 flex items-center gap-4 hover:shadow-md transition-shadow">
        <div class="h-12 w-12 rounded-full bg-blue-50 flex items-center justify-center text-blue-600">
           <Inbox class="h-6 w-6" />
        </div>
        <div>
           <p class="text-sm text-gray-500 font-medium">Mới gửi</p>
           <h3 class="text-2xl font-bold text-gray-900">{{ countStatus(0) }}</h3>
        </div>
      </div>

      <div class="bg-white rounded-xl p-4 shadow-sm border border-indigo-50 flex items-center gap-4 hover:shadow-md transition-shadow">
        <div class="h-12 w-12 rounded-full bg-amber-50 flex items-center justify-center text-amber-600">
           <Loader2 class="h-6 w-6" />
        </div>
        <div>
           <p class="text-sm text-gray-500 font-medium">Đang xử lý</p>
           <h3 class="text-2xl font-bold text-gray-900">{{ countStatus(1) }}</h3>
        </div>
      </div>

      <div class="bg-white rounded-xl p-4 shadow-sm border border-indigo-50 flex items-center gap-4 hover:shadow-md transition-shadow">
        <div class="h-12 w-12 rounded-full bg-green-50 flex items-center justify-center text-green-600">
           <CheckCircle2 class="h-6 w-6" />
        </div>
        <div>
           <p class="text-sm text-gray-500 font-medium">Đã giải quyết</p>
           <h3 class="text-2xl font-bold text-gray-900">{{ countStatus(2) }}</h3>
        </div>
      </div>
    </div>

    <!-- Main Content Tab & Table -->
    <Card class="border-none shadow-lg overflow-hidden bg-white/80 backdrop-blur-sm">
       <div class="border-b px-6 py-4 flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white/50">
          <!-- Custom Tabs -->
          <div class="flex p-1 bg-gray-100/80 rounded-lg gap-1">
             <button
               v-for="tab in tabs"
               :key="tab.value"
               @click="currentTab = tab.value"
               class="px-4 py-2 text-sm font-medium rounded-md transition-all duration-200"
               :class="currentTab === tab.value 
                  ? 'bg-white text-indigo-600 shadow-sm' 
                  : 'text-gray-500 hover:text-gray-900 hover:bg-gray-200/50'"
             >
               {{ tab.label }}
             </button>
          </div>

          <Button variant="outline" size="sm" @click="fetchList" :disabled="loading" class="gap-2 border-dashed">
            <RefreshCw class="w-4 h-4" :class="{ 'animate-spin': loading }" />
            Làm mới
          </Button>
       </div>
       
       <CardContent class="p-0">
          <DataTable 
             v-if="!loading"
             :columns="columns" 
             :data="feedbacks" 
             search-placeholder="Tìm kiếm theo tên, tiêu đề, mã hồ sơ..."
             class="border-none"
          />
          <div v-else class="h-64 flex items-center justify-center">
             <div class="flex flex-col items-center gap-2">
                <Loader2 class="h-8 w-8 animate-spin text-indigo-500" />
                <span class="text-sm text-gray-500">Đang tải dữ liệu...</span>
             </div>
          </div>
       </CardContent>
    </Card>

    <!-- Detail Modal -->
    <TransitionRoot appear :show="!!selectedFeedback" as="template">
      <Dialog as="div" @close="selectedFeedback = null" class="relative z-50">
        <TransitionChild
          as="template"
          enter="duration-300 ease-out"
          enter-from="opacity-0"
          enter-to="opacity-100"
          leave="duration-200 ease-in"
          leave-from="opacity-100"
          leave-to="opacity-0"
        >
          <div class="fixed inset-0 bg-black/60 backdrop-blur-sm" />
        </TransitionChild>

        <div class="fixed inset-0 overflow-y-auto">
          <div class="flex min-h-full items-center justify-center p-4 text-center">
            <TransitionChild
              as="template"
              enter="duration-300 ease-out"
              enter-from="opacity-0 scale-95"
              enter-to="opacity-100 scale-100"
              leave="duration-200 ease-in"
              leave-from="opacity-100 scale-100"
              leave-to="opacity-0 scale-95"
            >
              <DialogPanel class="w-full max-w-4xl transform overflow-hidden rounded-2xl bg-white shadow-2xl transition-all flex flex-col max-h-[90vh]">
                 <!-- Modal Header -->
                 <div class="px-6 py-4 border-b flex justify-between items-center bg-gray-50/50 sticky top-0 z-10">
                    <div class="flex items-center gap-3">
                       <div class="h-10 w-10 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-600">
                          <FileText class="w-5 h-5" />
                       </div>
                       <div class="text-left">
                          <DialogTitle as="h3" class="text-lg font-bold text-gray-900">
                             Chi tiết phản ánh #{{ selectedFeedback?.id }}
                          </DialogTitle>
                          <p class="text-xs text-gray-500">Gửi lúc {{ formatDate(selectedFeedback?.createdAt || '') }}</p>
                       </div>
                    </div>
                    <button @click="selectedFeedback = null" class="p-2 rounded-full hover:bg-gray-200 text-gray-500 transition-colors">
                       <X class="w-5 h-5" />
                    </button>
                 </div>

                 <!-- Modal Body -->
                 <div class="flex-1 overflow-y-auto p-0">
                    <div class="grid grid-cols-1 md:grid-cols-3 min-h-[400px]">
                       
                       <!-- Left Column: Info & Content -->
                       <div class="md:col-span-2 p-6 space-y-6">
                          <!-- Citizen Card -->
                           <div class="bg-gradient-to-r from-blue-50/50 to-indigo-50/50 p-4 rounded-xl border border-blue-100 flex gap-4 items-start">
                             <div class="h-12 w-12 rounded-full bg-white border-2 border-blue-200 shadow-sm flex items-center justify-center text-xl font-bold text-blue-600 shrink-0">
                                {{ selectedFeedback?.studentName.charAt(0) }}
                             </div>
                             <div class="flex-1 text-left">
                                <h4 class="font-bold text-gray-900 text-lg">{{ selectedFeedback?.studentName }}</h4>
                                <div class="flex flex-wrap gap-x-4 gap-y-1 mt-1 text-sm text-gray-600">
                                   <span class="flex items-center gap-1"><CreditCard class="w-3.5 h-3.5" /> {{ selectedFeedback?.studentId }}</span>
                                   <span v-if="selectedFeedback?.requestCode" class="flex items-center gap-1 bg-white px-2 rounded-md border shadow-sm text-xs font-mono text-indigo-600"><Hash class="w-3 h-3" /> {{ selectedFeedback?.requestCode }}</span>
                                </div>
                             </div>
                             <Badge :variant="getStatusVariant(selectedFeedback?.status || 0)" class="uppercase text-[10px] tracking-wider">
                                {{ getStatusLabel(selectedFeedback?.status || 0) }}
                             </Badge>
                           </div>

                           <!-- Content Block -->
                           <div class="space-y-3 text-left">
                              <h5 class="text-sm font-semibold text-gray-900 border-l-4 border-indigo-500 pl-3">Nội dung phản ánh</h5>
                              <div class="bg-gray-50 rounded-xl p-5 text-gray-700 leading-relaxed border border-gray-100 shadow-inner">
                                 <h6 class="font-bold mb-2 text-gray-900">{{ selectedFeedback?.title }}</h6>
                                 <p class="whitespace-pre-line">{{ selectedFeedback?.content }}</p>
                              </div>
                           </div>
                       </div>

                       <!-- Right Column: Timeline & Actions -->
                       <div class="bg-gray-50/50 border-l p-6 flex flex-col">
                          <h5 class="text-sm font-semibold text-gray-900 mb-4 flex items-center gap-2">
                             <History class="w-4 h-4 text-indigo-500" /> Timeline xử lý
                          </h5>

                          <div class="flex-1 overflow-y-auto space-y-6 pr-2 mb-4 custom-scrollbar">
                             <!-- Original Post -->
                             <div class="relative pl-6 border-l-2 border-gray-200">
                                <div class="absolute -left-[5px] top-0 h-2.5 w-2.5 rounded-full bg-gray-300 ring-4 ring-white"></div>
                                <div class="text-left">
                                   <p class="text-xs text-gray-500 mb-1">{{ formatDate(selectedFeedback?.createdAt || '') }}</p>
                                   <p class="text-sm font-medium text-gray-900">Người dân gửi phản ánh</p>
                                </div>
                             </div>

                             <!-- Replies -->
                             <div v-for="reply in selectedFeedback?.replies" :key="reply.id" class="relative pl-6 border-l-2 border-indigo-200 last:border-0 last:pb-0">
                                <div class="absolute -left-[5px] top-0 h-2.5 w-2.5 rounded-full bg-indigo-500 ring-4 ring-white"></div>
                                <div class="text-left bg-white p-3 rounded-lg border shadow-sm">
                                   <div class="flex justify-between items-start mb-2">
                                      <span class="font-bold text-xs text-indigo-700 bg-indigo-50 px-2 py-0.5 rounded-full line-clamp-1">{{ reply.registrarName }}</span>
                                      <span class="text-[10px] text-gray-400 shrink-0">{{ formatDate(reply.createdAt) }}</span>
                                   </div>
                                   <p class="text-xs text-gray-600">{{ reply.content }}</p>
                                </div>
                             </div>
                          </div>

                          <!-- Reply Input -->
                          <div class="mt-auto space-y-3 pt-4 border-t sticky bottom-0">
                             <label class="text-xs font-semibold text-gray-700 uppercase tracking-wide block text-left">Phản hồi / Xử lý</label>
                             <textarea 
                               v-model="replyContent" 
                               rows="3" 
                               class="w-full text-sm p-3 rounded-lg border border-gray-200 bg-white focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-shadow resize-none shadow-sm"
                               placeholder="Nhập nội dung xử lý..."
                             ></textarea>
                             <Button 
                                @click="submitReply" 
                                :disabled="!replyContent.trim() || submitting"
                                class="w-full bg-indigo-600 hover:bg-indigo-700 text-white shadow-md shadow-indigo-200 disabled:shadow-none"
                             >
                                <Loader2 v-if="submitting" class="w-4 h-4 mr-2 animate-spin" />
                                {{ submitting ? 'Đang gửi...' : 'Gửi phản hồi' }}
                             </Button>
                          </div>
                       </div>
                    </div>
                 </div>
              </DialogPanel>
            </TransitionChild>
          </div>
        </div>
      </Dialog>
    </TransitionRoot>

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch, h } from 'vue'
import { feedbackApi, type Feedback } from '@/services/api'
import { 
  RefreshCw, Eye, X, MessageSquare, FileText, CreditCard, 
  Loader2, Inbox, CheckCircle2, Hash, History 
} from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import {
  TransitionRoot,
  TransitionChild,
  Dialog,
  DialogPanel,
  DialogTitle,
} from '@headlessui/vue'

// UI Components
import Card from '@/components/ui/card/Card.vue'
import CardContent from '@/components/ui/card/CardContent.vue'
import Button from '@/components/ui/button/Button.vue'
import Badge from '@/components/ui/badge/Badge.vue'
import DataTable from '@/components/ui/data-table/DataTable.vue'
import type { ColumnDef } from '@tanstack/vue-table'

const loading = ref(false)
const submitting = ref(false)
const feedbacks = ref<Feedback[]>([])
const currentTab = ref<number | undefined>(undefined)
const selectedFeedback = ref<Feedback | null>(null)
const replyContent = ref('')

const tabs = [
  { label: 'Tất cả', value: undefined },
  { label: 'Mới gửi', value: 0 },
  { label: 'Đang xử lý', value: 1 },
  { label: 'Đã giải quyết', value: 2 },
]

// Stats Helpers
const countStatus = (status: number) => {
   // Since API filters backend side, we might need a separate stats API call
   // For now, if currentTab is 'undefined' (All), we can count from local. 
   // But standard way is backend returns stats. 
   // We will just filter client side for better UX if the list is loaded fully, 
   // OR we accept that this number updates only when "All" is loaded.
   // Let's assume we load ALL for stats for this demo if feasible, or just return '...'
   if (currentTab.value === undefined) {
      return feedbacks.value.filter(f => f.status === status).length
   }
   return '...' 
}

// Table Config
const columns: ColumnDef<Feedback>[] = [
  {
    accessorKey: 'id',
    header: 'ID',
    cell: ({ row }) => h('div', { class: 'font-mono text-xs font-bold text-gray-500' }, `#${row.getValue('id')}`),
  },
  {
    accessorKey: 'studentName',
    header: 'Người dân',
    cell: ({ row }) => h('div', { class: 'flex items-center gap-3' }, [
        h('div', { class: 'h-8 w-8 rounded-full bg-gradient-to-br from-blue-100 to-indigo-100 flex items-center justify-center text-indigo-700 font-bold text-xs ring-2 ring-white shadow-sm' }, 
            (row.original.studentName?.charAt(0) || 'U').toUpperCase()),
        h('div', { class: 'flex flex-col' }, [
            h('span', { class: 'font-semibold text-gray-900 text-sm' }, row.original.studentName),
            h('span', { class: 'text-[11px] text-gray-500 font-mono' }, row.original.studentId)
        ])
    ]),
  },
  {
     accessorKey: 'type',
     header: 'Loại phản ánh',
     cell: ({ row }) => {
        const type = row.original.type
        // Force red color for Khiếu nại (1) explicitly if needed, but variant='destructive' should handle it.
        // We add explicit red class just in case theme differs.
        const isComplaint = type === 1
        return h(Badge, { 
            variant: getTypeVariant(type), 
            class: isComplaint 
                ? 'w-fit text-[11px] px-2 py-0.5 h-6 bg-red-600 hover:bg-red-700 text-white border-0' 
                : 'w-fit text-[11px] px-2 py-0.5 h-6' 
        }, () => getTypeLabel(type))
     }
  },
  {
     accessorKey: 'title',
     header: 'Tiêu đề',
     cell: ({ row }) => h('div', { class: 'font-medium text-gray-900 truncate max-w-[200px]', title: row.getValue('title') }, row.getValue('title') || 'Không tiêu đề')
  },
  {
     accessorKey: 'status',
     header: 'Trạng thái',
     cell: ({ row }) => {
        const status = row.getValue('status') as number
        return h(Badge, { variant: getStatusVariant(status), class: 'shadow-sm' }, () => getStatusLabel(status))
     }
  },
  {
     accessorKey: 'createdAt',
     header: 'Thời gian',
     cell: ({ row }) => h('div', { class: 'flex flex-col text-xs text-gray-500' }, [
         h('span', { class: 'font-medium' }, formatDate(row.getValue('createdAt')).split(' ')[0]), // Date
         h('span', {}, formatDate(row.getValue('createdAt')).split(' ')[1] + ' ' + formatDate(row.getValue('createdAt')).split(' ')[2]) // Time
     ])
  },
  {
     id: 'actions',
     header: () => h('div', { class: 'text-right' }, 'Thao tác'),
     cell: ({ row }) => {
        return h('div', { class: 'flex justify-end' }, 
            h(Button, { 
                variant: 'ghost', 
                size: 'icon',
                class: 'h-8 w-8 text-indigo-600 bg-indigo-50 hover:bg-indigo-100 hover:text-indigo-700 rounded-full',
                title: 'Xem chi tiết',
                onClick: () => openDetail(row.original)
            }, () => h(Eye, { class: 'h-4 w-4' }))
        )
     }
  }
]

const fetchList = async () => {
    loading.value = true
    try {
        const res = await feedbackApi.getList(currentTab.value)
        if (res.data.success) {
            feedbacks.value = res.data.data || []
        }
    } catch (e) {
        toast.error('Không thể tải danh sách')
    } finally {
        loading.value = false
    }
}

const openDetail = (item: Feedback) => {
    selectedFeedback.value = item
    replyContent.value = ''
}

const submitReply = async () => {
    if (!selectedFeedback.value || !replyContent.value.trim()) return
    
    submitting.value = true
    try {
        const res = await feedbackApi.reply(selectedFeedback.value.id, replyContent.value)
        if (res.data.success) {
            toast.success('Gửi phản hồi thành công')
            
            const updated = res.data.data
            // Update local state
            const idx = feedbacks.value.findIndex(f => f.id === updated.id)
            if (idx !== -1) feedbacks.value[idx] = updated
            selectedFeedback.value = updated
            replyContent.value = ''
            
            // If viewing specific filtered tab, refresh might be needed or manually handle logic
            // For simple UX, if status changed, it might disappear from current tab (e.g. New -> Processing)
            // But we keep it visible in modal. 
            if (currentTab.value !== undefined) {
               fetchList()
            }
        }
    } catch (e) {
        toast.error('Gửi thất bại')
    } finally {
        submitting.value = false
    }
}

watch(currentTab, () => {
    fetchList()
})

onMounted(() => {
    fetchList()
})

// Utilities
const formatDate = (str: string) => {
    if (!str) return ''
    try {
       return new Date(str).toLocaleString('vi-VN', {
         day: '2-digit', month: '2-digit', year: 'numeric',
         hour: '2-digit', minute: '2-digit'
       })
    } catch { return str }
}

const getTypeLabel = (type: number) => {
    switch(type) {
        case 0: return 'Góp ý'
        case 1: return 'Khiếu nại'
        case 2: return 'Khen ngợi'
        default: return 'Khác'
    }
}

const getTypeVariant = (type: number) => {
     switch(type) {
        case 0: return 'info' // Blue
        case 1: return 'destructive' // Red
        case 2: return 'success' // Green
        default: return 'secondary'
    }
}

const getStatusLabel = (status: number) => {
    switch(status) {
        case 0: return 'Mới'
        case 1: return 'Đang xử lý'
        case 2: return 'Đã giải quyết'
        default: return 'Không rõ'
    }
}

const getStatusVariant = (status: number) => {
    switch(status) {
        case 0: return 'info'
        case 1: return 'warning'
        case 2: return 'success'
        default: return 'secondary'
    }
}
</script>

<style scoped>
/* Custom Scrollbar for timeline */
.custom-scrollbar::-webkit-scrollbar {
  width: 4px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: #e5e7eb;
  border-radius: 20px;
}
</style>
