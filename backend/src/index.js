const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const supabase = require('./config/supabase');
const authRoutes = require('./routes/auth');
const adminRoutes = require('./routes/admin');
const productRoutes = require('./routes/products');
const salesRoutes = require('./routes/sales');
const staffRoutes = require('./routes/staff');
const libraryRoutes = require('./routes/library');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
//app.use(cors());
app.use(cors({
  origin: [
    'http://localhost:3001',
    'https://saas-pos-system-tau.vercel.app',
    'https://saas-pos-system-two.vercel.app',
    'https://admin.nbyte-tech.com',
  ],
  credentials: true,
}));
app.use(express.json());

// Routes
app.use('/auth', authRoutes);
app.use('/admin', adminRoutes);
app.use('/products', productRoutes);
app.use('/sales', salesRoutes);
app.use('/staff', staffRoutes);
app.use('/library', libraryRoutes);
// Health check
app.get('/health', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('tenants')
      .select('count');

    if (error) throw error;

    res.status(200).json({
      status: 'OK',
      message: 'POS API is running',
      database: 'connected',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      message: 'Database connection failed',
      database: 'disconnected',
      timestamp: new Date().toISOString()
    });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});