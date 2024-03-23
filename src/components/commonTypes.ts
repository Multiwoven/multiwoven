export type TypographySizes = 'small' | 'medium' | 'large';

export type AlertData = {
  status: 'info' | 'warning' | 'success' | 'error' | 'loading' | undefined;
  description: string[];
};

export type ConnectorType = {
  connectorType: 'sources' | 'destinations' | 'models';
  buttonText: string;
  buttonOnClick: any;
  buttonVisible: boolean;
};
