const multer = require('multer');
const eligibilityService = require('../services/eligibilityService');

// Multer config (memory storage for simple processing)
const storage = multer.memoryStorage();
const upload = multer({
    storage: storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
    fileFilter: (req, file, cb) => {
        const allowed = ['application/pdf', 'image/jpeg', 'image/png', 'image/webp'];
        if (allowed.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Unsupported file type. Only PDF and Images (JPG/PNG/WEBP) are allowed.'));
        }
    }
}).single('file');

// Middleware wrapper for multer
const uploadMiddleware = (req, res, next) => {
    upload(req, res, (err) => {
        if (err) {
            return res.status(400).json({ success: false, message: err.message });
        }
        next();
    });
};

// @desc    Analyze file or URL for scholarship eligibility
// @route   POST /api/eligibility/analyze
// @access  Private
const analyzeEligibilitySource = async (req, res) => {
    try {
        const { sourceType, url } = req.body;
        const fileBuffer = req.file ? req.file.buffer : null;

        const result = await eligibilityService.analyzeSource(sourceType, url, fileBuffer);
        
        res.status(200).json({
            success: true,
            ...result
        });
    } catch (error) {
        if (error.statusCode) {
            return res.status(error.statusCode).json({ success: false, message: error.message });
        }
        console.error('Error in analyzeEligibilitySource:', error);
        res.status(500).json({ success: false, message: 'Server error processing file' });
    }
};

module.exports = {
    uploadMiddleware,
    analyzeEligibilitySource
};
