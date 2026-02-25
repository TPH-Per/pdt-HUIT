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
          <h3 class="text-lg font-semibold text-gray-900">
            {{ isAdmin && editingUser ? 'Chỉnh sửa tài khoản' : 'Chỉnh sửa thông tin cá nhân' }}
          </h3>
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
          <!-- Mã nhân viên (Read-only) -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Mã nhân viên
            </label>
            <input
              :value="currentUser?.maNhanVien"
              type="text"
              disabled
              class="w-full px-3 py-2 border border-gray-200 rounded-lg bg-gray-50 text-gray-500 cursor-not-allowed"
            />
            <p class="mt-1 text-xs text-gray-400">Mã nhân viên không thể thay đổi</p>
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

          <!-- Divider -->
          <div class="relative">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-gray-200"></div>
            </div>
            <div class="relative flex justify-center text-sm">
              <span class="px-2 bg-white text-gray-500">Đổi mật khẩu (tùy chọn)</span>
            </div>
          </div>

          <!-- Password Section for Self-Edit -->
          <template v-if="!isAdmin || !editingUser">
            <!-- Old Password (required when changing password) -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                Mật khẩu hiện tại
              </label>
              <input
                v-model="form.oldPassword"
                type="password"
                placeholder="Nhập mật khẩu hiện tại"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                :class="{ 'border-red-500': errors.oldPassword }"
              />
              <p v-if="errors.oldPassword" class="mt-1 text-sm text-red-500">{{ errors.oldPassword }}</p>
              <p class="mt-1 text-xs text-gray-400">Bắt buộc nếu muốn đổi mật khẩu</p>
            </div>
          </template>

          <!-- New Password -->
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                Mật khẩu mới
              </label>
              <input
                v-model="form.newPassword"
                type="password"
                placeholder="Tối thiểu 6 ký tự"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                :class="{ 'border-red-500': errors.newPassword }"
              />
              <p v-if="errors.newPassword" class="mt-1 text-sm text-red-500">{{ errors.newPassword }}</p>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                Xác nhận mật khẩu
              </label>
              <input
                v-model="form.confirmPassword"
                type="password"
                placeholder="Nhập lại mật khẩu mới"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                :class="{ 'border-red-500': errors.confirmPassword }"
              />
              <p v-if="errors.confirmPassword" class="mt-1 text-sm text-red-500">{{ errors.confirmPassword }}</p>
            </div>
          </div>

          <!-- Admin-only fields: Role & Quay & Trạng thái -->
          <template v-if="isAdmin && editingUser">
            <div class="relative">
              <div class="absolute inset-0 flex items-center">
                <div class="w-full border-t border-gray-200"></div>
              </div>
              <div class="relative flex justify-center text-sm">
                <span class="px-2 bg-white text-gray-500">Cấu hình (Chỉ Admin)</span>
              </div>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Vai trò
                </label>
                <select
                  v-model="form.roleId"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                >
                  <option v-for="role in roles" :key="role.id" :value="role.id">
                    {{ role.displayName }}
                  </option>
                </select>
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

            <!-- Trạng thái -->
            <div class="flex items-center gap-3">
              <label class="relative inline-flex items-center cursor-pointer">
                <input
                  type="checkbox"
                  v-model="form.trangThai"
                  class="sr-only peer"
                />
                <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
              </label>
              <span class="text-sm font-medium text-gray-700">
                {{ form.trangThai ? 'Tài khoản đang hoạt động' : 'Tài khoản bị khóa' }}
              </span>
            </div>
          </template>

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
import { ref, reactive, onMounted, computed } from 'vue';
import { X, Loader2 } from 'lucide-vue-next';
import {
  profileApi,
  userApi,
  roleApi,
  serviceDeskApi,
  type UserData,
  type RoleData,
  type ServiceDeskData
} from '@/services/api';
import { useAuthStore } from '@/stores/auth';

// Props
interface Props {
  /**
   * User đang được edit (chỉ dùng cho Admin edit người khác)
   * Nếu null/undefined -> đang edit chính mình
   */
  editingUser?: UserData | null;
}

const props = withDefaults(defineProps<Props>(), {
  editingUser: null
});

// Emits
const emit = defineEmits<{
  close: [];
  updated: [user: UserData];
}>();

// Store
const authStore = useAuthStore();
const isAdmin = computed(() => authStore.isAdmin);

// State
const loading = ref(true);
const currentUser = ref<UserData | null>(null);
const roles = ref<RoleData[]>([]);
const quays = ref<ServiceDeskData[]>([]);
const submitting = ref(false);
const submitError = ref<string | null>(null);
const submitSuccess = ref<string | null>(null);

const form = reactive({
  hoTen: '',
  email: '',
  soDienThoai: '',
  oldPassword: '',
  newPassword: '',
  confirmPassword: '',
  // Admin-only fields
  roleId: null as number | null,
  quayId: null as number | null,
  trangThai: true,
});

