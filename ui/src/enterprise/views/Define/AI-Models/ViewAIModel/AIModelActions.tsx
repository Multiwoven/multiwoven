import RoleAccess from '@/enterprise/components/RoleAccess';
import { UserActions } from '@/enterprise/types';
import DeleteModelModal from '@/views/Models/ViewModel/DeleteModelModal';
import HorizontalMenuActions from '@/components/HorizontalMenuActions';
import MultiActionButton from '@/components/MultiActionButton';
import { FiEdit3 } from 'react-icons/fi';
import { useState } from 'react';
import EditDetailsModal from '@/components/EditDetailsModal';

type AIModelActionsProps = {
  values: { name: string; description: string };
  onSave: (values: { name: string; description: string }, preventNavigate?: boolean) => void;
};

const AIModelActions = ({ values, onSave }: AIModelActionsProps) => {
  const [openModal, setOpenModal] = useState(false);

  return (
    <HorizontalMenuActions contentMargin='8'>
      <>
        <RoleAccess location='model' type='item' action={UserActions.Update}>
          <>
            <MultiActionButton
              icon={FiEdit3}
              onClick={() => setOpenModal(true)}
              buttonTextColor='gray.200'
              textColor='black.500'
              buttonHoverColor='gray.200'
              iconColor='gray.600'
              text='Edit Details'
            />
            <EditDetailsModal
              openModal={openModal}
              setModalOpen={setOpenModal}
              resourceName='model'
              onSave={(values) => {
                onSave(values, true);
                setOpenModal(false);
              }}
              initialValues={{
                name: values?.name || '',
                description: values?.description || '',
              }}
            />
          </>
        </RoleAccess>
        <RoleAccess location='model' type='item' action={UserActions.Delete}>
          <DeleteModelModal />
        </RoleAccess>
      </>
    </HorizontalMenuActions>
  );
};

export default AIModelActions;
