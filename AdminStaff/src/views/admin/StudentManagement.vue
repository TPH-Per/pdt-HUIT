<template>
  <div class="space-y-6 animate-in slide-in-from-bottom-2 duration-500">
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-2xl font-bold tracking-tight text-slate-800">Quản lý Sinh viên</h2>
        <p class="text-sm text-slate-500 mt-1">Quản lý danh sách sinh viên, đặt lại mật khẩu</p>
      </div>
      <button 
        @click="openAddModal"
        class="inline-flex items-center justify-center rounded-lg bg-[#003865] px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-[#002d52] transition-colors focus:outline-none focus:ring-2 focus:ring-[#003865] focus:ring-offset-2"
      >
        <Plus class="mr-2 h-4 w-4" />
        Thêm sinh viên
      </button>
    </div>

    <!-- Toolbar: Search -->
    <div class="flex flex-col sm:flex-row gap-4 items-center bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
      <div class="relative w-full sm:max-w-xs">
        <Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
        <input 
          v-model="searchQuery"
          type="text" 
          placeholder="Tìm sinh viên theo MSSV hoặc Tên..."
          class="w-full pl-9 pr-4 py-2 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-[#003865]/20 focus:border-[#003865] transition-all"
        />
      </div>
      <div class="ml-auto text-sm text-slate-500 font-medium">
        Tổng số: <span class="text-slate-900">{{ filteredStudents.length }}</span> sinh viên
      </div>
    </div>

    <!-- Table content -->
    <div class="bg-white border text-sm border-slate-200 rounded-xl shadow-sm overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="bg-slate-50 border-b border-slate-200">
              <th class="h-10 px-4 align-middle font-medium text-slate-500">MSSV</th>
              <th class="h-10 px-4 align-middle font-medium text-slate-500">Họ và tên</th>
              <th class="h-10 px-4 align-middle font-medium text-slate-500">Chuyên ngành</th>
              <th class="h-10 px-4 align-middle font-medium text-slate-500 w-[120px]">Số ĐT</th>
              <th class="h-10 px-4 align-middle font-medium text-slate-500 w-[120px]">Email</th>
              <th class="h-10 px-4 align-middle font-medium text-slate-500 text-right w-[150px]">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="isLoading" class="border-b border-slate-200">
              <td colspan="6" class="p-8 text-center text-slate-500">Đang tải dữ liệu...</td>
            </tr>
            <tr v-else-if="filteredStudents.length === 0" class="border-b border-slate-200">
              <td colspan="6" class="p-8 text-center text-slate-500">Không tìm thấy sinh viên nào.</td>
            </tr>
            <tr 
              v-for="student in filteredStudents" 
              :key="student.studentId"
              class="border-b border-slate-200 hover:bg-slate-50/50 transition-colors"
            >
              <td class="p-4 font-mono font-medium text-slate-900">{{ student.studentId }}</td>
              <td class="p-4 font-medium text-slate-900">{{ student.fullName }}</td>
              <td class="p-4 text-slate-600">{{ student.major || '-' }}</td>
              <td class="p-4 text-slate-600">{{ student.phone || '-' }}</td>
              <td class="p-4 text-slate-600 truncate max-w-[150px]">{{ student.email || '-' }}</td>
              <td class="p-4 text-right">
                <div class="flex items-center justify-end gap-2">
                  <button 
                    @click="openResetPasswordModal(student)"
                    class="p-1.5 text-orange-600 hover:bg-orange-50 rounded-md transition-colors tooltip-trigger"
                    title="Đặt lại mật khẩu"
                  >
                    <KeyRound class="h-4 w-4" />
                  </button>
                  <button 
                    @click="openEditModal(student)"
                    class="p-1.5 text-blue-600 hover:bg-blue-50 rounded-md transition-colors tooltip-trigger"
                    title="Sửa thông tin"
                  >
                    <Edit2 class="h-4 w-4" />
                  </button>
                  <button 
                    @click="confirmDelete(student)"
                    class="p-1.5 text-red-600 hover:bg-red-50 rounded-md transition-colors tooltip-trigger"
                    title="Xóa"
                  >
                    <Trash2 class="h-4 w-4" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Add/Edit Modal -->
    <div v-if="showModal" class="fixed inset-0 z-50 bg-black/50 flex flex-col items-center justify-center p-4 sm:p-0">
      <div 
        class="bg-white rounded-xl shadow-xl w-full max-w-lg overflow-hidden animate-in zoom-in-95 duration-200"
        @click.stop
      >
        <div class="px-6 py-4 border-b border-slate-200 flex items-center justify-between bg-slate-50">
          <h3 class="font-bold text-lg text-slate-800">{{ isEditing ? 'Sửa Sinh Viên' : 'Thêm Sinh Viên' }}</h3>
          <button @click="showModal = false" class="text-slate-400 hover:text-slate-600 p-1 rounded-sm">
            <X class="h-5 w-5" />
          </button>
        </div>
        <div class="p-6 space-y-4 max-h-[70vh] overflow-y-auto">
          <div class="space-y-2">
            <label class="text-sm font-medium text-slate-700">MSSV <span class="text-red-500">*</span></label>
            <input 
              v-model="editForm.studentId" 
              type="text" 
              required
              :disabled="isEditing"
              class="w-full px-3 py-2 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-[#003865]/20 focus:border-[#003865] disabled:bg-slate-100 disabled:text-slate-500"
              placeholder="VD: 2001215001"
            />
          </div>
          <div class="space-y-2">
            <label class="text-sm font-medium text-slate-700">Họ và tên <span class="text-red-500">*</span></label>
            <input 
              v-model="editForm.fullName" 
              type="text" 
              required
              class="w-full px-3 py-2 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-[#003865]/20 focus:border-[#003865]"
              placeholder="VD: Nguyễn Văn A"
            />
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-sm font-medium text-slate-700">Ngày sinh</label>
              <input 
                v-model="editForm.dateOfBirth" 
                type="date" 
                class="w-full px-3 py-2 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-[#003865]/20 focus:border-[#003865]"
              />
            </div>
            <div class="space-y-2">
              <label class="text-sm font-medium text-slate-700">Giới tính</label>
              <select 
                v-model="editForm.gender" 
                class="w-full px-3 py-2 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-[#003865]/20 focus:border-[#003865] bg-white appearance-none"
              >
                <option value="">Chọn</option>
                <option value="Nam">Nam</option>
                <option value="Nữ">Nữ</option>
              </select>
            </div>
          </div>
          <div class="space-y-2">
            <label class="text-sm font-medium text-slate-700">Chuyên ngành</label>
            <input 
              v-model="editForm.major" 
              type="text" 
              class="w-full px-3 py-2 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-[#003865]/20 focus:border-[#003865]"
              placeholder="Kỹ thuật phần mềm..."
            />
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-sm font-medium text-slate-700">Số điện thoại</label>
              <input 
                v-model="editForm.phone" 
                type="tel" 
                class="w-full px-3 py-2 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-[#003865]/20 focus:border-[#003865]"
              />
            </div>
            <div class="space-y-2">
              <label class="text-sm font-medium text-slate-700">Email</label>
              <input 
                v-model="editForm.email" 
                type="email" 
                class="w-full px-3 py-2 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-[#003865]/20 focus:border-[#003865]"
              />
            </div>
          </div>
        </div>
        <div class="px-6 py-4 border-t border-slate-200 bg-slate-50 flex justify-end gap-3 flex-shrink-0">
          <button 
            @click="showModal = false"
            class="px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 transition-colors"
          >
            Hủy
          </button>
          <button 
            @click="saveStudent"
            :disabled="isSaving"
            class="px-4 py-2 text-sm font-medium text-white bg-[#003865] rounded-lg hover:bg-[#002d52] transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
          >
            <Loader2 v-if="isSaving" class="h-4 w-4 animate-spin" />
            Lưu
          </button>
        </div>
      </div>
    </div>

    <!-- Reset Password Modal -->
    <div v-if="showResetModal" class="fixed inset-0 z-50 bg-black/50 flex flex-col items-center justify-center p-4 sm:p-0">
      <div 
        class="bg-white rounded-xl shadow-xl w-full max-w-sm overflow-hidden animate-in zoom-in-95 duration-200"
        @click.stop
      >
        <div class="px-6 py-4 border-b border-slate-200">
          <h3 class="font-bold text-lg text-slate-800">Đặt lại mật khẩu</h3>
          <p class="text-sm text-slate-500 mt-1">
            Đặt lại mật khẩu cho <span class="font-semibold text-slate-900">{{ currentStudent?.studentId }}</span>
          </p>
        </div>
        <div class="p-6 space-y-4">
          <div class="space-y-2">
            <label class="text-sm font-medium text-slate-700">Mật khẩu mới <span class="text-red-500">*</span></label>
            <input 
              v-model="newPassword" 
              type="text" 
              class="w-full px-3 py-2 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-[#003865]/20 focus:border-[#003865]"
              placeholder="Nhập ít nhất 6 ký tự..."
            />
          </div>
        </div>
        <div class="px-6 py-4 border-t border-slate-200 bg-slate-50 flex justify-end gap-3">
          <button 
            @click="showResetModal = false"
            class="px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 transition-colors"
          >
            Hủy
          </button>
          <button 
            @click="resetPassword"
            :disabled="isSaving || !newPassword || newPassword.length < 6"
            class="px-4 py-2 text-sm font-medium text-white bg-orange-600 rounded-lg hover:bg-orange-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
          >
            <Loader2 v-if="isSaving" class="h-4 w-4 animate-spin" />
            Đổi mật khẩu
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Plus, Search, Edit2, Trash2, KeyRound, Loader2, X } from 'lucide-vue-next'
import { studentAdminApi } from '@/services/api'
import Swal from 'sweetalert2'

