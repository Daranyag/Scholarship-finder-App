const mongoose = require('mongoose');

const scholarshipSourceStatusSchema = new mongoose.Schema({
    sourceName: {
        type: String,
        required: true,
        unique: true
    },
    sourceUrl: {
        type: String,
        required: true
    },
    enabled: {
        type: Boolean,
        default: true
    },
    lastCheckedAt: {
        type: Date
    },
    lastSuccessfulAt: {
        type: Date
    },
    lastFailedAt: {
        type: Date
    },
    lastHttpStatus: {
        type: Number
    },
    lastRunStatus: {
        type: String,
        enum: ['ACTIVE', 'INACTIVE', 'FAILED', 'UNAVAILABLE', 'SUCCESS', 'SUCCESS_WITH_WARNINGS', 'PARSING_FAILED', 'PENDING'],
        default: 'PENDING'
    },
    recordsFound: {
        type: Number,
        default: 0
    },
    recordsInserted: {
        type: Number,
        default: 0
    },
    recordsUpdated: {
        type: Number,
        default: 0
    },
    recordsSkipped: {
        type: Number,
        default: 0
    },
    lastError: {
        type: String
    },
    consecutiveFailures: {
        type: Number,
        default: 0
    },
    lastContentHash: {
        type: String
    }
}, {
    timestamps: true
});

// Indexes
scholarshipSourceStatusSchema.index({ sourceName: 1 });
scholarshipSourceStatusSchema.index({ lastRunStatus: 1 });
scholarshipSourceStatusSchema.index({ lastCheckedAt: -1 });

module.exports = mongoose.model('ScholarshipSourceStatus', scholarshipSourceStatusSchema);
