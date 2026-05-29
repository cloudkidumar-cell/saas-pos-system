const supabase = require('../config/supabase');

const getLibrary = async (req, res) => {
  try {
    const { search, kategori } = req.query;

    let query = supabase
      .from('product_library')
      .select('*')
      .order('nama', { ascending: true });

    if (search) {
      query = query.or(
        `nama.ilike.%${search}%,barcode.ilike.%${search}%,brand.ilike.%${search}%`
      );
    }

    if (kategori) {
      query = query.eq('kategori', kategori);
    }

    const { data, error } = await query;
    if (error) throw error;

    res.status(200).json({ success: true, data });
  } catch (error) {
    console.error('Get library error:', error);
    res
      .status(500)
      .json({ success: false, message: 'Server error' });
  }
};

const getLibraryByBarcode = async (req, res) => {
  try {
    const { barcode } = req.params;

    const { data, error } = await supabase
      .from('product_library')
      .select('*')
      .eq('barcode', barcode)
      .single();

    if (error || !data) {
      return res.status(404).json({
        success: false,
        message: 'Produk tidak dijumpai dalam library'
      });
    }

    res.status(200).json({ success: true, data });
  } catch (error) {
    console.error('Get library barcode error:', error);
    res
      .status(500)
      .json({ success: false, message: 'Server error' });
  }
};

const createLibraryProduct = async (req, res) => {
  try {
    const {
      barcode,
      nama,
      brand,
      kategori,
      unit,
      description
    } = req.body;

    if (!nama) {
      return res.status(400).json({
        success: false,
        message: 'Nama produk diperlukan'
      });
    }

    if (barcode) {
      const { data: existing } = await supabase
        .from('product_library')
        .select('id')
        .eq('barcode', barcode)
        .single();

      if (existing) {
        return res.status(400).json({
          success: false,
          message: 'Barcode ini sudah wujud dalam library'
        });
      }
    }

    const { data, error } = await supabase
      .from('product_library')
      .insert({
        barcode: barcode || null,
        nama,
        brand: brand || null,
        kategori: kategori || null,
        unit: unit || 'pcs',
        description: description || null
      })
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      message: 'Produk berjaya ditambah ke library',
      data
    });
  } catch (error) {
    console.error('Create library error:', error);
    res
      .status(500)
      .json({ success: false, message: 'Server error' });
  }
};

const updateLibraryProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      barcode,
      nama,
      brand,
      kategori,
      unit,
      description
    } = req.body;

    const { data, error } = await supabase
      .from('product_library')
      .update({
        barcode,
        nama,
        brand,
        kategori,
        unit,
        description
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    res.status(200).json({
      success: true,
      message: 'Produk berjaya dikemaskini',
      data
    });
  } catch (error) {
    console.error('Update library error:', error);
    res
      .status(500)
      .json({ success: false, message: 'Server error' });
  }
};

const deleteLibraryProduct = async (req, res) => {
  try {
    const { id } = req.params;

    const { error } = await supabase
      .from('product_library')
      .delete()
      .eq('id', id);

    if (error) throw error;

    res.status(200).json({
      success: true,
      message: 'Produk berjaya dipadam dari library'
    });
  } catch (error) {
    console.error('Delete library error:', error);
    res
      .status(500)
      .json({ success: false, message: 'Server error' });
  }
};

const addToTenant = async (req, res) => {
  try {
    const { library_id, tenant_id, harga, stok } =
      req.body;

    if (!library_id || !tenant_id || !harga) {
      return res.status(400).json({
        success: false,
        message:
          'Library ID, tenant ID dan harga diperlukan'
      });
    }

    const { data: libProduct, error: libError } =
      await supabase
        .from('product_library')
        .select('*')
        .eq('id', library_id)
        .single();

    if (libError || !libProduct) {
      return res.status(404).json({
        success: false,
        message: 'Produk tidak dijumpai dalam library'
      });
    }

    const { data: existing } = await supabase
      .from('products')
      .select('id')
      .eq('tenant_id', tenant_id)
      .eq('library_id', library_id)
      .single();

    if (existing) {
      return res.status(400).json({
        success: false,
        message: 'Produk ini sudah ada dalam kedai'
      });
    }

    const { data, error } = await supabase
      .from('products')
      .insert({
        tenant_id,
        library_id,
        nama: libProduct.nama,
        harga: parseFloat(harga),
        barcode: libProduct.barcode,
        stok: stok || 0
      })
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      message: 'Produk berjaya ditambah ke kedai',
      data
    });
  } catch (error) {
    console.error('Add to tenant error:', error);
    res
      .status(500)
      .json({ success: false, message: 'Server error' });
  }
};

const getKategori = async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('product_library')
      .select('kategori')
      .not('kategori', 'is', null)
      .order('kategori');

    if (error) throw error;

    const uniqueKategori = [
      ...new Set(data.map((d) => d.kategori))
    ];

    res
      .status(200)
      .json({ success: true, data: uniqueKategori });
  } catch (error) {
    console.error('Get kategori error:', error);
    res
      .status(500)
      .json({ success: false, message: 'Server error' });
  }
};

module.exports = {
  getLibrary,
  getLibraryByBarcode,
  createLibraryProduct,
  updateLibraryProduct,
  deleteLibraryProduct,
  addToTenant,
  getKategori
};