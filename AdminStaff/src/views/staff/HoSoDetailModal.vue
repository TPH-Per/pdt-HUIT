<template>
  <div v-if="show" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4" @click.self="close">
    <div class="bg-white rounded-2xl shadow-xl w-full max-w-4xl max-h-[90vh] flex flex-col overflow-hidden">
      
      <!-- Loading State -->
      <div v-if="loading" class="flex-1 flex flex-col items-center justify-center p-12">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mb-4"></div>
        <p class="text-gray-500">Đang tải thông tin hồ sơ...</p>
      </div>

      <!-- Error State -->
      <div v-else-if="error" class="flex-1 flex flex-col items-center justify-center p-12">
        <div class="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mb-4">
          <AlertTriangle class="w-8 h-8 text-red-600" />
        </div>
        <h3 class="text-lg font-bold text-gray-900 mb-2">Không thể tải hồ sơ</h3>
        <p class="text-gray-500 text-center mb-6">{{ error }}</p>
        <button @click="close" class="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300">
          Đóng
        </button>
      </div>

      <!-- Content -->
      <template v-else-if="hoSo">
        <!-- Header -->
        <div class="bg-blue-600 px-6 py-4 flex justify-between items-start shrink-0">
          <div class="text-white">
            <div class="flex items-center gap-3 mb-1">
              <h2 class="text-xl font-bold">{{ hoSo.maHoSo }}</h2>
              <span class="px-2 py-0.5 bg-white/20 rounded text-sm text-blue-50 font-medium">
                {{ hoSo.trangThaiText }}
              </span>
              <span v-if="hoSo.doUuTien > 0" 
                :class="hoSo.doUuTien === 2 ? 'bg-red-500' : 'bg-orange-500'"
                class="px-2 py-0.5 rounded text-sm font-medium flex items-center gap-1"
              >
                <AlertCircle class="w-3 h-3" />
                {{ hoSo.doUuTien === 2 ? 'Khẩn cấp' : 'Ưu tiên' }}
              </span>
            </div>
            <p class="text-blue-100 text-sm opacity-90">{{ hoSo.tenThuTuc }}</p>
          </div>
          <button @click="close" class="text-white/80 hover:text-white transition p-1 hover:bg-white/10 rounded-lg">
            <X class="w-6 h-6" />
          </button>
        </div>

        <!-- Body with Tabs -->
        <div class="flex-1 overflow-y-auto bg-gray-50 flex flex-col">
          <!-- Main Info Grid -->
          <div class="p-6 grid grid-cols-1 md:grid-cols-3 gap-6">
            
            <!-- Left Column: Citizen Info -->
            <div class="bg-white p-5 rounded-xl shadow-sm border border-gray-100 h-fit">
              <h3 class="font-semibold text-gray-900 mb-4 flex items-center gap-2">
                <User class="w-5 h-5 text-gray-500" />
                Thông tin sinh viên
              </h3>
              <div class="space-y-4">
                <div>
                  <label class="text-xs font-medium text-gray-400 uppercase">Họ và tên</label>
                  <p class="font-medium text-gray-900">{{ hoSo.hoTenSinhVien }}</p>
                </div>
                <div>
                  <label class="text-xs font-medium text-gray-400 uppercase">CCCD/CMND</label>
                  <p class="text-gray-900">{{ hoSo.mssv }}</p>
                </div>
                <div>
                  <label class="text-xs font-medium text-gray-400 uppercase">Số điện thoại</label>
                  <p class="text-gray-900">{{ hoSo.soDienThoai || 'Chưa cập nhật' }}</p>
                </div>
                <div>
                  <label class="text-xs font-medium text-gray-400 uppercase">Email</label>
                  <p class="text-gray-900 break-all">{{ hoSo.email || 'Chưa cập nhật' }}</p>
                </div>
                <div>
                  <label class="text-xs font-medium text-gray-400 uppercase">Địa chỉ</label>
                  <p class="text-gray-900 text-sm">{{ hoSo.diaChi || 'Chưa cập nhật' }}</p>
                </div>
              </div>
            </div>

            <!-- Middle & Right: Document Details & History -->
            <div class="md:col-span-2 space-y-6">
              
              <!-- Processing Info -->
              <div class="bg-white p-5 rounded-xl shadow-sm border border-gray-100">
                <h3 class="font-semibold text-gray-900 mb-4 flex items-center gap-2">
                  <Clock class="w-5 h-5 text-gray-500" />
                  Thông tin xử lý
                </h3>
                <div class="grid grid-cols-2 gap-4">
                  <div class="p-3 bg-gray-50 rounded-lg border border-gray-100">
                    <label class="text-xs text-gray-500 block mb-1">Ngày nộp</label>
                    <div class="font-medium text-gray-900">{{ formatDate(hoSo.ngayNop) }}</div>
                  </div>
                  <div class="p-3 bg-gray-50 rounded-lg border border-gray-100">
                    <label class="text-xs text-gray-500 block mb-1">Hạn xử lý</label>
                    <div :class="isOverdue(hoSo.hanXuLy) ? 'text-red-600' : 'text-gray-900'" class="font-medium">
                      {{ hoSo.hanXuLy ? formatDate(hoSo.hanXuLy) : '--' }}
                    </div>
                  </div>
                  <div class="p-3 bg-gray-50 rounded-lg border border-gray-100 col-span-2">
                     <label class="text-xs text-gray-500 block mb-1">Tiến độ</label>
                     <div class="w-full bg-gray-200 rounded-full h-2.5 mb-1">
                        <div class="bg-blue-600 h-2.5 rounded-full" :style="{ width: getProgressPercent(hoSo.trangThai) + '%' }"></div>
                     </div>
                     <div class="flex justify-between text-xs text-gray-500">
                        <span>Tiếp nhận</span>
                        <span>Hoàn thành</span>
                     </div>
                  </div>
                </div>
              </div>

               <!-- Notes -->
               <div v-if="hoSo.ghiChu" class="bg-yellow-50 p-4 rounded-xl border border-yellow-200">
                  <h4 class="font-medium text-yellow-800 text-sm mb-1 flex items-center gap-2">
                    <StickyNote class="w-4 h-4" /> Ghi chú
                  </h4>
                  <p class="text-yellow-900 text-sm">{{ hoSo.ghiChu }}</p>
               </div>

              <!-- History Timeline -->
              <div class="bg-white p-5 rounded-xl shadow-sm border border-gray-100">
                <h3 class="font-semibold text-gray-900 mb-4 flex items-center gap-2">
                  <History class="w-5 h-5 text-gray-500" />
                  Lịch sử xử lý
                </h3>
                
                <div class="relative pl-4 border-l-2 border-gray-200 space-y-6">
                  <div v-for="(log, idx) in hoSo.lichSuXuLy" :key="idx" class="relative">
                    <div class="absolute -left-[21px] top-1 w-3 h-3 rounded-full border-2 border-white shadow-sm"
                      :class="getLogColor(log.hanhDong)">
                    </div>
                    <div class="mb-1 flex items-center gap-2">
                      <span class="font-medium text-sm text-gray-900">
                        {{ getActionText(log.hanhDong) }}
                        <span v-if="log.trangThaiCu && log.trangThaiMoi && log.trangThaiCu !== log.trangThaiMoi" class="text-xs font-normal text-gray-500 ml-1">
                            ({{ log.trangThaiCu }} &rarr; {{ log.trangThaiMoi }})
                        </span>
                      </span>
                      <span class="text-xs text-gray-400">{{ formatDateTime(log.thoiGian) }}</span>
                    </div>
                    <p class="text-sm text-gray-600 bg-gray-50 p-2 rounded-lg inline-block min-w-[200px]">
                      {{ log.noiDung }}
                    </p>
                    <div class="mt-1 text-xs text-gray-400 flex items-center gap-1">
                      <User class="w-3 h-3" /> {{ log.nguoiXuLy }}
                    </div>
                  </div>
                </div>
              </div>

            </div>
          </div>
        </div>

        <!-- Footer Actions -->
        <div class="bg-white px-6 py-4 border-t border-gray-200 flex justify-between items-center shrink-0">
          <button @click="close" class="px-5 py-2.5 border border-gray-300 text-gray-700 font-medium rounded-lg hover:bg-gray-50 transition">
            Đóng
          </button>
          
          <div class="flex gap-3" v-if="hoSo.trangThai < 4">
            <button 
              @click="$emit('updateStatus', hoSo)"
              class="px-5 py-2.5 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 transition shadow-sm flex items-center gap-2"
            >
              Cập nhật trạng thái <ArrowRight class="w-4 h-4" />
            </button>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import { X, User, Clock, History, AlertTriangle, AlertCircle, StickyNote, ArrowRight } from 'lucide-vue-next'
