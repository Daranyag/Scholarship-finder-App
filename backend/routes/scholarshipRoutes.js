const express = require('express');
const router = express.Router();
const {
    getScholarships,
    getScholarshipById,
    getMatches,
    checkEligibility,
    toggleBookmark,
    searchScholarships,
    getApplicationReadiness,
    uploadScholarshipDocument
} = require('../controllers/scholarshipController');
const { protect } = require('../middleware/authMiddleware');

const { analyzeUrl } = require('../controllers/urlAnalyzerController');

router.route('/')
    .get(protect, getScholarships);

router.route('/matches')
    .get(protect, getMatches);

router.route('/search')
    .get(protect, searchScholarships);

router.route('/analyze-url')
    .post(protect, analyzeUrl);

router.route('/:id')
    .get(protect, getScholarshipById);

router.route('/:id/check-eligibility')
    .post(protect, checkEligibility);

router.route('/:id/bookmark')
    .post(protect, toggleBookmark)
    .delete(protect, toggleBookmark);

router.route('/:id/readiness')
    .get(protect, getApplicationReadiness);

const { uploadMiddleware, analyzeEligibilitySource } = require('../controllers/eligibilityController');

router.route('/:id/documents/upload')
    .post(protect, uploadMiddleware, uploadScholarshipDocument);

// The new universal endpoint for Module 11
// We mount it under /analyze but inside scholarshipRoutes (so /api/scholarships/analyze)
// It doesn't need ID because it analyzes generic files/urls
router.route('/universal-analyze')
    .post(protect, uploadMiddleware, analyzeEligibilitySource);

module.exports = router;
