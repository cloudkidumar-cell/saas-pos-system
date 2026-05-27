const supabase = require('../config/supabase');

// ================================
// GET semua tenants
// ================================
const getAllTenants = async (req, res) => {
  try {
    const { status } = req.query;

    let query = supabase
      .from('tenants')
      .select('*')
      .order('created_at', { ascending: false });

    // Filter by status kalau ada
    if (status) {
      query = query.eq('status', status);
    }

    const { data: tenants, error } = await query;

    if (error) throw error;

    res.status(200).json({
      success: true,
      data: tenants
    });

  } catch (error) {
    console.error('Get tenants error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// ================================
// APPROVE tenant
// ================================
const approveTenant = async (req, res) => {
  try {
    const { id } = req.params;

    // Update tenant status
    const { data: tenant, error: tenantError } = await supabase
      .from('tenants')
      .update({ status: 'approved' })
      .eq('id', id)
      .select()
      .single();

    if (tenantError) throw tenantError;

    // Update user status sekali
    const { error: userError } = await supabase
      .from('users')
      .update({ status: 'active' })
      .eq('tenant_id', id);

    if (userError) throw userError;

    res.status(200).json({
      success: true,
      message: 'Tenant berjaya diluluskan',
      data: tenant
    });

  } catch (error) {
    console.error('Approve tenant error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// ================================
// REJECT tenant
// ================================
const rejectTenant = async (req, res) => {
  try {
    const { id } = req.params;

    const { data: tenant, error } = await supabase
      .from('tenants')
      .update({ status: 'rejected' })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    // Update user status sekali
    await supabase
      .from('users')
      .update({ status: 'rejected' })
      .eq('tenant_id', id);

    res.status(200).json({
      success: true,
      message: 'Tenant telah ditolak',
      data: tenant
    });

  } catch (error) {
    console.error('Reject tenant error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// ================================
// SUSPEND tenant
// ================================
const suspendTenant = async (req, res) => {
  try {
    const { id } = req.params;

    const { data: tenant, error } = await supabase
      .from('tenants')
      .update({ status: 'suspended' })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    await supabase
      .from('users')
      .update({ status: 'suspended' })
      .eq('tenant_id', id);

    res.status(200).json({
      success: true,
      message: 'Tenant telah digantung',
      data: tenant
    });

  } catch (error) {
    console.error('Suspend tenant error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

module.exports = {
  getAllTenants,
  approveTenant,
  rejectTenant,
  suspendTenant
};