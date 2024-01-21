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
    },
    {
      formKey: "connectToSources",
      name: "Connect to source",
      component: <SourceConfigForm />,
      isRequireContinueCta: false,
    },
  ];

  return (
    <Drawer isOpen onClose={() => navigate(-1)} placement="right" size="100%">
      <DrawerOverlay />
      <DrawerContent padding="0px">
        <DrawerBody padding="0px">
          <Box>
            <SteppedForm steps={steps} />
          </Box>
        </DrawerBody>
      </DrawerContent>
    </Drawer>
  );
};

export default SourcesForm;
