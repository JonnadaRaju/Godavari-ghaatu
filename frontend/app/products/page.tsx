'use client'

import { useEffect, useState, Suspense } from 'react'
import { useSearchParams } from 'next/navigation'
import { FunnelIcon, MagnifyingGlassIcon } from '@heroicons/react/24/outline'
import ProductCard from '@/components/ProductCard'
import { mockProducts } from '@/lib/mock-data'

const categories = [
  { value: '', label: 'All Categories' },
  { value: 'pickle', label: 'Pickles' },
  { value: 'spice', label: 'Spices' },
  { value: 'laddu', label: 'Laddus' },
  { value: 'combo', label: 'Combos' },
]

const types = [
  { value: '', label: 'All Types' },
  { value: 'veg', label: 'Vegetarian' },
  { value: 'non-veg', label: 'Non-Vegetarian' },
]

const specials = [
  { value: '', label: 'All' },
  { value: 'bestseller', label: 'Bestseller' },
  { value: 'new-arrival', label: 'New Arrival' },
]

const sortOptions = [
  { value: 'name-asc', label: 'Name (A-Z)' },
  { value: 'name-desc', label: 'Name (Z-A)' },
  { value: 'price-asc', label: 'Price (Low to High)' },
  { value: 'price-desc', label: 'Price (High to Low)' },
]

function ProductsContent() {
  const searchParams = useSearchParams()
  const [filteredProducts, setFilteredProducts] = useState(mockProducts)
  const [loading, setLoading] = useState(false)
  const [showFilters, setShowFilters] = useState(false)
  const [filters, setFilters] = useState({
    category: searchParams.get('category') || '',
    type: searchParams.get('type') || '',
    special: searchParams.get('special') || '',
    search: '',
    sort: '',
  })

  useEffect(() => {
    setLoading(true)
    let result = [...mockProducts]

    if (filters.category) {
      result = result.filter((product) => product.category === filters.category)
    }
    if (filters.type) {
      result = result.filter((product) => product.type === filters.type)
    }
    if (filters.special) {
      result = result.filter((product) => product.special === filters.special)
    }
    if (filters.search) {
      const search = filters.search.toLowerCase()
      result = result.filter(
        (product) =>
          product.name.toLowerCase().includes(search) ||
          product.description.toLowerCase().includes(search)
      )
    }
    if (filters.sort) {
      const [field, direction] = filters.sort.split('-')
      result.sort((a, b) => {
        if (field === 'name') {
          return direction === 'asc'
            ? a.name.localeCompare(b.name)
            : b.name.localeCompare(a.name)
        }
        return direction === 'asc' ? a.price - b.price : b.price - a.price
      })
    }

    setFilteredProducts(result)
    setLoading(false)
  }, [filters])

  const clearFilters = () => {
    setFilters({
      category: '',
      type: '',
      special: '',
      search: '',
      sort: '',
    })
  }

  const hasActiveFilters =
    filters.category || filters.type || filters.special || filters.search

  return (
    <div className="min-h-screen bg-cream-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-800 font-serif">Our Products</h1>
          <p className="text-gray-600 mt-2">Discover our authentic collection</p>
        </div>

        <div className="flex flex-col lg:flex-row gap-8">
          <button
            onClick={() => setShowFilters(!showFilters)}
            className="lg:hidden flex items-center gap-2 px-4 py-2 bg-white rounded-lg shadow"
          >
            <FunnelIcon className="h-5 w-5" />
            Filters
          </button>

          <aside className={`lg:w-64 ${showFilters ? 'block' : 'hidden'} lg:block`}>
            <div className="bg-white rounded-lg shadow p-4">
              <div className="flex justify-between items-center mb-4">
                <h2 className="font-semibold text-gray-800">Filters</h2>
                {hasActiveFilters && (
                  <button
                    onClick={clearFilters}
                    className="text-sm text-saffron-600 hover:text-saffron-700"
                  >
                    Clear all
                  </button>
                )}
              </div>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Category
                  </label>
                  <select
                    value={filters.category}
                    onChange={(e) => setFilters({ ...filters, category: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                  >
                    {categories.map((category) => (
                      <option key={category.value} value={category.value}>
                        {category.label}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Type
                  </label>
                  <select
                    value={filters.type}
                    onChange={(e) => setFilters({ ...filters, type: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                  >
                    {types.map((type) => (
                      <option key={type.value} value={type.value}>
                        {type.label}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Special
                  </label>
                  <select
                    value={filters.special}
                    onChange={(e) => setFilters({ ...filters, special: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                  >
                    {specials.map((special) => (
                      <option key={special.value} value={special.value}>
                        {special.label}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </div>
          </aside>

          <div className="flex-1">
            <div className="bg-white rounded-lg shadow p-4 mb-6">
              <div className="flex flex-col sm:flex-row gap-4">
                <div className="flex-1 relative">
                  <MagnifyingGlassIcon className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
                  <input
                    type="text"
                    placeholder="Search products..."
                    value={filters.search}
                    onChange={(e) => setFilters({ ...filters, search: e.target.value })}
                    className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg"
                  />
                </div>
                <select
                  value={filters.sort}
                  onChange={(e) => setFilters({ ...filters, sort: e.target.value })}
                  className="px-4 py-2 border border-gray-300 rounded-lg"
                >
                  <option value="">Sort by</option>
                  {sortOptions.map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="mb-4 flex items-center justify-between">
              <p className="text-gray-600">
                {filteredProducts.length} product
                {filteredProducts.length !== 1 ? 's' : ''} found
              </p>
            </div>

            {loading ? (
              <div className="text-center py-12">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-saffron-500 mx-auto"></div>
              </div>
            ) : filteredProducts.length === 0 ? (
              <div className="text-center py-12 bg-white rounded-lg shadow">
                <p className="text-gray-500 mb-4">No products found</p>
                <button
                  onClick={clearFilters}
                  className="text-saffron-600 hover:text-saffron-700"
                >
                  Clear filters
                </button>
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                {filteredProducts.map((product) => (
                  <ProductCard key={product.id} product={product} />
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export default function ProductsPage() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <ProductsContent />
    </Suspense>
  )
}
