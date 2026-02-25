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
          <h3 class="text-lg font-semibold text-gray-900">Chỉnh sửa danh mục</h3>
          <button 
            @click="$emit('close')"
            class="p-1 text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X :size="20" />
          </button>
        </div>

        <!-- Form -->
        <form @submit.prevent="handleSubmit" class="px-6 py-4 space-y-4">
          <!-- Tên danh mục -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Tên danh mục <span class="text-red-500">*</span>
            </label>
            <input
              v-model="form.name"
              type="text"
              placeholder="VD: Học vụ, Đào tạo"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
              :class="{ 'border-red-500': errors.name }"
            />
            <p v-if="errors.name" class="mt-1 text-sm text-red-500">{{ errors.name }}</p>
          </div>

          <!-- Mô tả -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Mô tả
            </label>
            <textarea
              v-model="form.description"
              rows="3"
              placeholder="Mô tả về danh mục (tùy chọn)"
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
              {{ form.isActive ? 'Đang hoạt động' : 'Đã khóa' }}
            </span>
          </div>

          <!-- Error/Success message -->
          <div v-if="submitError" class="p-3 bg-red-50 border border-red-200 rounded-lg">
            <p class="text-sm text-red-600">{{ submitError }}</p>
          </div>
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
import { serviceCategoryApi, type ServiceCategoryData } from '@/services/api';

// Props
const props = defineProps<{
  chuyenMon: ServiceCategoryData | null;
}>();

// Emits
const emit = defineEmits<{
  close: [];
  updated: [chuyenMon: ServiceCategoryData];
}>();

// State
const submitting = ref(false);
const submitError = ref<string | null>(null);
const submitSuccess = ref<string | null>(null);

const form = reactive({
  name: '',
  description: '',
  isActive: true,
});

const errors = reactive({
  name: '',
});

// Lifecycle
onMounted(() => {
  if (props.chuyenMon) {
    form.name = props.chuyenMon.name || '';
    form.description = props.chuyenMon.description || '';
    form.isActive = props.chuyenMon.isActive;
  }
});

// Methods
function validate(): boolean {
  errors.name = '';

  if (!form.name.trim()) {
    errors.name = 'Vui lòng nhập tên danh mục';
    return false;
  }

  return true;
}

async function handleSubmit() {
  if (!validate() || !props.chuyenMon) return;

  submitting.value = true;
  submitError.value = null;
  submitSuccess.value = null;

  try {
    const response = await serviceCategoryApi.update(props.chuyenMon.id, {
      name: form.name.trim(),
      description: form.description.trim() || undefined,
      isActive: form.isActive,
    });

    if (response.data.success) {
      submitSuccess.value = 'Cập nhật danh mục thành công!';
      emit('updated', response.data.data);
      
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
