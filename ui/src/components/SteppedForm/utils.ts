import { Form } from './types';

type updateFormDataForStep = {
  forms: Form[];
  step?: number;
  data: Record<string, unknown> | null;
  stepKey?: string;
};

export const updateFormDataForStep = ({
  forms,
  step,
  data,
  stepKey,
}: updateFormDataForStep): Form[] => {
  if ((!step && step !== 0) || !stepKey) return forms;

  if (forms?.[step]) {
    const newFormData = [...forms];
    newFormData[step] = { step, data, stepKey };
    return newFormData;
  }
  return [...forms, { step, data, stepKey }];
};
