import { useState } from 'react';
import {
  Box,
  Button,
  Checkbox,
  Flex,
  FormControl,
  FormHelperText,
  FormLabel,
  Icon,
  Input,
  Radio,
  RadioGroup,
  Select,
  Switch,
  Text,
} from '@chakra-ui/react';
import { FiArrowLeft, FiArrowRight, FiCheck, FiX } from 'react-icons/fi';

import type {
  ClarificationAnswer,
  ClarificationInputType,
  ClarificationQuestion,
  FormField,
  P2WEventItem,
} from '../p2wTypes';

const CUSTOM_INPUT_VALUE = 'custom-input';

type StepAnswer = string | string[] | Record<string, unknown>;

interface ClarificationEventRowProps {
  item: P2WEventItem;
  isLoading?: boolean;
  onAnswer?: (clarificationId: string, answer: ClarificationAnswer) => void;
  onReject?: (clarificationId: string) => void;
}

// ── Pure helpers ───────────────────────────────────────────────────────────────

function buildDefaultFormValues(fields: FormField[]): Record<string, string> {
  return Object.fromEntries(fields.map((f) => [f.name, String(f.default ?? '')]));
}

function coerceFormValues(
  fields: FormField[],
  raw: Record<string, string>,
): Record<string, unknown> {
  return Object.fromEntries(
    fields.map((f) => {
      const v = raw[f.name] ?? '';
      if (f.type === 'boolean') return [f.name, v === 'true'];
      if (f.type === 'number') return [f.name, v === '' ? '' : Number(v)];
      return [f.name, v];
    }),
  );
}

function isAnswered(
  inputType: ClarificationInputType,
  textValue: string,
  selectedOpt: string,
  selectedOpts: string[],
  formValues: Record<string, string>,
  fields?: FormField[],
): boolean {
  switch (inputType) {
    case 'multiple_option':
      return selectedOpts.length > 0;
    case 'form_input':
      return (fields ?? [])
        .filter((f) => f.required)
        .every((f) => (formValues[f.name] ?? '').trim() !== '');
    case 'select':
      return !!(selectedOpt && (selectedOpt !== CUSTOM_INPUT_VALUE || textValue.trim()));
    case 'single_option':
      return !!selectedOpt;
    default: // text | password
      return textValue.trim() !== '';
  }
}

// ── Component ──────────────────────────────────────────────────────────────────

