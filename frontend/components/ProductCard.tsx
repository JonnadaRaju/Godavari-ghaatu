'use client'

import Link from 'next/link'
import { ShoppingCartIcon } from '@heroicons/react/24/outline'
import { Product, useCartStore, useUIStore } from '@/lib/store'

interface ProductCardProps {
  product: Product
}

export default function ProductCard({ product }: ProductCardProps) {
  const addItem = useCartStore((state) => state.addItem)
  const showToast = useUIStore((state) => state.showToast)

  const handleAddToCart = (e: React.MouseEvent) => {
    e.preventDefault()
    addItem(product, 1)
    showToast(`${product.name} added to cart!`, 'success')
  }

  return (
    <Link href={`/products/${product.id}`} className="group">
      <div className="bg-white rounded-xl shadow-md overflow-hidden hover:shadow-lg transition-shadow">
        <div className="relative h-48 bg-gradient-to-br from-cream-50 to-saffron-50 flex items-center justify-center">
          <span className="text-7xl group-hover:scale-110 transition-transform">
            {product.image}
          </span>
          {product.special && (
            <span className="absolute top-2 left-2 px-2 py-1 text-xs font-semibold text-white rounded-full bg-saffron-500">
              {product.special === 'bestseller' ? 'Bestseller' : 'New'}
            </span>
          )}
          {product.type && (
            <span className="absolute top-2 right-2 px-2 py-1 text-xs font-semibold text-white rounded-full bg-deep-green-500">
              {product.type === 'veg' ? 'Veg' : 'Non-Veg'}
            </span>
          )}
        </div>
        <div className="p-4">
          <h3 className="text-lg font-semibold text-gray-800 mb-1 truncate">
            {product.name}
          </h3>
          <p className="text-gray-500 text-sm mb-2 line-clamp-2">{product.description}</p>
          <div className="flex items-center justify-between">
            <span className="text-xl font-bold text-saffron-600">₹{product.price}</span>
            <button
              onClick={handleAddToCart}
              disabled={!product.inStock}
              className="flex items-center space-x-1 px-3 py-2 bg-saffron-500 text-white rounded-lg hover:bg-saffron-600 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
            >
              <ShoppingCartIcon className="h-4 w-4" />
              <span className="text-sm">Add</span>
            </button>
          </div>
          {!product.inStock && <p className="text-red-500 text-sm mt-2">Out of stock</p>}
        </div>
      </div>
    </Link>
  )
}
