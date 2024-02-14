import SteppedForm from "@/components/SteppedForm";
import {
  Box,
  Drawer,
  DrawerBody,
  DrawerContent,
  DrawerOverlay,
} from "@chakra-ui/react";
import { useNavigate } from "react-router-dom";
import SelectModel from "./SelectModel";
import SelectDestination from "./SelectDestination";
import ConfigureSyncs from "./ConfigureSyncs";
import FinaliseSync from "./FinaliseSync";

const SyncForm = (): JSX.Element => {
  const navigate = useNavigate();
  const steps = [
    {
      formKey: "selectModel",
      name: "Select a model",
      component: <SelectModel />,
      isRequireContinueCta: false,
    },
    {
      formKey: "selectDestination",
      name: "Select a destination",
      component: <SelectDestination />,
      isRequireContinueCta: false,
    },
    {
      formKey: "configureSyncs",
      name: "Configure sync",
      component: <ConfigureSyncs />,
      isRequireContinueCta: false,
    },
    {
      formKey: "finaliseSync",
      name: "Finalize sync",
      component: <FinaliseSync />,
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

export default SyncForm;
