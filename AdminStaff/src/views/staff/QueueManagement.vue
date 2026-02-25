<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Quản lý hàng chờ</h1>
        <p class="text-gray-500 mt-1" v-if="dashboard">
          {{ dashboard.deskName }} ({{ dashboard.deskCode }})
        </p>
      </div>
      <button
        @click="refreshData"
        :disabled="loading"
        class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition disabled:opacity-50"
      >
        <RefreshCw :class="{ 'animate-spin': loading }" class="w-4 h-4" />
        Làm mới
      </button>
    </div>

    <!-- Error Alert -->
    <div v-if="error" class="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start gap-3">
      <AlertCircle class="w-5 h-5 text-red-500 mt-0.5" />
      <div>
        <p class="text-red-800 font-medium">Có lỗi xảy ra</p>
        <p class="text-red-600 text-sm">{{ error }}</p>
      </div>
      <button @click="error = ''" class="ml-auto text-red-500 hover:text-red-700">
        <X class="w-4 h-4" />
      </button>
    </div>

    <!-- Statistics Cards -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
      <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-500">Đang chờ</p>
            <p class="text-3xl font-bold text-blue-600">{{ dashboard?.totalWaiting ?? 0 }}</p>
          </div>
          <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
            <Users class="w-6 h-6 text-blue-600" />
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-500">Hoàn thành</p>
            <p class="text-3xl font-bold text-green-600">{{ dashboard?.totalCompleted ?? 0 }}</p>
          </div>
          <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
            <CheckCircle class="w-6 h-6 text-green-600" />
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-500">Vắng mặt/Hủy</p>
            <p class="text-3xl font-bold text-red-600">{{ dashboard?.totalCancelled ?? 0 }}</p>
          </div>
          <div class="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
            <XCircle class="w-6 h-6 text-red-600" />
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-500">TB xử lý</p>
            <p class="text-3xl font-bold text-purple-600">
              {{ dashboard?.averageProcessingTime ? `${dashboard.averageProcessingTime}'` : '--' }}
            </p>
          </div>
          <div class="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center">
            <Clock class="w-6 h-6 text-purple-600" />
          </div>
        </div>
      </div>
    </div>

    <!-- Main Content: 2 columns -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Left: Current Processing & Actions -->
      <div class="lg:col-span-1 space-y-4">
        <!-- Current Processing Card -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
          <div class="bg-gradient-to-r from-blue-600 to-blue-700 px-5 py-4">
            <h2 class="text-white font-semibold flex items-center gap-2">
              <Play class="w-5 h-5" />
              Đang phục vụ
            </h2>
          </div>
          
          <div class="p-5">
            <!-- No current processing -->
            <div v-if="!currentProcessing" class="text-center py-8">
              <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <UserX class="w-8 h-8 text-gray-400" />
              </div>
              <p class="text-gray-500">Chưa có lượt nào đang xử lý</p>
              <button
                @click="callNext"
                :disabled="actionLoading || (dashboard?.totalWaiting ?? 0) === 0"
                class="mt-4 w-full py-3 bg-green-600 text-white rounded-lg font-medium hover:bg-green-700 transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                <PhoneCall class="w-5 h-5" />
                Gọi số tiếp theo
              </button>
            </div>

            <!-- Has current processing -->
            <div v-else class="space-y-4">
              <!-- Number Display -->
              <div class="text-center">
                <div class="inline-block bg-gradient-to-r from-blue-500 to-blue-600 text-white px-8 py-4 rounded-2xl">
                  <span class="text-4xl font-bold">{{ currentProcessing.queueDisplay }}</span>
                </div>
              </div>

              <!-- Customer Info -->
              <div class="space-y-2">
                <div class="flex items-center gap-2 text-gray-700">
                  <User class="w-4 h-4 text-gray-400" />
                  <span class="font-medium">{{ currentProcessing.studentName }}</span>
                </div>
                <div class="flex items-center gap-2 text-gray-600 text-sm">
                  <CreditCard class="w-4 h-4 text-gray-400" />
                  <span>{{ currentProcessing.studentId }}</span>
                </div>
                <div class="flex items-center gap-2 text-gray-600 text-sm">
                  <FileText class="w-4 h-4 text-gray-400" />
                  <span>{{ currentProcessing.serviceName }}</span>
                </div>
                <div v-if="currentProcessing.createdAt" class="flex items-center gap-2 text-gray-600 text-sm">
                  <Clock class="w-4 h-4 text-gray-400" />
                  <span>Tạo lúc: {{ formatTime(currentProcessing.createdAt) }}</span>
                </div>
              </div>

              <!-- Action Buttons -->
              <!-- Action Buttons -->
              <div class="grid grid-cols-2 gap-3 pt-4 border-t">
                <!-- 1. Tiếp nhận hồ sơ -->
                <button
                  @click="handleReceiveHoSo"
                  :disabled="actionLoading"
                  class="py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  <FilePlus class="w-5 h-5" />
                  Tiếp nhận
                </button>

                <!-- 2. Hẹn bổ sung -->
                <button
                  @click="handleReschedule"
                  :disabled="actionLoading"
                  class="py-3 bg-amber-500 text-white rounded-lg font-medium hover:bg-amber-600 transition disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  <CalendarPlus class="w-5 h-5" />
                  Hẹn bổ sung
                </button>

                <!-- 3. Đã hoàn thành -->
                <button
                  @click="completeProcessing"
                  :disabled="actionLoading"
                  class="py-3 bg-green-600 text-white rounded-lg font-medium hover:bg-green-700 transition disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  <CheckSquare class="w-5 h-5" />
                  Hoàn thành
                </button>

                <!-- 4. Hủy / Vắng mặt -->
                <button
                  @click="showCancelModal = true"
                  :disabled="actionLoading"
                  class="py-3 bg-red-600 text-white rounded-lg font-medium hover:bg-red-700 transition disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  <XCircle class="w-5 h-5" />
                  Hủy / Vắng
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Call Next Button (when processing) -->
        <button
          v-if="currentProcessing"
          @click="callNext"
          :disabled="actionLoading || (dashboard?.totalWaiting ?? 0) === 0"
          class="w-full py-3 bg-blue-600 text-white rounded-xl font-medium hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
        >
          <PhoneCall class="w-5 h-5" />
          Hoàn thành & Gọi số tiếp
        </button>
      </div>

      <!-- Right: Waiting List -->
      <div class="lg:col-span-2">
        <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
          <div class="bg-gray-50 px-5 py-4 border-b flex items-center justify-between">
            <h2 class="font-semibold text-gray-800 flex items-center gap-2">
              <Users class="w-5 h-5 text-gray-600" />
              Danh sách chờ
            </h2>
            <span class="bg-blue-100 text-blue-700 px-3 py-1 rounded-full text-sm font-medium">
              {{ waitingList.length }} người
            </span>
          </div>

          <!-- Empty State -->
          <div v-if="waitingList.length === 0" class="p-8 text-center">
            <div class="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <Inbox class="w-10 h-10 text-gray-400" />
            </div>
            <p class="text-gray-500 text-lg">Hàng chờ trống</p>
            <p class="text-gray-400 text-sm mt-1">Không có sinh viên nào đang chờ</p>
          </div>

          <!-- Waiting List Table -->
          <div v-else class="overflow-x-auto">
            <table class="w-full">
              <thead class="bg-gray-50 border-b">
                <tr>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">STT</th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Họ tên</th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Thủ tục</th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Trạng thái</th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Giờ hẹn</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr
                  v-for="(item, index) in waitingList"
                  :key="item.id"
                  @click="callSpecific(item.id)"
                  :class="[
                     index === 0 ? 'bg-blue-50' : 'hover:bg-gray-50',
                     actionLoading ? 'cursor-not-allowed opacity-50' : 'cursor-pointer'
                  ]"
                  class="transition group"
                  :title="item.currentPhase === 2 ? 'Khách chưa check-in. Nhấn để gọi ngay.' : 'Nhấn để gọi số này'"
                >
                  <td class="px-4 py-4">
                    <span
                      :class="index === 0 ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-700 group-hover:bg-blue-100 group-hover:text-blue-700'"
                      class="inline-flex items-center justify-center w-10 h-10 rounded-full font-bold transition-colors"
                    >
                      {{ item.queueDisplay || '---' }}
                    </span>
                  </td>
                  <td class="px-4 py-4">
                    <div class="font-medium text-gray-900">{{ item.studentName }}</div>
                    <div class="text-sm text-gray-500">{{ item.studentId }}</div>
                  </td>
                  <td class="px-4 py-4">
                    <div class="text-gray-700 line-clamp-2" :title="item.serviceName">{{ item.serviceName }}</div>
                  </td>
                  <td class="px-4 py-4">
                    <span v-if="item.currentPhase === 3" class="px-2 py-1 bg-green-100 text-green-700 rounded-full text-xs font-bold whitespace-nowrap border border-green-200">
                        Đã lấy số
                    </span>
                    <span v-else-if="item.currentPhase === 2" class="px-2 py-1 bg-yellow-100 text-yellow-700 rounded-full text-xs font-bold whitespace-nowrap border border-yellow-200">
                        Chưa check-in
                    </span>
                    <span v-else-if="item.currentPhase === 6" class="px-2 py-1 bg-orange-100 text-orange-700 rounded-full text-xs font-bold whitespace-nowrap border border-orange-200">
                        Bổ sung hồ sơ
                    </span>
                    <span v-else class="text-gray-500 text-xs">{{ item.phaseName }}</span>
                  </td>
                  <td class="px-4 py-4 text-gray-600 font-mono text-sm">
                    {{ item.expectedTime ? item.expectedTime.substring(0, 5) : '--:--' }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>

    <!-- Cancel Modal -->
    <div
      v-if="showCancelModal"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      @click.self="showCancelModal = false"
    >
      <div class="bg-white rounded-xl shadow-lg w-full max-w-md p-6">
        <h3 class="text-lg font-bold text-gray-900 mb-4">Hủy lượt / Khách vắng mặt</h3>
        
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Lý do</label>
            <textarea
              v-model="cancelReason"
              rows="3"
              class="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
              placeholder="Nhập lý do hủy..."
            ></textarea>
          </div>

          <div class="flex items-center gap-4">
            <label class="flex items-center gap-2 cursor-pointer">
              <input type="radio" v-model="cancelStatus" :value="3" class="text-blue-600" />
              <span>Khách vắng mặt</span>
            </label>
            <label class="flex items-center gap-2 cursor-pointer">
              <input type="radio" v-model="cancelStatus" :value="4" class="text-blue-600" />
              <span>Hủy vì lý do khác</span>
            </label>
          </div>
        </div>

        <div class="flex justify-end gap-3 mt-6">
          <button
            @click="showCancelModal = false"
            class="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg transition"
          >
            Đóng
          </button>
          <button
            @click="handleCancel"
            :disabled="actionLoading"
            class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition disabled:opacity-50"
          >
            Xác nhận Hủy
          </button>
        </div>
      </div>
    </div>

    <!-- Receive Modal (Tiếp nhận) -->
    <div
      v-if="showReceiveModal"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      @click.self="showReceiveModal = false"
    >
      <div class="bg-white rounded-xl shadow-lg w-full max-w-md p-6">
        <h3 class="text-lg font-bold text-gray-900 mb-4">Tiếp nhận hồ sơ</h3>
        <p class="text-sm text-gray-500 mb-4">Vui lòng nhập thông tin hẹn trả kết quả (nếu có)</p>
        
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Ngày hẹn trả</label>
            <input
              v-model="receiveForm.appointmentDate"
              type="date"
              class="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Giờ hẹn trả</label>
            <input
              v-model="receiveForm.expectedTime"
              type="time"
              class="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
            />
          </div>
        </div>

        <div class="flex justify-end gap-3 mt-6">
          <button
            @click="showReceiveModal = false"
            class="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg transition"
          >
            Hủy bỏ
          </button>
          <button
            @click="confirmReceive"
            :disabled="actionLoading"
            class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition disabled:opacity-50 flex items-center gap-2"
          >
            <FilePlus class="w-4 h-4" />
            Tiếp nhận & Tạo hồ sơ
          </button>
        </div>
      </div>
    </div>

    <!-- Supplement Modal -->
    <div
      v-if="showSupplementModal"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      @click.self="showSupplementModal = false"
    >
      <div class="bg-white rounded-xl shadow-lg w-full max-w-2xl p-6 max-h-[90vh] overflow-y-auto">
        <h3 class="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
          <CalendarPlus class="w-5 h-5 text-amber-500" />
          Đặt lịch hẹn bổ sung
        </h3>
        
        <div class="space-y-6">
          <!-- Date Selection -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Ngày hẹn</label>
            <input
              v-model="supplementDate"
              type="date"
              class="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-amber-500 outline-none"
              :min="new Date().toISOString().split('T')[0]"
              @change="fetchSlots"
            />
          </div>

          <!-- Slots Selection -->
          <div v-if="slotLoading" class="py-8 text-center text-gray-500">
            <Loader class="w-8 h-8 animate-spin mx-auto mb-2" />
            Đang tải khung giờ...
          </div>
          
          <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Morning -->
            <div>
              <h4 class="font-medium text-gray-700 mb-3 flex items-center gap-2">
                <Sun class="w-4 h-4" /> Buổi sáng
              </h4>
              <div class="grid grid-cols-3 gap-2">
                <button
                  v-for="slot in slots.morning"
                  :key="slot.time"
                  @click="!slot.booked && selectSlot(slot.time)"
                  :disabled="slot.booked"
                  :class="[
                    slot.booked 
                        ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                        : supplementTime === slot.time
                            ? 'bg-amber-500 text-white ring-2 ring-amber-300'
                            : 'bg-white border hover:border-amber-500 text-gray-700',
                    'px-2 py-2 rounded text-sm transition text-center'
                  ]"
                >
                  {{ slot.time.substring(0, 5) }}
                </button>
              </div>
            </div>

            <!-- Afternoon -->
            <div>
              <h4 class="font-medium text-gray-700 mb-3 flex items-center gap-2">
                <Moon class="w-4 h-4" /> Buổi chiều
              </h4>
              <div class="grid grid-cols-3 gap-2">
                <button
                  v-for="slot in slots.afternoon"
                  :key="slot.time"
                  @click="!slot.booked && selectSlot(slot.time)"
                  :disabled="slot.booked"
                  :class="[
                    slot.booked 
                        ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                        : supplementTime === slot.time
                            ? 'bg-amber-500 text-white ring-2 ring-amber-300'
                            : 'bg-white border hover:border-amber-500 text-gray-700',
                    'px-2 py-2 rounded text-sm transition text-center'
                  ]"
                >
                  {{ slot.time.substring(0, 5) }}
                </button>
              </div>
            </div>
          </div>
        </div>

        <div class="flex justify-end gap-3 mt-8 pt-4 border-t">
          <button
            @click="showSupplementModal = false"
            class="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg transition"
          >
            Hủy bỏ
          </button>
          <button
            @click="confirmSupplement"
            :disabled="!supplementTime || actionLoading"
            class="px-4 py-2 bg-amber-500 text-white rounded-lg hover:bg-amber-600 transition disabled:opacity-50 flex items-center gap-2"
          >
            <Check class="w-4 h-4" />
            Xác nhận hẹn
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import {
  User, CreditCard, FileText, AlertCircle, X, Inbox,
  FilePlus, CalendarPlus, CheckSquare, PhoneCall, Users, XCircle,
  Sun, Moon, Check, Loader,
  RefreshCw, CheckCircle, Clock, Play, UserX
} from 'lucide-vue-next'
import { useRouter } from 'vue-router'
import { queueApi, type QueueDashboardData } from '@/services/api'
import Swal from 'sweetalert2'
import { useToast } from 'vue-toastification'

