import Categories from '@/components/Categories'
import FeaturedProducts from '@/components/FeaturedProducts'
import Hero from '@/components/Hero'
import WhyChooseUs from '@/components/WhyChooseUs'
import { mockProducts } from '@/lib/mock-data'

export default function HomePage() {
  return (
    <div>
      <Hero />
      <Categories />
      <FeaturedProducts products={mockProducts.slice(0, 4)} />
      <WhyChooseUs />
    </div>
  )
}