import { hoSoApi, type HoSoDetailData, type HoSoData } from '@/services/api'

const props = defineProps<{
  show: boolean
  hoSoId: number | null
}>()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'updateStatus', hoSo: HoSoData): void
}>()

const loading = ref(false)
const error = ref('')
const hoSo = ref<HoSoDetailData | null>(null)

const fetchDetail = async () => {
  if (!props.hoSoId) return
  
  loading.value = true
  error.value = ''
  hoSo.value = null
  
  try {
    const response = await hoSoApi.getById(props.hoSoId)
    if (response.data.success) {
      hoSo.value = response.data.data
    }
  } catch (err: any) {
    error.value = err.response?.data?.message || 'Không thể tải chi tiết hồ sơ'
  } finally {
    loading.value = false
  }
}

watch(() => props.show, (newVal) => {
  if (newVal && props.hoSoId) {
    fetchDetail()
  }
})

onMounted(() => {
  if (props.show && props.hoSoId) {
    fetchDetail()
  }
})


const close = () => {
  emit('close')
}

// Helpers
const formatDate = (dateStr: string) => {
  if (!dateStr) return '--'
  return new Date(dateStr).toLocaleDateString('vi-VN')
}

const formatDateTime = (dateStr: string) => {
  if (!dateStr) return '--'
  return new Date(dateStr).toLocaleString('vi-VN')
}

