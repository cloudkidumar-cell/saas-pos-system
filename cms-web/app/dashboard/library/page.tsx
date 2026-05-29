'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';

interface LibraryProduct {
  id: string;
  barcode: string;
  nama: string;
  brand: string;
  kategori: string;
  unit: string;
  description: string;
}

export default function LibraryPage() {
  const [products, setProducts] = useState(
    [] as LibraryProduct[]
  );
  const [loading, setLoading] = useState(false);
  const [search, setSearch] = useState('');
  const [kategori, setKategori] = useState('');
  const [kategoriList, setKategoriList] = useState(
    [] as string[]
  );
  const [showModal, setShowModal] = useState(false);
  const [editProduct, setEditProduct] = useState(
    null as LibraryProduct | null
  );
  const [form, setForm] = useState({
    barcode: '',
    nama: '',
    brand: '',
    kategori: '',
    unit: 'pcs',
    description: ''
  });

  useEffect(() => {
    loadLibrary();
    loadKategori();
  }, []);

  useEffect(() => {
    const timer = setTimeout(() => {
      loadLibrary();
    }, 400);
    return () => clearTimeout(timer);
  }, [search, kategori]);

  const loadLibrary = async () => {
    try {
      setLoading(true);
      const res = await api.get('/library', {
        params: { search, kategori }
      });
      setProducts(res.data.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const loadKategori = async () => {
    try {
      const res = await api.get(
        '/library/kategori'
      );
      setKategoriList(res.data.data);
    } catch (err) {
      console.error(err);
    }
  };

  const handleSubmit = async (
    e: React.FormEvent
  ) => {
    e.preventDefault();
    try {
      if (editProduct) {
        await api.put(
          `/library/${editProduct.id}`,
          form
        );
      } else {
        await api.post('/library', form);
      }
      setShowModal(false);
      resetForm();
      loadLibrary();
      loadKategori();
    } catch (err: any) {
      alert(
        err.response?.data?.message || 'Error'
      );
    }
  };

  const handleDelete = async (id: string) => {
    if (
      !confirm('Padam produk ini dari library?')
    )
      return;
    try {
      await api.delete(`/library/${id}`);
      loadLibrary();
    } catch (err) {
      console.error(err);
    }
  };

  const handleEdit = (p: LibraryProduct) => {
    setEditProduct(p);
    setForm({
      barcode: p.barcode || '',
      nama: p.nama,
      brand: p.brand || '',
      kategori: p.kategori || '',
      unit: p.unit || 'pcs',
      description: p.description || ''
    });
    setShowModal(true);
  };

  const resetForm = () => {
    setForm({
      barcode: '',
      nama: '',
      brand: '',
      kategori: '',
      unit: 'pcs',
      description: ''
    });
    setEditProduct(null);
  };

  return (
    <div>
      {/* Header */}
      <div className="flex justify-between items-center mb-6">
        <div>
          <h2 className="text-xl font-bold">
            Product Library
          </h2>
          <p className="text-sm text-gray-500 mt-1">
            {products.length} produk dalam library
          </p>
        </div>
        <button
          onClick={() => {
            resetForm();
            setShowModal(true);
          }}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700"
        >
          + Tambah ke Library
        </button>
      </div>

      {/* Search + Filter */}
      <div className="bg-white rounded-lg p-4 mb-4 shadow-sm flex gap-3 flex-wrap">
        <input
          type="text"
          placeholder="Cari nama, barcode, brand..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="border rounded-lg px-3 py-2 text-sm flex-1 min-w-48 focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
        <select
          value={kategori}
          onChange={(e) =>
            setKategori(e.target.value)
          }
          className="border rounded-lg px-3 py-2 text-sm"
        >
          <option value="">Semua Kategori</option>
          {kategoriList.map((k) => (
            <option key={k} value={k}>
              {k}
            </option>
          ))}
        </select>
      </div>

      {/* Table */}
      <div className="bg-white rounded-lg shadow-sm overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-gray-500">
            Loading...
          </div>
        ) : products.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            <p className="font-medium">
              Tiada produk dalam library
            </p>
            <p className="text-sm mt-1">
              Tambah produk pertama ke library
            </p>
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-left px-4 py-3 font-medium text-gray-600">
                  Barcode
                </th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">
                  Nama Produk
                </th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">
                  Brand
                </th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">
                  Kategori
                </th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">
                  Unit
                </th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">
                  Tindakan
                </th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {products.map((product) => (
                <tr
                  key={product.id}
                  className="hover:bg-gray-50"
                >
                  <td className="px-4 py-3 font-mono text-xs text-gray-500">
                    {product.barcode || (
                      <span className="text-gray-300">
                        —
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3 font-medium text-gray-800">
                    {product.nama}
                  </td>
                  <td className="px-4 py-3 text-gray-600">
                    {product.brand || (
                      <span className="text-gray-300">
                        —
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    {product.kategori ? (
                      <span className="bg-blue-50 text-blue-700 px-2 py-0.5 rounded text-xs font-medium">
                        {product.kategori}
                      </span>
                    ) : (
                      <span className="text-gray-300">
                        —
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-gray-600">
                    {product.unit}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex gap-3">
                      <button
                        onClick={() =>
                          handleEdit(product)
                        }
                        className="text-blue-600 hover:underline text-xs font-medium"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() =>
                          handleDelete(product.id)
                        }
                        className="text-red-600 hover:underline text-xs font-medium"
                      >
                        Padam
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md max-h-screen overflow-y-auto">
            <h3 className="font-bold text-lg mb-4">
              {editProduct
                ? 'Edit Produk Library'
                : 'Tambah ke Library'}
            </h3>

            <form
              onSubmit={handleSubmit}
              className="space-y-4"
            >
              <div>
                <label className="block text-sm font-medium mb-1">
                  Barcode
                  <span className="text-gray-400 font-normal ml-1">
                    (Optional)
                  </span>
                </label>
                <input
                  type="text"
                  value={form.barcode}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      barcode: e.target.value
                    })
                  }
                  className="w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="9556789012345"
                />
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">
                  Nama Produk{' '}
                  <span className="text-red-500">
                    *
                  </span>
                </label>
                <input
                  type="text"
                  value={form.nama}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      nama: e.target.value
                    })
                  }
                  className="w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Milo Tin 400g"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">
                  Brand
                  <span className="text-gray-400 font-normal ml-1">
                    (Optional)
                  </span>
                </label>
                <input
                  type="text"
                  value={form.brand}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      brand: e.target.value
                    })
                  }
                  className="w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Nestle"
                />
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">
                  Kategori
                  <span className="text-gray-400 font-normal ml-1">
                    (Optional)
                  </span>
                </label>
                <input
                  type="text"
                  value={form.kategori}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      kategori: e.target.value
                    })
                  }
                  className="w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Minuman, Makanan, Stationery"
                  list="kategori-list"
                />
                <datalist id="kategori-list">
                  {kategoriList.map((k) => (
                    <option key={k} value={k} />
                  ))}
                </datalist>
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">
                  Unit
                </label>
                <select
                  value={form.unit}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      unit: e.target.value
                    })
                  }
                  className="w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="pcs">pcs</option>
                  <option value="kg">kg</option>
                  <option value="g">g</option>
                  <option value="liter">liter</option>
                  <option value="ml">ml</option>
                  <option value="botol">botol</option>
                  <option value="kotak">kotak</option>
                  <option value="tin">tin</option>
                  <option value="pek">pek</option>
                  <option value="biji">biji</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">
                  Deskripsi
                  <span className="text-gray-400 font-normal ml-1">
                    (Optional)
                  </span>
                </label>
                <textarea
                  value={form.description}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      description: e.target.value
                    })
                  }
                  className="w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Deskripsi produk..."
                  rows={3}
                />
              </div>

              <div className="flex gap-3 pt-2">
                <button
                  type="submit"
                  className="flex-1 bg-blue-600 text-white py-2 rounded-lg text-sm hover:bg-blue-700 font-medium"
                >
                  {editProduct
                    ? 'Kemaskini'
                    : 'Tambah ke Library'}
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setShowModal(false);
                    resetForm();
                  }}
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