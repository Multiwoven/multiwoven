import SteppedForm from "@/components/SteppedForm";

import {
  Box,
  Drawer,
  DrawerBody,
  DrawerContent,
  DrawerOverlay,
} from "@chakra-ui/react";
import { useNavigate } from "react-router-dom";
import SelectModelSourceForm from "./SelectModelSourceForm";
import ModelMethod from "./ModelMethod";
import DefineModel from "./DefineModel";
import FinalizeModel from "./FinalizeModel";

const ModelsForm = (): JSX.Element => {
  const navigate = useNavigate();
  const steps = [
    {
      formKey: "datasource",
      name: "Select a Data Source",
      component: <SelectModelSourceForm />,
      isRequireContinueCta: false,
      beforeNextStep: () => true,
    },
    {
      formKey: "selectModelType",
      name: "Select a Modelling Method",
      component: <ModelMethod />,
      isRequireContinueCta: false,
      beforeNextStep: () => true,
    },
    {
      formKey: "defineModel",
      name: "Define your model",
      component: <DefineModel isUpdateButtonVisible={false} />,
      isRequireContinueCta: false,
      beforeNextStep: () => true,
    },
    {
      formKey: "finalizeModel",
      name: "Finalize model",
      component: <FinalizeModel />,
      isRequireContinueCta: false,
      beforeNextStep: () => true,
    },
  ];

  return (
    <Drawer isOpen onClose={() => navigate(-1)} placement="right" size="100%">
      <DrawerOverlay />
      <DrawerContent>
        <DrawerBody>
          <Box width="100%">
            <SteppedForm steps={steps} />
          </Box>
        </DrawerBody>
      </DrawerContent>
    </Drawer>
  );
};

export default ModelsForm;
