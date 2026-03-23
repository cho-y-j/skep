const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const winston = require('winston');
require('dotenv').config();

// ==========================================
// Configuration
// ==========================================

const PORT = process.env.PORT || 8090;
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';
const NODE_ENV = process.env.NODE_ENV || 'dev';

// ==========================================
// Logging Configuration
// ==========================================

const logger = winston.createLogger({
    level: LOG_LEVEL,
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    defaultMeta: { service: 'govapi-service', environment: NODE_ENV },
    transports: [
        new winston.transports.Console({
            format: winston.format.combine(
                winston.format.colorize(),
                winston.format.simple()
            )
        })
    ]
});

// ==========================================
// Express App Setup
// ==========================================

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging
app.use((req, res, next) => {
    logger.info(`${req.method} ${req.path}`, {
        method: req.method,
        path: req.path,
        query: req.query,
        ip: req.ip
    });
    next();
});

// ==========================================
// Health Check
// ==========================================

app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'UP',
        service: 'govapi-service',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

// ==========================================
// Mock Government API Endpoints
// ==========================================

/**
 * Verify vehicle information
 * POST /api/verify/vehicle
 */
app.post('/api/verify/vehicle', (req, res) => {
    try {
        const { vehicleNumber, ownerName, registrationNumber } = req.body;

        if (!vehicleNumber) {
            return res.status(400).json({
                success: false,
                error: 'vehicleNumber is required'
            });
        }

        const requestId = uuidv4();
        logger.info('Vehicle Verification Request', {
            requestId,
            vehicleNumber
        });

        // Mock verification response (90% success rate)
        const isVerified = Math.random() > 0.1;

        const response = {
            success: true,
            requestId,
            verified: isVerified,
            data: isVerified ? {
                vehicleNumber: vehicleNumber || 'AB1234CD',
                ownerName: ownerName || 'John Doe',
                registrationNumber: registrationNumber || 'REG123456',
                engineNumber: 'EN123456789',
                chassisNumber: 'CH123456789',
                modelYear: 2021,
                fuelType: 'Diesel',
                color: 'Black',
                registrationDate: '2021-01-15',
                expiryDate: '2026-01-15',
                status: 'VALID'
            } : {
                vehicleNumber,
                error: 'Vehicle not found in registry'
            }
        };

        logger.info('Vehicle Verification Completed', {
            requestId,
            verified: isVerified
        });

        res.status(200).json(response);

    } catch (error) {
        logger.error('Vehicle Verification Error', {
            error: error.message,
            stack: error.stack
        });
        res.status(500).json({
            success: false,
            error: 'Internal server error'
        });
    }
});

/**
 * Verify driver license information
 * POST /api/verify/license
 */
app.post('/api/verify/license', (req, res) => {
    try {
        const { licenseNumber, name, dateOfBirth } = req.body;

        if (!licenseNumber) {
            return res.status(400).json({
                success: false,
                error: 'licenseNumber is required'
            });
        }

        const requestId = uuidv4();
        logger.info('License Verification Request', {
            requestId,
            licenseNumber
        });

        // Mock verification response (92% success rate)
        const isVerified = Math.random() > 0.08;

        const response = {
            success: true,
            requestId,
            verified: isVerified,
            data: isVerified ? {
                licenseNumber: licenseNumber || 'DL123456789',
                name: name || 'Jane Smith',
                dateOfBirth: dateOfBirth || '1990-05-20',
                gender: 'Female',
                address: '123 Main Street, Seoul',
                issueDate: '2019-06-01',
                expiryDate: '2029-06-01',
                restrictions: 'None',
                licenseClass: 'B',
                status: 'VALID'
            } : {
                licenseNumber,
                error: 'License not found in registry'
            }
        };

        logger.info('License Verification Completed', {
            requestId,
            verified: isVerified
        });

        res.status(200).json(response);

    } catch (error) {
        logger.error('License Verification Error', {
            error: error.message,
            stack: error.stack
        });
        res.status(500).json({
            success: false,
            error: 'Internal server error'
        });
    }
});

/**
 * Verify business registration information
 * POST /api/verify/business
 */
app.post('/api/verify/business', (req, res) => {
    try {
        const { businessNumber, companyName, representative } = req.body;

        if (!businessNumber) {
            return res.status(400).json({
                success: false,
                error: 'businessNumber is required'
            });
        }

        const requestId = uuidv4();
        logger.info('Business Verification Request', {
            requestId,
            businessNumber
        });

        // Mock verification response (95% success rate)
        const isVerified = Math.random() > 0.05;

        const response = {
            success: true,
            requestId,
            verified: isVerified,
            data: isVerified ? {
                businessNumber: businessNumber || '123-45-67890',
                companyName: companyName || 'SKEP Corporation',
                representative: representative || 'Park Min-jun',
                businessAddress: '456 Business Park, Seoul',
                businessType: 'Technology Services',
                businessCategory: 'Software Development',
                registrationDate: '2015-03-10',
                capitalAmount: '500,000,000',
                status: 'ACTIVE'
            } : {
                businessNumber,
                error: 'Business not found in registry'
            }
        };

        logger.info('Business Verification Completed', {
            requestId,
            verified: isVerified
        });

        res.status(200).json(response);

    } catch (error) {
        logger.error('Business Verification Error', {
            error: error.message,
            stack: error.stack
        });
        res.status(500).json({
            success: false,
            error: 'Internal server error'
        });
    }
});

