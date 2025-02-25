import SelectDataSourcesForm from './SelectDataSourcesForm';

<<<<<<< HEAD
import { Box, Drawer, DrawerBody, DrawerContent, DrawerOverlay } from '@chakra-ui/react';
import { useNavigate } from 'react-router-dom';
import ConnectorConfigForm from '@/views/Connectors/ConnectorConfigForm';
import ConnectorConnectionTest from '@/views/Connectors/ConnectorConnectionTest';
import ConnectorFinaliseForm from '@/views/Connectors/ConnectorFinaliseForm';

const SourcesForm = (): JSX.Element => {
  const navigate = useNavigate();
=======
import { useParams } from 'react-router-dom';
import ConnectorConfigForm from '@/views/Connectors/ConnectorConfigForm';
import ConnectorConnectionTest from '@/views/Connectors/ConnectorConnectionTest';
import ConnectorFinaliseForm from '@/views/Connectors/ConnectorFinaliseForm';
import { AIMLSourceFormSteps } from '@/enterprise/views/AIMLSources/SourceFormSteps/SourceFormSteps';
import { SourceTypes } from '../../types';
import SteppedFormDrawer from '@/components/SteppedFormDrawer';

const SourcesForm = (): JSX.Element => {
  const { sourceType } = useParams();

>>>>>>> 6e1cfad3 (fix(CE): Content centered at max width)
  const steps = [
    {
      formKey: 'datasource',
      name: 'Select a Data Source',
      component: <SelectDataSourcesForm />,
      isRequireContinueCta: false,
    },
    {
      formKey: 'connectToSources',
      name: 'Connect to your Source',
      component: <ConnectorConfigForm connectorType='source' />,
      isRequireContinueCta: false,
    },
    {
      formKey: 'testSource',
      name: 'Test your Source',
      component: <ConnectorConnectionTest connectorType='source' />,
      isRequireContinueCta: false,
    },
    {
      formKey: 'finalizeSource',
      name: 'Finalize your Source',
      component: <ConnectorFinaliseForm connectorType='source' />,
      isRequireContinueCta: false,
    },
  ];

  return (
<<<<<<< HEAD
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
=======
    <SteppedFormDrawer steps={sourceType === SourceTypes.AI_ML ? AIMLSourceFormSteps : steps} />
>>>>>>> 6e1cfad3 (fix(CE): Content centered at max width)
  );
};

export default SourcesForm;
