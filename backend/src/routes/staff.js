const express = require('express');
const router = express.Router();
const {
  getStaff,
  addStaff,
  suspendStaff,
  deleteStaff
} = require('../controllers/staffController');
const {
  authenticate,
  authorize
} = require('../middleware/auth');

router.use(authenticate);

// Tenant je boleh manage staff
router.get('/', authorize('tenant'), getStaff);
router.post('/', authorize('tenant'), addStaff);
router.put('/:id/suspend', authorize('tenant'), suspendStaff);
router.delete('/:id', authorize('tenant'), deleteStaff);

module.exports = router;