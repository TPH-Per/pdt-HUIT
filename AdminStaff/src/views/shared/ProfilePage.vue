<template>
  <div class="space-y-6 max-w-6xl mx-auto pb-10 animate-in fade-in slide-in-from-bottom-4 duration-500">
    
    <!-- Header Section -->
    <div class="relative rounded-xl overflow-hidden bg-gradient-to-r from-blue-600 via-indigo-600 to-purple-600 shadow-xl min-h-[160px] flex items-end p-6 md:p-8">
      <div class="absolute inset-0 bg-[url('https://grainy-gradients.vercel.app/noise.svg')] opacity-20"></div>
      <div class="relative z-10 flex flex-col md:flex-row md:items-end gap-6 w-full">
        <!-- Avatar Wrapper -->
        <div class="relative shrink-0">
          <div class="h-24 w-24 md:h-32 md:w-32 bg-white rounded-full p-1 shadow-2xl ring-4 ring-white/20">
            <div class="h-full w-full bg-gradient-to-br from-indigo-100 to-blue-50 rounded-full flex items-center justify-center text-indigo-600 text-3xl md:text-4xl font-bold uppercase select-none">
              {{ user?.hoTen?.charAt(0) || 'U' }}
            </div>
          </div>
          <!-- Status Indicator -->
          <div class="absolute bottom-2 right-2 h-6 w-6 bg-green-500 border-4 border-white rounded-full shadow-sm" title="Online"></div>
        </div>
        
        <!-- User Basic Info -->
        <div class="flex-1 text-white pb-2 text-center md:text-left">
          <h1 class="text-3xl font-bold tracking-tight shadow-black/10 drop-shadow-sm">{{ user?.hoTen || 'Người dùng' }}</h1>
          <div class="flex flex-wrap items-center justify-center md:justify-start gap-2 mt-2 text-blue-100">
            <span class="px-2.5 py-0.5 rounded-full bg-white/20 backdrop-blur-sm border border-white/10 text-sm font-medium">
              {{ user?.roleDisplayName || 'Cán bộ' }}
            </span>
            <span v-if="user?.tenQuay" class="px-2.5 py-0.5 rounded-full bg-indigo-500/30 backdrop-blur-sm border border-white/10 text-sm">
              {{ user.tenQuay }}
            </span>
            <span class="px-2.5 py-0.5 rounded-full bg-black/20 backdrop-blur-sm border border-white/10 text-sm font-mono">
              #{{ user?.maNhanVien }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Left Sidebar: Menu & Stats -->
      <div class="space-y-6">
        <Card class="border-none shadow-md overflow-hidden">
          <div class="p-2 space-y-1">
            <button 
              @click="activeTab = 'general'"
              class="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition-all duration-200"
              :class="activeTab === 'general' ? 'bg-indigo-50 text-indigo-700 shadow-sm' : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'"
            >
              <UserCircle class="h-5 w-5" />
              Thông tin chung
            </button>
            <button 
              @click="activeTab = 'security'"
              class="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition-all duration-200"
              :class="activeTab === 'security' ? 'bg-indigo-50 text-indigo-700 shadow-sm' : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'"
            >
              <ShieldCheck class="h-5 w-5" />
              Bảo mật & Mật khẩu
            </button>
          </div>
        </Card>

        <!-- Stats / Additional Info -->
        <Card class="border-none shadow-md bg-gradient-to-br from-gray-900 to-slate-800 text-white">
          <CardHeader>
            <CardTitle class="text-base font-medium text-gray-200 flex items-center gap-2">
              <Activity class="h-4 w-4 text-blue-400" />
              Thông tin hoạt động
            </CardTitle>
          </CardHeader>
          <CardContent class="grid gap-4">
            <div class="flex items-center justify-between p-3 rounded-lg bg-white/5 border border-white/5">
               <span class="text-sm text-gray-400">Trạng thái</span>
               <Badge class="bg-green-500/20 text-green-300 hover:bg-green-500/30 border-green-500/20">Hoạt động</Badge>
            </div>
            <div class="flex items-center justify-between p-3 rounded-lg bg-white/5 border border-white/5">
               <span class="text-sm text-gray-400">Đăng nhập lần cuối</span>
               <span class="text-sm font-medium text-white">{{ formatDate(user?.lanDangNhapCuoi) }}</span>
            </div>
            <div class="flex items-center justify-between p-3 rounded-lg bg-white/5 border border-white/5">
                <span class="text-sm text-gray-400">Ngày tham gia</span>
                <span class="text-sm font-medium text-white">{{ formatDate((user as any)?.ngayTao) }}</span>
            </div>
          </CardContent>
        </Card>
      </div>

      <!-- Right Content: Forms -->
      <div class="lg:col-span-2">
        
        <!-- Tab: General Info -->
        <div v-show="activeTab === 'general'" class="space-y-6 animate-in fade-in slide-in-from-right-4 duration-300">
          <Card class="border-none shadow-md">
            <CardHeader class="border-b bg-gray-50/50 pb-4">
              <div class="flex items-center justify-between">
                <div>
                  <CardTitle class="text-xl text-gray-800">Thông tin cá nhân</CardTitle>
                  <p class="text-sm text-gray-500 mt-1">Cập nhật thông tin cơ bản của bạn</p>
                </div>
                <Button 
                  v-if="!isEditing"
                  @click="isEditing = true"
                  variant="outline" 
                  size="sm"
                  class="gap-2 border-indigo-200 text-indigo-700 hover:bg-indigo-50 hover:text-indigo-800"
                >
                  <Pencil class="h-3.5 w-3.5" />
                  Chỉnh sửa
                </Button>
              </div>
            </CardHeader>
            <CardContent class="p-6">
              <form @submit.prevent="updateProfile">
                <div class="grid gap-6">
                  <div class="grid gap-2">
                    <Label>Họ và tên</Label>
                    <div class="relative">
                      <User class="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
                      <Input 
                        v-model="form.hoTen" 
                        :disabled="!isEditing"
                        class="pl-9"
                        placeholder="Nhập họ và tên đầy đủ"
                      />
                    </div>
                  </div>

                  <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div class="grid gap-2">
                      <Label>Email</Label>
                      <div class="relative">
                        <Mail class="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
                        <Input 
                          v-model="form.email" 
                          type="email" 
                          :disabled="!isEditing"
                          class="pl-9"
                          placeholder="example@domain.com"
                        />
                      </div>
                    </div>
                    <div class="grid gap-2">
                      <Label>Số điện thoại</Label>
                      <div class="relative">
                        <Phone class="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
                        <Input 
                          v-model="form.soDienThoai" 
                          :disabled="!isEditing"
                          class="pl-9"
                          placeholder="Số điện thoại liên hệ"
                        />
                      </div>
                    </div>
                  </div>

                  <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div class="grid gap-2 opacity-75">
                        <Label>Mã nhân viên</Label>
                         <div class="relative">
                          <Hash class="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
                          <Input :model-value="user?.maNhanVien" disabled class="pl-9 bg-gray-50 text-gray-500 font-mono" />
                        </div>
                    </div>
                    <div class="grid gap-2 opacity-75">
                        <Label>Vai trò hệ thống</Label>
                        <div class="relative">
                          <Shield class="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
                          <Input :model-value="user?.roleDisplayName" disabled class="pl-9 bg-gray-50 text-gray-500" />
                        </div>
                    </div>
                  </div>
                </div>

                <!-- Action Buttons -->
                <div v-if="isEditing" class="flex gap-3 mt-8 pt-6 border-t animate-in fade-in slide-in-from-top-2">
                  <Button type="submit" :disabled="saving" class="bg-blue-600 hover:bg-blue-700 text-white min-w-[120px]">
                    <Loader2 v-if="saving" class="h-4 w-4 mr-2 animate-spin" />
                    {{ saving ? 'Đang lưu...' : 'Lưu thay đổi' }}
                  </Button>
                  <Button type="button" variant="outline" @click="cancelEdit" :disabled="saving" class="min-w-[100px]">
                    Hủy bỏ
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>
        </div>

        <!-- Tab: Security -->
        <div v-show="activeTab === 'security'" class="space-y-6 animate-in fade-in slide-in-from-right-4 duration-300">
           <Card class="border-none shadow-md">
            <CardHeader class="border-b bg-gray-50/50 pb-4">
               <div>
                  <CardTitle class="text-xl text-gray-800">Đổi mật khẩu</CardTitle>
                  <p class="text-sm text-gray-500 mt-1">Nên sử dụng mật khẩu mạnh để bảo vệ tài khoản</p>
               </div>
            </CardHeader>
            <CardContent class="p-6">
               <form @submit.prevent="changePassword" class="space-y-4 max-w-md">
                  <div class="grid gap-2">
                    <Label>Mật khẩu hiện tại</Label>
                    <div class="relative">
                      <Lock class="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
                      <Input 
                        v-model="passwordForm.currentPassword" 
                        :type="showCurrentPassword ? 'text' : 'password'"
                        class="pl-9 pr-10 transition-all focus:ring-2 focus:ring-indigo-100" 
                        placeholder="••••••••"
                      />
                      <button 
                        type="button"
                        @click="showCurrentPassword = !showCurrentPassword"
                        class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-indigo-600 transition-colors p-1"
                      >
                        <Eye v-if="!showCurrentPassword" class="h-4 w-4" />
                        <EyeOff v-else class="h-4 w-4" />
                      </button>
                    </div>
                  </div>

                  <div class="grid gap-2">
                    <Label>Mật khẩu mới</Label>
                    <div class="relative">
                      <Key class="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
                      <Input 
                        v-model="passwordForm.newPassword" 
                        :type="showNewPassword ? 'text' : 'password'"
                        class="pl-9 pr-10 transition-all focus:ring-2 focus:ring-indigo-100" 
                        placeholder="••••••••"
                      />
                      <button 
                        type="button"
                        @click="showNewPassword = !showNewPassword"
                        class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-indigo-600 transition-colors p-1"
                      >
                        <Eye v-if="!showNewPassword" class="h-4 w-4" />
                        <EyeOff v-else class="h-4 w-4" />
                      </button>
                    </div>
                     <p class="text-xs text-gray-500">* Tối thiểu 6 ký tự</p>
                  </div>

                  <div class="grid gap-2">
                    <Label>Xác nhận mật khẩu</Label>
                    <div class="relative">
                      <Key class="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
                      <Input 
                        v-model="passwordForm.confirmPassword" 
                        :type="showConfirmPassword ? 'text' : 'password'"
                        class="pl-9 pr-10 transition-all focus:ring-2 focus:ring-indigo-100" 
                        placeholder="••••••••"
                      />
                      <button 
                        type="button"
                        @click="showConfirmPassword = !showConfirmPassword"
                        class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-indigo-600 transition-colors p-1"
                      >
                        <Eye v-if="!showConfirmPassword" class="h-4 w-4" />
                        <EyeOff v-else class="h-4 w-4" />
                      </button>
                    </div>
                    <p v-if="passwordForm.newPassword && passwordForm.confirmPassword && passwordForm.newPassword !== passwordForm.confirmPassword" 
                       class="text-xs text-red-500 mt-1 font-medium flex items-center gap-1 animate-pulse">
                       <AlertCircle class="h-3 w-3" /> Mật khẩu không khớp
                    </p>
                  </div>

                  <div class="pt-4">
                    <Button 
                      type="submit" 
                      :disabled="changingPassword || !isPasswordFormValid"
                      class="w-full bg-blue-600 hover:bg-blue-700 text-white"
                    >
                      <Loader2 v-if="changingPassword" class="h-4 w-4 mr-2 animate-spin" />
                      {{ changingPassword ? 'Đang xử lý...' : 'Cập nhật mật khẩu' }}
                    </Button>
                  </div>
               </form>
            </CardContent>
           </Card>
        </div>

      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { 
  UserCircle, 
  ShieldCheck, 
  Activity, 
  Pencil, 
  User, 
  Mail, 
  Phone, 
  Hash, 
  Shield, 
  Loader2,
  Lock,
  Key,
  Eye,
  EyeOff,
  AlertCircle
} from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import { useAuthStore } from '@/stores/auth'
import api from '@/services/api'

