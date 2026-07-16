import { useState } from 'react';

import { FiTrash2, FiEdit3 } from 'react-icons/fi';
import { useNavigate, useParams } from 'react-router-dom';

import { CustomToastStatus } from '@/components/Toast';
import EditDetailsModal from '@/components/EditDetailsModal';
import MultiActionButton from '@/components/MultiActionButton/MultiActionButton';

import { deleteConnector } from '@/services/connectors';

import useCustomToast from '@/hooks/useCustomToast';
import HorizontalMenuActions from '@/components/HorizontalMenuActions';

type ConnectorActionsProps = {
  connectorType: 'source' | 'destination';
  initialValues?: { name: string; description: string };
  onSave: (values: { name: string; description: string }) => void;
};

const ConnectorActions = ({ connectorType, initialValues, onSave }: ConnectorActionsProps) => {
  const [openModal, setOpenModal] = useState(false);

  const showToast = useCustomToast();
  const navigate = useNavigate();
  const { sourceId, destinationId } = useParams();

  const handleDeleteConnector = async () => {
    try {
      const connectorId = connectorType === 'source' ? sourceId : destinationId;
      await deleteConnector(connectorId as string);
      showToast({
        title: 'Connector deleted successfully',
        isClosable: true,
        duration: 5000,
        status: CustomToastStatus.Success,
        position: 'bottom-right',
      });
      navigate(`/setup/${connectorType}`);
      return;
    } catch {
      showToast({
        status: CustomToastStatus.Error,
        title: 'Error!!',
        description: 'Something went wrong while deleting the connector',
        position: 'bottom-right',
        isClosable: true,
      });
    }
  };

  return (
    <HorizontalMenuActions contentMargin='8px'>
      <>
        <MultiActionButton
          text='Edit Details'
          icon={FiEdit3}
          iconColor='gray.600'
          onClick={() => setOpenModal(true)}
          buttonTextColor='gray.200'
          buttonHoverColor='gray.200'
          textColor='black.500'
        />
        <MultiActionButton
          text='Delete'
          icon={FiTrash2}
          iconColor='red.600'
          onClick={handleDeleteConnector}
          buttonTextColor='red.600'
          buttonHoverColor='gray.200'
          textColor='red.500'
        />
        <EditDetailsModal
          openModal={openModal}
          setModalOpen={setOpenModal}
          resourceName={connectorType === 'source' ? 'source' : 'destination'}
          onSave={(values) => {
            onSave(values);
            setOpenModal(false);
          }}
          initialValues={initialValues}
        />
      </>
    </HorizontalMenuActions>
  );
};

export default ConnectorActions;
