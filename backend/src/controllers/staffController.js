const bcrypt = require('bcryptjs');
const supabase = require('../config/supabase');

// ================================
// GET semua staff — by tenant
// ================================
const getStaff = async (req, res) => {
  try {
    const { tenant_id } = req.user;

    const { data: staff, error } = await supabase
      .from('users')
      .select('id, email, role, status, created_at')
      .eq('tenant_id', tenant_id)
      .eq('role', 'cashier')
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.status(200).json({
      success: true,
      data: staff
    });

  } catch (error) {
    console.error('Get staff error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// ================================
// ADD cashier — tenant je
// ================================
const addStaff = async (req, res) => {
  try {
    const { tenant_id } = req.user;
    const { email, password } = req.body;

    // Validate
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email dan password diperlukan'
      });
    }

    // Check email exist
    const { data: existing } = await supabase
      .from('users')
      .select('id')
      .eq('email', email)
      .single();

    if (existing) {
      return res.status(400).json({
        success: false,
        message: 'Email sudah didaftarkan'
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create cashier
    const { data: staff, error } = await supabase
      .from('users')
      .insert({
        tenant_id,
        email,
        password: hashedPassword,
        role: 'cashier',
        status: 'active'
      })
      .select('id, email, role, status, created_at')
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      message: 'Cashier berjaya ditambah',
      data: staff
    });

  } catch (error) {
    console.error('Add staff error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// ================================
// SUSPEND cashier
// ================================
const suspendStaff = async (req, res) => {
  try {
    const { tenant_id } = req.user;
    const { id } = req.params;

    // Pastikan cashier ni dari tenant yang sama
    const { data: staff, error: checkError } = await supabase
      .from('users')
      .select('tenant_id, status')
      .eq('id', id)
      .single();

    if (checkError || !staff) {
      return res.status(404).json({
        success: false,
        message: 'Staff tidak dijumpai'
      });
    }

    if (staff.tenant_id !== tenant_id) {
      return res.status(403).json({
        success: false,
        message: 'Anda tidak mempunyai akses'
      });
    }

    // Toggle status
    const newStatus =
      staff.status === 'active' ? 'suspended' : 'active';

    const { data: updated, error } = await supabase
      .from('users')
      .update({ status: newStatus })
      .eq('id', id)
      .select('id, email, role, status')
      .single();

    if (error) throw error;

    res.status(200).json({
      success: true,
      message: newStatus === 'suspended'
        ? 'Cashier digantung'
        : 'Cashier diaktifkan',
      data: updated
    });

  } catch (error) {
    console.error('Suspend staff error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// ================================
// DELETE cashier
// ================================
const deleteStaff = async (req, res) => {
  try {
    const { tenant_id } = req.user;
    const { id } = req.params;

    // Pastikan cashier ni dari tenant yang sama
    const { data: staff, error: checkError } = await supabase
      .from('users')
      .select('tenant_id')
      .eq('id', id)
      .single();

    if (checkError || !staff) {
      return res.status(404).json({
        success: false,
        message: 'Staff tidak dijumpai'
      });
    }

    if (staff.tenant_id !== tenant_id) {
      return res.status(403).json({
        success: false,
        message: 'Anda tidak mempunyai akses'
      });
    }

    const { error } = await supabase
      .from('users')
      .delete()
      .eq('id', id);

    if (error) throw error;

    res.status(200).json({
      success: true,
      message: 'Cashier berjaya dipadam'
    });

  } catch (error) {
    console.error('Delete staff error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

module.exports = {
  getStaff,
  addStaff,
  suspendStaff,
  deleteStaff
};