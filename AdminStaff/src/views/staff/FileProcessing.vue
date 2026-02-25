<template>
  <div class="space-y-8 p-6 animate-fade-in-up">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
      <div>
        <h1 class="text-3xl font-bold bg-gradient-to-r from-blue-700 to-indigo-700 bg-clip-text text-transparent">
          Xử lý hồ sơ
        </h1>
        <p class="text-gray-500 mt-2 font-medium">Tiếp nhận và xử lý hồ sơ hành chính</p>
      </div>
      <div class="flex gap-3">
        <button
          @click="showCreateModal = true"
          class="group flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-green-600 to-emerald-600 text-white rounded-xl shadow-lg shadow-green-500/30 hover:shadow-green-500/40 hover:-translate-y-0.5 transition-all duration-300 font-medium"
        >
          <Plus :size="20" class="group-hover:rotate-90 transition-transform duration-300" />
          Tạo hồ sơ mới
        </button>
        <button
          @click="refreshData"
          :disabled="loading"
          class="flex items-center gap-2 px-5 py-2.5 bg-white text-blue-600 border border-blue-100 rounded-xl hover:bg-blue-50 transition-all font-medium disabled:opacity-50"
        >
          <RefreshCw :class="{ 'animate-spin': loading }" :size="20" />
          Làm mới
        </button>
      </div>
    </div>

    <!-- Filter Tabs -->
    <div class="flex flex-wrap gap-2 p-1.5 bg-gray-100/50 rounded-2xl border border-gray-200">
      <button
        v-for="tab in statusTabs"
        :key="tab.value ?? 'all'"
        @click="filterStatus = tab.value"
        :class="[
          'px-5 py-2.5 rounded-xl font-medium transition-all duration-200 flex items-center gap-2.5 text-sm',
          filterStatus === tab.value 
            ? 'bg-white text-blue-600 shadow-md shadow-gray-200 ring-1 ring-black/5' 
            : 'text-gray-500 hover:text-gray-700 hover:bg-white/50'
        ]"
      >
        {{ tab.label }}
        <span 
          v-if="tab.count > 0"
          :class="[
            'px-2 py-0.5 rounded-full text-xs font-bold',
             filterStatus === tab.value ? 'bg-blue-50 text-blue-600' : 'bg-gray-200 text-gray-500'
          ]"
        >
          {{ tab.count }}
        </span>
      </button>
    </div>

    <!-- Document List -->
    <div class="bg-white rounded-2xl shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden">
      <!-- Loading State -->
      <div v-if="loading" class="p-12 text-center">
        <div class="inline-block animate-spin rounded-full h-10 w-10 border-4 border-blue-600 border-t-transparent"></div>
        <p class="mt-4 text-gray-500 font-medium">Đang tải danh sách hồ sơ...</p>
      </div>

      <!-- Empty State -->
      <div v-else-if="filteredList.length === 0" class="p-24 text-center">
        <div class="w-24 h-24 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-6">
          <FileText class="w-12 h-12 text-gray-300" />
        </div>
        <h3 class="text-xl font-bold text-gray-900">Không có hồ sơ nào</h3>
        <p class="text-gray-500 mt-2">Danh sách hồ sơ trống hoặc không tìm thấy kết quả phù hợp</p>
      </div>

      <!-- Table -->
      <div v-else class="overflow-x-auto">
        <table class="w-full">
          <thead class="bg-gray-50/50 border-b border-gray-100">
            <tr>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Mã hồ sơ</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Sinh viên</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Thủ tục</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Trạng thái</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Hạn xử lý</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Thao tác</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-50">
            <tr
              v-for="hoSo in filteredList"
              :key="hoSo.id"
              class="hover:bg-blue-50/30 transition-colors duration-200 group"
            >
              <!-- Mã hồ sơ -->
              <td class="px-6 py-4">
                <div class="font-mono font-semibold text-blue-600 bg-blue-50 px-2 py-1 rounded inline-block">
                  {{ hoSo.maHoSo }}
                </div>
                <div class="text-xs text-gray-500 mt-1.5 flex items-center gap-1">
                  <!-- Note: Clock icon needs to be imported if used -->
                  {{ formatDate(hoSo.ngayNop) }}
                </div>
              </td>
              
              <!-- Sinh viên -->
              <td class="px-6 py-4">
                <div class="font-semibold text-gray-900">{{ hoSo.hoTenSinhVien }}</div>
                <div class="text-sm text-gray-500 font-mono mt-0.5">{{ hoSo.mssv }}</div>
              </td>
              
              <!-- Thủ tục -->
              <td class="px-6 py-4">
                <div class="text-gray-900 font-medium line-clamp-2 max-w-xs" :title="hoSo.tenThuTuc">{{ hoSo.tenThuTuc }}</div>
                <div class="text-xs text-gray-400 mt-1 flex items-center gap-1">
                   <div class="w-1.5 h-1.5 rounded-full bg-gray-300"></div>
                   {{ hoSo.nguonGoc }}
                </div>
              </td>
              
              <!-- Trạng thái -->
              <td class="px-6 py-4">
                 <div class="flex flex-col gap-1.5 items-start">
                   <span :class="getStatusClass(hoSo.trangThai)" class="px-3 py-1 rounded-full text-xs font-bold border">
                    {{ hoSo.trangThaiText }}
                  </span>
                  <span v-if="hoSo.doUuTien > 0" :class="hoSo.doUuTien === 2 ? 'bg-red-100 text-red-700 border-red-200' : 'bg-orange-100 text-orange-700 border-orange-200'" class="px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wide border">
                    {{ hoSo.doUuTien === 2 ? 'Khẩn cấp' : 'Ưu tiên' }}
                  </span>
                 </div>
              </td>
              
              <!-- Hạn xử lý -->
              <td class="px-6 py-4">
                <div :class="isOverdue(hoSo.hanXuLy) ? 'text-red-600 font-semibold' : 'text-gray-700 font-medium'">
                  {{ hoSo.hanXuLy ? formatDate(hoSo.hanXuLy) : '--' }}
                </div>
                <div v-if="isOverdue(hoSo.hanXuLy)" class="text-xs text-red-500 font-bold mt-1 flex items-center gap-1">
                  <AlertCircle :size="12" /> Quá hạn
                </div>
              </td>
              
              <!-- Thao tác -->
              <td class="px-6 py-4">
                <div class="flex items-center gap-2 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity">
                  <button
                    @click="viewDetail(hoSo)"
                    class="p-2 text-blue-600 bg-blue-50 hover:bg-blue-100 hover:text-blue-700 rounded-lg transition-all duration-200 shadow-sm"
                    title="Xem chi tiết"
                  >
                    <Eye :size="18" />
                  </button>
                  <button
                    v-if="hoSo.trangThai < 4"
                    @click="openStatusModal(hoSo)"
                    class="p-2 text-green-600 bg-green-50 hover:bg-green-100 hover:text-green-700 rounded-lg transition-all duration-200 shadow-sm"
                    title="Cập nhật trạng thái"
                  >
                    <ArrowRight :size="18" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Detail Modal -->
    <HoSoDetailModal
      :show="showDetailModal"
      :ho-so-id="selectedDetailId"
      @close="showDetailModal = false"
      @update-status="handleUpdateStatusFromDetail"
    />

    <!-- Create Modal -->
    <div
      v-if="showCreateModal"
      class="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50 animate-fade-in"
      @click.self="showCreateModal = false"
    >
      <div class="bg-white rounded-2xl shadow-2xl w-full max-w-lg mx-4 overflow-hidden max-h-[90vh] overflow-y-auto transform transition-all scale-100">
        <div class="bg-gradient-to-r from-green-600 to-emerald-600 px-6 py-4">
          <h3 class="text-white font-bold text-lg flex items-center gap-2">
            <Plus :size="20" /> Tạo hồ sơ mới
          </h3>
          <p class="text-green-100 text-sm mt-1">Nhập thông tin tiếp nhận hồ sơ</p>
        </div>
        
        <div class="p-6 space-y-6">
          <div class="grid grid-cols-2 gap-4">
            <div class="col-span-2">
              <label class="block text-sm font-bold text-gray-700 mb-1.5">MSSV <span class="text-red-500">*</span></label>
              <input v-model="createForm.mssv" type="text" maxlength="10" 
                class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500/20 focus:border-green-500 transition-all outline-none" placeholder="Nhập MSSV">
            </div>
            <div class="col-span-2">
              <label class="block text-sm font-bold text-gray-700 mb-1.5">Họ tên sinh viên <span class="text-red-500">*</span></label>
              <input v-model="createForm.hoTen" type="text"
                class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500/20 focus:border-green-500 transition-all outline-none" placeholder="Nhập họ và tên">
            </div>
            <div>
              <label class="block text-sm font-bold text-gray-700 mb-1.5">Số điện thoại</label>
              <input v-model="createForm.soDienThoai" type="text"
                class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500/20 focus:border-green-500 transition-all outline-none" placeholder="09xxxxxxxxx">
            </div>
            <div>
              <label class="block text-sm font-bold text-gray-700 mb-1.5">Email</label>
              <input v-model="createForm.email" type="email"
                class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500/20 focus:border-green-500 transition-all outline-none" placeholder="example@gmail.com">
            </div>
            <div class="col-span-2">
              <label class="block text-sm font-bold text-gray-700 mb-1.5">Loại thủ tục <span class="text-red-500">*</span></label>
              <select v-model="createForm.loaiThuTucId"
                class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500/20 focus:border-green-500 transition-all outline-none bg-white">
                <option :value="null">-- Chọn thủ tục hành chính --</option>
                <option v-for="tt in thuTucList" :key="tt.id" :value="tt.id">{{ tt.serviceName }}</option>
              </select>
            </div>
            <div class="col-span-2">
              <label class="block text-sm font-bold text-gray-700 mb-1.5">Độ ưu tiên</label>
              <select v-model="createForm.doUuTien"
                class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500/20 focus:border-green-500 transition-all outline-none bg-white">
                <option :value="0">Bình thường</option>
                <option :value="1">Ưu tiên</option>
                <option :value="2">Khẩn cấp</option>
              </select>
            </div>
            <div class="col-span-2">
              <label class="block text-sm font-bold text-gray-700 mb-1.5">Ghi chú</label>
              <textarea v-model="createForm.ghiChu" rows="2"
                class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500/20 focus:border-green-500 transition-all outline-none resize-none" placeholder="Ghi chú thêm..."></textarea>
            </div>

            <!-- Dynamic Fields -->
            <div class="col-span-2 border-t border-gray-100 pt-4 mt-2">
              <div class="flex justify-between items-center mb-3">
                <label class="block text-sm font-bold text-gray-700">Thông tin bổ sung</label>
                <button @click="addDynamicField" type="button" class="text-xs bg-gray-100 hover:bg-gray-200 text-gray-700 px-3 py-1.5 rounded-lg font-medium transition-colors">
                  + Thêm trường
                </button>
              </div>
              <div class="space-y-3">
                <div v-for="(field, idx) in dynamicFields" :key="idx" class="flex gap-3 animate-fade-in">
                  <input v-model="field.key" placeholder="Tên trường (ví dụ: Số ĐKKD)" class="flex-1 text-sm border border-gray-300 rounded-lg px-3 py-2 outline-none focus:border-green-500">
                  <input v-model="field.value" placeholder="Giá trị" class="flex-1 text-sm border border-gray-300 rounded-lg px-3 py-2 outline-none focus:border-green-500">
                  <button @click="removeDynamicField(idx)" class="text-red-400 hover:text-red-600 transition-colors p-1">
                    <X :size="18" />
                  </button>
                </div>
                <p v-if="dynamicFields.length === 0" class="text-xs text-center text-gray-400 italic py-2 bg-gray-50 rounded-lg border border-dashed border-gray-200">
                  Chưa có thông tin bổ sung
                </p>
              </div>
            </div>

            <!-- Attachments -->
            <div class="col-span-2 border-t border-gray-100 pt-4">
              <div class="flex justify-between items-center mb-3">
                <label class="block text-sm font-bold text-gray-700">File đính kèm</label>
                <button @click="addAttachment" type="button" class="text-xs bg-gray-100 hover:bg-gray-200 text-gray-700 px-3 py-1.5 rounded-lg font-medium transition-colors">
                  + Thêm file
                </button>
              </div>
              <div class="space-y-3">
                <div v-for="(file, idx) in attachments" :key="idx" class="flex gap-3 animate-fade-in">
                  <input v-model="file.tenFile" placeholder="Tên file" class="flex-1 text-sm border border-gray-300 rounded-lg px-3 py-2 outline-none focus:border-green-500">
                  <input v-model="file.url" placeholder="URL / Ghi chú" class="flex-1 text-sm border border-gray-300 rounded-lg px-3 py-2 outline-none focus:border-green-500">
                  <button @click="removeAttachment(idx)" class="text-red-400 hover:text-red-600 transition-colors p-1">
                    <X :size="18" />
                  </button>
                </div>
                <p v-if="attachments.length === 0" class="text-xs text-center text-gray-400 italic py-2 bg-gray-50 rounded-lg border border-dashed border-gray-200">
                  Chưa có file đính kèm
                </p>
              </div>
            </div>
          </div>
        </div>
        <div class="bg-gray-50 p-6 flex gap-3 justify-end border-t border-gray-100">
          <button @click="showCreateModal = false" class="px-5 py-2.5 border border-gray-300 rounded-xl text-gray-700 font-medium hover:bg-white hover:shadow-sm transition-all">
            Hủy bỏ
          </button>
          <button @click="submitCreateHoSo" :disabled="actionLoading" class="px-5 py-2.5 bg-gradient-to-r from-green-600 to-emerald-600 text-white rounded-xl shadow-lg shadow-green-500/30 hover:shadow-green-500/40 hover:-translate-y-0.5 transition-all duration-300 font-bold disabled:opacity-50">
            {{ actionLoading ? 'Đang xử lý...' : 'Tạo hồ sơ' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Status Update Modal -->
    <div
      v-if="showStatusModal && selectedHoSo"
      class="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50 animate-fade-in"
      @click.self="showStatusModal = false"
    >
      <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md mx-4 overflow-hidden transform transition-all scale-100">
        <div class="bg-gradient-to-r from-blue-600 to-indigo-600 px-6 py-4">
          <h3 class="text-white font-bold text-lg">Cập nhật trạng thái</h3>
          <p class="text-blue-100 text-sm mt-1 font-mono opacity-90">{{ selectedHoSo.maHoSo }}</p>
        </div>
        <div class="p-6 space-y-5">
          <div>
            <label class="block text-sm font-bold text-gray-700 mb-2">Trạng thái mới</label>
            <select v-model="statusForm.trangThaiMoi"
              class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none bg-white">
              <option :value="1">Đang xử lý</option>
              <option :value="2">Cần bổ sung</option>
              <option :value="4">Hoàn thành</option>
              <option :value="5">Từ chối</option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-bold text-gray-700 mb-2">Ghi chú / Lý do</label>
            <textarea v-model="statusForm.noiDung" rows="4"
              class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none resize-none"
              placeholder="Nhập nội dung chi tiết..."></textarea>
          </div>
        </div>
        <div class="bg-gray-50 p-6 flex gap-3 justify-end border-t border-gray-100">
          <button @click="showStatusModal = false" class="px-5 py-2.5 border border-gray-300 rounded-xl text-gray-700 font-medium hover:bg-white hover:shadow-sm transition-all">
            Hủy bỏ
          </button>
          <button @click="submitUpdateStatus" :disabled="actionLoading" class="px-5 py-2.5 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-xl shadow-lg shadow-blue-500/30 hover:shadow-blue-500/40 hover:-translate-y-0.5 transition-all duration-300 font-bold disabled:opacity-50">
            {{ actionLoading ? 'Đang cập nhật...' : 'Xác nhận' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import {
  RefreshCw, Plus, FileText, AlertCircle, X, Eye, ArrowRight
} from 'lucide-vue-next'
import { hoSoApi, publicLoaiThuTucApi, type HoSoData, type LoaiThuTucData } from '@/services/api'
import { useToast } from "vue-toastification";
import HoSoDetailModal from './HoSoDetailModal.vue'

// State
const loading = ref(false)
const actionLoading = ref(false)
const hoSoList = ref<HoSoData[]>([])
const filterStatus = ref<number | null>(null)
const thuTucList = ref<LoaiThuTucData[]>([])
const toast = useToast();

// Modals
const showCreateModal = ref(false)
const showStatusModal = ref(false)
const showDetailModal = ref(false)
const selectedHoSo = ref<HoSoData | null>(null)
const selectedDetailId = ref<number | null>(null)

// Forms
const createForm = ref({
  mssv: '',
  hoTen: '',
  soDienThoai: '',
  email: '',
  loaiThuTucId: null as number | null,
  doUuTien: 0,
  ghiChu: ''
})

const dynamicFields = ref<{ key: string, value: string }[]>([])
const attachments = ref<{ tenFile: string, url: string }[]>([])

const addDynamicField = () => dynamicFields.value.push({ key: '', value: '' })
const removeDynamicField = (index: number) => dynamicFields.value.splice(index, 1)

const addAttachment = () => attachments.value.push({ tenFile: '', url: '' })
const removeAttachment = (index: number) => attachments.value.splice(index, 1)

const statusForm = ref({
  trangThaiMoi: 1,
  noiDung: ''
})

// Computed
const statusTabs = computed(() => [
  { value: null, label: 'Tất cả', count: hoSoList.value.length },
  { value: 1, label: 'Đang xử lý', count: hoSoList.value.filter(h => h.trangThai === 1).length },
  { value: 2, label: 'Cần bổ sung', count: hoSoList.value.filter(h => h.trangThai === 2).length },
  { value: 4, label: 'Hoàn thành', count: hoSoList.value.filter(h => h.trangThai === 4).length },
  { value: 5, label: 'Từ chối', count: hoSoList.value.filter(h => h.trangThai === 5).length },
])

const filteredList = computed(() => {
  if (filterStatus.value === null) return hoSoList.value
  return hoSoList.value.filter(h => h.trangThai === filterStatus.value)
})

// Methods
const refreshData = async () => {
  loading.value = true
  try {
    const response = await hoSoApi.getList()
    if (response.data.success) {
      hoSoList.value = response.data.data
    }
  } catch (err: any) {
    toast.error(err.response?.data?.message || 'Không thể tải danh sách hồ sơ')
  } finally {
    loading.value = false
  }
}

const loadThuTuc = async () => {
  try {
    const response = await publicLoaiThuTucApi.getAll()
    if (response.data.success) {
      thuTucList.value = response.data.data
    }
  } catch (err) {
    console.error('Không thể tải danh sách thủ tục')
  }
}

const submitCreateHoSo = async () => {
  if (!createForm.value.mssv || !createForm.value.hoTen || !createForm.value.loaiThuTucId) {
    toast.error('Vui lòng điền đầy đủ thông tin bắt buộc')
    return
  }
  actionLoading.value = true
  try {
      const thongTinHoSo = dynamicFields.value.length > 0 
        ? dynamicFields.value.reduce((acc, curr) => ({ ...acc, [curr.key]: curr.value }), {})
        : undefined

      const response = await hoSoApi.create({
      mssv: createForm.value.mssv,
      hoTen: createForm.value.hoTen,
      soDienThoai: createForm.value.soDienThoai || undefined,
      email: createForm.value.email || undefined,
      loaiThuTucId: createForm.value.loaiThuTucId,
      doUuTien: createForm.value.doUuTien,
      ghiChu: createForm.value.ghiChu || undefined,
      thongTinHoSo,
      fileDinhKem: attachments.value.length > 0 ? attachments.value : undefined
    })
    if (response.data.success) {
      showCreateModal.value = false
      createForm.value = { mssv: '', hoTen: '', soDienThoai: '', email: '', loaiThuTucId: null, doUuTien: 0, ghiChu: '' }
      dynamicFields.value = []
      attachments.value = []
      toast.success('Tạo hồ sơ thành công')
      await refreshData()
    }
  } catch (err: any) {
    toast.error(err.response?.data?.message || 'Không thể tạo hồ sơ')
  } finally {
    actionLoading.value = false
  }
}

const openStatusModal = (hoSo: HoSoData) => {
  selectedHoSo.value = hoSo
  statusForm.value = { trangThaiMoi: hoSo.trangThai + 1, noiDung: '' }
  showStatusModal.value = true
}

const submitUpdateStatus = async () => {
  if (!selectedHoSo.value) return
  actionLoading.value = true
  try {
    const response = await hoSoApi.updateStatus(selectedHoSo.value.id, {
      trangThaiMoi: statusForm.value.trangThaiMoi,
      noiDung: statusForm.value.noiDung || undefined
    })
    if (response.data.success) {
      showStatusModal.value = false
      toast.success('Cập nhật trạng thái thành công')
      await refreshData()
    }
  } catch (err: any) {
    toast.error(err.response?.data?.message || 'Không thể cập nhật trạng thái')
  } finally {
    actionLoading.value = false
  }
}

const viewDetail = (hoSo: HoSoData) => {
  selectedDetailId.value = hoSo.id
  showDetailModal.value = true
}

const handleUpdateStatusFromDetail = (hoSo: HoSoData) => {
  showDetailModal.value = false
  openStatusModal(hoSo)
}

const getStatusClass = (status: number) => {
  const classes: Record<number, string> = {
    0: 'bg-blue-100 text-blue-700 border-blue-200',
    1: 'bg-yellow-100 text-yellow-700 border-yellow-200',
    2: 'bg-orange-100 text-orange-700 border-orange-200',
    3: 'bg-purple-100 text-purple-700 border-purple-200',
    4: 'bg-green-100 text-green-700 border-green-200',
    5: 'bg-red-100 text-red-700 border-red-200'
  }
  return classes[status] || 'bg-gray-100 text-gray-700 border-gray-200'
}

const formatDate = (dateStr: string) => {
  if (!dateStr) return '--'
  const date = new Date(dateStr)
  return date.toLocaleDateString('vi-VN')
}

const isOverdue = (hanXuLy: string | null) => {
  if (!hanXuLy) return false
  return new Date(hanXuLy) < new Date()
}

onMounted(() => {
  refreshData()
  loadThuTuc()
})
</script>
