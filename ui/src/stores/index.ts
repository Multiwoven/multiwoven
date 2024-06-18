import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

type Store = {
  workspaceId: number;
  setActiveWorkspaceId: (workspaceId: number) => void;
  clearState: () => void;
};

const useStore = create<Store>()(
  persist(
    (set) => ({
      workspaceId: 0,
      setActiveWorkspaceId: (workspaceId: number) => set({ workspaceId }),
      clearState: () => {
        set({ workspaceId: 0 }); // Reset state
        createJSONStorage(() => localStorage)?.removeItem('workspace-config'); // Clear from localStorage
      },
    }),
    {
      name: 'workspace-config-ce',
    },
  ),
);

export { useStore };
