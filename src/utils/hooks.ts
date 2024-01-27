type UseUiConfig = {
  maxContentWidth: number;
  contentPadding: number;
};

export const useUiConfig = (): UseUiConfig => {
  return {
    maxContentWidth: 1300,
    contentPadding: 30,
  };
};
