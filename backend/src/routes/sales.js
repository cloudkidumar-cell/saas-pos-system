const express = require('express');
const router = express.Router();
const {
  createSale,
  getSales,
  getEOD
} = require('../controllers/salesController');
const { authenticate, authorize } = require('../middleware/auth');

router.use(authenticate);

// Cashier & tenant boleh create sale
router.post(
  '/',
  authorize('cashier', 'tenant'),
  createSale
);

// Semua boleh tengok sales
router.get('/', getSales);

// EOD — cashier & tenant
router.get(
  '/eod',
  authorize('cashier', 'tenant'),
  getEOD
);

module.exports = router;