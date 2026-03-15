'use client'

import {
  HeartIcon,
  StarIcon,
  TruckIcon,
  ShieldCheckIcon,
} from '@heroicons/react/24/outline'

const features = [
  {
    icon: HeartIcon,
    title: 'Handmade with Love',
    description: 'Every product is carefully crafted using traditional recipes passed down through generations.',
    color: 'bg-saffron-100 text-saffron-600',
  },
  {
    icon: StarIcon,
    title: 'Premium Quality',
    description: 'We use only the finest ingredients sourced from trusted suppliers and local farmers.',
    color: 'bg-deep-green-100 text-deep-green-600',
  },
  {
    icon: TruckIcon,
    title: 'Fast Delivery',
    description: 'Quick and safe delivery across India with proper packaging to maintain freshness.',
    color: 'bg-blue-100 text-blue-600',
  },
  {
    icon: ShieldCheckIcon,
    title: '100% Authentic',
    description: 'Guaranteed authentic taste of Godavari region with no artificial preservatives.',
    color: 'bg-purple-100 text-purple-600',
  },
]

export default function WhyChooseUs() {
  return (
    <section className="py-16 bg-cream-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <h2 className="text-3xl font-bold text-center text-gray-800 font-serif mb-12">
          Why Choose Us
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {features.map((feature, index) => (
            <div
              key={index}
              className="bg-white rounded-xl p-6 shadow-md hover:shadow-lg transition-shadow text-center"
            >
              <div className={`w-16 h-16 ${feature.color} rounded-full flex items-center justify-center mx-auto mb-4`}>
                <feature.icon className="h-8 w-8" />
              </div>
              <h3 className="text-lg font-semibold text-gray-800 mb-2">{feature.title}</h3>
              <p className="text-gray-600">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
