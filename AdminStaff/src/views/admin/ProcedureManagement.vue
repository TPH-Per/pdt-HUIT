<template>
  <div class="space-y-8 p-6 animate-fade-in-up">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
      <div>
        <h1 class="text-3xl font-bold bg-gradient-to-r from-blue-700 to-indigo-700 bg-clip-text text-transparent">
          Quản lý dịch vụ đào tạo
        </h1>
        <p class="text-gray-500 mt-2 font-medium">Danh mục các dịch vụ học vụ và quy trình xử lý</p>
      </div>
      <button
        @click="openCreateModal"
        class="group flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-xl shadow-lg shadow-blue-500/30 hover:shadow-blue-500/40 hover:-translate-y-0.5 transition-all duration-300 font-medium"
      >
        <Plus :size="20" class="group-hover:rotate-90 transition-transform duration-300" />
        Thêm dịch vụ mới
      </button>
    </div>

    <!-- Filter Card -->
    <div class="bg-white rounded-2xl p-6 shadow-lg shadow-gray-200/50 border border-gray-100">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="space-y-2">
          <label class="text-sm font-semibold text-gray-700 flex items-center gap-2">
            <Search :size="16" /> Tìm kiếm
          </label>
          <div class="relative">
             <input
              v-model="searchQuery"
              type="text"
              placeholder="Nhập mã hoặc tên dịch vụ..."
              class="w-full pl-4 pr-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none"
            />
          </div>
        </div>
        <div class="space-y-2">
          <label class="text-sm font-semibold text-gray-700 flex items-center gap-2">
            <Filter :size="16" /> Danh mục
          </label>
          <select
            v-model="filterCategory"
            class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none bg-white"
          >
            <option value="">Tất cả danh mục</option>
            <option v-for="cat in categories" :key="cat.id" :value="cat.id">
              {{ cat.name }}
            </option>
          </select>
        </div>
        <div class="space-y-2">
          <label class="text-sm font-semibold text-gray-700 flex items-center gap-2">
            <CheckCircle :size="16" /> Trạng thái
          </label>
          <select
            v-model="filterStatus"
            class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none bg-white"
          >
            <option value="">Tất cả</option>
            <option value="true">Đang hoạt động</option>
            <option value="false">Đã khóa</option>
          </select>
        </div>
      </div>
    </div>

    <!-- Table -->
    <div class="bg-white rounded-2xl shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden">
        <!-- Loading State -->
      <div v-if="loading" class="p-12 text-center">
        <div class="inline-block animate-spin rounded-full h-10 w-10 border-4 border-blue-600 border-t-transparent"></div>
        <p class="mt-4 text-gray-500 font-medium">Đang tải dữ liệu...</p>
      </div>

      <div v-else class="overflow-x-auto">
        <table class="w-full">
          <thead class="bg-gray-50/50 border-b border-gray-100">
            <tr>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Mã dịch vụ</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Tên dịch vụ</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Danh mục</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Thời gian xử lý</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Trạng thái</th>
              <th class="px-6 py-4 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Thao tác</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-50">
            <tr v-for="svc in filteredServices" :key="svc.id" class="hover:bg-blue-50/30 transition-colors duration-200 group">
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="font-mono text-sm font-semibold text-blue-600 bg-blue-50 px-2 py-1 rounded-md">
                   {{ svc.serviceCode }}
                </span>
              </td>
              <td class="px-6 py-4">
                <div class="text-gray-900 font-medium">{{ svc.serviceName }}</div>
                <div class="text-gray-500 text-sm mt-0.5 line-clamp-1">{{ svc.description || '-' }}</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="px-2.5 py-1 text-xs font-medium rounded-full bg-indigo-50 text-indigo-700 border border-indigo-100">
                  {{ svc.categoryName }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center gap-1.5 text-gray-700">
                   <Clock :size="16" class="text-orange-500" />
                   <span class="font-medium">{{ svc.processingDays }}</span> ngày
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span
                  :class="[
                    'px-3 py-1 text-xs font-medium rounded-full inline-flex items-center gap-1.5',
                    svc.isActive 
                      ? 'bg-green-50 text-green-700 border border-green-200' 
                      : 'bg-red-50 text-red-700 border border-red-200'
                  ]"
                >
                  <span class="w-1.5 h-1.5 rounded-full" :class="svc.isActive ? 'bg-green-500' : 'bg-red-500'"></span>
                  {{ svc.isActive ? 'Hoạt động' : 'Đã khóa' }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right">
                <div class="flex items-center justify-end gap-2 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity">
                  <button
                    @click="openEditModal(svc)"
                    class="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-all duration-200"
                    title="Chỉnh sửa"
                  >
                    <Pencil :size="18" />
                  </button>
                  <button
                    @click="confirmDelete(svc)"
                    class="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-all duration-200"
                    title="Khóa dịch vụ"
                  >
                    <Trash2 :size="18" />
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="filteredServices.length === 0">
              <td colspan="6" class="px-6 py-24 text-center">
                 <div class="w-24 h-24 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Search :size="48" class="text-gray-300" />
                </div>
                <p class="text-gray-500 font-medium text-lg">Không tìm thấy dịch vụ nào</p>
                <p class="text-gray-400 text-sm mt-1">Thử thay đổi bộ lọc tìm kiếm</p>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Create/Edit Modal -->
    <div
      v-if="showModal"
      class="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50 animate-fade-in"
      @click.self="closeModal"
    >
      <div class="bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto m-4 transform transition-all scale-100">
        <div class="p-6 border-b border-gray-100 bg-gray-50/50">
          <h2 class="text-xl font-bold bg-gradient-to-r from-blue-700 to-indigo-700 bg-clip-text text-transparent">
            {{ isEditing ? 'Cập nhật dịch vụ' : 'Thêm dịch vụ mới' }}
          </h2>
          <p class="text-sm text-gray-500 mt-1">Điền đầy đủ thông tin chi tiết cho dịch vụ</p>
        </div>

        <div class="p-6">
          <form @submit.prevent="handleSubmit" class="space-y-6">
            <div class="grid grid-cols-2 gap-6">
              <div class="space-y-2">
                <label class="block text-sm font-semibold text-gray-700">
                  Mã dịch vụ <span class="text-red-500">*</span>
                </label>
                <input
                  v-model="form.serviceCode"
                  type="text"
                  :disabled="isEditing"
                  class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:bg-gray-100 transition-all outline-none"
                  placeholder="VD: DV001"
                />
              </div>
              <div class="space-y-2">
                <label class="block text-sm font-semibold text-gray-700">
                  Tên dịch vụ <span class="text-red-500">*</span>
                </label>
                <input
                  v-model="form.serviceName"
                  type="text"
                  class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none"
                  placeholder="VD: Xin bảng điểm"
                />
              </div>
            </div>

            <div class="space-y-2">
              <label class="block text-sm font-semibold text-gray-700">Mô tả</label>
              <textarea
                v-model="form.description"
                rows="3"
                class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none resize-none"
                placeholder="Mô tả chi tiết về dịch vụ..."
              ></textarea>
            </div>

            <div class="grid grid-cols-2 gap-6">
              <div class="space-y-2">
                <label class="block text-sm font-semibold text-gray-700">
                  Danh mục <span class="text-red-500">*</span>
                </label>
                <select
                  v-model="form.categoryId"
                  class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none bg-white"
                >
                  <option value="">Chọn danh mục</option>
                  <option v-for="cat in categories" :key="cat.id" :value="cat.id">
                    {{ cat.name }}
                  </option>
                </select>
              </div>
              <div class="space-y-2">
                <label class="block text-sm font-semibold text-gray-700">
                  Thời gian xử lý (ngày)
                </label>
                <input
                  v-model.number="form.processingDays"
                  type="number"
                  min="1"
                  class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none"
                  placeholder="15"
                />
              </div>
            </div>

            <div class="space-y-2">
              <label class="block text-sm font-semibold text-gray-700">Giấy tờ yêu cầu</label>
              <textarea
                v-model="form.requiredDocuments"
                rows="4"
                class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none resize-none"
                placeholder="Liệt kê các giấy tờ cần thiết, mỗi giấy tờ một dòng..."
              ></textarea>
            </div>

            <div class="grid grid-cols-2 gap-6">
              <div class="space-y-2">
                <label class="block text-sm font-semibold text-gray-700">Thứ tự hiển thị</label>
                <input
                  v-model.number="form.displayOrder"
                  type="number"
                  min="0"
                  class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none"
                  placeholder="0"
                />
              </div>
              <div v-if="isEditing" class="space-y-2">
                <label class="block text-sm font-semibold text-gray-700">Trạng thái</label>
                <select
                  v-model="form.isActive"
                  class="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none bg-white"
                >
                  <option :value="true">Hoạt động</option>
                  <option :value="false">Đã khóa</option>
                </select>
              </div>
            </div>

            <div class="flex justify-end gap-3 pt-4 border-t border-gray-100">
              <button
                type="button"
                @click="closeModal"
                class="px-5 py-2.5 border border-gray-300 rounded-xl text-gray-700 font-medium hover:bg-gray-50 transition-colors"
              >
                Hủy bỏ
              </button>
              <button
                type="submit"
                :disabled="submitting"
                class="px-5 py-2.5 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-xl shadow-lg shadow-blue-500/30 hover:shadow-blue-500/40 hover:-translate-y-0.5 transition-all duration-300 font-medium disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
              >
                <div v-if="submitting" class="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent"></div>
                {{ isEditing ? 'Cập nhật' : 'Thêm mới' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { 
  Plus, Search, Filter, Pencil, Trash2, Clock, CheckCircle 
} from 'lucide-vue-next';
import { 
  academicServiceApi, serviceCategoryApi, 
  type AcademicServiceData, type ServiceCategoryData, 
  type CreateAcademicServiceRequest, type UpdateAcademicServiceRequest 
} from '@/services/api';
import { useToast } from "vue-toastification";
import Swal from 'sweetalert2';

// State
const loading = ref(true);
const submitting = ref(false);
const services = ref<AcademicServiceData[]>([]);
const categories = ref<ServiceCategoryData[]>([]);
const searchQuery = ref('');
const filterCategory = ref('');
const filterStatus = ref('');
const showModal = ref(false);
const isEditing = ref(false);
const selectedService = ref<AcademicServiceData | null>(null);
const toast = useToast();

// Form
const form = ref({
  serviceCode: '',
  serviceName: '',
  description: '',
  categoryId: '' as number | '',
  processingDays: 15,
  requiredDocuments: '',
  displayOrder: 0,
  isActive: true
});

// Computed
const filteredServices = computed(() => {
  return services.value.filter(svc => {
    const matchSearch = !searchQuery.value ||
      svc.serviceCode.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      svc.serviceName.toLowerCase().includes(searchQuery.value.toLowerCase());

    const matchCategory = !filterCategory.value ||
      svc.categoryId === Number(filterCategory.value);

    const matchStatus = !filterStatus.value ||
      String(svc.isActive) === filterStatus.value;

    return matchSearch && matchCategory && matchStatus;
  });
});

// Methods
const fetchData = async () => {
  loading.value = true;
  try {
    const [servicesRes, categoriesRes] = await Promise.all([
      academicServiceApi.getAll(),
      serviceCategoryApi.getAll()
    ]);
    services.value = servicesRes.data.data || [];
    categories.value = categoriesRes.data.data || [];
  } catch (error) {
    console.error('Error fetching data:', error);
    toast.error('Lỗi tải dữ liệu');
  } finally {
    loading.value = false;
  }
};

const resetForm = () => {
  form.value = {
    serviceCode: '',
    serviceName: '',
    description: '',
    categoryId: '',
    processingDays: 15,
    requiredDocuments: '',
    displayOrder: 0,
    isActive: true
  };
};

const openCreateModal = () => {
  resetForm();
  isEditing.value = false;
  showModal.value = true;
};

const openEditModal = (svc: AcademicServiceData) => {
  selectedService.value = svc;
  form.value = {
    serviceCode: svc.serviceCode,
    serviceName: svc.serviceName,
    description: svc.description || '',
    categoryId: svc.categoryId,
    processingDays: svc.processingDays,
    requiredDocuments: svc.requiredDocuments || '',
    displayOrder: svc.displayOrder,
    isActive: svc.isActive
  };
  isEditing.value = true;
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
  resetForm();
};

const handleSubmit = async () => {
  // Validation
  if (!form.value.serviceCode || !form.value.serviceName || !form.value.categoryId) {
    toast.error('Vui lòng điền đầy đủ thông tin bắt buộc');
    return;
  }

  submitting.value = true;
  try {
    if (isEditing.value && selectedService.value) {
      const updateData: UpdateAcademicServiceRequest = {
        serviceName: form.value.serviceName,
        description: form.value.description || undefined,
        categoryId: form.value.categoryId as number,
        processingDays: form.value.processingDays,
        requiredDocuments: form.value.requiredDocuments || undefined,
        displayOrder: form.value.displayOrder,
        isActive: form.value.isActive
      };
      await academicServiceApi.update(selectedService.value.id, updateData);
      toast.success('Cập nhật dịch vụ thành công');
    } else {
      const createData: CreateAcademicServiceRequest = {
        serviceCode: form.value.serviceCode,
        serviceName: form.value.serviceName,
        description: form.value.description || undefined,
        categoryId: form.value.categoryId as number,
        processingDays: form.value.processingDays,
        requiredDocuments: form.value.requiredDocuments || undefined,
        displayOrder: form.value.displayOrder
      };
      await academicServiceApi.create(createData);
      toast.success('Thêm dịch vụ thành công');
    }

    closeModal();
    fetchData();
  } catch (error: any) {
    toast.error(error.response?.data?.message || 'Có lỗi xảy ra');
  } finally {
    submitting.value = false;
  }
};

const confirmDelete = async (svc: AcademicServiceData) => {
   const result = await Swal.fire({
    title: 'Xác nhận khóa dịch vụ',
    text: `Bạn có chắc muốn khóa dịch vụ ${svc.serviceName}?`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonColor: '#d33',
    cancelButtonColor: '#3085d6',
    confirmButtonText: 'Đồng ý khóa',
    cancelButtonText: 'Hủy'
  });

  if (!result.isConfirmed) return;

  submitting.value = true;
  try {
    await academicServiceApi.delete(svc.id);
    toast.success('Đã khóa dịch vụ thành công');
    fetchData();
  } catch (error) {
    console.error('Error deleting:', error);
    toast.error('Không thể khóa dịch vụ');
  } finally {
    submitting.value = false;
  }
};


// Lifecycle
onMounted(fetchData);
</script>
