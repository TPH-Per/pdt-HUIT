import axios, { AxiosInstance, AxiosError, InternalAxiosRequestConfig } from 'axios';

/**
 * API Service - Phòng Đào tạo HUIT
 * 
 * Refactored to match new backend endpoints:
 * - /api/admin/desks (was /api/admin/quays)
 * - /api/admin/categories (was /api/admin/chuyenmons)
 * - /api/admin/services (was /api/admin/loaithutucs)
 */

// Tạo axios instance với cấu hình mặc định
const api: AxiosInstance = axios.create({
    baseURL: 'http://localhost:8081/api',  // URL của Spring Boot backend
    timeout: 10000,                         // Timeout 10 giây
    headers: {
        'Content-Type': 'application/json',
    },
});

/**
 * Request Interceptor
 * Tự động thêm JWT token vào header.
 */
api.interceptors.request.use(
    (config: InternalAxiosRequestConfig) => {
        const token = localStorage.getItem('token');
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    },
    (error: AxiosError) => {
        return Promise.reject(error);
    }
);

/**
 * Response Interceptor
 * Xử lý lỗi chung (401, 500, etc.)
 */
api.interceptors.response.use(
    (response) => {
        return response;
    },
    (error: AxiosError) => {
        if (error.response) {
            const status = error.response.status;

            switch (status) {
                case 401:
                    console.warn('Unauthorized - Token expired or invalid');
                    localStorage.removeItem('token');
                    localStorage.removeItem('user');
                    if (!window.location.pathname.includes('/login')) {
                        window.location.href = '/login';
                    }
                    break;

                case 403:
                    console.warn('Forbidden - Access denied');
                    break;

                case 500:
                    console.error('Server Error:', error.response.data);
                    break;
            }
        } else if (error.request) {
            console.error('Network Error - Server không phản hồi');
        }

        return Promise.reject(error);
    }
);

export default api;

// =============================================
// AUTH API - Các hàm gọi API authentication
// =============================================

export interface LoginRequest {
    maNhanVien: string;  // Maps to 'username' on backend via @JsonAlias
    password: string;
}

export interface UserData {
    id: number;
    maNhanVien: string;
    hoTen: string;
    email: string;
    soDienThoai: string;
    roleName: string;
    roleDisplayName: string;
    tenQuay: string | null;
    quayId: number | null;
    trangThai: boolean;
    lanDangNhapCuoi: string | null;
}

export interface LoginResponse {
    token: string;
    tokenType: string;
    expiresIn: number;
    user: UserData;
}

export interface ApiResponse<T> {
    success: boolean;
    code: string;
    message: string;
    data: T;
    timestamp: string;
}

export const authApi = {
    login: (data: LoginRequest) =>
        api.post<ApiResponse<LoginResponse>>('/auth/login', data),

    logout: () =>
        api.post<ApiResponse<null>>('/auth/logout'),

    getMe: () =>
        api.get<ApiResponse<UserData>>('/auth/me'),

    validateToken: () =>
        api.get<ApiResponse<{ valid: boolean }>>('/auth/validate'),
};

// =============================================
// USER API - Admin quản lý users
// =============================================

export interface CreateUserRequest {
    maNhanVien: string;
    hoTen: string;
    email: string;
    soDienThoai?: string;
    password: string;
    roleId: number;
    quayId?: number;
}

export interface UpdateUserRequest {
    hoTen?: string;
    email?: string;
    soDienThoai?: string;
    password?: string;
    roleId?: number;
    quayId?: number;
    trangThai?: boolean;
}

