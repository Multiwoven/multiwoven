import SteppedForm from "@/components/SteppedForm";
import SelectDataSourcesForm from "./SelectDataSourcesForm";
import SourceConfigForm from "./SourceConfigForm";

import {
  Box,
  Drawer,
  DrawerBody,
  DrawerContent,
  DrawerOverlay,
} from "@chakra-ui/react";
import { useNavigate } from "react-router-dom";

const SourcesForm = (): JSX.Element => {
  const navigate = useNavigate();
  const steps = [
    {
      formKey: "datasource",
      name: "Select a data source",
      component: <SelectDataSourcesForm />,
      isRequireContinueCta: false,
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

export default SourcesForm;
