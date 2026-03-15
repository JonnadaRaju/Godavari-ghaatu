import './globals.css'
import type { Metadata } from 'next'
import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import CartSidebar from '@/components/CartSidebar'
import AuthModal from '@/components/AuthModal'
import Toast from '@/components/Toast'

export const metadata: Metadata = {
  title: 'Godavari Ghaatu - Authentic Indian Pickles & Traditional Foods',
  description: 'Shop for authentic Indian pickles, spices, laddus, and traditional food products.',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className="min-h-screen flex flex-col">
        <Navbar />
        <main className="flex-1">{children}</main>
        <Footer />
        <CartSidebar />
        <AuthModal />
        <Toast />
      </body>
    </html>
  )
}
