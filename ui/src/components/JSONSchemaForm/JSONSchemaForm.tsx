import { useEffect } from 'react';
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
import useConnectorFormStore from '@/stores/useConnectorFormStore';

type JSONSchemaFormProps = {
  schema: RJSFSchema;
  uiSchema: Record<string, string>;
  onSubmit: (formData: FormData) => void;
  onChange?: (formData: FormData) => void;
  children?: JSX.Element;
  formData?: unknown;
  connectorId?: string;
  connectorType: string;
};

const JSONSchemaForm = ({
  schema,
  uiSchema,
  onSubmit,
  onChange,
  children,
  formData,
  connectorId,
  connectorType,
}: JSONSchemaFormProps): JSX.Element => {
  const { getConnectorFormData, setConnectorFormData, resetConnectorFormData } =
    useConnectorFormStore();
  const currentFormData = connectorId ? getConnectorFormData(connectorType, connectorId) : formData;

  const templateOverrides: FormProps<any, RJSFSchema, any>['templates'] = {
    ObjectFieldTemplate: ObjectFieldTemplate,
    TitleFieldTemplate: TitleFieldTemplate,
    FieldTemplate: FieldTemplate,
    BaseInputTemplate: BaseInputTemplate,
    DescriptionFieldTemplate: DescriptionFieldTemplate,
    WrapIfAdditionalTemplate: WrapIfAdditionalTemplate,
  };

  const handleFormChange = (data: any) => {
    const updatedFormData = data.formData;
    connectorId && setConnectorFormData(connectorType, connectorId, updatedFormData);
    onChange?.(updatedFormData);
  };

  useEffect(() => {
    const handleBeforeUnload = () => {
      connectorId && resetConnectorFormData(connectorType, connectorId);
    };
    window.addEventListener('beforeunload', handleBeforeUnload);

    return () => {
      window.removeEventListener('beforeunload', handleBeforeUnload);
    };
  }, [connectorType, connectorId, resetConnectorFormData]);

  return (
    <Form
      uiSchema={uiSchema}
      schema={schema}
      validator={validator}
      templates={templateOverrides}
      formData={currentFormData}
      onSubmit={({ formData }) => {
        onSubmit(formData);
        connectorId && resetConnectorFormData(connectorType, connectorId);
      }}
      onChange={handleFormChange}
    >
      {children}
    </Form>
  );
};

export default JSONSchemaForm;
