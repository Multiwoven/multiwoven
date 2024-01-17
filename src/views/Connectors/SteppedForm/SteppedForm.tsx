import { useEffect } from "react";
import { Box, Button, Text } from "@chakra-ui/react";
import { createContext, useReducer } from "react";
import {
  FormAction,
  FormContextType,
  FormState,
  SteppedForm as SteppedFormType,
} from "./types";
import { updateFormDataForStep } from "./utils";
import {
  useNavigate,
  useLocation,
  createSearchParams,
  useSearchParams,
} from "react-router-dom";

const initialState: FormState = {
  currentStep: 0,
  currentForm: null,
  forms: [],
};

const reducer = (state: FormState, action: FormAction) => {
  switch (action.type) {
    case "NEXT_STEP":
      return {
        ...state,
        currentStep: state.currentStep + 1,
      };
    case "UPDATE_FORM": {
      const { payload } = action;
      const newFormData = updateFormDataForStep({
        forms: state.forms,
        step: payload?.step,
        data: payload?.data,
        stepKey: payload?.stepKey,
      });
      return {
        ...state,
        forms: newFormData,
      };
    }
    case "UPDATE_CURRENT_FORM": {
      const { payload } = action;
      return {
        ...state,
        currentForm: payload?.data,
      };
    }
    case "UPDATE_STEP": {
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
});

const SteppedForm = ({ steps }: SteppedFormType): JSX.Element => {
  const navigate = useNavigate();
  const location = useLocation();
  const [state, dispatch] = useReducer(reducer, initialState);
  const { currentStep, currentForm } = state;
  const [searchParams, setSearchParams] = useSearchParams();
  const step = searchParams.get("step");

  useEffect(() => {
    if (!step) {
      const params = {
        step: "0",
      };

      setSearchParams(params, { replace: true });
    }
  }, []);

  useEffect(() => {
    if (step) {
      dispatch({
        type: "UPDATE_STEP",
        payload: {
          step: parseInt(step),
        },
      });
    }
  }, [step]);

  const handleOnContinueClick = (stepKey: string) => {
    dispatch({
      type: "UPDATE_FORM",
      payload: {
        step: currentStep,
        data: currentForm,
        stepKey,
      },
    });

    dispatch({
      type: "UPDATE_CURRENT_FORM",
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

  const stepInfo = steps[state.currentStep];

  return (
    <SteppedFormContext.Provider value={{ state, dispatch }}>
      <Box width="100%">
        <Box width="100%" padding="10px">
          <Box display="flex" justifyContent="space-between">
            <Box>
              <Text fontSize="l" color="gray">
                STEP {currentStep + 1} OF {steps.length}
              </Text>
              <Text fontWeight="bold" fontSize="xl">
                {stepInfo.name}
              </Text>
            </Box>
            <Box>
              <Button variant="outline" size="sm" colorScheme="gray">
                Exit
              </Button>
            </Box>
          </Box>
        </Box>
        {stepInfo.component}
        <Box>
          <Button onClick={() => handleOnContinueClick(stepInfo.formKey)}>
            Continue
          </Button>
        </Box>
      </Box>
    </SteppedFormContext.Provider>
  );
};

export default SteppedForm;
