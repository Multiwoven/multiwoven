import SteppedForm from '@/components/SteppedForm';

import { Box, Drawer, DrawerBody, DrawerContent, DrawerOverlay } from '@chakra-ui/react';
import { useNavigate } from 'react-router-dom';
import SelectModelSourceForm from './SelectModelSourceForm';
import ModelMethod from './ModelMethod';
import DefineModel from './DefineModel';
import FinalizeModel from './FinalizeModel';

const ModelsForm = (): JSX.Element => {
  const navigate = useNavigate();
  const steps = [
    {
      formKey: 'datasource',
      name: 'Select a data source',
      component: <SelectModelSourceForm />,
      isRequireContinueCta: false,
      beforeNextStep: () => true,
    },
    {
      formKey: 'selectModelType',
      name: 'Select a Modelling method',
      component: <ModelMethod />,
      isRequireContinueCta: false,
      beforeNextStep: () => true,
    },
    {
      formKey: 'defineModel',
      name: 'Define your Model',
      component: <DefineModel isUpdateButtonVisible={false} />,
      isRequireContinueCta: false,
      beforeNextStep: () => true,
    },
    {
      formKey: 'finalizeModel',
      name: 'Finalize Model',
      component: <FinalizeModel />,
      isRequireContinueCta: false,
      beforeNextStep: () => true,
    },
  ];

  return (
    <Drawer isOpen onClose={() => navigate(-1)} placement='right' size='100%'>
      <DrawerOverlay />
      <DrawerContent padding='0px'>
        <DrawerBody padding='0px'>
          <Box width='100%'>
            <SteppedForm steps={steps} />
          </Box>
        </DrawerBody>
      </DrawerContent>
    </Drawer>
  );
};

export default ModelsForm;
