import { Step } from '@/components/Breadcrumbs/types';
import ContentContainer from '@/components/ContentContainer';
import TopBar from '@/components/TopBar';
import { Box, Switch, Text, useDisclosure } from '@chakra-ui/react';
import { useEffect, useState } from 'react';
import { FiEdit, FiPlus, FiTrash2 } from 'react-icons/fi';
import { useNavigate } from 'react-router-dom';
import VectorStoreTableColumns from './VectorStoreTableColumns';
import DataTable from '@/components/DataTable';
import NoTablesFound from './NoTablesFound';
import NewVectorTableDrawer from './NewVectorTableDrawer';
import { ColumnDef } from '@tanstack/react-table';
import HorizontalMenuActions from '@/components/HorizontalMenuActions';
import MenuAction from '@/enterprise/components/MenuAction/MenuAction';
import ConfirmDeleteModal from '@/components/ConfirmDeleteModal/ConfirmDeleteModal';
import DisableVectorStore from './DisableVectorStore';
import ToolTip from '@/components/ToolTip';
import useHostedStoreQueries from '@/enterprise/hooks/queries/useHostedStoreQueries';
import { useParams } from 'react-router-dom';
import {
  HostedDataStoreTableResponse,
  HostedStoreTemplateResponse,
} from '@/enterprise/services/types';
import Loader from '@/components/Loader';
import useHostedStoreMutations from '@/enterprise/hooks/mutations/useHostedStoreMutations';
import { useQueryClient } from '@tanstack/react-query';
import { useAPIErrorsToast } from '@/hooks/useErrorToast';
import Pagination from '@/components/EnhancedPagination/Pagination';
import useFilters from '@/hooks/useFilters';
import { hasActionPermission } from '@/enterprise/utils/accessControlPermission';
import { useRoleDataStore } from '@/enterprise/store/useRoleDataStore';
import { UserActions } from '@/enterprise/types';

const ActionButtons = ({
  isStoreEnabled,
  setShowDisableVectorStoreModal,
  isDisabled = false,
  onEnableStore,
}: {
  isStoreEnabled: boolean;
  setShowDisableVectorStoreModal: (value: boolean) => void;
  isDisabled?: boolean;
  onEnableStore: () => void;
}) => (
  <ToolTip
    label={
      isDisabled
        ? "This resource can't be disabled because one or more tables are part of an active sync. Disable all active syncs to disable this resource."
        : ''
    }
  >
    <Box
      display='flex'
      flexDir='row'
      gap='8px'
      alignItems='center'
      border='1px solid'
      borderColor='gray.500'
      borderRadius='6px'
      padding='10px 12px'
    >
      <Text color='gray.600' letterSpacing='2.4px' fontWeight='bold' size='xs' minWidth='85px'>
        {isStoreEnabled ? 'ENABLED' : 'DISABLED'}
      </Text>
      <Switch
        isDisabled={isDisabled}
        isChecked={isStoreEnabled}
        onChange={(event) => {
          if (event.target.checked) {
            onEnableStore();
          } else {
            setShowDisableVectorStoreModal(true);
          }
        }}
        _loading={{
          opacity: 0.5,
          cursor: 'not-allowed',
        }}
      />
    </Box>
  </ToolTip>
);