const errors = reactive({
  hoTen: '',
  email: '',
  oldPassword: '',
  newPassword: '',
  confirmPassword: '',
});

// Load data
onMounted(async () => {
  try {
    // Nếu Admin edit người khác -> dùng data từ props
    if (isAdmin.value && props.editingUser) {
      currentUser.value = props.editingUser;

      // Load roles và quays cho Admin
      const [rolesRes, quaysRes] = await Promise.all([
        roleApi.getAll(),
        serviceDeskApi.getAll()
      ]);
      roles.value = rolesRes.data.data;
      quays.value = quaysRes.data.data;
    } else {
      // Staff/Admin edit chính mình -> gọi API profile
      const response = await profileApi.getMyProfile();
      currentUser.value = response.data.data;
    }

    // Populate form
    if (currentUser.value) {
      form.hoTen = currentUser.value.hoTen || '';
      form.email = currentUser.value.email || '';
      form.soDienThoai = currentUser.value.soDienThoai || '';

      // Admin-only fields
      if (isAdmin.value && props.editingUser) {
        // Find roleId from roleName
        const role = roles.value.find(r => r.roleName === currentUser.value!.roleName);
        form.roleId = role?.id || null;
        form.quayId = currentUser.value.quayId;
        form.trangThai = currentUser.value.trangThai;
      }
    }
  } catch (err: any) {
    console.error('Error loading profile:', err);
    submitError.value = 'Không thể tải thông tin. Vui lòng thử lại.';
  } finally {
    loading.value = false;
  }
});

// Validation
function validate(): boolean {
  let isValid = true;

  // Reset errors
  Object.keys(errors).forEach(key => {
    errors[key as keyof typeof errors] = '';
  });

  // Validate họ tên
  if (!form.hoTen.trim()) {
    errors.hoTen = 'Vui lòng nhập họ tên';
    isValid = false;
  }

  // Validate email
  if (!form.email.trim()) {
    errors.email = 'Vui lòng nhập email';
    isValid = false;
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
    errors.email = 'Email không đúng định dạng';
    isValid = false;
  }

  // Validate password change
  if (form.newPassword) {
    // Staff phải nhập mật khẩu cũ
    if (!isAdmin.value || !props.editingUser) {
      if (!form.oldPassword) {
        errors.oldPassword = 'Vui lòng nhập mật khẩu hiện tại';
        isValid = false;
      }
    }

    if (form.newPassword.length < 6) {
      errors.newPassword = 'Mật khẩu mới ít nhất 6 ký tự';
      isValid = false;
    }

    if (form.newPassword !== form.confirmPassword) {
      errors.confirmPassword = 'Mật khẩu xác nhận không khớp';
      isValid = false;
    }
  }

  return isValid;
}

// Submit
async function handleSubmit() {
  submitError.value = null;
  submitSuccess.value = null;

  if (!validate()) return;

  submitting.value = true;

  try {
    let response;

    if (isAdmin.value && props.editingUser) {
      // Admin edit người khác -> call userApi.update
      const updateData: any = {
        hoTen: form.hoTen,
        email: form.email,
        soDienThoai: form.soDienThoai,
        roleId: form.roleId,
        quayId: form.quayId,
        trangThai: form.trangThai,
      };

      // Nếu có đổi password
      if (form.newPassword) {
        updateData.password = form.newPassword;
      }

      response = await userApi.update(props.editingUser.id, updateData);
    } else {
      // Staff/Admin edit chính mình -> call profileApi
      const updateData: any = {
        hoTen: form.hoTen,
        email: form.email,
        soDienThoai: form.soDienThoai,
      };

      // Nếu có đổi password
      if (form.newPassword) {
        updateData.oldPassword = form.oldPassword;
        updateData.newPassword = form.newPassword;
      }

      response = await profileApi.updateMyProfile(updateData);

      // Update localStorage với thông tin mới
      if (response.data.success) {
        const updatedUser = response.data.data;
        localStorage.setItem('user', JSON.stringify(updatedUser));
      }
    }

    if (response.data.success) {
      submitSuccess.value = 'Cập nhật thông tin thành công!';
      currentUser.value = response.data.data;

      // Clear password fields
      form.oldPassword = '';
      form.newPassword = '';
      form.confirmPassword = '';

      // Emit updated event
      emit('updated', response.data.data);

      // Auto close after 1.5s
      setTimeout(() => {
        emit('close');
      }, 1500);
    } else {
      submitError.value = response.data.message || 'Có lỗi xảy ra';
    }
  } catch (err: any) {
    console.error('Update error:', err);
    if (err.response?.data?.message) {
      submitError.value = err.response.data.message;
    } else {
      submitError.value = 'Có lỗi xảy ra. Vui lòng thử lại.';
    }
  } finally {
    submitting.value = false;
  }
}
</script>

