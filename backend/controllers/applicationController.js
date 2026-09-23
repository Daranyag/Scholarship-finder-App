const ScholarshipApplication = require('../models/ScholarshipApplication');
const Scholarship = require('../models/Scholarship');

// @desc    Get all tracking applications for the authenticated user
// @route   GET /api/applications
// @access  Private
const getApplications = async (req, res) => {
    try {
        const applications = await ScholarshipApplication.find({ user: req.user.id })
            .populate('scholarship', 'title organization deadline applyUrl')
            .sort('-updatedAt');
            
        res.status(200).json({ success: true, count: applications.length, data: applications });
    } catch (error) {
        console.error('Error fetching applications:', error);
        res.status(500).json({ success: false, message: 'Server Error fetching applications' });
    }
};

// @desc    Get single tracking application
// @route   GET /api/applications/:id
// @access  Private
const getApplicationById = async (req, res) => {
    try {
        const application = await ScholarshipApplication.findById(req.params.id)
            .populate('scholarship');

        if (!application) {
            return res.status(404).json({ success: false, message: 'Application tracking record not found' });
        }

        // Enforce user isolation
        if (application.user.toString() !== req.user.id) {
            return res.status(403).json({ success: false, message: 'Not authorized to access this record' });
        }

        res.status(200).json({ success: true, data: application });
    } catch (error) {
        console.error('Error fetching application:', error);
        res.status(500).json({ success: false, message: 'Server Error fetching application' });
    }
};

// @desc    Create an application tracking record
// @route   POST /api/applications
// @access  Private
const createApplication = async (req, res) => {
    try {
        const { scholarshipId, status, referenceNumber, notes, applicationDate } = req.body;

        if (!scholarshipId) {
            return res.status(400).json({ success: false, message: 'Scholarship ID is required' });
        }

        // Verify scholarship exists
        const scholarship = await Scholarship.findById(scholarshipId);
        if (!scholarship) {
            return res.status(404).json({ success: false, message: 'Scholarship not found' });
        }

        // Check for duplicates
        let application = await ScholarshipApplication.findOne({ user: req.user.id, scholarship: scholarshipId });
        
        if (application) {
            return res.status(200).json({ success: true, data: application, message: 'Record already exists', existing: true });
        }

        const initialStatus = status || 'PLANNING_TO_APPLY';
        
        application = await ScholarshipApplication.create({
            user: req.user.id,
            scholarship: scholarshipId,
            status: initialStatus,
            referenceNumber,
            notes,
            applicationDate: applicationDate || Date.now(),
            timeline: [{
                status: initialStatus,
                date: Date.now(),
                description: 'Tracking record created'
            }]
        });

        res.status(201).json({ success: true, data: application });
    } catch (error) {
        console.error('Error creating application:', error);
        res.status(500).json({ success: false, message: 'Server Error creating application' });
    }
};

// @desc    Update an application tracking record
// @route   PATCH /api/applications/:id
// @access  Private
const updateApplication = async (req, res) => {
    try {
        const application = await ScholarshipApplication.findById(req.params.id);

        if (!application) {
            return res.status(404).json({ success: false, message: 'Application tracking record not found' });
        }

        // Enforce user isolation
        if (application.user.toString() !== req.user.id) {
            return res.status(403).json({ success: false, message: 'Not authorized to update this record' });
        }

        const { status, referenceNumber, notes, applicationDate } = req.body;

        // Track timeline changes
        if (status && status !== application.status) {
            application.timeline.push({
                status: status,
                date: Date.now(),
                description: `Status manually updated to ${status}`
            });
            application.status = status;
        }

        if (referenceNumber !== undefined) application.referenceNumber = referenceNumber;
        if (notes !== undefined) application.notes = notes;
        if (applicationDate !== undefined) application.applicationDate = applicationDate;

        await application.save();

        res.status(200).json({ success: true, data: application });
    } catch (error) {
        console.error('Error updating application:', error);
        res.status(500).json({ success: false, message: 'Server Error updating application' });
    }
};

// @desc    Delete an application tracking record
// @route   DELETE /api/applications/:id
// @access  Private
const deleteApplication = async (req, res) => {
    try {
        const application = await ScholarshipApplication.findById(req.params.id);

        if (!application) {
            return res.status(404).json({ success: false, message: 'Application tracking record not found' });
        }

        // Enforce user isolation
        if (application.user.toString() !== req.user.id) {
            return res.status(403).json({ success: false, message: 'Not authorized to delete this record' });
        }

        await application.deleteOne();

        res.status(200).json({ success: true, message: 'Tracking record deleted' });
    } catch (error) {
        console.error('Error deleting application:', error);
        res.status(500).json({ success: false, message: 'Server Error deleting application' });
    }
};

module.exports = {
    getApplications,
    getApplicationById,
    createApplication,
    updateApplication,
    deleteApplication
};