const VectorStore = () => {
  const { storeId } = useParams();
  const queryClient = useQueryClient();
  const { filters, updateFilters } = useFilters({ page: '1' });
  const [isStoreEnabled, setIsStoreEnabled] = useState(false);
  const { isOpen, onOpen, onClose } = useDisclosure();
  const [selectedTable, setSelectedTable] = useState<HostedDataStoreTableResponse | null>(null);
  const [isDeleteTableModalOpen, setIsDeleteTableModalOpen] = useState(false);
  const [isDisableVectorStoreModalOpen, setIsDisableVectorStoreModalOpen] = useState(false);
  const navigate = useNavigate();
  const apiErrorToast = useAPIErrorsToast();

  const { useGetHostedDataStoreTables, useGetHostedDBTemplates } = useHostedStoreQueries();
  const { data: hostedDBTemplates } = useGetHostedDBTemplates();
  const { data: hostedDataStoreTables, isLoading: isLoadingHostedDataStoreTables } =
    useGetHostedDataStoreTables(storeId as string, filters.page ? Number(filters.page) : 1);

  const template = hostedDBTemplates?.data?.find(
    (template: HostedStoreTemplateResponse) => +template.linked_data_store_id === +storeId!,
  );

  const { deleteHostedDataStoreTableMutation, enableHostedDataStoreMutation } =
    useHostedStoreMutations();

  const activeRole = useRoleDataStore((state) => state.activeRole);

  const hasPermission = activeRole
    ? hasActionPermission(activeRole, 'hosted_datastore', UserActions.Update)
    : false;

  const actionsColumn: ColumnDef<HostedDataStoreTableResponse> = {
    header: '',
    accessorKey: 'attributes',
    cell: ({ row }) => {
      const { onClose } = useDisclosure();
      return (
        <HorizontalMenuActions
          placement='bottom-end'
          variant='light'
          onClick={(e) => {
            e.stopPropagation();
          }}
        >
          <>
            <MenuAction
              icon={FiEdit}
              label='Edit Details'
              variant='edit'
              onClick={(e) => {
                e.stopPropagation();
                setSelectedTable(row.original);
                onOpen();
              }}
              onClose={() => {
                onClose();
              }}
              isDisabled={false}
              testId='edit-hosted-data-store-table'
            />
            <MenuAction
              icon={FiTrash2}
              label='Delete'
              variant='delete'
              onClick={(e) => {
                e.stopPropagation();
                setSelectedTable(row.original);
                setIsDeleteTableModalOpen(true);
              }}
              onClose={() => {
                setSelectedTable(null);
                onClose();
              }}
              isDisabled={row.original.attributes.sync_enabled === 'enabled'}
              tooltipLabel={
                row.original.attributes.sync_enabled === 'enabled'
                  ? "This table can't be deleted because it's part of an active sync. Disable the sync first to delete the table."
                  : ''
              }
              testId='delete-hosted-data-store-table'
            />
          </>
        </HorizontalMenuActions>
      );
    },
  };

  const tableColumns: ColumnDef<HostedDataStoreTableResponse>[] = [
    ...VectorStoreTableColumns,
    ...(hasPermission ? [actionsColumn] : []),
  ];

  const RESOURCES_FORM_STEPS: Step[] = [
    { name: 'Settings', url: '/settings' },
    { name: 'Resources', url: '/settings/resources' },
    { name: template?.name ?? 'AI Squared Vector Store', url: '' },
  ];

  const onPageSelect = (page: number) => {
    updateFilters({ page: page.toString() });
  };

  useEffect(() => {
    if (template) {
      setIsStoreEnabled(template.store_enabled);
    }
  }, [template]);

  if (hostedDataStoreTables?.errors) {
    apiErrorToast(hostedDataStoreTables.errors);
  }

  const isSyncEnabled = hostedDataStoreTables?.data?.some(
    (table: HostedDataStoreTableResponse) => table.attributes.sync_enabled === 'enabled',
  );

  return (
    <ContentContainer>
      <TopBar
        name={template?.name ?? 'AI Squared Vector Store'}
        ctaName='Create Table'
        ctaIcon={<FiPlus color='gray.100' />}
        isCtaVisible={hasPermission}
        onCtaClicked={() => {
          setSelectedTable(null);
          onOpen();
        }}
        breadcrumbSteps={RESOURCES_FORM_STEPS}
        extra={
          hasPermission ? (
            <ActionButtons
              isStoreEnabled={isStoreEnabled}
              setShowDisableVectorStoreModal={setIsDisableVectorStoreModalOpen}
              onEnableStore={async () => {
                if (storeId) {
                  const response = await enableHostedDataStoreMutation.mutateAsync({
                    dataStoreId: storeId,
                    enabled: true,
                  });
                  if (response.errors) {
                    apiErrorToast(response.errors);
                    return;
                  }
                  setIsStoreEnabled(true);
                }
              }}
              isDisabled={isSyncEnabled}
            />
          ) : null
        }
      />
      <Box>
        {isLoadingHostedDataStoreTables ? (
          <Loader />
        ) : (
          <>
            <Box border='1px' borderColor='gray.400' borderRadius={'lg'} overflowX='scroll'>
              <DataTable
                columns={tableColumns}
                data={hostedDataStoreTables?.data ?? []}
                dataTestId='data-store-tables-datatable'
                getRowProps={(row) => ({
                  'data-testid': `data-store-table-row-${row.original.id}`,
                })}
                noRowsComponent={<NoTablesFound onOpen={onOpen} showActionButton={hasPermission} />}
              />
            </Box>
            {hostedDataStoreTables?.data &&
              hostedDataStoreTables.data.length > 0 &&
              hostedDataStoreTables.links && (
                <Box display='flex' justifyContent='center' mt='20px'>
                  <Pagination
                    links={hostedDataStoreTables.links}
                    currentPage={filters.page ? Number(filters.page) : 1}
                    handlePageChange={onPageSelect}
                  />
                </Box>
              )}
          </>
        )}
      </Box>
      <ConfirmDeleteModal
        open={isDeleteTableModalOpen}
        title={`Are you sure you want to delete this table?`}
        description={`This action will permanently delete the table from the AI Squared Vector Store and cannot be undone.`}
        onDelete={async () => {
          if (selectedTable && storeId) {
            await deleteHostedDataStoreTableMutation.mutateAsync({
              dataStoreId: storeId,
              tableId: selectedTable.id,
            });
            queryClient.invalidateQueries({ queryKey: ['get-hosted-data-store-tables'] });
            setIsDeleteTableModalOpen(false);
            setSelectedTable(null);
          }
        }}
        onClose={() => {
          setSelectedTable(null);
          setIsDeleteTableModalOpen(false);
        }}
        isDeleting={deleteHostedDataStoreTableMutation.isPending}
      />
      <NewVectorTableDrawer
        isOpen={isOpen}
        onClose={() => {
          setSelectedTable(null);
          onClose();
        }}
        title={selectedTable ? 'Edit table' : 'Create new table'}
        dataStoreId={storeId as string}
        selectedTable={selectedTable}
        isEditable={selectedTable?.attributes.sync_enabled !== 'enabled'}
      />
      <DisableVectorStore
        isOpen={isDisableVectorStoreModalOpen}
        onClose={() => setIsDisableVectorStoreModalOpen(false)}
        onDisable={async () => {
          if (storeId) {
            const response = await enableHostedDataStoreMutation.mutateAsync({
              dataStoreId: storeId,
              enabled: false,
            });
            if (response.errors) {
              apiErrorToast(response.errors);
              return;
            }
            setIsStoreEnabled(false);
            setIsDisableVectorStoreModalOpen(false);
          }
        }}
        onDeleteSuccess={() => {
          navigate(`/settings/resources`, { replace: true });
        }}
        dataStoreId={storeId as string}
        isDisabling={enableHostedDataStoreMutation.isPending}
      />
    </ContentContainer>
  );
};

export default VectorStore;
