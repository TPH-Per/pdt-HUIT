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
          <h3 class="text-lg font-semibold text-gray-900">Thêm quầy mới</h3>
          <button 
            @click="$emit('close')"
            class="p-1 text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X :size="20" />
          </button>
        </div>

        <!-- Form -->
        <form @submit.prevent="handleSubmit" class="px-6 py-4 space-y-4">
          <!-- Mã quầy -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Mã quầy <span class="text-red-500">*</span>
            </label>
            <input
              v-model="form.deskCode"
              type="text"
              placeholder="VD: Q1, Q2, Q3"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
              :class="{ 'border-red-500': errors.deskCode }"
            />
            <p v-if="errors.deskCode" class="mt-1 text-sm text-red-500">{{ errors.deskCode }}</p>
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
            {{ submitting ? 'Đang tạo...' : 'Tạo quầy' }}
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

// Emits
const emit = defineEmits<{
  close: [];
  created: [quay: ServiceDeskData];
}>();

// State
const categories = ref<ServiceCategoryData[]>([]);
const submitting = ref(false);
const submitError = ref<string | null>(null);

const form = reactive({
  deskCode: '',
  deskName: '',
  location: '',
  categoryId: null as number | null,
  notes: '',
});

const errors = reactive({
  deskCode: '',
  deskName: '',
});

// Methods
function validate(): boolean {
  let isValid = true;
  
  Object.keys(errors).forEach(key => {
    errors[key as keyof typeof errors] = '';
  });

  if (!form.deskCode.trim()) {
    errors.deskCode = 'Vui lòng nhập mã quầy';
    isValid = false;
  }

  if (!form.deskName.trim()) {
    errors.deskName = 'Vui lòng nhập tên quầy';
    isValid = false;
  }

  return isValid;
}

async function handleSubmit() {
  if (!validate()) return;

  submitting.value = true;
  submitError.value = null;

  try {
    const response = await serviceDeskApi.create({
      deskCode: form.deskCode.trim(),
      deskName: form.deskName.trim(),
      location: form.location.trim() || undefined,
      categoryId: form.categoryId ?? undefined,
      notes: form.notes.trim() || undefined,
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

async function fetchCategories() {
  try {
    const response = await serviceCategoryApi.getAll();
    if (response.data.success) {
      categories.value = response.data.data;
    }
  } catch (err) {
    console.error('Failed to fetch categories:', err);
  }
}

// Lifecycle
onMounted(() => {
  fetchCategories();
});
</script>
