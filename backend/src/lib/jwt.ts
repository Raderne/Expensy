import jwt, { type JwtPayload, type SignOptions } from 'jsonwebtoken';
import { env } from '../config/env.js';

export interface AccessTokenPayload extends JwtPayload {
  sub: string;
}

export interface RefreshTokenPayload extends JwtPayload {
  sub: string;
  jti: string;
}

const signAccessOptions: SignOptions = {
  expiresIn: env.JWT_ACCESS_TTL as SignOptions['expiresIn'],
};
const signRefreshOptions: SignOptions = {
  expiresIn: env.JWT_REFRESH_TTL as SignOptions['expiresIn'],
};

export const signAccessToken = (userId: string): string =>
  jwt.sign({ sub: userId }, env.JWT_ACCESS_SECRET, signAccessOptions);

export const signRefreshToken = (userId: string, jti: string): string =>
  jwt.sign({ sub: userId }, env.JWT_REFRESH_SECRET, { ...signRefreshOptions, jwtid: jti });

export const verifyAccessToken = (token: string): AccessTokenPayload => {
  const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET);
  if (typeof decoded === 'string' || typeof decoded.sub !== 'string') {
    throw new Error('Malformed access token payload');
  }
  return decoded as AccessTokenPayload;
};

export const verifyRefreshToken = (token: string): RefreshTokenPayload => {
  const decoded = jwt.verify(token, env.JWT_REFRESH_SECRET);
  if (
    typeof decoded === 'string' ||
    typeof decoded.sub !== 'string' ||
    typeof decoded.jti !== 'string'
  ) {
    throw new Error('Malformed refresh token payload');
  }
  return decoded as RefreshTokenPayload;
};
