const { matchScholarship } = require('./services/eligibilityMatcherService');
const mongoose = require('mongoose');
const Scholarship = require('./models/Scholarship');

require('dotenv').config();

const test = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/scholarship');
        console.log('DB Connected.');

        const scholarships = await Scholarship.find({});
        if (scholarships.length === 0) {
            console.log('No scholarships found to test against.');
            return;
        }

        console.log('--- TEST 1: Full match ---');
        const user1 = { caste: 'minority', annualIncome: 100000, stream: 'engineering', educationLevel: 'ug degree', gender: 'male' };
        console.log('User:', user1);
        for(let sch of scholarships) {
            console.log(`Matching against: ${sch.title} | Result:`, matchScholarship(user1, sch).matchStatus);
        }

        console.log('\n--- TEST 2: Missing info ---');
        const user2 = { caste: 'minority' }; // missing income, stream, etc.
        console.log('User:', user2);
        for(let sch of scholarships) {
            console.log(`Matching against: ${sch.title} | Result:`, matchScholarship(user2, sch).matchStatus);
        }
        
    } catch (err) {
        console.error(err);
    } finally {
        await mongoose.disconnect();
    }
};

test();
