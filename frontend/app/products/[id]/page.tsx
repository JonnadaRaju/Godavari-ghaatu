'use client'

import { useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import Link from 'next/link'
import {
  ShoppingCartIcon,
  MinusIcon,
  PlusIcon,
  CheckIcon,
} from '@heroicons/react/24/outline'
import { useCartStore, useUIStore } from '@/lib/store'
import { mockProducts } from '@/lib/mock-data'

export default function ProductDetailPage() {
  const params = useParams()
  const router = useRouter()
  const [quantity, setQuantity] = useState(1)
  const addItem = useCartStore((state) => state.addItem)
  const { toggleCart, showToast } = useUIStore()

  const product = mockProducts.find((item) => item.id === Number(params.id))

  if (!product) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-gray-800 mb-4">Product not found</h2>
          <Link href="/products" className="text-saffron-600 hover:text-saffron-700">
            Back to Products
          </Link>
        </div>
      </div>
    )
  }

  const handleAddToCart = () => {
    addItem(product, quantity)
    showToast(`${product.name} added to cart!`, 'success')
    toggleCart()
  }

  const handleBuyNow = () => {
    addItem(product, quantity)
    router.push('/checkout')
  }

  return (
    <div className="min-h-screen bg-cream-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <nav className="flex items-center gap-2 text-sm text-gray-500 mb-6">
          <Link href="/" className="hover:text-saffron-600">
            Home
          </Link>
          <span>/</span>
          <Link href="/products" className="hover:text-saffron-600">
            Products
          </Link>
          <span>/</span>
          <span className="text-gray-800">{product.name}</span>
        </nav>

        <div className="bg-white rounded-xl shadow-lg overflow-hidden">
          <div className="grid grid-cols-1 lg:grid-cols-2">
            <div className="bg-gradient-to-br from-cream-50 to-saffron-50 p-8 flex items-center justify-center">
              <span className="text-[12rem]">{product.image}</span>
            </div>

            <div className="p-8">
              <div className="flex flex-wrap gap-2 mb-4">
                {product.special && (
                  <span className="px-3 py-1 text-sm font-medium text-white bg-saffron-500 rounded-full">
                    {product.special === 'bestseller' ? 'Bestseller' : 'New Arrival'}
                  </span>
                )}
                <span
                  className={`px-3 py-1 text-sm font-medium text-white rounded-full ${
                    product.type === 'veg' ? 'bg-deep-green-500' : 'bg-red-500'
                  }`}
                >
                  {product.type === 'veg' ? 'Veg' : 'Non-Veg'}
                </span>
              </div>

              <h1 className="text-3xl font-bold text-gray-800 font-serif mb-2">
                {product.name}
              </h1>

              <div className="flex items-baseline gap-2 mb-4">
                <span className="text-3xl font-bold text-saffron-600">₹{product.price}</span>
                {product.stock && product.stock <= 10 && (
                  <span className="text-sm text-red-500">Only {product.stock} left!</span>
                )}
              </div>

              <p className="text-gray-600 mb-6">{product.description}</p>

              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Quantity
                </label>
                <div className="flex items-center gap-3">
                  <button
                    onClick={() => setQuantity(Math.max(1, quantity - 1))}
                    className="p-2 border border-gray-300 rounded-lg hover:bg-gray-50"
                  >
                    <MinusIcon className="h-5 w-5" />
                  </button>
                  <span className="w-12 text-center text-lg font-medium">{quantity}</span>
                  <button
                    onClick={() => setQuantity(quantity + 1)}
                    className="p-2 border border-gray-300 rounded-lg hover:bg-gray-50"
                  >
                    <PlusIcon className="h-5 w-5" />
                  </button>
                </div>
              </div>

              <div className="flex gap-4 mb-6">
                <button
                  onClick={handleAddToCart}
                  disabled={!product.inStock}
                  className="flex-1 flex items-center justify-center gap-2 px-6 py-3 bg-saffron-500 text-white font-semibold rounded-lg hover:bg-saffron-600 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
                >
                  <ShoppingCartIcon className="h-5 w-5" />
                  Add to Cart
                </button>
                <button
                  onClick={handleBuyNow}
                  disabled={!product.inStock}
                  className="flex-1 px-6 py-3 bg-deep-green-500 text-white font-semibold rounded-lg hover:bg-deep-green-600 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
                >
                  Buy Now
                </button>
              </div>

              <div className="border-t pt-6">
                <h3 className="font-semibold text-gray-800 mb-4">Product Features</h3>
                <ul className="space-y-2">
                  <li className="flex items-center gap-2 text-gray-600">
                    <CheckIcon className="h-5 w-5 text-deep-green-500" />
                    100% Authentic Recipe
                  </li>
                  <li className="flex items-center gap-2 text-gray-600">
                    <CheckIcon className="h-5 w-5 text-deep-green-500" />
                    No Artificial Preservatives
                  </li>
                  <li className="flex items-center gap-2 text-gray-600">
                    <CheckIcon className="h-5 w-5 text-deep-green-500" />
                    Fresh Ingredients
                  </li>
                  <li className="flex items-center gap-2 text-gray-600">
                    <CheckIcon className="h-5 w-5 text-deep-green-500" />
                    Handmade with Love
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