/**
 * Verify insurance information
 * POST /api/verify/insurance
 */
app.post('/api/verify/insurance', (req, res) => {
    try {
        const { policyNumber, vehicleNumber, holderName } = req.body;

        if (!policyNumber && !vehicleNumber) {
            return res.status(400).json({
                success: false,
                error: 'policyNumber or vehicleNumber is required'
            });
        }

        const requestId = uuidv4();
        logger.info('Insurance Verification Request', {
            requestId,
            policyNumber,
            vehicleNumber
        });

        // Mock verification response (88% success rate)
        const isVerified = Math.random() > 0.12;

        const response = {
            success: true,
            requestId,
            verified: isVerified,
            data: isVerified ? {
                policyNumber: policyNumber || 'POL123456789',
                vehicleNumber: vehicleNumber || 'AB1234CD',
                holderName: holderName || 'John Doe',
                insurer: 'Korea Insurance Company',
                policyType: 'Third-party Liability',
                coverageAmount: '100,000,000',
                issueDate: '2023-01-01',
                expiryDate: '2024-12-31',
                status: 'ACTIVE'
            } : {
                policyNumber,
                error: 'Insurance policy not found in registry'
            }
        };

        logger.info('Insurance Verification Completed', {
            requestId,
            verified: isVerified
        });

        res.status(200).json(response);

    } catch (error) {
        logger.error('Insurance Verification Error', {
            error: error.message,
            stack: error.stack
        });
        res.status(500).json({
            success: false,
            error: 'Internal server error'
        });
    }
});

/**
 * Verify ID card information
 * POST /api/verify/id-card
 */
app.post('/api/verify/id-card', (req, res) => {
    try {
        const { idNumber, name, dateOfBirth } = req.body;

        if (!idNumber) {
            return res.status(400).json({
                success: false,
                error: 'idNumber is required'
            });
        }

        const requestId = uuidv4();
        logger.info('ID Card Verification Request', {
            requestId,
            idNumber
        });

        // Mock verification response (94% success rate)
        const isVerified = Math.random() > 0.06;

        const response = {
            success: true,
            requestId,
            verified: isVerified,
            data: isVerified ? {
                idNumber: idNumber,
                name: name || 'Lee Ji-woo',
                dateOfBirth: dateOfBirth || '1990-05-15',
                gender: 'Male',
                address: '789 Apartment, Busan',
                issueDate: '2018-05-15',
                expiryDate: '2028-05-15',
                status: 'VALID'
            } : {
                idNumber,
                error: 'ID not found in registry'
            }
        };

        logger.info('ID Card Verification Completed', {
            requestId,
            verified: isVerified
        });

        res.status(200).json(response);

    } catch (error) {
        logger.error('ID Card Verification Error', {
            error: error.message,
            stack: error.stack
        });
        res.status(500).json({
            success: false,
            error: 'Internal server error'
        });
    }
});

/**
 * Get Government API service status
 * GET /api/verify/status
 */
app.get('/api/verify/status', (req, res) => {
    res.status(200).json({
        status: 'operational',
        service: 'govapi-service',
        version: '1.0.0',
        endpoints: [
            '/api/verify/vehicle',
            '/api/verify/license',
            '/api/verify/business',
            '/api/verify/insurance',
            '/api/verify/id-card'
        ],
        timestamp: new Date().toISOString()
    });
});

// ==========================================
// Error Handling
// ==========================================

// 404 Handler
app.use((req, res) => {
    logger.warn('Route not found', {
        method: req.method,
        path: req.path
    });
    res.status(404).json({
        success: false,
        error: 'Route not found',
        path: req.path
    });
});

// Global error handler
app.use((err, req, res, next) => {
    logger.error('Unhandled error', {
        error: err.message,
        stack: err.stack,
        method: req.method,
        path: req.path
    });
    res.status(500).json({
        success: false,
        error: 'Internal server error'
    });
});

// ==========================================
// Server Start
// ==========================================

const server = app.listen(PORT, () => {
    logger.info(`Government API Service started successfully`, {
        port: PORT,
        environment: NODE_ENV,
        logLevel: LOG_LEVEL
    });
});

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM received, gracefully shutting down...');
    server.close(() => {
        logger.info('Server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    logger.info('SIGINT received, gracefully shutting down...');
    server.close(() => {
        logger.info('Server closed');
        process.exit(0);
    });
});

module.exports = app;
