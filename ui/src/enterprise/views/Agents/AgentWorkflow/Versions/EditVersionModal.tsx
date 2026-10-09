import SharedEditVersionModal from '@/enterprise/components/Versions/EditVersionModal';
import { WorkflowVersionResponse } from '@/enterprise/services/types';

interface EditVersionModalProps {
  isOpen: boolean;
  onClose: () => void;
  version: WorkflowVersionResponse;
  onSave: (description: string) => void;
  isLoading?: boolean;
}

const EditVersionModal = ({
  isOpen,
  onClose,
  version,
  onSave,
  isLoading = false,
}: EditVersionModalProps): JSX.Element => (
  <SharedEditVersionModal
    isOpen={isOpen}
    onClose={onClose}
    versionLabel={`v${version.attributes.version_number}`}
    initialDescription={version.attributes.version_description}
    onSave={onSave}
    isLoading={isLoading}
    saveButtonTestId='workflow-version-save-changes-button'
  />
);

export default EditVersionModal;