// State
const router = useRouter()
const toast = useToast()
const loading = ref(false)
const actionLoading = ref(false)
const error = ref('')
const dashboard = ref<QueueDashboardData | null>(null)

// Modal state
const showCancelModal = ref(false)
const cancelReason = ref('')
const cancelStatus = ref(0) // Default: CANCEL_NO_SHOW (0) - Check backend constant

const showReceiveModal = ref(false)
const receiveForm = ref({
  appointmentDate: new Date().toISOString().split('T')[0], // Default today
  expectedTime: '17:00'
})

// Supplement Modal
const showSupplementModal = ref(false)
const supplementDate = ref('')
const supplementTime = ref('')
const slotLoading = ref(false)
const slots = ref<{
    morning: { time: string; booked: boolean }[];
    afternoon: { time: string; booked: boolean }[];
}>({ morning: [], afternoon: [] })

// Computed
const currentProcessing = computed(() => dashboard.value?.currentProcessing ?? null)
const waitingList = computed(() => dashboard.value?.waitingList ?? [])

// Auto refresh interval
let refreshInterval: number | null = null

// Methods
// Button Actions
const handleReceiveHoSo = () => {
    if (!currentProcessing.value) return;
    // Open modal instead of direct action
    showReceiveModal.value = true;
}

const confirmReceive = async () => {
    if (!currentProcessing.value) return;
    
    actionLoading.value = true;
    error.value = '';

    try {
        // Gọi API chuyển trạng thái sang RECEIVED kèm ngày hẹn
        const response = await queueApi.receive(currentProcessing.value.id, {
           appointmentDate: receiveForm.value.appointmentDate,
           expectedTime: receiveForm.value.expectedTime
        });
        
        if (response.data.success) {
            showReceiveModal.value = false;
             // Chuyển hướng sang trang Quản lý hồ sơ để cập nhật thông tin
             router.push({
                name: 'HoSoManagement',
                query: {
                    view: 'true',
                    id: currentProcessing.value.id.toString()
                }
            });
        } else {
             error.value = response.data.message;
        }
    } catch (err: any) {
        error.value = err.response?.data?.message || 'Không thể tiếp nhận hồ sơ';
    } finally {
        actionLoading.value = false;
    }
}



