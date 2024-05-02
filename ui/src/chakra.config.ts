import { extendTheme } from '@chakra-ui/react';

import { enterpriseExtension } from './enterprise/chakra-enterprise.config';

const mwTheme = extendTheme(enterpriseExtension());

export default mwTheme;
