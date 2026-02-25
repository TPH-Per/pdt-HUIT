<template>
  <div class="fixed inset-0 z-50 overflow-y-auto">
    <!-- Backdrop -->
    <div 
      class="fixed inset-0 bg-black/50 transition-opacity"
      @click="$emit('close')"
    ></div>
    
    <!-- Modal -->
    <div class="flex min-h-full items-center justify-center p-4">
      <div 
        class="relative w-full max-w-lg bg-white rounded-xl shadow-xl transform transition-all"
        @click.stop
      >
        <!-- Header -->
        <div class="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 class="text-lg font-semibold text-gray-900">Chỉnh sửa quầy</h3>
          <button 
            @click="$emit('close')"
            class="p-1 text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X :size="20" />
          </button>
        </div>

        <!-- Loading State -->
        <div v-if="loading" class="flex items-center justify-center py-12">
          <Loader2 :size="32" class="animate-spin text-blue-600" />
        </div>

        <!-- Form -->
        <form v-else @submit.prevent="handleSubmit" class="px-6 py-4 space-y-4">
          <!-- Mã quầy (Read-only) -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Mã quầy
            </label>
            <input
              :value="props.quay?.deskCode"
              type="text"
              disabled
              class="w-full px-3 py-2 border border-gray-200 rounded-lg bg-gray-50 text-gray-500 cursor-not-allowed"
            />
            <p class="mt-1 text-xs text-gray-400">Mã quầy không thể thay đổi</p>
          </div>

          <!-- Tên quầy -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Tên quầy <span class="text-red-500">*</span>
            </label>
            <input
              v-model="form.deskName"
              type="text"
              placeholder="VD: Quầy Học vụ"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
              :class="{ 'border-red-500': errors.deskName }"
            />
            <p v-if="errors.deskName" class="mt-1 text-sm text-red-500">{{ errors.deskName }}</p>
          </div>

          <!-- Danh mục & Vị trí -->
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                Danh mục
              </label>
              <select
                v-model="form.categoryId"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
              >
                <option :value="null">Không chọn</option>
                <option v-for="cat in categories" :key="cat.id" :value="cat.id">
                  {{ cat.name }}
                </option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                Vị trí
              </label>
              <input
                v-model="form.location"
                type="text"
                placeholder="VD: Tầng 1, Phòng A"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
              />
            </div>
          </div>

          <!-- Ghi chú -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Ghi chú
            </label>
            <textarea
              v-model="form.notes"
              rows="2"
              placeholder="Ghi chú thêm (tùy chọn)"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none"
            ></textarea>
          </div>

          <!-- Trạng thái -->
          <div class="flex items-center gap-3">
            <label class="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                v-model="form.isActive"
                class="sr-only peer"
              />
              <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
            </label>
            <span class="text-sm font-medium text-gray-700">
              {{ form.isActive ? 'Quầy đang hoạt động' : 'Quầy đã khóa' }}
            </span>
          </div>

          <!-- Error message -->
          <div v-if="submitError" class="p-3 bg-red-50 border border-red-200 rounded-lg">
            <p class="text-sm text-red-600">{{ submitError }}</p>
          </div>

          <!-- Success message -->
          <div v-if="submitSuccess" class="p-3 bg-green-50 border border-green-200 rounded-lg">
            <p class="text-sm text-green-600">{{ submitSuccess }}</p>
          </div>
        </form>

        <!-- Footer -->
        <div class="flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-100 bg-gray-50 rounded-b-xl">
          <button
            type="button"
            @click="$emit('close')"
            class="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
          >
            Đóng
          </button>
          <button
            @click="handleSubmit"
            :disabled="submitting"
            class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            <Loader2 v-if="submitting" :size="18" class="animate-spin" />
            {{ submitting ? 'Đang lưu...' : 'Lưu thay đổi' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue';
import { X, Loader2 } from 'lucide-vue-next';
import { serviceDeskApi, serviceCategoryApi, type ServiceCategoryData, type ServiceDeskData } from '@/services/api';

// Props
const props = defineProps<{
  quay: ServiceDeskData | null;
}>();

// Emits
const emit = defineEmits<{
  close: [];
  updated: [quay: ServiceDeskData];
}>();

// State
const loading = ref(true);
const categories = ref<ServiceCategoryData[]>([]);
const submitting = ref(false);
const submitError = ref<string | null>(null);
const submitSuccess = ref<string | null>(null);

const form = reactive({
  deskName: '',
  location: '',
  categoryId: null as number | null,
  notes: '',
  isActive: true,
});

const errors = reactive({
  deskName: '',
});

// Lifecycle
onMounted(async () => {
  try {
    // Load categories
    const catResponse = await serviceCategoryApi.getAll();
    if (catResponse.data.success) {
      categories.value = catResponse.data.data;
    }

    // Populate form with current desk data
    if (props.quay) {
      form.deskName = props.quay.deskName || '';
      form.location = props.quay.location || '';
      form.categoryId = props.quay.categoryId || null;
      form.notes = props.quay.notes || '';
      form.isActive = props.quay.isActive;
    }
  } catch (err) {
    console.error('Error loading data:', err);
    submitError.value = 'Không thể tải dữ liệu';
  } finally {
    loading.value = false;
  }
});

// Methods
function validate(): boolean {
  let isValid = true;
  
  Object.keys(errors).forEach(key => {
    errors[key as keyof typeof errors] = '';
  });

  if (!form.deskName.trim()) {
    errors.deskName = 'Vui lòng nhập tên quầy';
    isValid = false;
  }

  return isValid;
}

async function handleSubmit() {
  if (!validate() || !props.quay) return;

  submitting.value = true;
  submitError.value = null;
  submitSuccess.value = null;

  try {
    const response = await serviceDeskApi.update(props.quay.id, {
      deskName: form.deskName.trim(),
      location: form.location.trim() || undefined,
      categoryId: form.categoryId ?? undefined,
      notes: form.notes.trim() || undefined,
      isActive: form.isActive,
    });

    if (response.data.success) {
      submitSuccess.value = 'Cập nhật quầy thành công!';
      emit('updated', response.data.data);
      
      // Auto close after 1.5s
      setTimeout(() => {
        emit('close');
      }, 1500);
    } else {
      submitError.value = response.data.message;
    }
  } catch (err: any) {
    submitError.value = err.response?.data?.message || 'Có lỗi xảy ra, vui lòng thử lại';
  } finally {
    submitting.value = false;
  }
}
</script>
