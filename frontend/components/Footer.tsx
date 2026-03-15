import Link from 'next/link'

export default function Footer() {
  return (
    <footer className="bg-gray-800 text-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          <div>
            <h3 className="text-xl font-bold font-serif mb-4">Godavari Ghaatu</h3>
            <p className="text-gray-300">
              Authentic Indian pickles and traditional food products made with love and traditional recipes.
            </p>
          </div>

          <div>
            <h4 className="text-lg font-semibold mb-4">Quick Links</h4>
            <ul className="space-y-2">
              <li>
                <Link href="/" className="text-gray-300 hover:text-saffron-400 transition-colors">
                  Home
                </Link>
              </li>
              <li>
                <Link href="/products" className="text-gray-300 hover:text-saffron-400 transition-colors">
                  Products
                </Link>
              </li>
            </ul>
          </div>

          <div>
            <h4 className="text-lg font-semibold mb-4">Categories</h4>
            <ul className="space-y-2">
              <li>
                <Link href="/products?category=pickle" className="text-gray-300 hover:text-saffron-400 transition-colors">
                  Pickles
                </Link>
              </li>
              <li>
                <Link href="/products?category=spice" className="text-gray-300 hover:text-saffron-400 transition-colors">
                  Spices
                </Link>
              </li>
              <li>
                <Link href="/products?category=laddu" className="text-gray-300 hover:text-saffron-400 transition-colors">
                  Laddus
                </Link>
              </li>
              <li>
                <Link href="/products?category=combo" className="text-gray-300 hover:text-saffron-400 transition-colors">
                  Combos
                </Link>
              </li>
            </ul>
          </div>

          <div>
            <h4 className="text-lg font-semibold mb-4">Contact</h4>
            <ul className="space-y-2 text-gray-300">
              <li>Email: info@godavarighaatu.com</li>
              <li>Phone: +91 1234567890</li>
              <li>Address: Godavari, Andhra Pradesh, India</li>
            </ul>
          </div>
        </div>

        <div className="border-t border-gray-700 mt-8 pt-8 text-center text-gray-300">
          <p>&copy; {new Date().getFullYear()} Godavari Ghaatu. All rights reserved.</p>
        </div>
      </div>
    </footer>
  )
}
