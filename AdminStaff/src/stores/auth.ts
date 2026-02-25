import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { authApi, type UserData, type LoginRequest } from '@/services/api';
import router from '@/router';

/**
 * Auth Store - Quản lý trạng thái đăng nhập
 * 
 * Sử dụng Composition API style (setup function)
 * 
 * State:
 * - user: Thông tin user đã đăng nhập
 * - token: JWT token
 * - loading: Trạng thái đang xử lý
 * - error: Thông báo lỗi
 * 
 * Actions:
 * - login(): Đăng nhập
 * - logout(): Đăng xuất
 * - checkAuth(): Kiểm tra token còn valid không
 * 
 * Getters:
 * - isAuthenticated: Đã đăng nhập chưa
 * - isAdmin: Có phải Admin không
 * - isRegistrar: Có phải Cán bộ đào tạo không
 */
export const useAuthStore = defineStore('auth', () => {
    // ==================== STATE ====================

    /**
     * Thông tin user đã đăng nhập
     * Lấy từ localStorage khi khởi tạo (để persist qua refresh)
     */
    const user = ref<UserData | null>(
        JSON.parse(localStorage.getItem('user') || 'null')
    );

    /**
     * JWT token
     * Lấy từ localStorage khi khởi tạo
     */
    const token = ref<string | null>(
        localStorage.getItem('token')
    );

    /**
     * Trạng thái đang xử lý (loading spinner)
     */
    const loading = ref(false);

    /**
     * Thông báo lỗi
     */
    const error = ref<string | null>(null);

    // ==================== GETTERS ====================

    /**
     * Đã đăng nhập chưa?
     * True nếu có token
     */
    const isAuthenticated = computed(() => !!token.value);

    /**
     * Có phải Admin không?
     */
    const isAdmin = computed(() => user.value?.roleName === 'Admin');

    /**
     * Có phải Cán bộ đào tạo (Registrar) không?
     */
    const isStaff = computed(() => user.value?.roleName === 'Registrar');

    /**
     * Tên hiển thị của user
     */
    const displayName = computed(() => user.value?.hoTen || 'Chưa đăng nhập');

    /**
     * Role hiển thị
     */
    const roleDisplay = computed(() => user.value?.roleDisplayName || '');

    // ==================== ACTIONS ====================

    /**
     * Đăng nhập
     * 
     * @param credentials - Mã nhân viên và mật khẩu
     * @returns true nếu thành công, false nếu thất bại
     */
    async function login(credentials: LoginRequest): Promise<boolean> {
        loading.value = true;
        error.value = null;

        try {
            // Gọi API login
            const response = await authApi.login(credentials);

            // Kiểm tra response
            if (response.data.success) {
                const { token: newToken, user: userData } = response.data.data;

                // Lưu vào state
                token.value = newToken;
                user.value = userData;

                // Lưu vào localStorage (persist qua refresh)
                localStorage.setItem('token', newToken);
                localStorage.setItem('user', JSON.stringify(userData));

                console.log('Đăng nhập thành công:', userData.hoTen);
                return true;
            } else {
                error.value = response.data.message || 'Đăng nhập thất bại';
                return false;
            }
        } catch (err: any) {
            // Xử lý lỗi từ API
            if (err.response?.data?.message) {
                error.value = err.response.data.message;
            } else if (err.response?.status === 401) {
                error.value = 'Mã cán bộ hoặc mật khẩu không đúng';
            } else {
                error.value = 'Lỗi kết nối server. Vui lòng thử lại.';
            }
            console.error('Login error:', err);
            return false;
        } finally {
            loading.value = false;
        }
    }

    /**
     * Đăng xuất
     */
    async function logout(): Promise<void> {
        try {
            // Gọi API logout (optional, vì JWT stateless)
            if (token.value) {
                await authApi.logout();
            }
        } catch (err) {
            // Ignore error, vẫn tiếp tục logout local
            console.warn('Logout API error:', err);
        } finally {
            // Xóa state
            token.value = null;
            user.value = null;
            error.value = null;

            // Xóa localStorage
            localStorage.removeItem('token');
            localStorage.removeItem('user');

            // Redirect về login
            router.push('/login');
        }
    }

    /**
     * Kiểm tra token còn valid không
     * Gọi khi app khởi động
     */
    async function checkAuth(): Promise<boolean> {
        if (!token.value) {
            return false;
        }

        try {
            const response = await authApi.validateToken();
            return response.data.data?.valid === true;
        } catch (err) {
            // Token không valid → logout
            await logout();
            return false;
        }
    }

    /**
     * Xóa error
     */
    function clearError(): void {
        error.value = null;
    }

    // ==================== RETURN ====================
    // Expose tất cả state, getters, actions

    return {
        // State
        user,
        token,
        loading,
        error,

        // Getters
        isAuthenticated,
        isAdmin,
        isStaff,
        displayName,
        roleDisplay,

        // Actions
        login,
        logout,
        checkAuth,
        clearError,
    };
});
