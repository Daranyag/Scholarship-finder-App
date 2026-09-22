const mongoose = require('mongoose');

const scholarshipFetchJobSchema = new mongoose.Schema({
    jobId: {
        type: String,
        required: true,
        unique: true
    },
    status: {
        type: String,
        enum: ['queued', 'running', 'completed', 'completed_with_errors', 'failed'],
        default: 'queued'
    },
    startedAt: {
        type: Date
    },
    completedAt: {
        type: Date
    },
    sourcesAttempted: {
        type: Number,
        default: 0
    },
    sourcesSuccessful: {
        type: Number,
        default: 0
    },
    sourcesFailed: {
        type: Number,
        default: 0
    },
    recordsDiscovered: {
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
    failedSources: [{
        name: String,
        reason: String
    }],
    errorSummary: {
        type: String
    },
    triggeredBy: {
        type: String,
        default: 'system'
    },
    triggerType: {
        type: String,
        enum: ['manual', 'scheduled'],
        default: 'scheduled'
    },
    isDryRun: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

// Indexes for quick querying
scholarshipFetchJobSchema.index({ status: 1 });
scholarshipFetchJobSchema.index({ startedAt: -1 });

module.exports = mongoose.model('ScholarshipFetchJob', scholarshipFetchJobSchema);