export const userApi = {
    getAll: () =>
        api.get<ApiResponse<UserData[]>>('/admin/users'),

    getById: (id: number) =>
        api.get<ApiResponse<UserData>>(`/admin/users/${id}`),

    create: (data: CreateUserRequest) =>
        api.post<ApiResponse<UserData>>('/admin/users', data),

    update: (id: number, data: UpdateUserRequest) =>
        api.put<ApiResponse<UserData>>(`/admin/users/${id}`, data),

    delete: (id: number) =>
        api.delete<ApiResponse<null>>(`/admin/users/${id}`),

    resetPassword: (id: number, newPassword: string) =>
        api.post<ApiResponse<UserData>>(`/admin/users/${id}/reset-password`, { newPassword }),
};

export interface RoleData {
    id: number;
    roleName: string;
    displayName: string;
}

export const roleApi = {
    getAll: () =>
        api.get<ApiResponse<RoleData[]>>('/admin/roles'),
};

// =============================================
// PROFILE API - Cán bộ cập nhật thông tin cá nhân
// =============================================

export interface UpdateProfileRequest {
    hoTen?: string;
    email?: string;
    soDienThoai?: string;
    oldPassword?: string;
    newPassword?: string;
}

export const profileApi = {
    getMyProfile: () =>
        api.get<ApiResponse<UserData>>('/profile'),

    updateMyProfile: (data: UpdateProfileRequest) =>
        api.put<ApiResponse<UserData>>('/profile', data),
};

// =============================================
// SERVICE DESK API (was QUAY API)
// Backend: /api/admin/desks
// =============================================

export interface ServiceDeskData {
    id: number;
    deskCode: string;
    deskName: string;
    location: string;
    categoryId: number | null;
    categoryName: string | null;
    isActive: boolean;
    notes: string;
    createdAt: string;
    staffCount: number;
}

// Aliases cho backward compatibility trong views
export type QuayData = ServiceDeskData;

export interface CreateServiceDeskRequest {
    deskCode: string;
    deskName: string;
    location?: string;
    categoryId?: number;
    notes?: string;
}

export type CreateQuayRequest = CreateServiceDeskRequest;

export interface UpdateServiceDeskRequest {
    deskName?: string;
    location?: string;
    categoryId?: number;
    notes?: string;
    isActive?: boolean;
}

export type UpdateQuayRequest = UpdateServiceDeskRequest;

export const serviceDeskApi = {
    getAll: () =>
        api.get<ApiResponse<ServiceDeskData[]>>('/admin/desks'),

    getById: (id: number) =>
        api.get<ApiResponse<ServiceDeskData>>(`/admin/desks/${id}`),

    create: (data: CreateServiceDeskRequest) =>
        api.post<ApiResponse<ServiceDeskData>>('/admin/desks', data),

    update: (id: number, data: UpdateServiceDeskRequest) =>
        api.put<ApiResponse<ServiceDeskData>>(`/admin/desks/${id}`, data),

    delete: (id: number) =>
        api.delete<ApiResponse<null>>(`/admin/desks/${id}`),
};

// Backward compat alias
export const quayApi = serviceDeskApi;

// =============================================
// SERVICE CATEGORY API (was CHUYEN MON API)
// Backend: /api/admin/categories
// =============================================

export interface ServiceCategoryData {
    id: number;
    name: string;
    description: string;
    isActive: boolean;
    createdAt: string;
    deskCount: number;
    serviceCount: number;
}

export type ChuyenMonData = ServiceCategoryData;

export interface CreateServiceCategoryRequest {
    name: string;
    description?: string;
}

export type CreateChuyenMonRequest = CreateServiceCategoryRequest;

export interface UpdateServiceCategoryRequest {
    name?: string;
    description?: string;
    isActive?: boolean;
}

export type UpdateChuyenMonRequest = UpdateServiceCategoryRequest;

export const serviceCategoryApi = {
    getAll: () =>
        api.get<ApiResponse<ServiceCategoryData[]>>('/admin/categories'),

    getById: (id: number) =>
        api.get<ApiResponse<ServiceCategoryData>>(`/admin/categories/${id}`),

    create: (data: CreateServiceCategoryRequest) =>
        api.post<ApiResponse<ServiceCategoryData>>('/admin/categories', data),

    update: (id: number, data: UpdateServiceCategoryRequest) =>
        api.put<ApiResponse<ServiceCategoryData>>(`/admin/categories/${id}`, data),

    delete: (id: number) =>
        api.delete<ApiResponse<null>>(`/admin/categories/${id}`),
};

