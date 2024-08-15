import SteppedForm from '@/components/SteppedForm';
import { Box, Drawer, DrawerBody, DrawerContent, DrawerOverlay } from '@chakra-ui/react';
import { useNavigate } from 'react-router-dom';
import SelectDestinations from './SelectDestinations';
import ConnectorConfigForm from '@/views/Connectors/ConnectorConfigForm';
import ConnectorConnectionTest from '@/views/Connectors/ConnectorConnectionTest';
import ConnectorFinaliseForm from '@/views/Connectors/ConnectorFinaliseForm';

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
      component: <ConnectorConfigForm connectorType='destination' />,
      isRequireContinueCta: false,
    },
    {
      formKey: 'testDestination',
      name: 'Test your Destination',
      component: <ConnectorConnectionTest connectorType='destination' />,
      isRequireContinueCta: false,
    },
    {
      formKey: 'finalizeDestination',
      name: 'Finalize your Destination',
      component: <ConnectorFinaliseForm connectorType='destination' />,
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
