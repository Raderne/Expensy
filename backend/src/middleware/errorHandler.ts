import type { ErrorRequestHandler } from 'express';
import { ZodError } from 'zod';
import { Prisma } from '@prisma/client';
import { AppError } from '../lib/errors.js';
import { logger } from '../lib/logger.js';

interface ProblemDetails {
  type: string;
  title: string;
  status: number;
  detail?: string;
  code?: string;
  errors?: unknown;
}

export const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  let problem: ProblemDetails;

  if (err instanceof AppError) {
    problem = {
      type: `about:blank`,
      title: err.message,
      status: err.status,
      code: err.code,
      detail: err.message,
      ...(err.details ? { errors: err.details } : {}),
    };
  } else if (err instanceof ZodError) {
    problem = {
      type: 'about:blank',
      title: 'Validation failed',
      status: 400,
      code: 'VALIDATION_ERROR',
      errors: err.flatten(),
    };
  } else if (err instanceof Prisma.PrismaClientKnownRequestError) {
    const status = err.code === 'P2025' ? 404 : 409;
    problem = {
      type: 'about:blank',
      title: status === 404 ? 'Not found' : 'Database constraint violated',
      status,
      code: `PRISMA_${err.code}`,
    };
  } else {
    logger.error({ err }, 'Unhandled error');
    problem = {
      type: 'about:blank',
      title: 'Internal Server Error',
      status: 500,
      code: 'INTERNAL_ERROR',
    };
  }

  res.status(problem.status).type('application/problem+json').json(problem);
};
