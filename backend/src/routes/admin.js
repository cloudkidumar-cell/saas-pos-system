const express = require('express');
const router = express.Router();
const {
  getAllTenants,
  approveTenant,
  rejectTenant,
  suspendTenant
} = require('../controllers/adminController');
const { authenticate, authorize } = require('../middleware/auth');

// Semua admin routes kena:
// 1. Ada token — authenticate
// 2. Role mesti admin — authorize

router.get(
  '/tenants',
  authenticate,
  authorize('admin'),
  getAllTenants
);

router.put(
  '/tenants/:id/approve',
  authenticate,
  authorize('admin'),
  approveTenant
);

router.put(
  '/tenants/:id/reject',
  authenticate,
  authorize('admin'),
  rejectTenant
);

router.put(
  '/tenants/:id/suspend',
  authenticate,
  authorize('admin'),
  suspendTenant
);

module.exports = router;