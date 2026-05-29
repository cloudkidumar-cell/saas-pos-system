const express = require('express');
const router = express.Router();
const {
  getLibrary,
  getLibraryByBarcode,
  createLibraryProduct,
  updateLibraryProduct,
  deleteLibraryProduct,
  addToTenant,
  getKategori
} = require('../controllers/libraryController');
const {
  authenticate,
  authorize
} = require('../middleware/auth');

router.use(authenticate);

// Semua boleh access library — untuk search
router.get('/', getLibrary);
router.get('/kategori', getKategori);
router.get('/barcode/:barcode', getLibraryByBarcode);

// Admin je boleh manage library
router.post(
  '/',
  authorize('admin'),
  createLibraryProduct
);
router.put(
  '/:id',
  authorize('admin'),
  updateLibraryProduct
);
router.delete(
  '/:id',
  authorize('admin'),
  deleteLibraryProduct
);

// Admin add product ke tenant
router.post(
  '/add-to-tenant',
  authorize('admin'),
  addToTenant
);

module.exports = router;