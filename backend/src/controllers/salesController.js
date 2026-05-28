const supabase = require('../config/supabase');

// ================================
// CREATE SALE — checkout
// ================================
const createSale = async (req, res) => {
  try {
    const { tenant_id, user_id } = req.user;
    const {
      items,
      payment_method,
      cash_received,
      change
    } = req.body;

    if (!items || items.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Cart kosong'
      });
    }

    // Calculate total
    let total = 0;
    for (const item of items) {
      total += item.harga * item.quantity;
    }

    // Create sale record
    const { data: sale, error: saleError } = await supabase
      .from('sales')
      .insert({
        tenant_id,
        user_id,
        total,
        payment_method: payment_method || 'cash',
        cash_received: cash_received || null,
        change_amount: change || null
      })
      .select()
      .single();

    if (saleError) throw saleError;

    // Create sale items + kurangkan stok
    for (const item of items) {
      await supabase
        .from('sale_items')
        .insert({
          sale_id: sale.id,
          product_id: item.product_id || null,
          quantity: item.quantity,
          harga: item.harga,
          nama: item.nama
        });

      // Kurangkan stok kalau ada product_id
      if (item.product_id) {
        const { data: product } = await supabase
          .from('products')
          .select('stok')
          .eq('id', item.product_id)
          .single();

        if (product) {
          await supabase
            .from('products')
            .update({ stok: product.stok - item.quantity })
            .eq('id', item.product_id);
        }
      }
    }

    // Get complete sale
    const { data: completeSale } = await supabase
      .from('sales')
      .select(`
        *,
        sale_items (
          *,
          products (nama, harga)
        ),
        users (email)
      `)
      .eq('id', sale.id)
      .single();

    res.status(201).json({
      success: true,
      message: 'Sale berjaya dicipta',
      data: completeSale
    });

  } catch (error) {
    console.error('Create sale error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// ================================
// GET SALES — by tenant
// ================================
const getSales = async (req, res) => {
  try {
    const { role, tenant_id } = req.user;
    const { date, tenant_id: queryTenantId } = req.query;

    // Admin boleh tengok semua tenant
    const targetTenantId = role === 'admin'
      ? queryTenantId || tenant_id
      : tenant_id;

    let query = supabase
      .from('sales')
      .select(`
        *,
        sale_items (
          *,
          products (nama)
        ),
        users (email)
      `)
      .eq('tenant_id', targetTenantId)
      .order('created_at', { ascending: false });

    // Filter by date kalau ada
    if (date) {
      const startDate = new Date(date);
      startDate.setHours(0, 0, 0, 0);
      const endDate = new Date(date);
      endDate.setHours(23, 59, 59, 999);

      query = query
        .gte('created_at', startDate.toISOString())
        .lte('created_at', endDate.toISOString());
    }

    const { data: sales, error } = await query;

    if (error) throw error;

    res.status(200).json({
      success: true,
      data: sales
    });

  } catch (error) {
    console.error('Get sales error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// ================================
// EOD — end of day summary
// ================================
const getEOD = async (req, res) => {
  try {
    const { tenant_id } = req.user;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);

    const { data: sales, error } = await supabase
      .from('sales')
      .select(`
        *,
        sale_items (
          *,
          products (nama)
        )
      `)
      .eq('tenant_id', tenant_id)
      .gte('created_at', today.toISOString())
      .lte('created_at', endOfDay.toISOString());

    if (error) throw error;

    // Calculate summary
    const totalSales = sales.length;
    const totalRevenue = sales.reduce(
      (sum, sale) => sum + sale.total, 0
    );
    const totalItems = sales.reduce(
      (sum, sale) => sum + sale.sale_items.length, 0
    );

    res.status(200).json({
      success: true,
      data: {
        date: today.toISOString().split('T')[0],
        total_sales: totalSales,
        total_revenue: totalRevenue,
        total_items: totalItems,
        sales
      }
    });

  } catch (error) {
    console.error('EOD error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

module.exports = {
  createSale,
  getSales,
  getEOD
};