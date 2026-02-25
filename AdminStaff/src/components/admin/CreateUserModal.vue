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
          <h3 class="text-lg font-semibold text-gray-900">Thêm tài khoản mới</h3>
          <button 
            @click="$emit('close')"
            class="p-1 text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X :size="20" />
          </button>
        </div>

        <!-- Form -->
        <form @submit.prevent="handleSubmit" class="px-6 py-4 space-y-4">
          <!-- Mã nhân viên -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Mã nhân viên <span class="text-red-500">*</span>
            </label>
            <input
              v-model="form.maNhanVien"
              type="text"
              placeholder="VD: NV001"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
              :class="{ 'border-red-500': errors.maNhanVien }"
            />
            <p v-if="errors.maNhanVien" class="mt-1 text-sm text-red-500">{{ errors.maNhanVien }}</p>
          </div>

          <!-- Họ tên -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Họ tên <span class="text-red-500">*</span>
            </label>
            <input
              v-model="form.hoTen"
              type="text"
              placeholder="Nguyễn Văn A"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
              :class="{ 'border-red-500': errors.hoTen }"
            />
            <p v-if="errors.hoTen" class="mt-1 text-sm text-red-500">{{ errors.hoTen }}</p>
          </div>

          <!-- Email -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Email <span class="text-red-500">*</span>
            </label>
            <input
              v-model="form.email"
              type="email"
              placeholder="email@example.com"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
              :class="{ 'border-red-500': errors.email }"
            />
            <p v-if="errors.email" class="mt-1 text-sm text-red-500">{{ errors.email }}</p>
          </div>

          <!-- Số điện thoại -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Số điện thoại
            </label>
            <input
              v-model="form.soDienThoai"
              type="tel"
              placeholder="0901234567"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
            />
          </div>

          <!-- Password fields -->
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                Mật khẩu <span class="text-red-500">*</span>
              </label>
              <input
                v-model="form.password"
                type="password"
                placeholder="Tối thiểu 6 ký tự"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                :class="{ 'border-red-500': errors.password }"
              />
              <p v-if="errors.password" class="mt-1 text-sm text-red-500">{{ errors.password }}</p>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                Xác nhận mật khẩu <span class="text-red-500">*</span>
              </label>
              <input
                v-model="form.confirmPassword"
                type="password"
                placeholder="Nhập lại mật khẩu"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                :class="{ 'border-red-500': errors.confirmPassword }"
              />
              <p v-if="errors.confirmPassword" class="mt-1 text-sm text-red-500">{{ errors.confirmPassword }}</p>
            </div>
          </div>

          <!-- Role & Quay -->
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                Vai trò <span class="text-red-500">*</span>
              </label>
              <select
                v-model="form.roleId"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                :class="{ 'border-red-500': errors.roleId }"
              >
                <option :value="null" disabled>Chọn vai trò</option>
                <option v-for="role in roles" :key="role.id" :value="role.id">
                  {{ role.displayName }}
                </option>
              </select>
              <p v-if="errors.roleId" class="mt-1 text-sm text-red-500">{{ errors.roleId }}</p>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                Quầy làm việc
              </label>
              <select
                v-model="form.quayId"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                :disabled="form.roleId === 1"
              >
                <option :value="null">-- Chưa phân quầy --</option>
                <option v-for="quay in quays" :key="quay.id" :value="quay.id">
                  {{ quay.deskName }}
                </option>
              </select>
            </div>
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
            {{ submitting ? 'Đang tạo...' : 'Tạo tài khoản' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue';
import { X, Loader2 } from 'lucide-vue-next';
import { userApi, roleApi, serviceDeskApi, type RoleData, type ServiceDeskData, type UserData } from '@/services/api';

// Emits
const emit = defineEmits<{
  close: [];
  created: [user: UserData];
}>();

// State
const roles = ref<RoleData[]>([]);
const quays = ref<ServiceDeskData[]>([]);
const submitting = ref(false);
const submitError = ref<string | null>(null);

const form = reactive({
  maNhanVien: '',
  hoTen: '',
  email: '',
  soDienThoai: '',
  password: '',
  confirmPassword: '',
  roleId: null as number | null,
  quayId: null as number | null,
});

const errors = reactive({
  maNhanVien: '',
  hoTen: '',
  email: '',
  password: '',
  confirmPassword: '',
  roleId: '',
});

// Methods
function validate(): boolean {
  let isValid = true;
  
  // Reset errors
  Object.keys(errors).forEach(key => {
    errors[key as keyof typeof errors] = '';
  });

  if (!form.maNhanVien.trim()) {
    errors.maNhanVien = 'Vui lòng nhập mã nhân viên';
    isValid = false;
  }

  if (!form.hoTen.trim()) {
    errors.hoTen = 'Vui lòng nhập họ tên';
    isValid = false;
  }

  if (!form.email.trim()) {
    errors.email = 'Vui lòng nhập email';
    isValid = false;
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
    errors.email = 'Email không đúng định dạng';
    isValid = false;
  }

  if (!form.password) {
    errors.password = 'Vui lòng nhập mật khẩu';
    isValid = false;
  } else if (form.password.length < 6) {
    errors.password = 'Mật khẩu ít nhất 6 ký tự';
    isValid = false;
  }

  if (!form.confirmPassword) {
    errors.confirmPassword = 'Vui lòng xác nhận mật khẩu';
    isValid = false;
  } else if (form.password !== form.confirmPassword) {
    errors.confirmPassword = 'Mật khẩu không khớp';
    isValid = false;
  }

  if (!form.roleId) {
    errors.roleId = 'Vui lòng chọn vai trò';
    isValid = false;
  }

  return isValid;
}

async function handleSubmit() {
  if (!validate()) return;

  submitting.value = true;
  submitError.value = null;

  try {
    const response = await userApi.create({
      maNhanVien: form.maNhanVien.trim(),
      hoTen: form.hoTen.trim(),
      email: form.email.trim(),
      soDienThoai: form.soDienThoai.trim() || undefined,
      password: form.password,
      roleId: form.roleId!,
      quayId: form.quayId || undefined,
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

async function fetchDropdownData() {
  try {
    const [rolesRes, quaysRes] = await Promise.all([
      roleApi.getAll(),
      serviceDeskApi.getAll(),
    ]);
    
    if (rolesRes.data.success) {
      roles.value = rolesRes.data.data;
    }
    if (quaysRes.data.success) {
      quays.value = quaysRes.data.data;
    }
  } catch (err) {
    console.error('Failed to fetch dropdown data:', err);
  }
}

// Lifecycle
onMounted(() => {
  fetchDropdownData();
});
</script>
