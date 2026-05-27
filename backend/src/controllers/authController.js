const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const supabase = require('../config/supabase');

// ================================
// REGISTER — Tenant baru
// ================================
const register = async (req, res) => {
  try {
    const { nama_kedai, email, password } = req.body;

    // Validate input
    if (!nama_kedai || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Nama kedai, email dan password diperlukan'
      });
    }

    // Check email dah exist ke tidak
    const { data: existingUser } = await supabase
      .from('users')
      .select('id')
      .eq('email', email)
      .single();

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'Email sudah didaftarkan'
      });
    }

    // Encrypt password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create tenant dulu
    const { data: tenant, error: tenantError } = await supabase
      .from('tenants')
      .insert({
        nama_kedai,
        email,
        status: 'pending'
      })
      .select()
      .single();

    if (tenantError) throw tenantError;

    // Create user untuk tenant ni
    const { data: user, error: userError } = await supabase
      .from('users')
      .insert({
        tenant_id: tenant.id,
        email,
        password: hashedPassword,
        role: 'tenant',
        status: 'pending'
      })
      .select()
      .single();

    if (userError) throw userError;

    // Return success
    res.status(201).json({
      success: true,
      message: 'Pendaftaran berjaya. Sila tunggu kelulusan admin.',
      data: {
        id: tenant.id,
        nama_kedai: tenant.nama_kedai,
        email: tenant.email,
        status: tenant.status
      }
    });

  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// ================================
// LOGIN — Semua user
// ================================
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email dan password diperlukan'
      });
    }

    // Cari user dalam database
    const { data: user, error } = await supabase
      .from('users')
      .select('*, tenants(*)')
      .eq('email', email)
      .single();

    if (error || !user) {
      return res.status(401).json({
        success: false,
        message: 'Email atau password tidak betul'
      });
    }

    // Check status — pending tak boleh login
    if (user.status === 'pending') {
      return res.status(403).json({
        success: false,
        message: 'Akaun anda belum diluluskan oleh admin'
      });
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Email atau password tidak betul'
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      {
        user_id: user.id,
        tenant_id: user.tenant_id,
        role: user.role,
        email: user.email
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    // Return token
    res.status(200).json({
      success: true,
      message: 'Login berjaya',
      data: {
        token,
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          nama_kedai: user.tenants?.nama_kedai
        }
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// ================================
// ME — Check current user
// ================================
const me = async (req, res) => {
  try {
    res.status(200).json({
      success: true,
      data: {
        user_id: req.user.user_id,
        tenant_id: req.user.tenant_id,
        role: req.user.role,
        email: req.user.email
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

module.exports = { register, login, me };