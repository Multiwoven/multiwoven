import { Button, Flex, Icon, Spinner, Text } from '@chakra-ui/react';
import { useCallback, useEffect, useRef, useState } from 'react';
import { FiPlus } from 'react-icons/fi';

import ConfirmDeleteModal from '@/components/ConfirmDeleteModal';
import useAppGenMutations from '@/enterprise/hooks/mutations/useAppGenMutations';
import useAppGenQueries from '@/enterprise/hooks/queries/useAppGenQueries';

import { EnableState } from '../shared/EnableState';
import { STEP_DURATION_MS } from '../shared/constants';
import type { DatabaseSectionStatus } from '../Database/types';

import { STORAGE_ENABLE_COPY, STORAGE_ENABLING_STEPS } from './constants';
import { EmptyFoldersVisual } from './EmptyFoldersVisual';

import { CreateFolderView } from './CreateFolderView';
import { FolderDetailView } from './FolderDetailView';
import { FoldersList } from './FoldersList';
import type { Folder } from './types';

type StorageSectionProps = {
  appId: string;
};

export function StorageSection({ appId }: StorageSectionProps): JSX.Element {
  const [status, setStatus] = useState<DatabaseSectionStatus>('idle');
  const [stepIndex, setStepIndex] = useState(0);
  /**
   * Currently-open folder name. `null` = top-level folder list. The backend
   * doesn't support nested folders, so this is a single string rather than a
   * path array.
   */
  const [selectedFolderName, setSelectedFolderName] = useState<string | null>(null);
  const [isCreatingFolder, setIsCreatingFolder] = useState(false);
  const [folderToDelete, setFolderToDelete] = useState<Folder | null>(null);

  const timersRef = useRef<ReturnType<typeof setTimeout>[]>([]);
  const mountedRef = useRef(true);

  const { useGetStorage, useGetStorageFolders } = useAppGenQueries();
  const { provisionStorage, createStorageFolder, deleteStorageFolder } = useAppGenMutations();

  const { data: storageData, isLoading: isLoadingStorage } = useGetStorage(appId);
  const remoteStatus = storageData?.data?.attributes?.status;

  /**
   * Sync remote provisioned-state into local state ONCE — only while we're
   * still 'idle'. Once the user clicks Enable here (or the bucket is already
   * provisioned), a refetch must not clobber local UI state.
   */
  useEffect(() => {
    if (status === 'idle' && remoteStatus === 'provisioned') {
      setStatus('enabled');
    }
  }, [remoteStatus, status]);

  useEffect(() => {
    mountedRef.current = true;
    return () => {
      mountedRef.current = false;
      timersRef.current.forEach(clearTimeout);
      timersRef.current = [];
    };
  }, []);

  const isEnabled = status === 'enabled';

  // Only fetch folders once the bucket is provisioned — before that, hitting
  // GET /folders 404s with "Storage not provisioned" and creates UI noise.
  const { data: foldersData, isLoading: isLoadingFolders } = useGetStorageFolders(appId, isEnabled);
  const folders: Folder[] =
    foldersData?.data?.folders?.map((f) => ({
      id: f.name, // backend doesn't give us a separate ID; the name is unique-per-app
      name: f.name,
      is_public: f.public,
    })) ?? [];

  const stopBadgeCycle = useCallback((): void => {
    timersRef.current.forEach(clearTimeout);
    timersRef.current = [];
  }, []);

  const startBadgeCycle = useCallback((): void => {
    setStepIndex(0);
    for (let i = 1; i < STORAGE_ENABLING_STEPS.length; i++) {
      const t = setTimeout(() => {
        if (!mountedRef.current) return;
        setStepIndex(i);
      }, STEP_DURATION_MS * i);
      timersRef.current.push(t);
    }
  }, []);

  const handleEnable = useCallback(async (): Promise<void> => {
    if (!appId) return;
    setStatus('enabling');
    startBadgeCycle();
    try {
      const response = await provisionStorage.mutateAsync(appId);
      if (!mountedRef.current) return;
      stopBadgeCycle();
      if (response?.errors) {
        setStatus('idle');
        return;
      }
      setStatus('enabled');
    } catch {
      if (!mountedRef.current) return;
      stopBadgeCycle();
      setStatus('idle');
    }
  }, [appId, provisionStorage, startBadgeCycle, stopBadgeCycle]);

  // ---- Folder CRUD ---------------------------------------------------------

  const existingFolderNames = folders.map((f) => f.name);

  const handleCreateFolder = async ({
    name,
    isPublic,
  }: {
    name: string;
    isPublic: boolean;
  }): Promise<void> => {
    if (createStorageFolder.isPending) return;
    try {
      const response = await createStorageFolder.mutateAsync({
        appId,
        name,
        public: isPublic,
      });
      // Soft failure: useResponseHandlers already toasted; stay on form so
      // the user can correct (e.g. duplicate name).
      if (response?.errors) return;
      setIsCreatingFolder(false);
    } catch {
      /* network error already toasted by mutation onError */
    }
  };

  const handleConfirmDeleteFolder = async (): Promise<void> => {
    if (!folderToDelete || deleteStorageFolder.isPending) return;
    try {
      await deleteStorageFolder.mutateAsync({
        appId,
        folderName: folderToDelete.name,
      });
    } finally {
      // If we were inside the deleted folder, pop back to the list.
      if (selectedFolderName === folderToDelete.name) {
        setSelectedFolderName(null);
      }
      setFolderToDelete(null);
    }
  };

  // ---- Render --------------------------------------------------------------

  if (isLoadingStorage) {
    return (
      <Flex w='100%' h='100%' align='center' justify='center' minH='320px'>
        <Spinner size='md' color='gray.600' />
      </Flex>
    );
  }

  if (isEnabled && isCreatingFolder) {
    return (
      <CreateFolderView
        existingFolderNames={existingFolderNames}
        onSubmit={handleCreateFolder}
        onCancel={() => setIsCreatingFolder(false)}
        isSubmitting={createStorageFolder.isPending}
      />
    );
  }

  // Detail view: rendered when a folder is selected AND it still exists in
  // the live folder list (it may have been deleted from another tab).
  const selectedFolder = selectedFolderName
    ? folders.find((f) => f.name === selectedFolderName) ?? null
    : null;
  if (isEnabled && selectedFolder) {
    return (
      <>
        <FolderDetailView
          appId={appId}
          folder={selectedFolder}
          onBackToRoot={() => setSelectedFolderName(null)}
        />
        <ConfirmDeleteModal
          open={folderToDelete !== null}
          title='Delete folder?'
          description={
            folderToDelete
              ? `"${folderToDelete.name}" and all its files will be permanently removed. This action cannot be undone.`
              : ''
          }
          onClose={() => setFolderToDelete(null)}
          onDelete={handleConfirmDeleteFolder}
          isDeleting={deleteStorageFolder.isPending}
          deleteButtonText='Delete'
          testId='app-builder-delete-folder-modal'
        />
      </>
    );
  }

  return (
    <Flex direction='column' w='100%' h='100%'>
      <Flex
        align='flex-start'
        justify='space-between'
        gap='16px'
        px='24px'
        pt='16px'
        pb='16px'
        borderBottomWidth='1px'
        borderColor='gray.400'
      >
        <Flex direction='column' gap='4px' minW={0}>
          <Text fontSize='md' fontWeight='semibold' color='black.500'>
            Storage
          </Text>
          <Text fontSize='xs' color='black.100'>
            View and manage the files stored in your app.
          </Text>
        </Flex>
        {isEnabled && (
          <Button
            variant='shell'
            size='sm'
            minWidth={0}
            width='auto'
            leftIcon={<Icon as={FiPlus} />}
            onClick={() => setIsCreatingFolder(true)}
            data-testid='app-builder-add-new-folder'
          >
            Add New Folder
          </Button>
        )}
      </Flex>

      {isEnabled ? (
        isLoadingFolders ? (
          <Flex flex='1' align='center' justify='center' px='24px' pb='24px'>
            <Spinner size='md' color='gray.600' />
          </Flex>
        ) : (
          <FoldersList
            folders={folders}
            onSelectFolder={(f) => setSelectedFolderName(f.name)}
            onDeleteFolder={(f) => setFolderToDelete(f)}
          />
        )
      ) : (
        <Flex flex='1' align='center' justify='center' px='24px' pb='24px'>
          <EnableState
            status={status}
            stepLabel={STORAGE_ENABLING_STEPS[stepIndex]}
            onEnable={handleEnable}
            copy={STORAGE_ENABLE_COPY}
            visual={<EmptyFoldersVisual />}
            enableButtonTestId='app-builder-enable-storage'
          />
        </Flex>
      )}

      <ConfirmDeleteModal
        open={folderToDelete !== null}
        title='Delete folder?'
        description={
          folderToDelete
            ? `"${folderToDelete.name}" and all its files will be permanently removed. This action cannot be undone.`
            : ''
        }
        onClose={() => setFolderToDelete(null)}
        onDelete={handleConfirmDeleteFolder}
        isDeleting={deleteStorageFolder.isPending}
        deleteButtonText='Delete'
        testId='app-builder-delete-folder-modal'
      />
    </Flex>
  );
}
