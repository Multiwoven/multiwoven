import SteppedForm from '@/components/SteppedForm';
import { Box, Drawer, DrawerBody, DrawerContent, DrawerOverlay } from '@chakra-ui/react';
import { useNavigate } from 'react-router-dom';
import SelectDestinations from './SelectDestinations';
import DestinationConfigForm from './DestinationConfigForm';
import DestinationFinalizeForm from './DestinationFinalizeForm';
import DestinationConnectionTest from './DestinationConnectionTest/DestinationConnectionTest';

const DestinationsForm = (): JSX.Element => {
  const navigate = useNavigate();

  const steps = [
    {
      formKey: 'destination',
      name: 'Select a Destination',
      component: <SelectDestinations />,
      isRequireContinueCta: false,
    },
    {
      formKey: 'destinationConfig',
      name: 'Connect your Destination',
      component: <DestinationConfigForm />,
      isRequireContinueCta: false,
    },
    {
      formKey: 'testDestination',
      name: 'Test your Destination',
      component: <DestinationConnectionTest />,
      isRequireContinueCta: false,
    },
    {
      formKey: 'finalizeDestination',
      name: 'Finalize your Destination',
      component: <DestinationFinalizeForm />,
      isRequireContinueCta: false,
    },
  ];

  return (
    <Drawer isOpen onClose={() => navigate(-1)} placement='right' size='100%'>
      <DrawerOverlay />
      <DrawerContent padding='0px'>
        <DrawerBody padding='0px'>
          <Box>
            <SteppedForm steps={steps} />
          </Box>
        </DrawerBody>
      </DrawerContent>
    </Drawer>
  );
};

export default DestinationsForm;
