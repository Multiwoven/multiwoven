import { useEffect } from 'react';
import { Box, Button, Text } from '@chakra-ui/react';
import { createContext, useReducer } from 'react';
import { FormAction, FormContextType, FormState, SteppedForm as SteppedFormType } from './types';
import { updateFormDataForStep } from './utils';
import { useNavigate, useLocation, createSearchParams, useSearchParams } from 'react-router-dom';
import ExitModal from '../ExitModal';
import { useUiConfig } from '@/utils/hooks';
import ContentContainer from '../ContentContainer';

const initialState: FormState = {
  currentStep: 0,
  currentForm: null,
  forms: [],
};

const reducer = (state: FormState, action: FormAction) => {
  switch (action.type) {
    case 'NEXT_STEP':
      return {
        ...state,
        currentStep: state.currentStep + 1,
      };
    case 'UPDATE_FORM': {
      const { payload } = action;
      const newFormData = updateFormDataForStep({
        forms: state.forms,
        step: payload?.step,
        data: payload?.data ?? null,
        stepKey: payload?.stepKey,
      });
      return {
        ...state,
        forms: newFormData,
      };
    }
    case 'UPDATE_CURRENT_FORM': {
      const { payload } = action;
      return {
        ...state,
        currentForm: payload?.stepKey ? { [payload?.stepKey]: payload?.data } : null,
      };
    }
    case 'UPDATE_STEP': {
      const { payload } = action;
      return {
        ...state,
        currentStep: payload?.step || 0,
      };
    }
    default:
      return state;
  }
};

export const SteppedFormContext = createContext<FormContextType>({
  state: initialState,
  dispatch: () => {},
  stepInfo: null,
  handleMoveForward: () => {},
});

const SteppedForm = ({ steps }: SteppedFormType): JSX.Element => {
  const navigate = useNavigate();
  const location = useLocation();
  const [state, dispatch] = useReducer(reducer, initialState);
  const { currentStep, currentForm, forms } = state;
  const [searchParams, setSearchParams] = useSearchParams();
  const step = searchParams.get('step');
  const stepInfo = steps[state.currentStep];
  const { maxContentWidth } = useUiConfig();

  useEffect(() => {
    if (!step || forms.length === 0) {
      const params = {
        step: '0',
      };

      setSearchParams(params, { replace: true });
    }
  }, []);

  useEffect(() => {
    if (step) {
      dispatch({
        type: 'UPDATE_STEP',
        payload: {
          step: parseInt(step),
        },
      });
    }
  }, [step]);

  const handleMoveForward = (stepKey: string, data?: unknown) => {
    const currentFormData = currentForm;
    let isValidated = true;

    if (stepInfo?.beforeNextStep) {
      isValidated = stepInfo.beforeNextStep();
    }

    if (!isValidated) return;

    dispatch({
      type: 'UPDATE_FORM',
      payload: {
        step: currentStep,
        data: currentFormData ?? { [stepKey]: data },
        stepKey,
      },
    });

    dispatch({
      type: 'UPDATE_CURRENT_FORM',
      payload: {
        data: null,
      },
    });

    navigate({
      pathname: location.pathname,
      search: createSearchParams({
        step: `${currentStep + 1}`,
      }).toString(),
    });
  };

  const valuesToExpose: FormContextType = {
    state,
    stepInfo,
    dispatch,
    handleMoveForward,
  };

  return (
    <SteppedFormContext.Provider value={valuesToExpose}>
      <Box width='100%'>
        <Box
          width='100%'
          borderBottomWidth='thin'
          display='flex'
          justifyContent='center'
          borderBottom='1px'
          borderColor='gray.400'
        >
          <Box
            display='flex'
            justifyContent='space-between'
            alignItems='center'
            maxWidth={maxContentWidth}
            width='100%'
          >
            <ContentContainer>
              <Box display='flex' justifyContent='space-between' alignItems='center' width='100%'>
                <Box>
                  <Text size='xs' color='gray.600' letterSpacing={2.4} fontWeight={700}>
                    STEP {currentStep + 1} OF {steps.length}
                  </Text>
                  <Text
                    fontWeight={700}
                    color='black.500'
                    size='lg'
                    letterSpacing={-0.18}
                    marginTop='4px'
                  >
                    {stepInfo.name}
                  </Text>
                </Box>
                <Box>
                  <ExitModal />
                </Box>
              </Box>
            </ContentContainer>
          </Box>
        </Box>
        {stepInfo.component}
        {stepInfo.isRequireContinueCta ? (
          <Box padding='10px' display='flex' justifyContent='center'>
            <Box maxWidth={maxContentWidth} width='100%'>
              <Button onClick={() => handleMoveForward(stepInfo.formKey)}>Continue</Button>
            </Box>
          </Box>
        ) : null}
      </Box>
    </SteppedFormContext.Provider>
  );
};

export default SteppedForm;
