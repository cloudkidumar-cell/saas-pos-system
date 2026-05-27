const express = require('express');
const router = express.Router();
const {
  getProducts,
  getProductByBarcode,
  createProduct,
  updateProduct,
  deleteProduct,
  restockProduct
} = require('../controllers/productController');
const { authenticate, authorize } = require('../middleware/auth');

// Semua routes kena authenticate dulu
router.use(authenticate);

// Tenant & cashier boleh access
router.get('/', getProducts);
router.get('/barcode/:code', getProductByBarcode);

// Admin je boleh
router.post('/', authorize('admin'), createProduct);
router.put('/:id', authorize('admin'), updateProduct);
router.delete('/:id', authorize('admin'), deleteProduct);

// Cashier & tenant boleh restock
router.put(
  '/:id/restock',
  authorize('cashier', 'tenant'),
  restockProduct
);

module.exports = router;