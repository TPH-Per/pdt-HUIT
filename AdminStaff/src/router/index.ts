import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'

// Lazy load layouts
const StaffLayout = () => import('@/layouts/StaffLayout.vue')
const AdminLayout = () => import('@/layouts/AdminLayout.vue')

// Lazy load views
const LoginView = () => import('@/views/Login.vue')

// Staff views
const StaffDashboard = () => import('@/views/staff/Dashboard.vue')
const QueueManagement = () => import('@/views/staff/QueueManagement.vue')
const FileProcessing = () => import('@/views/staff/FileProcessing.vue')

// Admin views
const AdminDashboard = () => import('@/views/admin/Dashboard.vue')
const AccountManagement = () => import('@/views/admin/AccountManagement.vue')
const StudentManagement = () => import('@/views/admin/StudentManagement.vue')
const CounterManagement = () => import('@/views/admin/CounterManagement.vue')
const Reports = () => import('@/views/admin/Reports.vue')

const routes: RouteRecordRaw[] = [
    // Login route
    {
        path: '/login',
        name: 'Login',
        component: LoginView,
        meta: { title: 'Đăng nhập' }
    },

    // Redirect root to login
    {
        path: '/',
        redirect: '/login'
    },

    // Staff routes
    {
        path: '/staff',
        component: StaffLayout,
        meta: { requiresAuth: true, role: 'staff' },
        children: [
            {
                path: '',
                redirect: '/staff/dashboard'
            },
            {
                path: 'dashboard',
                name: 'StaffDashboard',
                component: StaffDashboard,
                meta: { title: 'Tổng quan' }
            },
            {
                path: 'queue',
                name: 'QueueManagement',
                component: QueueManagement,
                meta: { title: 'Quản lý hàng chờ' }
            },
            {
                path: 'hoso',
                name: 'HoSoManagement',
                component: () => import('@/views/staff/HoSoManagement.vue'),
                meta: { title: 'Quản lý hồ sơ' }
            },
            {
                path: 'documents',
                name: 'FileProcessing',
                component: FileProcessing,
                meta: { title: 'Xử lý hồ sơ' }
            },
            {
                path: 'feedbacks',
                name: 'FeedbackManagement',
                component: () => import('@/views/staff/FeedbackManagement.vue'),
                meta: { title: 'Tiếp nhận phản ánh' }
            },
            {
                path: 'profile',
                name: 'StaffProfile',
                component: () => import('@/views/shared/ProfilePage.vue'),
                meta: { title: 'Tài khoản cá nhân' }
            }
        ]
    },

    // Admin routes
    {
        path: '/admin',
        component: AdminLayout,
        meta: { requiresAuth: true, role: 'admin' },
        children: [
            {
                path: '',
                redirect: '/admin/dashboard'
            },
            {
                path: 'dashboard',
                name: 'AdminDashboard',
                component: AdminDashboard,
                meta: { title: 'Tổng quan hệ thống' }
            },
            {
                path: 'accounts',
                name: 'AccountManagement',
                component: AccountManagement,
                meta: { title: 'Quản lý tài khoản' }
            },
            {
                path: 'students',
                name: 'StudentManagement',
                component: StudentManagement,
                meta: { title: 'Quản lý sinh viên' }
            },
            {
                path: 'counters',
                name: 'CounterManagement',
                component: CounterManagement,
                meta: { title: 'Quản lý quầy' }
            },
            {
                path: 'specialties',
                name: 'SpecialtyManagement',
                component: () => import('@/views/admin/SpecialtyManagement.vue'),
                meta: { title: 'Quản lý chuyên môn' }
            },
            {
                path: 'procedures',
                name: 'ProcedureManagement',
                component: () => import('@/views/admin/ProcedureManagement.vue'),
                meta: { title: 'Quản lý thủ tục' }
            },
            {
                path: 'reports',
                name: 'Reports',
                component: Reports,
                meta: { title: 'Báo cáo & Góp ý' }
            },
            {
                path: 'profile',
                name: 'AdminProfile',
                component: () => import('@/views/shared/ProfilePage.vue'),
                meta: { title: 'Tài khoản cá nhân' }
            }
        ]
    },

    // 404 catch-all
    {
        path: '/:pathMatch(.*)*',
        redirect: '/login'
    }
]

const router = createRouter({
    history: createWebHistory(),
    routes
})

/**
 * Navigation Guard - Bảo vệ routes
 * 
 * Chạy TRƯỚC mỗi lần chuyển trang.
 * Kiểm tra:
 * 1. Route có yêu cầu đăng nhập không?
 * 2. User đã đăng nhập chưa?
 * 3. User có đủ quyền không?
 */
router.beforeEach(async (to, _from, next) => {
    // Import auth store (lazy import để tránh circular dependency)
    const { useAuthStore } = await import('@/stores/auth')
    const authStore = useAuthStore()

    // Lấy thông tin meta từ route
    const requiresAuth = to.matched.some(record => record.meta.requiresAuth)
    const requiredRole = to.meta.role as string | undefined

    // Set page title
    const title = to.meta.title as string
    if (title) {
        document.title = `${title} - Phòng Đào tạo HUIT`
    }

    // ========== LOGIC KIỂM TRA ==========

    // 1. Route không yêu cầu auth → cho đi
    if (!requiresAuth) {
        // Nếu đang ở login mà đã authenticated → redirect về dashboard
        if (to.path === '/login' && authStore.isAuthenticated) {
            next(authStore.isAdmin ? '/admin/dashboard' : '/staff/dashboard')
            return
        }
        next()
        return
    }

    // 2. Route yêu cầu auth nhưng chưa đăng nhập → redirect login
    if (!authStore.isAuthenticated) {
        console.warn('Chưa đăng nhập, redirect về /login')
        next('/login')
        return
    }

    // 3. Kiểm tra role (nếu có yêu cầu)
    if (requiredRole) {
        const userRole = authStore.user?.roleName?.toLowerCase()

        // Admin chỉ được vào admin routes
        if (authStore.isAdmin) {
            if (requiredRole === 'admin') {
                next()
                return
            }
            // Admin cố vào staff routes → redirect về admin
            console.warn('Admin không cần vào staff routes, redirect về /admin/dashboard')
            next('/admin/dashboard')
            return
        }

        // Staff chỉ được vào staff routes
        if (requiredRole === 'staff' && userRole === 'registrar') {
            next()
            return
        }

        // Staff cố vào admin routes → redirect về staff
        if (requiredRole === 'admin' && !authStore.isAdmin) {
            console.warn('Không đủ quyền Admin, redirect về /staff/dashboard')
            next('/staff/dashboard')
            return
        }
    }

    // 4. Tất cả OK → cho đi
    next()
})

export default router

