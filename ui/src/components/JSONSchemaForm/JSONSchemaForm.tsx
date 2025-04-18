import Form from '@rjsf/chakra-ui';
import { RJSFSchema } from '@rjsf/utils';
import validator from '@rjsf/validator-ajv8';

import ObjectFieldTemplate from '@/components/JSONSchemaForm/rjsf/ObjectFieldTemplate';
import TitleFieldTemplate from '@/components/JSONSchemaForm/rjsf/TitleFieldTemplate';
import FieldTemplate from '@/components/JSONSchemaForm/rjsf/FieldTemplate';
import BaseInputTemplate from '@/components/JSONSchemaForm/rjsf/BaseInputTemplate';
import DescriptionFieldTemplate from '@/components/JSONSchemaForm/rjsf/DescriptionFieldTemplate';
import { FormProps } from '@rjsf/core';
import WrapIfAdditionalTemplate from './rjsf/WrapIfAdditionalTemplate';

type JSONSchemaFormProps = {
  schema: RJSFSchema;
  uiSchema: Record<string, string>;
  onSubmit: (formData: FormData) => void;
  onChange?: (formData: FormData) => void;
  children?: JSX.Element;
  formData?: unknown;
};

const JSONSchemaForm = ({
  schema,
  uiSchema,
  onSubmit,
  onChange,
  children,
  formData,
}: JSONSchemaFormProps): JSX.Element => {
  const templateOverrides: FormProps<any, RJSFSchema, any>['templates'] = {
    ObjectFieldTemplate: ObjectFieldTemplate,
    TitleFieldTemplate: TitleFieldTemplate,
    FieldTemplate: FieldTemplate,
    BaseInputTemplate: BaseInputTemplate,
    DescriptionFieldTemplate: DescriptionFieldTemplate,
    WrapIfAdditionalTemplate: WrapIfAdditionalTemplate,
  };
  return (
    <Form
      uiSchema={uiSchema}
      schema={schema}
      validator={validator}
      templates={templateOverrides}
      formData={formData}
      onSubmit={({ formData }) => {
        console.log('JSONSchemaForm onSubmit received:', formData);
        // Convert the form data to a proper object before passing it to onSubmit
        const processedData = new FormData();
        // Add all properties from formData to the FormData object
        if (formData && typeof formData === 'object') {
          Object.entries(formData).forEach(([key, value]) => {
            processedData.append(key, value as string);
          });
        }
        onSubmit(processedData);
      }}
      onChange={({ formData }) => onChange?.(formData as any)}
    >
      {children}
    </Form>
  );
};

export default JSONSchemaForm;
