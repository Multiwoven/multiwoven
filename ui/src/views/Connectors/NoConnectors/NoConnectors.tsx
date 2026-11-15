import { Button, Center, Flex, Heading, Image, Text, VStack } from '@chakra-ui/react';
import { FiPlus } from 'react-icons/fi';
<<<<<<< HEAD
import NoSourcesImage from '@/assets/images/NoSources.png';
import NoDestinationsImage from '@/assets/images/NoDestinations.png';
import { useNavigate } from 'react-router-dom';
=======
import NoSourcesImage from '@/assets/images/NoSources.svg';
import NoDestinationsImage from '@/assets/images/NoDestinations.svg';
import { UserActions } from '@/enterprise/types';
import RoleAccess from '@/enterprise/components/RoleAccess';
import { useRoleDataStore } from '@/enterprise/store/useRoleDataStore';
import { hasActionPermission } from '@/enterprise/utils/accessControlPermission';
import NoAccess from '@/enterprise/views/NoAccess';
import { SourceTypes } from '../types';
import useProtectedNavigate from '@/enterprise/hooks/useProtectedNavigate';
>>>>>>> a17b1ac0 (refactor(CE): change images to svgs (#987))

type NoConnectorsProps = {
  connectorType: string;
};

const NoConnectors = ({ connectorType }: NoConnectorsProps): JSX.Element => {
  const navigate = useNavigate();

  const type = connectorType === 'source' ? 'Source' : 'Destination';
<<<<<<< HEAD
  const description =
    connectorType === 'source'
=======
  const isAiMlSource = connectorType === 'source' && sourceType && sourceType === SourceTypes.AI_ML;

  const description = hasConnectorCreationPermission
    ? connectorType === 'source'
>>>>>>> a17b1ac0 (refactor(CE): change images to svgs (#987))
      ? 'Configure a source where your data is stored and managed'
      : 'Add a Destination where your data will be sent';

  const image = connectorType === 'source' ? NoSourcesImage : NoDestinationsImage;

  function onClickAddConnector() {
    const path = connectorType === 'source' ? 'sources' : 'destinations';

    navigate(`/setup/${path}/new`, { replace: true });
  }

  return (
    <Flex width='100%' height='100vh' alignContent='center' justifyContent='center'>
      <Center>
        <VStack spacing={8}>
          <VStack>
            <Image src={image} />
            <Heading size='xs' fontWeight='semibold'>
              No {type}s added
            </Heading>
            <Text size='sm' color='black.200'>
              {description}{' '}
            </Text>
          </VStack>
<<<<<<< HEAD
          <Button onClick={onClickAddConnector} leftIcon={<FiPlus />} variant='solid' w='fit'>
            Add {type}
          </Button>
=======
          <RoleAccess location='connector' type='item' action={UserActions.Create}>
            <Button onClick={onClickAddConnector} leftIcon={<FiPlus />} variant='solid' w='fit'>
              Add {type === 'Source' ? `${isAiMlSource ? 'AI/ML' : 'Data'} ${type}` : type}
            </Button>
          </RoleAccess>
>>>>>>> a17b1ac0 (refactor(CE): change images to svgs (#987))
        </VStack>
      </Center>
    </Flex>
  );
};

export default NoConnectors;
