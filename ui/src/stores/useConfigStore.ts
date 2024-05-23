import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export type Config = {
  apiHost: string;
  logoUrl: string;
};

type ConfigStore = {
  configs: Config;
  setConfigs: (configs: Partial<Config>) => void;
};

const useConfigStore = create<ConfigStore>()(
  persist(
    (set, get) => ({
      configs: {
        apiHost: '',
        logoUrl: '',
      },
      setConfigs: (args) => set({ configs: { ...get().configs, ...args } }),
    }),
    {
      name: 'env-configs-ce',
    },
  ),
);

export { useConfigStore };
