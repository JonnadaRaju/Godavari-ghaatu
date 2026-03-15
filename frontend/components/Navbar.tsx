'use client'

import Link from 'next/link'
import { ShoppingCartIcon, UserIcon, Bars3Icon, XMarkIcon } from '@heroicons/react/24/outline'
import { useCartStore, useAuthStore, useUIStore } from '@/lib/store'
import { useState, useEffect } from 'react'

export default function Navbar() {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)
  const [mounted, setMounted] = useState(false)
  const { getTotalItems } = useCartStore()
  const { isAuthenticated, user, logout } = useAuthStore()
  const { toggleCart, openAuthModal } = useUIStore()
  
  useEffect(() => {
    setMounted(true)
  }, [])
  
  const totalItems = mounted ? getTotalItems() : 0

  return (
    <nav className="bg-white shadow-md sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          <Link href="/" className="flex-shrink-0 flex items-center">
            <span className="text-2xl font-bold text-saffron-600 font-serif">
              Godavari Ghaatu
            </span>
          </Link>

          <div className="hidden md:flex items-center space-x-8">
            <Link href="/" className="text-gray-700 hover:text-saffron-600 transition-colors">
              Home
            </Link>
            <Link href="/products" className="text-gray-700 hover:text-saffron-600 transition-colors">
              Products
            </Link>
            <button
              onClick={toggleCart}
              className="relative p-2 text-gray-700 hover:text-saffron-600 transition-colors"
            >
              <ShoppingCartIcon className="h-6 w-6" />
              {totalItems > 0 && (
                <span className="absolute -top-1 -right-1 bg-saffron-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
                  {totalItems}
                </span>
              )}
            </button>
            {mounted && isAuthenticated ? (
              <div className="flex items-center space-x-4">
                <span className="text-gray-700">{user?.name}</span>
                <button
                  onClick={logout}
                  className="text-gray-700 hover:text-saffron-600 transition-colors"
                >
                  Logout
                </button>
              </div>
            ) : mounted ? (
              <button
                onClick={() => openAuthModal('login')}
                className="flex items-center space-x-2 text-gray-700 hover:text-saffron-600 transition-colors"
              >
                <UserIcon className="h-6 w-6" />
                <span>Login</span>
              </button>
            ) : null}
          </div>

          <div className="md:hidden flex items-center space-x-4">
            <button
              onClick={toggleCart}
              className="relative p-2 text-gray-700 hover:text-saffron-600"
            >
              <ShoppingCartIcon className="h-6 w-6" />
              {totalItems > 0 && (
                <span className="absolute -top-1 -right-1 bg-saffron-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
                  {totalItems}
                </span>
              )}
            </button>
            <button
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              className="p-2 text-gray-700"
            >
              {isMobileMenuOpen ? (
                <XMarkIcon className="h-6 w-6" />
              ) : (
                <Bars3Icon className="h-6 w-6" />
              )}
            </button>
          </div>
        </div>
      </div>

      {isMobileMenuOpen && (
        <div className="md:hidden bg-white border-t">
          <div className="px-2 pt-2 pb-3 space-y-1 sm:px-3">
            <Link
              href="/"
              className="block px-3 py-2 text-gray-700 hover:bg-saffron-50"
              onClick={() => setIsMobileMenuOpen(false)}
            >
              Home
            </Link>
            <Link
              href="/products"
              className="block px-3 py-2 text-gray-700 hover:bg-saffron-50"
              onClick={() => setIsMobileMenuOpen(false)}
            >
              Products
            </Link>
            {mounted && isAuthenticated ? (
              <button
                onClick={() => {
                  logout()
                  setIsMobileMenuOpen(false)
                }}
                className="block w-full text-left px-3 py-2 text-gray-700 hover:bg-saffron-50"
              >
                Logout
              </button>
            ) : mounted ? (
              <button
                onClick={() => {
                  openAuthModal('login')
                  setIsMobileMenuOpen(false)
                }}
                className="block w-full text-left px-3 py-2 text-gray-700 hover:bg-saffron-50"
              >
                Login
              </button>
            ) : null}
          </div>
        </div>
      )}
    </nav>
  )
}
