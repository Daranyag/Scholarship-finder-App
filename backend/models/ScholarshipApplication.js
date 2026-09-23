const mongoose = require('mongoose');

const timelineItemSchema = new mongoose.Schema({
    status: {
        type: String,
        required: true
    },
    date: {
        type: Date,
        default: Date.now
    },
    description: {
        type: String,
        default: ''
    }
}, { _id: false });

const scholarshipApplicationSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    scholarship: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Scholarship',
        required: true
    },
    status: {
        type: String,
        enum: [
            'NOT_APPLIED',
            'PLANNING_TO_APPLY',
            'APPLICATION_STARTED',
            'SUBMITTED',
            'UNDER_REVIEW',
            'DOCUMENT_VERIFICATION',
            'APPROVED',
            'REJECTED',
            'WITHDRAWN',
            'EXPIRED',
            'UNKNOWN'
        ],
        default: 'PLANNING_TO_APPLY'
    },
    applicationDate: {
        type: Date,
        default: Date.now
    },
    referenceNumber: {
        type: String,
        default: ''
    },
    notes: {
        type: String,
        default: ''
    },
    timeline: [timelineItemSchema]
}, {
    timestamps: true
});

// Ensure a user can only have one application tracking record per scholarship
scholarshipApplicationSchema.index({ user: 1, scholarship: 1 }, { unique: true });

module.exports = mongoose.model('ScholarshipApplication', scholarshipApplicationSchema);
