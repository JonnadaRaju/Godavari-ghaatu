'use client'

import { CheckCircleIcon, XCircleIcon, XMarkIcon } from '@heroicons/react/24/outline'
import { useUIStore } from '@/lib/store'

export default function Toast() {
  const { toast, hideToast } = useUIStore()

  if (!toast) return null

  return (
    <div className="fixed bottom-4 right-4 z-50 animate-slide-up">
      <div
        className={`flex items-center gap-3 px-4 py-3 rounded-lg shadow-lg ${
          toast.type === 'success' ? 'bg-deep-green-500' : 'bg-red-500'
        } text-white`}
      >
        {toast.type === 'success' ? (
          <CheckCircleIcon className="h-5 w-5" />
        ) : (
          <XCircleIcon className="h-5 w-5" />
        )}
        <span>{toast.message}</span>
        <button onClick={hideToast} className="ml-2 hover:opacity-80">
          <XMarkIcon className="h-5 w-5" />
        </button>
      </div>
    </div>
  )
}
