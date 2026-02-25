import Swal, { type SweetAlertResult } from 'sweetalert2'

export const confirmAction = async (
    title: string,
    text: string,
    confirmText = 'Xác nhận',
    cancelText = 'Hủy'
): Promise<boolean> => {
    const result: SweetAlertResult = await Swal.fire({
        title,
        text,
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#003366', // Staff color
        cancelButtonColor: '#d33',
        confirmButtonText: confirmText,
        cancelButtonText: cancelText
    })
    return result.isConfirmed
}

export const showSuccess = (title: string, text?: string) => {
    // Vue Sonner is preferred for simple notifications, but SweetAlert makes a stronger impression
    Swal.fire({
        title,
        text,
        icon: 'success',
        timer: 1500,
        showConfirmButton: false
    })
}

export const showError = (title: string, text?: string) => {
    Swal.fire({
        title,
        text,
        icon: 'error'
    })
}
