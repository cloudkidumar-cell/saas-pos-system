import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SECRET_KEY!;

const supabase = createClient(supabaseUrl, supabaseKey);

interface SaleItem {
  id: string;
  quantity: number;
  harga: number;
  nama: string;
  products: { nama: string; harga: number } | null;
}

interface Sale {
  id: string;
  total: number;
  created_at: string;
  payment_method: string;
  cash_received: number | null;
  change_amount: number | null;
  sale_items: SaleItem[];
  tenants: {
    nama_kedai: string;
    email: string;
  } | null;
}

export default async function ReceiptPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  const { data: sale, error } = await supabase
    .from('sales')
    .select(
      `
      *,
      sale_items (
        *,
        products (nama, harga)
      ),
      tenants (nama_kedai, email)
    `
    )
    .eq('id', id)
    .single();

  if (error || !sale) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl shadow p-8 text-center max-w-sm w-full">
          <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <span className="text-3xl text-red-500">
              ✗
            </span>
          </div>
          <h2 className="text-lg font-bold text-gray-800 mb-2">
            Resit Tidak Dijumpai
          </h2>
          <p className="text-gray-500 text-sm">
            Resit ini mungkin sudah tamat tempoh
            atau tidak wujud.
          </p>
        </div>
      </div>
    );
  }

  const typedSale = sale as Sale;

  const createdAt = new Date(
    typedSale.created_at
  ).toLocaleString('ms-MY', {
    timeZone: 'Asia/Kuala_Lumpur',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });

  const paymentLabel = (method: string) => {
    switch (method) {
      case 'qr_bank':
        return 'QR Bank';
      case 'tng':
        return 'Touch n Go';
      default:
        return 'Tunai';
    }
  };

  const total = Number(typedSale.total);

  return (
    <div className="min-h-screen bg-gray-100 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-lg w-full max-w-sm overflow-hidden">

        {/* Header Green */}
        <div className="bg-green-500 p-6 text-center">
          <div className="w-14 h-14 bg-white rounded-full flex items-center justify-center mx-auto mb-3">
            <span className="text-green-500 text-2xl font-bold">
              ✓
            </span>
          </div>
          <h1 className="text-white text-xl font-bold">
            {typedSale.tenants?.nama_kedai || 'Kedai'}
          </h1>
          <p className="text-green-100 text-sm mt-1">
            Pembayaran Berjaya
          </p>
        </div>

        <div className="p-6">
          {/* Date */}
          <p className="text-center text-gray-400 text-xs mb-6">
            {createdAt}
          </p>

          {/* Items */}
          <div className="mb-4">
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3">
              Item Dibeli
            </p>
            <div className="space-y-2">
              {typedSale.sale_items.map((item) => {
                const nama =
                  item.products?.nama ||
                  item.nama ||
                  '-';
                const subtotal =
                  item.quantity * item.harga;
                return (
                  <div
                    key={item.id}
                    className="flex justify-between items-center"
                  >
                    <div className="flex items-center gap-2">
                      <div className="w-1.5 h-1.5 bg-blue-500 rounded-full" />
                      <span className="text-gray-700 text-sm">
                        {nama}
                        <span className="text-gray-400 ml-1">
                          x{item.quantity}
                        </span>
                      </span>
                    </div>
                    <span className="text-gray-800 text-sm font-medium">
                      RM {subtotal.toFixed(2)}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Divider */}
          <div className="border-t border-dashed border-gray-200 my-4" />

          {/* Payment Summary */}
          <div className="space-y-2">
            <div className="flex justify-between items-center">
              <span className="font-bold text-gray-800 text-base">
                Total
              </span>
              <span className="font-bold text-blue-600 text-xl">
                RM {total.toFixed(2)}
              </span>
            </div>

            <div className="flex justify-between text-sm">
              <span className="text-gray-400">
                Kaedah Bayaran
              </span>
              <span className="text-gray-600 font-medium">
                {paymentLabel(
                  typedSale.payment_method || 'cash'
                )}
              </span>
            </div>

            {typedSale.payment_method === 'cash' &&
              typedSale.cash_received && (
                <>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-400">
                      Diterima
                    </span>
                    <span className="text-gray-600">
                      RM{' '}
                      {Number(
                        typedSale.cash_received
                      ).toFixed(2)}
                    </span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-400">
                      Baki
                    </span>
                    <span className="text-green-600 font-semibold">
                      RM{' '}
                      {Number(
                        typedSale.change_amount
                      ).toFixed(2)}
                    </span>
                  </div>
                </>
              )}
          </div>

          {/* Divider */}
          <div className="border-t border-dashed border-gray-200 my-4" />

          {/* Footer */}
          <div className="text-center">
            <p className="text-sm text-gray-500 font-medium">
              Terima kasih kerana membeli! 🙏
            </p>
            {typedSale.tenants?.email && (
              <p className="text-xs text-gray-400 mt-1">
                {typedSale.tenants.email}
              </p>
            )}
          </div>
        </div>

        {/* Bottom bar */}
        <div className="bg-gray-50 px-6 py-3 text-center border-t">
          <p className="text-xs text-gray-400">
            Dijana oleh POS System
          </p>
        </div>

      </div>
    </div>
  );
}