import EditModelModal from './EditModelModal';
import { PrefillValue } from '../ModelsForm/DefineModel/DefineSQL/types';
import DeleteModelModal from './DeleteModelModal';
<<<<<<< HEAD

const ModelActions = ({ prefillValues }: { prefillValues: PrefillValue }) => (
  <>
    <Popover closeOnEsc>
      <PopoverTrigger>
        <Box>
          <Box
            cursor='pointer'
            bgColor='gray.300'
            px={2}
            py={2}
            ml={6}
            rounded='xl'
            _hover={{ bgColor: 'gray.400' }}
          >
            <Box>
              <FiMoreHorizontal />
            </Box>
          </Box>
        </Box>
      </PopoverTrigger>
      <PopoverContent w='182px' border='1px' borderColor='gray.500' mr={8}>
        <PopoverBody margin={0} p={0}>
          <EditModelModal {...prefillValues} />
          <DeleteModelModal />
        </PopoverBody>
      </PopoverContent>
    </Popover>
  </>
=======
import RoleAccess from '@/enterprise/components/RoleAccess';
import { UserActions } from '@/enterprise/types';
import HorizontalMenuActions from '@/components/HorizontalMenuActions';

const ModelActions = ({ prefillValues }: { prefillValues: PrefillValue }) => (
  <HorizontalMenuActions backgroundColor='gray.200' contentMargin='12px' borderColor='gray.400'>
    <>
      <RoleAccess location='model' type='item' action={UserActions.Update}>
        <EditModelModal {...prefillValues} />
      </RoleAccess>
      <RoleAccess location='model' type='item' action={UserActions.Delete}>
        <DeleteModelModal />
      </RoleAccess>
    </>
  </HorizontalMenuActions>
>>>>>>> 8f1c21c9 (refactor(CE): models creation flow)
);

export default ModelActions;