const refreshData = async () => {
  loading.value = true
  error.value = ''
  
  try {
    const response = await queueApi.getDashboard()
    if (response.data.success) {
      dashboard.value = response.data.data
    } else {
      error.value = response.data.message
    }
  } catch (err: any) {
    error.value = err.response?.data?.message || 'Không thể tải dữ liệu hàng chờ'
  } finally {
    loading.value = false
  }
}

const callNext = async () => {
  actionLoading.value = true
  error.value = ''
  
  try {
    // If currently processing, complete first
    if (currentProcessing.value) {
      await queueApi.complete(currentProcessing.value.id)
    }
    
    // Call next (first in queue)
    const response = await queueApi.callNext()
    if (response.data.success) {
      await refreshData()
    } else {
      error.value = response.data.message
    }
  } catch (err: any) {
    error.value = err.response?.data?.message || 'Không thể gọi số tiếp theo'
  } finally {
    actionLoading.value = false
  }
}

const callSpecific = async (id: number) => {
    if (actionLoading.value) return;
    
    // Confirm with SweetAlert2
    const result = await Swal.fire({
        title: 'Gọi hồ sơ này?',
        text: 'Bạn có chắc muốn gọi hồ sơ này (không theo thứ tự)?',
        icon: 'question',
        showCancelButton: true,
        confirmButtonColor: '#3085d6',
        cancelButtonColor: '#d33',
        confirmButtonText: 'Đồng ý',
        cancelButtonText: 'Hủy'
    });
    
    if (!result.isConfirmed) return;
    
    actionLoading.value = true;
    error.value = '';

    try {
        // If currently processing, complete first
        if (currentProcessing.value) {
            await queueApi.complete(currentProcessing.value.id);
        }

        // Call specific
        const response = await queueApi.callNext(id);
        if (response.data.success) {
            toast.success('Đã gọi số thành công!');
            await refreshData();
        } else {
            toast.error(response.data.message || 'Có lỗi xảy ra');
        }
    } catch (err: any) {
        toast.error(err.response?.data?.message || 'Không thể gọi hồ sơ này');
    } finally {
        actionLoading.value = false;
    }
}

