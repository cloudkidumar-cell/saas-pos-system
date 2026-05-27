const supabase = require('../config/supabase');

// ================================
// GET semua products — by tenant
// ================================
const getProducts = async (req, res) => {
  try {
    const { tenant_id } = req.user;

    const { data: products, error } = await supabase
      .from('products')
      .select('*')
      .eq('tenant_id', tenant_id)
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.status(200).json({
      success: true,
      data: products
    });

  } catch (error) {
    console.error('Get products error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// ================================
// GET product by barcode
// ================================
const getProductByBarcode = async (req, res) => {
  try {
    const { tenant_id } = req.user;
    const { code } = req.params;

    const { data: product, error } = await supabase
      .from('products')
      .select('*')
      .eq('tenant_id', tenant_id)
      .eq('barcode', code)
      .single();

    if (error || !product) {
      return res.status(404).json({
        success: false,
        message: 'Produk tidak dijumpai'
      });
    }

    // Check stok
    if (product.stok === 0) {
      return res.status(200).json({
        success: true,
        warning: 'Stok habis',
        data: product
      });
    }

    res.status(200).json({
      success: true,
      data: product
    });

  } catch (error) {
    console.error('Get product by barcode error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// ================================
// CREATE product — admin je
// ================================
const createProduct = async (req, res) => {
  try {
    const { nama, harga, barcode, stok, tenant_id } = req.body;

    // Validate input
    if (!nama || !harga || !tenant_id) {
      return res.status(400).json({
        success: false,
        message: 'Nama, harga dan tenant diperlukan'
      });
    }

    // Check barcode dah exist ke dalam tenant ni
    if (barcode) {
      const { data: existing } = await supabase
        .from('products')
        .select('id')
        .eq('tenant_id', tenant_id)
        .eq('barcode', barcode)
        .single();

      if (existing) {
        return res.status(400).json({
          success: false,
          message: 'Barcode ini sudah digunakan'
        });
      }
    }

    const { data: product, error } = await supabase
      .from('products')
      .insert({
        tenant_id,
        nama,
        harga,
        barcode: barcode || null,
        stok: stok || 0
      })
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      message: 'Produk berjaya ditambah',
      data: product
    });

  } catch (error) {
    console.error('Create product error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// ================================
// UPDATE product — admin je
// ================================
const updateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const { nama, harga, barcode, stok } = req.body;

    const { data: product, error } = await supabase
      .from('products')
      .update({ nama, harga, barcode, stok })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    res.status(200).json({
      success: true,
      message: 'Produk berjaya dikemaskini',
      data: product
    });

  } catch (error) {
    console.error('Update product error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// ================================
// DELETE product — admin je
// ================================
const deleteProduct = async (req, res) => {
  try {
    const { id } = req.params;

    const { error } = await supabase
      .from('products')
      .delete()
      .eq('id', id);

    if (error) throw error;

    res.status(200).json({
      success: true,
      message: 'Produk berjaya dipadam'
    });

  } catch (error) {
    console.error('Delete product error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// ================================
// RESTOCK — cashier je
// ================================
const restockProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const { quantity } = req.body;
    const { tenant_id } = req.user;

    if (!quantity || quantity <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Quantity mesti lebih dari 0'
      });
    }

    // Get current stok
    const { data: product, error: getError } = await supabase
      .from('products')
      .select('stok, tenant_id')
      .eq('id', id)
      .single();

    if (getError || !product) {
      return res.status(404).json({
        success: false,
        message: 'Produk tidak dijumpai'
      });
    }

    // Pastikan cashier restock produk tenant dia je
    if (product.tenant_id !== tenant_id) {
      return res.status(403).json({
        success: false,
        message: 'Anda tidak mempunyai akses'
      });
    }

    // Update stok
    const newStok = product.stok + quantity;

    const { data: updated, error: updateError } = await supabase
      .from('products')
      .update({ stok: newStok })
      .eq('id', id)
      .select()
      .single();

    if (updateError) throw updateError;

    res.status(200).json({
      success: true,
      message: `Stok berjaya ditambah. Stok baru: ${newStok}`,
      data: updated
    });

  } catch (error) {
    console.error('Restock error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

module.exports = {
  getProducts,
  getProductByBarcode,
  createProduct,
  updateProduct,
  deleteProduct,
  restockProduct
};