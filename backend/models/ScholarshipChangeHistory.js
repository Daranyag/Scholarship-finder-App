const mongoose = require('mongoose');

const scholarshipChangeHistorySchema = new mongoose.Schema({
    scholarshipId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Scholarship',
        required: true
    },
    sourceName: {
        type: String,
        required: true
    },
    changedFields: [{
        type: String
    }],
    previousValues: {
        type: mongoose.Schema.Types.Mixed
    },
    newValues: {
        type: mongoose.Schema.Types.Mixed
    },
    detectedAt: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

// Index to quickly find recent changes
scholarshipChangeHistorySchema.index({ detectedAt: -1 });
// Index to quickly find changes for a specific scholarship
scholarshipChangeHistorySchema.index({ scholarshipId: 1, detectedAt: -1 });

module.exports = mongoose.model('ScholarshipChangeHistory', scholarshipChangeHistorySchema);
