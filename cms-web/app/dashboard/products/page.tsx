'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';

interface Product {
  id: string;
  nama: string;
  harga: number;
  barcode: string;
  stok: number;
  tenant_id: string;
}

interface Tenant {
  id: string;
  nama_kedai: string;
}

export default function ProductsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [tenants, setTenants] = useState<Tenant[]>([]);
  const [selectedTenant, setSelectedTenant] = useState('');
  const [loading, setLoading] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [editProduct, setEditProduct] = useState<Product | null>(null);
  const [form, setForm] = useState({
    nama: '',
    harga: '',
    barcode: '',
    stok: '',
    tenant_id: ''
  });

  // Load tenants
  useEffect(() => {
    loadTenants();
  }, []);

  // Load products bila tenant berubah
  useEffect(() => {
    if (selectedTenant) loadProducts();
  }, [selectedTenant]);

  const loadTenants = async () => {
    try {
      const res = await api.get('/admin/tenants?status=approved');
      setTenants(res.data.data);
      if (res.data.data.length > 0) {
        setSelectedTenant(res.data.data[0].id);
      }
    } catch (err) {
      console.error(err);
    }
  };

  const loadProducts = async () => {
    try {
      setLoading(true);
      const res = await api.get('/products', {
        headers: {
          'x-tenant-id': selectedTenant
        }
      });
      setProducts(res.data.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (editProduct) {
        await api.put(`/products/${editProduct.id}`, {
          nama: form.nama,
          harga: parseFloat(form.harga),
          barcode: form.barcode,
          stok: parseInt(form.stok)
        });
      } else {
        await api.post('/products', {
          nama: form.nama,
          harga: parseFloat(form.harga),
          barcode: form.barcode,
          stok: parseInt(form.stok),
          tenant_id: form.tenant_id || selectedTenant
        });
      }
      setShowModal(false);
      resetForm();
      loadProducts();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Error');
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Padam produk ini?')) return;
    try {
      await api.delete(`/products/${id}`);
      loadProducts();
    } catch (err) {
      console.error(err);
    }
  };

  const handleEdit = (product: Product) => {
    setEditProduct(product);
    setForm({
      nama: product.nama,
      harga: product.harga.toString(),
      barcode: product.barcode || '',
      stok: product.stok.toString(),
      tenant_id: product.tenant_id
    });
    setShowModal(true);
  };

  const resetForm = () => {
    setForm({ nama: '', harga: '', barcode: '', stok: '', tenant_id: '' });
    setEditProduct(null);
  };

  return (
    <div>
      {/* Header */}
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-xl font-bold">Produk</h2>
        <button
          onClick={() => { resetForm(); setShowModal(true); }}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700"
        >
          + Tambah Produk
        </button>
      </div>

      {/* Tenant Filter */}
      <div className="bg-white rounded-lg p-4 mb-4 shadow-sm">
        <label className="text-sm font-medium mr-3">Pilih Kedai:</label>
        <select
          value={selectedTenant}
          onChange={(e) => setSelectedTenant(e.target.value)}
          className="border rounded-lg px-3 py-1.5 text-sm"
        >
          {tenants.map((t) => (
            <option key={t.id} value={t.id}>
              {t.nama_kedai}
            </option>
          ))}
        </select>
      </div>

      {/* Products Table */}
      <div className="bg-white rounded-lg shadow-sm overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-gray-500">Loading...</div>
        ) : products.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            Tiada produk. Tambah produk baru.
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-left px-4 py-3 font-medium">Nama</th>
                <th className="text-left px-4 py-3 font-medium">Harga</th>
                <th className="text-left px-4 py-3 font-medium">Barcode</th>
                <th className="text-left px-4 py-3 font-medium">Stok</th>
                <th className="text-left px-4 py-3 font-medium">Tindakan</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {products.map((product) => (
                <tr key={product.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3">{product.nama}</td>
                  <td className="px-4 py-3">RM {product.harga.toFixed(2)}</td>
                  <td className="px-4 py-3">
                    {product.barcode || (
                      <span className="text-gray-400">Tiada</span>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    <span className={`font-medium ${
                      product.stok === 0
                        ? 'text-red-600'
                        : product.stok < 10
                        ? 'text-yellow-600'
                        : 'text-green-600'
                    }`}>
                      {product.stok}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <button
                      onClick={() => handleEdit(product)}
                      className="text-blue-600 hover:underline mr-3"
                    >
                      Edit
                    </button>
                    <button
                      onClick={() => handleDelete(product.id)}
                      className="text-red-600 hover:underline"
                    >
                      Padam
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Modal Add/Edit */}
      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <h3 className="font-bold text-lg mb-4">
              {editProduct ? 'Edit Produk' : 'Tambah Produk'}
            </h3>

            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-1">
                  Nama Produk
                </label>
                <input
                  type="text"
                  value={form.nama}
                  onChange={(e) => setForm({ ...form, nama: e.target.value })}
                  className="w-full border rounded-lg px-3 py-2 text-sm"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">
                  Harga (RM)
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={form.harga}
                  onChange={(e) => setForm({ ...form, harga: e.target.value })}
                  className="w-full border rounded-lg px-3 py-2 text-sm"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">
                  Barcode
                </label>
                <input
                  type="text"
                  value={form.barcode}
                  onChange={(e) => setForm({ ...form, barcode: e.target.value })}
                  className="w-full border rounded-lg px-3 py-2 text-sm"
                  placeholder="Optional"
                />
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">
                  Stok
                </label>
                <input
                  type="number"
                  value={form.stok}
                  onChange={(e) => setForm({ ...form, stok: e.target.value })}
                  className="w-full border rounded-lg px-3 py-2 text-sm"
                  required
                />
              </div>

              {/* Tenant select — untuk add je */}
              {!editProduct && (
                <div>
                  <label className="block text-sm font-medium mb-1">
                    Kedai
                  </label>
                  <select
                    value={form.tenant_id || selectedTenant}
                    onChange={(e) => setForm({ ...form, tenant_id: e.target.value })}
                    className="w-full border rounded-lg px-3 py-2 text-sm"
                  >
                    {tenants.map((t) => (
                      <option key={t.id} value={t.id}>
                        {t.nama_kedai}
                      </option>
                    ))}
                  </select>
                </div>
              )}

              <div className="flex gap-3 pt-2">
                <button
                  type="submit"
                  className="flex-1 bg-blue-600 text-white py-2 rounded-lg text-sm hover:bg-blue-700"
                >
                  {editProduct ? 'Kemaskini' : 'Tambah'}
                </button>
                <button
                  type="button"
                  onClick={() => { setShowModal(false); resetForm(); }}
                  className="flex-1 border py-2 rounded-lg text-sm hover:bg-gray-50"
                >
                  Batal
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}