// Components
import Card from '@/components/ui/card/Card.vue'
import CardHeader from '@/components/ui/card/CardHeader.vue'
import CardTitle from '@/components/ui/card/CardTitle.vue'
import CardContent from '@/components/ui/card/CardContent.vue'
import Button from '@/components/ui/button/Button.vue'
import Input from '@/components/ui/input/Input.vue'
import Badge from '@/components/ui/badge/Badge.vue'

// Helper component for Label (simple text wrapper)
const Label = 'label'

const authStore = useAuthStore()
const user = computed(() => authStore.user)

// Tabs
const activeTab = ref('general')

// Edit profile state
const isEditing = ref(false)
const saving = ref(false)
const form = ref({
  hoTen: '',
  email: '',
  soDienThoai: ''
})

// Change password state
const changingPassword = ref(false)
const showCurrentPassword = ref(false)
const showNewPassword = ref(false)
const showConfirmPassword = ref(false)
const passwordForm = ref({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const isPasswordFormValid = computed(() => {
  return passwordForm.value.currentPassword.length > 0 &&
         passwordForm.value.newPassword.length >= 6 &&
         passwordForm.value.newPassword === passwordForm.value.confirmPassword
})

// Initialize Data
const initFormData = () => {
  if (user.value) {
    form.value = {
      hoTen: user.value.hoTen || '',
      email: user.value.email || '',
      soDienThoai: user.value.soDienThoai || ''
    }
  }
}

onMounted(() => {
  initFormData()
})

watch(activeTab, () => {
  // Reset states when switching tabs if needed
  if (activeTab.value === 'general' && !isEditing.value) {
     initFormData()
  }
})

const cancelEdit = () => {
  isEditing.value = false
  initFormData()
}

const updateProfile = async () => {
  saving.value = true
  try {
    const response = await api.put('/auth/profile', form.value)
    if (response.data.success) {
      // Update store and local storage
      const updatedUser = { ...user.value, ...form.value }
      localStorage.setItem('user', JSON.stringify(updatedUser))
      authStore.user = updatedUser as typeof authStore.user
      
      toast.success('Cập nhật hồ sơ thành công!')
      isEditing.value = false
    } else {
      toast.error(response.data.message || 'Cập nhật thất bại')
    }
  } catch (error: any) {
    console.error(error)
    toast.error(error.response?.data?.message || 'Có lỗi xảy ra khi lưu thông tin')
  } finally {
    saving.value = false
  }
}

const changePassword = async () => {
  if (!isPasswordFormValid.value) return
  
  changingPassword.value = true
  try {
    const response = await api.post('/auth/change-password', {
      currentPassword: passwordForm.value.currentPassword,
      newPassword: passwordForm.value.newPassword
    })
    
    if (response.data.success) {
      toast.success('Đổi mật khẩu thành công! Vui lòng đăng nhập lại.')
      
      // Clear form
      passwordForm.value = {
        currentPassword: '',
        newPassword: '',
        confirmPassword: ''
      }
      
      // Optional: Logout user to force re-login with new password
      // await authStore.logout()
    } else {
      toast.error(response.data.message || 'Không thể đổi mật khẩu')
    }
  } catch (error: any) {
    if (error.response?.status === 400) {
       toast.error('Mật khẩu hiện tại không chính xác')
    } else {
       toast.error('Lỗi hệ thống khi đổi mật khẩu')
    }
  } finally {
    changingPassword.value = false
  }
}

const formatDate = (dateStr: string | undefined | null) => {
  if (!dateStr) return 'N/A'
  return new Date(dateStr).toLocaleDateString('vi-VN', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}
</script>

<style scoped>
/* Custom label style */
label {
  display: block;
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151; /* text-gray-700 */
  margin-bottom: 0.25rem;
}
</style>
