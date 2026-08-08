import { create } from 'zustand';

type ConnectorType = string;
type ConnectorId = string;
interface FormData {
  [key: string]: unknown;
}

interface ConnectorFormState {
  formsData: {
    [connectorType: string]: {
      [connectorId: string]: FormData;
    };
  };
  setConnectorFormData: (
    connectorType: ConnectorType,
    connectorId: ConnectorId,
    data: FormData,
  ) => void;
  getConnectorFormData: (connectorType: ConnectorType, connectorId: ConnectorId) => FormData | null;
  resetConnectorFormData: (connectorType: ConnectorType, connectorId: ConnectorId) => void;
  resetAllFormData: () => void;
}

const useConnectorFormStore = create<ConnectorFormState>((set, get) => ({
  formsData: {},

  setConnectorFormData: (connectorType, connectorId, data) =>
    set((state) => ({
      formsData: {
        ...state.formsData,
        [connectorType]: {
          ...state.formsData[connectorType],
          [connectorId]: data,
        },
      },
    })),

  getConnectorFormData: (connectorType, connectorId) => {
    const state = get();
    return state.formsData[connectorType]?.[connectorId] ?? null;
  },

  resetConnectorFormData: (connectorType, connectorId) =>
    set((state) => {
      if (!state.formsData[connectorType]) return state;
      const remainingConnectorData = Object.fromEntries(
        Object.entries(state.formsData[connectorType] || {}).filter(([key]) => key !== connectorId),
      );
      return {
        formsData: {
          ...state.formsData,
          [connectorType]: remainingConnectorData,
        },
      };
    }),

  resetAllFormData: () => set(() => ({ formsData: {} })),
}));

export default useConnectorFormStore;
