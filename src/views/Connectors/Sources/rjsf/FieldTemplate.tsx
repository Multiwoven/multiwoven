import {
  FieldTemplateProps,
  FormContextType,
  getTemplate,
  getUiOptions,
  RJSFSchema,
  StrictRJSFSchema,
} from '@rjsf/utils';
import { FormControl } from '@chakra-ui/react';

export default function FieldTemplate<
  T = unknown,
  S extends StrictRJSFSchema = RJSFSchema,
  F extends FormContextType = any
>(props: FieldTemplateProps<T, S, F>) {
  const {
    id,
    children,
    classNames,
    style,
    disabled,
    hidden,
    label,
    onDropPropertyClick,
    onKeyChange,
    readonly,
    registry,
    required,
    rawErrors = [],
    errors,
    help,
    schema,
    uiSchema,
  } = props;
  const uiOptions = getUiOptions<T, S, F>(uiSchema);
  const WrapIfAdditionalTemplate = getTemplate<'WrapIfAdditionalTemplate', T, S, F>(
    'WrapIfAdditionalTemplate',
    registry,
    uiOptions
  );

  if (hidden) {
    return <div style={{ display: 'none' }}>{children}</div>;
  }
  
  const patchedStyle = {
    ...style,
    display: "flex",
    flexDirection: "column",
    justifyContent: "space-between",
    flexGrow: 1,
  }
  
  return (
    <WrapIfAdditionalTemplate
      classNames={classNames}
      style={patchedStyle}
      disabled={disabled}
      id={id}
      label={label}
      onDropPropertyClick={onDropPropertyClick}
      onKeyChange={onKeyChange}
      readonly={readonly}
      required={required}
      schema={schema}
      uiSchema={uiSchema}
      registry={registry}
    >
      <FormControl isRequired={required} isInvalid={rawErrors && rawErrors.length > 0} display="flex" flexDirection="column" flexGrow={1}>
        {children}
        {errors}
        {help}
      </FormControl>
    </WrapIfAdditionalTemplate>
  );
}