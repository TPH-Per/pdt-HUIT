<template>
  <div class="min-h-screen flex flex-col items-center justify-center p-4 relative bg-[#F4F6F9]">
    <!-- Background Pattern -->
    <div class="absolute inset-0 z-0 overflow-hidden">
      <div class="absolute inset-0 bg-gradient-to-br from-[#003865] via-[#0B4271] to-[#002d51]"></div>
      <!-- Decorative circles -->
      <div class="absolute top-[-20%] right-[-10%] w-[600px] h-[600px] bg-white/5 rounded-full blur-3xl"></div>
      <div class="absolute bottom-[-20%] left-[-10%] w-[500px] h-[500px] bg-[#D31826]/10 rounded-full blur-3xl"></div>
    </div>

    <!-- Login Container -->
    <div class="relative z-10 w-full max-w-[420px]">
      
      <!-- Logo & Title -->
      <div class="text-center mb-8">
        <div class="inline-flex items-center justify-center h-20 w-20 bg-white rounded-2xl shadow-2xl p-2 mb-4">
          <img 
            src="@/assets/image/huit_logo.webp" 
            alt="Logo HUIT" 
            class="h-full w-full object-contain" 
          />
        </div>
        <h1 class="text-2xl font-bold text-white mb-1">Phòng Đào tạo</h1>
        <p class="text-blue-200/80 text-sm">Trường Đại học Công Thương TP.HCM</p>
      </div>

      <!-- Back Layer (Decoration) -->
      <div class="absolute inset-x-0 bottom-0 top-[140px] bg-[#002d51] rounded-[24px] translate-x-3 translate-y-3"></div>

      <!-- Front Layer (Content) -->
      <div class="relative bg-white rounded-[24px] p-8 md:p-10 shadow-xl overflow-hidden">
        
        <!-- Header -->
        <h2 class="text-center text-xl font-bold text-[#1A1A1A] mb-6">Đăng nhập hệ thống</h2>
        
        <form @submit.prevent="handleLogin" class="space-y-5">
          <!-- Username -->
          <div>
            <label for="username" class="block text-sm font-semibold text-[#333333] mb-2">
              Mã cán bộ
            </label>
            <div class="relative">
              <span class="absolute left-4 top-1/2 -translate-y-1/2 text-[#6C757D]">
                <User class="h-5 w-5" />
              </span>
              <input
                id="username"
                v-model="form.username"
                type="text"
                required
                placeholder="Nhập mã cán bộ"
                class="w-full pl-11 pr-4 py-3.5 bg-[#F4F6F9] border border-[#DEE2E6] rounded-xl focus:ring-2 focus:ring-[#003865] focus:border-[#003865] transition-all outline-none text-[#333333]"
              />
            </div>
          </div>

          <!-- Password -->
          <div>
            <label for="password" class="block text-sm font-semibold text-[#333333] mb-2">
              Mật khẩu
            </label>
            <div class="relative">
              <span class="absolute left-4 top-1/2 -translate-y-1/2 text-[#6C757D]">
                <Lock class="h-5 w-5" />
              </span>
              <input
                id="password"
                v-model="form.password"
                :type="showPassword ? 'text' : 'password'"
                required
                placeholder="Nhập mật khẩu"
                class="w-full pl-11 pr-12 py-3.5 bg-[#F4F6F9] border border-[#DEE2E6] rounded-xl focus:ring-2 focus:ring-[#003865] focus:border-[#003865] transition-all outline-none text-[#333333]"
              />
              <button
                type="button"
                @click="showPassword = !showPassword"
                class="absolute right-4 top-1/2 -translate-y-1/2 text-[#6C757D] hover:text-[#003865]"
              >
                <EyeOff v-if="showPassword" class="h-5 w-5" />
                <Eye v-else class="h-5 w-5" />
              </button>
            </div>
          </div>

          <!-- Remember & Forgot Password -->
          <div class="flex items-center justify-between pt-1">
            <label class="flex items-center cursor-pointer">
              <input
                v-model="form.remember"
                type="checkbox"
                class="w-5 h-5 text-[#003865] border-[#DEE2E6] rounded focus:ring-[#003865] rounded-md"
              />
              <span class="ml-2 text-sm text-[#6C757D]">Ghi nhớ đăng nhập</span>
            </label>
            <a href="#" class="text-sm text-[#003865] hover:text-[#0B4271] font-semibold">
              Quên mật khẩu?
            </a>
          </div>

          <!-- Error Message -->
          <div v-if="authStore.error" class="bg-red-50 border-l-4 border-[#D31826] p-4 rounded-r mt-4">
            <div class="flex">
              <AlertCircle class="h-5 w-5 text-[#D31826]" />
              <p class="ml-3 text-sm text-[#D31826]">{{ authStore.error }}</p>
            </div>
          </div>

          <!-- Login Button -->
          <button
            type="submit"
            :disabled="authStore.loading"
            class="w-full py-4 px-6 bg-[#003865] text-white font-bold rounded-xl shadow-lg hover:bg-[#0B4271] focus:ring-4 focus:ring-[#003865]/30 transition-all transform active:scale-[0.98] mt-2 flex items-center justify-center gap-2 text-base disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Loader2 v-if="authStore.loading" class="h-5 w-5 animate-spin" />
            <span v-else class="flex items-center gap-2">
              <LogIn class="h-5 w-5" />
              Đăng nhập
            </span>
          </button>
        </form>

        <!-- Footer -->
        <p class="text-center text-xs text-[#6C757D] mt-6">
          © 2026 Phòng Đào tạo · <span class="text-[#D31826] font-bold">HUIT</span>
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { User, Lock, Eye, EyeOff, LogIn, AlertCircle, Loader2 } from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

// Form state
const form = reactive({
  username: '',
  password: '',
  remember: false
})

const showPassword = ref(false)

const handleLogin = async () => {
  authStore.clearError()

  const success = await authStore.login({
    maNhanVien: form.username,
    password: form.password
  })

  if (success) {
    if (authStore.isAdmin) {
      router.push('/admin/dashboard')
    } else {
      router.push('/staff/dashboard')
    }
  }
}

onMounted(() => {
  if (authStore.isAuthenticated) {
    if (authStore.isAdmin) {
      router.push('/admin/dashboard')
    } else {
      router.push('/staff/dashboard')
    }
  }
})
</script>
