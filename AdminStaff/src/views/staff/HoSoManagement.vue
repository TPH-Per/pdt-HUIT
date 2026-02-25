<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Quản lý hồ sơ</h1>
        <p class="text-gray-500 mt-1">Quản lý và theo dõi hồ sơ hành chính</p>
      </div>
      <button
        @click="showCreateModal = true"
        class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
      >
        <Plus class="w-4 h-4" />
        Tạo hồ sơ mới
      </button>
    </div>

    <!-- Error Alert -->
    <div v-if="error" class="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start gap-3 animate-fade-in">
      <AlertCircle class="w-5 h-5 text-red-500 mt-0.5" />
      <div>
        <p class="text-red-800 font-medium">Có lỗi xảy ra</p>
        <p class="text-red-600 text-sm">{{ error }}</p>
      </div>
      <button @click="error = ''" class="ml-auto text-red-500 hover:text-red-700">
        <X class="w-4 h-4" />
      </button>
    </div>

    <!-- Statistics Cards -->
    <div class="grid grid-cols-1 md:grid-cols-5 gap-4">
      <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-500">Tổng hồ sơ</p>
            <p class="text-3xl font-bold text-gray-800">{{ dashboard?.tongSoHoSo ?? 0 }}</p>
          </div>
          <div class="w-12 h-12 bg-gray-100 rounded-full flex items-center justify-center">
            <FileStack class="w-6 h-6 text-gray-600" />
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-500">Chờ xử lý</p>
            <p class="text-3xl font-bold text-yellow-600">{{ dashboard?.choXuLy ?? 0 }}</p>
          </div>
          <div class="w-12 h-12 bg-yellow-100 rounded-full flex items-center justify-center">
            <Clock class="w-6 h-6 text-yellow-600" />
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-500">Đang xử lý</p>
            <p class="text-3xl font-bold text-blue-600">{{ dashboard?.dangXuLy ?? 0 }}</p>
          </div>
          <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
            <Loader class="w-6 h-6 text-blue-600" />
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-500">Hoàn thành</p>
            <p class="text-3xl font-bold text-green-600">{{ dashboard?.hoanThanh ?? 0 }}</p>
          </div>
          <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
            <CheckCircle class="w-6 h-6 text-green-600" />
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-500">Trễ hạn</p>
            <p class="text-3xl font-bold text-red-600">{{ dashboard?.treHan ?? 0 }}</p>
          </div>
          <div class="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
            <AlertTriangle class="w-6 h-6 text-red-600" />
          </div>
        </div>
      </div>
    </div>

    <!-- Filter Tabs -->
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <!-- Tabs Navigation -->
      <div class="border-b border-gray-200">
        <nav class="flex -mb-px">
          <button
            v-for="(tab, index) in statusTabs"
            :key="index"
            @click="selectedStatus = tab.value"
            :class="[
              'px-6 py-4 text-sm font-medium border-b-2 transition',
              selectedStatus === tab.value
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            ]"
          >
            {{ tab.label }}
            <span
              v-if="tab.count !== undefined"
              :class="[
                'ml-2 px-2 py-0.5 rounded-full text-xs',
                selectedStatus === tab.value
                  ? 'bg-blue-100 text-blue-600'
                  : 'bg-gray-100 text-gray-500'
              ]"
            >
              {{ tab.count }}
            </span>
          </button>
        </nav>
      </div>

      <!-- Search & Refresh -->
      <div class="p-4 border-b bg-gray-50 flex gap-4 items-center">
        <div class="flex-1 relative">
          <Search class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Tìm theo mã hồ sơ, CCCD, họ tên..."
            class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
        </div>
        <button
          @click="refreshData"
          :disabled="loading"
          class="flex items-center gap-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-100 transition disabled:opacity-50"
        >
          <RefreshCw :class="{ 'animate-spin': loading }" class="w-4 h-4" />
          Làm mới
        </button>
      </div>

      <!-- Table -->
      <div class="overflow-x-auto">
        <table class="w-full">
          <thead class="bg-gray-50 border-b">
            <tr>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Mã hồ sơ</th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Sinh viên</th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Thủ tục</th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Trạng thái</th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Ngày nộp</th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Hạn xử lý</th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Thao tác</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-if="loading" class="text-center">
              <td colspan="7" class="py-12">
                <Loader class="w-8 h-8 animate-spin mx-auto text-blue-600" />
                <p class="text-gray-500 mt-2">Đang tải...</p>
              </td>
            </tr>
            <tr v-else-if="filteredList.length === 0" class="text-center">
              <td colspan="7" class="py-12">
                <FileX class="w-12 h-12 mx-auto text-gray-300" />
                <p class="text-gray-500 mt-2">Không có hồ sơ nào</p>
              </td>
            </tr>
            <tr
              v-else
              v-for="item in paginatedList"
              :key="item.id"
              class="hover:bg-blue-50/30 transition cursor-pointer group"
              @dblclick="viewDetail(item)"
            >
              <td class="px-4 py-4">
                <div class="font-medium text-blue-600 font-mono">{{ item.maHoSo }}</div>
                <div class="text-xs text-gray-400 mt-0.5">{{ item.nguonGoc }}</div>
              </td>
              <td class="px-4 py-4">
                <div class="font-medium text-gray-900">{{ item.hoTenSinhVien }}</div>
                <div class="text-sm text-gray-500 font-mono">{{ item.mssv }}</div>
              </td>
              <td class="px-4 py-4">
                <div class="text-gray-700 max-w-xs truncate" :title="item.tenThuTuc">{{ item.tenThuTuc }}</div>
                <div class="text-xs text-gray-400 mt-0.5">{{ item.maThuTuc }}</div>
              </td>
              <td class="px-4 py-4">
                <span :class="getStatusClass(item.trangThai)">
                  {{ item.trangThaiText }}
                </span>
              </td>
              <td class="px-4 py-4 text-gray-600 text-sm">
                {{ formatDate(item.ngayNop) }}
              </td>
              <td class="px-4 py-4">
                <span
                  :class="isOverdue(item.hanXuLy) ? 'text-red-600 font-medium' : 'text-gray-600'"
                  class="text-sm"
                >
                  {{ formatDate(item.hanXuLy) || '--' }}
                </span>
                <span v-if="isOverdue(item.hanXuLy)" class="block text-xs text-red-500 font-bold flex items-center gap-1 mt-0.5">
                  <AlertTriangle class="w-3 h-3" /> Trễ hạn
                </span>
              </td>
              <td class="px-4 py-4">
                <div class="flex items-center gap-2 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity">
                  <button
                    @click="viewDetail(item)"
                    class="p-2 text-blue-600 bg-blue-50 hover:bg-blue-100 hover:text-blue-700 rounded-lg transition-all shadow-sm"
                    title="Xem chi tiết"
                  >
                    <Eye class="w-4 h-4" />
                  </button>
                  <button
                    v-if="item.trangThai !== 4 && item.trangThai !== 0"
                    @click="openStatusModal(item)"
                    class="p-2 text-green-600 bg-green-50 hover:bg-green-100 hover:text-green-700 rounded-lg transition-all shadow-sm"
                    title="Cập nhật trạng thái"
                  >
                    <RefreshCcw class="w-4 h-4" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <!-- Pagination Controls -->
      <div v-if="totalPages > 0" class="flex items-center justify-between px-4 py-3 border-t bg-gray-50/50">
        <div class="flex items-center text-sm text-gray-500">
          Hiển thị {{ (currentPage - 1) * pageSize + 1 }}-{{ Math.min(currentPage * pageSize, filteredList.length) }} 
          trong tổng số {{ filteredList.length }} hồ sơ
        </div>
        
        <div class="flex items-center gap-2">
          <button
            @click="currentPage = 1"
            :disabled="currentPage === 1"
            class="p-2 rounded-lg hover:bg-gray-100 disabled:opacity-30 disabled:hover:bg-transparent transition-colors"
            title="Trang đầu"
          >
            <ChevronsLeft class="w-4 h-4" />
          </button>
          
          <button
            @click="currentPage--"
            :disabled="currentPage === 1"
            class="p-2 rounded-lg hover:bg-gray-100 disabled:opacity-30 disabled:hover:bg-transparent transition-colors"
            title="Trang trước"
          >
            <ChevronLeft class="w-4 h-4" />
          </button>
          
          <div class="flex items-center gap-1 font-medium text-sm text-gray-700 mx-2">
            Trang {{ currentPage }} / {{ totalPages }}
          </div>
          
          <button
            @click="currentPage++"
            :disabled="currentPage === totalPages"
            class="p-2 rounded-lg hover:bg-gray-100 disabled:opacity-30 disabled:hover:bg-transparent transition-colors"
            title="Trang sau"
          >
            <ChevronRight class="w-4 h-4" />
          </button>
          
          <button
            @click="currentPage = totalPages"
            :disabled="currentPage === totalPages"
            class="p-2 rounded-lg hover:bg-gray-100 disabled:opacity-30 disabled:hover:bg-transparent transition-colors"
            title="Trang cuối"
          >
            <ChevronsRight class="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>

    <!-- Create Modal -->
    <div
      v-if="showCreateModal"
      class="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50 animate-fade-in"
      @click.self="showCreateModal = false"
    >
      <div class="bg-white rounded-2xl shadow-xl w-full max-w-2xl mx-4 max-h-[90vh] overflow-y-auto transform transition-all scale-100">
        <div class="bg-gradient-to-r from-blue-600 to-indigo-600 px-6 py-4 sticky top-0 z-10">
          <h3 class="text-white font-bold text-lg flex items-center gap-2">
            <Plus class="w-5 h-5" /> Tạo hồ sơ mới
          </h3>
        </div>
        <form @submit.prevent="handleSubmitCreate" class="p-6 space-y-4">
          <!-- Warning Alert -->
          <div v-if="warningMessage" class="bg-amber-50 border-l-4 border-amber-500 p-4 rounded-r flex items-start gap-3 animate-pulse">
            <AlertTriangle class="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
            <div class="flex-1">
               <p class="text-sm text-amber-800 font-bold">{{ warningMessage }}</p>
               <p class="text-xs text-amber-600 mt-1">Nhấn "Xác nhận & Ghi đè" để tiếp tục tạo hồ sơ và cập nhật thông tin sinh viên.</p>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-bold text-gray-700 mb-1">
                CCCD <span class="text-red-500">*</span>
              </label>
              <input
                v-model="createForm.mssv"
                type="text"
                required
                maxlength="12"
                placeholder="Nhập số CCCD"
                class="w-full border border-gray-300 rounded-xl px-4 py-2.5 focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none"
              />
            </div>
            <div>
              <label class="block text-sm font-bold text-gray-700 mb-1">
                Họ tên <span class="text-red-500">*</span>
              </label>
              <input
                v-model="createForm.hoTen"
                type="text"
                required
                placeholder="Nhập họ tên"
                class="w-full border border-gray-300 rounded-xl px-4 py-2.5 focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none"
              />
            </div>
            <div>
              <label class="block text-sm font-bold text-gray-700 mb-1">Số điện thoại</label>
              <input
                v-model="createForm.soDienThoai"
                type="tel"
                placeholder="Nhập số điện thoại"
                class="w-full border border-gray-300 rounded-xl px-4 py-2.5 focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none"
              />
            </div>
            <div>
              <label class="block text-sm font-bold text-gray-700 mb-1">Email</label>
              <input
                v-model="createForm.email"
                type="email"
                placeholder="Nhập email"
                class="w-full border border-gray-300 rounded-xl px-4 py-2.5 focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none"
              />
            </div>
          </div>
          
          <div>
            <label class="block text-sm font-bold text-gray-700 mb-1">
              Loại thủ tục <span class="text-red-500">*</span>
            </label>
            <select
              v-model="createForm.loaiThuTucId"
              required
              class="w-full border border-gray-300 rounded-xl px-4 py-2.5 focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none bg-white"
            >
              <option value="">-- Chọn thủ tục --</option>
              <option v-for="proc in procedures" :key="proc.id" :value="proc.id">
                {{ proc.serviceName }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-bold text-gray-700 mb-1">Độ ưu tiên</label>
            <select
              v-model="createForm.doUuTien"
              class="w-full border border-gray-300 rounded-xl px-4 py-2.5 focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none bg-white"
            >
              <option :value="0">Bình thường</option>
              <option :value="1">Ưu tiên</option>
              <option :value="2">Khẩn cấp</option>
            </select>
          </div>

          <div class="flex gap-3 justify-end pt-4 border-t border-gray-100 bg-gray-50 -mx-6 -mb-6 p-6 mt-6">
            <button
              type="button"
              @click="showCreateModal = false"
              class="px-5 py-2.5 border border-gray-300 rounded-xl text-gray-700 font-medium hover:bg-white hover:shadow-sm transition-all"
            >
              Hủy
            </button>
            <button
              type="submit"
              :disabled="actionLoading"
              class="px-5 py-2.5 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-xl shadow-lg shadow-blue-500/30 hover:shadow-blue-500/40 hover:-translate-y-0.5 transition-all duration-300 font-bold disabled:opacity-50"
              :class="{ 'from-amber-500 to-orange-500 shadow-amber-500/30 hover:shadow-amber-500/40': warningMessage }"
            >
              {{ actionLoading ? 'Đang xử lý...' : (warningMessage ? 'Xác nhận & Ghi đè' : 'Tạo hồ sơ') }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Status Update Modal -->
    <div
      v-if="showStatusModal"
      class="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50 animate-fade-in"
      @click.self="showStatusModal = false"
    >
      <div class="bg-white rounded-2xl shadow-xl w-full max-w-md mx-4 overflow-hidden transform transition-all scale-100">
        <div class="bg-gradient-to-r from-green-600 to-emerald-600 px-6 py-4">
          <h3 class="text-white font-bold text-lg">Cập nhật trạng thái</h3>
          <p class="text-green-100 text-sm mt-1 font-mono opacity-90">{{ selectedHoSo?.maHoSo }}</p>
        </div>
        <div class="p-6 space-y-4">
          <div>
            <p class="text-gray-500 text-sm mb-1">Sinh viên</p>
            <p class="font-bold text-gray-900">{{ selectedHoSo?.hoTenSinhVien }}</p>
          </div>
          
          <div>
            <label class="block text-sm font-bold text-gray-700 mb-2">
              Trạng thái mới <span class="text-red-500">*</span>
            </label>
            <select
              v-model="statusForm.trangThaiMoi"
              class="w-full border border-gray-300 rounded-xl px-4 py-2.5 focus:ring-2 focus:ring-green-500/20 focus:border-green-500 transition-all outline-none bg-white"
            >
              <option :value="2">Đang tiếp nhận</option>
              <option :value="6">Yêu cầu bổ sung</option>
              <option :value="4">Hoàn thành</option>
              <option :value="0">Hủy hồ sơ</option>
            </select>
          </div>

          <!-- Appointment Slot Selection (if requesting supplementary) -->
          <div v-if="statusForm.trangThaiMoi === 6" class="animate-fade-in">
               <div>
                  <label class="block text-sm font-bold text-gray-700 mb-1">Ngày hẹn <span class="text-red-500">*</span></label>
                  <input type="date"
                    v-model="statusForm.ngayHen"
                    class="w-full border border-gray-300 rounded-xl px-4 py-2.5 mb-2"
                    :min="new Date().toISOString().split('T')[0]"
                    @change="fetchSlots"
                    required
                  >
               </div>

               <!-- Slot Selection UI -->
               <div v-if="statusForm.ngayHen" class="border border-gray-200 rounded-xl p-3 bg-gray-50 mt-2">
                  <div v-if="slotLoading" class="py-6 text-center text-gray-500">
                    <Loader class="w-6 h-6 animate-spin mx-auto mb-2 text-green-600" />
                    Đang tải khung giờ...
                  </div>

                  <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4 max-h-[200px] overflow-y-auto pr-1 custom-scrollbar">
                    <!-- Morning -->
                    <div>
                      <h4 class="font-bold text-gray-600 mb-2 flex items-center gap-1 text-xs uppercase tracking-wide">
                        <Sun class="w-3 h-3" /> Buổi sáng
                      </h4>
                      <div class="grid grid-cols-2 gap-2">
                        <button type="button" v-for="slot in slots.morning" :key="slot.time"
                          @click="!slot.booked && selectSlot(slot.time)"
                          :disabled="slot.booked"
                          :class="[
                            slot.booked ? 'bg-gray-200 text-gray-400 cursor-not-allowed border-transparent' :
                            statusForm.gioHen === slot.time ? 'bg-green-600 text-white shadow-md shadow-green-500/30' : 'bg-white border text-gray-700 hover:border-green-500 hover:text-green-600',
                            'px-2 py-1.5 rounded-lg text-xs font-medium transition-all text-center border'
                          ]"
                        >
                          {{ slot.time.substring(0, 5) }}
                        </button>
                      </div>
                    </div>

                    <!-- Afternoon -->
                    <div>
                      <h4 class="font-bold text-gray-600 mb-2 flex items-center gap-1 text-xs uppercase tracking-wide">
                        <Moon class="w-3 h-3" /> Buổi chiều
                      </h4>
                      <div class="grid grid-cols-2 gap-2">
                        <button type="button" v-for="slot in slots.afternoon" :key="slot.time"
                          @click="!slot.booked && selectSlot(slot.time)"
                          :disabled="slot.booked"
                          :class="[
                            slot.booked ? 'bg-gray-200 text-gray-400 cursor-not-allowed border-transparent' :
                            statusForm.gioHen === slot.time ? 'bg-green-600 text-white shadow-md shadow-green-500/30' : 'bg-white border text-gray-700 hover:border-green-500 hover:text-green-600',
                            'px-2 py-1.5 rounded-lg text-xs font-medium transition-all text-center border'
                          ]"
                        >
                          {{ slot.time.substring(0, 5) }}
                        </button>
                      </div>
                    </div>
                  </div>
               </div>
          </div>

          <div>
            <label class="block text-sm font-bold text-gray-700 mb-1">Ghi chú</label>
            <textarea
              v-model="statusForm.noiDung"
              rows="3"
              placeholder="Nhập ghi chú..."
              class="w-full border border-gray-300 rounded-xl px-4 py-2.5 focus:ring-2 focus:ring-green-500/20 focus:border-green-500 transition-all outline-none resize-none"
            ></textarea>
          </div>
        </div>
        <div class="bg-gray-50 p-6 flex gap-3 justify-end border-t border-gray-100">
          <button
            @click="showStatusModal = false"
            class="px-5 py-2.5 border border-gray-300 rounded-xl text-gray-700 font-medium hover:bg-white hover:shadow-sm transition-all"
          >
            Hủy
          </button>
          <button
            @click="updateStatus"
            :disabled="actionLoading"
            class="px-5 py-2.5 bg-gradient-to-r from-green-600 to-emerald-600 text-white rounded-xl shadow-lg shadow-green-500/30 hover:shadow-green-500/40 hover:-translate-y-0.5 transition-all duration-300 font-bold disabled:opacity-50"
          >
            {{ actionLoading ? 'Đang cập nhật...' : 'Xác nhận' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Detail Modal -->
    <HoSoDetailModal
      v-if="showDetailModal && selectedHoSo"
      :show="showDetailModal"
      :hoSoId="selectedHoSo.id"
      @close="showDetailModal = false"
      @update-status="openStatusModal"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'

import {
  Plus, AlertCircle, X, CheckCircle, FileStack, Clock, Loader, AlertTriangle,
  Search, RefreshCw, Eye, RefreshCcw, FileX, Sun, Moon,
  ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight
} from 'lucide-vue-next'
import { hoSoApi, publicLoaiThuTucApi, queueApi, type HoSoData, type HoSoDashboardData, type LoaiThuTucData } from '@/services/api'
import HoSoDetailModal from './HoSoDetailModal.vue'
import { useToast } from "vue-toastification";
// Note: HoSoManagement uses built-in toast for success/error alerts in template for better visibility, 
// as requested by previous patterns, but we will use useToast for consistency where alert() was used.
// Actually, I will replace the inline alerts with toast where appropriate or keep them if they are part of the UI design.
// User asked to replace "alert()" (browser alert).
// I will use toast for actions.

const toast = useToast();



// State
const loading = ref(false)
const actionLoading = ref(false)
const error = ref('')
const warningMessage = ref('')
const successMsg = ref('')

const slotLoading = ref(false)
const slots = ref<{
    morning: { time: string; booked: boolean }[];
    afternoon: { time: string; booked: boolean }[];
}>({ morning: [], afternoon: [] })

const dashboard = ref<HoSoDashboardData | null>(null)
const hoSoList = ref<HoSoData[]>([])
const procedures = ref<LoaiThuTucData[]>([])

const selectedStatus = ref<number | null>(null)
const searchQuery = ref('')
const currentPage = ref(1)
const pageSize = ref(10)

// Modals
const showCreateModal = ref(false)
const showStatusModal = ref(false)
const showDetailModal = ref(false)
const selectedHoSo = ref<HoSoData | null>(null)

// Forms
const createForm = ref({
  mssv: '',
  hoTen: '',
  soDienThoai: '',
  email: '',
  loaiThuTucId: '',
  doUuTien: 0
})

const statusForm = ref({
  trangThaiMoi: 3,
  noiDung: '',
  ngayHen: '',
  gioHen: ''
})

// Computed
const statusTabs = computed(() => [
  { label: 'Tất cả', value: null, count: dashboard.value?.tongSoHoSo },
  { label: 'Đang tiếp nhận', value: 2, count: dashboard.value?.choXuLy },
  { label: 'Bổ sung', value: 6, count: undefined },
  { label: 'Hoàn thành', value: 4, count: dashboard.value?.hoanThanh },
  { label: 'Đã hủy', value: 0, count: undefined }
])

const filteredList = computed(() => {
  let list = hoSoList.value

  // Filter by status
  if (selectedStatus.value !== null) {
    list = list.filter(item => item.trangThai === selectedStatus.value)
  }

  // Filter by search query
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase().trim()
    list = list.filter(item =>
      item.maHoSo.toLowerCase().includes(query) ||
      item.mssv.toLowerCase().includes(query) ||
      item.hoTenSinhVien.toLowerCase().includes(query)
    )
  }

  return list
})

const totalPages = computed(() => Math.ceil(filteredList.value.length / pageSize.value))

const paginatedList = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredList.value.slice(start, end)
})

