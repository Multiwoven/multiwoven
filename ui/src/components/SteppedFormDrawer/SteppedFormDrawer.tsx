import { Box, Drawer, DrawerBody, DrawerContent, DrawerOverlay } from '@chakra-ui/react';
import { useNavigate } from 'react-router-dom';
import SteppedForm from '../SteppedForm/SteppedForm';
import { Step } from '../SteppedForm/types';

type SteppedFormDrawerProps = {
  steps: Step[];
};

const SteppedFormDrawer = ({ steps }: SteppedFormDrawerProps) => {
  const navigate = useNavigate();

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

export default SteppedFormDrawer;
