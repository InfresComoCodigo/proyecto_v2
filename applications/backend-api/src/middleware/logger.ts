import { Request, Response, NextFunction } from 'express';

export const logger = (req: Request, res: Response, next: NextFunction): void => {
  const start = Date.now();
  const { method, url, ip } = req;
  const userAgent = req.get('User-Agent') || 'Unknown';
  
  // Log request
  console.log(`📝 [${new Date().toISOString()}] ${method} ${url} - ${ip} - ${userAgent}`);
  
  // Capture original send method
  const originalSend = res.send;
  
  // Override send method to log response
  res.send = function(body) {
    const duration = Date.now() - start;
    const statusCode = res.statusCode;
    const statusEmoji = statusCode >= 400 ? '❌' : statusCode >= 300 ? '⚠️' : '✅';
    
    console.log(`${statusEmoji} [${new Date().toISOString()}] ${method} ${url} - ${statusCode} - ${duration}ms`);
    
    // Call original send method
    return originalSend.call(this, body);
  };
  
  next();
};