watch([selectedStatus, searchQuery], () => {
  currentPage.value = 1
})

// Methods
const refreshData = async () => {
  loading.value = true
  error.value = ''

  try {
    const [dashboardRes, listRes] = await Promise.all([
      hoSoApi.getDashboard(),
      hoSoApi.getList()
    ])

    if (dashboardRes.data.success) {
      dashboard.value = dashboardRes.data.data
    }
    if (listRes.data.success) {
      hoSoList.value = listRes.data.data
    }
  } catch (err: any) {
    console.error(err);
    toast.error('Không thể tải dữ liệu');
  } finally {
    loading.value = false
  }
}

const loadProcedures = async () => {
  try {
    const res = await publicLoaiThuTucApi.getAll()
    if (res.data.success) {
      procedures.value = res.data.data
    }
  } catch (err) {
    console.error('Failed to load procedures:', err)
  }
}

const handleSubmitCreate = () => createHoSo(!!warningMessage.value)

const createHoSo = async (confirmDuplicate = false) => {
  if (!createForm.value.mssv || !createForm.value.hoTen || !createForm.value.loaiThuTucId) {
    toast.error('Vui lòng điền đầy đủ thông tin bắt buộc')
    return
  }

  actionLoading.value = true
  error.value = ''
  successMsg.value = ''
  if (!confirmDuplicate) warningMessage.value = ''

  try {
    const res = await hoSoApi.create({
      mssv: createForm.value.mssv,
      hoTen: createForm.value.hoTen,
      soDienThoai: createForm.value.soDienThoai,
      email: createForm.value.email,
      loaiThuTucId: parseInt(createForm.value.loaiThuTucId as string),
      doUuTien: createForm.value.doUuTien,
      confirmDuplicate: confirmDuplicate
    })

    if (res.data.success) {
      toast.success('Tạo hồ sơ thành công!')
      showCreateModal.value = false
      warningMessage.value = ''
      resetCreateForm()
      await refreshData()
    } else {
      error.value = res.data.message
      toast.error(error.value)
    }
  } catch (err: any) {
    console.error("Create HoSo Error:", err);
    // Check Status 409
    if (err.response?.status === 409) {
       warningMessage.value = err.response?.data?.message || 'Cảnh báo trùng lặp Citizen';
       toast.warning('Cảnh báo trùng lặp thông tin sinh viên');
    } else {
       error.value = err.response?.data?.message || 'Không thể tạo hồ sơ'
       toast.error(error.value)
    }
  } finally {
    actionLoading.value = false
  }
}

