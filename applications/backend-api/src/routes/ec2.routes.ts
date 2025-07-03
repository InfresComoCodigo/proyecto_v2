import { Router, Request, Response } from 'express';
import axios from 'axios';

const router = Router();

// Lista de IPs privadas de las instancias EC2 (estas se obtendrían de las variables de entorno)
const EC2_INSTANCES = [
  process.env.EC2_ZONE_A_IP || '10.0.101.10', // IP privada de la instancia en zona A
  process.env.EC2_ZONE_B_IP || '10.0.102.10'  // IP privada de la instancia en zona B
];

/**
 * @route GET /api/ec2/hello
 * @desc Obtiene "Hello World" de todas las instancias EC2
 * @access Public
 */
router.get('/hello', async (req: Request, res: Response) => {
  try {
    const responses = await Promise.allSettled(
      EC2_INSTANCES.map(async (ip, index) => {
        try {
          // Intentar conectar al endpoint de hello en cada instancia
          const response = await axios.get(`http://${ip}/api/hello`, {
            timeout: 5000,
            headers: {
              'User-Agent': 'Villa-Alfredo-Backend/1.0'
            }
          });
          
          return {
            instance: `ec2-zone-${index === 0 ? 'a' : 'b'}`,
            ip: ip,
            status: 'success',
            message: response.data.message || 'Hello World',
            timestamp: new Date().toISOString(),
            responseTime: response.headers['x-response-time'] || 'N/A'
          };
        } catch (error: any) {
          return {
            instance: `ec2-zone-${index === 0 ? 'a' : 'b'}`,
            ip: ip,
            status: 'error',
            error: error.message,
            timestamp: new Date().toISOString()
          };
        }
      })
    );

    const results = responses.map(result => 
      result.status === 'fulfilled' ? result.value : result.reason
    );

    const successCount = results.filter(r => r.status === 'success').length;
    const totalCount = EC2_INSTANCES.length;

    res.status(200).json({
      message: 'EC2 instances connectivity test completed',
      summary: {
        total_instances: totalCount,
        successful_connections: successCount,
        failed_connections: totalCount - successCount
      },
      instances: results,
      timestamp: new Date().toISOString()
    });

  } catch (error: any) {
    console.error('Error connecting to EC2 instances:', error);
    res.status(500).json({
      error: 'Failed to connect to EC2 instances',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * @route GET /api/ec2/status
 * @desc Verifica el estado de las instancias EC2
 * @access Public
 */
router.get('/status', async (req: Request, res: Response) => {
  try {
    const healthChecks = await Promise.allSettled(
      EC2_INSTANCES.map(async (ip, index) => {
        try {
          const response = await axios.get(`http://${ip}/health`, {
            timeout: 3000
          });
          
          return {
            instance: `ec2-zone-${index === 0 ? 'a' : 'b'}`,
            ip: ip,
            status: 'healthy',
            uptime: response.data.uptime || 'N/A',
            timestamp: new Date().toISOString()
          };
        } catch (error: any) {
          return {
            instance: `ec2-zone-${index === 0 ? 'a' : 'b'}`,
            ip: ip,
            status: 'unhealthy',
            error: error.message,
            timestamp: new Date().toISOString()
          };
        }
      })
    );

    const results = healthChecks.map(result => 
      result.status === 'fulfilled' ? result.value : result.reason
    );

    res.status(200).json({
      message: 'EC2 health check completed',
      instances: results,
      timestamp: new Date().toISOString()
    });

  } catch (error: any) {
    console.error('Error checking EC2 health:', error);
    res.status(500).json({
      error: 'Failed to check EC2 health',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

export default router;
