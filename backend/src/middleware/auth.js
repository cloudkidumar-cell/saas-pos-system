const jwt = require('jsonwebtoken');

const authenticate = (req, res, next) => {
  try {
    // Ambil token dari header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Token diperlukan'
      });
    }

    // Extract token
    const token = authHeader.split(' ')[1];

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Attach user info ke request
    req.user = decoded;

    // Teruskan ke controller
    next();

  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Token tidak sah atau telah tamat tempoh'
    });
  }
};

// Check role
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Anda tidak mempunyai akses'
      });
    }
    next();
  };
};

module.exports = { authenticate, authorize };