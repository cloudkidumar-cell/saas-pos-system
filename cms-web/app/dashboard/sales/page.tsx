'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';

interface SaleItem {
  id: string;
  quantity: number;
  harga: number;
  nama: string;
  products: { nama: string };
}

interface Sale {
  id: string;
  total: number;
  created_at: string;
  payment_method: string;
  users: { email: string };
  sale_items: SaleItem[];
}

interface Tenant {
  id: string;
  nama_kedai: string;
}

export default function SalesPage() {
  const [sales, setSales] = useState<Sale[]>([]);
  const [tenants, setTenants] = useState<Tenant[]>([]);
  const [selectedTenant, setSelectedTenant] = useState('');
  const [selectedDate, setSelectedDate] = useState(
    new Date()
      .toLocaleDateString('en-CA', {
        timeZone: 'Asia/Kuala_Lumpur',
      })
  );
  const [loading, setLoading] = useState(false);
  const [summary, setSummary] = useState({
    totalSales: 0,
    totalRevenue: 0,
  });

  useEffect(() => {
    loadTenants();
  }, []);

  useEffect(() => {
    if (selectedTenant) loadSales();
  }, [selectedTenant, selectedDate]);

  const loadTenants = async () => {
    try {
      const res = await api.get(
        '/admin/tenants?status=approved'
      );
      setTenants(res.data.data);
      if (res.data.data.length > 0) {
        setSelectedTenant(res.data.data[0].id);
      }
    } catch (err) {
      console.error(err);
    }
  };

  const loadSales = async () => {
    try {
      setLoading(true);
      const res = await api.get('/sales', {
        params: {
          tenant_id: selectedTenant,
          date: selectedDate,
        },
      });

      const salesData = res.data.data;
      setSales(salesData);

      const totalRevenue = salesData.reduce(
        (sum: number, sale: Sale) => sum + sale.total,
        0
      );
      setSummary({
        totalSales: salesData.length,
        totalRevenue,
      });
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const formatTime = (dateStr: string) => {
    return new Date(dateStr).toLocaleTimeString('ms-MY', {
      hour: '2-digit',
      minute: '2-digit',
      timeZone: 'Asia/Kuala_Lumpur',
    });
  };

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString('ms-MY', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      timeZone: 'Asia/Kuala_Lumpur',
    });
  };

  const paymentLabel = (method: string) => {
    switch (method) {
      case 'qr_bank': return 'QR Bank';
      case 'tng': return 'TnG';
      default: return 'Tunai';
    }
  };

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-xl font-bold">Sales Report</h2>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg p-4 mb-4 shadow-sm flex gap-4 items-center flex-wrap">
        <div>
          <label className="text-sm font-medium mr-2">
            Kedai:
          </label>
          <select
            value={selectedTenant}
            onChange={(e) =>
              setSelectedTenant(e.target.value)
            }
            className="border rounded-lg px-3 py-1.5 text-sm"
          >
            {tenants.map((t) => (
              <option key={t.id} value={t.id}>
                {t.nama_kedai}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="text-sm font-medium mr-2">
            Tarikh:
          </label>
          <input
            type="date"
            value={selectedDate}
            onChange={(e) =>
              setSelectedDate(e.target.value)
            }
            className="border rounded-lg px-3 py-1.5 text-sm"
          />
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 gap-4 mb-4">
        <div className="bg-white rounded-lg p-4 shadow-sm">
          <p className="text-sm text-gray-500">
            Jumlah Transaksi
          </p>
          <p className="text-2xl font-bold text-blue-600">
            {summary.totalSales}
          </p>
        </div>
        <div className="bg-white rounded-lg p-4 shadow-sm">
          <p className="text-sm text-gray-500">
            Jumlah Pendapatan
          </p>
          <p className="text-2xl font-bold text-green-600">
            RM {summary.totalRevenue.toFixed(2)}
          </p>
        </div>
      </div>

      {/* Sales Table */}
      <div className="bg-white rounded-lg shadow-sm overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-gray-500">
            Loading...
          </div>
        ) : sales.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            Tiada sales pada tarikh ini
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-left px-4 py-3 font-medium">
                  Masa
                </th>
                <th className="text-left px-4 py-3 font-medium">
                  Cashier
                </th>
                <th className="text-left px-4 py-3 font-medium">
                  Items
                </th>
                <th className="text-left px-4 py-3 font-medium">
                  Kaedah
                </th>
                <th className="text-left px-4 py-3 font-medium">
                  Total
                </th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {sales.map((sale) => (
                <tr
                  key={sale.id}
                  className="hover:bg-gray-50"
                >
                  <td className="px-4 py-3">
                    <div className="font-medium">
                      {formatTime(sale.created_at)}
                    </div>
                    <div className="text-xs text-gray-400">
                      {formatDate(sale.created_at)}
                    </div>
                  </td>
                  <td className="px-4 py-3 text-gray-600">
                    {sale.users?.email || '-'}
                  </td>
                  <td className="px-4 py-3">
                    <div className="space-y-1">
                      {sale.sale_items.map((item) => (
                        <div
                          key={item.id}
                          className="text-xs"
                        >
                          {item.products?.nama ||
                            item.nama}{' '}
                          x{item.quantity}
                        </div>
                      ))}
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <span className="px-2 py-1 rounded text-xs bg-blue-50 text-blue-600">
                      {paymentLabel(
                        sale.payment_method
                      )}
                    </span>
                  </td>
                  <td className="px-4 py-3 font-medium text-green-600">
                    RM {sale.total.toFixed(2)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}