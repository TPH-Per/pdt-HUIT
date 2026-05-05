// Request phase constants (matching backend INTEGER values)
export const REQUEST_PHASE = {
  CANCELLED: 0,
  QUEUE: 1,
  PENDING: 2,
  PROCESSING: 3,
  COMPLETED: 4,
  SUPPLEMENT: 6,
} as const

export type RequestPhase = typeof REQUEST_PHASE[keyof typeof REQUEST_PHASE]

export const APPOINTMENT_STATUS = {
  SCHEDULED: 0,
  COMPLETED: 1,
  CANCELLED: 2,
} as const

export type AppointmentStatus = typeof APPOINTMENT_STATUS[keyof typeof APPOINTMENT_STATUS]

export const REPORT_TYPE = {
  ACADEMIC: 'ACADEMIC',
  FINANCIAL: 'FINANCIAL',
  PERSONAL: 'PERSONAL',
  OTHER: 'OTHER',
} as const

// Generic API response wrapper
export interface ApiResponse<T> {
  success: boolean
  message: string
  data: T
  timestamp?: string
}

export interface Student {
  id: number
  studentId: string
  fullName: string
  email: string
  phone: string
  class: string
  major: string
  isActive: boolean
  createdAt: string
}

export interface Request {
  id: number
  requestCode: string
  studentId: string
  academicServiceId: number
  currentPhase: RequestPhase
  status: string
  createdAt: string
  updatedAt: string
}

export interface Appointment {
  id: number
  requestId: number
  registrarId: number
  appointmentDate: string
  appointmentTime: string
  status: AppointmentStatus
  createdAt: string
}

export interface QueueTicket {
  id: number
  ticketNumber: number
  ticketPrefix: string
  studentId: string
  deskId: number
  registrarId: number | null
  requestId: number | null
  status: string
  createdAt: string
  calledAt: string | null
  servedAt: string | null
  completedAt: string | null
}

export interface ServiceDesk {
  id: number
  deskCode: string
  deskName: string
  categoryId: number
  registrarId: number | null
  registrarName: string | null
  isActive: boolean
}

export interface Notification {
  id: number
  studentId: string
  type: string
  title: string
  body: string
  isRead: boolean
  refId: number | null
  refType: string | null
  createdAt: string
}
