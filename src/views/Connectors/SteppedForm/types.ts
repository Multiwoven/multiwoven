export type Form = {
  step: number;
  data: unknown;
};

export type FormState = {
  currentStep: number;
  currentForm: unknown | null;
  forms: Form[];
};
