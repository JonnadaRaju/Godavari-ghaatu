'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { useAuthStore } from '@/lib/store'

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname()
  const router = useRouter()
  const { isAdmin, logout, user } = useAuthStore()
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  useEffect(() => {
    if (mounted && !isAdmin) {
      router.push('/admin/login')
    }
  }, [mounted, isAdmin, router])

  const handleLogout = () => {
    logout()
    router.push('/')
  }

  const navItems = [
    { href: '/admin', label: 'Dashboard', icon: '📊' },
    { href: '/admin/products', label: 'Products', icon: '📦' },
    { href: '/admin/orders', label: 'Orders', icon: '🛒' },
  ]

  if (!mounted) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-saffron-500"></div>
      </div>
    )
  }

  if (!isAdmin) {
    return null
  }

  return (
    <div className="min-h-screen bg-gray-100">
      <nav className="bg-white shadow-md">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex justify-between h-16">
            <div className="flex items-center space-x-8">
              <Link href="/admin" className="text-xl font-bold text-saffron-600 font-serif">
                Admin Panel
              </Link>
              <div className="flex space-x-4">
                {navItems.map((item) => (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={`px-3 py-2 rounded-md text-sm font-medium ${
                      pathname === item.href
                        ? 'bg-saffron-100 text-saffron-600'
                        : 'text-gray-700 hover:bg-gray-100'
                    }`}
                  >
                    {item.icon} {item.label}
                  </Link>
                ))}
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-sm text-gray-600">{user?.name}</span>
              <button
                onClick={handleLogout}
                className="px-3 py-2 text-sm text-gray-700 hover:text-saffron-600"
              >
                Logout
              </button>
              <Link href="/" className="text-sm text-saffron-600 hover:text-saffron-700">
                View Site
              </Link>
            </div>
          </div>
        </div>
      </nav>
      <main className="max-w-7xl mx-auto px-4 py-8">{children}</main>
    </div>
  )
}