// Backward compat alias
export const chuyenMonApi = serviceCategoryApi;

// =============================================
// ACADEMIC SERVICE API (was LOAI THU TUC API)
// Backend: /api/admin/services
// =============================================

export interface AcademicServiceData {
    id: number;
    serviceCode: string;
    serviceName: string;
    description: string | null;
    categoryId: number;
    categoryName: string;
    processingDays: number;
    requiredDocuments: string | null;
    formSchema: string | null;
    displayOrder: number;
    isActive: boolean;
    createdAt: string;
    requestCount: number;
}

export type LoaiThuTucData = AcademicServiceData;

export interface CreateAcademicServiceRequest {
    serviceCode: string;
    serviceName: string;
    description?: string;
    categoryId: number;
    processingDays?: number;
    requiredDocuments?: string;
    formSchema?: string;
    displayOrder?: number;
}

export type CreateLoaiThuTucRequest = CreateAcademicServiceRequest;

export interface UpdateAcademicServiceRequest {
    serviceName?: string;
    description?: string;
    categoryId?: number;
    processingDays?: number;
    requiredDocuments?: string;
    formSchema?: string;
    displayOrder?: number;
    isActive?: boolean;
}

export type UpdateLoaiThuTucRequest = UpdateAcademicServiceRequest;

export const academicServiceApi = {
    // Lấy danh sách tất cả dịch vụ (Admin)
    getAll: () =>
        api.get<ApiResponse<AcademicServiceData[]>>('/admin/services'),

    // Lấy dịch vụ theo ID
    getById: (id: number) =>
        api.get<ApiResponse<AcademicServiceData>>(`/admin/services/${id}`),

    // Lấy dịch vụ theo danh mục
    getByCategory: (categoryId: number) =>
        api.get<ApiResponse<AcademicServiceData[]>>(`/admin/services/by-category/${categoryId}`),

    // Tạo dịch vụ mới
    create: (data: CreateAcademicServiceRequest) =>
        api.post<ApiResponse<AcademicServiceData>>('/admin/services', data),

    // Cập nhật dịch vụ
    update: (id: number, data: UpdateAcademicServiceRequest) =>
        api.put<ApiResponse<AcademicServiceData>>(`/admin/services/${id}`, data),

    // Xóa dịch vụ (soft delete)
    delete: (id: number) =>
        api.delete<ApiResponse<null>>(`/admin/services/${id}`),
};

// Backward compat alias
export const loaiThuTucApi = academicServiceApi;

// Public API cho sinh viên (không cần đăng nhập)
export const publicServiceApi = {
    getAll: () =>
        api.get<ApiResponse<AcademicServiceData[]>>('/public/services'),

    getById: (id: number) =>
        api.get<ApiResponse<AcademicServiceData>>(`/public/services/${id}`),

    getByCategory: (categoryId: number) =>
        api.get<ApiResponse<AcademicServiceData[]>>(`/public/services/by-category/${categoryId}`),
};

// Backward compat alias
export const publicLoaiThuTucApi = publicServiceApi;

// =============================================
// QUEUE API - Cán bộ đào tạo quản lý hàng chờ
// =============================================

export interface LichHenData {
    id: number;
    maLichHen: string;
    soThuTu: number;
    soThuTuDisplay: string;
    mssv: string;
    hoTenSinhVien: string;
    soDienThoai: string | null;
    tenThuTuc: string;
    maThuTuc: string;
    tenQuay: string;
    maQuay: string;
    ngayHen: string;
    thoiGianDuKien: string | null;
    thoiGianGoiSo: string | null;
    thoiGianBatDauXuLy: string | null;
    thoiGianKetThuc: string | null;
    trangThai: number;
    trangThaiText: string;
    tenCanBoXuLy: string | null;
    lyDoHuy: string | null;
}

