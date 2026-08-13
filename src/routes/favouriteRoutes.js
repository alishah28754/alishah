const router = require('express').Router();
const { getFavourites, addFavourite, removeFavourite } = require('../controllers/favouriteController');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth); // All favourite routes require login

router.get('/', getFavourites);
router.post('/', addFavourite);
router.delete('/:productId', removeFavourite);

module.exports = router;