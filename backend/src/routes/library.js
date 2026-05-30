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

router.get('/', getLibrary);
router.get('/kategori', getKategori);
router.get('/barcode/:barcode', getLibraryByBarcode);

router.post('/', authorize('admin'), createLibraryProduct);
router.put('/:id', authorize('admin'), updateLibraryProduct);
router.delete('/:id', authorize('admin'), deleteLibraryProduct);

// Tenant dan admin boleh add ke kedai
router.post('/add-to-tenant', addToTenant);

module.exports = router;