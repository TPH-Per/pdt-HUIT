<template>
  <div class="space-y-8 p-6 animate-fade-in-up">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
      <div>
        <h1 class="text-3xl font-bold bg-gradient-to-r from-blue-700 to-indigo-700 bg-clip-text text-transparent">
          Quản lý tài khoản
        </h1>
        <p class="text-gray-500 mt-2 font-medium">Hệ thống phân quyền và quản lý nhân viên</p>
      </div>
      <button
        @click="openCreateModal"
        class="group flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-xl shadow-lg shadow-blue-500/30 hover:shadow-blue-500/40 hover:-translate-y-0.5 transition-all duration-300 font-medium"
      >
        <Plus :size="20" class="group-hover:rotate-90 transition-transform duration-300" />
        Thêm tài khoản
      </button>
    </div>

    <!-- Stats Cards -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
      <div class="bg-white rounded-2xl p-5 border border-gray-100 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 group">
        <div class="flex items-center gap-4">
          <div class="p-3 bg-blue-50 text-blue-600 rounded-xl group-hover:scale-110 transition-transform duration-300">
            <Users :size="24" />
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">Tổng nhân viên</p>
            <p class="text-2xl font-bold text-gray-800 mt-1">{{ users.length }}</p>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-2xl p-5 border border-gray-100 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 group">
        <div class="flex items-center gap-4">
          <div class="p-3 bg-green-50 text-green-600 rounded-xl group-hover:scale-110 transition-transform duration-300">
            <UserCheck :size="24" />
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">Đang hoạt động</p>
            <p class="text-2xl font-bold text-gray-800 mt-1">{{ activeUsers }}</p>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-2xl p-5 border border-gray-100 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 group">
        <div class="flex items-center gap-4">
          <div class="p-3 bg-purple-50 text-purple-600 rounded-xl group-hover:scale-110 transition-transform duration-300">
            <Shield :size="24" />
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">Quản trị viên</p>
            <p class="text-2xl font-bold text-gray-800 mt-1">{{ adminCount }}</p>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-2xl p-5 border border-gray-100 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 group">
        <div class="flex items-center gap-4">
          <div class="p-3 bg-orange-50 text-orange-600 rounded-xl group-hover:scale-110 transition-transform duration-300">
            <UserX :size="24" />
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">Đã khóa</p>
            <p class="text-2xl font-bold text-gray-800 mt-1">{{ inactiveUsers }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- User Table -->
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
          @click="fetchUsers" 
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
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Mã NV</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Họ tên</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Email</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Vai trò</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Quầy</th>
              <th class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Trạng thái</th>
              <th class="px-6 py-4 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Thao tác</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-50">
            <tr v-for="user in users" :key="user.id" class="hover:bg-blue-50/30 transition-colors duration-200 group">
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="font-mono text-sm font-semibold text-blue-600 bg-blue-50 px-2 py-1 rounded-md">
                  {{ user.maNhanVien }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center gap-3">
                  <div class="h-9 w-9 rounded-full bg-gradient-to-br from-blue-100 to-indigo-100 flex items-center justify-center text-blue-700 font-bold text-sm shadow-sm ring-2 ring-white">
                    {{ getInitials(user.hoTen) }}
                  </div>
                  <span class="text-gray-900 font-medium">{{ user.hoTen }}</span>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-gray-600">{{ user.email }}</td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span
                  :class="[
                    'px-2.5 py-1 text-xs font-medium rounded-full border',
                    user.roleName === 'Admin' 
                      ? 'bg-purple-50 text-purple-700 border-purple-100' 
                      : 'bg-blue-50 text-blue-700 border-blue-100'
                  ]"
                >
                  {{ user.roleDisplayName }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-gray-600">
                <div class="flex items-center gap-1.5" v-if="user.tenQuay">
                   <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-50 text-blue-700 border border-blue-100">
                     {{ user.tenQuay }}
                   </span>
                </div>
                <span v-else class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-600 border border-gray-200">
                  <span class="w-1.5 h-1.5 rounded-full bg-gray-400 mr-1.5"></span>
                  Chưa phân công
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span
                  :class="[
                    'px-3 py-1 text-xs font-medium rounded-full inline-flex items-center gap-1.5',
                    user.trangThai 
                      ? 'bg-green-50 text-green-700 border border-green-200' 
                      : 'bg-red-50 text-red-700 border border-red-200'
                  ]"
                >
                  <span class="w-1.5 h-1.5 rounded-full" :class="user.trangThai ? 'bg-green-500' : 'bg-red-500'"></span>
                  {{ user.trangThai ? 'Hoạt động' : 'Đã khóa' }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right">
                <div class="flex justify-end">
                  <ActionMenu 
                    :is-active="user.trangThai"
                    :show-reset-password="true"
                    @edit="editUser(user)"
                    @reset-password="resetPassword(user)"
                    @toggle-status="toggleUserStatus(user)"
                  />
                </div>
              </td>
            </tr>
            
            <!-- Empty State -->
            <tr v-if="users.length === 0">
              <td colspan="7" class="px-6 py-24 text-center">
                <div class="w-24 h-24 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Users :size="48" class="text-gray-300" />
                </div>
                <p class="text-gray-500 font-medium text-lg">Chưa có tài khoản nào</p>
                <p class="text-gray-400 text-sm mt-1">Bắt đầu bằng cách thêm tài khoản mới</p>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Create User Modal -->
    <CreateUserModal
      v-if="showCreateModal"
      @close="showCreateModal = false"
      @created="onUserCreated"
    />

    <!-- Edit User Modal (Admin editing another user) -->
    <EditProfileModal
      v-if="showEditModal"
      :editing-user="editingUser"
      @close="showEditModal = false; editingUser = null"
      @updated="onUserUpdated"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { 
  Plus, Users, UserCheck, UserX, Shield, AlertCircle 
} from 'lucide-vue-next';
import { userApi, type UserData } from '@/services/api';
import { useToast } from "vue-toastification";
import Swal from 'sweetalert2';
import CreateUserModal from '@/components/admin/CreateUserModal.vue';
import EditProfileModal from '@/components/shared/EditProfileModal.vue';
import ActionMenu from '@/components/shared/ActionMenu.vue';

// State
const users = ref<UserData[]>([]);
const loading = ref(false);
const error = ref<string | null>(null);
const showCreateModal = ref(false);
const showEditModal = ref(false);
const editingUser = ref<UserData | null>(null);
const toast = useToast();

// Computed
const activeUsers = computed(() => users.value.filter(u => u.trangThai).length);
const inactiveUsers = computed(() => users.value.filter(u => !u.trangThai).length);
const adminCount = computed(() => users.value.filter(u => u.roleName === 'Admin').length);

// Methods
function getInitials(name: string): string {
  return name
    .split(' ')
    .map(w => w[0])
    .join('')
    .substring(0, 2)
    .toUpperCase();
}

async function fetchUsers() {
  loading.value = true;
  error.value = null;
  
  try {
    const response = await userApi.getAll();
    if (response.data.success) {
      users.value = response.data.data;
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

function onUserCreated(newUser: UserData) {
  users.value.unshift(newUser);
  showCreateModal.value = false;
  toast.success('Thêm tài khoản thành công');
}

function editUser(user: UserData) {
  editingUser.value = user;
  showEditModal.value = true;
}

function onUserUpdated(updatedUser: UserData) {
  // Update user in list
  const index = users.value.findIndex(u => u.id === updatedUser.id);
  if (index !== -1) {
    users.value[index] = updatedUser;
  }
  showEditModal.value = false;
  editingUser.value = null;
  toast.success('Cập nhật tài khoản thành công');
}

async function toggleUserStatus(user: UserData) {
  const action = user.trangThai ? 'khóa' : 'mở khóa';
  const result = await Swal.fire({
    title: 'Xác nhận',
    text: `Bạn có chắc muốn ${action} tài khoản ${user.hoTen}?`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonColor: '#3085d6',
    cancelButtonColor: '#d33',
    confirmButtonText: 'Đồng ý',
    cancelButtonText: 'Hủy'
  });

  if (!result.isConfirmed) return;
  
  try {
    if (user.trangThai) {
      await userApi.delete(user.id);
    } else {
      await userApi.update(user.id, { trangThai: true });
    }
    user.trangThai = !user.trangThai;
    toast.success(`Đã ${action} tài khoản ${user.hoTen}`);
  } catch (err: any) {
    toast.error(err.response?.data?.message || 'Có lỗi xảy ra');
  }
}

async function resetPassword(user: UserData) {
  const { value: newPassword } = await Swal.fire({
    title: `Đặt lại mật khẩu cho ${user.hoTen}`,
    input: 'password',
    inputLabel: 'Nhập mật khẩu mới',
    inputPlaceholder: 'Mật khẩu',
    showCancelButton: true,
    inputValidator: (value) => {
      if (!value) {
        return 'Bạn cần nhập mật khẩu!'
      }
      if (value.length < 6) {
        return 'Mật khẩu phải có ít nhất 6 ký tự'
      }
    }
  });
  
  if (newPassword) {
    try {
      await userApi.resetPassword(user.id, newPassword);
      toast.success(`Đã đặt lại mật khẩu cho ${user.hoTen}`);
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Có lỗi xảy ra');
    }
  }
}

// Lifecycle
onMounted(() => {
  fetchUsers();
});
</script>
