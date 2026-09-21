const mongoose = require('mongoose');

const checkHealth = (req, res) => {
    // mongoose.connection.readyState returns 1 when connected
    const isDatabaseConnected = mongoose.connection.readyState === 1;

    res.json({
        success: true,
        message: "Backend is running",
        database: isDatabaseConnected ? "connected" : "disconnected"
    });
};

module.exports = {
    checkHealth
};