const ClarificationEventRow = ({
  item,
  isLoading,
  onAnswer,
  onReject,
}: ClarificationEventRowProps) => {
  // Per-step editing state (reset/restored on wizard navigation)
  const [textValue, setTextValue] = useState('');
  const [selectedOpt, setSelectedOpt] = useState('');
  const [selectedOpts, setSelectedOpts] = useState<string[]>([]);
  const [formValues, setFormValues] = useState<Record<string, string>>(() => {
    const firstStep = item.clarificationQuestions?.[0];
    const fields =
      (firstStep?.inputType === 'form_input' ? firstStep.fields : undefined) ??
      (item.clarificationInputType === 'form_input' ? item.clarificationFields : undefined);
    return fields ? buildDefaultFormValues(fields) : {};
  });

  // Wizard state
  const [currentStep, setCurrentStep] = useState(0);
  const [wizardAnswers, setWizardAnswers] = useState<Record<number, StepAnswer>>({});

  // ── Terminal states ──────────────────────────────────────────────────────────

  if (item.status === 'resolved') {
    return (
      <Flex align='center' gap='8px' my='4px'>
        <Icon as={FiCheck} color='gray.600' h='14px' w='14px' />
        <Text size='sm' color='gray.600' fontWeight={400}>
          Question answered
        </Text>
      </Flex>
    );
  }

  if (item.status === 'failed') {
    return (
      <Flex align='center' gap='8px' my='4px'>
        <Icon as={FiX} color='error.500' h='14px' w='14px' />
        <Text size='sm' color='gray.600' fontWeight={400}>
          Execution stopped
        </Text>
      </Flex>
    );
  }

  // ── Step helpers ─────────────────────────────────────────────────────────────

  const captureStepAnswer = (step: ClarificationQuestion): StepAnswer => {
    switch (step.inputType) {
      case 'multiple_option':
        return selectedOpts;
      case 'form_input':
        return coerceFormValues(step.fields ?? [], formValues);
      case 'select':
        return selectedOpt === CUSTOM_INPUT_VALUE ? textValue : selectedOpt;
      default:
        return textValue || selectedOpt;
    }
  };

  const restoreStepState = (step: ClarificationQuestion, saved?: ClarificationAnswer) => {
    if (saved === undefined) {
      setTextValue('');
      setSelectedOpt('');
      setSelectedOpts([]);
      setFormValues(step.fields ? buildDefaultFormValues(step.fields) : {});
      return;
    }
    switch (step.inputType) {
      case 'multiple_option':
        setSelectedOpts(Array.isArray(saved) ? (saved as string[]) : []);
        break;
      case 'form_input':
        setFormValues(
          typeof saved === 'object' && !Array.isArray(saved)
            ? (saved as Record<string, string>)
            : {},
        );
        break;
      default: {
        const str = typeof saved === 'string' ? saved : '';
        setTextValue(str);
        setSelectedOpt(str);
      }
    }
  };

  // ── Event handlers ───────────────────────────────────────────────────────────

  const handleReject = () => {
    if (!item.clarificationId) return;
    onReject?.(item.clarificationId);
  };

  const handleSingleSubmit = () => {
    if (!item.clarificationId) return;
    const inputType = item.clarificationInputType ?? 'text';
    let answer: ClarificationAnswer;
    switch (inputType) {
      case 'multiple_option':
        answer = selectedOpts;
        break;
      case 'form_input':
        answer = coerceFormValues(item.clarificationFields ?? [], formValues);
        break;
      case 'select':
        answer = selectedOpt === CUSTOM_INPUT_VALUE ? textValue : selectedOpt;
        break;
      default:
        answer = textValue || selectedOpt;
    }
    onAnswer?.(item.clarificationId, answer);
  };

  const questions = item.clarificationQuestions ?? [];

  const handleWizardAdvance = () => {
    const step = questions[currentStep];
    const answer = captureStepAnswer(step);
    const next = { ...wizardAnswers, [currentStep]: answer };
    setWizardAnswers(next);

    const nextIdx = currentStep + 1;
    if (nextIdx < questions.length) {
      restoreStepState(questions[nextIdx], next[nextIdx]);
      setCurrentStep(nextIdx);
    } else {
      if (!item.clarificationId) return;
      onAnswer?.(
        item.clarificationId,
        questions.map((_, i) => next[i]),
      );
    }
  };

  const handleWizardBack = () => {
    const step = questions[currentStep];
    const answer = captureStepAnswer(step);
    const next = { ...wizardAnswers, [currentStep]: answer };
    setWizardAnswers(next);

    const prevIdx = currentStep - 1;
    restoreStepState(questions[prevIdx], next[prevIdx]);
    setCurrentStep(prevIdx);
  };

  // ── Input body renderers ─────────────────────────────────────────────────────

  const renderTextInput = (sensitive: boolean, onEnterSubmit: () => void) => (
    <Box padding='12px'>
      <Input
        value={textValue}
        onChange={(e) => setTextValue(e.target.value)}
        type={sensitive ? 'password' : 'text'}
        placeholder='Type your answer'
        size='sm'
        borderColor='gray.500'
        bg='white'
        height='40px'
        onKeyDown={(e) => {
          if ((e.key === 'Enter' && e.metaKey) || (e.key === 'Enter' && e.ctrlKey)) {
            onEnterSubmit();
          }
        }}
      />
    </Box>
  );

  const renderSelectInput = (
    options: string[],
    sensitive: boolean,
    allowCustom: boolean,
    onEnterSubmit: () => void,
  ) => (
    <RadioGroup
      data-testid='clarification-options'
      onChange={(v) => {
        setTextValue('');
        setSelectedOpt(v);
      }}
      value={selectedOpt}
      width='100%'
    >
      {options.map((option) => (
        <Box
          key={`${option}-clarification-option`}
          data-testid='clarification-option'
          width='100%'
          borderTop='1px solid'
          borderColor='gray.400'
          padding='12px'
          _hover={{ bgColor: 'gray.200' }}
        >
          <Radio
            value={option}
            size='sm'
            width='100%'
            colorScheme='gray.400'
            _hover={{ borderColor: 'gray.600' }}
          >
            {option}
          </Radio>
        </Box>
      ))}
      {allowCustom && (
        <Flex
          width='100%'
          borderTop='1px solid'
          borderColor='gray.400'
          padding='12px'
          gap='8px'
          _hover={{ bgColor: 'gray.200' }}
        >
          <Radio value={CUSTOM_INPUT_VALUE} size='sm' />
          <Input
            value={textValue}
            onChange={(e) => {
              setTextValue(e.target.value);
              if (e.target.value && selectedOpt !== CUSTOM_INPUT_VALUE) {
                setSelectedOpt(CUSTOM_INPUT_VALUE);
              }
            }}
            onFocus={() => setSelectedOpt(CUSTOM_INPUT_VALUE)}
            type={sensitive ? 'password' : 'text'}
            placeholder='Type your own answer'
            size='sm'
            borderColor='gray.500'
            bg='white'
            width='100%'
            height='40px'
            onKeyDown={(e) => {
              if ((e.key === 'Enter' && e.metaKey) || (e.key === 'Enter' && e.ctrlKey)) {
                onEnterSubmit();
              }
            }}
          />
        </Flex>
      )}
    </RadioGroup>
  );

  const renderMultipleOptionInput = (options: string[]) => (
    <Flex flexDir='column' data-testid='clarification-options'>
      {options.map((option) => (
        <Box
          key={`${option}-clarification-option`}
          data-testid='clarification-option'
          width='100%'
          borderTop='1px solid'
          borderColor='gray.400'
          padding='12px'
          _hover={{ bgColor: 'gray.200' }}
        >
          <Checkbox
            isChecked={selectedOpts.includes(option)}
            onChange={(e) =>
              setSelectedOpts((prev) =>
                e.target.checked ? [...prev, option] : prev.filter((o) => o !== option),
              )
            }
            size='sm'
            colorScheme='gray'
          >
            {option}
          </Checkbox>
        </Box>
      ))}
    </Flex>
  );

  const renderFormInput = (fields: FormField[]) => (
    <Flex flexDir='column' gap='10px' padding='12px'>
      {fields.map((field) => (
        <FormControl key={field.name} isRequired={field.required}>
          <FormLabel fontSize='sm' mb='2px'>
            {field.label}
          </FormLabel>
          {field.type === 'boolean' ? (
            <>
              <Switch
                isChecked={formValues[field.name] === 'true'}
                onChange={(e) =>
                  setFormValues((prev) => ({ ...prev, [field.name]: String(e.target.checked) }))
                }
                size='sm'
              />
              {field.hint && <FormHelperText fontSize='xs'>{field.hint}</FormHelperText>}
            </>
          ) : field.type === 'select' && field.options ? (
            <>
              <Select
                value={formValues[field.name] ?? ''}
                onChange={(e) =>
                  setFormValues((prev) => ({ ...prev, [field.name]: e.target.value }))
                }
                size='sm'
                borderColor='gray.500'
                bg='white'
              >
                <option value=''>Select…</option>
                {field.options.map((opt) => (
                  <option key={opt} value={opt}>
                    {opt}
                  </option>
                ))}
              </Select>
              {field.hint && <FormHelperText fontSize='xs'>{field.hint}</FormHelperText>}
            </>
          ) : (
            <Input
              value={formValues[field.name] ?? ''}
              type={
                field.type === 'password' ? 'password' : field.type === 'number' ? 'number' : 'text'
              }
              placeholder={field.hint}
              onChange={(e) => setFormValues((prev) => ({ ...prev, [field.name]: e.target.value }))}
              size='sm'
              borderColor='gray.500'
              bg='white'
              height='32px'
            />
          )}
        </FormControl>
      ))}
    </Flex>
  );

  const renderBody = (
    inputType: ClarificationInputType,
    options: string[],
    fields: FormField[] | undefined,
    sensitive: boolean,
    onEnterSubmit: () => void,
  ) => {
    switch (inputType) {
      case 'form_input':
        return renderFormInput(fields ?? []);
      case 'multiple_option':
        return renderMultipleOptionInput(options);
      case 'single_option':
        return renderSelectInput(options, sensitive, false, onEnterSubmit);
      case 'select':
        return renderSelectInput(options, sensitive, true, onEnterSubmit);
      default: // text | password
        return renderTextInput(sensitive || inputType === 'password', onEnterSubmit);
    }
  };

  // ── Wizard mode ──────────────────────────────────────────────────────────────

  if (questions.length > 0) {
    const stepQuestion = questions[currentStep];
    const isLastStep = currentStep === questions.length - 1;
    const canAdvance = isAnswered(
      stepQuestion.inputType,
      textValue,
      selectedOpt,
      selectedOpts,
      formValues,
      stepQuestion.fields,
    );

    return (
      <Box
        border='1px solid'
        borderColor='gray.400'
        borderRadius='8px'
        bg='gray.100'
        display='flex'
        flexDir='column'
        my='4px'
        overflow='hidden'
      >
        <Flex
          align='flex-start'
          gap='8px'
          paddingY='12px'
          paddingX='20px'
          bg='gray.400'
          flexDir='column'
        >
          {item.clarificationQuestion && (
            <Text size='xs' color='gray.700' fontWeight={400}>
              {item.clarificationQuestion}
            </Text>
          )}
          <Flex
            data-testid='clarification-question'
            justify='space-between'
            align='center'
            width='100%'
          >
            <Text size='sm' color='black.500' fontWeight={600} lineHeight='20px'>
              {stepQuestion.question}
            </Text>
            <Text size='xs' color='gray.600' whiteSpace='nowrap' ml='12px'>
              {currentStep + 1} / {questions.length}
            </Text>
          </Flex>
        </Flex>

        <Flex flexDir='column'>
          {renderBody(
            stepQuestion.inputType,
            stepQuestion.options ?? [],
            stepQuestion.fields,
            stepQuestion.sensitive ?? false,
            handleWizardAdvance,
          )}
        </Flex>

        <Flex justify='flex-end' gap='8px' padding='12px' bgColor='gray.400'>
          <Button
            size='sm'
            variant='outline'
            onClick={handleReject}
            isLoading={isLoading}
            isDisabled={isLoading}
            width='auto'
          >
            Cancel
          </Button>
          {currentStep > 0 && (
            <Button
              size='sm'
              variant='outline'
              onClick={handleWizardBack}
              isDisabled={isLoading}
              width='auto'
              leftIcon={<Icon as={FiArrowLeft} h='12px' w='12px' />}
            >
              Back
            </Button>
          )}
          <Button
            size='sm'
            onClick={handleWizardAdvance}
            isLoading={isLoading}
            isDisabled={isLoading || !canAdvance}
            width='auto'
            rightIcon={!isLastStep ? <Icon as={FiArrowRight} h='12px' w='12px' /> : undefined}
            {...(isLastStep && { 'data-testid': 'clarification-submit-btn' })}
          >
            {isLastStep ? 'Submit' : 'Next'}
          </Button>
        </Flex>
      </Box>
    );
  }

  // ── Single-question mode ─────────────────────────────────────────────────────

  const singleOptions = (item.clarificationOptions ?? []).filter(Boolean);
  const singleInputType = item.clarificationInputType ?? 'text';
  const canSubmit = isAnswered(
    singleInputType,
    textValue,
    selectedOpt,
    selectedOpts,
    formValues,
    item.clarificationFields,
  );

  return (
    <Box
      border='1px solid'
      borderColor='gray.400'
      borderRadius='8px'
      bg='gray.100'
      display='flex'
      flexDir='column'
      my='4px'
      overflow='hidden'
    >
      <Flex
        data-testid='clarification-question'
        align='flex-start'
        gap='8px'
        paddingY='12px'
        paddingX='20px'
        bg='gray.400'
      >
        <Text size='sm' color='black.500' fontWeight={600} lineHeight='20px' letterSpacing='-1%'>
          {item.clarificationQuestion}
        </Text>
      </Flex>

      <Flex flexDir='column'>
        {renderBody(
          singleInputType,
          singleOptions,
          item.clarificationFields,
          item.clarificationSensitive ?? false,
          handleSingleSubmit,
        )}
      </Flex>

      <Flex justify='flex-end' gap='8px' padding='12px' bgColor='gray.400'>
        <Button
          size='sm'
          variant='outline'
          onClick={handleReject}
          isLoading={isLoading}
          isDisabled={isLoading}
          width='auto'
        >
          Reject
        </Button>
        <Button
          data-testid='clarification-submit-btn'
          size='sm'
          onClick={handleSingleSubmit}
          isLoading={isLoading}
          isDisabled={isLoading || !canSubmit}
          width='auto'
        >
          Submit
        </Button>
      </Flex>
    </Box>
  );
};

export default ClarificationEventRow;