const resetCreateForm = () => {
  createForm.value = {
    mssv: '',
    hoTen: '',
    soDienThoai: '',
    email: '',
    loaiThuTucId: '',
    doUuTien: 0
  }
}

const viewDetail = (item: HoSoData) => {
  selectedHoSo.value = item
  showDetailModal.value = true
}

const openStatusModal = (item: HoSoData) => {
  selectedHoSo.value = item
  statusForm.value = {
    trangThaiMoi: item.trangThai,
    noiDung: '',
    ngayHen: '',
    gioHen: ''
  }
  showStatusModal.value = true
}

const updateStatus = async () => {
  if (!selectedHoSo.value) return

  actionLoading.value = true
  error.value = ''

  try {
    const payload: any = {
      trangThaiMoi: statusForm.value.trangThaiMoi,
      noiDung: statusForm.value.noiDung || undefined
    }
    if (statusForm.value.trangThaiMoi === 6) {
        if (!statusForm.value.ngayHen || !statusForm.value.gioHen) {
            toast.error('Vui lòng nhập ngày và giờ hẹn')
            actionLoading.value = false
            return
        }
        payload.ngayHen = statusForm.value.ngayHen
        payload.gioHen = statusForm.value.gioHen
    }

    const res = await hoSoApi.updateStatus(selectedHoSo.value.id, payload)

    if (res.data.success) {
      toast.success('Cập nhật trạng thái thành công!')
      showStatusModal.value = false
      await refreshData()
    } else {
      error.value = res.data.message
      toast.error(error.value)
    }
  } catch (err: any) {
    error.value = err.response?.data?.message || 'Không thể cập nhật trạng thái'
    toast.error(error.value)
  } finally {
    actionLoading.value = false
  }
}

