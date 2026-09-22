const mongoose = require('mongoose');

const scholarshipSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true
    },
    organization: {
        type: String,
        required: true
    },
    description: {
        type: String,
        required: true
    },
    amount: {
        type: String,
        default: 'Amount not specified'
    },
    eligibility: {
        caste: [String],
        incomeMax: Number,
        stream: [String],
        educationLevel: [String],
        gender: { type: String, default: 'Any' }
    },
    deadline: {
        type: String,
        required: true
    },
    applyUrl: {
        type: String
    },
    sourceUrl: {
        type: String
    },
    sourceName: {
        type: String
    },
    documents: [String],
    lastUpdated: {
        type: Date,
        default: Date.now
    },
    isActive: {
        type: Boolean,
        default: true
    },
    category: {
        type: String,
        default: 'All'
    },
    iconName: {
        type: String,
        default: 'star'
    },
    colorName: {
        type: String,
        default: 'amber'
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Scholarship', scholarshipSchema);
