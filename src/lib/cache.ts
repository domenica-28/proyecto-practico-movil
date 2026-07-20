type CacheItem<T> = {
  data: T
  expiry: number
}

const cacheStore = new Map<string, CacheItem<any>>()

export const memoryCache = {
  get: <T>(key: string): T | null => {
    const item = cacheStore.get(key)
    if (!item) return null

    if (Date.now() > item.expiry) {
      cacheStore.delete(key)
      return null
    }

    return item.data as T
  },

  set: <T>(key: string, data: T, ttlSeconds: number = 60): void => {
    const expiry = Date.now() + ttlSeconds * 1000
    cacheStore.set(key, { data, expiry })
  },

  clear: (key: string): void => {
    cacheStore.delete(key)
  },
}