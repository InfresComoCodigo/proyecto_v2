import jwt from 'jsonwebtoken';
import { JWTPayload } from '../types';

export const signJWT = (payload: JWTPayload, secret: string, expiresIn: string): string => {
  return jwt.sign(payload, secret, { expiresIn } as any);
};

export const verifyJWT = (token: string, secret: string): JWTPayload => {
  return jwt.verify(token, secret) as JWTPayload;
};
