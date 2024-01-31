import SteppedForm from "@/components/SteppedForm";
import {
  Box,
  Drawer,
  DrawerBody,
  DrawerContent,
  DrawerOverlay,
} from "@chakra-ui/react";
import { useNavigate } from "react-router-dom";
import SelectDestinations from "./SelectDestinations";

const DestinationsForm = (): JSX.Element => {
  const navigate = useNavigate();

  const steps = [
    {
      formKey: "datasource",
      name: "Select a data source",
      component: <SelectDestinations />,
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

export default DestinationsForm;
