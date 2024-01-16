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
