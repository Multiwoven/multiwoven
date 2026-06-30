import { ChangeEvent, FocusEvent } from 'react';
import {
  FormControl,
  FormLabel,
  IconButton,
  Input,
  InputGroup,
  InputRightElement,
} from '@chakra-ui/react';
import {
  ariaDescribedByIds,
  BaseInputTemplateProps,
  examplesId,
  labelValue,
  FormContextType,
  getInputProps,
  RJSFSchema,
  StrictRJSFSchema,
  getTemplate,
} from '@rjsf/utils';
import { ChakraUiSchema, getChakra } from '@rjsf/chakra-ui/lib/utils';

import { useDisclosure } from '@chakra-ui/react';
import { FiEye, FiEyeOff } from 'react-icons/fi';

export default function BaseInputTemplate<
  T = unknown,
  S extends StrictRJSFSchema = RJSFSchema,
  F extends FormContextType = any,
>(props: BaseInputTemplateProps<T, S, F>) {
  const {
    id,
    type,
    value,
    label,
    hideLabel,
    schema,
    uiSchema,
    onChange,
    onChangeOverride,
    onBlur,
    onFocus,
    options,
    required,
    readonly,
    rawErrors,
    autofocus,
    placeholder,
    disabled,
    registry,
  } = props;
  const inputProps = getInputProps<T, S, F>(schema, type, options);
  const chakraProps = getChakra({ uiSchema: uiSchema as ChakraUiSchema });

  const _onChange = ({ target: { value } }: ChangeEvent<HTMLInputElement>) =>
    onChange(value === '' ? options.emptyValue : value);
  const _onBlur = ({ target: { value } }: FocusEvent<HTMLInputElement>) => onBlur(id, value);
  const _onFocus = ({ target: { value } }: FocusEvent<HTMLInputElement>) => onFocus(id, value);

  const DescriptionFieldTemplate = getTemplate('DescriptionFieldTemplate', registry, uiSchema);
  const displayLabel = registry.schemaUtils.getDisplayLabel(
    schema,
    uiSchema,
    registry.globalUiOptions,
  );

  const { isOpen, onToggle } = useDisclosure();

  const onClickReveal = () => {
    onToggle();
  };

  return (
    <FormControl
      mb={1}
      {...chakraProps}
      isDisabled={disabled || readonly}
      isRequired={required}
      isReadOnly={readonly}
      isInvalid={rawErrors && rawErrors.length > 0}
      display='flex'
      flexDirection='column'
      justifyContent='space-between'
      flexGrow={1}
    >
      <div>
        {labelValue(
          <FormLabel
            htmlFor={id}
            id={`${id}-label`}
            fontSize='b4'
            letterSpacing='b4'
            fontWeight='semiBold'
            mb={1}
          >
            {label}
          </FormLabel>,
          hideLabel || !label,
        )}

        {displayLabel && schema.description && (
          <DescriptionFieldTemplate
            id={`${id}-description`}
            description={schema.description}
            schema={schema}
            registry={registry}
          />
        )}
      </div>

      <div>
        <InputGroup>
          <Input
            id={id}
            name={id}
            value={value || value === 0 ? value : ''}
            onChange={onChangeOverride || _onChange}
            onBlur={_onBlur}
            onFocus={_onFocus}
            autoFocus={autofocus}
            placeholder={placeholder}
            {...inputProps}
            type={inputProps.type === 'text' ? 'text' : isOpen ? 'text' : 'password'}
            list={schema.examples ? examplesId<T>(id) : undefined}
            aria-describedby={ariaDescribedByIds<T>(id, !!schema.examples)}
<<<<<<< HEAD
=======
            sx={{
              '&::-webkit-calendar-picker-indicator': {
                display: 'none !important',
              },
            }}
            fontSize='sm'
>>>>>>> a030d9bb (refactor(CE): changed font size in JSON Form (#1287))
          />
          {inputProps.type !== 'text' ? (
            <InputRightElement>
              <IconButton
                variant='text'
                aria-label={isOpen ? 'Mask password' : 'Reveal password'}
                icon={isOpen ? <FiEyeOff /> : <FiEye />}
                onClick={onClickReveal}
              />
            </InputRightElement>
          ) : null}
        </InputGroup>
        {Array.isArray(schema.examples) ? (
          <datalist id={examplesId<T>(id)}>
            {(schema.examples as string[])
              .concat(
                schema.default && !schema.examples.includes(schema.default)
                  ? ([schema.default] as string[])
                  : [],
              )
              .map((example: any) => {
                return <option key={example} value={example} />;
              })}
          </datalist>
        ) : null}
      </div>
    </FormControl>
  );
}
