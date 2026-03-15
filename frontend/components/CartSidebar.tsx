'use client'

import Link from 'next/link'
import { XMarkIcon, MinusIcon, PlusIcon, TrashIcon } from '@heroicons/react/24/outline'
import { useCartStore, useUIStore } from '@/lib/store'

export default function CartSidebar() {
  const { isCartOpen, toggleCart } = useUIStore()
  const { items, getTotalPrice, updateQuantity, removeItem } = useCartStore()
  const total = getTotalPrice()
  const deliveryFee = total >= 500 ? 0 : 50

  if (!isCartOpen) return null

  return (
    <div className="fixed inset-0 z-50 overflow-hidden">
      <div className="absolute inset-0 bg-black bg-opacity-50" onClick={toggleCart} />
      <div className="absolute inset-y-0 right-0 max-w-md w-full bg-white shadow-xl flex flex-col">
        <div className="flex items-center justify-between p-4 border-b">
          <h2 className="text-xl font-semibold text-gray-800">Shopping Cart</h2>
          <button
            onClick={toggleCart}
            className="p-2 text-gray-500 hover:text-gray-700"
          >
            <XMarkIcon className="h-6 w-6" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-4">
          {items.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-gray-500 mb-4">Your cart is empty</p>
              <button
                onClick={toggleCart}
                className="text-saffron-600 hover:text-saffron-700 font-medium"
              >
                Continue Shopping
              </button>
            </div>
          ) : (
            <div className="space-y-4">
              {items.map((item) => (
                <div
                  key={item.id}
                  className="flex items-center gap-4 bg-gray-50 rounded-lg p-3"
                >
                  <span className="text-4xl">{item.image}</span>
                  <div className="flex-1">
                    <h3 className="font-medium text-gray-800">{item.name}</h3>
                    <p className="text-saffron-600 font-semibold">₹{item.price}</p>
                    <div className="flex items-center gap-2 mt-2">
                      <button
                        onClick={() => updateQuantity(item.id, item.quantity - 1)}
                        className="p-1 bg-white rounded shadow"
                      >
                        <MinusIcon className="h-4 w-4" />
                      </button>
                      <span className="w-8 text-center">{item.quantity}</span>
                      <button
                        onClick={() => updateQuantity(item.id, item.quantity + 1)}
                        className="p-1 bg-white rounded shadow"
                      >
                        <PlusIcon className="h-4 w-4" />
                      </button>
                      <button
                        onClick={() => removeItem(item.id)}
                        className="ml-auto p-1 text-red-500 hover:text-red-700"
                      >
                        <TrashIcon className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {items.length > 0 && (
          <div className="border-t p-4 bg-gray-50">
            <div className="space-y-2 mb-4">
              <div className="flex justify-between text-gray-600">
                <span>Subtotal</span>
                <span>₹{total}</span>
              </div>
              <div className="flex justify-between text-gray-600">
                <span>Delivery</span>
                <span>{deliveryFee === 0 ? 'Free' : `₹${deliveryFee}`}</span>
              </div>
              <div className="flex justify-between text-lg font-semibold text-gray-800 pt-2 border-t">
                <span>Total</span>
                <span>₹{total + deliveryFee}</span>
              </div>
              {total < 500 && (
                <p className="text-sm text-deep-green-600">
                  Add ₹{500 - total} more for free delivery!
                </p>
              )}
            </div>
            <Link
              href="/checkout"
              onClick={toggleCart}
              className="block w-full py-3 bg-saffron-500 text-white text-center font-semibold rounded-lg hover:bg-saffron-600 transition-colors"
            >
              Proceed to Checkout
            </Link>
          </div>
        )}
      </div>
    </div>
  )
}
