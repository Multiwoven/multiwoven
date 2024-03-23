import { ExtractedData, StepData } from '@/views/Models/ModelsForm/DefineModel/DefineSQL/types';
import { Form } from '@/components/SteppedForm/types';

export function extractData(steps: StepData[]): ExtractedData[] {
  return steps
    .map((step) => {
      if (step.stepKey === 'datasource' && step.data.datasource) {
        return {
          id: step.data.datasource.id,
          icon: step.data.datasource.icon,
          name: step.data.datasource.name,
        };
      } else {
        return {};
      }
    })
    .filter((obj) => Object.keys(obj).length > 0);
}

export function extractDataByKey<T>(forms: Form[], key: string): T {
  return forms.find(({ stepKey }) => stepKey === key) as T;
}
