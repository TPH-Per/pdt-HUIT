<template>
  <div class="min-h-screen bg-[#F4F6F9] flex">
    <!-- Sidebar - Dark HUIT Theme for Admin -->
    <aside class="w-72 bg-slate-900 text-white fixed h-full z-20 hidden md:flex flex-col shadow-xl">
      <!-- Logo Area -->
      <div class="p-6 pb-4">
        <div class="flex items-center gap-3 mb-6">
          <div class="h-10 w-10 bg-white rounded-xl flex items-center justify-center shadow-lg overflow-hidden p-1">
            <img 
              src="@/assets/image/huit_logo.webp" 
              alt="Logo HUIT" 
              class="h-full w-full object-contain" 
            />
          </div>
          <div>
            <h1 class="font-bold text-base uppercase tracking-wide">HUIT</h1>
            <p class="text-xs text-slate-400">Trang Quản Trị</p>
          </div>
        </div>
      </div>

      <!-- Navigation -->
      <nav class="flex-1 px-4 space-y-1.5 overflow-y-auto py-4">
        <p class="px-4 text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">QUẢN TRỊ</p>
        <RouterLink
          v-for="item in sidebarItems"
          :key="item.path"
          :to="item.path"
          class="nav-link flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200 group"
          :class="[
            $route.path === item.path 
              ? 'bg-[#003865] text-white shadow-md translate-x-1' 
              : 'text-slate-400 hover:bg-white/5 hover:text-white hover:translate-x-1'
          ]"
        >
          <component 
            :is="item.icon" 
            class="h-5 w-5 transition-colors"
            :class="$route.path === item.path ? 'text-white' : 'text-slate-500 group-hover:text-white'"
          />
          {{ item.label }}
        </RouterLink>
      </nav>

      <!-- User Profile -->
      <div class="p-4 border-t border-white/5 bg-slate-950">
        <div class="flex items-center gap-3 mb-4 bg-white/5 p-3 rounded-xl border border-white/5">
          <div class="h-10 w-10 bg-gradient-to-br from-[#003865] to-[#0B4271] rounded-full flex items-center justify-center text-white font-bold border-2 border-white/20 shadow-inner">
            {{ adminInfo.avatar }}
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-bold text-white truncate">{{ adminInfo.name }}</p>
            <p class="text-xs text-slate-400 truncate">{{ adminInfo.role }}</p>
          </div>
        </div>
        <div class="flex gap-2">
          <button
            @click="showEditProfileModal = true"
            class="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-white/5 hover:bg-white/10 border border-white/5 rounded-lg text-xs font-medium text-slate-400 hover:text-white transition-colors group"
          >
            <UserCog class="h-4 w-4 group-hover:text-[#3374ab] transition-colors" />
            Sửa profile
          </button>
          <button
            @click="handleLogout"
            class="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-white/5 hover:bg-white/10 border border-white/5 rounded-lg text-xs font-medium text-slate-400 hover:text-white transition-colors group"
          >
            <LogOut class="h-4 w-4 group-hover:text-[#D31826] transition-colors" />
            Đăng xuất
          </button>
        </div>
      </div>
    </aside>

    <!-- Main Content -->
    <div class="flex-1 md:ml-72 flex flex-col min-h-screen transition-all duration-300">
      <!-- Top Header -->
      <header class="bg-white border-b border-[#DEE2E6] h-16 px-6 flex items-center justify-between sticky top-0 z-10 shadow-sm">
        <div class="flex items-center gap-4 flex-1">
          <div class="relative w-96 max-w-full">
            <Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-[#6C757D]" />
            <input 
              type="text" 
              placeholder="Tìm kiếm..."
              class="w-full pl-10 pr-4 py-2 bg-[#F4F6F9] border border-[#DEE2E6] rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#003865]/20 focus:border-[#003865] transition-all"
            />
          </div>
        </div>

        <div class="flex items-center gap-4">
          <button class="relative p-2 text-[#6C757D] hover:bg-[#F4F6F9] rounded-full transition-colors">
            <Bell class="h-5 w-5" />
            <span class="absolute top-1.5 right-1.5 h-2 w-2 bg-[#D31826] rounded-full border-2 border-white"></span>
          </button>
        </div>
      </header>

      <!-- Page Content -->
      <main class="flex-1 p-6 overflow-y-auto bg-[#F4F6F9]">
        <RouterView />
      </main>
    </div>

    <!-- Edit Profile Modal -->
    <EditProfileModal
      v-if="showEditProfileModal"
      @close="showEditProfileModal = false"
      @updated="handleProfileUpdated"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  LayoutDashboard, 
  Users, 
  Building2, 
  FileBarChart, 
  LogOut, 
  Search, 
  Bell, 
  UserCog,
  Layers,
  ClipboardList,
  GraduationCap
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'
import EditProfileModal from '@/components/shared/EditProfileModal.vue'

const authStore = useAuthStore()

// Modal state
const showEditProfileModal = ref(false)

// Sidebar navigation items
const sidebarItems = [
  { icon: LayoutDashboard, label: 'Tổng quan', path: '/admin/dashboard' },
  { icon: Users, label: 'Quản lý tài khoản', path: '/admin/accounts' },
  { icon: GraduationCap, label: 'Quản lý sinh viên', path: '/admin/students' },
  { icon: Building2, label: 'Quản lý quầy', path: '/admin/counters' },
  { icon: Layers, label: 'Quản lý danh mục DV', path: '/admin/specialties' },
  { icon: ClipboardList, label: 'Quản lý dịch vụ', path: '/admin/procedures' },
  { icon: FileBarChart, label: 'Báo cáo & Góp ý', path: '/admin/reports' },
  { icon: UserCog, label: 'Tài khoản cá nhân', path: '/admin/profile' },
]

// Lấy thông tin user từ authStore (reactive)
const adminInfo = computed(() => ({
  name: authStore.user?.hoTen || 'Administrator',
  role: authStore.user?.roleDisplayName || 'Quản trị viên',
  avatar: authStore.user?.hoTen?.charAt(0).toUpperCase() || 'AD'
}))

const handleLogout = async () => {
  await authStore.logout()
}

const handleProfileUpdated = () => {
  const userJson = localStorage.getItem('user')
  if (userJson) {
    authStore.user = JSON.parse(userJson)
  }
}
</script>

<style scoped>
.nav-link {
  text-decoration: none;
}
</style>
