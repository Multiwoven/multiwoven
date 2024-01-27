import {
	ExtractedData,
	StepData,
} from "@/views/Models/ModelsForm/DefineModel/DefineSQL/types";
import { Form } from "@/components/SteppedForm/types";

export function extractData(steps: StepData[]): ExtractedData[] {
	return steps
		.map((step) => {
			if (step.stepKey === "datasource" && step.data.datasource) {
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


export function extractDataByKey(forms: Form[], key: string): unknown[] {
    return forms
      .filter(form => form.stepKey === key && form.data !== null)
      .map(form => form.data ? form.data[key] : null)
      .filter(data => data !== undefined);
  }