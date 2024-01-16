import React, { useEffect } from "react";
import { Box, Button } from "@chakra-ui/react";
import { createContext, useReducer } from "react";
import { FormState } from "./types";
import { updateFormDataForStep } from "./utils";

type Step = {
  formKey: string;
  name: string;
  component: JSX.Element;
};

type SteppedForm = {
  steps: Step[];
};

type FormAction = {
  type: string;
  payload: {
    step?: number;
    data?: unknown;
    stepKey?: string;
  } | null;
};

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
    default:
      return state;
  }
};

type FormContextType = {
  state: FormState;
  dispatch: React.Dispatch<FormAction>;
};

export const SteppedFormContext = createContext<FormContextType>({
  state: initialState,
  dispatch: () => {},
});

const SteppedForm = ({ steps }: SteppedForm): JSX.Element => {
  const [state, dispatch] = useReducer(reducer, initialState);
  const { currentStep, currentForm } = state;

  const handleOnContinueClick = (stepKey: string) => {
    dispatch({
      type: "UPDATE_FORM",
      payload: {
        step: currentStep,
        data: currentForm,
        stepKey,
      },
    });
    dispatch({ type: "NEXT_STEP", payload: null });
  };

  useEffect(() => {
    dispatch({
      type: "UPDATE_CURRENT_FORM",
      payload: {
        data: null,
      },
    });
  }, [currentStep]);

  const stepInfo = steps[state.currentStep];

  return (
    <SteppedFormContext.Provider value={{ state, dispatch }}>
      <Box>
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
