import { create } from 'zustand';

type Store = {
  workspaceId: number;
  setActiveWorkspaceId: (workspaceId: number) => void;
};

const useStore = create<Store>()((set) => ({
  workspaceId: 0,
  setActiveWorkspaceId: (workspaceId) => set({ workspaceId: workspaceId }),
}));

export { useStore };