const isOverdue = (hanXuLy: string | null) => {
  if (!hanXuLy) return false
  return new Date(hanXuLy) < new Date()
}

const getProgressPercent = (status: number) => {
  switch (status) {
    case 2: return 20; // Đang tiếp nhận
    case 3: return 60; // Chờ gọi số
    case 6: return 50; // Bổ sung
    case 4: return 100; // Hoàn thành
    case 0: return 100; // Hủy
    default: return 0;
  }
}

const getLogColor = (action: string) => {
  const act = action?.toUpperCase() || ''
  
  // Success / Create / Complete
  if (['TẠO HỒ SƠ', 'TAO_MOI', 'HOÀN THÀNH', 'CREATE', 'COMPLETE', 'TAO_TU_LICH_HEN'].some(k => act.includes(k))) 
    return 'bg-green-500'
    
  // Warning / Pending / Supplement / Reschedule
  if (['YÊU CẦU BỔ SUNG', 'BỔ SUNG', 'RESCHEDULE', 'SUPPLEMENT', 'PENDING'].some(k => act.includes(k))) 
    return 'bg-yellow-500'
    
  // Info / Processing / Call / Receive
  if (['CHUYỂN GỌI SỐ', 'ĐANG XỬ LÝ', 'CẬP NHẬT TRẠNG THÁI', 'GỌI SỐ', 'CALL_NUMBER', 'RECEIVE', 'CHUYEN_TRANG_THAI'].some(k => act.includes(k))) 
    return 'bg-blue-500'
    
  // Error / Cancel
  if (['HỦY', 'CANCEL', 'REJECT'].some(k => act.includes(k))) 
    return 'bg-red-500'
    
  return 'bg-gray-400'
}

const getActionText = (action: string) => {
  if (!action) return ''
  const act = action.toUpperCase()
  
  const map: Record<string, string> = {
    'TAO_MOI': 'Tạo mới hồ sơ',
    'CREATE': 'Tạo mới',
    'TAO_TU_LICH_HEN': 'Tạo từ lịch hẹn',
    'CHUYEN_TRANG_THAI': 'Chuyển trạng thái',
    'CAP_NHAT': 'Cập nhật thông tin',
    'RESCHEDULE': 'Hẹn lại / Bổ sung',
    'SUPPLEMENT': 'Yêu cầu bổ sung',
    'COMPLETE': 'Hoàn thành hồ sơ',
    'CANCEL': 'Hủy hồ sơ',
    'RECEIVE': 'Tiếp nhận hồ sơ',
    'CALL_NUMBER': 'Gọi số',
    'GỌI SỐ': 'Gọi số'
  }
  
  // Custom checks for dynamic or unmapped actions
  if (act.includes('GỌI SỐ')) return 'Gọi số'
  if (act === 'CREATE') {
      // Check context logic if needed, but 'Tạo mới' is safe
      return 'Tạo hồ sơ'
  }

  return map[act] || action
}
</script>
