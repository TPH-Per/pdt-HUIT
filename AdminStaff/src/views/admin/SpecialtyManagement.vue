<template>
  <div class="space-y-8 p-6 animate-fade-in-up">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
      <div>
        <h1 class="text-3xl font-bold bg-gradient-to-r from-blue-700 to-indigo-700 bg-clip-text text-transparent">
          Quản lý danh mục dịch vụ
        </h1>
        <p class="text-gray-500 mt-2 font-medium">Hệ thống quản lý các danh mục dịch vụ đào tạo</p>
      </div>
      <button
        @click="openCreateModal"
        class="group flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-xl shadow-lg shadow-blue-500/30 hover:shadow-blue-500/40 hover:-translate-y-0.5 transition-all duration-300 font-medium"
      >
        <Plus :size="20" class="group-hover:rotate-90 transition-transform duration-300" />
        Thêm danh mục
      </button>
    </div>

    <!-- Stats Cards -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
      <div class="bg-white rounded-2xl p-5 border border-gray-100 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 group">
        <div class="flex items-center gap-4">
          <div class="p-3 bg-blue-50 text-blue-600 rounded-xl group-hover:scale-110 transition-transform duration-300">
            <Layers :size="24" />
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">Tổng danh mục</p>
            <p class="text-2xl font-bold text-gray-800 mt-1">{{ categories.length }}</p>
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
            <p class="text-2xl font-bold text-gray-800 mt-1">{{ activeCategories }}</p>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-2xl p-5 border border-gray-100 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 group">
        <div class="flex items-center gap-4">
          <div class="p-3 bg-purple-50 text-purple-600 rounded-xl group-hover:scale-110 transition-transform duration-300">
            <Building2 :size="24" />
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">Tổng quầy</p>
            <p class="text-2xl font-bold text-gray-800 mt-1">{{ totalDesks }}</p>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-2xl p-5 border border-gray-100 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 group">
        <div class="flex items-center gap-4">
          <div class="p-3 bg-orange-50 text-orange-600 rounded-xl group-hover:scale-110 transition-transform duration-300">
            <FileText :size="24" />
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">Tổng dịch vụ</p>
            <p class="text-2xl font-bold text-gray-800 mt-1">{{ totalServices }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Category Table -->
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
          @click="fetchCategories" 
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
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">#</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Tên danh mục</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Mô tả</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Thống kê</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Trạng thái</th>
              <th class="px-6 py-4 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Thao tác</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-50">
            <tr v-for="(cat, index) in categories" :key="cat.id" class="hover:bg-blue-50/30 transition-colors duration-200 group">
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="font-mono text-sm font-semibold text-blue-600 bg-blue-50 px-2 py-1 rounded-md">
                  {{ index + 1 }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="text-gray-900 font-medium">{{ cat.name }}</span>
              </td>
              <td class="px-6 py-4">
                <span class="text-gray-500 text-sm line-clamp-2 max-w-xs">{{ cat.description || '-' }}</span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex gap-2">
                  <span class="px-2.5 py-1 text-xs font-medium rounded-full bg-purple-50 text-purple-700 border border-purple-100">
                    {{ cat.deskCount }} quầy
                  </span>
                  <span class="px-2.5 py-1 text-xs font-medium rounded-full bg-orange-50 text-orange-700 border border-orange-100">
                    {{ cat.serviceCount }} dịch vụ
                  </span>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span
                  :class="[
                    'px-3 py-1 text-xs font-medium rounded-full inline-flex items-center gap-1.5',
                    cat.isActive 
                      ? 'bg-green-50 text-green-700 border border-green-200' 
                      : 'bg-red-50 text-red-700 border border-red-200'
                  ]"
                >
                  <span class="w-1.5 h-1.5 rounded-full" :class="cat.isActive ? 'bg-green-500' : 'bg-red-500'"></span>
                  {{ cat.isActive ? 'Hoạt động' : 'Đã khóa' }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right">
                <div class="flex items-center justify-end gap-2 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity">
                  <button
                    @click="editCategory(cat)"
                    class="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-all duration-200"
                    title="Chỉnh sửa"
                  >
                    <Pencil :size="18" />
                  </button>
                  <button
                    @click="toggleCategoryStatus(cat)"
                    :class="[
                      'p-2 rounded-lg transition-all duration-200',
                      cat.isActive 
                        ? 'text-gray-400 hover:text-red-600 hover:bg-red-50' 
                        : 'text-gray-400 hover:text-green-600 hover:bg-green-50'
                    ]"
                    :title="cat.isActive ? 'Khóa danh mục' : 'Mở khóa danh mục'"
                  >
                    <Lock v-if="cat.isActive" :size="18" />
                    <Unlock v-else :size="18" />
                  </button>
                </div>
              </td>
            </tr>
            
            <!-- Empty State -->
            <tr v-if="categories.length === 0">
              <td colspan="6" class="px-6 py-24 text-center">
                <div class="w-24 h-24 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Layers :size="48" class="text-gray-300" />
                </div>
                <p class="text-gray-500 font-medium text-lg">Chưa có danh mục nào</p>
                <p class="text-gray-400 text-sm mt-1">Bắt đầu bằng cách thêm danh mục mới</p>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Create Modal -->
    <CreateChuyenMonModal
      v-if="showCreateModal"
      @close="showCreateModal = false"
      @created="onCategoryCreated"
    />

    <!-- Edit Modal -->
    <EditChuyenMonModal
      v-if="showEditModal"
      :chuyen-mon="editingCategory"
      @close="showEditModal = false; editingCategory = null"
      @updated="onCategoryUpdated"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { 
  Plus, Layers, CheckCircle, Building2, FileText,
  Pencil, Lock, Unlock, AlertCircle 
} from 'lucide-vue-next';
import { serviceCategoryApi, type ServiceCategoryData } from '@/services/api';
import CreateChuyenMonModal from '@/components/admin/CreateChuyenMonModal.vue';
import EditChuyenMonModal from '@/components/admin/EditChuyenMonModal.vue';
import { useToast } from "vue-toastification";
import Swal from 'sweetalert2';

// State
const categories = ref<ServiceCategoryData[]>([]);
const loading = ref(false);
const error = ref<string | null>(null);
const showCreateModal = ref(false);
const showEditModal = ref(false);
const editingCategory = ref<ServiceCategoryData | null>(null);
const toast = useToast();

// Computed
const activeCategories = computed(() => categories.value.filter(c => c.isActive).length);
const totalDesks = computed(() => categories.value.reduce((sum, c) => sum + (c.deskCount || 0), 0));
const totalServices = computed(() => categories.value.reduce((sum, c) => sum + (c.serviceCount || 0), 0));

// Methods
async function fetchCategories() {
  loading.value = true;
  error.value = null;
  
  try {
    const response = await serviceCategoryApi.getAll();
    if (response.data.success) {
      categories.value = response.data.data;
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

function onCategoryCreated(newCategory: ServiceCategoryData) {
  categories.value.unshift(newCategory);
  showCreateModal.value = false;
  toast.success('Thêm danh mục thành công');
}

function editCategory(cat: ServiceCategoryData) {
  editingCategory.value = cat;
  showEditModal.value = true;
}

function onCategoryUpdated(updatedCategory: ServiceCategoryData) {
  const index = categories.value.findIndex(c => c.id === updatedCategory.id);
  if (index !== -1) {
    categories.value[index] = updatedCategory;
  }
  showEditModal.value = false;
  editingCategory.value = null;
  toast.success('Cập nhật danh mục thành công');
}

async function toggleCategoryStatus(cat: ServiceCategoryData) {
  const result = await Swal.fire({
    title: 'Xác nhận',
    text: `Bạn có chắc muốn ${cat.isActive ? 'khóa' : 'mở khóa'} danh mục ${cat.name}?`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonColor: '#3085d6',
    cancelButtonColor: '#d33',
    confirmButtonText: 'Đồng ý',
    cancelButtonText: 'Hủy'
  });

  if (!result.isConfirmed) return;
  
  try {
    if (cat.isActive) {
      await serviceCategoryApi.delete(cat.id);
    } else {
      await serviceCategoryApi.update(cat.id, { isActive: true });
    }
    cat.isActive = !cat.isActive;
    toast.success(`Đã ${cat.isActive ? 'mở khóa' : 'khóa'} danh mục ${cat.name}`);
  } catch (err: any) {
    toast.error(err.response?.data?.message || 'Có lỗi xảy ra');
  }
}

// Lifecycle
onMounted(() => {
  fetchCategories();
});
</script>
