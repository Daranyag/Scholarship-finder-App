// 1. Load environment variables
require('dotenv').config();

// 2. Validate required configuration
const requiredEnvVars = ['PORT', 'MONGODB_URI', 'JWT_SECRET', 'NODE_ENV'];
const missingVars = requiredEnvVars.filter(envVar => !process.env[envVar]);

if (missingVars.length > 0) {
    console.error(`[ERROR] Missing required environment variables: ${missingVars.join(', ')}`);
}

const express = require('express');
const cors = require('cors');
const connectDB = require('./config/database');

// Import Routes
const healthRoutes = require('./routes/healthRoutes');

// Import Middleware
const notFoundMiddleware = require('./middleware/notFoundMiddleware');
const errorMiddleware = require('./middleware/errorMiddleware');

const app = express();

// 3. Connect to MongoDB
connectDB();

// 4. Initialize Express (done above)

// 5. Register middleware
app.use(cors()); // Allow all origins for development
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 6. Register routes
app.use('/api/health', healthRoutes);

// 7. Register 404 middleware
app.use(notFoundMiddleware);

// 8. Register error middleware
app.use(errorMiddleware);

// 9. Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT} in ${process.env.NODE_ENV} mode`);
});
