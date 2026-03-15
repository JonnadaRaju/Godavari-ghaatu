'use client'

import { useEffect, useState } from 'react'
import { adminApi } from '@/lib/api'
import { useUIStore } from '@/lib/store'

interface Order {
  id: string
  status: string
  total_amount: number
  created_at: string
  user?: { full_name: string; email: string }
  shipping_address?: {
    full_name: string
    address: string
    city: string
    state: string
    pincode: string
  }
}

const statusOptions = ['PENDING', 'PACKED', 'SHIPPED', 'DELIVERED', 'CANCELLED']

export default function AdminOrdersPage() {
  const [orders, setOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null)
  const showToast = useUIStore((state) => state.showToast)

  useEffect(() => {
    fetchOrders()
  }, [])

  const fetchOrders = async () => {
    try {
      const data = await adminApi.getOrders()
      setOrders(Array.isArray(data) ? data : [])
    } catch (error: any) {
      console.error('Failed to fetch orders:', error)
      showToast(error?.response?.data?.detail || 'Failed to load orders', 'error')
    } finally {
      setLoading(false)
    }
  }

  const handleStatusChange = async (orderId: string, newStatus: string) => {
    try {
      await adminApi.updateOrderStatus(orderId, newStatus)
      showToast('Order status updated', 'success')
      fetchOrders()
      setSelectedOrder(null)
    } catch (error: any) {
      showToast(error?.response?.data?.detail || 'Failed to update status', 'error')
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'PENDING': return 'bg-yellow-100 text-yellow-800'
      case 'PACKED': return 'bg-blue-100 text-blue-800'
      case 'SHIPPED': return 'bg-purple-100 text-purple-800'
      case 'DELIVERED': return 'bg-green-100 text-green-800'
      case 'CANCELLED': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-saffron-500"></div>
      </div>
    )
  }

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Orders</h1>

      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Order ID</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Customer</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Total</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {orders.map((order) => (
              <tr key={order.id}>
                <td className="px-6 py-4 whitespace-nowrap text-sm">{order.id.slice(0, 8)}...</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">
                  {order.user?.full_name || 'Unknown'}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">₹{Number(order.total_amount).toFixed(2)}</td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={`px-2 py-1 text-xs rounded-full ${getStatusColor(order.status)}`}>
                    {order.status}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">
                  {new Date(order.created_at).toLocaleDateString()}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <button
                    onClick={() => setSelectedOrder(order)}
                    className="text-saffron-600 hover:text-saffron-800"
                  >
                    View
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {orders.length === 0 && (
          <div className="text-center py-8 text-gray-500">No orders found</div>
        )}
      </div>

      {selectedOrder && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg w-full max-w-lg">
            <h2 className="text-xl font-bold mb-4">Order Details</h2>
            
            <div className="space-y-3 mb-6">
              <p><span className="font-medium">Order ID:</span> {selectedOrder.id}</p>
              <p><span className="font-medium">Customer:</span> {selectedOrder.user?.full_name || 'Unknown'}</p>
              <p><span className="font-medium">Email:</span> {selectedOrder.user?.email || 'N/A'}</p>
              <p><span className="font-medium">Total:</span> ₹{Number(selectedOrder.total_amount).toFixed(2)}</p>
              <p><span className="font-medium">Date:</span> {new Date(selectedOrder.created_at).toLocaleString()}</p>
              
              {selectedOrder.shipping_address && (
                <div className="border-t pt-3 mt-3">
                  <p className="font-medium">Shipping Address:</p>
                  <p className="text-gray-600">
                    {selectedOrder.shipping_address.full_name}<br />
                    {selectedOrder.shipping_address.address}<br />
                    {selectedOrder.shipping_address.city}, {selectedOrder.shipping_address.state} - {selectedOrder.shipping_address.pincode}
                  </p>
                </div>
              )}
            </div>

            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 mb-2">Update Status</label>
              <select
                value={selectedOrder.status}
                onChange={(e) => handleStatusChange(selectedOrder.id, e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg"
              >
                {statusOptions.map((status) => (
                  <option key={status} value={status}>{status}</option>
                ))}
              </select>
            </div>

            <button
              onClick={() => setSelectedOrder(null)}
              className="w-full px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400"
            >
              Close
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
