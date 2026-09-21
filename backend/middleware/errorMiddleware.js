const errorHandler = (err, req, res, next) => {
    console.error(`[ERROR] ${err.message}`);
    
    // Log details in development, but don't expose in response
    if (process.env.NODE_ENV === 'development') {
        console.error(err.stack);
    }

    res.status(err.statusCode || 500).json({
        success: false,
        message: err.message || "Internal server error"
    });
};

module.exports = errorHandler;
