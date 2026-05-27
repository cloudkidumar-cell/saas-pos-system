const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const supabase = require('./config/supabase');
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check — dengan database check
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