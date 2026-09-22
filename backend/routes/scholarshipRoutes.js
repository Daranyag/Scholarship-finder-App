const express = require('express');
const router = express.Router();
const {
    getScholarships,
    getScholarshipById,
    getMatches
} = require('../controllers/scholarshipController');
const { protect } = require('../middleware/authMiddleware');

router.route('/')
    .get(protect, getScholarships);

router.route('/matches')
    .get(protect, getMatches);

router.route('/:id')
    .get(protect, getScholarshipById);

module.exports = router;