const completeProcessing = async () => {
  if (!currentProcessing.value) return
  
  actionLoading.value = true
  error.value = ''
  
  try {
    const response = await queueApi.complete(currentProcessing.value.id)
    if (response.data.success) {
      await refreshData()
    } else {
      error.value = response.data.message
    }
  } catch (err: any) {
    error.value = err.response?.data?.message || 'Không thể hoàn thành'
  } finally {
    actionLoading.value = false
  }
}

const handleCancel = async () => {
  if (!currentProcessing.value || !cancelReason.value.trim()) return
  
  actionLoading.value = true
  error.value = ''
  
  try {
    const response = await queueApi.cancel(
      currentProcessing.value.id,
      cancelReason.value.trim(),
      cancelStatus.value
    )
    if (response.data.success) {
      showCancelModal.value = false
      cancelReason.value = ''
      cancelStatus.value = 0 // Reset to default
      await refreshData()
    } else {
      error.value = response.data.message
    }
  } catch (err: any) {
    error.value = err.response?.data?.message || 'Không thể hủy'
  } finally {
    actionLoading.value = false
  }
}

const handleReschedule = () => {
    // Set default date = tomorrow
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    supplementDate.value = tomorrow.toISOString().split('T')[0];
    supplementTime.value = '';
    showSupplementModal.value = true;
    fetchSlots();
}

