import { Box, Flex, Text } from '@chakra-ui/react';
import { useState } from 'react';
import type { IconType } from 'react-icons';
import { FiDatabase, FiFolder, FiKey, FiSettings } from 'react-icons/fi';
import BaseModal from '@/components/BaseModal';
import { DatabaseSection } from './Database';
import { GeneralPanel } from './GeneralPanel';
import { StorageSection } from './Storage';
import type { AppSettingsModalProps, AppSettingsSection } from './types';
import { NavButton } from '@/views/Sidebar/NavButton';
import SecretsSection from './Secrets/SecretsSection';

type NavItem = {
  id: AppSettingsSection;
  label: string;
  icon: IconType;
  /** Optional section-heading grouping label (rendered above this item). */
  groupLabel?: string;
  testId?: string;
};

const NAV_ITEMS: NavItem[] = [
  { id: 'general', label: 'General', icon: FiSettings },
  { id: 'database', label: 'Database', icon: FiDatabase, groupLabel: 'Data & Logic' },
  { id: 'secrets', label: 'Secrets', icon: FiKey, testId: 'app-builder-secret' },
  { id: 'storage', label: 'Storage', icon: FiFolder, testId: 'app-builder-storage' },
];

type NavRowProps = {
  item: NavItem;
  isActive: boolean;
  onSelect: (id: AppSettingsSection) => void;
};

function NavRow({ item, isActive, onSelect }: NavRowProps): JSX.Element {
  return (
    <>
      {item.groupLabel && (
        <Text
          px='16px'
          py='10px'
          fontSize='xs'
          fontWeight={700}
          color='gray.600'
          letterSpacing='2.4px'
          textTransform='uppercase'
        >
          {item.groupLabel}
        </Text>
      )}
      <NavButton
        label={item.label}
        icon={item.icon}
        isActive={isActive}
        onClick={() => onSelect(item.id)}
        data-testid={item.testId}
      />
    </>
  );
}

function AppSettingsModal({
  openModal,
  setModalOpen,
  appId,
  appName,
  publishedUrl,
  status,
  visibility,
  showBadge,
  onEditAppDetails,
  onUnpublish,
  onRepublish,
  onSetToDraft,
}: AppSettingsModalProps): JSX.Element {
  const [activeSection, setActiveSection] = useState<AppSettingsSection>('general');

  return (
    <BaseModal
      title='App Settings'
      openModal={openModal}
      setModalOpen={setModalOpen}
      modalWidth='6xl'
      maxHeight='85vh'
      addHeaderStroke
      bodyPaddingX='0px'
      bodyPaddingY='0px'
      bodyPaddingTop='0px'
      bodyPaddingBottom='0px'
      contentDataTestId='app-builder-settings'
      closeButtonDataTestId='app-builder-close'
    >
      <Flex w='100%' h='100%' minH='560px'>
        {/* Left nav */}
        <Flex
          direction='column'
          w='280px'
          borderRightWidth='1px'
          borderRightColor='gray.400'
          p='12px'
          gap='4px'
        >
          {NAV_ITEMS.map((item) => (
            <NavRow
              key={item.id}
              item={item}
              isActive={activeSection === item.id}
              onSelect={setActiveSection}
            />
          ))}
        </Flex>

        {/* Right content panel */}
        <Box flex='1' minW={0} overflowY='auto'>
          {activeSection === 'general' && (
            <GeneralPanel
              appId={appId}
              appName={appName}
              publishedUrl={publishedUrl}
              status={status}
              visibility={visibility}
              showBadge={showBadge}
              onEditAppDetails={onEditAppDetails}
              onUnpublish={onUnpublish}
              onRepublish={onRepublish}
              onSetToDraft={onSetToDraft}
            />
          )}
          {activeSection === 'database' && <DatabaseSection appId={appId} />}
          {activeSection === 'secrets' && <SecretsSection appId={appId} />}
          {activeSection === 'storage' && <StorageSection appId={appId} />}
        </Box>
      </Flex>
    </BaseModal>
  );
}

export default AppSettingsModal;
