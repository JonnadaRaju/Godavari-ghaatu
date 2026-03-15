import { create } from 'zustand'
import { persist } from 'zustand/middleware'

export interface Product {
  id: number
  name: string
  description: string
  price: number
  image: string
  category: string
  type: 'veg' | 'non-veg'
  special?: 'bestseller' | 'new-arrival'
  inStock: boolean
  stock?: number
}

export interface CartItem extends Product {
  quantity: number
}

interface AuthState {
  user: { id: number; name: string; email: string; role?: string } | null
  token: string | null
  isAuthenticated: boolean
  isAdmin: boolean
  login: (user: { id: number; name: string; email: string; role?: string }, token: string) => void
  logout: () => void
}

interface CartState {
  items: CartItem[]
  addItem: (product: Product, quantity?: number) => void
  removeItem: (productId: number) => void
  updateQuantity: (productId: number, quantity: number) => void
  clearCart: () => void
  getTotalItems: () => number
  getTotalPrice: () => number
}

interface UIState {
  isCartOpen: boolean
  isAuthModalOpen: boolean
  authModalMode: 'login' | 'register'
  toast: { message: string; type: 'success' | 'error' } | null
  toggleCart: () => void
  openAuthModal: (mode?: 'login' | 'register') => void
  closeAuthModal: () => void
  showToast: (message: string, type: 'success' | 'error') => void
  hideToast: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      isAdmin: false,
      login: (user, token) => set({ 
        user, 
        token, 
        isAuthenticated: true,
        isAdmin: user.role === 'admin'
      }),
      logout: () => set({ user: null, token: null, isAuthenticated: false, isAdmin: false }),
    }),
    { name: 'auth-storage' }
  )
)

export const useCartStore = create<CartState>()(
  persist(
    (set, get) => ({
      items: [],
      addItem: (product, quantity = 1) => {
        const items = get().items
        const existingItem = items.find((item) => item.id === product.id)
        if (existingItem) {
          set({
            items: items.map((item) =>
              item.id === product.id
                ? { ...item, quantity: item.quantity + quantity }
                : item
            ),
          })
        } else {
          set({ items: [...items, { ...product, quantity }] })
        }
      },
      removeItem: (productId) =>
        set({ items: get().items.filter((item) => item.id !== productId) }),
      updateQuantity: (productId, quantity) => {
        if (quantity <= 0) {
          get().removeItem(productId)
        } else {
          set({
            items: get().items.map((item) =>
              item.id === productId ? { ...item, quantity } : item
            ),
          })
        }
      },
      clearCart: () => set({ items: [] }),
      getTotalItems: () => get().items.reduce((sum, item) => sum + item.quantity, 0),
      getTotalPrice: () =>
        get().items.reduce((sum, item) => sum + item.price * item.quantity, 0),
    }),
    { name: 'cart-storage' }
  )
)

export const useUIStore = create<UIState>((set) => ({
  isCartOpen: false,
  isAuthModalOpen: false,
  authModalMode: 'login',
  toast: null,
  toggleCart: () => set((state) => ({ isCartOpen: !state.isCartOpen })),
  openAuthModal: (mode = 'login') => set({ isAuthModalOpen: true, authModalMode: mode }),
  closeAuthModal: () => set({ isAuthModalOpen: false }),
  showToast: (message, type) => {
    set({ toast: { message, type } })
    setTimeout(() => set({ toast: null }), 3000)
  },
  hideToast: () => set({ toast: null }),
}))
