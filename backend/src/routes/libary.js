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

// Semua roles boleh access — untuk search
router.get('/', getLibrary);
router.get('/kategori', getKategori);
router.get('/barcode/:barcode', getLibraryByBarcode);

// Admin je boleh manage library content
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

// Tenant DAN admin boleh add ke kedai sendiri
router.post('/add-to-tenant', addToTenant);

module.exports = router;