const students = ref<any[]>([])
const isLoading = ref(true)
const isSaving = ref(false)
const searchQuery = ref('')

const filteredStudents = computed(() => {
  if (!searchQuery.value) return students.value
  const q = searchQuery.value.toLowerCase()
  return students.value.filter(s => 
    (s.studentId && s.studentId.toLowerCase().includes(q)) || 
    (s.fullName && s.fullName.toLowerCase().includes(q))
  )
})

const fetchStudents = async () => {
  isLoading.value = true
  try {
    const data = await studentAdminApi.getAll()
    students.value = data
  } catch (error) {
    console.error('Failed to load students:', error)
    Swal.fire('Lỗi', 'Không thể tải danh sách sinh viên', 'error')
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  fetchStudents()
})

// === Modal logic ===
const showModal = ref(false)
const isEditing = ref(false)
const editForm = ref({
  studentId: '', fullName: '', dateOfBirth: '', gender: '', major: '', phone: '', email: ''
})

const openAddModal = () => {
  isEditing.value = false
  editForm.value = { studentId: '', fullName: '', dateOfBirth: '', gender: '', major: '', phone: '', email: '' }
  showModal.value = true
}

const openEditModal = (student: any) => {
  isEditing.value = true
  editForm.value = { ...student }
  showModal.value = true
}

