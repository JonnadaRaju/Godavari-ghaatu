import Hero from '@/components/Hero'
import Categories from '@/components/Categories'
import FeaturedProducts from '@/components/FeaturedProducts'
import WhyChooseUs from '@/components/WhyChooseUs'

const mockProducts = [
  {
    id: 1,
    name: 'Mango Pickle',
    description: 'Authentic Andhra mango pickle with traditional spices',
    price: 250,
    image: '🥭',
    category: 'pickle',
    type: 'veg' as const,
    special: 'bestseller' as const,
    inStock: true,
  },
  {
    id: 2,
    name: 'Gundu Pickle',
    description: 'Traditional gundu chili pickle from Godavari region',
    price: 300,
    image: '🌶️',
    category: 'pickle',
    type: 'veg' as const,
    inStock: true,
  },
  {
    id: 3,
    name: 'Avakaya Pickle',
    description: 'Famous mango pickle with extra spicy masala',
    price: 350,
    image: '🥒',
    category: 'pickle',
    type: 'veg' as const,
    special: 'bestseller' as const,
    inStock: true,
  },
  {
    id: 4,
    name: 'Mixed Pickle',
    description: 'Combination of mango and lemon pickle',
    price: 280,
    image: '🫙',
    category: 'pickle',
    type: 'veg' as const,
    inStock: true,
  },
]

export default function HomePage() {
  return (
    <div>
      <Hero />
      <Categories />
      <FeaturedProducts products={mockProducts} />
      <WhyChooseUs />
    </div>
  )
}