export interface QueueDashboardData {
    deskId: number;
    deskName: string;
    deskCode: string;
    currentProcessing: ApplicationData | null;
    waitingList: ApplicationData[];
    totalWaiting: number;
    totalCompleted: number;
    totalCancelled: number;
    averageProcessingTime: number | null;
}

export interface ApplicationData {
    id: number;
    requestCode: string;
    serviceId: number;
    serviceCode: string;
    serviceName: string;
    studentId: string;
    studentName: string;
    studentPhone: string | null;
    currentPhase: number;
    phaseName: string;
    queueNumber: number;
    queuePrefix: string;
    queueDisplay: string;
    appointmentDate: string | null;
    expectedTime: string | null;
    deadline: string | null;
    priority: number;
    priorityName: string;
    cancelReason: string | null;
    cancelType: number | null;
    createdAt: string;
    updatedAt: string | null;
}

export interface QueueStatusRequest {
    trangThai?: number;
    lyDo?: string;
    ghiChu?: string;
}

export const queueApi = {
    getDashboard: () =>
        api.get<ApiResponse<QueueDashboardData>>('/registrar/queue/dashboard'),

    getWaitingList: () =>
        api.get<ApiResponse<LichHenData[]>>('/registrar/queue/waiting'),

    getCurrentProcessing: () =>
        api.get<ApiResponse<LichHenData | null>>('/registrar/queue/current'),

    callNext: (id?: number) => api.post<ApiResponse<LichHenData>>('/registrar/queue/call-next', { id }),

    getSlots: (date: string) => api.get<ApiResponse<{
        morning: { time: string; booked: boolean }[];
        afternoon: { time: string; booked: boolean }[];
    }>>('/registrar/queue/slots', { params: { date } }),

    supplement: (id: number, data: { appointmentDate: string; appointmentTime: string }) =>
        api.post<ApiResponse<LichHenData>>(`/registrar/queue/${id}/supplement`, data),

    receive: (id: number, data?: { appointmentDate: string; expectedTime: string }) =>
        api.post<ApiResponse<LichHenData>>(`/registrar/queue/${id}/receive`, data),

    complete: (id: number, ghiChu?: string) =>
        api.post<ApiResponse<LichHenData>>(`/registrar/queue/${id}/complete`, { ghiChu }),

    cancel: (id: number, lyDo: string, trangThai?: number) =>
        api.post<ApiResponse<LichHenData>>(`/registrar/queue/${id}/cancel`, {
            lyDo,
            trangThai: trangThai ?? 3
        }),
};

// =============================================
// HOSO API - Cán bộ đào tạo quản lý hồ sơ
// =============================================

export interface HoSoData {
    id: number;
    maHoSo: string;
    mssv: string;
    hoTenSinhVien: string;
    soDienThoai: string | null;
    tenThuTuc: string;
    maThuTuc: string;
    tenQuay: string;
    trangThai: number;
    trangThaiText: string;
    doUuTien: number;
    ngayNop: string;
    hanXuLy: string | null;
    ngayHoanThanh: string | null;
    nguonGoc: string;
    maLichHen: string | null;
}

export interface HoSoDetailData extends HoSoData {
    email: string | null;
    diaChi: string | null;
    loaiThuTucId: number;
    thoiGianXuLyQuyDinh: number;
    thongTinHoSo: Record<string, unknown> | null;
    fileDinhKem: Record<string, unknown>[] | null;
    ghiChu: string | null;
    lichHen: LichHenData | null;
    lichSuXuLy: {
        nguoiXuLy: string;
        hanhDong: string;
        trangThaiCu: string;
        trangThaiMoi: string;
        noiDung: string;
        thoiGian: string;
    }[];
}

