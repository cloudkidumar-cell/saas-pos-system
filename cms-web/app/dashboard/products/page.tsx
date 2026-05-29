'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';

interface Product {
  id: string;
  nama: string;
  harga: number;
  stok: number;
  barcode: string;
  library_id: string | null;
}

interface Tenant {
  id: string;
  nama_kedai: string;
  status: string;
}

interface LibraryProduct {
  id: string;
  barcode: string;
  nama: string;
  brand: string;
  kategori: string;
  unit: string;
}

export default function ProductsPage() {
  const [tenants, setTenants] = useState(
    [] as Tenant[]
  );
  const [selectedTenant, setSelectedTenant] =
    useState('');
  const [products, setProducts] = useState(
    [] as Product[]
  );
  const [loading, setLoading] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [editProduct, setEditProduct] = useState(
    null as Product | null
  );
  const [addMode, setAddMode] = useState(
    'library' as 'library' | 'manual'
  );

  // Library search
  const [librarySearch, setLibrarySearch] =
    useState('');
  const [libraryResults, setLibraryResults] = useState(
    [] as LibraryProduct[]
  );
  const [selectedLibrary, setSelectedLibrary] =
    useState(null as LibraryProduct | null);
  const [librarySearching, setLibrarySearching] =
    useState(false);

  // Form
  const [form, setForm] = useState({
    nama: '',
    harga: '',
    stok: '',
    barcode: ''
  });

  useEffect(() => {
    loadTenants();
  }, []);

  useEffect(() => {
    if (selectedTenant) loadProducts();
  }, [selectedTenant]);

  useEffect(() => {
    const timer = setTimeout(() => {
      if (librarySearch.length >= 2) {
        searchLibrary(librarySearch);
      } else {
        setLibraryResults([]);
      }
    }, 400);
    return () => clearTimeout(timer);
  }, [librarySearch]);

  const loadTenants = async () => {
    try {
      const res = await api.get('/admin/tenants');
      const approved = res.data.data.filter(
        (t: Tenant) => t.status === 'approved'
      );
      setTenants(approved);
      if (approved.length > 0) {
        setSelectedTenant(approved[0].id);
      }
    } catch (err) {
      console.error(err);
    }
  };

  const loadProducts = async () => {
    if (!selectedTenant) return;
    try {
      setLoading(true);
      const res = await api.get('/products', {
        params: { tenant_id: selectedTenant }
      });
      setProducts(res.data.data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const searchLibrary = async (q: string) => {
    try {
      setLibrarySearching(true);
      const res = await api.get('/library', {
        params: { search: q }
      });
      setLibraryResults(res.data.data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLibrarySearching(false);
    }
  };

  const handleAddFromLibrary = async (
    e: React.FormEvent
  ) => {
    e.preventDefault();
    if (!selectedLibrary || !selectedTenant) return;
    try {
      await api.post('/library/add-to-tenant', {
        library_id: selectedLibrary.id,
        tenant_id: selectedTenant,
        harga: parseFloat(form.harga),
        stok: parseInt(form.stok) || 0
      });
      setShowModal(false);
      resetForm();
      loadProducts();
    } catch (err: any) {
      alert(
        err.response?.data?.message ||
          'Error menambah produk'
      );
    }
  };

  const handleAddManual = async (
    e: React.FormEvent
  ) => {
    e.preventDefault();
    if (!selectedTenant) return;
    try {
      if (editProduct) {
        await api.put(`/products/${editProduct.id}`, {
          nama: form.nama,
          harga: parseFloat(form.harga),
          stok: parseInt(form.stok),
          barcode: form.barcode
        });
      } else {
        await api.post('/products', {
          tenant_id: selectedTenant,
          nama: form.nama,
          harga: parseFloat(form.harga),
          stok: parseInt(form.stok) || 0,
          barcode: form.barcode
        });
      }
      setShowModal(false);
      resetForm();
      loadProducts();
    } catch (err: any) {
      alert(
        err.response?.data?.message || 'Error'
      );
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

  const handleEdit = (p: Product) => {
    setEditProduct(p);
    setAddMode('manual');
    setForm({
      nama: p.nama,
      harga: String(p.harga),
      stok: String(p.stok),
      barcode: p.barcode || ''
    });
    setShowModal(true);
  };

  const resetForm = () => {
    setForm({
      nama: '',
      harga: '',
      stok: '',
      barcode: ''
    });
    setEditProduct(null);
    setSelectedLibrary(null);
    setLibrarySearch('');
    setLibraryResults([]);
    setAddMode('library');
  };

  return (
    <div>
      {/* Header */}
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-xl font-bold">
          Produk Kedai
        </h2>
        <button
          onClick={() => {
            resetForm();
            setShowModal(true);
          }}
          disabled={!selectedTenant}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700 disabled:opacity-40"
        >
          + Tambah Produk
        </button>
      </div>

      {/* Tenant Selector */}
      <div className="bg-white rounded-lg p-4 mb-4 shadow-sm">
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Pilih Kedai
        </label>
        <select
          value={selectedTenant}
          onChange={(e) =>
            setSelectedTenant(e.target.value)
          }
          className="w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
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
          <div className="p-8 text-center text-gray-500">
            Loading...
          </div>
        ) : products.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            <p className="font-medium">
              Tiada produk
            </p>
            <p className="text-sm mt-1">
              Tambah produk dari library atau manual
            </p>
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-left px-4 py-3 font-medium text-gray-600">
                  Nama
                </th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">
                  Barcode
                </th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">
                  Harga
                </th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">
                  Stok
                </th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">
                  Sumber
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
                  <td className="px-4 py-3 font-medium text-gray-800">
                    {product.nama}
                  </td>
                  <td className="px-4 py-3 font-mono text-xs text-gray-500">
                    {product.barcode || (
                      <span className="text-gray-300">
                        —
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-gray-700">
                    RM{' '}
                    {Number(product.harga).toFixed(2)}
                  </td>
                  <td className="px-4 py-3">
                    <span
                      className={`font-medium ${
                        product.stok <= 5
                          ? 'text-red-600'
                          : 'text-gray-700'
                      }`}
                    >
                      {product.stok}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    {product.library_id ? (
                      <span className="bg-blue-50 text-blue-700 px-2 py-0.5 rounded text-xs font-medium">
                        Library
                      </span>
                    ) : (
                      <span className="bg-gray-100 text-gray-600 px-2 py-0.5 rounded text-xs">
                        Manual
                      </span>
                    )}
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
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl w-full max-w-md max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <h3 className="font-bold text-lg mb-4">
                {editProduct
                  ? 'Edit Produk'
                  : 'Tambah Produk'}
              </h3>

              {/* Toggle — hide when editing */}
              {!editProduct && (
                <div className="flex bg-gray-100 rounded-lg p-1 mb-5">
                  <button
                    onClick={() => {
                      setAddMode('library');
                      setSelectedLibrary(null);
                      setLibrarySearch('');
                      setLibraryResults([]);
                    }}
                    className={`flex-1 py-2 rounded-md text-sm font-medium transition-all ${
                      addMode === 'library'
                        ? 'bg-white shadow text-blue-600'
                        : 'text-gray-500'
                    }`}
                  >
                    Dari Library
                  </button>
                  <button
                    onClick={() =>
                      setAddMode('manual')
                    }
                    className={`flex-1 py-2 rounded-md text-sm font-medium transition-all ${
                      addMode === 'manual'
                        ? 'bg-white shadow text-blue-600'
                        : 'text-gray-500'
                    }`}
                  >
                    Manual
                  </button>
                </div>
              )}

              {/* LIBRARY MODE */}
              {addMode === 'library' &&
                !editProduct && (
                  <form
                    onSubmit={handleAddFromLibrary}
                    className="space-y-4"
                  >
                    {!selectedLibrary ? (
                      <div>
                        <label className="block text-sm font-medium mb-1">
                          Cari dari Library
                        </label>
                        <input
                          type="text"
                          value={librarySearch}
                          onChange={(e) =>
                            setLibrarySearch(
                              e.target.value
                            )
                          }
                          className="w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                          placeholder="Taip nama, barcode atau brand..."
                          autoFocus
                        />

                        {librarySearching && (
                          <p className="text-xs text-gray-400 mt-2">
                            Mencari...
                          </p>
                        )}

                        {!librarySearching &&
                          libraryResults.length >
                            0 && (
                            <div className="mt-2 border rounded-lg divide-y max-h-56 overflow-y-auto">
                              {libraryResults.map(
                                (item) => (
                                  <button
                                    key={item.id}
                                    type="button"
                                    onClick={() => {
                                      setSelectedLibrary(
                                        item
                                      );
                                      setLibraryResults(
                                        []
                                      );
                                    }}
                                    className="w-full text-left px-3 py-2.5 hover:bg-blue-50 transition-colors"
                                  >
                                    <p className="font-medium text-sm text-gray-800">
                                      {item.nama}
                                    </p>
                                    <div className="flex gap-2 mt-0.5 flex-wrap">
                                      {item.brand && (
                                        <span className="text-xs text-gray-500">
                                          {item.brand}
                                        </span>
                                      )}
                                      {item.barcode && (
                                        <span className="text-xs text-gray-400 font-mono">
                                          {
                                            item.barcode
                                          }
                                        </span>
                                      )}
                                      {item.kategori && (
                                        <span className="text-xs bg-blue-50 text-blue-600 px-1.5 rounded">
                                          {
                                            item.kategori
                                          }
                                        </span>
                                      )}
                                    </div>
                                  </button>
                                )
                              )}
                            </div>
                          )}

                        {!librarySearching &&
                          librarySearch.length >=
                            2 &&
                          libraryResults.length ===
                            0 && (
                            <p className="text-xs text-gray-400 mt-2">
                              Tiada produk dijumpai
                            </p>
                          )}
                      </div>
                    ) : (
                      <div>
                        <label className="block text-sm font-medium mb-1">
                          Produk Dipilih
                        </label>
                        <div className="border rounded-lg p-3 bg-blue-50 flex justify-between items-start">
                          <div>
                            <p className="font-medium text-sm text-gray-800">
                              {selectedLibrary.nama}
                            </p>
                            <div className="flex gap-2 mt-1 flex-wrap">
                              {selectedLibrary.brand && (
                                <span className="text-xs text-gray-500">
                                  {
                                    selectedLibrary.brand
                                  }
                                </span>
                              )}
                              {selectedLibrary.barcode && (
                                <span className="text-xs text-gray-400 font-mono">
                                  {
                                    selectedLibrary.barcode
                                  }
                                </span>
                              )}
                              {selectedLibrary.kategori && (
                                <span className="text-xs bg-blue-100 text-blue-600 px-1.5 rounded">
                                  {
                                    selectedLibrary.kategori
                                  }
                                </span>
                              )}
                            </div>
                          </div>
                          <button
                            type="button"
                            onClick={() => {
                              setSelectedLibrary(null);
                              setLibrarySearch('');
                            }}
                            className="text-gray-400 hover:text-red-500 text-xs ml-2"
                          >
                            ✕ Tukar
                          </button>
                        </div>
                      </div>
                    )}

                    <div>
                      <label className="block text-sm font-medium mb-1">
                        Harga (RM){' '}
                        <span className="text-red-500">
                          *
                        </span>
                      </label>
                      <input
                        type="number"
                        step="0.01"
                        min="0"
                        value={form.harga}
                        onChange={(e) =>
                          setForm({
                            ...form,
                            harga: e.target.value
                          })
                        }
                        className="w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                        placeholder="0.00"
                        required
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium mb-1">
                        Stok Awal
                      </label>
                      <input
                        type="number"
                        min="0"
                        value={form.stok}
                        onChange={(e) =>
                          setForm({
                            ...form,
                            stok: e.target.value
                          })
                        }
                        className="w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                        placeholder="0"
                      />
                    </div>

                    <div className="flex gap-3 pt-2">
                      <button
                        type="submit"
                        disabled={!selectedLibrary}
                        className="flex-1 bg-blue-600 text-white py-2 rounded-lg text-sm hover:bg-blue-700 font-medium disabled:opacity-40"
                      >
                        Tambah ke Kedai
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
                )}

              {/* MANUAL MODE */}
              {(addMode === 'manual' ||
                editProduct) && (
                <form
                  onSubmit={handleAddManual}
                  className="space-y-4"
                >
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
                      placeholder="Nama produk"
                      required
                    />
                  </div>

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
                      placeholder="Barcode produk"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-1">
                      Harga (RM){' '}
                      <span className="text-red-500">
                        *
                      </span>
                    </label>
                    <input
                      type="number"
                      step="0.01"
                      min="0"
                      value={form.harga}
                      onChange={(e) =>
                        setForm({
                          ...form,
                          harga: e.target.value
                        })
                      }
                      className="w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="0.00"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-1">
                      Stok
                    </label>
                    <input
                      type="number"
                      min="0"
                      value={form.stok}
                      onChange={(e) =>
                        setForm({
                          ...form,
                          stok: e.target.value
                        })
                      }
                      className="w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="0"
                    />
                  </div>

                  <div className="flex gap-3 pt-2">
                    <button
                      type="submit"
                      className="flex-1 bg-blue-600 text-white py-2 rounded-lg text-sm hover:bg-blue-700 font-medium"
                    >
                      {editProduct
                        ? 'Kemaskini'
                        : 'Tambah Produk'}
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
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}