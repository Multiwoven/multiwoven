import { create } from 'zustand';
import { persist } from 'zustand/middleware';

type SelectedSync = {
  syncName?: string;
  sourceName?: string;
  sourceIcon?: string;
  destinationName?: string;
  destinationIcon?: string;
};

type SyncStore = {
  selectedSync: SelectedSync;
  setSelectedSync: (args: SelectedSync) => void;
};

const useSyncStore = create<SyncStore>()(
  persist(
    (set) => ({
      selectedSync: {
        syncName: '',
        sourceName: '',
        sourceIcon: '',
        destinationName: '',
        destinationIcon: '',
      },
      setSelectedSync: (args: SelectedSync) => set({ selectedSync: args }),
    }),
    {
      name: 'selected-sync',
    },
  ),
);

export { useSyncStore };
