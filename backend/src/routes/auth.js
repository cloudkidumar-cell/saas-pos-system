const express = require('express');
const router = express.Router();
const { register, login, me } = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');

// Public routes — tak perlu token
router.post('/register', register);
router.post('/login', login);

// Protected route — perlu token
router.get('/me', authenticate, me);

module.exports = router;