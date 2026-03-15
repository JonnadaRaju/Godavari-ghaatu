'use client'

import Link from 'next/link'

const categories = [
  {
    name: 'Pickles',
    slug: 'pickle',
    emoji: '🥒',
    gradient: 'from-saffron-400 to-saffron-600',
  },
  {
    name: 'Spices',
    slug: 'spice',
    emoji: '🌶️',
    gradient: 'from-red-400 to-red-600',
  },
  {
    name: 'Laddus',
    slug: 'laddu',
    emoji: '🍬',
    gradient: 'from-amber-400 to-amber-600',
  },
  {
    name: 'Combos',
    slug: 'combo',
    emoji: '🎁',
    gradient: 'from-deep-green-400 to-deep-green-600',
  },
]

export default function Categories() {
  return (
    <section className="py-16 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <h2 className="text-3xl font-bold text-center text-gray-800 font-serif mb-12">
          Shop by Category
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {categories.map((category) => (
            <Link
              key={category.slug}
              href={`/products?category=${category.slug}`}
              className="group relative overflow-hidden rounded-2xl shadow-lg transition-transform hover:scale-105"
            >
              <div className={`h-48 bg-gradient-to-br ${category.gradient} flex items-center justify-center`}>
                <span className="text-7xl group-hover:scale-110 transition-transform">
                  {category.emoji}
                </span>
              </div>
              <div className="absolute bottom-0 left-0 right-0 bg-white/95 backdrop-blur-sm py-4 text-center">
                <h3 className="text-xl font-semibold text-gray-800">{category.name}</h3>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </section>
  )
}
