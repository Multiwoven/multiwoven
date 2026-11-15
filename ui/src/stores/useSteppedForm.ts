import { Form, Step } from '@/components/SteppedForm/types';
import { updateFormDataForStep } from '@/components/SteppedForm/utils';
import { create } from 'zustand';

type SteppedFormStore = {
  forms: Form[];
  currentStep: number;
  steps: Step[];
  baseSteps: Step[];
  stepInfo: Step | null;
  connectorFormData: Record<string, Record<string, unknown>>;
  setSteps: (steps: Step[]) => void;
  setBaseSteps: (steps: Step[]) => void;
  updateStep: (step: number) => void;
  resetForms: () => void;
  handleMoveForward: (formKey: string, form: unknown) => void;
  handleMoveBack: (formKey: string, form: unknown) => void;
  removeStep: (index: number) => void;
  addStep: (step: Step, atIndex: number, noOfStepsToSplice: number) => void;
  setSearchParamsUpdater: (fn: (step: number) => void) => void;
  saveConnectorFormData: (connectorName: string, stepKey: string, formData: unknown) => void;
  setSearchParamsExternal?: (step: number) => void;
};

const DEFAULT_STORE = {
  forms: [],
  currentStep: 0,
  isCurrentStepValid: false,
  steps: [],
  baseSteps: [],
  connectorFormData: {},
};

const useSteppedForm = create<SteppedFormStore>()((set, get) => ({
  ...DEFAULT_STORE,
  stepInfo: get()?.steps?.[get().currentStep] ?? null,
  setSteps: (steps: Step[]) => set({ steps, stepInfo: steps?.[0] ?? null, forms: [] }),
  setBaseSteps: (steps: Step[]) => set({ baseSteps: steps }),

  updateStep: (step: number) => set({ currentStep: step, stepInfo: get().steps?.[step] ?? null }),
  resetForms: () =>
    set({ forms: [], stepInfo: null, currentStep: 0, steps: [], connectorFormData: {} }),
  handleMoveForward: (stepKey: string, form?: unknown) => {
    get().setSearchParamsExternal?.(get().currentStep + 1);
    return set({
      forms: updateFormDataForStep({
        forms: get().forms,
        step: get().currentStep,
        data: { [stepKey]: form },
        stepKey: stepKey,
      }),
      currentStep: get().currentStep + 1,
      stepInfo: get().steps?.[get().currentStep + 1] ?? null,
    });
  },
  handleMoveBack: (stepKey: string, form?: unknown) => {
    get().setSearchParamsExternal?.(get().currentStep - 1);
    return set({
      forms: updateFormDataForStep({
        forms: get().forms,
        step: get().currentStep,
        data: { [stepKey]: form },
        stepKey: stepKey,
      }),
      currentStep: get().currentStep - 1,
      stepInfo: get().steps?.[get().currentStep - 1] ?? null,
    });
  },
  removeStep: (index: number) => {
    const _steps = [...get().steps];
    _steps.splice(index, 1);
    set({ steps: _steps });
  },
  addStep: (step: Step, atIndex: number, noOfStepsToSplice: number = 0) => {
    const _steps = [...get().steps];
    _steps.splice(atIndex, noOfStepsToSplice, step);
    set({ steps: _steps });
  },
  setSearchParamsUpdater: (fn: (step: number) => void) => set({ setSearchParamsExternal: fn }),
  saveConnectorFormData: (connectorName: string, stepKey: string, formData: unknown) => {
    const currentData = get().connectorFormData;
    set({
      connectorFormData: {
        ...currentData,
        [connectorName]: {
          ...currentData[connectorName],
          [stepKey]: formData,
        },
      },
    });
  },
}));

export default useSteppedForm;