const saveStudent = async () => {
  if (!editForm.value.studentId || !editForm.value.fullName) {
    Swal.fire('Chú ý', 'Vui lòng nhập MSSV và Họ tên', 'warning')
    return
  }

  isSaving.value = true
  try {
    if (isEditing.value) {
      await studentAdminApi.update(editForm.value.studentId, editForm.value)
      Swal.fire({
        toast: true,
        position: 'top-end',
        showConfirmButton: false,
        timer: 3000,
        icon: 'success',
        title: 'Cập nhật thành công'
      })
    } else {
      await studentAdminApi.create(editForm.value)
      Swal.fire({
        toast: true,
        position: 'top-end',
        showConfirmButton: false,
        timer: 3000,
        icon: 'success',
        title: 'Thêm mới thành công'
      })
    }
    showModal.value = false
    fetchStudents()
  } catch (error: any) {
    console.error(error)
    Swal.fire('Lỗi', error.response?.data?.error || 'Có lỗi xảy ra', 'error')
  } finally {
    isSaving.value = false
  }
}

// === Reset Password Logic ===
const showResetModal = ref(false)
const currentStudent = ref<any>(null)
const newPassword = ref('')

const openResetPasswordModal = (student: any) => {
  currentStudent.value = student
  newPassword.value = ''
  showResetModal.value = true
}

const resetPassword = async () => {
  if (newPassword.value.length < 6) return
  isSaving.value = true
  try {
    await studentAdminApi.resetPassword(currentStudent.value.studentId, newPassword.value)
    showResetModal.value = false
    Swal.fire({
      toast: true,
      position: 'top-end',
      showConfirmButton: false,
      timer: 3000,
      icon: 'success',
      title: 'Đổi mật khẩu thành công'
    })
  } catch (error: any) {
    console.error(error)
    Swal.fire('Lỗi', error.response?.data?.error || 'Không thể đặt lại mật khẩu', 'error')
  } finally {
    isSaving.value = false
  }
}

// === Delete Logic ===
const confirmDelete = (student: any) => {
  Swal.fire({
    title: 'Xác nhận xóa?',
    html: `Bạn có chắc chắn muốn xóa sinh viên <b>${student.studentId} - ${student.fullName}</b>?`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonColor: '#d33',
    cancelButtonColor: '#3085d6',
    confirmButtonText: 'Xóa',
    cancelButtonText: 'Hủy'
  }).then(async (result) => {
    if (result.isConfirmed) {
      try {
        await studentAdminApi.delete(student.studentId)
        Swal.fire('Đã xóa!', 'Sinh viên đã được xóa khỏi hệ thống.', 'success')
        fetchStudents()
      } catch (error: any) {
        Swal.fire('Không thể xóa', error.response?.data?.error || 'Có lỗi xảy ra', 'error')
      }
    }
  })
}
</script>
