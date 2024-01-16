import { Form } from "./types";

type updateFormDataForStep = {
  forms: Form[];
  step?: number;
  data?: unknown;
};

export const updateFormDataForStep = ({
  forms,
  step,
  data,
}: updateFormDataForStep): Form[] => {
  if (!step && step !== 0) return forms;

  if (forms?.[step]) {
    const newFormData = [...forms];
    newFormData[step] = { step, data };
    return newFormData;
  }
  return [...forms, { step, data }];
};
