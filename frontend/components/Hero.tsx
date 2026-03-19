'use client'

import Link from 'next/link'

export default function Hero() {
  return (
    <section className="relative bg-gradient-to-br from-saffron-50 via-cream-50 to-saffron-100 py-16 md:py-24 overflow-hidden">
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-10 left-10 text-9xl animate-pulse">🥒</div>
        <div className="absolute bottom-10 right-10 text-9xl animate-pulse delay-1000">🌶️</div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
        <div className="text-center">
          <h1 className="text-4xl md:text-6xl font-bold text-gray-800 font-serif mb-6">
            Authentic Taste of{' '}
            <span className="text-saffron-600">Godavari</span>
          </h1>
          <p className="text-xl text-gray-600 mb-8 max-w-2xl mx-auto">
            Discover the finest pickles, spices, and traditional delicacies crafted with
            generations of expertise.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/products?category=pickle"
              className="px-8 py-3 bg-saffron-500 text-white font-semibold rounded-lg hover:bg-saffron-600 transition-colors shadow-lg"
            >
              Shop Pickles
            </Link>
            <Link
              href="/products?category=combo"
              className="px-8 py-3 bg-deep-green-500 text-white font-semibold rounded-lg hover:bg-deep-green-600 transition-colors shadow-lg"
            >
              Explore Combos
            </Link>
          </div>
        </div>

        <div className="mt-12 flex justify-center space-x-8 text-6xl md:text-8xl">
          <span className="animate-bounce">🥭</span>
          <span className="animate-bounce delay-100">🌶️</span>
          <span className="animate-bounce delay-200">🫚</span>
          <span className="animate-bounce delay-300">🍬</span>
        </div>
      </div>
    </section>
  )
}
