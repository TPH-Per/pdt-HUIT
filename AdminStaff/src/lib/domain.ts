export enum REQUEST_PHASE {
  SUBMITTED = 0,
  QUEUE = 1,
  PENDING = 2,
  PROCESSING = 3,
  COMPLETED = 4,
  CANCELLED = 0,
  SUPPLEMENT = 2,
}

export enum APPOINTMENT_STATUS {
  SCHEDULED = 0,
  COMPLETED = 1,
  CANCELLED = 2,
}

export enum REPORT_TYPE {
  ACADEMIC = 'ACADEMIC',
  FINANCIAL = 'FINANCIAL',
  PERSONAL = 'PERSONAL',
  OTHER = 'OTHER',
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
  currentPhase: REQUEST_PHASE
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
  status: APPOINTMENT_STATUS
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
