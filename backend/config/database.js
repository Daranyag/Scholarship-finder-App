const mongoose = require('mongoose');

const connectDB = async () => {
    try {
        if (!process.env.MONGODB_URI) {
            console.error('[ERROR] MongoDB connection failed: MONGODB_URI is not defined in environment variables.');
            return false;
        }

        await mongoose.connect(process.env.MONGODB_URI);
        console.log('MongoDB successfully connected.');
        return true;
    } catch (err) {
        console.error('[ERROR] MongoDB connection failed:', err.message);
        // Do not print credentials or expose the URI.
        return false;
    }
};

module.exports = connectDB;
