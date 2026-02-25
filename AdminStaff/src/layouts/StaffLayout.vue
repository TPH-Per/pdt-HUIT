<template>
  <div class="min-h-screen bg-[#F4F6F9] flex">
    <!-- Sidebar -->
    <aside class="w-72 bg-[#003865] text-white fixed h-full z-20 hidden md:flex flex-col shadow-2xl transition-all duration-300">
      <!-- Logo Area -->
      <div class="p-6 pb-6 border-b border-white/10">
        <div class="flex items-center gap-4">
           <div class="h-12 w-12 bg-white rounded-xl shadow-lg p-1 flex items-center justify-center shrink-0">
             <img 
               src="@/assets/image/huit_logo.webp" 
               alt="Logo HUIT" 
               class="h-full w-full object-contain" 
             />
           </div>
           <div>
             <h1 class="font-bold text-lg uppercase tracking-wide leading-none mb-1">HUIT</h1>
             <span class="text-xs text-blue-200 font-medium bg-blue-500/20 px-2 py-0.5 rounded-full border border-blue-400/20">Phòng Đào tạo</span>
           </div>
        </div>
      </div>

      <!-- Counter Info Widget (Compact) -->
      <div class="px-4 py-6">
        <div class="bg-gradient-to-br from-white/10 to-transparent rounded-xl p-4 border border-white/10 shadow-inner backdrop-blur-sm">
           <div class="flex items-center gap-3 mb-3">
              <div class="p-2 bg-blue-500/20 rounded-lg shrink-0">
                 <Building2 class="h-5 w-5 text-blue-300" />
              </div>
              <div class="flex-1">
                 <p class="text-[10px] text-blue-200 uppercase font-bold tracking-wider">Vị trí làm việc</p>
                 <p class="font-bold text-base truncate">{{ registrarInfo.counter }}</p>
              </div>
           </div>
           <div class="flex items-center justify-between text-xs bg-black/20 rounded-lg p-2">
              <span class="text-blue-200">Trạng thái</span>
              <div class="flex items-center gap-1.5">
                  <span class="relative flex h-2 w-2">
                    <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                    <span class="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
                  </span>
                  <span class="text-green-300 font-bold">Online</span>
              </div>
           </div>
        </div>
      </div>

      <!-- Navigation -->
      <nav class="flex-1 px-3 space-y-1 overflow-y-auto">
        <p class="px-4 text-[10px] font-bold text-blue-300/60 uppercase tracking-widest mb-2 mt-2">Menu chính</p>
        <RouterLink
          v-for="item in sidebarItems"
          :key="item.path"
          :to="item.path"
          class="flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition-all duration-300 group"
          :class="[
            $route.path === item.path 
              ? 'bg-white text-[#003865] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.1)] translate-x-1 font-bold' 
              : 'text-blue-100/80 hover:bg-white/10 hover:text-white hover:translate-x-1'
          ]"
        >
          <component 
            :is="item.icon" 
            class="h-5 w-5 transition-transform duration-300"
            :class="$route.path === item.path ? 'scale-110' : 'group-hover:scale-110'"
          />
          {{ item.label }}
        </RouterLink>
      </nav>

      <!-- User Profile (Bottom) -->
      <div class="p-4 bg-[#002d51]/50 border-t border-white/5 backdrop-blur-md">
        <button 
          @click="showEditProfileModal = true"
          class="flex items-center gap-3 w-full p-2 rounded-xl hover:bg-white/5 transition-colors group text-left"
        >
          <div class="relative">
             <div class="h-10 w-10 bg-gradient-to-br from-blue-400 to-[#003865] rounded-full flex items-center justify-center text-white font-bold border-2 border-white/20 shadow-md">
                {{ registrarInfo.avatar }}
             </div>
             <div class="absolute -bottom-0.5 -right-0.5 bg-green-500 rounded-full p-0.5 border-2 border-[#002d51]">
                <div class="h-2 w-2 bg-white rounded-full"></div>
             </div>
          </div>
          <div class="flex-1 min-w-0">
             <p class="text-sm font-bold text-white truncate group-hover:text-blue-200 transition-colors">{{ registrarInfo.name }}</p>
             <p class="text-xs text-blue-300/80 truncate">{{ registrarInfo.role }}</p>
          </div>
          <ChevronRight class="h-4 w-4 text-blue-300/50 group-hover:text-white transition-transform group-hover:translate-x-1" />
        </button>
        
        <div class="mt-3 pt-3 border-t border-white/5 flex gap-2">
            <button @click="handleLogout" class="flex-1 flex items-center justify-center gap-2 py-2 text-xs font-medium text-red-300 hover:bg-red-500/10 hover:text-red-200 rounded-lg transition-colors">
               <LogOut class="h-3.5 w-3.5" /> Đăng xuất
            </button>
        </div>
      </div>
    </aside>

    <!-- Main Content -->
    <div class="flex-1 md:ml-72 flex flex-col min-h-screen transition-all bg-[#F4F6F9]">
      <!-- Top Header -->
      <header class="h-16 bg-white/80 backdrop-blur-md border-b border-[#DEE2E6]/60 sticky top-0 z-10 px-6 flex items-center justify-between shadow-sm">
        <div class="flex items-center gap-2 text-[#6C757D] text-sm breadcrumb">
           <span class="hover:text-[#003865] cursor-pointer">Phòng Đào tạo</span>
           <span class="mx-1">/</span>
           <span class="text-[#1A1A1A] font-medium">{{ $route.meta.title || 'Tổng quan' }}</span>
        </div>

        <div class="flex items-center gap-4">
           <div class="relative group">
              <input 
                type="text" 
                placeholder="Tìm kiếm nhanh..." 
                class="w-64 pl-10 pr-4 py-2 bg-[#F4F6F9] border-none rounded-full text-sm focus:bg-white focus:ring-2 focus:ring-[#003865]/20 transition-all shadow-inner"
              />
              <Search class="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-[#6C757D] group-focus-within:text-[#003865] transition-colors" />
           </div>
           
           <div class="h-8 w-[1px] bg-[#DEE2E6] mx-2"></div>

           <button class="relative p-2.5 bg-white border border-[#DEE2E6] rounded-full hover:bg-gray-50 hover:shadow-md transition-all text-[#6C757D]">
             <Bell class="h-5 w-5" />
             <span class="absolute top-0 right-0 h-3 w-3 bg-[#D31826] rounded-full border-2 border-white animate-pulse"></span>
           </button>
        </div>
      </header>
      
      <!-- Content Area -->
      <main class="flex-1 p-6 space-y-6 overflow-x-hidden">
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
  ListOrdered, 
  FileStack,
  UserCog, 
  Search, 
  Bell, 
  LogOut,
  Building2,
  ChevronRight,
  MessageSquare
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'
import EditProfileModal from '@/components/shared/EditProfileModal.vue'

const authStore = useAuthStore()
const showEditProfileModal = ref(false)

const sidebarItems = [
  { icon: LayoutDashboard, label: 'Tổng quan', path: '/staff/dashboard' },
  { icon: ListOrdered, label: 'Quản lý hàng chờ', path: '/staff/queue' },
  { icon: FileStack, label: 'Quản lý hồ sơ', path: '/staff/hoso' },
  { icon: MessageSquare, label: 'Tiếp nhận phản ánh', path: '/staff/feedbacks' },
  { icon: UserCog, label: 'Tài khoản cá nhân', path: '/staff/profile' },
]

const registrarInfo = computed(() => ({
  name: authStore.user?.hoTen || 'Cán bộ đào tạo',
  id: authStore.user?.maNhanVien || 'N/A',
  role: authStore.user?.roleDisplayName || 'Cán bộ Phòng Đào tạo',
  avatar: authStore.user?.hoTen?.charAt(0).toUpperCase() || 'CB',
  counter: authStore.user?.tenQuay || 'Chưa phân quầy'
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
