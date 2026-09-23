const mongoose = require('mongoose');

const connectDB = async () => {
    try {
        if (!process.env.MONGODB_URI) {
            console.error('[ERROR] MongoDB connection failed: MONGODB_URI is not defined in environment variables.');
            return false;
        }

        await mongoose.connect(process.env.MONGODB_URI, {
            maxPoolSize: 50, // Increase max connection pool size
            minPoolSize: 10, // Maintain a minimum number of connections
            socketTimeoutMS: 45000, // Close sockets after 45s of inactivity
            serverSelectionTimeoutMS: 10000, // Keep trying to send operations for 10s
            family: 4, // Use IPv4, skip trying IPv6
        });
        console.log('MongoDB successfully connected.');
        return true;
    } catch (err) {
        console.error('[ERROR] MongoDB connection failed:', err.message);
        // Do not print credentials or expose the URI.
        return false;
    }
};

module.exports = connectDB;
