import SteppedForm from "@/components/SteppedForm";
import SourceConfigForm from "@/views/Connectors/Sources/SourcesForm/SourceConfigForm";

import {
  Box,
  Drawer,
  DrawerBody,
  DrawerContent,
  DrawerOverlay,
} from "@chakra-ui/react";
import { useNavigate } from "react-router-dom";

const ModelsForm = (): JSX.Element => {
  const navigate = useNavigate();
  const steps = [
    {
      formKey: "datasource",
      name: "Select a data source",
      component: <div></div>,
      isRequireContinueCta: true,
      beforeNextStep: () => true,
    },
    {
      formKey: "connectToSources",
      name: "Connect to source",
      component: <SourceConfigForm />,
      isRequireContinueCta: true,
      beforeNextStep: () => false,
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
