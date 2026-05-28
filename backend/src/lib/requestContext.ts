import { AsyncLocalStorage } from 'node:async_hooks';

export interface RequestContext {
  requestId?: string;
  actorId?: string;
}

const storage = new AsyncLocalStorage<RequestContext>();

export const requestContext = {
  run<T>(ctx: RequestContext, fn: () => T): T {
    return storage.run(ctx, fn);
  },
  get(): RequestContext | undefined {
    return storage.getStore();
  },
  getActorId(): string | undefined {
    return storage.getStore()?.actorId;
  },
  setActor(actorId: string): void {
    const store = storage.getStore();
    if (store) store.actorId = actorId;
  },
};
