export type Form = {
  step: number;
  data: unknown;
  stepKey: string;
};

export type FormState = {
  currentStep: number;
  currentForm: unknown | null;
  forms: Form[];
};

export type Step = {
  formKey: string;
  name: string;
  component: JSX.Element;
};

export type SteppedForm = {
  steps: Step[];
};

export type FormAction = {
  type: string;
  payload: {
    step?: number;
    data?: unknown;
    stepKey?: string;
  } | null;
};

export type FormContextType = {
  state: FormState;
  dispatch: React.Dispatch<FormAction>;
};
