<template>
  <div class="space-y-8 p-6 animate-fade-in-up">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
      <div>
        <h1 class="text-3xl font-bold bg-gradient-to-r from-blue-700 to-indigo-700 bg-clip-text text-transparent">
          Quản lý quầy
        </h1>
        <p class="text-gray-500 mt-2 font-medium">Quản lý các quầy tiếp nhận và phân công nhân viên</p>
      </div>
      <button
        @click="openCreateModal"
        class="group flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-xl shadow-lg shadow-blue-500/30 hover:shadow-blue-500/40 hover:-translate-y-0.5 transition-all duration-300 font-medium"
      >
        <Plus :size="20" class="group-hover:rotate-90 transition-transform duration-300" />
        Thêm quầy mới
      </button>
    </div>

    <!-- Stats Cards -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
      <div class="bg-white rounded-2xl p-5 border border-gray-100 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 group">
        <div class="flex items-center gap-4">
          <div class="p-3 bg-blue-50 text-blue-600 rounded-xl group-hover:scale-110 transition-transform duration-300">
            <Building2 :size="24" />
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">Tổng quầy</p>
            <p class="text-2xl font-bold text-gray-800 mt-1">{{ desks.length }}</p>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-2xl p-5 border border-gray-100 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 group">
        <div class="flex items-center gap-4">
          <div class="p-3 bg-green-50 text-green-600 rounded-xl group-hover:scale-110 transition-transform duration-300">
            <CheckCircle :size="24" />
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">Đang hoạt động</p>
            <p class="text-2xl font-bold text-gray-800 mt-1">{{ activeDesks }}</p>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-2xl p-5 border border-gray-100 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 group">
         <div class="flex items-center gap-4">
          <div class="p-3 bg-orange-50 text-orange-600 rounded-xl group-hover:scale-110 transition-transform duration-300">
            <XCircle :size="24" />
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">Đã khóa</p>
            <p class="text-2xl font-bold text-gray-800 mt-1">{{ inactiveDesks }}</p>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-2xl p-5 border border-gray-100 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 group">
        <div class="flex items-center gap-4">
          <div class="p-3 bg-purple-50 text-purple-600 rounded-xl group-hover:scale-110 transition-transform duration-300">
            <Users :size="24" />
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">Tổng nhân viên</p>
            <p class="text-2xl font-bold text-gray-800 mt-1">{{ totalStaff }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Desk Table -->
    <div class="bg-white rounded-2xl shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden">
      <!-- Loading State -->
      <div v-if="loading" class="p-12 text-center">
        <div class="inline-block animate-spin rounded-full h-10 w-10 border-4 border-blue-600 border-t-transparent"></div>
        <p class="mt-4 text-gray-500 font-medium">Đang tải dữ liệu...</p>
      </div>

      <!-- Error State -->
      <div v-else-if="error" class="p-12 text-center">
        <div class="w-16 h-16 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-4">
          <AlertCircle :size="32" class="text-red-500" />
        </div>
        <p class="text-red-800 font-medium text-lg mb-2">Đã xảy ra lỗi</p>
        <p class="text-gray-500 mb-6">{{ error }}</p>
        <button 
          @click="fetchDesks" 
          class="px-4 py-2 bg-white border border-gray-300 rounded-lg text-gray-700 font-medium hover:bg-gray-50 transition-colors"
        >
          Thử lại
        </button>
      </div>

      <!-- Table -->
      <div v-else class="overflow-x-auto">
        <table class="w-full">
          <thead class="bg-gray-50/50 border-b border-gray-100">
            <tr>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Mã quầy</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Tên quầy</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Danh mục</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Vị trí</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Nhân sự</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Trạng thái</th>
              <th class="px-6 py-4 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Thao tác</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-50">
            <tr v-for="desk in desks" :key="desk.id" class="hover:bg-blue-50/30 transition-colors duration-200 group">
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="font-mono text-sm font-semibold text-blue-600 bg-blue-50 px-2 py-1 rounded-md">
                  {{ desk.deskCode }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center gap-3">
                  <div class="h-9 w-9 rounded-full bg-gradient-to-br from-blue-100 to-indigo-100 flex items-center justify-center text-blue-700 font-bold text-sm shadow-sm ring-2 ring-white">
                    {{ desk.deskCode?.substring(0, 2) }}
                  </div>
                  <span class="text-gray-900 font-medium">{{ desk.deskName }}</span>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="px-2.5 py-1 text-xs font-medium rounded-full bg-purple-50 text-purple-700 border border-purple-100">
                  {{ desk.categoryName || 'Chưa phân loại' }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center gap-1.5 text-gray-600">
                  <span class="text-sm">{{ desk.location || 'Chưa cập nhật' }}</span>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="text-gray-900 font-medium">{{ desk.staffCount }}</span>
                <span class="text-gray-500 text-sm"> nhân viên</span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span
                  :class="[
                    'px-3 py-1 text-xs font-medium rounded-full inline-flex items-center gap-1.5',
                    desk.isActive 
                      ? 'bg-green-50 text-green-700 border border-green-200' 
                      : 'bg-red-50 text-red-700 border border-red-200'
                  ]"
                >
                  <span class="w-1.5 h-1.5 rounded-full" :class="desk.isActive ? 'bg-green-500' : 'bg-red-500'"></span>
                  {{ desk.isActive ? 'Hoạt động' : 'Đã khóa' }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right">
                <div class="flex items-center justify-end gap-2 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity">
                  <button
                    @click="editDesk(desk)"
                    class="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-all duration-200"
                    title="Chỉnh sửa"
                  >
                    <Pencil :size="18" />
                  </button>
                  <button
                    @click="toggleDeskStatus(desk)"
                    :class="[
                      'p-2 rounded-lg transition-all duration-200',
                      desk.isActive 
                        ? 'text-gray-400 hover:text-red-600 hover:bg-red-50' 
                        : 'text-gray-400 hover:text-green-600 hover:bg-green-50'
                    ]"
                    :title="desk.isActive ? 'Khóa quầy' : 'Mở khóa quầy'"
                  >
                    <Lock v-if="desk.isActive" :size="18" />
                    <Unlock v-else :size="18" />
                  </button>
                </div>
              </td>
            </tr>
            
            <!-- Empty State -->
            <tr v-if="desks.length === 0">
              <td colspan="7" class="px-6 py-24 text-center">
                <div class="w-24 h-24 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Building2 :size="48" class="text-gray-300" />
                </div>
                <p class="text-gray-500 font-medium text-lg">Chưa có quầy nào</p>
                <p class="text-gray-400 text-sm mt-1">Hệ thống chưa ghi nhận quầy nào</p>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Create Desk Modal -->
    <CreateQuayModal
      v-if="showCreateModal"
      @close="showCreateModal = false"
      @created="onDeskCreated"
    />

    <!-- Edit Desk Modal -->
    <EditQuayModal
      v-if="showEditModal"
      :quay="editingDesk"
      @close="showEditModal = false; editingDesk = null"
      @updated="onDeskUpdated"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { 
  Plus, Building2, CheckCircle, XCircle, Users,
  Pencil, Lock, Unlock, AlertCircle 
} from 'lucide-vue-next';
import { serviceDeskApi, type ServiceDeskData } from '@/services/api';
import CreateQuayModal from '@/components/admin/CreateQuayModal.vue';
import EditQuayModal from '@/components/admin/EditQuayModal.vue';
import { useToast } from "vue-toastification";
import Swal from 'sweetalert2';

// State
const desks = ref<ServiceDeskData[]>([]);
const loading = ref(false);
const error = ref<string | null>(null);
const showCreateModal = ref(false);
const showEditModal = ref(false);
const editingDesk = ref<ServiceDeskData | null>(null);
const toast = useToast();

// Computed
const activeDesks = computed(() => desks.value.filter(q => q.isActive).length);
const inactiveDesks = computed(() => desks.value.filter(q => !q.isActive).length);
const totalStaff = computed(() => desks.value.reduce((sum, q) => sum + (q.staffCount || 0), 0));

// Methods
async function fetchDesks() {
  loading.value = true;
  error.value = null;
  
  try {
    const response = await serviceDeskApi.getAll();
    if (response.data.success) {
      desks.value = response.data.data;
    } else {
      error.value = response.data.message;
      toast.error(error.value || 'Lỗi tải dữ liệu');
    }
  } catch (err: any) {
    error.value = err.response?.data?.message || 'Lỗi kết nối server';
    toast.error(error.value || 'Lỗi kết nối server');
  } finally {
    loading.value = false;
  }
}

function openCreateModal() {
  showCreateModal.value = true;
}

function onDeskCreated(newDesk: ServiceDeskData) {
  desks.value.unshift(newDesk);
  showCreateModal.value = false;
  toast.success('Thêm quầy mới thành công');
}

function editDesk(desk: ServiceDeskData) {
  editingDesk.value = desk;
  showEditModal.value = true;
}

function onDeskUpdated(updatedDesk: ServiceDeskData) {
  const index = desks.value.findIndex(q => q.id === updatedDesk.id);
  if (index !== -1) {
    desks.value[index] = updatedDesk;
  }
  showEditModal.value = false;
  editingDesk.value = null;
  toast.success('Cập nhật quầy thành công');
}

async function toggleDeskStatus(desk: ServiceDeskData) {
  const result = await Swal.fire({
    title: 'Xác nhận',
    text: `Bạn có chắc muốn ${desk.isActive ? 'khóa' : 'mở khóa'} quầy ${desk.deskName}?`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonColor: '#3085d6',
    cancelButtonColor: '#d33',
    confirmButtonText: 'Đồng ý',
    cancelButtonText: 'Hủy'
  });

  if (!result.isConfirmed) return;
  
  try {
    if (desk.isActive) {
      await serviceDeskApi.delete(desk.id);
    } else {
      await serviceDeskApi.update(desk.id, { isActive: true });
    }
    desk.isActive = !desk.isActive;
    toast.success(`Đã ${desk.isActive ? 'mở khóa' : 'khóa'} quầy ${desk.deskName}`);
  } catch (err: any) {
    toast.error(err.response?.data?.message || 'Có lỗi xảy ra');
  }
}

// Lifecycle
onMounted(() => {
  fetchDesks();
});
</script>