export interface HoSoDashboardData {
    tongSoHoSo: number;
    choXuLy: number;
    dangXuLy: number;
    hoanThanh: number;
    treHan: number;
}

export interface CreateHoSoRequest {
    mssv: string;
    hoTen: string;
    soDienThoai?: string;
    email?: string;
    nganh?: string;
    loaiThuTucId: number;
    thongTinHoSo?: Record<string, unknown>;
    fileDinhKem?: Record<string, unknown>[];
    ghiChu?: string;
    doUuTien?: number;
    confirmDuplicate?: boolean;
}

export interface UpdateHoSoRequest {
    hoTen?: string;
    soDienThoai?: string;
    diaChi?: string;
    thongTinHoSo?: Record<string, unknown>;
    fileDinhKem?: Record<string, unknown>[];
    ghiChu?: string;
    doUuTien?: number;
    ngayHoanThanh?: string;
}

export interface ChangeStatusRequest {
    trangThaiMoi: number;
    noiDung?: string;
    ghiChu?: string;
    ngayHen?: string;
    gioHen?: string;
}

export const hoSoApi = {
    getDashboard: () =>
        api.get<ApiResponse<HoSoDashboardData>>('/registrar/requests/dashboard'),

    getList: (trangThai?: number) =>
        api.get<ApiResponse<HoSoData[]>>('/registrar/requests', { params: { trangThai } }),

    getById: (id: number) =>
        api.get<ApiResponse<HoSoDetailData>>(`/registrar/requests/${id}`),

    create: (data: CreateHoSoRequest) =>
        api.post<ApiResponse<HoSoData>>('/registrar/requests', data),

    update: (id: number, data: UpdateHoSoRequest) =>
        api.put<ApiResponse<HoSoData>>(`/registrar/requests/${id}`, data),

    createFromLichHen: (lichHenId: number) =>
        api.post<ApiResponse<HoSoData>>(`/registrar/requests/from-lichhen/${lichHenId}`),

    updateStatus: (id: number, data: ChangeStatusRequest) =>
        api.put<ApiResponse<HoSoData>>(`/registrar/requests/${id}/status`, data),
};

// =============================================
// FEEDBACK API - Cán bộ đào tạo quản lý phản ánh
// =============================================

export interface Feedback {
    id: number;
    type: number;
    title: string;
    content: string;
    studentName: string;
    studentId: string;
    requestCode: string;
    status: number;
    createdAt: string;
    replies: Reply[];
}

export interface Reply {
    id: number;
    content: string;
    registrarName: string;
    createdAt: string;
}

export const feedbackApi = {
    getList: (status?: number) => api.get<ApiResponse<Feedback[]>>('/registrar/feedbacks', { params: { status } }),
    getDetail: (id: number) => api.get<ApiResponse<Feedback>>(`/registrar/feedbacks/${id}`),
    reply: (id: number, content: string) => api.post<ApiResponse<Feedback>>(`/registrar/feedbacks/${id}/reply`, { content })
};

// =============================================
// ADMIN STUDENT API - Quản lý sinh viên
// =============================================
export const studentAdminApi = {
    getAll() {
        return api.get<any[]>('/admin/students').then(res => res.data);
    },
    getById(mssv: string) {
        return api.get<any>(`/admin/students/${mssv}`).then(res => res.data);
    },
    create(data: any) {
        return api.post<any>('/admin/students', data).then(res => res.data);
    },
    update(mssv: string, data: any) {
        return api.put<any>(`/admin/students/${mssv}`, data).then(res => res.data);
    },
    delete(mssv: string) {
        return api.delete<any>(`/admin/students/${mssv}`).then(res => res.data);
    },
    resetPassword(mssv: string, newPassword: string) {
        return api.post<any>(`/admin/students/${mssv}/reset-password`, { newPassword }).then(res => res.data);
    }
};
