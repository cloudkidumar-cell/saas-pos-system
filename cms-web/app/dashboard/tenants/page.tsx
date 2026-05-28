'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';

interface Tenant {
  id: string;
  nama_kedai: string;
  email: string;
  status: string;
  subscription_status: string;
  created_at: string;
}

export default function TenantsPage() {
  const [tenants, setTenants] = useState<Tenant[]>([]);
  const [loading, setLoading] = useState(false);
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');

  useEffect(() => {
    loadTenants();
  }, []);

  const loadTenants = async () => {
    try {
      setLoading(true);
      const res = await api.get('/admin/tenants');
      setTenants(res.data.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (id: string) => {
    try {
      await api.put(`/admin/tenants/${id}/approve`);
      loadTenants();
    } catch (err) {
      console.error(err);
    }
  };

  const handleReject = async (id: string) => {
    if (!confirm('Tolak tenant ini?')) return;
    try {
      await api.put(`/admin/tenants/${id}/reject`);
      loadTenants();
    } catch (err) {
      console.error(err);
    }
  };

  const handleSuspend = async (id: string) => {
    if (!confirm('Gantung tenant ini?')) return;
    try {
      await api.put(`/admin/tenants/${id}/suspend`);
      loadTenants();
    } catch (err) {
      console.error(err);
    }
  };

  const filtered = tenants.filter((t) => {
    const matchFilter =
      filter === 'all' || t.status === filter;
    const matchSearch =
      t.nama_kedai
        .toLowerCase()
        .includes(search.toLowerCase()) ||
      t.email.toLowerCase().includes(search.toLowerCase());
    return matchFilter && matchSearch;
  });

  const statusBadge = (status: string) => {
    const map: Record
      string,
      { label: string; cls: string }
    > = {
      pending: {
        label: 'Pending',
        cls: 'bg-yellow-100 text-yellow-700',
      },
      approved: {
        label: 'Aktif',
        cls: 'bg-green-100 text-green-700',
      },
      rejected: {
        label: 'Ditolak',
        cls: 'bg-red-100 text-red-700',
      },
      suspended: {
        label: 'Digantung',
        cls: 'bg-orange-100 text-orange-700',
      },
    };
    const s = map[status] || {
      label: status,
      cls: 'bg-gray-100 text-gray-700',
    };
    return (
      <span
        className={`px-2 py-1 rounded text-xs font-medium ${s.cls}`}
      >
        {s.label}
      </span>
    );
  };

  const counts = {
    all: tenants.length,
    pending: tenants.filter((t) => t.status === 'pending')
      .length,
    approved: tenants.filter(
      (t) => t.status === 'approved'
    ).length,
    suspended: tenants.filter(
      (t) => t.status === 'suspended'
    ).length,
  };

  return (
    <div>
      {/* Header */}
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-xl font-bold">
          Tenant Management
        </h2>
        <button
          onClick={loadTenants}
          className="text-sm text-blue-600 hover:underline"
        >
          Refresh
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        {[
          {
            label: 'Semua',
            value: counts.all,
            color: 'text-blue-600',
          },
          {
            label: 'Pending',
            value: counts.pending,
            color: 'text-yellow-600',
          },
          {
            label: 'Aktif',
            value: counts.approved,
            color: 'text-green-600',
          },
          {
            label: 'Digantung',
            value: counts.suspended,
            color: 'text-orange-600',
          },
        ].map((stat) => (
          <div
            key={stat.label}
            className="bg-white rounded-lg p-4 shadow-sm"
          >
            <p className="text-sm text-gray-500">
              {stat.label}
            </p>
            <p
              className={`text-2xl font-bold ${stat.color}`}
            >
              {stat.value}
            </p>
          </div>
        ))}
      </div>

      {/* Filter + Search */}
      <div className="bg-white rounded-lg p-4 mb-4 shadow-sm flex gap-4 flex-wrap items-center">
        <div className="flex gap-2">
          {[
            { value: 'all', label: 'Semua' },
            { value: 'pending', label: 'Pending' },
            { value: 'approved', label: 'Aktif' },
            { value: 'suspended', label: 'Digantung' },
          ].map((f) => (
            <button
              key={f.value}
              onClick={() => setFilter(f.value)}
              className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                filter === f.value
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {f.label}
            </button>
          ))}
        </div>

        <input
          type="text"
          placeholder="Cari nama atau email..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="border rounded-lg px-3 py-1.5 text-sm flex-1 min-w-48 focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      {/* Pending alert */}
      {counts.pending > 0 && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3 mb-4 flex items-center gap-2">
          <span className="text-yellow-600 text-sm font-medium">
            ⚠️ {counts.pending} tenant menunggu kelulusan
          </span>
        </div>
      )}

      {/* Table */}
      <div className="bg-white rounded-lg shadow-sm overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-gray-500">
            Loading...
          </div>
        ) : filtered.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            Tiada tenant dijumpai
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-left px-4 py-3 font-medium text-gray-600">
                  Nama Kedai
                </th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">
                  Email
                </th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">
                  Status
                </th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">
                  Tarikh Daftar
                </th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">
                  Tindakan
                </th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {filtered.map((tenant) => (
                <tr
                  key={tenant.id}
                  className="hover:bg-gray-50"
                >
                  <td className="px-4 py-3 font-medium text-gray-800">
                    {tenant.nama_kedai}
                  </td>
                  <td className="px-4 py-3 text-gray-600">
                    {tenant.email}
                  </td>
                  <td className="px-4 py-3">
                    {statusBadge(tenant.status)}
                  </td>
                  <td className="px-4 py-3 text-gray-500">
                    {new Date(
                      tenant.created_at
                    ).toLocaleDateString('ms-MY')}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex gap-3">
                      {tenant.status === 'pending' && (
                        <>
                          <button
                            onClick={() =>
                              handleApprove(tenant.id)
                            }
                            className="text-green-600 hover:underline text-xs font-medium"
                          >
                            ✓ Approve
                          </button>
                          <button
                            onClick={() =>
                              handleReject(tenant.id)
                            }
                            className="text-red-600 hover:underline text-xs font-medium"
                          >
                            ✕ Tolak
                          </button>
                        </>
                      )}
                      {tenant.status === 'approved' && (
                        <button
                          onClick={() =>
                            handleSuspend(tenant.id)
                          }
                          className="text-orange-600 hover:underline text-xs font-medium"
                        >
                          Gantung
                        </button>
                      )}
                      {tenant.status === 'suspended' && (
                        <button
                          onClick={() =>
                            handleApprove(tenant.id)
                          }
                          className="text-green-600 hover:underline text-xs font-medium"
                        >
                          Aktifkan
                        </button>
                      )}
                      {tenant.status === 'rejected' && (
                        <button
                          onClick={() =>
                            handleApprove(tenant.id)
                          }
                          className="text-blue-600 hover:underline text-xs font-medium"
                        >
                          Approve Balik
                        </button>
                      )}
                    </div>
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