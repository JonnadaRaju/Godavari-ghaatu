'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import Cookies from 'js-cookie'
import { useAuthStore } from '@/lib/store'
import { authApi } from '@/lib/api'

export default function AdminLoginPage() {
  const router = useRouter()
  const login = useAuthStore((state) => state.login)
  const [formData, setFormData] = useState({ email: '', password: '' })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      const response = await authApi.login(formData.email, formData.password)
      Cookies.set('token', response.token)
      
      const userResponse = await authApi.getCurrentUser()
      
      if (userResponse.role !== 'admin') {
        setError('Access denied. Admin only.')
        Cookies.remove('token')
        return
      }
      
      login({ 
        id: userResponse.id, 
        name: userResponse.full_name, 
        email: userResponse.email,
        role: userResponse.role 
      }, response.token)
      
      router.push('/admin')
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Invalid credentials')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-100 flex items-center justify-center">
      <div className="bg-white p-8 rounded-lg shadow-md w-full max-w-md">
        <h1 className="text-2xl font-bold text-center mb-6 font-serif">Admin Login</h1>
        
        {error && (
          <div className="mb-4 p-3 bg-red-50 text-red-600 rounded-lg text-sm">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
            <input
              type="email"
              required
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-saffron-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
            <input
              type="password"
              required
              value={formData.password}
              onChange={(e) => setFormData({ ...formData, password: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-saffron-500"
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 bg-saffron-500 text-white font-semibold rounded-lg hover:bg-saffron-600 transition-colors disabled:bg-gray-300"
          >
            {loading ? 'Please wait...' : 'Login'}
          </button>
        </form>

        <p className="mt-4 text-center text-sm">
          <Link href="/" className="text-saffron-600 hover:text-saffron-700">Back to Home</Link>
        </p>
      </div>
    </div>
  )
}
