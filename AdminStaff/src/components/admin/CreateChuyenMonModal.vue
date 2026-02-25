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
          <h3 class="text-lg font-semibold text-gray-900">Thêm danh mục mới</h3>
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

          <!-- Error message -->
          <div v-if="submitError" class="p-3 bg-red-50 border border-red-200 rounded-lg">
            <p class="text-sm text-red-600">{{ submitError }}</p>
          </div>
        </form>

        <!-- Footer -->
        <div class="flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-100 bg-gray-50 rounded-b-xl">
          <button
            type="button"
            @click="$emit('close')"
            class="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
          >
            Hủy
          </button>
          <button
            @click="handleSubmit"
            :disabled="submitting"
            class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            <Loader2 v-if="submitting" :size="18" class="animate-spin" />
            {{ submitting ? 'Đang tạo...' : 'Tạo danh mục' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue';
import { X, Loader2 } from 'lucide-vue-next';
import { serviceCategoryApi, type ServiceCategoryData } from '@/services/api';

// Emits
const emit = defineEmits<{
  close: [];
  created: [chuyenMon: ServiceCategoryData];
}>();

// State
const submitting = ref(false);
const submitError = ref<string | null>(null);

const form = reactive({
  name: '',
  description: '',
});

const errors = reactive({
  name: '',
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
  if (!validate()) return;

  submitting.value = true;
  submitError.value = null;

  try {
    const response = await serviceCategoryApi.create({
      name: form.name.trim(),
      description: form.description.trim() || undefined,
    });

    if (response.data.success) {
      emit('created', response.data.data);
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
