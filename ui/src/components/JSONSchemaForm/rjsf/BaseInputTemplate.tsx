import { ChangeEvent, FocusEvent } from 'react';
import {
  FormControl,
  FormLabel,
  IconButton,
  Input,
  InputGroup,
  InputRightElement,
  Textarea,
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

  // Create a mock input event from a value
  const createInputEvent = (value: string): ChangeEvent<HTMLInputElement> => ({
    target: { value } as HTMLInputElement,
    currentTarget: { value } as HTMLInputElement,
  } as ChangeEvent<HTMLInputElement>);

  // Create type-safe handlers for input
  const handleInputEvents = {
    onChange: (e: ChangeEvent<HTMLInputElement>) => {
      const value = e.target.value;
      if (onChangeOverride) {
        onChangeOverride(e);
      } else {
        onChange(value === '' ? options.emptyValue : value);
      }
    },
    onBlur: (e: FocusEvent<HTMLInputElement>) => onBlur(id, e.target.value),
    onFocus: (e: FocusEvent<HTMLInputElement>) => onFocus(id, e.target.value),
  };

  // Create type-safe handlers for textarea
  const handleTextareaEvents = {
    onChange: (e: ChangeEvent<HTMLTextAreaElement>) => {
      const value = e.target.value;
      if (onChangeOverride) {
        // Create a mock input event for onChangeOverride
        onChangeOverride(createInputEvent(value));
      } else {
        onChange(value === '' ? options.emptyValue : value);
      }
    },
    onBlur: (e: FocusEvent<HTMLTextAreaElement>) => onBlur(id, e.target.value),
    onFocus: (e: FocusEvent<HTMLTextAreaElement>) => onFocus(id, e.target.value),
  };

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
        {(schema.type === 'string' && (schema.format === 'private-key' || id.endsWith('private_key'))) ? (
          <Textarea
            id={id}
            name={id}
            value={value || value === 0 ? value : ''}
            onChange={handleTextareaEvents.onChange}
            onBlur={handleTextareaEvents.onBlur}
            onFocus={handleTextareaEvents.onFocus}
            autoFocus={autofocus}
            placeholder={placeholder}
            {...inputProps}
            rows={5}
            whiteSpace="pre"
            bg="white"
            fontFamily="mono"
          />
        ) : (
          <InputGroup>
            <Input
              id={id}
              name={id}
              value={value || value === 0 ? value : ''}
              onChange={handleInputEvents.onChange}
              onBlur={handleInputEvents.onBlur}
              onFocus={handleInputEvents.onFocus}
              autoFocus={autofocus}
              placeholder={placeholder}
              {...inputProps}
              type={inputProps.type === 'text' ? 'text' : isOpen ? 'text' : 'password'}
              list={schema.examples ? examplesId<T>(id) : undefined}
              aria-describedby={ariaDescribedByIds<T>(id, !!schema.examples)}
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
        )}
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
