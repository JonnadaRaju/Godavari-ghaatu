import axios from 'axios'
import Cookies from 'js-cookie'

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

export const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

api.interceptors.request.use((config) => {
  const token = Cookies.get('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true
      try {
        const refreshToken = Cookies.get('refreshToken')
        const response = await axios.post(`${API_URL}/api/v1/auth/refresh`, {
          refreshToken,
        })
        const { token } = response.data
        Cookies.set('token', token)
        originalRequest.headers.Authorization = `Bearer ${token}`
        return api(originalRequest)
      } catch (refreshError) {
        Cookies.remove('token')
        Cookies.remove('refreshToken')
        window.location.href = '/'
      }
    }
    return Promise.reject(error)
  }
)

export const authApi = {
  login: async (email: string, password: string) => {
    const response = await api.post('/api/v1/auth/login', { email, password })
    return {
      token: response.data.access_token,
      refreshToken: response.data.access_token,
    }
  },
  register: async (name: string, email: string, password: string) => {
    const response = await api.post('/api/v1/auth/register', { 
      full_name: name, 
      email, 
      password 
    })
    return {
      user: response.data,
      token: 'temp_token',
      refreshToken: 'temp_token',
    }
  },
  logout: async () => {
    Cookies.remove('token')
    Cookies.remove('refreshToken')
  },
  getCurrentUser: async () => {
    const response = await api.get('/api/v1/users/me')
    return response.data
  },
}

export const productApi = {
  getAll: async (params?: { category?: string; type?: string; search?: string; sort?: string }) => {
    const response = await api.get('/api/v1/products', { params })
    return response.data
  },
  getById: async (id: string) => {
    const response = await api.get(`/api/v1/products/${id}`)
    return response.data
  },
  getBestsellers: async () => {
    const response = await api.get('/api/v1/products', { params: { special: 'bestseller' } })
    return response.data
  },
}

export const orderApi = {
  create: async (orderData: {
    items: { productId: number; quantity: number }[]
    shippingAddress: {
      fullName: string
      address: string
      city: string
      state: string
      pincode: string
      phone: string
    }
    paymentMethod: string
  }) => {
    const response = await api.post('/api/v1/orders', orderData)
    return response.data
  },
}

export const adminApi = {
  getProducts: async () => {
    const response = await api.get('/api/v1/products?active_only=false')
    return response.data
  },
  createProduct: async (productData: any) => {
    const response = await api.post('/api/v1/products', productData)
    return response.data
  },
  updateProduct: async (id: number, productData: any) => {
    const response = await api.put(`/api/v1/products/${id}`, productData)
    return response.data
  },
  deleteProduct: async (id: number) => {
    const response = await api.delete(`/api/v1/products/${id}`)
    return response.data
  },
  getOrders: async () => {
    const response = await api.get('/api/v1/orders')
    return response.data
  },
  updateOrderStatus: async (id: string, status: string) => {
    let endpoint = `/api/v1/orders/${id}`
    if (status === 'PACKED') endpoint += '/pack'
    else if (status === 'SHIPPED') endpoint += '/ship'
    else if (status === 'DELIVERED') endpoint += '/deliver'
    else if (status === 'CANCELLED') endpoint += '/cancel'
    
    const response = await api.patch(endpoint, {})
    return response.data
  },
}
