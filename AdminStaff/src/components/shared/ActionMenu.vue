<template>
  <Menu as="div" class="relative inline-block text-left">
    <MenuButton
      class="inline-flex items-center justify-center w-8 h-8 rounded-full text-gray-400 hover:text-gray-600 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all duration-200"
    >
      <span class="sr-only">Mở menu</span>
      <MoreVertical class="w-4 h-4" />
    </MenuButton>

    <transition
      enter-active-class="transition duration-100 ease-out"
      enter-from-class="transform scale-95 opacity-0"
      enter-to-class="transform scale-100 opacity-100"
      leave-active-class="transition duration-75 ease-in"
      leave-from-class="transform scale-100 opacity-100"
      leave-to-class="transform scale-95 opacity-0"
    >
      <MenuItems
        class="absolute right-0 z-50 mt-2 w-48 origin-top-right divide-y divide-gray-100 rounded-xl bg-white shadow-lg ring-1 ring-black/5 focus:outline-none overflow-hidden"
      >
        <!-- Edit Action -->
        <div class="p-1">
          <MenuItem v-slot="{ active }">
            <button
              @click="$emit('edit')"
              :class="[
                active ? 'bg-indigo-50 text-indigo-700' : 'text-gray-700',
                'group flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm transition-colors'
              ]"
            >
              <Pencil class="w-4 h-4" :class="active ? 'text-indigo-600' : 'text-gray-400'" />
              Chỉnh sửa
            </button>
          </MenuItem>
        </div>

        <!-- Password Reset (Optional) -->
        <div v-if="showResetPassword" class="p-1">
          <MenuItem v-slot="{ active }">
            <button
              @click="$emit('reset-password')"
              :class="[
                active ? 'bg-amber-50 text-amber-700' : 'text-gray-700',
                'group flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm transition-colors'
              ]"
            >
              <KeyRound class="w-4 h-4" :class="active ? 'text-amber-600' : 'text-gray-400'" />
              Đặt lại mật khẩu
            </button>
          </MenuItem>
        </div>

        <!-- Lock/Unlock Action -->
        <div class="p-1">
          <MenuItem v-slot="{ active }">
            <button
              @click="$emit('toggle-status')"
              :class="[
                active ? (isActive ? 'bg-orange-50 text-orange-700' : 'bg-green-50 text-green-700') : 'text-gray-700',
                'group flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm transition-colors'
              ]"
            >
              <Lock v-if="isActive" class="w-4 h-4" :class="active ? 'text-orange-600' : 'text-gray-400'" />
              <Unlock v-else class="w-4 h-4" :class="active ? 'text-green-600' : 'text-gray-400'" />
              {{ isActive ? 'Khóa tài khoản' : 'Mở khóa' }}
            </button>
          </MenuItem>
        </div>

        <!-- Delete Action (Optional, Danger) -->
        <div v-if="showDelete" class="p-1">
          <MenuItem v-slot="{ active }">
            <button
              @click="$emit('delete')"
              :class="[
                active ? 'bg-red-50 text-red-700' : 'text-gray-700',
                'group flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm transition-colors'
              ]"
            >
              <Trash2 class="w-4 h-4" :class="active ? 'text-red-600' : 'text-gray-400'" />
              Xóa
            </button>
          </MenuItem>
        </div>
      </MenuItems>
    </transition>
  </Menu>
</template>

<script setup lang="ts">
import { Menu, MenuButton, MenuItems, MenuItem } from '@headlessui/vue'
import { MoreVertical, Pencil, KeyRound, Lock, Unlock, Trash2 } from 'lucide-vue-next'

interface Props {
  isActive?: boolean
  showResetPassword?: boolean
  showDelete?: boolean
}

withDefaults(defineProps<Props>(), {
  isActive: true,
  showResetPassword: false,
  showDelete: false,
})

defineEmits<{
  (e: 'edit'): void
  (e: 'reset-password'): void
  (e: 'toggle-status'): void
  (e: 'delete'): void
}>()
</script>
