export class AppError extends Error {
  public readonly status: number;
  public readonly code: string;
  public readonly details?: unknown;

  constructor(opts: { status: number; code: string; message: string; details?: unknown }) {
    super(opts.message);
    this.name = 'AppError';
    this.status = opts.status;
    this.code = opts.code;
    this.details = opts.details;
  }
}