const fetchSlots = async () => {
    if (!statusForm.value.ngayHen) return;
    slotLoading.value = true;
    try {
        const res = await queueApi.getSlots(statusForm.value.ngayHen);
        if (res.data.success) {
            slots.value = res.data.data;
        }
    } catch (e) {
        console.error(e);
    } finally {
        slotLoading.value = false;
    }
}

const selectSlot = (time: string) => {
    statusForm.value.gioHen = time;
}

const getStatusClass = (status: number): string => {
  const classes: Record<number, string> = {
    0: 'px-2.5 py-1 rounded-full text-xs font-bold bg-gray-100 text-gray-600 border border-gray-200',
    1: 'px-2.5 py-1 rounded-full text-xs font-bold bg-blue-50 text-blue-700 border border-blue-100', // Xử lý
    2: 'px-2.5 py-1 rounded-full text-xs font-bold bg-yellow-50 text-yellow-700 border border-yellow-100', // Tiếp nhận
    6: 'px-2.5 py-1 rounded-full text-xs font-bold bg-orange-50 text-orange-700 border border-orange-100', // Bổ sung
    4: 'px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-100', // Hoàn thành
    5: 'px-2.5 py-1 rounded-full text-xs font-bold bg-red-50 text-red-700 border border-red-100' // Từ chối
  }
  return classes[status] || classes[1]
}

const formatDate = (dateStr: string | null): string => {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  return date.toLocaleDateString('vi-VN')
}

const isOverdue = (deadline: string | null): boolean => {
  if (!deadline) return false
  const deadlineDate = new Date(deadline)
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  return deadlineDate < today
}

onMounted(() => {
  refreshData()
  loadProcedures()
})
</script>
