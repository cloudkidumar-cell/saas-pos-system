'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Cookies from 'js-cookie';

export default function DashboardLayout({
  children
}: {
  children: React.ReactNode
}) {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);

  useEffect(() => {
    const token = Cookies.get('token');
    const userData = Cookies.get('user');

    if (!token || !userData) {
      router.push('/');
      return;
    }

    setUser(JSON.parse(userData));
  }, []);

  const handleLogout = () => {
    Cookies.remove('token');
    Cookies.remove('user');
    router.push('/');
  };

  return (
    <div className="min-h-screen bg-gray-100">

      {/* Navbar */}
      <nav className="bg-white shadow-sm px-6 py-4 flex justify-between items-center">
        <h1 className="font-bold text-lg">POS Admin Panel</h1>
        <div className="flex items-center gap-4">
          <span className="text-sm text-gray-600">{user?.email}</span>
          <button
            onClick={handleLogout}
            className="text-sm text-red-600 hover:underline"
          >
            Log Keluar
          </button>
        </div>
      </nav>

      {/* Sidebar + Content */}
      <div className="flex">

        {/* Sidebar */}
        <aside className="w-56 bg-white min-h-screen shadow-sm p-4">
          <nav className="space-y-1">
            <Link
              href="/dashboard"
              className="block px-3 py-2 rounded-lg text-sm hover:bg-gray-100"
            >
              Dashboard
            </Link>
            <Link
              href="/dashboard/tenants"
              className="block px-3 py-2 rounded-lg text-sm hover:bg-gray-100"
            >
              Tenant
            </Link>
            <Link
              href="/dashboard/products"
              className="block px-3 py-2 rounded-lg text-sm hover:bg-gray-100"
            >
              Produk


            <Link
              href="/dashboard/sales"
               className="block px-3 py-2 rounded-lg text-sm hover:bg-gray-100"
            >
  Sales Report
</Link>
            </Link>
          </nav>
        </aside>

        {/* Main Content */}
        <main className="flex-1 p-6">
          {children}
        </main>

      </div>
    </div>
  );
}