const fetchSlots = async () => {
    if (!supplementDate.value) return;
    slotLoading.value = true;
    try {
        const res = await queueApi.getSlots(supplementDate.value);
        if (res.data.success) {
            slots.value = res.data.data;
        }
    } catch (e) {
        console.error(e);
    } finally {
        slotLoading.value = false;
    }
}

const selectSlot = (time: string) => {
    supplementTime.value = time;
}

const confirmSupplement = async () => {
    if (!currentProcessing.value || !supplementDate.value || !supplementTime.value) return;
    actionLoading.value = true;
    try {
        const res = await queueApi.supplement(currentProcessing.value.id, {
            appointmentDate: supplementDate.value,
            appointmentTime: supplementTime.value
        });
        if (res.data.success) {
             showSupplementModal.value = false;
             await refreshData();
        }
    } catch (e: any) {
         error.value = e.response?.data?.message || 'Lỗi đặt lịch hẹn';
    } finally {
        actionLoading.value = false;
    }
}

const formatTime = (dateTimeStr: string) => {
  if (!dateTimeStr) return '--:--'
  const date = new Date(dateTimeStr)
  return date.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
}

// Lifecycle
onMounted(() => {
  refreshData()
  // Auto refresh every 30 seconds
  refreshInterval = window.setInterval(refreshData, 30000)
})

onUnmounted(() => {
  if (refreshInterval) {
    clearInterval(refreshInterval)
  }
})
</script>
